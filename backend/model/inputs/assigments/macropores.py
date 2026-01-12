from typing import Literal
from dataclasses import dataclass, field
import numpy as np

MACROPORE_DTYPE = np.dtype([
    ('fmac', 'f8'), # fmac: Macroporosity factor
    ('amac', 'f8'), # amac: Macroporous cross section
    ('beta', 'f8') # beta: Exponent for KSB increase
])

@dataclass
class MacroporeHeader:
    velocity_method: Literal['ari', 'geo'] = 'ari' # 'ari' or 'geo'
    anisotropy: int = 1         # m_aniso (1=vert, 2=lat, 3=both)
    assignment_mode: int = 1    # 0=Relative Coords, 1=Node Indices

@dataclass
class MacroporeDef:
    header: MacroporeHeader    
    data: np.ndarray = field(init=False)

    @classmethod
    def from_file(cls, path: str, n_layers: int, n_columns: int) -> 'MacroporeDef':
        """
        n_layers: Vertical nodes (iacnv)
        n_columns: Lateral nodes (iacnl)
        """
        instance = cls(header=MacroporeHeader())
        
        # Initialize Default Grid
        instance.data = np.zeros((n_columns, n_layers), dtype=MACROPORE_DTYPE)
        instance.data['fmac'] = 1.0
        instance.data['beta'] = 1.0
        
        try:
            with open(path, 'r') as f:
                lines = [l.strip() for l in f if l.strip() and not l.startswith('#')]
            
            if not lines:
                 return instance

            # HEADER
            header_parts = lines[0].split()
            
            if header_parts[0] == "DIRECT":
                raise NotImplementedError("DIRECT mode reading not yet implemented.")
            
            n_lines_to_read = int(header_parts[0])
            mode = int(header_parts[1]) # 0=Relative, 1=Node-wise
            m_aniso = int(header_parts[2])
            
            # Line 2: Velocity Method
            velocity_method = lines[1].strip()
            
            instance.header = MacroporeHeader(
                velocity_method=velocity_method,
                anisotropy=m_aniso,
                assignment_mode=mode
            )
            
            # DATA
            for i in range(n_lines_to_read):
                parts = lines[2 + i].split()
                
                if mode == 1:
                    # Node-wise (Integers in file)
                    # Input is 1-based (Fortran), convert to 0-based
                    v_start = int(parts[0]) - 1
                    v_end = int(parts[1])   # Slice excludes end
                    
                    l_start = int(parts[2]) - 1
                    l_end = int(parts[3])
                else:
                    # Relative coordinates (Floats 0.0 - 1.0 in file)
                    # Convert percentages to indices
                    v_start = int(float(parts[0]) * n_layers)
                    v_end = int(float(parts[1]) * n_layers)
                    
                    l_start = int(float(parts[2]) * n_columns)
                    l_end = int(float(parts[3]) * n_columns)
                    
                    # Safety: Ensure slice is at least 1 cell wide/high if values are valid
                    if v_end == v_start: v_end += 1
                    if l_end == l_start: l_end += 1

                # 3. Parse Parameters
                fmac = float(parts[4])
                amac = float(parts[5])
                beta = float(parts[6])
                
                # Your requested fix for amac
                if 0 < amac < 1e-8:
                    amac = 1.0

                # Apply to grid
                instance.data[l_start:l_end, v_start:v_end]['fmac'] = fmac
                instance.data[l_start:l_end, v_start:v_end]['amac'] = amac
                instance.data[l_start:l_end, v_start:v_end]['beta'] = beta

            return instance

        except Exception as e:
            raise ValueError(f"Failed to parse Macropore file ({path}): {e}")

    
    def _get_column_segments(self, col_idx: int):
        """
        Helper method: Compresses a single column vertically.
        Returns a list of segments: [(v_start, v_end, (fmac, amac, beta)), ...]
        """
        rows = self.data.shape[1]
        segments = []
        v_start = 0
        # Convert numpy structured scalar to standard python tuple for safe comparison
        curr_vals = tuple(self.data[col_idx, 0])
        
        for v in range(1, rows):
            next_vals = tuple(self.data[col_idx, v])
            if curr_vals != next_vals:
                # Value changed, close current segment
                # Note: v-1 because the range is inclusive for the segment logic
                segments.append((v_start, v - 1, curr_vals))
                curr_vals = next_vals
                v_start = v
        
        # Append the final segment of the column
        segments.append((v_start, rows - 1, curr_vals))
        return segments

    def to_file(self, filepath: str):
        """
        Writes the Macropore definition to a file using 2D compression.
        """
        cols = self.data.shape[0]
        blocks = [] # Will hold dictionaries: {'l_start', 'l_end', 'segments'}

        if cols > 0:
            # 1. Analyze the first column
            current_segments = self._get_column_segments(0)
            current_block = {'l_start': 0, 'l_end': 0, 'segments': current_segments}
            
            # 2. Iterate through remaining columns to find lateral blocks
            for l in range(1, cols):
                next_segments = self._get_column_segments(l)
                
                # If this column has the exact same structure/values as the previous one
                if next_segments == current_segments:
                    # Extend the current block laterally
                    current_block['l_end'] = l
                else:
                    # Structure changed: save current block and start a new one
                    blocks.append(current_block)
                    current_segments = next_segments
                    current_block = {'l_start': l, 'l_end': l, 'segments': next_segments}
            
            # Don't forget the last block
            blocks.append(current_block)

        # 3. Flatten blocks into the final list of lines to write
        output_lines = []
        for block in blocks:
            l_s, l_e = block['l_start'], block['l_end']
            for v_s, v_e, vals in block['segments']:
                output_lines.append({
                    'v_s': v_s, 'v_e': v_e,
                    'l_s': l_s, 'l_e': l_e,
                    'fmac': vals[0], 'amac': vals[1], 'beta': vals[2]
                })

        try:
            with open(filepath, 'w') as f:
                # --- Write Header ---
                # Line 1: n_lines mode m_aniso
                # We use Mode 1 (Node-wise) because we calculated explicit indices
                f.write(f"{len(output_lines)} 1 {self.header.anisotropy}\n")
                
                # Line 2: Velocity Method
                f.write(f"{self.header.velocity_method}\n")
                
                # --- Write Data Lines ---
                for line in output_lines:
                    # Convert 0-based Python indices to 1-based Fortran indices
                    # Format: v_start v_end l_start l_end fmac amac beta
                    f.write(
                        f"{line['v_s'] + 1} {line['v_e'] + 1} "
                        f"{line['l_s'] + 1} {line['l_e'] + 1} "
                        f"{line['fmac']:.6f} "
                        f"{line['amac']:.6g} "  # .6g handles small scientific notation (1.E-3) better
                        f"{line['beta']:.6f}\n"
                    )
                    
        except Exception as e:
            raise IOError(f"Failed to write Macropore file to {filepath}: {e}")

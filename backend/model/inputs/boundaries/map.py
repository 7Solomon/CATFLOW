import numpy as np
from dataclasses import dataclass, field
from typing import Dict, List, Tuple

BC_ZERO_FLUX = 0
BC_GRAVITATION = -3
BC_FIXED_POTENTIAL = -4
BC_FREE_FLOW = -5
BC_SEEPAGE = -10
BC_ATMOSPHERIC = -99

@dataclass
class BoundaryConditions:
    left: np.ndarray   # n_layers (Vertical)
    right: np.ndarray  # n_layers (Vertical)
    top: np.ndarray    # n_columns (Lateral)
    bottom: np.ndarray # n_columns (Lateral)
    
    # 2D Array for Sinks (Inner Domain)
    sinks: np.ndarray  # Shape: (n_columns, n_layers)
    # Mass Transport File Link (Integer ID)
    mass_file_id: int = 0

    @classmethod
    def from_file(cls, path: str, n_layers: int, n_columns: int) -> 'BoundaryConditions':
        left = np.zeros(n_layers, dtype=int)
        right = np.zeros(n_layers, dtype=int)
        top = np.zeros(n_columns, dtype=int)
        bottom = np.zeros(n_columns, dtype=int)
        sinks = np.zeros((n_columns, n_layers), dtype=int)
        mass_id = 0
        
        with open(path, 'r') as f:
            lines = [l.strip() for l in f if l.strip()] # Comments starting with % handled in loop?
        
        iterator = iter(lines)
        try:
            while True:
                line = next(iterator).split('%')[0].strip() # Remove comments inline
                if not line: continue
                
                keyword = line.upper()
                
                if keyword.startswith('MASS'):
                    try:
                        val_line = next(iterator).split('%')[0].strip()
                        mass_id = int(val_line)
                    except StopIteration:
                        pass # End of file
                    continue

                #  GEOM OF BCs
                target_arr = None
                max_dim = 0
                is_sink = False
                
                if keyword.startswith('LEFT'):
                    target_arr = left; max_dim = n_layers
                elif keyword.startswith('RIGHT'):
                    target_arr = right; max_dim = n_layers
                elif keyword.startswith('TOP'):
                    target_arr = top; max_dim = n_columns
                elif keyword.startswith('BOTTOM'):
                    target_arr = bottom; max_dim = n_columns
                elif keyword.startswith('SINK') or keyword.startswith('SOURCE'):
                    is_sink = True
                else:
                    raise ValueError("BROTHER EH")
                
                # Read "ianz, iart" (Number of lines, Dummy)
                meta_line = next(iterator).split('%')[0].split()
                n_lines = int(meta_line[0])
                
                for _ in range(n_lines):
                    data_line = next(iterator).split('%')[0].split()
                    
                    if is_sink:
                        # Format: v_start v_end l_start l_end bc_id
                        v_s, v_e = cls._parse_range(data_line[0], data_line[1], n_layers)
                        l_s, l_e = cls._parse_range(data_line[2], data_line[3], n_columns)
                        val = int(float(data_line[4]))
                        
                        # Apply to 2D Sink Matrix
                        sinks[l_s:l_e, v_s:v_e] = val
                    else:
                        # Format: start end bc_id
                        s, e = cls._parse_range(data_line[0], data_line[1], max_dim)
                        val = int(float(data_line[2]))
                        
                        # Apply to 1D Edge Array
                        target_arr[s:e] = val
                        
        except StopIteration:
            pass
            
        return cls(left=left, right=right, top=top, bottom=bottom, sinks=sinks, mass_file_id=mass_id)

    def to_file(self, filepath: str):
        """
        Writes the Boundary Conditions using run-length encoding (ranges) to match the format.
        """
        def write_1d_section(f, name, array):
            blocks = self._compress_1d(array)
            f.write(f"{name}\n")
            f.write(f"{len(blocks)} 0\n") # ianz, iart=0
            
            n = len(array)
            for s, e, val in blocks:
                # Convert to relative (0.0 - 1.0)
                # s is start index, e is END index (inclusive in blocks)
                #start/N, (end+1)/N 
                
                # Normalize
                start_rel = s / n
                end_rel = (e + 1) / n 
                
                # Format: s e val
                f.write(f" {start_rel:.6f} {end_rel:.6f} {val}\n")
            f.write("\n")

        with open(filepath, 'w') as f:
            write_1d_section(f, "LEFT", self.left)
            write_1d_section(f, "RIGHT", self.right)
            write_1d_section(f, "TOP", self.top)
            write_1d_section(f, "BOTTOM", self.bottom)
            print("SINK NOT IMPOEMENTED")
            f.write(f"MASS\n{self.mass_file_id}\n")

    @staticmethod
    def _parse_range(start_str, end_str, max_dim):
        """Shared range parsing logic (same as SoilWaterIC)."""
        s = float(start_str)
        e = float(end_str)
        if s <= 1.0 and e <= 1.0 and not (s >= 1.0 and e >= 1.0): 
            # Relative
            start = int(s * max_dim)
            end = int(e * max_dim)
            if end == start: end += 1
            return start, end
        else:
            # Absolute (1-based -> 0-based)
            return int(s) - 1, int(e)

    @staticmethod
    def _compress_1d(array):
        """Run-Length Encoding for 1D array."""
        if len(array) == 0: return []
        blocks = []
        curr_val = array[0]
        start_idx = 0
        for i in range(1, len(array)):
            if array[i] != curr_val:
                blocks.append((start_idx, i-1, curr_val))
                curr_val = array[i]
                start_idx = i
        blocks.append((start_idx, len(array)-1, curr_val))
        return blocks

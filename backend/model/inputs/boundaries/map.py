import numpy as np
from dataclasses import dataclass, field
from typing import Dict, List, Tuple, Optional

# Constants for Boundary Types
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
        # Initialize default arrays (0 = Zero Flux is default usually)
        left = np.zeros(n_layers, dtype=int)
        right = np.zeros(n_layers, dtype=int)
        top = np.zeros(n_columns, dtype=int)
        bottom = np.zeros(n_columns, dtype=int)
        sinks = np.zeros((n_columns, n_layers), dtype=int)
        mass_id = 0
        
        with open(path, 'r') as f:
            # Clean lines: strip comments (%) and whitespace
            lines = []
            for l in f:
                l_clean = l.split('%')[0].strip()
                if l_clean:
                    lines.append(l_clean)
        
        iterator = iter(lines)
        
        try:
            while True:
                line = next(iterator)
                keyword = line.upper()
                
                # --- CASE 1: MASS INPUT ---
                if keyword.startswith('MASS') or keyword.startswith('MASSE'):
                    # The manual implies: "MASS" line, then next line is ID
                    # Sometimes written as "MASS 1" on one line? 
                    # Standard is keyword line, then value line.
                    try:
                        val_line = next(iterator)
                        # Expecting an integer like "1" or "0"
                        # Handle potential inline comments or extra tokens
                        parts = val_line.split()
                        if parts:
                            mass_id = int(parts[0])
                    except (StopIteration, ValueError):
                        pass 
                    continue

                # --- CASE 2: GEOMETRY BLOCKS ---
                target_arr = None
                max_dim = 0
                is_sink = False
                
                if keyword.startswith('LINKS') or keyword.startswith('LEFT'):
                    target_arr = left; max_dim = n_layers
                elif keyword.startswith('RECHTS') or keyword.startswith('RIGHT'):
                    target_arr = right; max_dim = n_layers
                elif keyword.startswith('OBEN') or keyword.startswith('TOP'):
                    target_arr = top; max_dim = n_columns
                elif keyword.startswith('UNTEN') or keyword.startswith('BOTTOM'):
                    target_arr = bottom; max_dim = n_columns
                elif keyword.startswith('SENKEN') or keyword.startswith('SINK') or keyword.startswith('SOURCE'):
                    is_sink = True
                else:
                    # Unknown keyword or just a comment line that slipped through?
                    # If strictly following manual, maybe break or continue.
                    print(f"Warning: Unknown keyword '{keyword}' in boundary file.")
                    continue
                
                # Read "ianz, iart" (Number of lines, Dummy)
                # Example: "2 0" -> 2 lines follow
                try:
                    meta_line = next(iterator)
                    meta_parts = meta_line.split()
                    n_lines = int(meta_parts[0])
                except (StopIteration, ValueError):
                    break
                
                for _ in range(n_lines):
                    data_line = next(iterator)
                    parts = data_line.split()
                    
                    if is_sink:
                        # Format: v_start v_end l_start l_end bc_id
                        # Example: 0. 1. 0. 1. -99
                        v_s, v_e = cls._parse_range(parts[0], parts[1], n_layers)
                        l_s, l_e = cls._parse_range(parts[2], parts[3], n_columns)
                        val = int(float(parts[4]))
                        
                        # Apply to 2D Sink Matrix
                        # Note: numpy slicing excludes end, so v_e is correct if 0-based exclusive
                        sinks[l_s:l_e, v_s:v_e] = val
                    else:
                        # Format: start end bc_id
                        # Example: 0. 1. -99
                        s, e = cls._parse_range(parts[0], parts[1], max_dim)
                        val = int(float(parts[2]))
                        
                        # Apply to 1D Edge Array
                        target_arr[s:e] = val
                        
        except StopIteration:
            pass
            
        return cls(left=left, right=right, top=top, bottom=bottom, sinks=sinks, mass_file_id=mass_id)

    def to_file(self, filepath: str):
        """
        Writes the Boundary Conditions using run-length encoding (ranges).
        """
        def write_1d_section(f, name, array):
            blocks = self._compress_1d(array)
            f.write(f"{name}\n")
            f.write(f"{len(blocks)} 0\n") # ianz, iart=0
            
            n = len(array)
            for s, e, val in blocks:
                # Convert 0-based indices to relative (0.0 - 1.0)
                # s is start index (inclusive), e is end index (inclusive)
                # Relative: start/N, (end+1)/N
                
                start_rel = s / n
                end_rel = (e + 1) / n 
                
                # Format: s e val
                f.write(f" {start_rel:.6f} {end_rel:.6f} {val}\n")

        with open(filepath, 'w') as f:
            write_1d_section(f, "LINKS", self.left)
            write_1d_section(f, "RECHTS", self.right)
            write_1d_section(f, "OBEN", self.top)
            write_1d_section(f, "UNTEN", self.bottom)
            
            # Write Sinks (Compressed)
            # This requires 2D compression, but simple "Full Domain" is common
            # Here we check if the sink is uniform to save space
            unique_sinks = np.unique(self.sinks)
            if len(unique_sinks) == 1:
                # Uniform sink (e.g., atmospheric everywhere)
                val = unique_sinks[0]
                if val != 0: # Only write if not default 0? Or always write?
                    f.write("SENKEN\n")
                    f.write("1 0\n")
                    f.write(f" 0.000000 1.000000 0.000000 1.000000 {val}\n")
            else:
                raise NotImplementedError("SCHERE")
                # If complex sinks, simple implementation: Write 1 block for whole domain
                f.write("SENKEN\n")
                f.write("1 0\n")
                f.write(" 0.000000 1.000000 0.000000 1.000000 -99\n") # Fallback/Placeholder
            
            f.write(f"MASSE\n{self.mass_file_id}\n")

    @staticmethod
    def _parse_range(start_str: str, end_str: str, max_dim: int) -> Tuple[int, int]:
        """
        Parses range string (float relative or int absolute) to 0-based slice indices.
        """
        s = float(start_str)
        e = float(end_str)
        
        # Heuristic: If BOTH are <= 1.0, treat as relative.
        # This covers 0.0 to 1.0 cases.
        # Edge case: "1 5" (absolute) vs "0.0 1.0" (relative)
        is_relative = (s <= 1.0 and e <= 1.0) and not (s == 1.0 and e > 1.0)
        
        if is_relative:
            start = int(s * max_dim)
            end = int(e * max_dim)
            
            # Ensure non-empty slice
            if end == start: end += 1
            
            # Clamp to bounds
            start = max(0, min(start, max_dim))
            end = max(0, min(end, max_dim))
            
            return start, end
        else:
            # Absolute (1-based inclusive start, 1-based inclusive end in file)
            # Python needs 0-based inclusive start, exclusive end
            start = int(s) - 1
            end = int(e) 
            return start, end

    @staticmethod
    def _compress_1d(array: np.ndarray) -> List[Tuple[int, int, int]]:
        """Run-Length Encoding for 1D array. Returns [(start, end_inclusive, val)]"""
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

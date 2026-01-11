import numpy as np
from dataclasses import dataclass, field
from typing import Literal, Tuple, List

def parse_range(start_str: str, end_str: str, max_dim: int) -> Tuple[int, int]:
    """
    Parses start/end values. 
    If <= 1.0 (and float-like), treats as relative fraction.
    If > 1.0 (or int-like), treats as absolute node index (1-based -> 0-based).
    """
    s = float(start_str)
    e = float(end_str)
    
    # Heuristic: If values are small (<=1.0), they are relative.
    # Exception: "1." could be index 1 or 100%. 
    # Context usually implies integers for indices.
    is_absolute = (s >= 1.0 and e >= 1.0 and s.is_integer() and e.is_integer())
    
    if is_absolute:
        # Fortran 1-based index -> Python 0-based
        # "1 5" means nodes 1,2,3,4,5. Python slice [0:5]
        return int(s) - 1, int(e) 
    else:
        # Relative coordinates (0.0 - 1.0)
        start_idx = int(s * max_dim)
        end_idx = int(e * max_dim)
        # Ensure at least one cell is selected
        if end_idx == start_idx: end_idx += 1
        return start_idx, end_idx


@dataclass
class SoilWaterIC:
    data: np.ndarray # Shape: (n_columns, n_layers)
    type: Literal['PSI', 'THETA', 'PHI'] = 'PSI' 
    
    @classmethod
    def from_file(cls, path: str, n_layers: int, n_columns: int) -> 'SoilWaterIC':
        with open(path, 'r') as f:
            lines = [l.strip() for l in f if l.strip() and not l.startswith('%')]
        
        header = lines[0].split()
        
        # Pointwise/Uniform (Keyword Headers), NOT THE CASE IN MY STUFF
        if header[0] in ['PSI', 'THETA', 'PHI']:
            keyword = header[0]
            if keyword == 'PHI':
                # 1.1.1.1.3 Uniform Potential
                phi_val = float(lines[1].split()[0])
                grid = np.full((n_columns, n_layers), phi_val)
                return cls(data=grid, type='PHI')
            else:
                # 1.1.1.1.2 Pointwise Dump
                grid = np.zeros((n_columns, n_layers))
                line_idx = 1
                for v in range(n_layers):
                    # Dump is row by row
                    vals = [float(x) for x in lines[line_idx].split()]
                    grid[:, v] = vals
                    line_idx += 1
                return cls(data=grid, type=keyword)

        # NUMMERIC WHAT IS MY CASE
        else:
            # 1.1.1.1.1 Blockwise assignment
            n_lines = int(header[0])
            ischal = int(header[1]) # 0=Saturation, 1=Suction
            
            grid = np.zeros((n_columns, n_layers))
            var_type = 'PSI' if ischal == 1 else 'THETA'

            for i in range(n_lines):
                parts = lines[1+i].split()
                v_s, v_e = parse_range(parts[0], parts[1], n_layers)
                l_s, l_e = parse_range(parts[2], parts[3], n_columns)
                val = float(parts[4])
                
                grid[l_s:l_e, v_s:v_e] = val
                
            return cls(data=grid, type=var_type)
    def to_file(self, filepath: str, time: float = 0.0, hillslope_id: int = 1):
        n_cols, n_layers = self.data.shape
        
        try:
            with open(filepath, 'w') as f:
                # Format 1.1.1.1.3
                if self.type == 'PHI':
                    # Header: PHI tzeit ihg nv nl 1
                    f.write(f"PHI {time} {hillslope_id} {n_layers} {n_cols} 1\n")
                    
                    # Line 2: phi_s iart
                    # We take the value from the grid (assuming it's uniform)
                    val = self.data[0, 0]
                    # iart=0: relative to heights specified in geometry (standard default)
                    f.write(f"{val:.6f} 0\n")
                    
                # Pointwise Dump (PSI or THETA)
                # Format 1.1.1.1.2
                else:
                    # Header: KEYWORD tzeit ihg nv nl 1
                    # KEYWORD is either PSI (Suction) or THETA (Water Content)
                    keyword = self.type
                    f.write(f"{keyword} {time} {hillslope_id} {n_layers} {n_cols} 1\n")
                    
                    # Data: nv lines (vertical), each with nl columns (lateral)
                    # "The header is followed by iv=1...nv lines... Thus, the first line represents the upper boundary."
                    # This means we loop Vertical (Outer) -> Lateral (Inner)
                    
                    for v in range(n_layers):
                        # Extract the full lateral row for this vertical depth
                        # Shape of self.data is (n_cols, n_layers) -> we need slice [:, v]
                        row_data = self.data[:, v]
                        
                        # Write space-separated values
                        row_str = " ".join(f"{val:.6f}" for val in row_data)
                        f.write(row_str + "\n")
                        
        except Exception as e:
            raise IOError(f"Failed to write SoilWaterIC to {filepath}: {e}")


@dataclass
class SoluteIC:
    concentrations: np.ndarray 
    n_solutes: int

    @classmethod
    def from_file(cls, path: str, n_layers: int, n_columns: int) -> 'SoluteIC':
        with open(path, 'r') as f:
            lines = [l.strip() for l in f if l.strip() and not l.startswith('%')]
            
        header = lines[0].split()
        
        # Case A: Pointwise (Keyword "KONZ")
        if header[0] == 'KONZ':
            n_solutes = int(header[5])
            grid = np.zeros((n_solutes, n_columns, n_layers))
            line_idx = 1
            # Assuming standard dump: Blocks of rows? Or interleaved? 
            # Text implies standard dump format. Usually loop solutes -> loop vertical
            for s in range(n_solutes):
                for v in range(n_layers):
                    vals = [float(x) for x in lines[line_idx].split()]
                    grid[s, :, v] = vals
                    line_idx += 1
            return cls(concentrations=grid, n_solutes=n_solutes)

        # Case B: Blockwise Solutes (Numeric Header "2 1 2")
        else:
            # 1.1.1.2.1 Blockwise
            n_lines_per_solute = int(header[0])
            # header[1] is 'type' (relative/node), often ignored if we detect range manually
            n_solutes = int(header[2])
            
            grid = np.zeros((n_solutes, n_columns, n_layers))
            
            current_line = 1
            for s in range(n_solutes):
                # Each solute block starts with an ID line: "1" or "2"
                solute_id_line = lines[current_line]
                current_line += 1
                
                for _ in range(n_lines_per_solute):
                    parts = lines[current_line].split()
                    v_s, v_e = parse_range(parts[0], parts[1], n_layers)
                    l_s, l_e = parse_range(parts[2], parts[3], n_columns)
                    val = float(parts[4])
                    
                    grid[s, l_s:l_e, v_s:v_e] = val
                    current_line += 1
                    
            return cls(concentrations=grid, n_solutes=n_solutes)

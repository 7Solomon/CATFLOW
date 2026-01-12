import numpy as np
from dataclasses import dataclass
from typing import Literal

@dataclass
class SoilWaterIC:
    data: np.ndarray  # Shape (n_columns, n_layers)
    type: Literal['PSI', 'THETA', 'PHI'] = 'PSI'

    @classmethod
    def from_file(cls, path: str, n_layers: int, n_columns: int) -> 'SoilWaterIC':
        data = np.zeros((n_columns, n_layers))
        ic_type = 'PSI' # Default

        with open(path, 'r') as f:
            lines = [l.strip() for l in f if l.strip() and not l.startswith('#')]
        
        if not lines:
            return cls(data, ic_type)

        header_parts = lines[0].split()
        keyword = header_parts[0].upper()

        # --- FORMAT 1: Pointwise Dump (PSI / THETA / PHI) ---
        if keyword in ['PSI', 'THETA', 'PHI']:
            ic_type = keyword
            # Header: KEYWORD time hill_id nv nl 1
            # Data follows
            
            # Read all tokens
            tokens = []
            for line in lines[1:]:
                tokens.extend([float(x) for x in line.split()])
                
            # If PHI (Uniform potential usually has just 1 line with value?)
            # Manual says: "PHI ... followed by iv=1...nv lines" OR "PHI ... line 2: val, iart"
            if keyword == 'PHI' and len(tokens) <= 2:
                # Uniform Potential
                val = tokens[0]
                data.fill(val)
            else:
                # Full matrix
                idx = 0
                for v in range(n_layers):
                    for l in range(n_columns):
                        if idx < len(tokens):
                            data[l, v] = tokens[idx]
                            idx += 1

        # --- FORMAT 2: Blockwise (Numeric Header) ---
        else:
            # Header: n_lines ischal (0=Sat/1=Suction) dummy
            n_lines = int(header_parts[0])
            ischal = int(header_parts[1]) if len(header_parts) > 1 else 1
            
            # Determine type based on ischal
            # 0 = Saturation -> THETA (technically Degree of Saturation, but maps to THETA space)
            # 1 = Suction -> PSI
            ic_type = 'THETA' if ischal == 0 else 'PSI'
            
            for i in range(n_lines):
                if i + 1 >= len(lines): break
                parts = lines[i+1].split()
                
                # Format: v_s v_e l_s l_e value
                v_s, v_e = cls._parse_range(parts[0], parts[1], n_layers)
                l_s, l_e = cls._parse_range(parts[2], parts[3], n_columns)
                val = float(parts[4])
                
                data[l_s:l_e, v_s:v_e] = val
                
        return cls(data, type=ic_type)

    @staticmethod
    def _parse_range(s_str, e_str, dim):
        s_val = float(s_str)
        e_val = float(e_str)
        
        # Robust Logic:
        # If input looks like "1.0 5.0" -> Absolute
        # If input looks like "0.0 1.0" -> Relative
        # If input looks like "1 5" -> Absolute
        
        is_relative = (s_val <= 1.0 and e_val <= 1.0) and not (s_val == 1.0 and e_val > 1.0)
        
        if is_relative:
            start = int(s_val * dim)
            end = int(e_val * dim)
            if end == start: end += 1
            return start, end
        else:
            return int(s_val) - 1, int(e_val)

    def to_file(self, filepath: str, time=0.0, hill_id=1):
        """Writes as Pointwise Dump (PSI/THETA)"""
        n_cols, n_layers = self.data.shape
        
        with open(filepath, 'w') as f:
            # Header: TYPE time hill nv nl 1
            f.write(f"{self.type} {time} {hill_id} {n_layers} {n_cols} 1\n")
            
            for v in range(n_layers):
                row_vals = []
                for l in range(n_cols):
                    # Format float nicely
                    row_vals.append(f"{self.data[l, v]:.6g}")
                f.write(" ".join(row_vals) + "\n")



@dataclass
class SoluteIC:
    concentrations: np.ndarray # (n_solutes, n_cols, n_layers)
    
    @classmethod
    def from_file(cls, path: str, n_layers: int, n_columns: int) -> 'SoluteIC':
        # We don't know N solutes initially, list approach
        temp_grids = []
        
        with open(path, 'r') as f:
            lines = [l.strip() for l in f if l.strip()]
            
        if not lines: return cls(np.array([]))

        # Check header
        parts = lines[0].split()
        
        # KEYWORD KONZ (Pointwise)
        if parts[0].upper() == 'KONZ':
            n_solutes = int(parts[5]) # Header: KONZ time hill nv nl n_solutes
            data = np.zeros((n_solutes, n_columns, n_layers))
            
            # Read tokens
            tokens = []
            for line in lines[1:]:
                tokens.extend([float(x) for x in line.split()])
                
            idx = 0
            for s in range(n_solutes):
                for v in range(n_layers):
                    for l in range(n_columns):
                        if idx < len(tokens):
                            data[s, l, v] = tokens[idx]
                            idx += 1
            return cls(data)
            
        # BLOCKWISE (e.g. "2 1 2" -> 2 lines, ?, 2 solutes)
        else:
            # Header logic is tricky for solutes, usually:
            # n_lines mode n_solutes
            try:
                n_lines_per_solute = int(parts[0])
                n_solutes = int(parts[2])
            except:
                n_solutes = 1 # Fallback
                n_lines_per_solute = int(parts[0])
                
            data = np.zeros((n_solutes, n_columns, n_layers))
            current_line = 1
            
            for s in range(n_solutes):
                # Usually there's a solute header line: "1" (Solute ID)
                if current_line < len(lines) and len(lines[current_line].split()) == 1:
                     current_line += 1
                
                for _ in range(n_lines_per_solute):
                    if current_line >= len(lines): break
                    p = lines[current_line].split()
                    current_line += 1
                    
                    v_s, v_e = SoilWaterIC._parse_range(p[0], p[1], n_layers)
                    l_s, l_e = SoilWaterIC._parse_range(p[2], p[3], n_columns)
                    val = float(p[4])
                    data[s, l_s:l_e, v_s:v_e] = val
                    
            return cls(data)

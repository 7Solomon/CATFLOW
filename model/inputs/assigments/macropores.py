from dataclasses import dataclass
import numpy as np

@dataclass
class MacroporeDef:
    # Matrix of macropore factors (1.0 = no macropores)
    factor_matrix: np.ndarray
    
    @classmethod
    def from_file(cls, path: str, n_layers: int, n_columns: int) -> 'MacroporeDef':
        matrix = np.ones((n_layers, n_columns))
        
        with open(path, 'r') as f:
            lines = [l.strip() for l in f if l.strip()]
            
        header_line = lines[0]
        
        # Check for Matrix Mode ('D' header)
        if header_line.upper().startswith('D'):
            # Matrix Mode: Header, Method, then Rows
            # Skip header and method line ('ari')
            start_idx = 2 
            
            # Read rows top-to-bottom
            # CATFLOW loops: do iv = iacnv, 1, -1
            for r in range(n_layers - 1, -1, -1):
                if start_idx >= len(lines): break
                row_vals = list(map(float, lines[start_idx].split()))
                matrix[r, :len(row_vals)] = row_vals
                start_idx += 1
                
        else:
            # Block Mode (Legacy logic you had)
            header = header_line.split()
            n_blocks = int(header[0])
            mode = int(header[1]) # 0=Relative
            start_idx = 2
            
            for i in range(n_blocks):
                if start_idx + i >= len(lines): break
                parts = lines[start_idx + i].split()
                
                v1, v2 = float(parts[0]), float(parts[1])
                h1, h2 = float(parts[2]), float(parts[3])
                v_mak = float(parts[4])
                
                if mode == 0:
                    r_start = int(v1 * n_layers)
                    r_end = int(v2 * n_layers)
                    c_start = int(h1 * n_columns)
                    c_end = int(h2 * n_columns)
                    
                    # Clamp
                    r_end = min(r_end, n_layers)
                    c_end = min(c_end, n_columns)
                    
                    matrix[r_start:r_end, c_start:c_end] = v_mak
                    
        return cls(factor_matrix=matrix)

    def to_file(self, filepath: str):
        """
        Writes Macropore definition using 'D' (Direct/Matrix) mode.
        """
        rows, cols = self.factor_matrix.shape
        
        # Header params: amakh=1.0, b_makh=1.0, m_aniso=1
        # CATFLOW parser reads these starting at column 7.
        # "D" + 6 spaces puts the numbers exactly where Fortran expects them.
        header = "D      1.0 1.0 1"
        method = "ari"
        
        with open(filepath, 'w') as f:
            f.write(f"{header}\n")
            f.write(f"{method}\n")
            
            # CATFLOW reads top-to-bottom (iv=iacnv -> 1)
            for r in range(rows - 1, -1, -1):
                row_data = self.factor_matrix[r, :]
                f.write(" ".join([f"{v:.4f}" for v in row_data]) + "\n")

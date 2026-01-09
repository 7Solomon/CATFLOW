import numpy as np
from dataclasses import dataclass, field
from typing import List, Optional

@dataclass
class InitialState:
    # We store the final expanded matrix (e.g., Saturation or Suction Head)
    # The file defines HOW to set it, but for a loaded project, 
    # the matrix is the most useful form.
    values: np.ndarray 
    type_id: str = "THETA" # "THETA" (Saturation) or "PSI" (Suction Head)

    @classmethod
    def from_file(cls, path: str, n_layers: int, n_columns: int) -> 'InitialState':
        values = np.zeros((n_layers, n_columns))
        
        with open(path, 'r') as f:
            lines = [l.strip() for l in f if l.strip()]
        
        # Line 1: 2 0 0 
        header = lines[0].split()
        file_type = int(header[0]) # 2 = Block
        coord_mode = int(header[1]) # 0 = Relative
        val_type = int(header[2]) # 0 = Theta (Sat), 1 = Psi (Suction)
        
        type_str = "PSI" if val_type == 1 else "THETA"

        if file_type == 2: # Block format
             # Loop through blocks
            for line in lines[1:]:
                # skip comments
                if '%' in line: line = line.split('%')[0]
                if not line.strip(): continue
                
                parts = list(map(float, line.split()))
                if len(parts) < 5: continue
                
                v1, v2, h1, h2, val = parts[0], parts[1], parts[2], parts[3], parts[4]
                
                if coord_mode == 0:
                    r_start = int(v1 * n_layers)
                    r_end = int(v2 * n_layers)
                    c_start = int(h1 * n_columns)
                    c_end = int(h2 * n_columns)
                    
                    # Clamp
                    r_end = min(r_end, n_layers)
                    c_end = min(c_end, n_columns)
                    
                    values[r_start:r_end, c_start:c_end] = val
                else:
                    values[int(v1):int(v2), int(h1):int(h2)] = val
                    
        return cls(values=values, type_id=type_str)
    
    def to_file(self, filepath: str):
        """
        Writes initial conditions matrix.
        Format:
        THETA (or PSI)
              0.0 <hill_id> <rows> <cols>
        <Row N (top)>
        ...
        """
        rows, cols = self.values.shape
        hill_id = 1
        
        with open(filepath, 'w') as f:
            # Valid headers: THETA or PSI (Must be 5 chars usually, or spaced)
            header = f"{self.type_id:<5}" 
            f.write(f"{header}\n")
            # Time=0.0, Hill, Rows, Cols
            f.write(f"      0.00 {hill_id} {rows} {cols}\n")
            
            # CATFLOW reads: do iv = iacnv, 1, -1 (Top to Bottom)
            for r in range(rows - 1, -1, -1):
                row_data = self.values[r, :]
                # Format floats
                f.write(" ".join([f"{v:.4f}" for v in row_data]) + "\n")

from dataclasses import dataclass

import numpy as np


@dataclass
class SoilAssignment:
    # The result is a matrix of Integer IDs matching mesh dimensions
    assignment_matrix: np.ndarray 

    @classmethod
    def from_file(cls, path: str, n_layers: int, n_columns: int) -> 'SoilAssignment':
        # Initialize with default 0 or -1
        matrix = np.zeros((n_layers, n_columns), dtype=int)
        
        with open(path, 'r') as f:
            line1 = f.readline().split()
            if not line1: return cls(matrix)
            
            # Helper to check if line is header or block
            # Sometimes file starts with comment char or string
            
            n_blocks = int(line1[0])
            mode = int(line1[1]) # 0 = Relative (0.0-1.0), 1 = Indices
            
            for _ in range(n_blocks):
                line = f.readline()
                while line and (line.strip().startswith('%') or not line.strip()):
                    line = f.readline() # Skip comments
                
                parts = line.split()
                # Format: v_start v_end h_start h_end soil_id
                v1, v2, h1, h2, soil_id = float(parts[0]), float(parts[1]), float(parts[2]), float(parts[3]), int(parts[4])
                
                if mode == 0:
                    # Fortran 1-based: int(eta * (iacnv-1)) + 1
                    # Python 0-based: int(eta * (iacnv-1))
                    r_start = int(v1 * (n_layers - 1))
                    r_end = int(v2 * (n_layers - 1))
                    c_start = int(h1 * (n_columns - 1))
                    c_end = int(h2 * (n_columns - 1))
                                    
                    matrix[r_start:r_end, c_start:c_end] = soil_id
                    
                else:
                    # Direct indices
                    matrix[int(v1):int(v2), int(h1):int(h2)] = soil_id

        return cls(assignment_matrix=matrix)
    
    def to_file(self, filepath: str):
        rows, cols = self.assignment_matrix.shape
        hill_id = 1
        
        with open(filepath, 'w') as f:
            # "BLOCK " is 6 chars, so the numbers start at the 7th char (Fortran standard)
            f.write(f"BLOCK {rows} {cols} {hill_id}\n")

            # CATFLOW reads: do iv = iacnv, 1, -1 (Top to Bottom)
            for r in range(rows - 1, -1, -1):
                row_data = self.assignment_matrix[r, :]
                f.write(" ".join(map(str, row_data)) + "\n")

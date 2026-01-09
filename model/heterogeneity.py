from dataclasses import dataclass

import numpy as np


@dataclass
class HeterogeneityMap:
    # Matrix of scaling factors (multiplying the soil property)
    factors: np.ndarray 
    
    @classmethod
    def from_file(cls, path: str) -> 'HeterogeneityMap':
        with open(path, 'r') as f:
            lines = [l.strip() for l in f if l.strip()]
            
        # Line 1: -1001 15 15
        header = lines[0].split()
        # You could validate dimensions here: header[1]==rows, header[2]==cols
        
        # Determine matrix size from header
        rows = int(header[1])
        cols = int(header[2])
        
        data_values = []
        for line in lines[1:]:
            data_values.extend(map(float, line.split()))
            
        # Reshape into matrix
        # Note: Fortran output is usually row-major or column-major depending on the write loop.
        # 15 lines of 15 numbers -> straightforward row-by-row mapping, may difrent but currently work!
        
        matrix = np.array(data_values).reshape((rows, cols))
        
        return cls(factors=matrix)

    def to_file(self, filepath: str):
        rows, cols = self.factors.shape
        hill_id = -1001 # Standard legacy ID found in files
        
        with open(filepath, 'w') as f:
            f.write(f"{hill_id} {rows} {cols}\n")
            
            # CATFLOW reads: do iv = iacnv, 1, -1 (Top to Bottom)
            for r in range(rows - 1, -1, -1):
                row_data = self.factors[r, :]
                f.write(" ".join([f"{v:.3f}" for v in row_data]) + "\n")
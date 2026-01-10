import numpy as np
from dataclasses import dataclass
from typing import Optional

@dataclass
class HeterogeneityMap:
    # Matrix of scaling factors (multiplying the soil property)
    # Internal Storage: Index 0 = Bottom Layer, Index N-1 = Top Layer
    factors: np.ndarray 
    
    @classmethod
    def from_file(cls, path: str, n_layers: Optional[int] = None, n_columns: Optional[int] = None) -> 'HeterogeneityMap':
        with open(path, 'r') as f:
            lines = [l.strip() for l in f if l.strip()]
            
        if not lines:
            # Return empty or default if file is empty, though usually this should error
            if n_layers and n_columns:
                return cls(factors=np.ones((n_layers, n_columns)))
            raise ValueError(f"File {path} is empty")

        # Line 1: HillID Rows Cols (e.g., "-1001 15 15")
        header = lines[0].split()
        if len(header) < 3:
             raise ValueError(f"Invalid header in {path}: {lines[0]}")
             
        rows_in_file = int(header[1])
        cols_in_file = int(header[2])
        
        # --- FIX 1: Validation Logic ---
        # Ensure the file dimensions match the physics mesh
        if n_layers is not None and rows_in_file != n_layers:
            raise ValueError(f"Heterogeneity Map Mismatch: File has {rows_in_file} layers, expected {n_layers}.")
        
        if n_columns is not None and cols_in_file != n_columns:
            raise ValueError(f"Heterogeneity Map Mismatch: File has {cols_in_file} columns, expected {n_columns}.")
        
        # Parse Data
        data_values = []
        for line in lines[1:]:
            data_values.extend(map(float, line.split()))
            
        # Reshape into matrix
        # The file is stored Top-to-Bottom (Line 1 = Top Layer).
        # numpy.reshape fills row 0 first.
        # So matrix_raw[0] contains the TOP layer data.
        matrix_raw = np.array(data_values).reshape((rows_in_file, cols_in_file))
        
        # --- FIX 2: Orientation Correction ---
        # Our internal standard (and to_file) assumes Index 0 = Bottom.
        # Since matrix_raw[0] is Top, we must flip it upside down.
        matrix = np.flipud(matrix_raw)
        
        return cls(factors=matrix)

    def to_file(self, filepath: str):
        rows, cols = self.factors.shape
        hill_id = -1001 # Standard legacy ID found in files
        
        with open(filepath, 'w') as f:
            f.write(f"{hill_id} {rows} {cols}\n")
            
            # CATFLOW reads: do iv = iacnv, 1, -1 (Top to Bottom)
            # This loop writes index (rows-1) first.
            # Since we flipped on load, index (rows-1) correctly represents the Top Layer.
            for r in range(rows - 1, -1, -1):
                row_data = self.factors[r, :]
                f.write(" ".join([f"{v:.3f}" for v in row_data]) + "\n")

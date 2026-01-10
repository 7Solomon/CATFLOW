import numpy as np
from dataclasses import dataclass
from typing import List, Optional

@dataclass
class InitialState:
    # We store the final expanded matrix as Suction Head (PSI)
    values: np.ndarray 
    type_id: str = "PSI" # Default to PSI to avoid saturation crashes

    @classmethod
    def from_file(cls, path: str, n_layers: int, n_columns: int) -> 'InitialState':
        values = np.zeros((n_layers, n_columns))
        
        with open(path, 'r') as f:
            lines = [l.strip() for l in f if l.strip()]
        
        if not lines:
            return cls(values=values)

        header = lines[0].split()
        
        # Detect legacy formats
        # Standard Matrix: "PSI" or "THETA"
        # Block Mode: "2 0 0" (NumBlocks, CoordMode, ValType)  which currently but VERY FUCKING BAD!!!
        
        is_block_mode = False
        is_relative_sat = False
        coord_mode = 0 # 0=Relative, 1=Absolute
        
        if header[0].isdigit():
            # It's Block Mode (e.g. "2 0 0")
            is_block_mode = True
            n_blocks = int(header[0])
            coord_mode = int(header[1])
            val_type = int(header[2]) # 0=RelSat/Theta, 1=Psi
            
            # If val_type is 0 in block mode, it usually means Relative Saturation (0-1)
            if val_type == 0:
                is_relative_sat = True
                type_str = "THETA" # Temporarily track as theta
            else:
                type_str = "PSI"
        else:
            # It's Matrix Mode (e.g. "PSI  ...")
            type_str = header[0].strip()
            # If it was matrix mode THETA, it's usually Absolute Water Content, not Relative.

        # --- PARSING ---
        if is_block_mode:
            # Loop through blocks
            current_line = 1
            for _ in range(n_blocks):
                while current_line < len(lines):
                    line = lines[current_line]
                    if '%' in line: line = line.split('%')[0]
                    if not line.strip(): 
                        current_line += 1
                        continue
                    
                    parts = list(map(float, line.split()))
                    current_line += 1
                    
                    if len(parts) < 5: continue
                    
                    v1, v2, h1, h2, val = parts[0], parts[1], parts[2], parts[3], parts[4]
                    
                    if coord_mode == 0: # Relative Coords (0.0 - 1.0)
                        r_start = int(v1 * n_layers)
                        r_end = int(v2 * n_layers)
                        c_start = int(h1 * n_columns)
                        c_end = int(h2 * n_columns)
                    else: # Absolute Coords (Indices)
                        r_start = int(v1)
                        r_end = int(v2)
                        c_start = int(h1)
                        c_end = int(h2)
                    
                    # Clamp indices
                    r_start = max(0, r_start)
                    c_start = max(0, c_start)
                    r_end = min(r_end, n_layers)
                    c_end = min(c_end, n_columns)
                    
                    values[r_start:r_end, c_start:c_end] = val
                    break
        else:
            # Matrix Mode Parsing (Simple row-by-row)
            # Skip header line, read rest
            row_idx = n_layers - 1 # CATFLOW writes top-to-bottom
            for line in lines[1:]:
                if row_idx < 0: break
                parts = list(map(float, line.split()))
                # Fill as much of the row as provided
                cols_to_fill = min(len(parts), n_columns)
                values[row_idx, :cols_to_fill] = parts[:cols_to_fill]
                row_idx -= 1

        # --- CONVERSION LOGIC ---
        # If we read "Relative Saturation" (0.0 to 1.0), we MUST convert it 
        # to PSI because we cannot safely write it back as THETA (absolute).
        
        final_type = type_str
        
        if is_relative_sat:
            # Heuristic Conversion: RelSat -> PSI
            # 1.0 (Sat) -> 0.0 m
            # 0.9       -> -0.5 m (Just a guess to keep it unsaturated)
            # 0.0 (Dry) -> -100.0 m
            
            # Simple Linear mapping: PSI = (RelSat - 1.0) * Scale
            # You can adjust this scaling factor (-50.0) to represent your soil dryness
            values = (values - 1.0) * 50.0 
            
            # Ensure saturation is exactly 0.0 PSI
            values[values > 0] = 0.0
            
            final_type = "PSI"
            print("HERE COULD BE NOT SO GOOD!!!! SCALE FACTOR USED")

        return cls(values=values, type_id=final_type)
    
    def to_file(self, filepath: str):
        """
        Writes initial conditions matrix in PSI format.
        This is the safest format for CATFLOW to avoid singularity crashes.
        """
        rows, cols = self.values.shape
        hill_id = 1
        
        with open(filepath, 'w') as f:
            # Writes: "PSI   0.00 1 <rows> <cols>"
            # The header MUST be padded to 5 or 6 chars to work with Fortran
            f.write(f"{self.type_id:<6} 0.00 {hill_id} {rows} {cols}\n")
            
            # CATFLOW reads: do iv = iacnv, 1, -1 (Top to Bottom)
            for r in range(rows - 1, -1, -1):
                row_data = self.values[r, :]
                f.write(" ".join([f"{v:.4f}" for v in row_data]) + "\n")

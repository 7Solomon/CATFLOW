import numpy as np
from dataclasses import dataclass

@dataclass
class HillslopeMesh:
    n_layers: int   # iacnv (vertical nodes)
    n_columns: int  # iacnl (horizontal nodes)
    hill_id: int
    
    # Coordinates for every node (n_layers, n_columns)
    # Storing as 2D arrays matches the Fortran structure (iv, il)
    x_nodes: np.ndarray 
    z_nodes: np.ndarray 

    def _calculate_metric_factors(self):
        """Calculate f_eta, f_xsi from coordinate differences"""
        f_eta = np.zeros((self.n_layers, self.n_columns))
        f_xsi = np.zeros((self.n_layers, self.n_columns))
        
        for r in range(self.n_layers):
            for c in range(self.n_columns):
                # f_xsi: horizontal spacing (Metric factor along Xi)
                if c < self.n_columns - 1:
                    dx = self.x_nodes[r, c+1] - self.x_nodes[r, c]
                    dz = self.z_nodes[r, c+1] - self.z_nodes[r, c]
                    f_xsi[r, c] = np.sqrt(dx**2 + dz**2)
                elif c > 0:
                    # Copy from previous neighbor for boundary
                    f_xsi[r, c] = f_xsi[r, c-1]
                
                # f_eta: vertical spacing (Metric factor along Eta)
                if r < self.n_layers - 1:
                    dx = self.x_nodes[r+1, c] - self.x_nodes[r, c]
                    dz = self.z_nodes[r+1, c] - self.z_nodes[r, c]
                    f_eta[r, c] = np.sqrt(dx**2 + dz**2)
                elif r > 0:
                    # Copy from previous neighbor for boundary
                    f_eta[r, c] = f_eta[r, c-1]
                    
        return f_eta, f_xsi
        
    @classmethod
    def from_file(cls, path: str) -> 'HillslopeMesh':
        with open(path, 'r') as f:
            lines = [l.strip() for l in f if l.strip()]
            
        # Line 1: 15 15 0.0 1
        parts = lines[0].split()
        iacnv = int(parts[0])  # Layers (rows)
        iacnl = int(parts[1])  # Columns
        hill_id = int(parts[3])
        
        # Skip header lines (Line 2, 3)
        # Skip Block 1 (eta values) -> iacnv lines
        # Skip Block 2 (xsi values) -> iacnl lines
        
        # The main data block starts after: 3 (header) + iacnv + iacnl
        start_idx = 3 + iacnv + iacnl
        
        x_grid = np.zeros((iacnv, iacnl))
        z_grid = np.zeros((iacnv, iacnl))
        
        # Fortran loop order in rdhang:
        # do 110 il = 1,iacnl
        #   do 100 iv = 1,iacnv
        #     read... hko, sko...
        
        current_line = start_idx
        for col in range(iacnl):
            for row in range(iacnv):
                if current_line >= len(lines): break
                
                # Data line: 1169.8128 0.0000 5.71 ...
                # Parts: hko(z), sko(x), ...
                val_parts = lines[current_line].split()
                z = float(val_parts[0])
                x = float(val_parts[1])
                
                x_grid[row, col] = x
                z_grid[row, col] = z
                
                current_line += 1
                
        return cls(n_layers=iacnv, n_columns=iacnl, hill_id=hill_id, x_nodes=x_grid, z_nodes=z_grid)

    def to_file(self, filepath: str):
        """
        Reconstructs a legacy .geo file.
        """
        rows, cols = self.n_layers, self.n_columns
        w_fix = 0.0
        hill_id = self.hill_id
        
        with open(filepath, 'w') as f:
            # Header
            f.write(f"{rows} {cols} {w_fix:.4f} {hill_id}\n")
            
            # Ref Coords (Dummy 0,0,0)
            f.write("0.00 0.00 0.00\n")
            
            # Surface Stats
            length = self.x_nodes[-1, -1] - self.x_nodes[-1, 0]
            width = 1.0 
            slope = 0.0 
            f.write(f"{length:.2f} {width:.2f} {slope:.2f}\n")
            
            # Block 1: Eta vector (Vertical relative)
            for r in range(rows):
                # Avoid division by zero
                denom = (rows - 1) if rows > 1 else 1
                f.write(f"{r/denom:.8f}\n")
                
            # Block 2: Xsi vector + Surface Coords
            for c in range(cols):
                denom = (cols - 1) if cols > 1 else 1
                xsi = c / denom
                
                # Top node (row=rows-1) coords
                top_x = self.x_nodes[rows-1, c]
                top_z = self.z_nodes[rows-1, c]
                # Bottom node
                bot_x = self.x_nodes[0, c]
                bot_z = self.z_nodes[0, c]
                
                f.write(f"{xsi:.8f} {top_x:.4f} {top_z:.4f} {bot_x:.4f} {bot_z:.4f} 1.0\n")

            # --- FIX: Calculate factors ONCE outside the loop ---
            f_eta_grid, f_xsi_grid = self._calculate_metric_factors()

            # Block 3: Full Grid Loop
            # CATFLOW Loop: do il=1,iacnl; do iv=1,iacnv
            for c in range(cols):
                for r in range(rows):
                    z = self.z_nodes[r, c] # hko
                    x = self.x_nodes[r, c] # sko
                    
                    f_eta_val = f_eta_grid[r, c]
                    f_xsi_val = f_xsi_grid[r, c]

                    w_xsho = 0.0
                    w_hohr = 0.0
                    iboden = 1 
                    
                    # Now f_eta_val is a float, so :.2f works
                    f.write(f"{z:.4f} {x:.4f} {f_eta_val:.2f} {f_xsi_val:.2f} {w_xsho:.2f} {w_hohr:.2f} {iboden}\n")

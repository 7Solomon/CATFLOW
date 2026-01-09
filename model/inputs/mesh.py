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
                # Data line: 1169.8128 0.0000 5.71 ...
                # Parts: hko(z), sko(x), ...
                # Note: Fortran often stores Z as 'hko' (Height Coordinate)
                val_parts = lines[current_line].split()
                z = float(val_parts[0])
                x = float(val_parts[1])
                
                # Assign to grid (Python: row, col)
                # Note: iv=1 is usually surface or bottom depending on convention.
                # In CATFLOW rdhang: loop 1..iacnv. 
                x_grid[row, col] = x
                z_grid[row, col] = z
                
                current_line += 1
                
        return cls(n_layers=iacnv, n_columns=iacnl, hill_id=hill_id, x_nodes=x_grid, z_nodes=z_grid)

    def to_file(self, filepath: str):
        """
        Reconstructs a legacy .geo file.
        WARNING: Generates DUMMY values for internal coordinate system (eta/xsi)
        and angular parameters, as these are not stored in the class.
        This allows the file to be read, but advanced curvature features may be lost.
        """
        rows, cols = self.n_layers, self.n_columns
        w_fix = 0.0
        hill_id = self.hill_id
        
        with open(filepath, 'w') as f:
            # Header
            f.write(f"{rows} {cols} {w_fix:.4f} {hill_id}\n")
            
            # Ref Coords (Dummy 0,0,0)
            f.write("0.00 0.00 0.00\n")
            
            # Surface Stats (Dummy Length/Width)
            # Calculated from top layer
            length = self.x_nodes[-1, -1] - self.x_nodes[-1, 0]
            width = 1.0 # Unit width
            slope = 0.0 # Dummy
            f.write(f"{length:.2f} {width:.2f} {slope:.2f}\n")
            
            # Block 1: Eta vector (Vertical relative)
            # 0.0 to 1.0
            for r in range(rows):
                f.write(f"{r/(rows-1):.8f}\n")
                
            # Block 2: Xsi vector + Surface Coords
            # Loop Columns
            for c in range(cols):
                xsi = c / (cols - 1)
                # xko(nv,il), yko(nv,il), xko(il), yko(il), varbr
                # Top node (row=rows-1) coords
                top_x = self.x_nodes[rows-1, c]
                top_z = self.z_nodes[rows-1, c]
                # Assuming simple vertical profile for bottom node
                bot_x = self.x_nodes[0, c]
                bot_z = self.z_nodes[0, c]
                
                f.write(f"{xsi:.8f} {top_x:.4f} {top_z:.4f} {bot_x:.4f} {bot_z:.4f} 1.0\n")

            # Block 3: Full Grid Loop
            # CATFLOW Loop: do il=1,iacnl; do iv=1,iacnv
            for c in range(cols):
                for r in range(rows):
                    z = self.z_nodes[r, c] # hko
                    x = self.x_nodes[r, c] # sko
                    
                    # Dummy params for internal curvilinear coords
                    f_eta = 1.0
                    f_xsi = 1.0
                    w_xsho = 0.0
                    w_hohr = 0.0
                    iboden = 1 # Default, will be overwritten by .bod file anyway
                    
                    f.write(f"{z:.4f} {x:.4f} {f_eta:.2f} {f_xsi:.2f} {w_xsho:.2f} {w_hohr:.2f} {iboden}\n")
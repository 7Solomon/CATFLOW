import numpy as np
from dataclasses import dataclass

@dataclass
class SurfaceAssignment:
    landuse_ids: np.ndarray
    climate_ids: np.ndarray
    
    
    @classmethod
    def from_file(cls, path: str, n_columns: int) -> 'SurfaceAssignment':
        """
        Reads surface.pob. Raises ValueError if file is invalid/empty.
        """
        lu_ids = np.zeros(n_columns, dtype=int)
        clim_ids = np.zeros(n_columns, dtype=int)
        
        try:
            with open(path, 'r') as f:
                lines = [l.strip() for l in f if l.strip()]
            
            if not lines:
                raise ValueError("File is empty")

            # Parse Header: "Count Type Mode"
            header = lines[0].split()
            count = int(header[0])
            mode = int(header[2]) if len(header) > 2 else 0
            
            data_lines = [l for l in lines[1:] if not l.startswith('#')]
            
            if count == 0 or not data_lines:
                raise ValueError("Header specifies 0 points or no data found")

            # Reading Logic
            # Case A: Full Dense Data (Legacy/Generated)
            if count >= n_columns:
                for i in range(min(count, n_columns)):
                    parts = data_lines[i].split()
                    offset = 1 if mode == 1 else 0 # Mode 1 starts with NodeID
                    
                    if len(parts) > offset + 1:
                        lu_ids[i] = int(parts[offset])
                        clim_ids[i] = int(parts[offset + 1])
            
            # Case B: Sparse Anchor Points (Interpolation)
            else:
                indices = []
                lus = []
                clims = []
                
                for i in range(count):
                    parts = data_lines[i].split()
                    
                    if mode == 1: # Explicit Index
                        idx = int(parts[0]) - 1 
                        lu = int(parts[1])
                        clim = int(parts[2])
                    else: # Implicit Index
                        idx = int(i * (n_columns - 1) / (count - 1)) if count > 1 else 0
                        lu = int(parts[0])
                        clim = int(parts[1])
                    
                    indices.append(idx)
                    lus.append(lu)
                    clims.append(clim)
                
                # Interpolate (Forward Fill segments)
                current_idx = 0
                for i in range(len(indices)):
                    next_idx = indices[i+1] if i < len(indices)-1 else n_columns
                    lu_ids[current_idx:next_idx] = lus[i]
                    clim_ids[current_idx:next_idx] = clims[i]
                    current_idx = next_idx

        except Exception as e:
            raise ValueError(f"Failed to read surface.pob: {e}")
            
        return cls(landuse_ids=lu_ids, climate_ids=clim_ids)
    
    def to_file(self, filepath: str):
        """
        Writes surface assignments using the SAFE format (MAXFIX=3).
        """
        n_nodes = len(self.landuse_ids)
        if n_nodes == 0:
            raise ValueError("No data to write")

        # Get Representative Values (Start, Middle, End)
        idx_mid = n_nodes // 2
        
        # Data tuples (LU, Clim)
        p1 = (self.landuse_ids[0], self.climate_ids[0])
        p2 = (self.landuse_ids[idx_mid], self.climate_ids[idx_mid])
        p3 = (self.landuse_ids[-1], self.climate_ids[-1])
        
        wind_str = "1.00" # HERE ALSO BE CAREFULLTHIS IS VAR AGAIN
        
        with open(filepath, 'w') as f:
            # Header: 3 Points, 1 RainID (IFIXOB), 0 Mode
            f.write("3 1 0\n") 
            f.write("# Schlag-Id Clima-Id Niederschlag-Id Windrichtungsfaktoren\n")
            
            # Write 3 anchor points
            f.write(f"{p1[0]} {p1[1]} 1 {wind_str}\n")
            f.write(f"{p2[0]} {p2[1]} 1 {wind_str}\n")
            f.write(f"{p3[0]} {p3[1]} 1 {wind_str}\n")
            
            # Padding to avoid EOF
            f.write("\n\n")

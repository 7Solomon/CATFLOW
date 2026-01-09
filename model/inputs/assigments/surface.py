from dataclasses import dataclass
import numpy as np


@dataclass
class SurfaceAssignment:
    # 1D arrays matching n_columns
    landuse_ids: np.ndarray
    climate_ids: np.ndarray
    
    @classmethod
    def from_file(cls, path: str, n_columns: int) -> 'SurfaceAssignment':
        lu_ids = np.zeros(n_columns, dtype=int)
        clim_ids = np.zeros(n_columns, dtype=int)
        
        with open(path, 'r') as f:
            lines = [l.strip() for l in f if l.strip()]
        
        # Skip headers (usually 2 lines: counts and comment)
        data_start = 0
        for i, line in enumerate(lines):
            if line.startswith('#') or i == 0:
                continue
            # Check if line looks like data
            if len(line.split()) >= 3:
                data_start = i
                break
        
        # Read n_columns lines
        count = 0
        for i in range(data_start, len(lines)):
            if count >= n_columns: break
            
            parts = lines[i].split()
            # 33 1 1 ... -> LandUseID, ClimateID, RainID
            lu_ids[count] = int(parts[0])
            clim_ids[count] = int(parts[1])
            count += 1
            
        return cls(landuse_ids=lu_ids, climate_ids=clim_ids)
    
    def to_file(self, filepath: str):
        """
        Writes surface assignments.
        Format:
        <Count> <dummy> <dummy>
        # Header
        LU_ID Clim_ID Rain_ID WindFactors...
        """
        count = len(self.landuse_ids)
        
        with open(filepath, 'w') as f:
            f.write(f"{count} 4 0\n")
            f.write("# Schlag-Id Clima-Id Niederschlag-Id Windrichtungsfaktoren\n")
            
            for i in range(count):
                lu = self.landuse_ids[i]
                clim = self.climate_ids[i]
                # Assuming RainID=1 and WindFactors=1.0 as default if not stored
                f.write(f"{lu} {clim} 1 1.00 1.00 1.00 1.00\n")
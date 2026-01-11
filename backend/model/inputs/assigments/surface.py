from typing import Any, Dict, List
import numpy as np
from dataclasses import dataclass, field

@dataclass
class SurfaceAssignment:
    landuse_ids: np.ndarray
    climate_ids: np.ndarray
    # Store extra columns (wind/horizon) as raw strings to avoid parsing complex physics ????
    extra_data_lines: List[str] = field(default_factory=list)
    
    header_def: Dict[str, Any] = field(default_factory=lambda: {
        "n_attr_class": 3, 
        "n_wind_dir": 1, 
        "n_horizon": 0,
        "mode": 0
    })

    @classmethod
    def from_file(cls, path: str, n_columns: int) -> 'SurfaceAssignment':
        lu_ids = np.zeros(n_columns, dtype=int)
        clim_ids = np.zeros(n_columns, dtype=int)
        extra_data = []
        
        try:
            with open(path, 'r') as f:
                lines = [l.strip() for l in f if l.strip()]
            
            if not lines:
                raise ValueError("File is empty")

            # Parse Header "3.0 4.0 0.0" zu, n_attr, n_wind, n_horizon
            header = lines[0].split()

            n_attr = int(float(header[0]))
            n_wind = int(float(header[1]))
            n_hor = int(float(header[2])) if len(header) > 2 else 0
            
            # The mode is implicit in how the data lines are structured, usually 0 (relative) or 1 (node-wise)
            data_lines = [l for l in lines[1:] if not l.startswith('#')]
            count = len(data_lines)

            # READ DATA
            indices = []
            lus = []
            clims = []
            
            for i, line in enumerate(data_lines):
                parts = line.split()
                print("HERE CHECK IF RELATIVE MODE OR NODE; AND THEN BUT DONT WANNT AIMPLEMENT CURRENTLY")
                
                # Simplified reader, assumes relative spacing!!
                idx = int(i * (n_columns - 1) / (count - 1)) if count > 1 else 0
                
                lu = int(float(parts[0]))
                clim = int(float(parts[1]))
                
                indices.append(idx)
                lus.append(lu)
                clims.append(clim)
                
                # Capture everything AFTER the standard columns (Precip ID + Wind Factors)
                # Standard cols = LU (1) + CLIM (1) + PRECIP (1)
                # grabs from index 3 onwards
                if len(parts) > 3:
                    extra_data.append(" ".join(parts[3:]))
                else:
                    extra_data.append("1.00") # Default wind factor

            # Interpolate IDs to fill the array
            current_idx = 0
            for i in range(len(indices)):
                next_idx = indices[i+1] if i < len(indices)-1 else n_columns
                lu_ids[current_idx:next_idx] = lus[i]
                clim_ids[current_idx:next_idx] = clims[i]
                current_idx = next_idx

            header_info = {
                "n_attr_class": n_attr, 
                "n_wind_dir": n_wind, 
                "n_horizon": n_hor
            }

        except Exception as e:
            raise ValueError(f"Failed to read surface.pob: {e}")
            
        return cls(landuse_ids=lu_ids, climate_ids=clim_ids, 
                   extra_data_lines=extra_data, header_def=header_info)

    def to_file(self, filepath: str):
        """
        Writes surface assignments preserving the original header definition.
        """
        # Retrieve original header values
        n_attr = self.header_def["n_attr_class"]
        n_wind = self.header_def["n_wind_dir"]
        n_hor = self.header_def["n_horizon"]
        
        n_nodes = len(self.landuse_ids)
        points = [0, n_nodes // 2, -1]
        
        with open(filepath, 'w') as f:
            # Write Header using preserved values
            # Format usually floats: "3.000000 4.000000 0.000000"  , maybe lets use with :.1f?
            f.write(f"{float(n_attr):.6f} {float(n_wind):.6f} {float(n_hor):.6f}\n")
            
            for i, p_idx in enumerate(points):
                # Retrieve the data for this point
                lu = self.landuse_ids[p_idx]
                clim = self.climate_ids[p_idx]
                
                # Retrieve extra data (wind factors) - cycle if we have fewer lines than points
                extra = self.extra_data_lines[i] if i < len(self.extra_data_lines) else "1.00"
                
                # Write line: LU CLIM PRECIP(1) EXTRA..., ka was das ist
                f.write(f"{lu} {clim} 1 {extra}\n")
            
            f.write("\n")

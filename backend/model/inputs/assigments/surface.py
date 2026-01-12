from typing import Any, Dict, List
import numpy as np
from dataclasses import dataclass, field

@dataclass
class SurfaceRow:
    id: int
    land_use_id: int
    precip_id: int	
    climat_id : int
    wdirfac: List[float]

@dataclass
class SurfaceAssignment:
    header: Dict[str, Any] = field(default_factory=lambda: {
        "n_attr_class": 3, 
        "n_wind_dir": 1, 
        "n_horizon": 0,
        "mode": 0
    })
    surface_data: List[SurfaceRow] = field(default_factory=lambda: [])


    @classmethod
    def from_file(cls, path: str, n_columns: int) -> 'SurfaceAssignment':       
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
            header_info = {
                "n_attr_class": n_attr, 
                "n_wind_dir": n_wind, 
                "n_horizon": n_hor
            }
            
            surface_data = []
            data_lines = [l for l in lines[1:] if not l.startswith('#')]
            #|1. node	land-use ID	precip.ID	Climat ID	wdirfac D1	....	wdirfacID4	hor1	hor2	....	hor36
            for i, line in enumerate(data_lines):
                parts = line.split()
                land_use_id, precip_id, climat_id = parts[:3]
                wdirfac = parts[3:]
                surface_data.append(SurfaceRow(i, land_use_id, precip_id, climat_id, wdirfac))

        except Exception as e:
            raise ValueError(f"Failed to read surface.pob: {e}")
            
        return cls(header=header_info, surface_data=surface_data)

    def to_file(self, filepath: str):
        try:
            with open(filepath, 'w') as f:
                header_values = [
                    float(self.header.get("n_attr_class", 3)),
                    float(self.header.get("n_wind_dir", 1)),
                    float(self.header.get("n_horizon", 0))  #, maybe change to int??
                ]
                f.write(f"{header_values[0]:.1f} {header_values[1]:.1f} {header_values[2]:.1f}\n")

                # 2. Write Data Rows
                for row in self.surface_data:
                    line_parts = [
                        str(row.land_use_id),
                        str(row.precip_id),
                        str(row.climat_id)
                    ]
                    line_parts.extend(str(val) for val in row.wdirfac)
                    f.write(" ".join(line_parts) + "\n")
                    
        except Exception as e:
            raise IOError(f"Failed to write surface file to {filepath}: {e}")

from dataclasses import dataclass, field
from typing import List, Optional
from pathlib import Path

import numpy as np

@dataclass
class SoilType:
    id: int
    name: str
    
    # Line 2: Control Flags
    model_id: int          # e.g., 1=Van Genuchten
    table_size: int        # e.g., 800
    anisotropy_x: float    # 1.00
    anisotropy_z: float    # 1.00
    s_null: float          # 0.09 (Initial saturation/suction guess?)
    
    # Line 3: Physics Parameters (Van Genuchten / Brooks-Corey)
    # Based on standard CATFLOW parameter order for Model 1
    ks: float              # Saturated Conductivity [m/s]
    theta_s: float         # Saturated Water Content [-]
    theta_r: float         # Residual Water Content [-]
    alpha: float           # Alpha parameter [1/m]
    n_param: float         # n parameter [-]

    control_extras: List[float] = field(default_factory=list) 
    extra_params: List[float] = field(default_factory=list) 


    @classmethod
    def from_lines(cls, lines: List[str]) -> 'SoilType':
        # Line 1: "1 SL - St3 Su3..." -> Parse ID "1" and Name
        header = lines[0].strip()
        soil_id = int(header.split()[0])
        name = " ".join(header.split()[1:])
        
        # Line 2: Integer/Control params
        l2 = [float(x) for x in lines[1].split()]
        
        # Line 3: Physics params
        l3 = [float(x) for x in lines[2].split()]
        
        return cls(
            id=soil_id,
            name=name,
            model_id=int(l2[0]),
            table_size=int(l2[1]),
            anisotropy_x=l2[2],
            anisotropy_z=l2[3],
            s_null=l2[4],
            # Mapping standard params (adjust indices if your specific version differs)
            ks=l3[0],
            theta_s=l3[1],
            theta_r=l3[2],
            alpha=l3[3],
            n_param=l3[4],
            control_extras = l2[5:],
            extra_params=l3[5:]
        )
    
@dataclass    
class SoilLibrary:
    soils: List[SoilType] = field(default_factory=list)

    @classmethod
    def from_file(cls, path: str) -> 'SoilLibrary':
        with open(path, 'r') as f:
            lines = [l.strip() for l in f if l.strip()]
        
        count = int(lines[0])
        soils = []
        idx = 1
        
        # Header + Control + Physics + 3 Padding = 6 lines per soil
        lines_per_soil = 6 
        
        for _ in range(count):
            block = lines[idx : idx + lines_per_soil]
            soils.append(SoilType.from_lines(block))
            idx += lines_per_soil
            
        return cls(soils=soils)

    def to_file(self, filepath: str):
        with open(filepath, 'w') as f:
            f.write(f"{len(self.soils)}\n")
            for s in self.soils:
                # Line 1: ID Name
                f.write(f"{s.id} {s.name}\n")
                
                # Base params
                base_str = f"{s.model_id} {s.table_size} {s.anisotropy_x:.2f} {s.anisotropy_z:.2f} {s.s_null:.2f}"
                # Extra params
                if s.control_extras:
                    extra_str = " ".join([f"{x:.2f}" for x in s.control_extras])
                    f.write(f"{base_str} {extra_str}\n")
                else:
                    f.write(f"{base_str}\n")
                
                # Line 3: Physics
                # STRICT ORDER: Ks, Theta_s, Theta_r, Alpha, n, [Extras]
                params = [s.ks, s.theta_s, s.theta_r, s.alpha, s.n_param] + s.extra_params
                
                # Use .6g for precision
                param_str = " ".join([f"{p:.6g}" for p in params])
                f.write(f"{param_str}\n")
                
                # Padding
                f.write("0. 0. 0.\n0. 0. 0.\n0. 0. 0.\n")

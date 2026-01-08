import numpy as np
import pandas as pd
from dataclasses import dataclass, field
from pathlib import Path
from typing import List, Dict

from model.inputs.landuse.parameters import PlantParameters



@dataclass
class LandUseDefinition:
    """
    Land use parameter definitions (lu_file.def)
    """
    assignment_vector: np.ndarray 
    
    # The Dictionary: What does ID 1 mean?
    # Map ID -> PlantParameters Object
    land_use_types: Dict[int, PlantParameters] = field(default_factory=dict)
    
    @classmethod
    def from_file(cls, filepath: str) -> 'LandUseDefinition':
        """Parse lu_file.def"""
        path = Path(filepath)
        if not path.exists():
            raise FileNotFoundError("HERE")
            # Create default land use
            #return cls(land_uses=[{
            #    'id': 1,
            #    'name': 'Grassland',
            #    'lai': 3.0,
            #    'height': 0.3,
            #    'albedo': 0.23,
            #    'root_depth': 0.5
            #}])
        
        try:
            with open(path, 'r') as f:
                content = f.read()
            
            # Simplified parsing
            land_uses = [{
                'id': 1,
                'name': 'Default',
                'lai': 3.0,
                'height': 0.3,
                'albedo': 0.23,
                'root_depth': 0.5
            }]
            
            return cls(land_uses=land_uses)
            
        except Exception as e:
            print(f"⚠ Error parsing lu_file.def: {e}")
            return cls(land_uses=[])
    
    def to_file(self, filepath: str):
        """Write lu_file.def"""
        path = Path(filepath)
        path.parent.mkdir(parents=True, exist_ok=True)
        
        with open(path, 'w') as f:
            f.write(f"{len(self.land_uses)}  % Number of land uses\n")
            for lu in self.land_uses:
                f.write(f"\n% {lu.get('name', 'Unknown')}\n")
                f.write(f"{lu['id']}  {lu.get('lai', 3.0):.2f}  {lu.get('height', 0.3):.2f}\n")



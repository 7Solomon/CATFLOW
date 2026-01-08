from dataclasses import dataclass, field
from pathlib import Path
from typing import List


@dataclass
class PlantParameters:
    """
    Physical parameters for a specific vegetation type.
    Mapped File: *.par (e.g., laubwald.par)
    """
    name: str # e.g. "Laubwald"
    params: List[float] = field(default_factory=list)
    
    @classmethod
    def from_file(cls, filepath: str) -> 'PlantParameters':
        path = Path(filepath)
        with open(path, 'r') as f:
            # Read all numbers found in the file
            content = f.read()
            # Extract floats
            nums = [float(x) for x in content.split() if x.replace('.','',1).isdigit()]
            
        return cls(name=path.stem, params=nums)
        
    def to_file(self, filepath: str):
        # Write params in a simple list
        with open(filepath, 'w') as f:
            f.write(f"% Parameters for {self.name}\n")
            f.write(" ".join(f"{p:.4f}" for p in self.params))

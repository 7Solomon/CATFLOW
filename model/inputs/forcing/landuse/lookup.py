from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict


@dataclass
class LandUseLookup:
    """Represents a single lu_set1.dat file (Mapping External ID -> Library ID)"""
    filename: str          
    column_idx: int = 1    
    mapping: Dict[int, int] = field(default_factory=dict) # {11: 1, 22: 2}

    @classmethod
    def from_file(cls, path: str):
        mapping = {}
        with open(path, 'r') as f:
            lines = [l.split('%')[0].strip() for l in f if l.split('%')[0].strip()]
        
        col = 1
        if lines:
            col = int(lines[0])
            for line in lines[1:]:
                parts = line.split()
                if len(parts) >= 2:
                    mapping[int(parts[0])] = int(parts[1])
                
        return cls(Path(path).name, col, mapping)

    def to_file(self, folder: Path):
        with open(folder / self.filename, 'w') as f:
            f.write(f"{self.column_idx:<15} % columnnumber\n")
            for ext, lib in self.mapping.items():
                f.write(f"{ext:<4} {lib:<4}      % Mapping\n")
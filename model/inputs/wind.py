from dataclasses import dataclass, field
from typing import List

@dataclass
class WindSector:
    upper_angle: float  # Degrees (0-360)
    exposure_factor: float

@dataclass
class WindLibrary:
    sectors: List[WindSector] = field(default_factory=list)

    @classmethod
    def from_file(cls, path: str) -> 'WindLibrary':
        lib = cls()
        with open(path, 'r') as f:
            lines = [l.strip() for l in f if l.strip()]
            
        count = int(lines[0])
        for i in range(count):
            parts = lines[i+1].split()
            lib.sectors.append(WindSector(
                upper_angle=float(parts[0]),
                exposure_factor=float(parts[1])
            ))
        return lib
    
    def to_file(self, filepath: str):
        with open(filepath, 'w') as f:
            f.write(f"{len(self.sectors)}\n")
            for sec in self.sectors:
                # Angle Factor
                f.write(f"{sec.upper_angle:<5.1f} {sec.exposure_factor:.2f}\n")
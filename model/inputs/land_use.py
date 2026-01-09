from dataclasses import dataclass, field
from typing import List


@dataclass
class LandUseType:
    id: int
    name: str
    param_file: str

@dataclass
class LandUseLibrary:
    types: List[LandUseType] = field(default_factory=list)

    @classmethod
    def from_file(cls, path: str) -> 'LandUseLibrary':
        lib = cls()
        with open(path, 'r') as f:
            for line in f:
                if not line.strip(): continue
                parts = line.split()
                if len(parts) >= 3:
                    # ID Name Path
                    lib.types.append(LandUseType(
                        id=int(parts[0]),
                        name=parts[1],
                        param_file=parts[2]
                    ))
                elif len(parts) == 2:
                    raise ValueError("LANDUsE FILE WEIRD")
        return lib

    
    def to_file(self, filepath: str):
        with open(filepath, 'w') as f:
            for lu in self.types:
                # Format: ID   Name   Path
                f.write(f"{lu.id:<5} {lu.name:<30} {lu.param_file}\n")

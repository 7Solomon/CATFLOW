from dataclasses import dataclass
from typing import List


@dataclass
class ControlVolumeDef:
    # List of blocks: [v1, v2, h1, h2]
    # usually just 1 block for the whole domain
    blocks: List[List[float]] 
    
    @classmethod
    def from_file(cls, path: str):
        blocks = []
        with open(path, 'r') as f:
            lines = [l.strip() for l in f if l.strip()]
        
        count = int(lines[0])
        for i in range(count):
            # Parse line: 0.0 1.0 0.0 1.0
            parts = [float(x) for x in lines[1+i].split()]
            blocks.append(parts)
            
        return cls(blocks)

    def to_file(self, filepath: str):
        with open(filepath, 'w') as f:
            f.write(f"{len(self.blocks)}\n")
            for b in self.blocks:
                f.write(f"{b[0]:.4f}   {b[1]:.4f}   {b[2]:.4f}   {b[3]:.4f}\n")

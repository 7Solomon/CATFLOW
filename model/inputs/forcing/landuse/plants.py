from dataclasses import dataclass, field
from typing import List, Optional
from pathlib import Path


@dataclass
class PlantParameterRow:
    day: int
    params: List[float] 

@dataclass
class PlantDefinition:
    name: str
    filename: str 
    header_labels: List[str] 
    table: List[PlantParameterRow] = field(default_factory=list)

    @classmethod
    def from_file(cls, path: str):
        with open(path, 'r') as f:
            lines = [l.strip() for l in f if l.strip()]
            
        if not lines: return cls("Empty", Path(path).name, [])

        # Header parsing (heuristic)
        header_line = lines[0].split('%')[0].strip()
        parts = header_line.split()
        labels = parts[1:] if len(parts) > 1 else [] # Skip first number
        
        rows = []
        for line in lines[1:]: 
            clean = line.split('%')[0].strip()
            if not clean: continue
            try:
                nums = [float(x) for x in clean.split()]
                if nums:
                    rows.append(PlantParameterRow(day=int(nums[0]), params=nums[1:]))
            except ValueError:
                continue
            
        return cls(name=Path(path).stem, filename=Path(path).name, header_labels=labels, table=rows)

    def to_file(self, folder: Path):
        out_path = folder / self.filename
        out_path.parent.mkdir(parents=True, exist_ok=True)
        
        with open(out_path, 'w') as f:
            # Reconstruct header
            f.write(f" 10  {'  '.join(self.header_labels)}    %{self.name}\n")
            for row in self.table:
                p_str = "  ".join([f"{x:.4g}" for x in row.params])
                f.write(f"{row.day:>4}.  {p_str}\n")

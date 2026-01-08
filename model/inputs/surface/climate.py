from dataclasses import dataclass, field
from typing import List, Tuple
from pathlib import Path

@dataclass
class WindDirection:
    """
    Manages wind direction sectors and evapotranspiration factors.
    Mapped File: winddir.def
    """
    # List of (Start_Angle, Factor)
    sectors: List[Tuple[float, float]] = field(default_factory=list)

    @classmethod
    def from_file(cls, filepath: str) -> 'WindDirection':
        path = Path(filepath)
        if not path.exists():
            raise FileNotFoundError(f"Wind file not found: {filepath}")

        with open(path, 'r') as f:
            # Filter comments and empty lines
            lines = [l.strip().split('%')[0] for l in f.readlines()]
            lines = [l for l in lines if l]

        if not lines:
            raise ValueError(f"Empty wind file: {filepath}")

        try:
            # Line 1: Count
            n_sectors = int(lines[0].split()[0])
            
            sectors = []
            # Read N lines
            for i in range(n_sectors):
                parts = lines[i+1].split()
                if len(parts) >= 2:
                    start_angle = float(parts[0])
                    factor = float(parts[1])
                    sectors.append((start_angle, factor))
            
            return cls(sectors=sectors)
            
        except (ValueError, IndexError) as e:
            raise ValueError(f"Error parsing winddir.def: {e}")

    def to_file(self, filepath: str):
        """Writes strictly formatted winddir.def compatible with rdwind"""
        lines = []
        # Header: Count
        lines.append(f"{len(self.sectors)}")
        
        # Data: Start_Angle  Factor
        for angle, factor in self.sectors:
            # Format matching legacy: Angle (int/float), Factor (float)
            lines.append(f"{angle:5.1f}   {factor:.2f}")
            
        with open(filepath, 'w') as f:
            f.write('\n'.join(lines))

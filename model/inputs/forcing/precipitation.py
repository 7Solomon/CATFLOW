from dataclasses import dataclass
from pathlib import Path

import numpy as np

@dataclass
class PrecipitationData:
    filename: str
    header_date: str   # "01.01.2004 00:00:00.00"
    factor_t: float    # 86400.0 (Time conversion to seconds)
    factor_v: float    # 0.277e-5 (Value conversion)
    data: np.ndarray   # Columns: [Time, Value]

    @classmethod
    def from_file(cls, path: str):
        p = Path(path)
        with open(p, 'r') as f:
            lines = f.readlines()
        
        # Parse Header: "01.01.2004 00:00... 86400.0 0.277... "
        h = lines[0].split()
        date = f"{h[0]} {h[1]}"
        ft = float(h[2])
        fv = float(h[3])
        
        # Load Data (skip header line 1 and comment line 2)
        # Using numpy for speed
        try:
            data = np.loadtxt(lines[2:]) 
        except:
            # Fallback for empty files
            data = np.array([])

        return cls(filename=p.name, header_date=date, factor_t=ft, factor_v=fv, data=data)

    def to_file(self, folder: Path):
        with open(folder / self.filename, 'w') as f:
            f.write(f"{self.header_date:<22} {self.factor_t:.1f}    {self.factor_v:.5E}\n")
            f.write("#  Startdatum              [d] -> [s]  [mm/6min] -> [m/s]\n")
            if self.data.size > 0:
                for row in self.data:
                    f.write(f"\t{row[0]:.4f}\t{row[1]:.4f}\n")
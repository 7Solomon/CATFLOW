from dataclasses import dataclass
from pathlib import Path
from typing import List

import numpy as np

@dataclass
class ClimateData:
    filename: str
    id_pair: str       # "1 1" (Station IDs)
    header_date: str   # Start date
    factor_t: float
    coeffs: List[float] # The physics coefficients (8. -6. 0.7 ...)
    data: np.ndarray    # The matrix of climate variables

    @classmethod
    def from_file(cls, path: str):
        p = Path(path)
        with open(p, 'r') as f:
            lines = f.readlines()
        
        id_pair = lines[0].strip() # "1 1"
        
        l1 = lines[1].split()
        date = f"{l1[0]} {l1[1]}"
        ft = float(l1[2])
        coeffs = [float(x) for x in l1[3:]]
        
        try:
            data = np.loadtxt(lines[2:])
        except:
            data = np.array([])
            
        return cls(p.name, id_pair, date, ft, coeffs, data)

    def to_file(self, folder: Path):
        with open(folder / self.filename, 'w') as f:
            f.write(f"{self.id_pair}\n")
            c_str = " ".join([f"{c:.6g}" for c in self.coeffs])
            f.write(f"{self.header_date}    {self.factor_t}    {c_str}\n")
            if self.data.size > 0:
                for row in self.data:
                    # Format: Time + 6 vars
                    vals = "\t".join([f"{x:.6f}" for x in row])
                    f.write(f"{vals}\n")

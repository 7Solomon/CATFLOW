import numpy as np
from dataclasses import dataclass
from pathlib import Path
import re

@dataclass
class HillslopeMesh:
    x_coords: np.ndarray
    z_coords: np.ndarray
    eta: np.ndarray
    xsi: np.ndarray
    n_layers: int
    n_columns: int
    width: float = 1.0
    
    @classmethod
    def from_file(cls, filepath: str) -> 'HillslopeMesh':
        path = Path(filepath)
        if not path.exists(): 
            raise FileNotFoundError(f"{filepath} not found")

        with open(path, 'r') as f:
            raw_lines = f.readlines()

        # ---------------------------------------------------------
        # ROBUST LINE FILTERING
        # ---------------------------------------------------------
        lines = []
        for line in raw_lines:
            # 1. Strip comments
            clean = line.split('%')[0].strip()
            if not clean: continue
            
            # 2. Skip Explicit Headers
            if "HANG" in clean.upper(): continue
            
            # 3. Skip lines starting with non-numeric chars
            if not re.match(r'^[0-9.+\-]', clean):
                continue
                
            lines.append(clean)

        if not lines:
            raise ValueError("No valid data lines found in mesh file")

        try:
            # 1. Header: NV, NL, Width, SlopeID
            header_tokens = lines[0].split()
            valid_nums = []
            for t in header_tokens:
                try:
                    valid_nums.append(float(t))
                except ValueError:
                    break
            
            if len(valid_nums) < 3:
                 raise ValueError(f"Header line malformed: {lines[0]}")
                 
            n_rows = int(valid_nums[0])
            n_cols = int(valid_nums[1])
            width = valid_nums[2]
            
            # 2. Block 1: Eta (Vertical)
            nums = []
            line_idx = 3
            while len(nums) < n_rows and line_idx < len(lines):
                nums.extend([float(x) for x in lines[line_idx].split()])
                line_idx += 1
            eta = np.array(nums[:n_rows])
            
            # 3. Block 2: Xsi + Coords (Lateral)
            xsi = []
            found_cols = 0
            while found_cols < n_cols and line_idx < len(lines):
                row_nums = [float(x) for x in lines[line_idx].split()]
                if row_nums:
                    xsi.append(row_nums[0])
                    found_cols += 1
                line_idx += 1
            
            xsi = np.array(xsi)
            
            print(f"✓ Loaded mesh: {n_rows} layers × {len(xsi)} columns")
            
            return cls(
                x_coords=np.zeros(len(xsi)),
                z_coords=np.zeros(n_rows),
                eta=eta,
                xsi=xsi,
                n_layers=n_rows,
                n_columns=len(xsi),
                width=width
            )

        except Exception as e:
            raise ValueError(f"Mesh parsing failed: {e}")

    def to_file(self, filepath: str):
        """
        Writes a .geo file compatible with CATFLOW's rdhang subroutine.
        """
        lines = []
        
        # 1. Header: NV NL Width SlopeID
        lines.append(f"{self.n_layers} {self.n_columns} {self.width:.4f} 1")
        
        # 2. Reference & Dimensions (Dummy)
        lines.append("0.0 0.0 0.0")  # Ref coords
        lines.append("1.0 1.0 1.0")  # Surface dims
        
        # 3. Eta Block
        # Write 10 numbers per line
        for i in range(0, len(self.eta), 10):
            chunk = self.eta[i:i+10]
            lines.append(" ".join(f"{x:.8f}" for x in chunk))
            
        # 4. Xsi Block
        # rdhang expects: xsi, x_top, y_top, x_surf, y_surf, var_width
        # We fill coordinates with 0.0 as we only track xsi
        for val in self.xsi:
            lines.append(f"{val:.8f} 0.0 0.0 0.0 0.0 1.0")
            
        # 5. Detailed Grid Block
        # rdhang expects detailed parameters for every node.
        # We write dummy neutral values: 0 elevation, 0 slope, 1.0 scaling factors, soil_id 1
        dummy_params = "0.0 0.0 1.0 1.0 0.0 0.0 1"
        for _ in range(self.n_columns):
            for _ in range(self.n_layers):
                lines.append(dummy_params)
                
        with open(filepath, 'w') as f:
            f.write('\n'.join(lines))
        print(f"✓ Wrote mesh to {filepath}")

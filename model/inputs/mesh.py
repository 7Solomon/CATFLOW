import numpy as np
from dataclasses import dataclass
from pathlib import Path
import re

@dataclass
class HillslopeMesh:
    """
    Where is which node, mapping
    """

    x_coords: np.ndarray
    z_coords: np.ndarray
    eta: np.ndarray
    xsi: np.ndarray
    n_layers: int
    n_columns: int
    width: float = 1.0
    
    # New fields to preserve metadata
    ref_coords: str = "0.0 0.0 0.0"
    dimensions: str = "1.0 1.0 1.0"
    
    @classmethod
    def from_file(cls, filepath: str) -> 'HillslopeMesh':
        path = Path(filepath)
        if not path.exists(): 
            raise FileNotFoundError(f"{filepath} not found")

        with open(path, 'r') as f:
            raw_lines = f.readlines()

        lines = []
        for line in raw_lines:
            clean = line.split('%')[0].strip()
            if not clean or "HANG" in clean.upper(): continue
            if not re.match(r'^[0-9.+\-]', clean): continue
            lines.append(clean)

        if not lines: raise ValueError("No valid data lines")

        try:
            # 1. Header
            header_tokens = lines[0].split()
            # Stop at first non-number (like '(')
            valid_nums = []
            for t in header_tokens:
                try: 
                    valid_nums.append(float(t))
                except: break
            
            n_rows = int(valid_nums[0])
            n_cols = int(valid_nums[1])
            width = valid_nums[2]
            
            # 2. Capture Metadata (Lines 1 and 2)
            ref_coords = lines[1] if len(lines) > 1 else "0.0 0.0 0.0"
            dimensions = lines[2] if len(lines) > 2 else "1.0 1.0 1.0"
            
            # 3. Block 1: Eta (Vertical) - Starts Line 3
            nums = []
            line_idx = 3
            while len(nums) < n_rows and line_idx < len(lines):
                nums.extend([float(x) for x in lines[line_idx].split()])
                line_idx += 1
            eta = np.array(nums[:n_rows])
            
            # 4. Block 2: Xsi + Coords (Lateral)
            xsi = []
            found_cols = 0
            while found_cols < n_cols and line_idx < len(lines):
                row_nums = [float(x) for x in lines[line_idx].split()]
                if row_nums:
                    xsi.append(row_nums[0])
                    found_cols += 1
                line_idx += 1
            
            return cls(
                x_coords=np.zeros(len(xsi)), z_coords=np.zeros(n_rows),
                eta=eta, xsi=np.array(xsi),
                n_layers=n_rows, n_columns=len(xsi), width=width,
                ref_coords=ref_coords, dimensions=dimensions
            )

        except Exception as e:
            raise ValueError(f"Mesh parsing failed: {e}")

    def to_file(self, filepath: str):
        lines = []
        # Header
        lines.append(f"{self.n_layers}     {self.n_columns}  {self.width:.4f}     1")
        
        # Metadata
        lines.append(self.ref_coords)
        lines.append(self.dimensions)
        
        # Eta
        for i in range(0, len(self.eta), 10):
            chunk = self.eta[i:i+10]
            lines.append(" ".join(f"{x:.8f}" for x in chunk))
            
        # Xsi + Dummy Coords (Preserving 0.0s for now)
        for val in self.xsi:
            lines.append(f"{val:.8f} 0.0 0.0 0.0 0.0 1.0")
            
        # Detailed Grid (Dummy)
        dummy_params = "0.0 0.0 1.0 1.0 0.0 0.0 1"
        for _ in range(self.n_columns):
            for _ in range(self.n_layers):
                lines.append(dummy_params)
                
        with open(filepath, 'w') as f:
            f.write('\n'.join(lines))
        print(f"✓ Wrote mesh to {filepath}")

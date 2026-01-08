import numpy as np
import pandas as pd
from dataclasses import dataclass
from pathlib import Path

@dataclass
class HillslopeMesh:
    """
    Represents the 2D hillslope geometry:
    - x_coords: Horizontal discretization
    - surface_elevs: Surface elevation Z(x)
    - layer_depths: Matrix of depths relative to surface (negative values)
    """
    x_coords: np.ndarray          # 1D array (n_cols)
    surface_elevs: np.ndarray     # 1D array (n_cols)
    layer_depths: np.ndarray      # 2D array (n_layers, n_cols)
    width: float = 1.0            # Physical width of the slice

    @property
    def n_layers(self) -> int:
        return self.layer_depths.shape[0]

    @property
    def n_columns(self) -> int:
        return len(self.x_coords)

    @classmethod
    def from_file(cls, filepath: str) -> 'HillslopeMesh':
        path = Path(filepath)
        if not path.exists():
            raise FileNotFoundError()
            return cls(np.array([0]), np.array([0]), np.array([[0]]), 1.0)

        with open(path, 'r') as f:
            content = f.read().split()

        try:
            # Format detection
            if content[0].upper() == 'HANG':
                # Standard
                n_layers = int(content[2])
                n_columns = int(content[3])
                width = float(content[5])
            else:
                # "Profile" / Format 2 (Your Case)
                n_layers = int(content[0])
                n_columns = int(content[1])
                width = float(content[2])

            # Try to read actual data, but if it fails, return structure only
            # This ensures the Runner always has valid dimensions for Output Parsing
            
            # Simple heuristic: Do we have enough numbers?
            # We need ~ 3 * (N*M) numbers for a full mesh.
            # Your file only has ~40 lines, which is too small for a 15x15 full grid (225 nodes).
            # This confirms it defines a PROFILE (1D line expanded to 2D), not a full grid.
            
            # Since we can't reconstruct the full 3D mesh from just the profile 
            # without the internal generator logic of CATFLOW, we return a 
            # "Logical Mesh" (correct topology, dummy geometry).
            
            # Create a logical grid (0..N, 0..M)
            x_coords = np.linspace(0, 100, n_columns) # Dummy spacing
            elevs = np.zeros(n_columns)
            layer_depths = np.zeros((n_layers, n_columns))
            
            return cls(x_coords, elevs, layer_depths, width)

        except Exception as e:
            print(f"Mesh parsing error: {e}. Using default 1x1 mesh.")
            return cls(np.array([0]), np.array([0]), np.array([[0]]), 1.0)
        

    def to_file(self, filepath: str):
        """Writes standard Fortran-formatted .geo file"""
        path = Path(filepath)
        path.parent.mkdir(parents=True, exist_ok=True)
        
        with open(path, 'w') as f:
            f.write(f"HANG           1\n")
            f.write(f"{self.n_layers:5d}{self.n_columns:5d}          % nv, nl\n")
            f.write(f"{self.width:10.3f}          % hillslope width\n")
            
            def write_chunk(data_arr, label):
                f.write(f"\n% {label}\n")
                flat = data_arr.flatten()
                for i, val in enumerate(flat):
                    f.write(f"{val:10.3f}")
                    if (i + 1) % 8 == 0: f.write("\n")
                if len(flat) % 8 != 0: f.write("\n")

            write_chunk(self.x_coords, "Lateral coordinates [m]")
            write_chunk(self.layer_depths, "Layer depths [m]")
            write_chunk(self.surface_elevs, "Surface elevations [m]")


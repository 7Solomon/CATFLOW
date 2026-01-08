
from dataclasses import dataclass, field
from pathlib import Path
import numpy as np

@dataclass
class SurfaceProperties:
    """
    Surface node properties (surface.pob)
    Assigns land use, vegetation, and surface characteristics
    """
    # Fixed integer codes for each surface node
    fixed_codes: np.ndarray = field(default_factory=lambda: np.array([]))  # Shape: (n_cols, 3)
    
    # Land use ID for each surface node
    land_use_ids: np.ndarray = field(default_factory=lambda: np.array([]))  # Shape: (n_cols,)
    
    # Wind reduction factors (optional)
    wind_factors: np.ndarray = field(default_factory=lambda: np.array([]))  # Shape: (n_cols, n_directions)
    
    # Horizon angles (optional)
    horizon_angles: np.ndarray = field(default_factory=lambda: np.array([]))  # Shape: (n_cols, n_angles)
    
    @classmethod
    def from_file(cls, filepath: str, n_cols: int) -> 'SurfaceProperties':
        """
        Parse surface.pob
        This file is complex - it assigns vegetation and surface properties
        """
        path = Path(filepath)
        if not path.exists():
            raise FileNotFoundError("HERE SURFACE")

            # Create default: all nodes land use 1, no special codes
            return cls(
                fixed_codes=np.zeros((n_cols, 3), dtype=int),
                land_use_ids=np.ones(n_cols, dtype=int)
            )
        
        try:
            with open(path, 'r') as f:
                lines = [l.strip() for l in f.readlines()]
            
            # Basic parsing (simplified - actual format varies)
            # Usually has sections for each property type
            fixed = []
            land_use = []
            
            data_mode = False
            for line in lines:
                if line.startswith('%') or line.startswith('HANG'):
                    continue
                if not line:
                    continue
                    
                # Try to parse as integers
                try:
                    vals = [int(x) for x in line.split()]
                    if len(vals) == 1:
                        land_use.append(vals[0])
                    elif len(vals) >= 3:
                        fixed.append(vals[:3])
                except:
                    pass
            
            # Create arrays
            if land_use:
                land_use_ids = np.array(land_use[:n_cols])
            else:
                land_use_ids = np.ones(n_cols, dtype=int)
            
            if fixed:
                fixed_codes = np.array(fixed[:n_cols])
                if fixed_codes.shape[1] != 3:
                    fixed_codes = np.zeros((n_cols, 3), dtype=int)
            else:
                fixed_codes = np.zeros((n_cols, 3), dtype=int)
            
            return cls(fixed_codes=fixed_codes, land_use_ids=land_use_ids)
            
        except Exception as e:
            print(f"⚠ Error parsing surface.pob: {e}")
            return cls(
                fixed_codes=np.zeros((n_cols, 3), dtype=int),
                land_use_ids=np.ones(n_cols, dtype=int)
            )
    
    def to_file(self, filepath: str):
        """Write surface.pob"""
        path = Path(filepath)
        path.parent.mkdir(parents=True, exist_ok=True)
        
        with open(path, 'w') as f:
            f.write(" HANG           1\n")
            f.write(f"{len(self.land_use_ids):5d}           % Number of surface nodes\n")
            
            # Write land use assignments
            f.write("\n% Land use IDs\n")
            for i, lu_id in enumerate(self.land_use_ids):
                f.write(f"{lu_id:5d}")
                if (i + 1) % 15 == 0:
                    f.write("\n")
            if len(self.land_use_ids) % 15 != 0:
                f.write("\n")


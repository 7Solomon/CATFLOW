import numpy as np
from dataclasses import dataclass, field
from pathlib import Path

@dataclass
class BoundaryDefinition:
    """
    Boundary condition master file (boundary.rb)
    References external time series files
    """
    rainfall_file: str = "in/climate/rainfall.dat"
    evaporation_file: str = ""
    
    # Boundary types for each edge (-1=potential, 1=flux, etc.)
    bottom_bc_type: int = -2  # Usually prescribed potential
    top_bc_type: int = 1      # Usually flux (rainfall)
    
    @classmethod
    def from_file(cls, filepath: str) -> 'BoundaryDefinition':
        """
        Parse boundary.rb
        This is a master file that references other BC files
        """
        path = Path(filepath)
        if not path.exists():
            raise FileNotFoundError("HERE ALSO")

            return cls()
        
        try:
            with open(path, 'r') as f:
                lines = [l.strip() for l in f.readlines() if l.strip() and not l.startswith('%')]
            
            # Very simplified - actual format is complex
            rainfall_file = ""
            for line in lines:
                if 'rainfall' in line.lower() or 'precip' in line.lower():
                    parts = line.split()
                    if parts:
                        rainfall_file = parts[0]
                        break
            
            return cls(rainfall_file=rainfall_file if rainfall_file else "in/climate/rainfall.dat")
            
        except Exception as e:
            print(f"⚠ Error parsing boundary.rb: {e}")
            return cls()
    
    def to_file(self, filepath: str):
        """Write boundary.rb"""
        path = Path(filepath)
        path.parent.mkdir(parents=True, exist_ok=True)
        
        with open(path, 'w') as f:
            f.write("% Boundary condition definition\n")
            f.write(f"% Rainfall data: {self.rainfall_file}\n")
            f.write(f"\n1  {self.rainfall_file}\n")



@dataclass
class InitialConditions:
    """
    Initial conditions (rel_sat.ini or similar)
    """
    pressure_field: np.ndarray = field(default_factory=lambda: np.array([]))  # (n_layers, n_cols)
    saturation_field: np.ndarray = field(default_factory=lambda: np.array([]))
    
    @classmethod
    def from_file(cls, filepath: str, n_layers: int, n_cols: int) -> 'InitialConditions':
        """
        Parse initial conditions file
        Can be pressure head or saturation
        """
        path = Path(filepath)
        if not path.exists():
            raise FileNotFoundError("HERE ALSO")
            return cls()
        
        try:
            with open(path, 'r') as f:
                lines = f.readlines()
            
            # Skip header
            data = []
            for line in lines:
                if line.strip() and not line.strip().startswith('%'):
                    try:
                        data.extend([float(x) for x in line.split()])
                    except:
                        pass
            
            if len(data) >= n_layers * n_cols:
                field = np.array(data[:n_layers * n_cols]).reshape(n_layers, n_cols)
                return cls(pressure_field=field)
            
        except Exception as e:
            print(f"⚠ Error parsing initial conditions: {e}")
        
        return cls()

import numpy as np
from dataclasses import dataclass
from pathlib import Path
import re

@dataclass
class HillslopeMesh:
    """
    Represents the 2D hillslope geometry with proper parsing
    """
    x_coords: np.ndarray          # 1D array (n_cols)
    surface_elevs: np.ndarray     # 1D array (n_cols)
    layer_depths: np.ndarray      # 2D array (n_layers, n_cols)
    width: float = 1.0

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
            raise FileNotFoundError(f"Geometry file not found: {filepath}")

        with open(path, 'r') as f:
            content = f.read()

        try:
            # Extract dimensions from header
            header_match = re.search(r'^\s*(?:HANG)?\s*(?:\d+\s+)?(\d+)\s+(\d+)', content, re.MULTILINE)
            if not header_match:
                raise ValueError("Could not find HANG header with dimensions")
            
            n_layers = int(header_match.group(1))
            n_columns = int(header_match.group(2))
            
            # Extract width
            width_match = re.search(r'([\d.]+)\s+%\s*hillslope width', content, re.IGNORECASE)
            width = float(width_match.group(1)) if width_match else 1.0
            
            # Find section markers and extract data
            sections = {}
            
            # Pattern: % Section Name followed by numbers
            section_pattern = r'%\s*([^\n]+?)\s*\[(.*?)\]\s*\n([\d\s.eE+-]+?)(?=%|\Z)'
            
            # More flexible: Look for comment lines then numbers
            lines = content.split('\n')
            current_section = None
            current_data = []
            
            for line in lines:
                # Check if this is a section header (starts with %)
                if line.strip().startswith('%'):
                    # Save previous section
                    if current_section and current_data:
                        sections[current_section] = current_data
                    
                    # Start new section
                    section_name = line.strip().lower()
                    if 'lateral' in section_name or 'coordinates' in section_name:
                        current_section = 'x_coords'
                    elif 'layer' in section_name or 'depth' in section_name:
                        current_section = 'layer_depths'
                    elif 'surface' in section_name or 'elevation' in section_name:
                        current_section = 'surface_elevs'
                    else:
                        current_section = None
                    current_data = []
                    
                elif current_section and line.strip() and not line.strip().startswith('%'):
                    # Parse numbers from this line
                    try:
                        numbers = [float(x) for x in line.split()]
                        current_data.extend(numbers)
                    except ValueError:
                        pass  # Skip non-numeric lines
            
            # Save last section
            if current_section and current_data:
                sections[current_section] = current_data
            
            # Validate we got all sections
            if 'x_coords' not in sections:
                raise ValueError("Missing lateral coordinates section")
            if 'layer_depths' not in sections:
                raise ValueError("Missing layer depths section")
            if 'surface_elevs' not in sections:
                raise ValueError("Missing surface elevations section")
            
            # Convert to arrays
            x_coords = np.array(sections['x_coords'][:n_columns])
            surface_elevs = np.array(sections['surface_elevs'][:n_columns])
            
            # Layer depths are stored as flat array (n_layers * n_columns)
            layer_data = np.array(sections['layer_depths'])
            expected_size = n_layers * n_columns
            
            if len(layer_data) < expected_size:
                raise ValueError(f"Insufficient layer depth data: got {len(layer_data)}, need {expected_size}")
            
            layer_depths = layer_data[:expected_size].reshape(n_layers, n_columns)
            
            print(f"✓ Loaded mesh: {n_layers} layers × {n_columns} columns")
            return cls(x_coords, surface_elevs, layer_depths, width)
            
        except Exception as e:
            # Fallback: Create dummy mesh with correct dimensions
            print(f"⚠ Geometry parsing failed ({e}), creating logical mesh")
            x_coords = np.linspace(0, 100, n_columns) if 'n_columns' in locals() else np.array([0])
            elevs = np.zeros(len(x_coords))
            layers = np.zeros((n_layers if 'n_layers' in locals() else 1, len(x_coords)))
            return cls(x_coords, elevs, layers, 1.0)

    #def to_file(self, filepath: str):
    #    """Writes standard Fortran-formatted .geo file"""
    #    path = Path(filepath)
    #    path.parent.mkdir(parents=True, exist_ok=True)
    #    
    #    with open(path, 'w') as f:
    #        f.write(f"HANG           1\n")
    #        f.write(f"{self.n_layers:5d}{self.n_columns:5d}          % nv, nl\n")
    #        f.write(f"{self.width:10.3f}          % hillslope width\n")
    #        
    #        def write_array(data_arr, label, per_line=8):
    #            f.write(f"\n% {label}\n")
    #            flat = data_arr.flatten()
    #            for i, val in enumerate(flat):
    #                f.write(f"{val:10.3f}")
    #                if (i + 1) % per_line == 0: 
    #                    f.write("\n")
    #            if len(flat) % per_line != 0: 
    #                f.write("\n")
#
    #        write_array(self.x_coords, "Lateral coordinates [m]")
    #        write_array(self.layer_depths, "Layer depths [m] (from surface, negative)")
    #        write_array(self.surface_elevs, "Surface elevations [m]")
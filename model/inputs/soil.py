import numpy as np
import pandas as pd
from dataclasses import dataclass, field
from pathlib import Path
from typing import List, Dict, Any

@dataclass
class SoilProfile:
    """
    Manages Soil Physics and Spatial Assignment
    """
    soil_definitions: List[Dict[str, Any]] = field(default_factory=list) # HERE CHAGNE TO SOIL PARAMETER
    
    # 2D Matrix of Soil IDs mapping to the mesh cells (n_layers x n_cols)
    assignment_matrix: np.ndarray = field(default_factory=lambda: np.array([]))

    def add_soil_type(self, name: str, theta_s: float, theta_r: float, 
                     alpha: float, n: float, k_sat: float) -> int:
        """Helper to add a new soil type and return its ID"""
        new_id = len(self.soil_definitions) + 1
        m = 1.0 - (1.0/n)
        self.soil_definitions.append({
            'id': new_id, 'name': name, 'model': 1,
            'theta_s': theta_s, 'theta_r': theta_r, 
            'alpha': alpha, 'n': n, 'k_sat': k_sat, 'm': m
        })
        return new_id

    @classmethod
    def from_files(cls, def_path: str, bod_path: str) -> 'SoilProfile':
        profile = cls()
        
        # Parse soils.def
        if Path(def_path).exists():
            with open(def_path, 'r') as f:
                lines = [l.strip() for l in f.readlines() if l.strip() and not l.strip().startswith('%')]
            
            try:
                n_soils = int(lines[0].split('%')[0])
                current_line = 1
                for _ in range(n_soils):
                    # Skip extra comments
                    while current_line < len(lines) and (lines[current_line].startswith('%') or not lines[current_line]):
                        current_line += 1
                        
                    header = lines[current_line].split()
                    sid = int(header[0])
                    model = int(header[1])
                    name = header[2].strip("'")
                    
                    current_line += 1
                    params = [float(x) for x in lines[current_line].split()]
                    
                    profile.soil_definitions.append({
                        'id': sid, 'model': model, 'name': name,
                        'theta_s': params[0], 'theta_r': params[1],
                        'alpha': params[2], 'n': params[3], 'k_sat': params[4]
                    })
                    current_line += 1
            except Exception as e:
                print(f"Warning: Error parsing soils.def: {e}")

        # Parse soil_horizons.bod
        if Path(bod_path).exists():
            with open(bod_path, 'r') as f:
                content = f.read().split()
                # Skip header HANG 1 (content[0], content[1])
                # Filter strictly for integer-like tokens
                raw_ids = []
                for x in content[2:]:
                    # Handle negative IDs if they exist (though rare in CATFLOW, SO DONT KNOW IF NEEDED)
                    if x.lstrip('-').isdigit():
                        raw_ids.append(int(x))
                
            profile.assignment_matrix = np.array(raw_ids)
            
        return profile

    def write_soils_def(self, filepath: str):
        path = Path(filepath)
        path.parent.mkdir(parents=True, exist_ok=True)
        with open(path, 'w') as f:
            f.write(f"{len(self.soil_definitions)}          % Number of soil types\n")
            for s in self.soil_definitions:
                f.write(f"\n% Soil type {s['id']}: {s['name']}\n")
                f.write(f"{s['id']:3d}  {s.get('model', 1):2d}  '{s['name']}'\n")
                f.write(f"  {s['theta_s']:.4f}  {s['theta_r']:.4f}  {s['alpha']:.6f}  {s['n']:.4f}  {s['k_sat']:.6e}\n")

    def write_bod_file(self, filepath: str, n_layers: int, n_cols: int):
        """Writes the assignment matrix."""
        path = Path(filepath)
        path.parent.mkdir(parents=True, exist_ok=True)
        
        # Validation
        if self.assignment_matrix.size != n_layers * n_cols:
            # Create default matrix if size mismatch
            mat = np.ones((n_layers, n_cols), dtype=int)
        else:
            mat = self.assignment_matrix.reshape(n_layers, n_cols)
            
        with open(path, 'w') as f:
            f.write(" HANG           1\n")
            for row in mat:
                line = ''.join([f'{val:3d}' for val in row])
                f.write(f"{line}\n")


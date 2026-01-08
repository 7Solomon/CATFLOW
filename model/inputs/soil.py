import numpy as np
from dataclasses import dataclass, field
from pathlib import Path
from typing import List, Dict, Any
import re

@dataclass
class SoilProfile:
    """
    Manages Soil Physics and Spatial Assignment
    """
    soil_definitions: List[Dict[str, Any]] = field(default_factory=list)
    assignment_matrix: np.ndarray = field(default_factory=lambda: np.array([]))

    def add_soil_type(self, name: str, theta_s: float, theta_r: float, 
                     alpha: float, n: float, k_sat: float) -> int:
        """Add a new soil type and return its ID"""
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
        """
        Robustly parse soil definition and assignment files
        """
        profile = cls()
        
        # ═══════════════════════════════════════════════════════════
        # 1. Parse soils.def
        # ═══════════════════════════════════════════════════════════
        def_file = Path(def_path)
        if def_file.exists():
            try:
                with open(def_file, 'r') as f:
                    full_text = f.read()
                
                # Remove all comment lines
                lines = [l.strip() for l in full_text.split('\n') 
                        if l.strip() and not l.strip().startswith('%')]
                
                if not lines:
                    raise ValueError("soils.def is empty or all comments")
                
                # First line: number of soil types
                n_soils = int(lines[0].split()[0])
                print(f"  Reading {n_soils} soil types from {def_file.name}")
                
                idx = 1
                for _ in range(n_soils):
                    if idx >= len(lines):
                        break
                    
                    # Line 1: ID MODEL 'NAME'
                    header_line = lines[idx]
                    
                    # Handle quoted names: "1  1  'Sandy_Loam'"
                    match = re.match(r"(\d+)\s+(\d+)\s+'([^']+)'", header_line)
                    if match:
                        sid = int(match.group(1))
                        model = int(match.group(2))
                        name = match.group(3)
                    else:
                        # Fallback: split and take last as name
                        parts = header_line.split()
                        sid = int(parts[0])
                        model = int(parts[1])
                        name = parts[2].strip("'\"") if len(parts) > 2 else f"Soil_{sid}"
                    
                    idx += 1
                    
                    # Line 2: Parameters (theta_s theta_r alpha n k_sat)
                    if idx >= len(lines):
                        print(f"⚠ Missing parameters for soil {sid}, skipping")
                        break
                        
                    param_line = lines[idx]
                    params = [float(x) for x in param_line.split()]
                    
                    if len(params) < 5:
                        print(f"⚠ Incomplete parameters for soil {sid}, skipping")
                        idx += 1
                        continue
                    
                    profile.soil_definitions.append({
                        'id': sid,
                        'model': model,
                        'name': name,
                        'theta_s': params[0],
                        'theta_r': params[1],
                        'alpha': params[2],
                        'n': params[3],
                        'k_sat': params[4],
                        'm': 1.0 - 1.0/params[3]  # Calculate m
                    })
                    
                    idx += 1
                
                print(f"  ✓ Loaded {len(profile.soil_definitions)} soil type(s)")
                
            except Exception as e:
                print(f"⚠ Error parsing soils.def: {e}")
        else:
            print(f"⚠ Soil definition file not found: {def_path}")

        # ═══════════════════════════════════════════════════════════
        # 2. Parse soil_horizons.bod
        # ═══════════════════════════════════════════════════════════
        bod_file = Path(bod_path)
        if bod_file.exists():
            try:
                with open(bod_file, 'r') as f:
                    lines = f.readlines()
                
                # Skip header line "HANG 1"
                data_lines = [l.strip() for l in lines[1:] if l.strip()]
                
                # Each line contains soil IDs (fixed width: 3 chars each)
                # Example: "  3  3  3  3  3..."
                soil_ids = []
                
                for line in data_lines:
                    # Split into 3-character chunks
                    # OR use simple split if space-separated
                    if '  ' in line:  # Fixed width format
                        # Parse as fixed-width (every 3 chars)
                        n_chars = len(line)
                        for i in range(0, n_chars, 3):
                            chunk = line[i:i+3].strip()
                            if chunk and chunk.replace('-','').isdigit():
                                soil_ids.append(int(chunk))
                    else:  # Space-separated
                        tokens = line.split()
                        soil_ids.extend([int(t) for t in tokens if t.replace('-','').isdigit()])
                
                profile.assignment_matrix = np.array(soil_ids, dtype=int)
                print(f"  ✓ Loaded {len(soil_ids)} soil assignments from {bod_file.name}")
                
            except Exception as e:
                print(f"⚠ Error parsing soil horizons: {e}")
        else:
            print(f"⚠ Soil assignment file not found: {bod_path}")
        
        return profile

    def write_soils_def(self, filepath: str):
        """Write soil definitions in CATFLOW format"""
        path = Path(filepath)
        path.parent.mkdir(parents=True, exist_ok=True)
        
        with open(path, 'w') as f:
            f.write(f"{len(self.soil_definitions)}          % Number of soil types\n")
            
            for s in self.soil_definitions:
                f.write(f"\n% Soil type {s['id']}: {s['name']}\n")
                f.write(f"{s['id']:3d}  {s.get('model', 1):2d}  '{s['name']}'\n")
                f.write(f"  {s['theta_s']:.4f}  {s['theta_r']:.4f}  ")
                f.write(f"{s['alpha']:.6f}  {s['n']:.4f}  {s['k_sat']:.6e}\n")

    def write_bod_file(self, filepath: str, n_layers: int, n_cols: int):
        """Write soil assignment matrix"""
        path = Path(filepath)
        path.parent.mkdir(parents=True, exist_ok=True)
        
        # Validate and reshape
        if self.assignment_matrix.size == 0:
            print("⚠ No soil assignment data, creating default (all type 1)")
            mat = np.ones((n_layers, n_cols), dtype=int)
        elif self.assignment_matrix.size != n_layers * n_cols:
            print(f"⚠ Soil matrix size mismatch ({self.assignment_matrix.size} vs {n_layers*n_cols})")
            print("  Creating default matrix")
            mat = np.ones((n_layers, n_cols), dtype=int)
        else:
            mat = self.assignment_matrix.reshape(n_layers, n_cols)
        
        with open(path, 'w') as f:
            f.write(" HANG           1\n")
            for row in mat:
                # Fixed width format: 3 chars per value
                line = ''.join([f'{val:3d}' for val in row])
                f.write(f"{line}\n")

    def validate(self, n_layers: int, n_cols: int) -> List[str]:
        """
        Validate soil data consistency
        Returns list of warning/error messages
        """
        issues = []
        
        # Check if any soils defined
        if not self.soil_definitions:
            issues.append("ERROR: No soil types defined")
        
        # Check assignment matrix
        if self.assignment_matrix.size == 0:
            issues.append("WARNING: No soil assignments")
        elif self.assignment_matrix.size != n_layers * n_cols:
            issues.append(f"ERROR: Soil matrix size {self.assignment_matrix.size} doesn't match mesh {n_layers}×{n_cols}")
        
        # Check all assigned IDs exist
        if self.assignment_matrix.size > 0 and self.soil_definitions:
            defined_ids = {s['id'] for s in self.soil_definitions}
            assigned_ids = set(np.unique(self.assignment_matrix))
            missing = assigned_ids - defined_ids
            
            if missing:
                issues.append(f"ERROR: Soil IDs in assignment not defined: {missing}")
        
        # Check parameter validity
        for s in self.soil_definitions:
            if not (0 <= s['theta_r'] < s['theta_s'] <= 1):
                issues.append(f"ERROR: Invalid water content for {s['name']}: θr={s['theta_r']}, θs={s['theta_s']}")
            if s['alpha'] <= 0:
                issues.append(f"ERROR: Invalid alpha for {s['name']}: {s['alpha']}")
            if s['n'] <= 1:
                issues.append(f"ERROR: Invalid n for {s['name']}: {s['n']}")
            if s['k_sat'] <= 0:
                issues.append(f"ERROR: Invalid k_sat for {s['name']}: {s['k_sat']}")
        
        return issues
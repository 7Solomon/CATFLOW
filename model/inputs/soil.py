import numpy as np
from dataclasses import dataclass, field
from pathlib import Path
from typing import List, Dict, Any
import re

@dataclass
class SoilProfile:
    soil_definitions: List[Dict[str, Any]] = field(default_factory=list)
    assignment_matrix: np.ndarray = field(default_factory=lambda: np.array([]))
    profile_ranges: List[Dict[str, float]] = field(default_factory=list)

    @classmethod
    def from_files(cls, def_path: str, bod_path: str) -> 'SoilProfile':
        profile = cls()
        
        # 1. PARSE SOILS.DEF
        def_file = Path(def_path)
        if def_file.exists():
            try:
                with open(def_file, 'r') as f:
                    lines = []
                    for l in f.readlines():
                        clean = l.split('%')[0].strip()
                        if clean: lines.append(clean)
                
                if lines:
                    n_soils = int(lines[0].split()[0])
                    current_line = 1
                    
                    for i in range(n_soils):
                        if current_line >= len(lines): break
                        
                        # Line A: Name
                        name = lines[current_line].strip("'\"")
                        current_line += 1
                        
                        # Line B: Model ID + Flags
                        if current_line >= len(lines): break
                        flag_vals = [float(x) for x in lines[current_line].split()]
                        model = int(flag_vals[0]) if flag_vals else 1
                        current_line += 1
                        
                        # Line C: Parameters
                        if current_line >= len(lines): break
                        params = [float(x) for x in lines[current_line].split()]
                        current_line += 1
                        
                        # Skip extra 0 lines
                        while current_line < len(lines):
                            if re.match(r'^0\.?\s+0\.?\s+0\.?', lines[current_line]):
                                current_line += 1
                            else:
                                break
                        
                        if len(params) >= 5:
                            # Standard Format: Ts, Tr, Alpha, n, Ks
                            if params[0] < 1e-3 and params[3] > 1.0: # Legacy (Ks first)
                                ks, ts, tr, alpha, n = params[0], params[1], params[2], params[3], params[4]
                            else:
                                ts, tr, alpha, n, ks = params[0], params[1], params[2], params[3], params[4]

                            profile.soil_definitions.append({
                                'id': i + 1,
                                'name': name,
                                'model': model,
                                'theta_s': ts, 'theta_r': tr,
                                'alpha': alpha, 'n': n, 'k_sat': ks
                            })

            except Exception as e:
                print(f"⚠ Error parsing soils.def: {e}")

        # 2. PARSE .BOD
        bod_file = Path(bod_path)
        if bod_file.exists():
            try:
                with open(bod_file, 'r') as f:
                    lines = []
                    for l in f.readlines():
                        clean = l.split('%')[0].strip()
                        if clean: lines.append(clean)

                if lines:
                    first_line = lines[0]
                    if first_line.upper().startswith('B') or "HANG" in first_line.upper():
                        print(f" → Detected MATRIX MODE (Header: {first_line.split()[0]})")
                        all_ids = []
                        for l in lines[1:]:
                            all_ids.extend([int(float(x)) for x in l.split()])
                        profile.assignment_matrix = np.array(all_ids, dtype=int)
                    else:
                        parts = first_line.split()
                        ianz = int(parts[0])
                        print(f" → Detected DEFINITION MODE (Count={ianz})")
                        for i in range(ianz):
                            line_idx = i + 1
                            if line_idx >= len(lines): break
                            p = [float(x) for x in lines[line_idx].split()]
                            if len(p) >= 5:
                                profile.profile_ranges.append({
                                    'start_v': p[0], 'end_v': p[1],
                                    'start_l': p[2], 'end_l': p[3],
                                    'soil_id': int(p[4])
                                })
            except Exception as e:
                print(f"⚠ Error parsing bod file: {e}")

        return profile

    def apply_profile_to_mesh(self, n_layers: int, n_cols: int, eta=None, xsi=None) -> np.ndarray:
        if not self.profile_ranges:
            if self.assignment_matrix.size == n_layers * n_cols:
                return self.assignment_matrix.reshape(n_layers, n_cols)
            return np.ones((n_layers, n_cols), dtype=int)

        if eta is None: eta = np.linspace(0, 1, n_layers)
        if xsi is None: xsi = np.linspace(0, 1, n_cols)
        
        matrix = np.ones((n_layers, n_cols), dtype=int)
        for r in self.profile_ranges:
            sid = r['soil_id']
            v_mask = (eta >= min(r['start_v'], r['end_v'])) & (eta <= max(r['start_v'], r['end_v']))
            l_mask = (xsi >= min(r['start_l'], r['end_l'])) & (xsi <= max(r['start_l'], r['end_l']))
            
            for i in range(n_layers):
                if v_mask[i]:
                    for j in range(n_cols):
                        if l_mask[j]: matrix[i, j] = sid
        self.assignment_matrix = matrix
        return matrix
        
    def validate(self, n_layers, n_cols):
        issues = []
        if not self.soil_definitions:
            issues.append("ERROR: No soil types defined")
        if self.assignment_matrix.size > 0:
            if self.assignment_matrix.size != n_layers * n_cols:
                issues.append(f"ERROR: Matrix size {self.assignment_matrix.size} != {n_layers*n_cols}")
        return issues

    def write_soils_def(self, filepath: str):
        """Writes soils.def file"""
        lines = []
        lines.append(f"{len(self.soil_definitions)}  % Number of soils")
        
        for s in self.soil_definitions:
            lines.append(f"'{s['name']}'")
            # Standard Flags: Model ID, 800, Anisotropy...
            lines.append(f"{s['model']} 800 1.00 1.00 0.09 0.50 0.34 0.11 20.00 0.70 0.05 1.00 1.00 1.00")
            # Standard Parameters: Ts Tr Alpha n Ks
            # Note: Ks in m/s
            lines.append(f"{s['theta_s']:.4f} {s['theta_r']:.4f} {s['alpha']:.4f} {s['n']:.4f} {s['k_sat']:.2e}")
            lines.append("0. 0. 0.  % Dummy blocks")
            lines.append("0. 0. 0.")
            lines.append("0. 0. 0.")
            
        with open(filepath, 'w') as f:
            f.write('\n'.join(lines))

    def write_bod_file(self, filepath: str, n_layers: int, n_cols: int):
        """Writes assignment matrix to .bod file"""
        
        if self.assignment_matrix.size == 0 and self.profile_ranges:
            print(f"    (Auto-generating soil matrix from {len(self.profile_ranges)} profile ranges)")
            self.apply_profile_to_mesh(n_layers, n_cols)
            
        # Check size again
        needed_size = n_layers * n_cols
        if self.assignment_matrix.size != needed_size:
            # Last ditch effort: if still empty, fill with Default Soil 1
            if self.assignment_matrix.size == 0:
                print("    (Warning: No soil data found. Defaulting entire mesh to Soil ID 1)")
                self.assignment_matrix = np.ones((n_layers, n_cols), dtype=int)
            else:
                raise ValueError(f"Assignment matrix size {self.assignment_matrix.size} does not match mesh {needed_size}")
            
        lines = []
        # Matrix Mode Header: B NV NL HangID
        lines.append(f"B   {n_layers}   {n_cols}    1")
        
        # Flatten and Reshape to ensure correct 2D structure
        # Note: CATFLOW usually expects Row 1 (Top) to Row N (Bottom)
        flat = self.assignment_matrix.flatten()
        mat = flat.reshape(n_layers, n_cols)
        
        # Write row by row
        for i in range(n_layers):
            row_str = " ".join(str(x) for x in mat[i])
            lines.append(row_str)
            
        with open(filepath, 'w') as f:
            f.write('\n'.join(lines))
        print(f"✓ Wrote soil assignment to {filepath}")

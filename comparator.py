import difflib
from pathlib import Path
from typing import List, Dict, Optional, Tuple
import re

class CATFLOWComparator:
    def __init__(self, folder_a: str, folder_b: str):
        self.a = Path(folder_a).resolve()
        self.b = Path(folder_b).resolve()

    def compare(self):
        print(f"\n{'='*70}")
        print(f"CATFLOW PROJECT COMPARISON")
        print(f"{'='*70}")
        print(f"Source A (Legacy): {self.a}")
        print(f"Source B (New):    {self.b}\n")
        
        # 1. Compare Run Files
        run_a = self._find_run_file(self.a)
        run_b = self._find_run_file(self.b)
        
        if not run_a or not run_b:
            print("⚠ Could not find run_01.in in one or both folders.")
            return

        print(f"Comparing Run Control: {run_a.name} vs {run_b.name}")
        self._compare_files(run_a, run_b)
        
        # 2. Build Role Map (Functional Comparison)
        # We parse the run files to find what 'geo', 'bod', etc. correspond to
        roles_a = self._parse_run_roles(run_a)
        roles_b = self._parse_run_roles(run_b)
        
        all_roles = sorted(set(roles_a.keys()) | set(roles_b.keys()))
        
        print("\nComparing Simulation Files (by Role):")
        for role in all_roles:
            path_a = roles_a.get(role)
            path_b = roles_b.get(role)
            
            # Label for display (e.g., "Hill 1 Geometry")
            label = role.replace('_', ' ').title()
            
            if path_a and path_b:
                # Resolve full paths
                full_a = self.a / path_a
                full_b = self.b / path_b
                
                if full_a.exists() and full_b.exists():
                    self._compare_files(full_a, full_b, label=f"{label} ({path_b.name})")
                else:
                    print(f" ⚠ File missing on disk for {label}")
            elif path_a:
                print(f" ❌ {label} missing in New project (Old: {path_a})")
            elif path_b:
                print(f" ➕ {label} added in New project (New: {path_b})")

    def _find_run_file(self, folder: Path) -> Path:
        # Check CATFLOW.IN first
        cf = folder / "CATFLOW.IN"
        if cf.exists():
            try:
                with open(cf, 'r') as f:
                    name = f.readline().split()[0].strip()
                    return folder / name
            except: pass
        # Fallback
        matches = list(folder.glob("run_*.in"))
        return matches[0] if matches else None

    def _parse_run_roles(self, run_file: Path) -> Dict[str, Path]:
        """
        Parses run_01.in to map functional roles to file paths.
        Also recursively parses definition files (lu_file.def, timeser.def) 
        to find secondary assets.
        """
        roles = {}
        with open(run_file, 'r') as f:
            lines = [l.split('%')[0].strip() for l in f if l.split('%')[0].strip()]
            
        # ... (Same logic to find output block) ...
        idx = 0
        n_outputs = 0
        for i, line in enumerate(lines):
            if i>0 and len(line)>5 and all(c in '01 ' for c in line):
                 if lines[i-1].isdigit():
                     n_outputs = int(lines[i-1])
                     idx = i - 1
                     break
        
        if idx == 0: return {} 
        
        idx += 1 + 1 + n_outputs
        idx += 1 # Skip count
        
        # 1. Global Files
        roles['global_soil'] = Path(lines[idx]); idx += 1
        
        # TIME SERIES Config
        p_time = Path(lines[idx]); idx += 1
        roles['global_time'] = p_time
        self._parse_timeser_deps(run_file.parent, p_time, roles) # <--- NEW
        
        # LAND USE Config
        p_lu = Path(lines[idx]); idx += 1
        roles['global_landuse'] = p_lu
        self._parse_landuse_deps(run_file.parent, p_lu, roles) # <--- NEW
        
        roles['global_wind'] = Path(lines[idx]); idx += 1
        
        # ... (Rest of Hill loop) ...
        # (Copy your existing hill loop here)
        n_hills = abs(int(lines[idx])); idx += 1
        for h in range(n_hills):
            prefix = f"hill_{h+1}"
            roles[f'{prefix}_geo'] = Path(lines[idx]); idx += 1
            roles[f'{prefix}_bod'] = Path(lines[idx]); idx += 1
            roles[f'{prefix}_kstat'] = Path(lines[idx]); idx += 1
            roles[f'{prefix}_thstat'] = Path(lines[idx]); idx += 1
            roles[f'{prefix}_mak'] = Path(lines[idx]); idx += 1
            roles[f'{prefix}_cv'] = Path(lines[idx]); idx += 1
            roles[f'{prefix}_ini'] = Path(lines[idx]); idx += 1
            roles[f'{prefix}_prt'] = Path(lines[idx]); idx += 1
            roles[f'{prefix}_pob'] = Path(lines[idx]); idx += 1
            roles[f'{prefix}_rb'] = Path(lines[idx]); idx += 1
            
        return roles

    def _parse_landuse_deps(self, root: Path, rel_path: Path, roles: Dict):
        """Finds .par files inside lu_file.def"""
        full_path = root / rel_path
        if not full_path.exists(): return
        
        try:
            with open(full_path, 'r') as f:
                lines = [l.strip() for l in f if l.strip()]
            
            for line in lines:
                parts = line.split()
                if len(parts) >= 3:
                    # Format: ID Name Path
                    lu_name = parts[1]
                    par_path = Path(parts[2])
                    roles[f'landuse_par_{lu_name}'] = par_path
        except: pass

    def _parse_timeser_deps(self, root: Path, rel_path: Path, roles: Dict):
        """Finds .dat files inside timeser.def"""
        full_path = root / rel_path
        if not full_path.exists(): return
        
        try:
            with open(full_path, 'r') as f:
                lines = [l.strip() for l in f if l.strip()]
            
            iterator = iter(lines)
            while True:
                try:
                    line = next(iterator).upper()
                    if "NIEDERSCHLAG" in line:
                        count = int(next(iterator))
                        for i in range(count):
                            roles[f'precip_{i}'] = Path(next(iterator))
                    elif "KLIMA" in line:
                        count = int(next(iterator))
                        for i in range(count):
                            roles[f'climate_{i}'] = Path(next(iterator))
                except StopIteration:
                    break
        except: pass

    def _tokenize_line(self, line: str) -> List[str]:
        # Remove comments
        clean = line.split('%')[0].split('#')[0].strip()
        if not clean: return []
        
        # Split tokens
        raw_tokens = clean.split()
        normalized = []
        
        for t in raw_tokens:
            try:
                # Try to parse as float
                val = float(t)
                # Format consistently: 6 decimal places scientific
                # This makes 1.00 and 1.0 equal string wise for diff
                normalized.append(f"{val:.6e}")
            except ValueError:
                # Keep as string (e.g. 'pic', 'Laubwald')
                # Remove quotes for comparison
                normalized.append(t.replace("'", "").replace('"', ""))
                
        return normalized

    def _compare_files(self, file_a: Path, file_b: Path, label: str = None):
        try:
            with open(file_a, 'r') as f: lines_a = f.readlines()
            with open(file_b, 'r') as f: lines_b = f.readlines()
        except:
            print(f"  ⚠ Could not read files for {label or file_a.name}")
            return

        name = label or file_a.name
        
        # Preprocess lines
        tok_a = [self._tokenize_line(l) for l in lines_a]
        tok_b = [self._tokenize_line(l) for l in lines_b]
        
        # Remove empty lines
        tok_a = [t for t in tok_a if t]
        tok_b = [t for t in tok_b if t]
        
        # Compare token streams
        if tok_a == tok_b:
            print(f"  ✅ {name}: Semantically Identical")
            return

        # If not identical, find first difference
        diffs = 0
        max_diffs_to_show = 3
        
        print(f"  ⚠️ {name}: Content differs")
        
        # Compare line by line (best effort matching)
        limit = min(len(tok_a), len(tok_b))
        for i in range(limit):
            if tok_a[i] != tok_b[i]:
                diffs += 1
                if diffs <= max_diffs_to_show:
                    print(f"    Line {i+1} mismatch:")
                    print(f"      OLD: {tok_a[i]}")
                    print(f"      NEW: {tok_b[i]}")
        
        if len(tok_a) != len(tok_b):
            print(f"    Line count mismatch: {len(tok_a)} vs {len(tok_b)}")

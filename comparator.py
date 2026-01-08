import difflib
from pathlib import Path
from typing import List, Dict, Set

class CATFLOWComparator:
    """
    Compares two CATFLOW project folders to identify differences in configuration and data files.
    """
    
    def __init__(self, folder_a: str, folder_b: str):
        self.a = Path(folder_a).resolve()
        self.b = Path(folder_b).resolve()
        self.report = []

    def compare(self):
        print(f"\n{'='*70}")
        print(f"CATFLOW PROJECT COMPARISON")
        print(f"{'='*70}")
        print(f"Source A (Legacy): {self.a}")
        print(f"Source B (New):    {self.b}\n")
        
        # 1. Compare Run Files
        run_file_a = self._find_run_file(self.a)
        run_file_b = self._find_run_file(self.b)
        
        if run_file_a and run_file_b:
            print(f"Comparing Run Files: {run_file_a.name} vs {run_file_b.name}")
            self._compare_files(run_file_a, run_file_b)
        else:
            print("⚠ Could not pair run files for comparison.")

        # 2. Compare Common Input Files
        # We look for files with same relative paths or names
        files_a = self._map_files(self.a)
        files_b = self._map_files(self.b)
        
        all_keys = sorted(set(files_a.keys()) | set(files_b.keys()))
        
        print("\nComparing Input Files:")
        for key in all_keys:
            path_a = files_a.get(key)
            path_b = files_b.get(key)
            
            if path_a and path_b:
                self._compare_files(path_a, path_b, label=key)
            elif path_a:
                print(f"  ❌ {key} missing in New project")
            elif path_b:
                print(f"  ➕ {key} added in New project")

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

    def _map_files(self, folder: Path) -> Dict[str, Path]:
        """Maps simplified filenames to full paths for comparison"""
        mapping = {}
        for f in folder.rglob("*"):
            if f.is_file() and f.suffix in ['.in', '.geo', '.def', '.bod', '.prt', '.rb', '.pob']:
                if f.name.lower() == 'catflow.in': continue
                # Use filename as key to handle directory structure changes
                mapping[f.name.lower()] = f
        return mapping

    def _compare_files(self, file_a: Path, file_b: Path, label: str = None):
        """Intelligent comparison of two text files"""
        try:
            with open(file_a, 'r') as f: lines_a = [l.strip() for l in f.readlines() if l.strip()]
            with open(file_b, 'r') as f: lines_b = [l.strip() for l in f.readlines() if l.strip()]
        except:
            print(f"  ⚠ Could not read files for {label or file_a.name}")
            return

        name = label or file_a.name
        
        # Simple exact check
        if lines_a == lines_b:
            print(f"  ✅ {name}: Identical")
            return

        # Detailed Diff
        diff = list(difflib.unified_diff(lines_a, lines_b, n=0))
        # Filter out comment differences usually starting with %
        significant_diffs = [d for d in diff if not (d.startswith('---') or d.startswith('+++') or d.startswith('@@'))]

        if len(significant_diffs) > 0:
            print(f"  ⚠️ {name}: {len(significant_diffs)} differences found")
            # Print first 3 diffs
            for d in significant_diffs[:20]:
                prefix = "OLD: " if d.startswith('-') else "NEW: "
                print(f"      {prefix}{d[1:].strip()}")
            if len(significant_diffs) > 20:
                print("      ...")
                print("TO MANY")
        else:
            print(f"  ✅ {name}: Content matches (ignoring whitespace/comments)")


"""
CATFLOW Project Diagnostic Tool v2
Updated for Profile-based Soil Assignment and Flexible Headers
"""
from pathlib import Path
from typing import List, Dict, Tuple
import re

class CATFLOWDiagnostic:
    
    def __init__(self, project_folder: str):
        self.folder = Path(project_folder).resolve()
        self.issues = []
        self.warnings = []
        self.info = []
        
    def run_full_diagnostic(self) -> Dict[str, List[str]]:
        print(f"\n{'='*70}")
        print(f"CATFLOW PROJECT DIAGNOSTIC (Profile Support)")
        print(f"{'='*70}")
        print(f"Location: {self.folder}\n")
        
        self.check_folder_structure()
        self.check_control_files()
        self.check_geometry()
        self.check_soil_files()
        self.check_forcing()
        self.check_optional_files()
        
        self.print_report()
        
        return {'errors': self.issues, 'warnings': self.warnings, 'info': self.info}
    
    def check_folder_structure(self):
        print("📁 Checking folder structure...")
        if not self.folder.exists():
            self.issues.append(f"Project folder does not exist: {self.folder}")
            return
        
        expected_dirs = ['in/hillgeo', 'in/soil', 'in/control', 'in/landuse', 'in/climate', 'out']
        for dir_path in expected_dirs:
            if not (self.folder / dir_path).exists():
                self.warnings.append(f"Missing directory: {dir_path}")
        print("   ✓ Folder structure checked\n")
    
    def check_control_files(self):
        print("⚙️  Checking control files...")
        catflow_in = self.folder / "CATFLOW.IN"
        if not catflow_in.exists():
            self.issues.append("MISSING: CATFLOW.IN")
            return

        try:
            with open(catflow_in, 'r') as f:
                run_file_name = f.readline().split()[0].strip()
            
            run_file = self.folder / run_file_name
            if not run_file.exists():
                self.issues.append(f"MISSING: Run file {run_file_name}")
                return
                
            self.info.append(f"Run file: {run_file_name}")
            print("   ✓ Control files checked\n")
            
        except Exception as e:
            self.issues.append(f"Error reading control files: {e}")

    def check_geometry(self):
        """Check geometry file with flexible header"""
        print("🗺️  Checking geometry...")
        geo_files = list(self.folder.rglob("*.geo"))
        
        if not geo_files:
            self.issues.append("MISSING: No .geo file found")
            return
        
        geo_file = geo_files[0]
        self.info.append(f"Geometry file: {geo_file.relative_to(self.folder)}")
        
        try:
            with open(geo_file, 'r') as f:
                content = f.read()
            
            # FIXED: Regex matches start of line, optional HANG, then two integers
            match = re.search(r'^\s*(?:HANG)?\s*(\d+)\s+(\d+)', content, re.MULTILINE)
            if match:
                n_layers = int(match.group(1))
                n_cols = int(match.group(2))
                self.info.append(f"   Dimensions: {n_layers} layers × {n_cols} columns")
                self.geo_dims = (n_layers, n_cols)
            else:
                self.issues.append("   Could not parse geometry dimensions (Header missing)")
            
            print("   ✓ Geometry checked\n")
            
        except Exception as e:
            self.issues.append(f"Error reading geometry file: {e}")
    
    def check_soil_files(self):
        """Check soils with multi-line parameters and profile definitions"""
        print("🌱 Checking soil files...")
        
        # 1. Check definitions (soils.def)
        soil_defs = list(self.folder.rglob("soils.def"))
        if not soil_defs:
            self.issues.append("MISSING: soils.def")
            return
        
        self.soil_ids = set()
        try:
            with open(soil_defs[0], 'r') as f:
                lines = [l.strip() for l in f.readlines() if l.strip()]
                
            n_soils = int(lines[0])
            self.info.append(f"   {n_soils} soil types defined")
            
            idx = 1
            count = 0
            while count < n_soils and idx < len(lines):
                # FIXED: Read ID and Name (no quotes required)
                parts = lines[idx].split(None, 1)
                if len(parts) >= 1 and parts[0].isdigit():
                    sid = int(parts[0])
                    name = parts[1] if len(parts) > 1 else "Unknown"
                    self.soil_ids.add(sid)
                    count += 1
                    
                    # Skip parameter lines (heuristic: starts with number)
                    idx += 1
                    while idx < len(lines):
                        # Stop if we hit a new ID line (int followed by text) or just loop fixed amount
                        # Heuristic: If line implies parameters (floats), skip it.
                        # If line implies "0. 0. 0.", skip it.
                        if idx + 1 < len(lines) and lines[idx+1].split()[0].isdigit() and '.' not in lines[idx+1].split()[0]:
                             # Next line looks like a new ID
                             break
                        # Simple skip for standard 3-4 line block
                        if "0. 0. 0." in lines[idx]:
                             pass 
                        idx += 1
                else:
                    idx += 1
                    
        except Exception as e:
            self.issues.append(f"Error parsing soils.def: {e}")

        # 2. Check assignments (.bod)
        bod_files = list(self.folder.rglob("*.bod"))
        if not bod_files:
            self.warnings.append("No .bod file found")
            return
            
        bod_file = bod_files[0]
        self.info.append(f"Soil assignments: {bod_file.relative_to(self.folder)}")
        
        try:
            with open(bod_file, 'r') as f:
                lines = [l.strip() for l in f.readlines() if l.strip()]
                
            # Filter comments
            lines = [l for l in lines if not l.startswith('%')]
            
            # Detect if Matrix or Profile
            data_lines = lines[1:] if len(lines[0].split()) <= 2 else lines
            
            # Heuristic: Profile definition has floats (0.0 0.8), Matrix has ints (1 1 2)
            is_profile = '.' in data_lines[0] 
            
            if is_profile:
                self.info.append("   Format: Profile/Horizon definition (Depth ranges)")
                # Validate ranges
                assigned_ids = set()
                for line in data_lines:
                    clean = line.split('%')[0] # Remove trailing comments
                    parts = clean.split()
                    if len(parts) >= 5: # Start End ? ? ID
                        try:
                            sid = int(parts[4])
                            assigned_ids.add(sid)
                        except: pass
                
                undefined = assigned_ids - self.soil_ids
                if undefined:
                    self.issues.append(f"   Undefined soil IDs in profile: {undefined}")
                else:
                    self.info.append("   ✓ All referenced soil IDs are valid")
                    
            else:
                self.info.append("   Format: Node-by-node Matrix")
                # (Existing matrix logic could go here)
                
        except Exception as e:
            self.issues.append(f"Error parsing .bod file: {e}")
            
        print("   ✓ Soil files checked\n")

    def check_forcing(self):
        print("🌦️  Checking forcing data...")
        # Simple existence check
        forcing_files = list(self.folder.rglob("*precip*")) + list(self.folder.rglob("*timeser*"))
        if not forcing_files:
            self.warnings.append("No forcing/rainfall files found")
        else:
             # FIXED: Check if it's a file before printing
            valid_files = [f for f in forcing_files if f.is_file()]
            self.info.append(f"Found {len(valid_files)} forcing files")
        print("   ✓ Forcing checked\n")

    def check_optional_files(self):
        print("📋 Checking optional files...")
        # Just report existence
        for pattern in ['printout.prt', 'surface.pob', 'boundary.rb']:
            found = list(self.folder.rglob(pattern))
            if found:
                self.info.append(f"Found {pattern}")
        print("   ✓ Optional files checked\n")

    def print_report(self):
        print("\n" + "="*70)
        print("DIAGNOSTIC REPORT")
        print("="*70 + "\n")
        
        if self.issues:
            print("❌ ERRORS:")
            for i in self.issues: print(f"   • {i}")
        else:
            print("✅ No critical errors found!")
            
        if self.warnings:
            print("\n⚠️  WARNINGS:")
            for w in self.warnings: print(f"   • {w}")
            
        print("\n" + "="*70 + "\n")

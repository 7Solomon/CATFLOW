import numpy as np
import pickle
from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, Any, Optional, List
import re

from model.config import GlobalConfig, RunControl
from model.inputs.boundaries.conditions import ForcingData, InitialConditions
from model.inputs.boundaries.definitions import BoundaryDefinition
from model.inputs.landuse.landuse import LandUseDefinition
from model.inputs.mesh import HillslopeMesh
from model.inputs.soil import SoilProfile
from model.inputs.surface.surface import SurfaceProperties
from model.outputs import SimulationResults
from model.printout import PrintoutTimes
from utils import create_minimal_required_files



@dataclass
class CATFLOWProject:

    name: str = "New Project"
    
    # Core components
    mesh: Optional[HillslopeMesh] = None
    soils: Optional[SoilProfile] = None
    
    #Boundaries
    boundary: Optional[BoundaryDefinition] = None
    forcing: Optional[ForcingData] = None
    initial: Optional[InitialConditions] = None

    surface: Optional[SurfaceProperties] = None
    land_use: Optional[LandUseDefinition] = None
    printout: Optional[PrintoutTimes] = None
    
    # Simulation Control
    settings: Dict[str, RunControl | GlobalConfig] = field(default_factory=dict)
    _legacy_paths: Dict[str, str] = field(default_factory=dict)
    
    
    results: Optional[SimulationResults] = None

    def save(self, filename: str):
        """Binary save of entire project state"""
        with open(f"{filename}.pkl", 'wb') as f:
            pickle.dump(self, f)
        print(f"✓ Project saved to {filename}")

    @classmethod
    def load(cls, filename: str) -> 'CATFLOWProject':
        """Binary load"""
        with open(f"{filename}.pkl", 'rb') as f:
            return pickle.load(f)

    @classmethod
    def from_legacy_folder(cls, folder_path: str, run_file: str = "run_01.in") -> 'CATFLOWProject':
        """
        Enhanced loader with better error handling and file discovery
        """
        folder = Path(folder_path).resolve()
        project = cls(name=folder.name)
        
        print(f"\n{'='*60}")
        print(f"Loading CATFLOW Project from: {folder}")
        print(f"{'='*60}\n")
        
        # ═════════════════════════════════════════════════════════════
        # STEP 1: Resolve Run File
        # ═════════════════════════════════════════════════════════════
        run_path = folder / run_file
        
        if not run_path.exists():
            # Check CATFLOW.IN
            control_file = folder / "CATFLOW.IN"
            if control_file.exists():
                try:
                    with open(control_file) as f:
                        run_file_name = f.readline().split()[0].strip()
                        run_path = folder / run_file_name
                        print(f"→ Using run file from CATFLOW.IN: {run_file_name}")
                except Exception as e:
                    print(f"⚠ Could not read CATFLOW.IN: {e}")
        
        if not run_path.exists():
            raise FileNotFoundError(f"Run file not found: {run_file}")
        
        print(f"✓ Found run file: {run_path.name}\n")
        
        # ═════════════════════════════════════════════════════════════
        # STEP 2: Parse Run File
        # ═════════════════════════════════════════════════════════════
        try:
            with open(run_path, 'r') as f:
                lines = [l.rstrip() for l in f.readlines()]
        except Exception as e:
            raise IOError(f"Could not read run file: {e}")
        
        # Extract settings from header
        try:
            project.settings.update({
               'start_time': lines[0].split('%')[0].strip(),
                'end_time': lines[1].split('%')[0].strip(),
                'offset': float(lines[2].split('%')[0]),
                'method': lines[3].split('%')[0].strip(),
                'dtbach': float(lines[4].split('%')[0]),
                'qtol': float(lines[5].split('%')[0]),
                'dt_max': float(lines[6].split('%')[0]),
                'dt_min': float(lines[7].split('%')[0]),
                'dt_init': float(lines[8].split('%')[0])
            })
            print("✓ Parsed simulation settings")
        except (IndexError, ValueError) as e:
            raise ValueError(f"Run file header is malformed: {e}")
        
        # ═════════════════════════════════════════════════════════════
        # STEP 3: Discover File Paths
        # ═════════════════════════════════════════════════════════════
        paths = {}
        file_patterns = {
            'geo': [r'\.geo$', r'hillgeo', r'hang'],
            'soils_def': [r'soils\.def$'],
            'soils_bod': [r'horizons?\.bod$', r'boden\.dat$'],
            'timeser': [r'timeser', r'rainfall', r'niederschlag'],
            'printout': [r'printout\.prt$'],
            'surface': [r'surface\.pob$'],
            'boundary': [r'boundary\.rb$'],
            'lu_file': [r'lu_file\.def$', r'landuse'],
            'winddir': [r'winddir\.def$'],
            'initial': [r'\.ini$', r'rel_sat']
        }
        
        # Search run file for paths
        for line in lines:
            clean = line.split('%')[0].strip()
            
            # Skip if not a path
            if not clean or len(clean) < 4:
                continue
            if not ('/' in clean or '\\' in clean or '.' in clean):
                continue
            
            # Match against patterns
            for key, patterns in file_patterns.items():
                for pattern in patterns:
                    if re.search(pattern, clean, re.IGNORECASE):
                        full_path = folder / clean
                        if key not in paths:  # First match wins
                            paths[key] = full_path
                        break
        
        project._legacy_paths = {k: str(v) for k, v in paths.items()}
        
        # Report findings
        print("\nDiscovered files:")
        for key, path in sorted(paths.items()):
            exists = "✓" if path.exists() else "✗ MISSING"
            print(f"  {exists} {key:12s}: {path.relative_to(folder)}")
        
        # ═════════════════════════════════════════════════════════════
        # STEP 4: Validate Required Files
        # ═════════════════════════════════════════════════════════════
        required = ['geo', 'soils_def', 'soils_bod']
        missing = []
        
        for key in required:
            if key not in paths:
                missing.append(f"  ✗ {key}: not referenced in run file")
            elif not paths[key].exists():
                missing.append(f"  ✗ {key}: file not found at {paths[key]}")
        
        if missing:
            error_msg = "\n".join(["\n❌ MISSING REQUIRED FILES:"] + missing)
            error_msg += "\n\nCannot proceed without geometry and soil files."
            raise FileNotFoundError(error_msg)
        
        print("\n✓ All required files found\n")
        
        # ═════════════════════════════════════════════════════════════
        # STEP 5: Load Components
        # ═════════════════════════════════════════════════════════════
        print("Loading components...")
        
        # Load mesh
        try:
            print("  [1/3] Loading mesh...")
            project.mesh = HillslopeMesh.from_file(str(paths['geo']))
            print(f"        → {project.mesh.n_layers} layers × {project.mesh.n_columns} columns")
        except Exception as e:
            raise ValueError(f"Failed to load geometry: {e}")
        
        # Load soils
        try:
            print("  [2/3] Loading soils...")
            project.soils = SoilProfile.from_files(
                str(paths['soils_def']), 
                str(paths['soils_bod'])
            )
            
            # Validate and reshape
            if project.soils.assignment_matrix.size > 0:
                needed = project.mesh.n_layers * project.mesh.n_columns
                
                if project.soils.assignment_matrix.size == needed:
                    project.soils.assignment_matrix = project.soils.assignment_matrix.reshape(
                        project.mesh.n_layers, project.mesh.n_columns
                    )
                    print(f"        → Soil matrix reshaped to match mesh")
                else:
                    print(f"        ⚠ WARNING: Soil matrix size ({project.soils.assignment_matrix.size}) != mesh size ({needed})")
            
            # Validate soil data
            issues = project.soils.validate(project.mesh.n_layers, project.mesh.n_columns)
            if issues:
                print("\n        Validation issues:")
                for issue in issues:
                    print(f"        {issue}")
            
        except Exception as e:
            raise ValueError(f"Failed to load soils: {e}")
        
        # Load forcing (optional)
        try:
            if 'timeser' in paths and paths['timeser'].exists():
                print("  [3/3] Loading forcing data...")
                project.forcing = ForcingData.from_file(str(paths['timeser']))
                if not project.forcing.data.empty:
                    print(f"        → {len(project.forcing.data)} time steps")
            else:
                print("  [3/3] No forcing file (optional)")
        except Exception as e:
            print(f"        ⚠ Error loading forcing: {e}")
        
        # Load Raw Optional Files
        print("\n  Loading optional files...")
        for key, target_attr in [
            ('boundary', 'boundary_file'),
            ('lu_file', 'landuse_file'),
            ('printout', 'printout_file'),
            ('surface', 'surface_file'),
            ('winddir', 'winddir_file')
        ]:
            if key in paths and paths[key].exists():
                try:
                    print(f"    ✓ {key}")
                    setattr(project, target_attr, RawTextFile.from_file(str(paths[key])))
                except Exception as e:
                    print(f"    ⚠ Error loading {key}: {e}")
        
        print(f"\n{'='*60}")
        print(f"✓ Project loaded successfully")
        print(f"{'='*60}\n")
        
        return project

    def write_to_folder(self, folder_path: str):
        """
        Enhanced export with all components
        """
        base = Path(folder_path)
        base.mkdir(parents=True, exist_ok=True)
        
        print(f"\n{'='*60}")
        print(f"Writing CATFLOW Project to: {base}")
        print(f"{'='*60}\n")
        
        # Define file structure
        file_structure = {
            'geo': 'in/hillgeo/hang1.geo',
            'soils_def': 'in/soil/soils.def',
            'soils_bod': 'in/soil/soil_horizons.bod',
            'timeser': 'in/control/timeser.def',
            'printout': 'in/control/printout.prt',
            'surface': 'in/landuse/surface.pob',
            'boundary': 'in/control/boundary.rb',
            'lu_file': 'in/landuse/lu_file.def',
            'winddir': 'in/climate/winddir.def',
            'run': 'run_01.in'
        }
        
        # Write core components
        written_files = []
        
        if self.mesh:
            print("  [1/5] Writing mesh...")
            path = base / file_structure['geo']
            path.parent.mkdir(parents=True, exist_ok=True)
            self.mesh.to_file(str(path))
            written_files.append(file_structure['geo'])
        
        if self.soils:
            print("  [2/5] Writing soils...")
            path = base / file_structure['soils_def']
            path.parent.mkdir(parents=True, exist_ok=True)
            self.soils.write_soils_def(str(path))
            written_files.append(file_structure['soils_def'])
            
            if self.mesh:
                path = base / file_structure['soils_bod']
                path.parent.mkdir(parents=True, exist_ok=True)
                self.soils.write_bod_file(str(path), self.mesh.n_layers, self.mesh.n_columns)
                written_files.append(file_structure['soils_bod'])
        
        if self.forcing:
            print("  [3/5] Writing forcing...")
            path = base / file_structure['timeser']
            path.parent.mkdir(parents=True, exist_ok=True)
            self.forcing.to_file(str(path))
            written_files.append(file_structure['timeser'])
        
        # Write Raw Optional Files
        print("  [4/5] Writing optional files...")
        if self.boundary_file:
            path = base / file_structure['boundary']
            path.parent.mkdir(parents=True, exist_ok=True)
            self.boundary_file.to_file(str(path))
            written_files.append(file_structure['boundary'])
        if self.landuse_file:
            path = base / file_structure['lu_file']
            path.parent.mkdir(parents=True, exist_ok=True)
            self.landuse_file.to_file(str(path))
            written_files.append(file_structure['lu_file'])
        if self.printout_file:
            path = base / file_structure['printout']
            path.parent.mkdir(parents=True, exist_ok=True)
            self.printout_file.to_file(str(path))
            written_files.append(file_structure['printout'])
        if self.surface_file:
            path = base / file_structure['surface']
            path.parent.mkdir(parents=True, exist_ok=True)
            self.surface_file.to_file(str(path))
            written_files.append(file_structure['surface'])
        if self.winddir_file:
            path = base / file_structure['winddir']
            path.parent.mkdir(parents=True, exist_ok=True)
            self.winddir_file.to_file(str(path))
            written_files.append(file_structure['winddir'])
        
        # Write minimal required files that may be missing
        print("  [6/6] Creating required stub files...")
        
        # Ensure 'in' and subfolders exist for stubs too
        (base / 'in/control').mkdir(parents=True, exist_ok=True)
        (base / 'in/landuse').mkdir(parents=True, exist_ok=True)
        (base / 'in/climate').mkdir(parents=True, exist_ok=True)
        
        create_minimal_required_files(base)
        
        # Write run file
        print("  [7/7] Writing run configuration...")
        self._write_run_file(base / file_structure['run'], file_structure)
        
        # Write CATFLOW.IN
        with open(base / "CATFLOW.IN", "w") as f:
            f.write(f"run_01.in                       2.0\n")
        
        print(f"\n✓ Exported {len(written_files)} files")
        print(f"{'='*60}\n")


    def _write_run_file(self, run_path: Path, file_map: Dict[str, str]):
        """
        Generate complete run file
        """
        s = self.settings
        
        # Date Handling: Preserve original string if available
        # Ensure dates have time component
        start = s.get('start_time', '01.01.2000 00:00:00.00')
        end = s.get('end_time', '02.01.2000 00:00:00.00')
        
        if len(start) <= 10:
            start += " 00:00:00.00"
        if len(end) <= 10:
            end += " 00:00:00.00"
        
        # Output files
        outputs = [
            ('out/log.out', 'Log file'),
            ('out/bilanz.csv', 'Water balance'),
            ('out/theta.out', 'Soil moisture'),
            ('out/psi.out', 'Pressure head')
        ]
        
        # Build file content
        lines = [
            f"{start}          % start time",
            f"{end}          % end time",
            f"        {s.get('offset', 0.0):.1f}                     % offset",
            f"{s.get('method', 'pic'):<30s}% computation method",
            f"       {s.get('dtbach', 3600.0):.1f}                    % dtbach [s]",
            f"          {s.get('qtol', 1.e-6):.1e}                 % qtol",
            f"      {s.get('dt_max', 3600.0):.2f}                    % dt_max [s]",
            f"          {s.get('dt_min', 0.01):.2f}                  % dt_min [s]",
            f"         {s.get('dt_init', 10.0):.2f}                  % dt [s] initial",
            "          0.030                 % d_Th_opt",
            "          0.030                 % d_Phi_opt",
            "          5                     % n_gr",
            "         12                     % it_max",
            "          1.e-3                 % piceps",
            "          5.e-6                 % cgeps",
            "         15.0                    % rlongi",
            "          9.746                 % longi",
            "         47.35                  % lati",
            "          0                     % istact (number of solutes)",
            "        -80                     % Random seed",
            
            "          0                          % interaction with drainage network (0=noiact)", 
            
            f"     {len(outputs)}                         % number of output files",
        ]
        
        # Output flags (all enabled) - Ensure Integer format!
        lines.append('  ' + '  '.join(['1'] * len(outputs)))
        
        # Output file paths
        for path, desc in outputs:
            lines.append(f"{path:<40}% {desc}")
        
        # Input files (in groups separated by -1)
        input_groups = [
            # Group 1
            [file_map.get('soils_def', 'in/soil/soils.def'),
             file_map.get('timeser', 'in/control/timeser.def'),
             file_map.get('lu_file', 'in/landuse/lu_file.def'),
             file_map.get('winddir', 'in/climate/winddir.def')],
             
            # Group 2
            [file_map.get('geo', 'in/hillgeo/hang1.geo'),
             file_map.get('soils_bod', 'in/soil/soil_horizons.bod')],
             
            # Group 3
            [file_map.get('printout', 'in/control/printout.prt'),
             file_map.get('surface', 'in/landuse/surface.pob'),
             file_map.get('boundary', 'in/control/boundary.rb')]
        ]
        
        for i, group in enumerate(input_groups):
            # Ensure -1 is written as integer "-1", not float
            count_val = len(group) if i == 0 else -1
            lines.append(f"          {count_val}") 
            for fpath in group:
                lines.append(f"{fpath:<40}")
        
        with open(run_path, 'w') as f:
            f.write('\n'.join(lines))

        # Write to file
        with open(run_path, 'w') as f:
            f.write('\n'.join(lines))
    
    def summary(self) -> str:
        """
        Print project summary
        """
        lines = []
        lines.append(f"\nProject: {self.name}")
        lines.append("=" * 60)
        
        if self.mesh:
            lines.append(f"Mesh: {self.mesh.n_layers} layers × {self.mesh.n_columns} columns")
            lines.append(f"      Width: {self.mesh.width:.2f} m")
        
        if self.soils:
            lines.append(f"Soils: {len(self.soils.soil_definitions)} types defined")
            for s in self.soils.soil_definitions:
                lines.append(f"  - {s['name']}: θs={s['theta_s']:.3f}, Ks={s['k_sat']:.2e} m/s")
        
        if self.forcing and not self.forcing.data.empty:
            lines.append(f"Forcing: {len(self.forcing.data)} time steps")
        
        lines.append(f"\nSettings:")
        lines.append(f"  Period: {self.settings.get('start_time')} → {self.settings.get('end_time')}")
        lines.append(f"  Method: {self.settings.get('method')}")
        lines.append(f"  dt_max: {self.settings.get('dt_max')} s")
        
        if self.results:
            lines.append(f"\nResults: {len(self.results.water_balance)} time steps computed")
        
        lines.append("=" * 60)
        
        return '\n'.join(lines)
    



##################################################################################################################
##################################################################################################################
##################################################################################################################

@dataclass
class CATFLOWProject:
    name: str
    
    # 1. Control
    config: GlobalConfig          # CATFLOW.IN
    run_control: RunControl       # run_01.in
    
    # 2. Physics & Geometry
    mesh: HillslopeMesh           # hang1.geo
    soils: SoilProfile            # soils.def + .bod
    macropores: Optional[Macropores] # profil.mak (New)
    
    # 3. Conditions
    initial: InitialConditions    # rel_sat.ini
    boundary: BoundaryDefinition  # boundary.rb
    forcing: ForcingData          # timeser.def

    
    # 4. Surface & Atmosphere
    surface: SurfaceProperties    # surface.pob
    land_use: LandUseDefinition   # lu_file.def
    wind: WindDirection           # winddir.def (New)
    
    # 5. Output Config
    printout: PrintoutTimes       # printout.prt

import numpy as np
import pickle
from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, Any, Optional, List
import re

from model.inputs.conditions import BoundaryDefinition, InitialConditions
from model.inputs.forcing import ForcingData
from model.inputs.mesh import HillslopeMesh
from model.inputs.soil import SoilProfile
from model.inputs.surface import SurfaceProperties
from model.landuse import LandUseDefinition
from model.outputs import SimulationResults
from model.printout import PrintoutTimes


@dataclass
class CATFLOWProject:

    name: str = "New Project"
    
    # Core components
    mesh: Optional[HillslopeMesh] = None
    soils: Optional[SoilProfile] = None
    forcing: Optional[ForcingData] = None
    
    surface: Optional[SurfaceProperties] = None
    printout: Optional[PrintoutTimes] = None
    boundary: Optional[BoundaryDefinition] = None
    land_use: Optional[LandUseDefinition] = None
    initial: Optional[InitialConditions] = None
    
    # Simulation Control
    settings: Dict[str, Any] = field(default_factory=dict)
    
    _legacy_paths: Dict[str, str] = field(default_factory=dict)
    results: Optional[SimulationResults] = None

    def save(self, filepath: str):
        """Binary save of entire project state"""
        with open(filepath, 'wb') as f:
            pickle.dump(self, f)
        print(f"✓ Project saved to {filepath}")

    @classmethod
    def load(cls, filepath: str) -> 'CATFLOWProject':
        """Binary load"""
        with open(filepath, 'rb') as f:
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
                'start_time': lines[0].split()[0].strip(),
                'end_time': lines[1].split()[0].strip(),
                'offset': float(lines[2].split()[0]),
                'method': lines[3].split()[0].strip(),
                'dtbach': float(lines[4].split()[0]),
                'qtol': float(lines[5].split()[0]),
                'dt_max': float(lines[6].split()[0]),
                'dt_min': float(lines[7].split()[0]),
                'dt_init': float(lines[8].split()[0])
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
        
        # Load optional components
        # Add similar blocks for surface, printout, etc. as you implement them
        
        print(f"\n{'='*60}")
        print(f"✓ Project loaded successfully")
        print(f"{'='*60}\n")
        
        return project

    #def write_to_folder(self, folder_path: str):
    #    """
    #    Enhanced export with all components
    #    """
    #    base = Path(folder_path)
    #    base.mkdir(parents=True, exist_ok=True)
    #    
    #    print(f"\n{'='*60}")
    #    print(f"Writing CATFLOW Project to: {base}")
    #    print(f"{'='*60}\n")
    #    
    #    # Define file structure
    #    file_structure = {
    #        'geo': 'in/hillgeo/hang1.geo',
    #        'soils_def': 'in/soil/soils.def',
    #        'soils_bod': 'in/soil/soil_horizons.bod',
    #        'timeser': 'in/control/timeser.def',
    #        'printout': 'in/control/printout.prt',
    #        'surface': 'in/landuse/surface.pob',
    #        'boundary': 'in/control/boundary.rb',
    #        'lu_file': 'in/landuse/lu_file.def',
    #        'winddir': 'in/climate/winddir.def',
    #        'run': 'run_01.in'
    #    }
    #    
    #    # Write core components
    #    written_files = []
    #    
    #    if self.mesh:
    #        print("  [1/5] Writing mesh...")
    #        path = base / file_structure['geo']
    #        self.mesh.to_file(str(path))
    #        written_files.append(file_structure['geo'])
    #    
    #    if self.soils:
    #        print("  [2/5] Writing soils...")
    #        path = base / file_structure['soils_def']
    #        self.soils.write_soils_def(str(path))
    #        written_files.append(file_structure['soils_def'])
    #        
    #        if self.mesh:
    #            path = base / file_structure['soils_bod']
    #            self.soils.write_bod_file(str(path), self.mesh.n_layers, self.mesh.n_columns)
    #            written_files.append(file_structure['soils_bod'])
    #    
    #    if self.forcing:
    #        print("  [3/5] Writing forcing...")
    #        path = base / file_structure['timeser']
    #        self.forcing.to_file(str(path))
    #        written_files.append(file_structure['timeser'])
    #    
    #    # Write minimal required files that may be missing
    #    print("  [4/5] Creating required stub files...")
    #    
    #    create_minimal_required_files(base)
    #    
    #    # Write run file
    #    print("  [5/5] Writing run configuration...")
    #    self._write_run_file(base / file_structure['run'], file_structure)
    #    
    #    # Write CATFLOW.IN
    #    with open(base / "CATFLOW.IN", "w") as f:
    #        f.write(f"run_01.in                       2.0\n")
    #    
    #    print(f"\n✓ Exported {len(written_files)} files")
    #    print(f"{'='*60}\n")

    def _write_run_file(self, run_path: Path, file_map: Dict[str, str]):
        """
        Generate complete run file
        """
        s = self.settings
        
        # Output files
        outputs = [
            ('out/log.out', 'Log file'),
            ('out/bilanz.csv', 'Water balance'),
            ('out/theta.out', 'Soil moisture'),
            ('out/psi.out', 'Pressure head')
        ]
        
        # Build file content
        lines = [
            f"{s.get('start_time', '01.01.2000 00:00:00.00')}          % start time",
            f"{s.get('end_time', '02.01.2000 00:00:00.00')}          % end time",
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
            "noiact                          % interaction with drainage network",
            f"     {len(outputs)}                         % number of output files",
        ]
        
        # Output flags (all enabled)
        lines.append('  ' + '  '.join(['1'] * len(outputs)))
        
        # Output file paths
        for path, desc in outputs:
            lines.append(f"{path:<40}% {desc}")
        
        # Input files (in groups separated by -1)
        input_groups = [
            # Group 1: Core definition files
            [file_map.get('soils_def', 'in/soil/soils.def'),
             file_map.get('timeser', 'in/control/timeser.def'),
             file_map.get('lu_file', 'in/landuse/lu_file.def'),
             file_map.get('winddir', 'in/climate/winddir.def')],
            
            # Group 2: Geometry and soil assignment
            [file_map.get('geo', 'in/hillgeo/hang1.geo'),
             file_map.get('soils_bod', 'in/soil/soil_horizons.bod')],
            
            # Group 3: Control
            [file_map.get('printout', 'in/control/printout.prt'),
             file_map.get('surface', 'in/landuse/surface.pob'),
             file_map.get('boundary', 'in/control/boundary.rb')]
        ]
        
        # Write input file sections
        for i, group in enumerate(input_groups):
            lines.append(f"          {len(group) if i == 0 else -1}")
            for fpath in group:
                lines.append(f"{fpath:<40}")
        
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
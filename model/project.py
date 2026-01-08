import numpy as np
import pickle
from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, Any, Optional

from model.inputs.forcing import ForcingData
from model.inputs.mesh import HillslopeMesh
from model.inputs.soil import SoilProfile
from model.outputs import SimulationResults

@dataclass
class CATFLOWProject:
    """
    Main Project Container.
    Connects Settings, Mesh, Soils, and Forcing.
    """
    name: str = "New Project"
    
    mesh: Optional[HillslopeMesh] = None
    soils: Optional[SoilProfile] = None
    forcing: Optional[ForcingData] = None
    
    # Simulation Control
    settings: Dict[str, Any] = field(default_factory=dict)
    
    _legacy_paths: Dict[str, str] = field(default_factory=dict)

    results: Optional[SimulationResults] = None

    def save(self, filepath: str):
        """Binary save of entire project state"""
        with open(filepath, 'wb') as f:
            pickle.dump(self, f)
        print(f"Project saved to {filepath}")

    @classmethod
    def load(cls, filepath: str) -> 'CATFLOWProject':
        """Binary load"""
        with open(filepath, 'rb') as f:
            return pickle.load(f)

    # =========================================================================
    #  LEGACY IMPORT STUFF
    # =========================================================================

    @classmethod
    def from_legacy_folder(cls, folder_path: str, run_file: str = "run_01.in") -> 'CATFLOWProject':
        folder = Path(folder_path)
        project = cls(name=folder.name)
        
        # Resolve Run File
        run_path = folder / run_file
        if not run_path.exists():
            if (folder / "CATFLOW.IN").exists():
                try:
                    with open(folder / "CATFLOW.IN") as f:
                        # Read first token of first line
                        run_file_name = f.readline().split()[0]
                        run_path = folder / run_file_name
                except Exception:
                    pass # Fall through to error
        
        if not run_path.exists():
            raise FileNotFoundError(f"CRITICAL: Run file '{run_file}' (or linked file) not found in {folder}")

        # Parse Run File
        try:
            with open(run_path, 'r') as f:
                lines = [l.strip() for l in f.readlines()]
        except Exception as e:
            raise IOError(f"Could not read run file: {e}")

        # Basic settings
        try:
            project.settings.update({
                'start_time': lines[0].split('%')[0].strip(),
                'end_time': lines[1].split('%')[0].strip(),
                'method': lines[3].split('%')[0].strip(),
                'dt_max': float(lines[6].split('%')[0])
            })
        except IndexError:
            raise ValueError(f"Run file '{run_path.name}' is malformed (header too short).")

        # Path Discovery
        paths = {}
        for line in lines:
            clean_line = line.split('%')[0].strip()
            if ('/' in clean_line or '.' in clean_line) and len(clean_line) > 3:
                if 'hillgeo' in clean_line or '.geo' in clean_line: 
                    paths['geo'] = folder / clean_line
                elif 'soils.def' in clean_line: 
                    paths['soils_def'] = folder / clean_line
                elif 'horizons.bod' in clean_line: 
                    paths['soils_bod'] = folder / clean_line
                elif 'timeser' in clean_line: 
                    paths['timeser'] = folder / clean_line

        project._legacy_paths = {k: str(v) for k,v in paths.items()}

        # VALIDATION: Checks for missing files
        missing_errors = []
        required_keys = ['geo', 'soils_def', 'soils_bod'] # forcing is optional-ish usually
        
        # Check if keys exist in map
        for key in required_keys:
            if key not in paths:
                missing_errors.append(f"Missing entry in run file for: {key}")
            elif not paths[key].exists():
                missing_errors.append(f"File defined but not found on disk: {paths[key]}")

        # If errors, STOP
        if missing_errors:
            error_msg = "\n".join(["\n--- LOAD ABORTED: MISSING FILES ---"] + missing_errors)
            raise FileNotFoundError(error_msg)

        # Loads Components
        print("All required files found. Loading components...")
        
        try:
            project.mesh = HillslopeMesh.from_file(paths['geo'])
            project.soils = SoilProfile.from_files(paths['soils_def'], paths['soils_bod'])
            
            # Reshape validation
            if project.mesh and project.soils.assignment_matrix.size > 0:
                needed = project.mesh.n_layers * project.mesh.n_columns
                if project.soils.assignment_matrix.size == needed:
                    project.soils.assignment_matrix = project.soils.assignment_matrix.reshape(
                        project.mesh.n_layers, project.mesh.n_columns
                    )
                else:
                    print(f"WARNING: Soil matrix size ({project.soils.assignment_matrix.size}) does not match mesh ({needed}).")

            if 'timeser' in paths and paths['timeser'].exists():
                project.forcing = ForcingData.from_file(paths['timeser'])
            else:
                print("Note: No forcing file loaded (optional).")

        except Exception as e:
            raise ValueError(f"Error parsing component files: {e}")

        return project
    
    # =========================================================================
    #  LEGACY EXPORT
    # =========================================================================

    def write_to_folder(self, folder_path: str):
        """Regenerates all input files in the target folder"""
        base = Path(folder_path)
        base.mkdir(parents=True, exist_ok=True)
        
        # Define standard paths (Relative to run folder)
        paths = {
            'geo': 'in/hillgeo/hang1.geo',
            'soils_def': 'in/soil/soils.def',
            'soils_bod': 'in/soil/soil_horizons.bod',
            'timeser': 'in/control/timeser.def',
            'run': 'run_01.in'
        }

        # 1. Write Components
        if self.mesh:
            self.mesh.to_file(base / paths['geo'])
            
        if self.soils:
            self.soils.write_soils_def(base / paths['soils_def'])
            if self.mesh:
                self.soils.write_bod_file(base / paths['soils_bod'], self.mesh.n_layers, self.mesh.n_columns)
                
        if self.forcing:
            self.forcing.to_file(base / paths['timeser'])

        # 2. Write Run File
        self._write_run_file(base / paths['run'], paths)
        
        # 3. Write Main Control
        with open(base / "CATFLOW.IN", "w") as f:
            f.write(f"run_01.in                       2.0\n")

    def _write_run_file(self, run_path, file_map):
        """Generates the main .in file"""
        s = self.settings
        
        # Default output section (simplified)
        default_outputs = [
            f"{'out/log.out':<40}% log",
            f"{'out/bilanz.csv':<40}% bilanz"
        ]
        
        lines = [
            f"{s.get('start_time', '01.01.2000 00:00:00')}          % start time",
            f"{s.get('end_time', '02.01.2000 00:00:00')}          % end time",
            "        0.0                     % offset",
            f"{s.get('method', 'pic')}                       % computation method",
            "       3600.0                    % dtbach [s]",
            "          1.e-6                 % qtol",
            f"      {s.get('dt_max', 3600.0):.2f}                    % dt_max [s]",
            "          0.01                  % dt_min [s]",
            "         10.00                  % dt [s] initial",
            "          0.030                 % d_Th_opt",
            "          0.030                 % d_Phi_opt",
            "          5                     % n_gr",
            "         12                     % it_max",
            "          1.e-3                 % piceps",
            "          5.e-6                 % cgeps",
            "         15.0                    % rlongi",
            "          9.746                 % longi",
            "         47.35                  % lati",
            "          0                     % istact",
            "        -80             % Seed",
            "noiact                          % interaction",
            f"     {len(default_outputs)}                         % number of output files",
            " 1 1" # Flags for the 2 outputs
        ]
        lines.extend(default_outputs)
        
        # Input Files Section
        input_list = []
        if self.mesh: input_list.append(file_map['geo'])
        if self.soils: 
            input_list.append(file_map['soils_def'])
            input_list.append(file_map['soils_bod'])
        if self.forcing: input_list.append(file_map['timeser'])
        
        # Add required defaults if missing in components
        input_list.append('in/landuse/lu_file.def')
        input_list.append('in/climate/winddir.def')
        input_list.append('in/control/printout.prt')
        input_list.append('in/landuse/surface.pob')
        input_list.append('in/control/boundary.rb')

        lines.append(f"          {len(input_list)}")
        for p in input_list:
            lines.append(f"{p:<40}")

        with open(run_path, 'w') as f:
            f.write('\n'.join(lines))

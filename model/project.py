import pickle
from dataclasses import dataclass, field
from pathlib import Path
from typing import List, Optional, Dict
import numpy as np

from model.inputs.boundaries.initital import InitialState
from model.inputs.boundaries.map import BoundaryMap
from model.config import GlobalConfig, RunControl
from model.heterogeneity import HeterogeneityMap
from model.inputs.assigments.macropores import MacroporeDef
from model.inputs.assigments.soil import SoilAssignment
from model.inputs.assigments.surface import SurfaceAssignment
from model.inputs.controll_volume import ControlVolumeDef
from model.inputs.forcing.configuration import ForcingConfiguration
from model.inputs.land_use import LandUseLibrary
from model.inputs.mesh import HillslopeMesh
from model.inputs.soil import SoilLibrary
from model.inputs.wind import WindLibrary
from model.printout import PrintoutTimes


@dataclass
class Hill:
    id: int
    name: str = "Hill 1"
    
    # 1. Geometry (Master definition)
    mesh: Optional[HillslopeMesh] = None            # hang1.geo
    cv_def: Optional[ControlVolumeDef] = None

    
    # 2. Spatial Assignments (Map IDs to Nodes)
    soil_map: Optional[SoilAssignment] = None       # soil_horizons.bod
    surface_map: Optional[SurfaceAssignment] = None # surface.pob
    macropores: Optional[MacroporeDef] = None       # profil.mak
    boundary: Optional[BoundaryMap] = None          # boundary.rb
    
    # 3. Heterogeneity Scaling (The _1515.dat files)
    k_scaling: Optional[HeterogeneityMap] = None    # kstat_1515.dat
    theta_scaling: Optional[HeterogeneityMap] = None # thstat_1515.dat
    
    # 4. State & Output
    initial_cond: Optional[InitialState] = None     # rel_sat.ini
    printout: Optional[PrintoutTimes] = None        # printout.prt
    
    # 5. Aux (Control Volume)
    # cv_def: Optional[ControlVolumeDef] = None     # cont_vol.cv NOT IMPLEMENTED

@dataclass
class CATFLOWProject:
    name: str = "New Project"
    
    # --- GLOBAL CONTROL ---
    config: Optional[GlobalConfig] = None          # CATFLOW.IN
    run_control: Optional[RunControl] = None       # run_01.in (Time, Physics settings)
    
    # --- GLOBAL LIBRARIES (Shared by all hills) ---
    soil_library: Optional[SoilLibrary] = None     # soils.def
    forcing: Optional[ForcingConfiguration] = None # timeser.def
    land_use_library: Optional[LandUseLibrary] = None # lu_file.def
    wind_library: Optional[WindLibrary] = None     # winddir.def
    
    # --- SPATIAL DOMAINS ---
    hills: List[Hill] = field(default_factory=list)

    def save_binary(self, filename: str):
        """Quick binary save of full python state"""
        with open(f"{filename}.pkl", 'wb') as f:
            pickle.dump(self, f)
        print(f"✓ Project saved to {filename}.pkl")

    @classmethod
    def load_binary(cls, filename: str) -> 'CATFLOWProject':
        with open(f"{filename}.pkl", 'rb') as f:
            return pickle.load(f)

    @classmethod
    def from_legacy_folder(cls, folder_path: str, run_filename: str = "run_01.in") -> 'CATFLOWProject':
        """
        Parses a legacy CATFLOW folder structure.
        Crucially, this uses STRICT POSITIONAL PARSING for run_01.in,
        """
        folder = Path(folder_path).resolve()
        project = cls(name=folder.name)
        
        print(f"Loading Project from: {folder}")

        # 1. Global Config (CATFLOW.IN)
        if (folder / "CATFLOW.IN").exists():
            project.config = GlobalConfig.from_file(str(folder / "CATFLOW.IN"))
        
        # 2. Run Control (Parameters only)
        run_path = folder / run_filename
        if not run_path.exists():
            raise FileNotFoundError(f"Run file missing: {run_path}")
            
        # Load parameters (Time, dt, etc.)
        project.run_control = RunControl.from_file(str(run_path))
        
        # 3. Parse File Paths from run_01.in (Strict Order)
        # We re-read the file to get the paths in the correct loop order
        with open(folder / run_filename, 'r') as f:
            raw_lines = [l.split('%')[0].strip() for l in f if l.split('%')[0].strip()]

        # 1. FIND THE SYNC POINT (End of Output Files)
        # We don't rely on matching a number. We look for the structure.
        # Structure: [Count] -> [Flags] -> [Files...] -> [Next Count]
        
        idx = 0
        n_outputs = 0
        
        # Scan for the output block signature
        for i, line in enumerate(raw_lines):
            # Look for the flags line (e.g., "0 1 1 0...")
            # It's unique because it's a long sequence of 0s and 1s
            if i > 0 and len(line) > 5 and all(c in '01 ' for c in line):
                # If this is the flags line, the previous line MUST be the count
                if raw_lines[i-1].isdigit():
                    n_outputs = int(raw_lines[i-1])
                    idx = i - 1 # Set index to the count line
                    print(f"DEBUG: Found output block at line {idx} with {n_outputs} files")
                    break
        
        # Jump over the output block
        # Count(1) + Flags(1) + Files(n_outputs)
        idx += 1 + 1 + n_outputs
        
        # NOW we are exactly at "n_global_inputs"
        print(f"DEBUG: Reading Global Input Count at line {idx}: '{raw_lines[idx]}'")
        
        # 2. Parse Globals
        n_global_inputs = int(raw_lines[idx]); idx += 1
        
        # Helper to get full path
        def fpath(rel): return str(folder / rel)
        
        # Global 1: Soils
        p_soils = raw_lines[idx]; idx += 1
        print("  Loading Soil Library...")
        project.soil_library = SoilLibrary.from_file(fpath(p_soils))
        
        # Global 2: Forcing
        p_time = raw_lines[idx]; idx += 1
        print("  Loading Forcing Config...")
        project.forcing = ForcingConfiguration.from_file(fpath(p_time))
        
        # Global 3: Land Use
        p_lu = raw_lines[idx]; idx += 1
        print("  Loading Land Use Library...")
        project.land_use_library = LandUseLibrary.from_file(fpath(p_lu))
        
        # Global 4: Wind
        p_wind = raw_lines[idx]; idx += 1
        print("  Loading Wind Library...")
        project.wind_library = WindLibrary.from_file(fpath(p_wind))
        
        # Hill Loop Count
        n_hills_raw = int(raw_lines[idx]); idx += 1
        n_hills = abs(n_hills_raw)
        
        print(f"  Found {n_hills} Hill(s)...")
        
        for h_i in range(n_hills):
            hill = Hill(id=h_i+1)
            
            # 1. Geometry
            p_geo = raw_lines[idx]; idx += 1
            print(f"    [Hill {h_i+1}] Mesh: {p_geo}")
            hill.mesh = HillslopeMesh.from_file(fpath(p_geo))
            
            # Mesh dimensions needed for other files
            nl, nc = hill.mesh.n_layers, hill.mesh.n_columns
            
            # 2. Soil Map (.bod)
            p_bod = raw_lines[idx]; idx += 1
            hill.soil_map = SoilAssignment.from_file(fpath(p_bod), nl, nc)
            
            # 3. K-Stat (Heterogeneity)
            p_kstat = raw_lines[idx]; idx += 1
            hill.k_scaling = HeterogeneityMap.from_file(fpath(p_kstat))
            
            # 4. Th-Stat (Heterogeneity)
            p_thstat = raw_lines[idx]; idx += 1
            hill.theta_scaling = HeterogeneityMap.from_file(fpath(p_thstat))
            
            # 5. Macropores
            p_mak = raw_lines[idx]; idx += 1
            hill.macropores = MacroporeDef.from_file(fpath(p_mak), nl, nc)
            
            # 6. Control Volume
            p_cv = raw_lines[idx]; idx += 1
            hill.cv_def = ControlVolumeDef.from_file(fpath(p_cv))

            # 7. Initial Conditions
            p_ini = raw_lines[idx]; idx += 1
            hill.initial_cond = InitialState.from_file(fpath(p_ini), nl, nc)
            
            # 8. Printout
            p_prt = raw_lines[idx]; idx += 1
            hill.printout = PrintoutTimes.from_file(fpath(p_prt))
            
            # 9. Surface Map
            p_pob = raw_lines[idx]; idx += 1
            hill.surface_map = SurfaceAssignment.from_file(fpath(p_pob), nc)
            
            # 10. Boundary Map
            p_rb = raw_lines[idx]; idx += 1
            hill.boundary = BoundaryMap.from_file(fpath(p_rb), nl, nc)
            
            project.hills.append(hill)
            
        print("✓ Project Loaded Successfully")
        return project

    def write_to_folder(self, folder_path: str, source_folder: str = None):
        """
        Reconstructs the full folder structure and files.
        """
        base = Path(folder_path)
        base.mkdir(parents=True, exist_ok=True)
        
        print(f"Writing Project to {base}...")
        
        # 1. Write Global Config (CATFLOW.IN)
        if self.config:
            self.config.to_file(str(base / "CATFLOW.IN"))
            
        # 2. Define Standard Global Paths
        # These are the relative paths we will write into run_01.in
        p_soils = "in/soil/soils.def"
        p_time = "in/control/timeser.def"
        p_lu = "in/landuse/lu_file.def"
        p_wind = "in/climate/winddir.def"
        
        # Ensure parent directories exist
        (base / p_soils).parent.mkdir(parents=True, exist_ok=True)
        (base / p_time).parent.mkdir(parents=True, exist_ok=True)
        (base / p_lu).parent.mkdir(parents=True, exist_ok=True)
        (base / p_wind).parent.mkdir(parents=True, exist_ok=True)

        # 3. Write Global Libraries
        # We explicitly call to_file() on each library object if it exists.
        
        if self.soil_library: 
            self.soil_library.to_file(str(base / p_soils))
            
        if self.forcing:
            # Forcing writes timeser.def AND all referenced .dat files
            self.forcing.to_file(str(base / p_time))
            
        if self.land_use_library:
            self.land_use_library.to_file(str(base / p_lu))
            # If we still rely on external .par files (haven't modeled them fully yet), copy them:
            if source_folder:
                src = Path(source_folder)
                for lu in self.land_use_library.types:
                    # Copy parameter files if they exist in source
                    # lu.param_file might be "in/landuse/wiese.par"
                    s = src / lu.param_file
                    d = base / lu.param_file
                    if s.exists():
                        d.parent.mkdir(parents=True, exist_ok=True)
                        import shutil
                        shutil.copy2(s, d)
            
        if self.wind_library:
            self.wind_library.to_file(str(base / p_wind))
            
        # 4. Write Hills
        hill_file_lines = [] # Lines to append to run_01.in
        
        # Hill count line (Negative means standard CATFLOW format)
        hill_file_lines.append(f"          -{len(self.hills)}") 
        
        for i, hill in enumerate(self.hills):
            prefix = f"in/hill_{i+1}"
            (base / prefix).mkdir(parents=True, exist_ok=True)
            
            # Define standard filenames for this hill
            # We enforce this naming convention for the new project structure
            files = {
                'geo': f"{prefix}/hang.geo",
                'bod': f"{prefix}/soils.bod",
                'kstat': f"{prefix}/kstat.dat",
                'thstat': f"{prefix}/thstat.dat",
                'mak': f"{prefix}/profil.mak",
                'cv': f"{prefix}/control.cv",
                'ini': f"{prefix}/initial.ini",
                'prt': f"{prefix}/printout.prt",
                'pob': f"{prefix}/surface.pob",
                'rb': f"{prefix}/boundary.rb"
            }
            
            # Write objects to files (Check existence first)
            if hill.mesh: hill.mesh.to_file(str(base / files['geo']))
            if hill.soil_map: hill.soil_map.to_file(str(base / files['bod']))
            if hill.k_scaling: hill.k_scaling.to_file(str(base / files['kstat']))
            if hill.theta_scaling: hill.theta_scaling.to_file(str(base / files['thstat']))
            if hill.macropores: hill.macropores.to_file(str(base / files['mak']))
            if hill.cv_def: hill.cv_def.to_file(str(base / files['cv']))
            if hill.initial_cond: hill.initial_cond.to_file(str(base / files['ini']))
            if hill.printout: hill.printout.to_file(str(base / files['prt']))
            if hill.surface_map: hill.surface_map.to_file(str(base / files['pob']))
            if hill.boundary: hill.boundary.to_file(str(base / files['rb']))
            
            # Append paths to the run file list (Order determines how Fortran reads them)
            # The order MUST match the 'run_01.in' loop:
            # Geo, Bod, Kstat, Thstat, Mak, CV, Ini, Prt, Pob, RB
            hill_file_lines.append(files['geo'])
            hill_file_lines.append(files['bod'])
            hill_file_lines.append(files['kstat'])
            hill_file_lines.append(files['thstat'])
            hill_file_lines.append(files['mak'])
            hill_file_lines.append(files['cv'])
            hill_file_lines.append(files['ini'])
            hill_file_lines.append(files['prt'])
            hill_file_lines.append(files['pob'])
            hill_file_lines.append(files['rb'])

        # 5. Write run_01.in
        rc_path = str(base / "run_01.in")
        
        # Ensure run_control exists
        if not self.run_control:
            # Should create a default one if missing, but raising error is safer
            raise ValueError("Cannot write project: RunControl is missing.")

        self.run_control.to_file(rc_path) # Writes header + params + output files
        
        # Now append the INPUT file section manually
        with open(rc_path, 'a') as f:
            f.write("\n\t  4\n") # Global file count (Always 4 in this structure)
            f.write(f"{p_soils}\n")
            f.write(f"{p_time}\n")
            f.write(f"{p_lu}\n")
            f.write(f"{p_wind}\n")
            
            for line in hill_file_lines:
                f.write(f"{line}\n")
        
        print("✓ Export Complete")


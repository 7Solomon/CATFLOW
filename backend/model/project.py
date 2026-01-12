import pickle
from dataclasses import dataclass, field
from pathlib import Path
from typing import List, Optional, Dict
import numpy as np

from model.inputs.boundaries.initital import SoilWaterIC, SoluteIC
from model.inputs.boundaries.map import BoundaryConditions
from model.config import GlobalConfig, RunControl
from model.heterogeneity import HeterogeneityMap
from model.inputs.assigments.macropores import MacroporeDef
from model.inputs.assigments.soil import SoilAssignment
from model.inputs.assigments.surface import SurfaceAssignment
from model.inputs.controll_volume import ControlVolumeDef
from model.inputs.forcing.configuration import ForcingConfiguration
from model.inputs.forcing.landuse.library import LandUseLibrary
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
    boundary: Optional[BoundaryConditions] = None          # boundary.rb
    
    # 3. Heterogeneity Scaling (The _1515.dat files)
    k_scaling: Optional[HeterogeneityMap] = None    # kstat_1515.dat
    theta_scaling: Optional[HeterogeneityMap] = None # thstat_1515.dat
    
    # 4. State & Output
    initial_cond_sat: Optional[SoilWaterIC] = None     # rel_sat.ini
    initial_cond_sol: Optional[SoluteIC] = None     # NOT IN PROJECT
    printout: Optional[PrintoutTimes] = None        # printout.prt
    
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
    def from_legacy_folder(cls, folder_path: str) -> 'CATFLOWProject':
        """
        Parses a legacy CATFLOW folder structure.
        """
        folder = Path(folder_path).resolve()
        project = cls(name=folder.name)
        
        print(f"Loading Project from: {folder}")

        # 1. Global Config (CATFLOW.IN)
        project.config = GlobalConfig.from_file(str(folder / "CATFLOW.IN"))
        
        # 2. Run Control
        run_path = folder / project.config.run_filename
        if not run_path.exists():
            raise FileNotFoundError(f"Run file missing: {run_path}")
            
        # Load parameters (Time, dt, etc.)
        project.run_control = RunControl.from_file(str(run_path))
        
        # 3. Parse File Paths from run_01.in (Strict Order)
        with open(run_path, 'r') as f:
            raw_lines = [l.split('%')[0].strip() for l in f if l.split('%')[0].strip()]
            raw_lines = [l for l in raw_lines if not l.startswith('#')]

        def fpath(rel): return str(folder / rel)
        
        # Find the output file block
        idx = 0
        n_outputs = 0
        
        # Scan for the output block: Count -> Flags -> Files
        for i, line in enumerate(raw_lines):
            # Look for the flags line (long sequence of 0s and 1s)
            if i > 0 and len(line) >= 10 and all(c in '01 ' for c in line):
                if i > 0 and raw_lines[i-1].replace('-','').isdigit():
                    n_outputs = abs(int(raw_lines[i-1]))
                    idx = i - 1
                    print(f"DEBUG: Found output block at line {idx} with {n_outputs} files")
                    break
        
        # Jump over the output block: Count(1) + Flags(1) + Files(n_outputs)
        idx += 1 + 1 + n_outputs
        
        # Read number of global input files
        n_global_inputs = int(raw_lines[idx]); idx += 1
        print(f"DEBUG: Reading {n_global_inputs} Global Input Files")
        
        if n_global_inputs < 4:
            raise ValueError(f"Expected at least 4 global inputs, got {n_global_inputs}")
        
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
        project.land_use_library = LandUseLibrary.from_file(fpath(p_lu), folder)
        
        # Global 4: Wind
        p_wind = raw_lines[idx]; idx += 1
        print("  Loading Wind Library...")
        project.wind_library = WindLibrary.from_file(fpath(p_wind))
        
        # Skip any additional global files
        for _ in range(n_global_inputs - 4):
            idx += 1
        
        # Hill Loop Count (can be negative)
        n_hills_raw = int(raw_lines[idx]); idx += 1
        n_hills = abs(n_hills_raw)
        
        print(f"  Found {n_hills} Hill(s)...")
        
        for h_i in range(n_hills):
            hill = Hill(id=h_i+1)
            
            # 1. Geometry
            p_geo = raw_lines[idx]; idx += 1
            print(f"    [Hill {h_i+1}] Mesh: {p_geo}")
            hill.mesh = HillslopeMesh.from_file(fpath(p_geo))
            
            # Get dimensions
            nl, nc = hill.mesh.header.iacnv, hill.mesh.header.iacnl
            
            # 2. Soil Map (.bod)
            p_bod = raw_lines[idx]; idx += 1
            hill.soil_map = SoilAssignment.from_file(fpath(p_bod), nl, nc)
            
            # 3. K-Stat
            p_kstat = raw_lines[idx]; idx += 1
            hill.k_scaling = HeterogeneityMap.from_file(fpath(p_kstat))
            
            # 4. Th-Stat
            p_thstat = raw_lines[idx]; idx += 1
            hill.theta_scaling = HeterogeneityMap.from_file(fpath(p_thstat))
            
            # 5. Macropores
            p_mak = raw_lines[idx]; idx += 1
            hill.macropores = MacroporeDef.from_file(fpath(p_mak), nl, nc)
            
            # 6. Control Volume
            p_cv = raw_lines[idx]; idx += 1
            hill.cv_def = ControlVolumeDef.from_file(fpath(p_cv))

            # 7. Initial Conditions - Water
            p_ini = raw_lines[idx]; idx += 1
            hill.initial_cond_sat = SoilWaterIC.from_file(fpath(p_ini), nl, nc)
            
            # 8. Initial Conditions - Solute (OPTIONAL)
            # Check if the next file looks like a solute IC file
            # Heuristic: If istact > 0 in config, expect solute IC
            next_file = raw_lines[idx]
            if project.run_control and hasattr(project.run_control, 'istact'):
                if project.run_control.istact > 0:
                    # Expect solute IC file
                    p_sol_ini = raw_lines[idx]; idx += 1
                    try:
                        hill.initial_cond_sol = SoluteIC.from_file(fpath(p_sol_ini), nl, nc)
                    except:
                        print(f"    Warning: Failed to load solute IC from {p_sol_ini}")
                        pass
            
            # 9. Printout
            p_prt = raw_lines[idx]; idx += 1
            hill.printout = PrintoutTimes.from_file(fpath(p_prt))
            
            # 10. Surface Map
            p_pob = raw_lines[idx]; idx += 1
            hill.surface_map = SurfaceAssignment.from_file(fpath(p_pob), nc)
            
            # 11. Boundary Map
            p_rb = raw_lines[idx]; idx += 1
            hill.boundary = BoundaryConditions.from_file(fpath(p_rb), nl, nc)
            
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
            if hill.initial_cond_sat: hill.initial_cond_sat.to_file(str(base / files['ini']))
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


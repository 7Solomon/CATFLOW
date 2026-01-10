
from dataclasses import dataclass, field
from pathlib import Path
from typing import List, Optional

from model.inputs.forcing.climate import ClimateData
from model.inputs.forcing.landuse.timeline import LandUseTimeline
from model.inputs.forcing.precipitation import PrecipitationData


@dataclass
class ForcingConfiguration:
    # Data Storage (Real Objects)
    precip_data: List[PrecipitationData] = field(default_factory=list)
    climate_data: List[ClimateData] = field(default_factory=list)
    landuse_timeline: Optional[LandUseTimeline] = None
    
    # Boundary/Sinks STILL PATHs
    boundary_files: List[str] = field(default_factory=list)
    sink_files: List[str] = field(default_factory=list)

    @classmethod
    def from_file(cls, def_path: str) -> 'ForcingConfiguration':
        config = cls()
        p_def = Path(def_path)
        source_root = p_def.parents[2] # Assuming in/control/timeser.def -> root is up 2 levels
        # Better: Pass source_root explicitly if possible, but this heuristic works for standard layout
        
        if not p_def.exists(): return config

        with open(p_def, 'r') as f:
            lines = [l.strip() for l in f if l.strip()]
        
        iterator = iter(lines)
        try:
            while True:
                line = next(iterator)
                header = line.upper()
                
                if "NIEDERSCHLAG" in header:
                    count = int(next(iterator))
                    for _ in range(count):
                        rel_p = next(iterator)
                        # Load Data Immediately
                        config.precip_data.append(PrecipitationData.from_file(str(source_root / rel_p)))
                
                elif "KLIMA" in header:
                    count = int(next(iterator))
                    for _ in range(count):
                        rel_p = next(iterator)
                        config.climate_data.append(ClimateData.from_file(str(source_root / rel_p)))
                
                elif "RANDBEDINGUNGEN" in header:
                    count = int(next(iterator))
                    config.boundary_files = [next(iterator) for _ in range(count)]
                
                elif "SENKEN" in header:
                    count = int(next(iterator))
                    config.sink_files = [next(iterator) for _ in range(count)]
                
                elif "LANDNUTZUNG" in header:
                    val = next(iterator)
                    ts_rel_path = None
                    if val.isdigit() or (val.startswith('-') and val[1:].isdigit()):
                        if int(val) > 0:
                            ts_rel_path = next(iterator)
                    else:
                        ts_rel_path = val
                    
                    if ts_rel_path:
                        config.landuse_timeline = LandUseTimeline.from_file(str(source_root / ts_rel_path), source_root)

        except StopIteration:
            pass
        return config

    def to_file(self, filepath: str):
        """
        Writes timeser.def AND all the data files it references.
        filepath: path to 'in/control/timeser.def'
        """
        base_def = Path(filepath)
        root = base_def.parents[2] # project root
        
        # 1. Write Precip Data
        precip_folder = root / "in" / "precip"
        precip_folder.mkdir(parents=True, exist_ok=True)
        precip_paths = []
        for p in self.precip_data:
            p.to_file(precip_folder)
            precip_paths.append(f"in/precip/{p.filename}")
            
        # 2. Write Climate Data
        clim_folder = root / "in" / "climate"
        clim_folder.mkdir(parents=True, exist_ok=True)
        clim_paths = []
        for c in self.climate_data:
            c.to_file(clim_folder)
            clim_paths.append(f"in/climate/{c.filename}")
            
        # 3. Write Land Use Timeline & Lookups
        lu_folder = root / "in" / "landuse"
        lu_ts_path = None
        if self.landuse_timeline:
            self.landuse_timeline.to_file(lu_folder)
            lu_ts_path = f"in/landuse/{self.landuse_timeline.filename}"
            
        # 4. Write the Definition File
        with open(filepath, 'w') as f:
            f.write(f"NIEDERSCHLAG\n{len(precip_paths)}\n")
            for p in precip_paths: f.write(f"{p}\n")
            f.write("\n")
            
            f.write(f"RANDBEDINGUNGEN\n{len(self.boundary_files)}\n")
            for p in self.boundary_files: f.write(f"{p}\n")
            f.write("\n")
            
            f.write(f"SENKEN\n{len(self.sink_files)}\n")
            for p in self.sink_files: f.write(f"{p}\n")
            f.write("\n")
            
            f.write("Masse an Stoffen\n0\n\n")
            
            f.write("LANDNUTZUNG\n")
            if lu_ts_path:
                f.write(f"{lu_ts_path}\n")
            else:
                f.write("0\n")
            f.write("\n")
            
            f.write(f"KLIMA\n{len(clim_paths)}\n")
            for p in clim_paths: f.write(f"{p}\n")
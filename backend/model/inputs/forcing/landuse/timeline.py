from dataclasses import dataclass, field
from pathlib import Path
from typing import List
from model.inputs.forcing.landuse.lookup import LandUseLookup


@dataclass
class LandUsePeriod:
    """A single entry in the timeline: Date -> Lookup Set"""
    start_time: str        
    lookup: LandUseLookup  

@dataclass
class LandUseTimeline:
    """Represents lu_ts.dat"""
    filename: str = "lu_ts.dat"
    periods: List[LandUsePeriod] = field(default_factory=list)
    end_time: str = "" 

    @classmethod
    def from_file(cls, ts_path: str, source_root: Path):
        periods = []
        p_ts = Path(ts_path)
        if not p_ts.exists(): return cls()
        
        with open(p_ts, 'r') as f:
            lines = [l.strip() for l in f if l.strip()]
        
        i = 0
        while i < len(lines):
            date = lines[i]
            if i + 1 >= len(lines):
                return cls(p_ts.name, periods, end_time=date)
            
            # Next line is the lookup file path relative to project root
            # e.g. "in/landuse/lu_set1.dat"
            rel_path = lines[i+1]
            full_path = source_root / rel_path
            
            if full_path.exists():
                lookup_obj = LandUseLookup.from_file(str(full_path))
            else:
                # Fallback empty if missing
                print(f"⚠️ Warning: Missing lookup file {full_path}")
                lookup_obj = LandUseLookup(Path(rel_path).name)
            
            periods.append(LandUsePeriod(date, lookup_obj))
            i += 2
            
        return cls(p_ts.name, periods)

    def to_file(self, folder: Path, rel_prefix: str = "in/landuse"):
        """
        Writes the timeline file AND all referenced lookup files.
        folder: The 'in/landuse' directory where files should go.
        rel_prefix: The prefix to write inside the text file (e.g. 'in/landuse/lu_set.dat')
        """
        folder.mkdir(parents=True, exist_ok=True)
        lines = []
        
        for p in self.periods:
            # 1. Write the Lookup Object to disk
            p.lookup.to_file(folder)
            
            # 2. Add entry to timeline
            lines.append(p.start_time)
            # Construct relative path for the file content
            # e.g. "in/landuse/lu_set1.dat"
            lines.append(f"{rel_prefix}/{p.lookup.filename}")
            
        if self.end_time:
            lines.append(self.end_time)
        
        with open(folder / self.filename, 'w') as f:
            f.write("\n".join(lines))
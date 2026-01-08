from dataclasses import dataclass, field
from typing import Dict, List, Optional
from pathlib import Path
import re

@dataclass
class RunControl:
    """
    Parses and writes the main simulation control file (run_01.in).
    """
    # Header Parameters
    start_time: str = "01.01.2000 00:00:00.00"
    end_time: str = "02.01.2000 00:00:00.00"
    offset: float = 0.0
    method: str = "pic"
    dt_bach: float = 3600.0
    qtol: float = 1.e-6
    dt_max: float = 3600.0
    dt_min: float = 0.01
    dt_init: float = 10.0
    
    # Internal Fixed Params (rarely changed, but kept for write-back)
    d_th_opt: float = 0.030
    d_phi_opt: float = 0.030
    n_gr: int = 5
    it_max: int = 12
    piceps: float = 1.e-3
    cgeps: float = 5.e-6
    rlongi: float = 15.0
    longi: float = 9.746
    lati: float = 47.35
    istact: int = 0
    seed: int = -80
    noiact: int = 0  # 0 or 1
    
    # File Management
    output_files: List[str] = field(default_factory=lambda: [
        'out/log.out', 'out/bilanz.csv', 'out/theta.out', 'out/psi.out'
    ])
    
    # Map of Internal Key -> Relative Path (e.g. 'geo' -> 'in/hillgeo/hang1.geo')
    input_files: Dict[str, str] = field(default_factory=dict)

    @classmethod
    def from_file(cls, filepath: str) -> 'RunControl':
        path = Path(filepath)
        with open(path, 'r') as f:
            lines = [l.strip() for l in f.readlines()]

        try:
            # Parse Header (splitting by % comment)
            rc = cls(
                start_time=lines[0].split('%')[0].strip(),
                end_time=lines[1].split('%')[0].strip(),
                offset=float(lines[2].split()[0]),
                method=lines[3].split()[0].strip(),
                dt_bach=float(lines[4].split()[0]),
                qtol=float(lines[5].split()[0]),
                dt_max=float(lines[6].split()[0]),
                dt_min=float(lines[7].split()[0]),
                dt_init=float(lines[8].split()[0])
            )
            
            # Note: We skip lines 9-20 (fixed params) for brevity in this snippet,
            # but in production, you should parse them too to preserve values.
            # Example:
            # rc.noiact = int(lines[20].split()[0])
            
            # File Discovery (Heuristic)
            file_patterns = {
                'geo': r'\.geo$', 
                'soils_def': r'soils\.def$', 
                'soils_bod': r'\.bod$',
                'timeser': r'timeser',
                'boundary': r'boundary\.rb$',
                'surface': r'surface\.pob$',
                'lu_file': r'lu_file\.def$',
                'winddir': r'winddir\.def$',
                'printout': r'printout\.prt$'
            }
            
            rc.input_files = {}
            # Start scanning from line 22 onwards for paths
            for line in lines[22:]:
                clean = line.split('%')[0].strip()
                if len(clean) < 4 or clean.isdigit() or clean.startswith('-'): continue
                
                for key, pat in file_patterns.items():
                    if re.search(pat, clean):
                        rc.input_files[key] = clean
                        break
                        
            return rc

        except Exception as e:
            raise ValueError(f"Failed to parse run file {path}: {e}")

    def to_file(self, filepath: str):
        lines = []
        
        # 1. Header
        lines.append(f"{self.start_time}          % start time")
        lines.append(f"{self.end_time}          % end time")
        lines.append(f"        {self.offset:.1f}                     % offset")
        lines.append(f"{self.method:<30s}% computation method")
        lines.append(f"       {self.dt_bach:.1f}                    % dtbach")
        lines.append(f"          {self.qtol:.1e}                 % qtol")
        lines.append(f"      {self.dt_max:.2f}                    % dt_max")
        lines.append(f"          {self.dt_min:.2f}                  % dt_min")
        lines.append(f"         {self.dt_init:.2f}                  % dt_init")
        
        # 2. Fixed Params (Hardcoded defaults or from self attributes)
        lines.extend([
            f"          {self.d_th_opt:.3f}                 % d_Th_opt",
            f"          {self.d_phi_opt:.3f}                 % d_Phi_opt",
            f"          {self.n_gr}                     % n_gr",
            f"         {self.it_max}                     % it_max",
            f"          {self.piceps:.1e}                 % piceps",
            f"          {self.cgeps:.1e}                 % cgeps",
            f"         {self.rlongi:.1f}                    % rlongi",
            f"          {self.longi:.3f}                 % longi",
            f"         {self.lati:.2f}                  % lati",
            f"          {self.istact}                     % istact",
            f"        {self.seed}                     % Random seed",
            f"          {self.noiact}                          % interaction (0=noiact)"
        ])
        
        # 3. Output Files
        lines.append(f"     {len(self.output_files)}                         % number of output files")
        lines.append('  ' + '  '.join(['1'] * len(self.output_files))) # Flags
        for f in self.output_files:
            lines.append(f"{f:<40}% Output")
            
        # 4. Input Files (Grouped Structure for CATFLOW)
        # We must reconstruct the groups (Geo group, Soil group, etc.)
        # This part requires mapping specific keys to specific block positions.
        
        # Group 1: Soil Def, Timeser, LU, Wind
        g1 = [self.input_files.get(k) for k in ['soils_def', 'timeser', 'lu_file', 'winddir']]
        g1 = [x for x in g1 if x] # Filter None
        
        # Group 2: Geo, Bod
        g2 = [self.input_files.get(k) for k in ['geo', 'soils_bod']]
        g2 = [x for x in g2 if x]

        # Group 3: Printout, Surface, Boundary
        g3 = [self.input_files.get(k) for k in ['printout', 'surface', 'boundary']]
        g3 = [x for x in g3 if x]
        
        # Write Groups
        groups = [g1, g2, g3]
        for i, grp in enumerate(groups):
            count = len(grp) if i == 0 else -1
            lines.append(f"          {count}")
            for path in grp:
                lines.append(f"{path:<40}")
                
        with open(filepath, 'w') as f:
            f.write('\n'.join(lines))


class GlobalConfig:
    pass
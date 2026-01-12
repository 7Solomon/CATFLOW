from dataclasses import dataclass, field
from datetime import datetime
from typing import Dict, List, Optional
from pathlib import Path
import re

@dataclass
class RunControl:
    """
    Parses and writes the main simulation control file (run_01.in).
    Strictly typed with no defaults to ensure valid simulation configs.
    """
    # --- 1. Timing & Method ---
    start_time: str      # e.g. "01.01.2000 00:00:00.00"
    end_time: str        # e.g. "02.01.2000 00:00:00.00"
    offset: float        # e.g. 0.0
    method: str          # e.g. "pic"
    
    # --- 2. Time Stepping ---
    dt_bach: float       # Max time step for drainage [s]
    qtol: float          # Threshold for drainage [cbm/s]
    dt_max: float        # Max time step [s]
    dt_min: float        # Min time step [s]
    dt_init: float       # Initial time step [s]
    
    # --- 3. Iteration Control ---
    d_th_opt: float      # Optimum change of soil moisture
    d_phi_opt: float     # Optimum change of suction head
    n_gr: int            # Threshold for reducing time step
    it_max: int          # Max number of Picard iterations
    piceps: float        # Convergence crit. for Picard
    cgeps: float         # Convergence crit. for CG method
    
    # --- 4. Location & Physics ---
    rlongi: float        # Longitude for time calculation
    longi: float         # Reference longitude
    lati: float          # Reference latitude
    istact: int          # Number of solutes
    seed: int            # Random seed
    noiact: int          # Interaction switch (0=noiact, 1=simact)
    
    # --- 5. Files (Parsed Lists) ---
    output_files: List[str] = field(default_factory=list)
    input_files: Dict[str, str] = field(default_factory=dict) # Heuristic map only
    
    @property
    def start_datetime(self) -> datetime:
        clean = self.start_time.split('%')[0].strip()
        try:
            return datetime.strptime(clean, "%d.%m.%Y %H:%M:%S.%f")
        except ValueError:
            return datetime.strptime(clean, "%d.%m.%Y %H:%M:%S")

    @classmethod
    def from_file(cls, filepath: str) -> 'RunControl':
        path = Path(filepath)
        
        # Read and clean lines immediately
        with open(path, 'r') as f:
            lines = [l.split('%')[0].strip() for l in f.readlines()]
            lines = [l for l in lines if l] # Remove empty lines

        if len(lines) < 22:
            raise ValueError(f"Run file {path} is too short ({len(lines)} lines).")

        try:
            # 1. Parse Parameters (Strict Order lines 0-20)
            rc = cls(
                start_time=lines[0],
                end_time=lines[1],
                offset=float(lines[2]),
                method=lines[3],
                dt_bach=float(lines[4]),
                qtol=float(lines[5]),
                dt_max=float(lines[6]),
                dt_min=float(lines[7]),
                dt_init=float(lines[8]),
                d_th_opt=float(lines[9]),
                d_phi_opt=float(lines[10]),
                n_gr=int(lines[11]),
                it_max=int(lines[12]),
                piceps=float(lines[13]),
                cgeps=float(lines[14]),
                rlongi=float(lines[15]),
                longi=float(lines[16]),
                lati=float(lines[17]),
                istact=int(lines[18]),
                seed=int(lines[19]),
                noiact=0 # Default fallback if line 20 is weird
            )
            
            # Handle 'noiact' / 'simact' which can be string or int in legacy files
            val_20 = lines[20].lower()
            if 'noiact' in val_20:
                rc.noiact = 0
            elif 'simact' in val_20:
                rc.noiact = 1
            elif val_20.isdigit() or val_20.lstrip('-').isdigit():
                rc.noiact = int(val_20)
            
            # 2. Parse Output Files
            # Look for the output block start. It is usually immediately after line 20.
            # We look for the integer count.
            idx = 21
            n_outputs = 0
            
            # Safety scan in case there are extra param lines
            while idx < len(lines):
                if lines[idx].isdigit() and int(lines[idx]) < 100:
                    n_outputs = int(lines[idx])
                    # Validate next line looks like flags
                    flags = lines[idx+1].split()
                    if all(f in ['0', '1'] for f in flags):
                        n_outputs = int(lines[idx])
                        break
                idx += 1
                
            if n_outputs > 0:
                start_files = idx + 2 # Skip Count and Flags
                rc.output_files = lines[start_files : start_files + n_outputs]
            
            # 3. Heuristic Input File Discovery (Optional helper)
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
            
            # Start scanning AFTER the output files
            scan_start = idx + 2 + n_outputs
            for line in lines[scan_start:]:
                clean = line.strip()
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
        
        # 1. Header Params
        lines.append(f"{self.start_time}          % start time")
        lines.append(f"{self.end_time}          % end time")
        lines.append(f"        {self.offset:.1f}                     % offset")
        lines.append(f"{self.method:<30s}% computation method")
        lines.append(f"       {self.dt_bach:.1f}                    % dtbach")
        lines.append(f"          {self.qtol:.1e}                 % qtol")
        lines.append(f"      {self.dt_max:.2f}                    % dt_max")
        lines.append(f"          {self.dt_min:.2f}                  % dt_min")
        lines.append(f"         {self.dt_init:.2f}                  % dt_init")
        
        # 2. Fixed Params
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
            f"        {self.seed}                     % Random seed"
        ])
        
        # Interaction flag
        inter_str = "noiact" if self.noiact == 0 else "simact"
        lines.append(f"{inter_str:<30} % interaction (0=noiact)")
        
        # 3. Output Files
        lines.append(f"     {len(self.output_files)}                         % number of output files")
        # Flags: 1 for every file (standard)
        flags = ' '.join(['1'] * len(self.output_files))
        lines.append(f" {flags}")
        
        for f in self.output_files:
            lines.append(f"{f:<40}% Output")
            
        # Note: Input files are NOT written here. 
        # They must be appended by the Project writer to match the specific hill structure.
        
        with open(filepath, 'w') as f:
            f.write('\n'.join(lines))


@dataclass
class GlobalConfig:
    """
    Wraps CATFLOW.IN, which simply points to the active run file.
    """
    run_filename: Optional[str] = None
    scale_factor: float = 2.0

    @classmethod
    def from_file(cls, filepath: str) -> 'GlobalConfig':
        path = Path(filepath)
        if not path.exists():
            raise FileNotFoundError("EY YO KEINE .IN FILE")
        
        try:
            with open(path, 'r') as f:
                line = f.readline().strip()
                if not line: return cls()
                
                parts = line.split()
                # Expected format: "run_01.in   2."
                run_file = parts[0]
                factor = 2.0
                if len(parts) > 1:
                    factor = float(parts[1])
                    
                return cls(run_filename=run_file, scale_factor=factor)
                
        except Exception as e:
            print(f"⚠ Error reading CATFLOW.IN: {e}")
            return cls()

    def to_file(self, filepath: str):
        with open(filepath, 'w') as f:
            # Format with some spacing as seen in legacy files
            f.write(f"{self.run_filename:<30}  {self.scale_factor}\n")
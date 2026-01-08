

from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from typing import List, Optional, Tuple


@dataclass
class PrintoutTimes:
    """
    Manages output time specification (printout.prt)
    """
    times: List[Tuple[datetime, float]] = field(default_factory=list)  # (datetime, seconds_since_start)
    output_flags: List[int] = field(default_factory=list)  # Usually all 1
    
    @classmethod
    def from_file(cls, filepath: str, start_time: Optional[datetime] = None) -> 'PrintoutTimes':
        """
        Parse printout.prt
        Format:
        HANG           1
              10           % number of output times
        01.01.2004 00:00:00.00         0.00    1
        01.01.2004 01:00:00.00      3600.00    1
        """
        path = Path(filepath)
        if not path.exists():
            raise FileNotFoundError("")
            return cls()
        
        times = []
        flags = []
        
        try:
            with open(path, 'r') as f:
                lines = [l.strip() for l in f.readlines() if l.strip() and not l.startswith('%')]
            
            # Line 0: HANG 1
            # Line 1: number of times
            n_times = int(lines[1].split()[0])
            
            # Parse time entries
            for i in range(2, min(2 + n_times, len(lines))):
                parts = lines[i].split()
                if len(parts) >= 3:
                    # Date: DD.MM.YYYY HH:MM:SS.ss
                    date_str = f"{parts[0]} {parts[1]}"
                    try:
                        dt = datetime.strptime(date_str, "%d.%m.%Y %H:%M:%S.%f")
                    except:
                        dt = datetime.strptime(date_str, "%d.%m.%Y %H:%M:%S")
                    
                    seconds = float(parts[2])
                    flag = int(parts[3]) if len(parts) > 3 else 1
                    
                    times.append((dt, seconds))
                    flags.append(flag)
            
            print(f"  ✓ Loaded {len(times)} output times")
            
        except Exception as e:
            print(f"⚠ Error parsing printout.prt: {e}")
        
        return cls(times=times, output_flags=flags)
    
    def to_file(self, filepath: str, start_time: datetime):
        """Write printout.prt"""
        path = Path(filepath)
        path.parent.mkdir(parents=True, exist_ok=True)
        
        with open(path, 'w') as f:
            f.write("HANG           1\n")
            f.write(f"{len(self.times):10d}           % number of output times\n")
            
            for i, (dt, seconds) in enumerate(self.times):
                flag = self.output_flags[i] if i < len(self.output_flags) else 1
                time_str = dt.strftime("%d.%m.%Y %H:%M:%S.00")
                f.write(f"{time_str}  {seconds:15.2f}    {flag}\n")


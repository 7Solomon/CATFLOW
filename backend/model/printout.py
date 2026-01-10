from dataclasses import dataclass, field
from typing import List, Tuple
from datetime import datetime

@dataclass
class PrintoutTimes:
    reference_time: datetime
    time_factor: float          # e.g., 1200.0 (converts units to seconds)
    
    # List of (time_value, flag)
    # time_value is in the RAW units of the file (before multiplication)
    output_steps: List[Tuple[float, int]] = field(default_factory=list)

    @classmethod
    def from_file(cls, path: str) -> 'PrintoutTimes':
        steps = []
        ref_time = datetime.now() # Default fallback
        factor = 1.0

        with open(path, 'r') as f:
            lines = [l.strip() for l in f if l.strip()]
        
        # 1. Parse Header
        # Looking for line: "01.01.2004 00:00:00.00 1200."
        # Sometimes there are comment lines at the very top (start with #)
        
        iterator = iter(lines)
        header_found = False
        
        while not header_found:
            try:
                line = next(iterator)
            except StopIteration:
                break
                
            if line.startswith('#'): continue
            
            # This is the header line
            # It splits into a date string part and a factor float
            # "01.01.2004 00:00:00.00" is 22 characters
            date_str = line[:22].strip() 
            rest = line[22:].strip()
            
            try:
                ref_time = datetime.strptime(date_str, "%d.%m.%Y %H:%M:%S.%f")
            except ValueError:
                # Fallback if seconds don't have decimals or slightly different format
                try:
                    print("REF TIME NOT FOUND!!!")
                    ref_time = datetime.strptime(date_str.split('.')[0], "%d.%m.%Y %H:%M:%S")
                except:
                    pass

            if rest:
                factor = float(rest.split()[0])
            
            header_found = True

        # 2. Parse Data Steps
        for line in iterator:
            if line.startswith('#'): continue
            
            parts = line.split()
            if len(parts) >= 1:
                t_val = float(parts[0])
                flag = int(parts[1]) if len(parts) > 1 else 1
                steps.append((t_val, flag))

        return cls(reference_time=ref_time, time_factor=factor, output_steps=steps)

    def get_absolute_times_seconds(self) -> List[float]:
        """Returns the list of output times in seconds from the reference time."""
        return [t * self.time_factor for t, _ in self.output_steps]

    def to_file(self, path: str, start_dt: datetime = None):
        """
        Writes the printout config back to file.
        If start_dt is provided, it updates the reference time.
        """
        ref = start_dt if start_dt else self.reference_time
        
        # Format: "01.01.2004 00:00:00.00"
        dt_str = ref.strftime("%d.%m.%Y %H:%M:%S.%f")[:-4] # Truncate microseconds to 2 digits
        
        with open(path, 'w') as f:
            f.write(f"{dt_str:<25} {self.time_factor}\n")
            f.write("#  Startzeit              [d] -> [s]\n")
            f.write("# \t1: dump all; 0:dump for surface nodes\n")
            
            for t_val, flag in self.output_steps:
                f.write(f"{t_val:<10g} {flag}\n")


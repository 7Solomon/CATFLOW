import numpy as np
from dataclasses import dataclass
from typing import List, Optional

@dataclass
class BoundaryMap:
    # Stores ID assignments for edges. 0 = No Flow / Default
    left: np.ndarray   # Size: n_layers
    right: np.ndarray  # Size: n_layers
    top: np.ndarray    # Size: n_columns
    bottom: np.ndarray # Size: n_columns
    
    # Sinks are full matrices (mask)
    sinks: np.ndarray  # Size: (n_layers, n_columns)

    @classmethod
    def from_file(cls, path: str, n_layers: int, n_columns: int) -> 'BoundaryMap':
        # Initialize defaults (usually 0)
        left = np.zeros(n_layers, dtype=int)
        right = np.zeros(n_layers, dtype=int)
        top = np.zeros(n_columns, dtype=int)
        bottom = np.zeros(n_columns, dtype=int)
        sinks = np.zeros((n_layers, n_columns), dtype=int)
        
        with open(path, 'r') as f:
            content = f.read()
            
        lines = [l.strip() for l in content.splitlines() if l.strip()]
        iterator = iter(lines)
        
        # Valid keywords
        KEYWORDS = ['LINKS', 'RECHTS', 'OBEN', 'UNTEN', 'SENKEN', 'MASSE']
        
        try:
            while True:
                line = next(iterator)
                upper = line.upper()
                
                if upper in KEYWORDS:
                    current_section = upper
                    
                    # Read the count line
                    meta_line = next(iterator)
                    meta = meta_line.split()
                    
                    if not meta: break
                    
                    count = int(meta[0])
                    
                    # MASSE usually has only 1 value (count), others have 2 (count, mode)
                    mode = 0
                    if len(meta) > 1:
                        mode = int(meta[1])
                    
                    # If count is 0, just continue to next section
                    if count == 0:
                        continue

                    # Define target array and limit based on section
                    target_arr = None
                    limit = 0
                    
                    if current_section == 'LINKS': 
                        target_arr = left; limit = n_layers
                    elif current_section == 'RECHTS': 
                        target_arr = right; limit = n_layers
                    elif current_section == 'OBEN': 
                        target_arr = top; limit = n_columns
                    elif current_section == 'UNTEN': 
                        target_arr = bottom; limit = n_columns
                    elif current_section == 'SENKEN':
                        limit = -1 # Special case handled below
                    elif current_section == 'MASSE':
                        # Consume lines and ignore
                        for _ in range(count): next(iterator)
                        continue
                    
                    # Process the data lines
                    for _ in range(count):
                        data = next(iterator).split()
                        val_id = int(float(data[-1])) # Handle "1." or "1"
                        
                        if current_section == 'SENKEN':
                            # Sinks: v1 v2 h1 h2 id
                            if len(data) >= 5:
                                v1, v2, h1, h2 = map(float, data[:4])
                                
                                if mode == 0:
                                    # --- FIX 1: Scaling Factor (N-1) ---
                                    # Map relative coords (0-1) to indices using (N-1)
                                    # v = Vertical = Rows (n_layers)
                                    # h = Horizontal = Cols (n_columns)
                                    
                                    r1 = int(v1 * (n_layers - 1))
                                    r2 = int(v2 * (n_layers - 1))
                                    c1 = int(h1 * (n_columns - 1))
                                    c2 = int(h2 * (n_columns - 1))
                                else:
                                    # Absolute indices
                                    r1, r2 = int(v1), int(v2)
                                    c1, c2 = int(h1), int(h2)

                                # Sort to handle potential reversed definitions
                                r1, r2 = sorted([r1, r2])
                                c1, c2 = sorted([c1, c2])
                                
                                # Clamp
                                r1 = max(0, r1)
                                c1 = max(0, c1)
                                r2 = min(r2, n_layers - 1)
                                c2 = min(c2, n_columns - 1)
                                
                                # --- FIX 2: Orientation & Slicing ---
                                # Fortran loop: do iv (rows)... do il (cols)...
                                # Python Slicing is exclusive at end, so +1
                                sinks[r1:r2+1, c1:c2+1] = val_id
                                
                        elif target_arr is not None:
                            # Edges: p1 p2 id
                            if len(data) >= 3:
                                p1, p2 = float(data[0]), float(data[1])
                                if mode == 0:
                                    # Scaling Fix for 1D arrays
                                    idx1 = int(p1 * (limit - 1))
                                    idx2 = int(p2 * (limit - 1))
                                else:
                                    idx1, idx2 = int(p1), int(p2)
                                
                                idx1, idx2 = sorted([idx1, idx2])
                                idx1 = max(0, idx1)
                                idx2 = min(idx2, limit - 1)
                                
                                target_arr[idx1:idx2+1] = val_id
                                
        except StopIteration:
            pass
            
        return cls(left=left, right=right, top=top, bottom=bottom, sinks=sinks)

    def to_file(self, filepath: str):
        
        def write_section(f, name, array, relative_mode=0):
            blocks = []
            if len(array) == 0: return
            n = len(array)
            current_val = array[0]
            start_idx = 0
            for i in range(1, n):
                if array[i] != current_val:
                    # End of a block
                    blocks.append((start_idx, i - 1, current_val)) # Store inclusive end index
                    current_val = array[i]
                    start_idx = i
            blocks.append((start_idx, n - 1, current_val))
            
            # Filter out 0 (No Flow) blocks if desired, or keep all. 
            # Usually we write defined boundaries.
            
            f.write(f"{name}\n")
            f.write(f"{len(blocks)} {relative_mode}\n")
            for start, end, val in blocks:
                # Write normalized 0.0-1.0 coordinates
                # We normalize by (n-1) to be consistent with the reader
                # Avoid div by zero for single cell
                denom = (n - 1) if n > 1 else 1
                f.write(f"{start/denom:.4f} {end/denom:.4f} {val}\n")
            f.write("\n")

        with open(filepath, 'w') as f:
            # Edges
            write_section(f, "LINKS", self.left)
            write_section(f, "RECHTS", self.right)
            write_section(f, "OBEN", self.top)
            write_section(f, "UNTEN", self.bottom)
            
            # SINKS (Complex 2D)
            # Find unique non-zero values in sink matrix
            unique_sinks = np.unique(self.sinks)
            sink_blocks = []
            
            rows, cols = self.sinks.shape
            denom_r = (rows - 1) if rows > 1 else 1
            denom_c = (cols - 1) if cols > 1 else 1
            
            for sid in unique_sinks:
                if sid == 0: continue
                # Find coords where sink == sid
                r_idx, c_idx = np.where(self.sinks == sid)
                
                # Bounding Box Approach
                # Min/Max indices are inclusive here
                rmin, rmax = r_idx.min(), r_idx.max()
                cmin, cmax = c_idx.min(), c_idx.max()
                
                # Normalize using (N-1) logic
                v1, v2 = rmin / denom_r, rmax / denom_r
                h1, h2 = cmin / denom_c, cmax / denom_c
                
                sink_blocks.append((v1, v2, h1, h2, sid))
            
            # Write Sinks
            f.write("SENKEN\n")
            f.write(f"{len(sink_blocks)} 0\n") # 0=Relative Mode
            for b in sink_blocks:
                f.write(f"{b[0]:.4f} {b[1]:.4f} {b[2]:.4f} {b[3]:.4f} {b[4]}\n")
            f.write("\n")
            
            f.write("MASSE\n0\n")

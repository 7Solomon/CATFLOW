from dataclasses import dataclass

import numpy as np


@dataclass
class BoundaryBlock:
    side: str # 'LEFT', 'RIGHT', 'TOP', 'BOTTOM', 'SINKS'  # MASSE
    # For each node on this boundary, we assign a Type ID
    # Indices correspond to the node index along that boundary
    # e.g., LEFT/RIGHT have n_layers nodes; TOP/BOTTOM have n_columns nodes
    indices: np.ndarray 

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
                        limit = -1
                    elif current_section == 'MASSE':
                        print("Dont know what masses is!!!, bec careful just set to one")
                        # MASSE is legacy solute mass, usually not stored in boundary map, i think
                        # Just consume the lines
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
                                    r1, r2 = int(v1*n_layers), int(v2*n_layers)
                                    c1, c2 = int(h1*n_columns), int(h2*n_columns)
                                    # Clamp
                                    r2, c2 = min(r2, n_layers), min(c2, n_columns)
                                    sinks[r1:r2, c1:c2] = val_id
                                    
                        elif target_arr is not None:
                            # Edges: p1 p2 id
                            if len(data) >= 3:
                                p1, p2 = float(data[0]), float(data[1])
                                if mode == 0:
                                    idx1 = int(p1 * limit)
                                    idx2 = int(p2 * limit)
                                    idx2 = min(idx2, limit)
                                    target_arr[idx1:idx2] = val_id
                                    
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
                    blocks.append((start_idx, i, current_val))
                    current_val = array[i]
                    start_idx = i
            blocks.append((start_idx, n, current_val))
            
            f.write(f"{name}\n")
            f.write(f"{len(blocks)} {relative_mode}\n")
            for start, end, val in blocks:
                f.write(f"{start/n:.4f} {end/n:.4f} {val}\n")
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
            
            # Simple approach: Find bounding box for each sink ID (assumes rectangular sinks)
            # For complex shapes, RLE on rows is better, but this matches legacy block format best.
            rows, cols = self.sinks.shape
            
            for sid in unique_sinks:
                if sid == 0: continue
                # Find coords where sink == sid
                r_idx, c_idx = np.where(self.sinks == sid)
                
                # Normalize to 0.0-1.0
                v1, v2 = r_idx.min() / rows, (r_idx.max() + 1) / rows
                h1, h2 = c_idx.min() / cols, (c_idx.max() + 1) / cols
                
                sink_blocks.append((v1, v2, h1, h2, sid))
            
            # Write Sinks
            f.write("SENKEN\n")
            f.write(f"{len(sink_blocks)} 0\n") # 0=Relative Mode
            for b in sink_blocks:
                f.write(f"{b[0]:.4f} {b[1]:.4f} {b[2]:.4f} {b[3]:.4f} {b[4]}\n")
            f.write("\n")
            
            f.write("MASSE\n0\n")
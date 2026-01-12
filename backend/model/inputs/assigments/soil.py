from dataclasses import dataclass
import numpy as np

@dataclass
class SoilAssignment:
    assignment_matrix: np.ndarray  # Shape: (n_columns, n_layers)

    @classmethod
    def from_file(cls, path: str, n_layers: int, n_columns: int) -> 'SoilAssignment':
        # Result matrix: Default to 0 (or -1 if you prefer invalid)
        matrix = np.zeros((n_columns, n_layers), dtype=int)
        
        with open(path, 'r') as f:
            lines = [l.strip() for l in f if l.strip()]

        if not lines:
            return cls(assignment_matrix=matrix)

        header_parts = lines[0].split()

        # CASE 1: Keyword "BODEN" (Pointwise Matrix)
        if header_parts[0].upper().startswith("BODEN"):
            # Format: BODEN nv nl hill_id
            # Followed by the full matrix
            # The manual implies the matrix is read: "do iv = 1, iacnv ... read (..., (iboden(iv, il), il=1, iacnl))"
            # This means Outer Loop = Vertical, Inner Loop = Lateral
            
            # Read all subsequent tokens
            tokens = []
            for line in lines[1:]:
                tokens.extend([int(x) for x in line.split()])
            
            # Expected size: n_layers * n_columns
            if len(tokens) != n_layers * n_columns:
                print(f"Warning: Expected {n_layers*n_columns} tokens, got {len(tokens)}")

            idx = 0
            # CATFLOW usually reads Vertical (Outer) -> Lateral (Inner) or vice versa depending on the block
            # For BODEN: "do iv=1,nv ... do il=1,nl" is common in Fortran dumps
            # Let's assume standard reading order: Row by Row (Vertical 1, then all Laterals)
            for v in range(n_layers):
                for l in range(n_columns):
                    if idx < len(tokens):
                        matrix[l, v] = tokens[idx]
                        idx += 1
            
        # CASE 2: Blockwise (Numeric Header)
        else:
            # Format: n_blocks mode (0=rel/1=abs)
            n_blocks = int(header_parts[0])
            mode = int(header_parts[1]) if len(header_parts) > 1 else 0
            
            for i in range(n_blocks):
                if i + 1 >= len(lines): break
                parts = lines[i+1].split()
                
                # Format: v_start v_end l_start l_end soil_id
                v_s, v_e = cls._parse_range(parts[0], parts[1], n_layers, mode)
                l_s, l_e = cls._parse_range(parts[2], parts[3], n_columns, mode)
                soil_id = int(parts[4])
                
                # Apply
                matrix[l_s:l_e, v_s:v_e] = soil_id

        return cls(assignment_matrix=matrix)

    def to_file(self, filepath: str):
        """
        Writes the matrix in the BODEN (Pointwise) format which is safest/easiest.
        """
        rows, cols = self.assignment_matrix.shape # (n_cols, n_layers)
        
        with open(filepath, 'w') as f:
            # Header: BODEN n_layers n_columns hill_id
            f.write(f"BODEN {cols} {rows} 1\n")
            
            # Write data: Loop Vertical (Outer), Loop Lateral (Inner)
            # This matches "do iv=1,nv ... do il=1,nl"
            for v in range(cols):
                row_vals = []
                for l in range(rows):
                    row_vals.append(str(self.assignment_matrix[l, v]))
                f.write(" " + " ".join(row_vals) + "\n")

    @staticmethod
    def _parse_range(s_str, e_str, dim, mode):
        """
        Parses range based on mode.
        mode 0: Relative (0.0-1.0) OR Absolute (if > 1.0 heuristic)
        mode 1: Absolute (1-based)
        """
        s_val = float(s_str)
        e_val = float(e_str)
        
        # Heuristic override: if values are integers > 1, treat as absolute even if mode 0
        is_actually_absolute = (mode == 1) or (s_val > 1.0 or e_val > 1.0)
        
        if is_actually_absolute:
            return int(s_val) - 1, int(e_val)
        else:
            s = int(s_val * dim)
            e = int(e_val * dim)
            if e == s: e += 1
            return s, e

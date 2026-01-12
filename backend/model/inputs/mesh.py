from typing import Any, Dict, List
import numpy as np
from dataclasses import dataclass, field

@dataclass
class HillslopeMeshHeader:
    iacnv: int  # n of vertical nodes (height)
    iacnl: int  # n of lateral nodes (length)
    w_fix: float  # Global angle of anisotropy
    hangnr: int  # Hillslope ID number
    
    hgobfl: float = 0.0 # Surface area
    hgbreit: float = 0.0 # Average width
    hglang: float = 0.0 # Total length

    refrence_kords: Dict[str, Any] = field(default_factory=lambda: {
        "xkobez": None, "ykobez": None, "hkobez": None
    }) 

@dataclass
class HillslopeMeshCoordsVectors:
    etas: np.ndarray  # Shape: (iacnv,)
    xsis: np.ndarray  # Shape: (iacnl,), dtype_stuff=[('xsi', 'f8'), ('xko', 'f8'), ('yko', 'f8'), ('varbr', 'f8')]

HILLSLOPE_DTYPE = np.dtype([
    ('hko', 'f8'),    # Z-coordinate
    ('sko', 'f8'),    # S-coordinate
    ('f_eta', 'f8'),  # Metric coeff vertical
    ('f_xsi', 'f8'),  # Metric coeff lateral
    ('w_xsho', 'f8'), # Angle lateral
    ('w_hohr', 'f8'), # Angle anisotropy
    ('iboden', 'i4')  # Soil ID
])

LATERAL_VECTOR_DTYPE = np.dtype([
    ('xsi', 'f8'),
    ('xko', 'f8'),
    ('yko', 'f8'),
    ('varbr', 'f8')
])

@dataclass
class HillslopeMesh:
    header: HillslopeMeshHeader
    vector_definition: HillslopeMeshCoordsVectors
    data: np.ndarray = field(init=False)

    def __post_init__(self):
        if not hasattr(self, 'data'):
            self.data = np.zeros(
                (self.header.iacnl, self.header.iacnv), 
                dtype=HILLSLOPE_DTYPE
            ) # IF NOT FROM FILE INIT IN CORRECT SHAPE, IF FROM FILE ALSO ACTUALLY THEN POPULATE AfTER

    @classmethod
    def from_file(cls, path: str) -> 'HillslopeMesh':
        try:
            with open(path, 'r') as f:
                lines = [l.strip() for l in f if l.strip()]
                lines = [l for l in lines if not l.startswith('#')]

            # Iterator to consume lines sequentially
            line_iter = iter(lines)

            # HEADER
            # Line 1: iacnv, iacnl, w_fix, hangnr
            # "11 17 0.0 1"
            l1 = next(line_iter).split()
            iacnv = int(l1[0])
            iacnl = int(l1[1])
            w_fix = float(l1[2])
            hangnr = int(l1[3])

            # Line 2: xkobez, ykobez, hkobez
            # "3480100. 5445400. 202.0"
            l2 = next(line_iter).split()
            ref_coords = {
                "xkobez": float(l2[0]),
                "ykobez": float(l2[1]),
                "hkobez": float(l2[2])
            }

            # Line 3: hgobfl, hgbreit, hglang
            # "4. 10. 40."
            l3 = next(line_iter).split()
            hgobfl = float(l3[0])
            hgbreit = float(l3[1])
            hglang = float(l3[2])

            header = HillslopeMeshHeader(
                iacnv=iacnv, iacnl=iacnl, w_fix=w_fix, hangnr=hangnr,
                hgobfl=hgobfl, hgbreit=hgbreit, hglang=hglang,
                refrence_kords=ref_coords
            )

            # VECTOR STUFF

            # Block A: Vertical Coordinates (eta) -> 'iacnv' lines
            etas = np.zeros(iacnv, dtype=float)
            for i in range(iacnv):
                etas[i] = float(next(line_iter).split()[0])

            # Block B: Lateral Coordinates (xsi + geometry) -> 'iacnl' lines
            xsis_struct = np.zeros(iacnl, dtype=LATERAL_VECTOR_DTYPE)
            for i in range(iacnl):
                parts = next(line_iter).split()
                xsis_struct[i] = (float(parts[0]), float(parts[1]), float(parts[2]), float(parts[3]))

            vectors = HillslopeMeshCoordsVectors(etas=etas, xsis=xsis_struct)

            # DATA
            
            mesh_instance = cls(header=header, vector_definition=vectors)            
            mesh_instance.data = np.zeros((iacnl, iacnv), dtype=HILLSLOPE_DTYPE) # ACTUALLY NOT NECESSARY BECAUSE POST INIT BUT TO BE SURE

            # Block C: The Grid -> 'iacnl' blocks of 'iacnv' lines
            for il in range(iacnl):
                for iv in range(iacnv):
                    # Line: hko sko f_eta f_xsi w_xsho w_hohr iboden
                    parts = next(line_iter).split()
                    mesh_instance.data[il, iv] = (
                        float(parts[0]), # hko
                        float(parts[1]), # sko
                        float(parts[2]), # f_eta
                        float(parts[3]), # f_xsi
                        float(parts[4]), # w_xsho
                        float(parts[5]), # w_hohr
                        int(parts[6])    # iboden
                    )

            return mesh_instance

        except StopIteration:
            raise ValueError("Unexpected end of file while parsing.")
        except Exception as e:
            raise ValueError(f"Failed to parse HillslopeMesh file: {e}")
    def to_file(self, filepath: str):
        """
        Writes the mesh data to a file compatible with the FORTRAN reader.
        """
        try:
            with open(filepath, 'w') as f:
                # HEADER
                h = self.header
                
                # Line 1: Dimensions and ID
                # Format: iacnv iacnl w_fix hangnr
                f.write(f"{h.iacnv} {h.iacnl} {h.w_fix} {h.hangnr}\n")
                
                # Line 2: Reference Coordinates
                # Format: xkobez ykobez hkobez
                ref = h.refrence_kords
                # Use .get() to be safe, defaulting to 0.0 if missing
                xk = ref.get("xkobez", 0.0)
                yk = ref.get("ykobez", 0.0)
                hk = ref.get("hkobez", 0.0)
                f.write(f"{xk} {yk} {hk}\n")
                
                # Line 3: Geometry Stats
                # Format: hgobfl hgbreit hglang
                f.write(f"{h.hgobfl} {h.hgbreit} {h.hglang}\n")

                # VECTROS
                
                # Block A: Vertical Coordinates (eta)
                # Expects 'iacnv' lines
                if len(self.vector_definition.etas) != h.iacnv:
                    raise ValueError(f"Header says {h.iacnv} vertical nodes, but eta vector has {len(self.vector_definition.etas)}")
                
                for eta in self.vector_definition.etas:
                    f.write(f"{eta}\n")
                
                # Block B: Lateral Coordinates (xsi)
                # Expects 'iacnl' lines with 4 columns: xsi xko yko varbr
                if len(self.vector_definition.xsis) != h.iacnl:
                    raise ValueError(f"Header says {h.iacnl} lateral nodes, but xsi vector has {len(self.vector_definition.xsis)}")

                for row in self.vector_definition.xsis:
                    # Access structured array fields
                    f.write(f"{row['xsi']} {row['xko']} {row['yko']} {row['varbr']}\n")

                # DATA
                # Verify data shape matches header
                if self.data.shape != (h.iacnl, h.iacnv):
                    raise ValueError(f"Data shape {self.data.shape} does not match header dimensions ({h.iacnl}, {h.iacnv})")

                for il in range(h.iacnl):
                    for iv in range(h.iacnv):
                        # Get the structured point
                        d = self.data[il, iv]
                        
                        # Format: hko sko f_eta f_xsi w_xsho w_hohr iboden
                        # Note: iboden is cast to int, others are floats
                        line = (
                            f"{d['hko']} {d['sko']} "
                            f"{d['f_eta']} {d['f_xsi']} "
                            f"{d['w_xsho']} {d['w_hohr']} "
                            f"{int(d['iboden'])}"
                        )
                        f.write(line + "\n")
                        
        except Exception as e:
            raise IOError(f"Failed to write HillslopeMesh file to {filepath}: {e}")

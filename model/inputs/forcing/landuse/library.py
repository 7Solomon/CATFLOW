from dataclasses import dataclass, field
from pathlib import Path
from typing import List, Optional

from model.inputs.forcing.landuse.plants import PlantDefinition

@dataclass
class LandUseType:
    id: int
    name: str
    definition: Optional[PlantDefinition] = None 
    original_rel_path: str = "" 


@dataclass
class LandUseLibrary:
    types: List[LandUseType] = field(default_factory=list)

    @classmethod
    def from_file(cls, def_path: str, source_root: Path) -> 'LandUseLibrary':
        lib = cls()
        with open(def_path, 'r') as f:
            lines = [l.strip() for l in f if l.strip()]
            
        for line in lines:
            parts = line.split()
            if len(parts) >= 3:
                lu_id = int(parts[0])
                lu_name = parts[1]
                rel_path = parts[2] # e.g. "in/landuse/wiese.par"
                
                # Load definition from full path
                full_path = source_root / rel_path
                definition = None
                
                if full_path.exists():
                    definition = PlantDefinition.from_file(str(full_path))
                else:
                    # Try checking if it's relative to the def file itself? 
                    # Usually CATFLOW paths are from root, so source_root is correct.
                    print(f"⚠️ Warning: Plant .par file missing: {full_path}")

                lib.types.append(LandUseType(
                    id=lu_id,
                    name=lu_name,
                    definition=definition,
                    original_rel_path=rel_path
                ))
                
        return lib

    def to_file(self, def_filepath: str):
        # 1. Determine where to write .par files
        # def_filepath is "ft_backend/in/landuse/lu_file.def"
        # We want to write .par files to "ft_backend/in/landuse/"
        base_dir = Path(def_filepath).parent
        base_dir.mkdir(parents=True, exist_ok=True)
        
        with open(def_filepath, 'w') as f:
            for lu in self.types:
                # Decide filename
                fname = lu.definition.filename if lu.definition else Path(lu.original_rel_path).name
                
                # Write the .par file if we have the data
                if lu.definition:
                    lu.definition.to_file(base_dir)
                
                # Write line in .def file
                # CRITICAL: Must be relative from PROJECT ROOT, e.g. "in/landuse/wiese.par"
                # We assume standard structure:
                std_path = f"in/landuse/{fname}"
                f.write(f"{lu.id:<5} {lu.name:<35} {std_path}\n")
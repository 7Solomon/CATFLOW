# CATFLOW Python Wrapper Architecture

This project wraps the legacy Fortran CATFLOW input/output files into structured Python Dataclasses. This allows for reading, programmatic editing, and writing of simulation projects while maintaining 100% compatibility with the Fortran binary.

---

##File to Class Mapping

Each CATFLOW file type corresponds to a specific Python Dataclass in the `model` module.

| File Extension / Name | Python Dataclass | Module | Description |
| :--- | :--- | :--- | :--- |
| **Global Control** | | | |
| `CATFLOW.IN` | `GlobalConfig` | `model.config` | Entry point pointing to the active run file. |
| `run_*.in` | `RunControl` | `model.config` | Main configuration: timing, numerical flags, and file paths. |
| **Physics & Geometry** | | | |
| `*.geo` | `HillslopeMesh` | `model.inputs.mesh` | 2D Finite Element mesh (Nodes, Coordinates, Discretization). |
| `soils.def` | `SoilProfile` | `model.inputs.soil` | Physical hydraulic parameters (Van Genuchten) per soil type. |
| `*.bod`, `*.art` | `SoilAssignment` | `model.inputs.soil` | Maps Soil IDs to mesh nodes (supports Matrix or Profile mode). |
| `profil.mak` | `Macropores` | `model.inputs.soil` | Macropore channel definitions and parameters. |
| **Conditions** | | | |
| `*.ini`, `rel_sat` | `InitialConditions`| `model.inputs.conditions`| Initial state of the system (Theta/Psi/Phi) at t=0. |
| `boundary.rb` | `BoundaryDefinition`| `model.inputs.conditions`| Boundary condition flags (Neumann/Dirichlet) per node. |
| **Atmosphere & Surface** | | | |
| `timeser`, `precip` | `ForcingData` | `model.inputs.forcing` | Time-dependent forcing (Rainfall, Evaporation). |
| `winddir.def` | `WindDirection` | `model.inputs.climate` | Wind sector definitions for evapotranspiration scaling. |
| `surface.pob` | `SurfaceProperties` | `model.inputs.surface` | Surface roughness and vegetation coverage per node. |
| `lu_file.def` | `LandUseDefinition` | `model.landuse` | Maps Land Use IDs to surface nodes. |
| `*.par` | `PlantParameters` | `model.landuse` | Biological plant parameters (LAI, Root Depth) referenced by Land Use. |
| **Outputs** | | | |
| `printout.prt` | `PrintoutTimes` | `model.printout` | Defines simulation time steps where results are saved. |
| `out/bilanz.csv` | `SimulationResults`| `model.outputs` | Parsed simulation results (Water balance, Theta/Psi fields). |

---

## Class Details & Usage

### 1. `CATFLOWProject` (The Container)
The root object that holds all other components.
*   **Load:** `project = CATFLOWProject.from_legacy_folder("path/to/project")`
*   **Save:** `project.write_to_folder("path/to/new_project")`

### 2. Geometry (`HillslopeMesh`)
*   **Mapped File:** `in/hillgeo/hang1.geo`
*   **Key Attributes:**
    *   `n_layers`, `n_columns`: Mesh dimensions.
    *   `eta`, `xsi`: Relative discretization vectors.
    *   `nodes`: Full coordinate arrays.
*   **Note:** Preserves georeferencing metadata (x_ref, y_ref) hidden in legacy headers.

### 3. Soils (`SoilProfile` & `SoilAssignment`)
*   **Mapped Files:** `in/soil/soils.def` AND `in/soil/soil_horizons.bod`
*   **Logic:**
    *   `SoilProfile` holds the dictionary of physical parameters (ID -> Theta_s, Ks, etc.).
    *   `SoilAssignment` holds the spatial distribution. It can store data as a **2D Matrix** (exact grid) OR **Profile Ranges** (depth intervals).
    *   *Auto-Conversion:* On write, Profile Ranges are automatically rasterized to a Matrix if needed.

### 4. Run Control (`RunControl`)
*   **Mapped File:** `run_01.in`
*   **Key Attributes:**
    *   `start_time`, `end_time`: Simulation period (String format must be preserved).
    *   `dt_max`, `qtol`: Numerical solver limits.
    *   `file_paths`: Dictionary mapping internal names (`geo`, `soils`) to actual file paths on disk.

### 5. Forcing (`ForcingData`)
*   **Mapped File:** `in/control/timeser.def`
*   **Key Attributes:**
    *   `data`: Pandas DataFrame with columns `['time', 'flag', 'value']`.
*   **Note:** Paths inside `timeser.def` (pointing to `.dat` files) are handled relative to the project root.

---

## Developer Notes

### Loading Strategy
The loader (`from_legacy_folder`) uses a **heuristic discovery** process:
1.  Reads `run_01.in` to find active file paths.
2.  Instantiates the corresponding Python Class for each found file.
3.  If a file is missing (e.g., `winddir.def`), the corresponding attribute in `CATFLOWProject` remains `None`.

### Writing Strategy
The writer (`write_to_folder`) ensures a valid simulation structure:
1.  Creates standard directory tree (`in/hillgeo`, `in/soil`, etc.).
2.  Calls `.to_file()` on every active component.

### Data Types
*   **Integers:** Used for IDs (Soil ID, Land Use ID) and Counts.
*   **Floats:** Used for physical parameters. Note that legacy files often use specific formatting (e.g., `E12.4`), which the writers attempt to replicate to minimize diffs.
*   **Strings:** Used for names and timestamps.


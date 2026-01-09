# CATFLOW Python Wrapper Architecture

This wrapper provides a Pythonic interface for the legacy Fortran CATFLOW model. It strictly respects the hierarchical data structure of CATFLOW.

## 1. Data Flow Overview

CATFLOW operates in two distinct phases. This wrapper mirrors that structure to ensure compatibility.

### Phase 1: Global Libraries (The "What")
Before building the landscape, the model loads **Libraries**. These define physical properties and external drivers.
*   **Physics:** What types of soil exist? (Sand, Loam...) $\rightarrow$ `SoilLibrary`
*   **Vegetation:** What types of plants exist? (Forest, Grass...) $\rightarrow$ `LandUseLibrary`
*   **Drivers:** What acts on the system? (Rain, Wind...) $\rightarrow$ `ForcingConfiguration`
    *   *Note:* The wrapper now loads the actual climate data (precip series, climate tables) into Python objects (`PrecipitationData`, `ClimateData`), allowing for direct manipulation.

### Phase 2: Spatial Realization (The "Where")
The model then iterates over a list of **Hills**. Each hill is a distinct spatial domain where the Libraries are applied to a Mesh.
*   **Geometry:** The specific shape of the hill. $\rightarrow$ `HillslopeMesh`
*   **Assignment:** Mapping Soil IDs from the Library to Mesh Nodes. $\rightarrow$ `SoilAssignment`

---

## 2. File to Class Mapping

| File Extension / Name | Python Dataclass | Module | Description |
| :--- | :--- | :--- | :--- |
| **Global Control** | | | |
| `CATFLOW.IN` | `GlobalConfig` | `model.config` | Entry point; points to the active run file. |
| `run_*.in` | `RunControl` | `model.config` | Main simulation controller (Time, Solver Flags). |
| **Global Libraries** | | | **Shared by all Hills** |
| `soils.def` | `SoilLibrary` | `model.inputs.soil` | Catalog of physical soil parameters (Van Genuchten). |
| `timeser.def` | `ForcingConfiguration` | `model.inputs.forcing` | Configures external drivers (Precip, Climate, BCs). |
| `lu_file.def` | `LandUseLibrary` | `model.inputs.landuse` | Catalog of vegetation types and parameter files. |
| `winddir.def` | `WindLibrary` | `model.inputs.climate` | Wind exposure sectors. |
| **Data Assets** | | | **Loaded into Memory** |
| `*.dat` (Precip) | `PrecipitationData` | `model.inputs.forcing` | Time series of rainfall intensity. |
| `*.dat` (Climate) | `ClimateData` | `model.inputs.forcing` | Complex climate table (Radiation, Temp, Humidity). |
| `lu_ts.dat` | `LandUseTimeline` | `model.inputs.landuse` | Timeline of land use changes. |
| `lu_set*.dat` | `LandUseLookup` | `model.inputs.landuse` | Maps external IDs to Vegetation IDs. |
| **Spatial Domains (Hill)** | | | **Specific to one Hill** |
| `*.geo` | `HillslopeMesh` | `model.inputs.mesh` | 2D Finite Element mesh (Nodes, Coordinates). |
| `*.bod`, `*.art` | `SoilAssignment` | `model.inputs.soil` | Matrix mapping Soil IDs to mesh nodes. |
| `profil.mak` | `MacroporeDef` | `model.inputs.soil` | Macropore parameters per node. |
| `kstat_*.dat` | `HeterogeneityMap` | `model.inputs.soil` | Scaling factors for $K_{sat}$ per node. |
| `thstat_*.dat` | `HeterogeneityMap` | `model.inputs.soil` | Scaling factors for porosity $\theta_s$ per node. |
| `surface.pob` | `SurfaceAssignment` | `model.inputs.surface` | Maps Land Use IDs to surface nodes. |
| `boundary.rb` | `BoundaryMap` | `model.inputs.boundaries`| Boundary condition flags (Left, Right, Top, Bottom). |
| `rel_sat.ini` | `InitialState` | `model.inputs.conditions`| Initial system state (Saturation or Suction Head). |
| `printout.prt` | `PrintoutTimes` | `model.printout` | Defines specific output timestamps. |
| `*.cv` | `ControlVolumeDef` | `model.inputs.controll_volume` | Defines the control volume for mass balance. |

---

## 3. Class Details & Usage

### 1. `CATFLOWProject` (The Root)
The top-level container that holds the configuration and a list of hills.
*   **Structure:** Contains `config`, `run_control`, 4 Libraries (`soil`, `forcing`, `land_use`, `wind`), and a list `hills`.
*   **Load:** `project = CATFLOWProject.from_legacy_folder("path/to/project")`
*   **Save:** `project.write_to_folder("path/to/new_project")`

### 2. `ForcingConfiguration` (Climate Driver)
Unlike the legacy structure which just pointed to files, this class now **contains** the data.
*   `precip_data`: A list of `PrecipitationData` objects (actual numpy arrays of rainfall).
*   `climate_data`: A list of `ClimateData` objects (full climate tables).
*   `landuse_timeline`: A hierarchical object chain (`Timeline` -> `Period` -> `Lookup`) defining vegetation changes over time.

### 3. `Hill` (Spatial Instance)
Represents a single simulation domain.
*   **Attributes:**
    *   `mesh`: The geometry object.
    *   `soil_map`: Matrix of integers pointing to `SoilLibrary`.
    *   `cv_def`: Control volume definition.
    *   `initial_cond`: Matrix of floats for starting state.

### 4. Mesh (`HillslopeMesh`)
*   **Mapped File:** `hang1.geo`
*   **Critical Role:** This class parses the grid dimensions (`n_layers`, `n_columns`). **It must be loaded first** because other classes (SoilAssignment, InitialState) require these dimensions to parse their matrices correctly.

---

## 4. Developer Notes

### Loading Strategy (Strict Positional)
The legacy Fortran code reads `run_01.in` in a hardcoded loop sequence. The Python loader mimics this:
1.  **Output Files:** Detected by block parsing.
2.  **Global Files:** Soils, Time, LU, Wind.
3.  **Hill Loop:** Iterates `n_hills` times, reading exactly 11 files per hill (Geo, Bod, Kstat, Thstat, Mak, CV, Ini, Prt, Pob, BC).

### Writing Strategy (Standardized Tree)
When calling `write_to_folder`, the wrapper enforces a clean, standardized folder structure:
*   `in/control/` -> Timeseries, Boundary, Printout
*   `in/soil/` -> Global Soil Library
*   `in/landuse/` -> Global Land Use Library
*   `in/hill_1/` -> All spatial files for Hill 1.
*   `in/hill_n/` -> All spatial files for Hill n.
*   **Data Serialization:** It re-writes all `.dat` files (climate, precip) from memory into the new structure, ensuring the project is self-contained.

### Matrix vs. Block Mode
*   **Reading:** The wrapper supports both legacy "Block Mode" (Range indices 0.0-1.0) and "Matrix Mode".
*   **Writing:** The wrapper **standardizes to Matrix Mode** for files like `.bod`, `.mak`, and `.ini`. This rasterizes blocks into explicit grid values, which is safer and less ambiguous for the solver.

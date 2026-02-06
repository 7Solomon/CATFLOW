# CATFLOW Python Wrapper Architecture

This wrapper provides a Pythonic interface for the legacy Fortran CATFLOW model. It strictly respects the hierarchical data structure of CATFLOW.


## Installation & Setup

Follow these steps to set up the development environment locally.

---

### Prerequisites

Make sure you have the following installed:

- **Python**: Version **3.13.5**
- **Node.js**: Version **18+**
- **npm** (comes with Node.js)

You can verify your versions with:

```bash
python --version
node --version
```

### Clone the Repository
```bash
git clone https://github.com/7Solomon/Statik.git
cd Statik
```

### Backend Setup (Python / Flask)

Navigate to the backend directory, create a virtual environment, activate it, and install dependencies.
```bash
cd backend

Create virtual environment
python -m venv .venv
```


**Activate virtual environment**

*Windows (PowerShell):*
```bash
.venv\Scripts\activate
```

*Linux / macOS:*
```bash
source .venv/bin/activate
```

**Install dependencies**
```bash
pip install -r requirements.txt
```

### Frontend Setup (React / Vite)

Open a new terminal, navigate to the frontend directory, and install Node dependencies.

```bash
cd frontend
npm install
```

### Run CATFLOW

There is a script that starts the backend and frontend concurently, inside the root folder ./

*Windows (PowerShell):*
```bash
start.ps1
```

*Linux / macOS:*
NOT IMPLEMENTED

# User Interface Workflow

Once the application is running, the dashboard allows you to inspect and verify the CATFLOW file structure visually.

### 1. Project Selection
Upon launching, you are greeted with the start page. The application allows you to browse and load a specific CATFLOW project folder (e.g., `01`, `02`).

<p align="center">
  <img src="start_page.png" width="700" alt="Start Page">
  <br>
  <em>Initial landing page waiting for input</em>
</p>

<p align="center">
  <img src="load_project_modal.png" width="400" alt="Project Selection">
  <br>
  <em>Selecting a legacy project folder to parse</em>
</p>

### 2. Project Dashboard
Once loaded, the **Overview** tab provides a health check of the simulation. It displays global statistics, such as the total number of nodes and simulated hills, ensuring the Fortran files were parsed correctly by the Python backend.

<p align="center">
  <img src="overview.png" width="700" alt="Dashboard Overview">
</p>

### Global Config & Run Control
The `GlobalConfig` and `RunControl` classes map to `CATFLOW.IN` and `run_*.in`. They control simulation timing, solver methods (e.g., PIC), and numerical stability parameters.

<p align="center">
  <img src="config.png" width="700" alt="Configuration Panel">
  <br>
  <em>Visualization of time steps and solver settings parsed from run files</em>
</p>

### Physics Libraries
*   **Soil (`SoilLibrary`):** Defines physical soil parameters (Van Genuchten model). The UI plots these parameters to help verify hydraulic conductivity ($K_{sat}$) and porosity.
    <p align="center">
      <img src="soil.png" width="700" alt="Soil Library">
    </p>

*   **Vegetation (`LandUseLibrary`):** Defines plant types and their seasonal evolution (Root depth, Leaf Area Index). The timeline view visualizes how land use changes over the simulation period.
    <p align="center">
      <img src="land_use.png" width="700" alt="Land Use Timeline">
    </p>

### Drivers (`ForcingConfiguration`)
External forces acting on the system are loaded into memory objects (`PrecipitationData`, `ClimateData`, `WindLibrary`). The UI allows you to inspect raw time-series data and wind exposure factors.

<p align="center">
  <img src="precipitation.png" width="700" alt="Precipitation Data">
  <br>
  <em>Inspection of rainfall intensity time series (*.dat files)</em>
</p>

<p align="center">
  <img src="wind.png" width="700" alt="Wind Sectors">
  <br>
  <em>Wind exposure factors broken down by directional sectors</em>
</p>


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

# CATFLOW Data Format Specification (Verified)

**Source:** Based on `rd_wr.for` source code.

## 1. Global Control File (`CATFLOW.IN`)
**Purpose:** Points to the specific simulation run file.
*   **Format:** Single line, plain text.
*   **Structure:**
    ```text
    run_01.in       2.0
    ```
    *   Token 1: Simulation Run File (e.g., `run_01.in`)
    *   Token 2: Scale Factor (e.g., `2.0`)

---

## 2. Run File (e.g., `run_01.in`)
**Purpose:** Main configuration for simulation timing and file paths.
*   **Parsing Strategy:**
    1.  **Header (Lines 1–9):** Fixed simulation parameters.
        1.  Start Time (String)
        2.  End Time (String)
        3.  Time Offset (Float)
        4.  Method (String, e.g., `pic`)
        5.  `dtbach` (Float)
        6.  `qtol` (Float)
        7.  `dt_max` (Float)
        8.  `dt_min` (Float)
        9.  `dt_init` (Float)
    2.  **File Paths (Line 10+):**
        *   The file uses standard regex patterns to find input files.
        *   **Important:** Lines often contain comments starting with `%`. Parsers must strip these.
        *   **Keywords:** `geo`, `soils.def`, `timeser`, `printout`, `boundary`, `surface`, `landuse`.

---

## 3. Geometry File (`.geo`)
**Purpose:** Defines the 2D finite element mesh.
**Subroutine:** `rdhang`

*   **Structure:**
    1.  **Header (Line 1):** `Vertical_Nodes (nv)`, `Lateral_Nodes (nl)`, `Width`, `Slope_ID`
    2.  **Reference (Line 2):** `x_ref`, `y_ref`, `z_ref`
    3.  **Dimensions (Line 3):** `Surface_Area`, `Width`, `Length`
    4.  **Block 1: Vertical Discretization (`eta`)**
        *   List of `nv` floating point numbers (0.0 to 1.0).
        *   Often split across multiple lines.
    5.  **Block 2: Lateral Discretization (`xsi`) & Coordinates**
        *   **Crucial:** This is NOT just a list of `xsi` values.
        *   It is a loop of `nl` lines (or blocks).
        *   **Format per line:** `xsi_val`, `x_node`, `y_node`, ...
        *   **Parser Action:** Read `nl` lines; take the **first number** of each line as `xsi`.
    6.  **Block 3: Detailed Grid (`hko`, `sko`, etc.)**
        *   Detailed node coordinates for the entire grid.

---

## 4. Soil Definitions (`soils.def`)
**Purpose:** Defines hydraulic parameters for soil types.
**Subroutine:** `rdsoil`

*   **Structure:**
    1.  **Count (Line 1):** `N_Soils` (integer)
    2.  **Soil Block (Repeats `N` times):**
        *   **Line A:** Name (String, max 30 chars).
        *   **Line B:** `ID`, `Model_Type`, `Flags...` (Integers).
        *   **Line C:** `Parameters` (Floats).
            *   **Note:** Requires **8 parameters** for Model 1 (Van Genuchten), not 5.
            *   **Heuristic Mapping:**
                *   Standard: `Theta_s`, `Theta_r`, `Alpha`, `n`, `Ks`, ...
                *   Legacy: `Ks`, `Theta_s`, `Theta_r`, `Alpha`, `n`, ...
                *   *Parser should auto-detect columns based on magnitude.*

---

## 5. Soil Assignment (`.bod` / `.art`)
**Purpose:** Maps Soil IDs to mesh nodes.
**Subroutine:** `rdstyp`

*   **Header Detection:**
    *   The parser checks the **first character** of the first line.

### Mode A: Matrix Mode (Grid)
*   **Trigger:** Header starts with `B` (e.g., `BODEN`) or `HANG`.
*   **Format:**
    *   **Line 1:** Header (ignored or contains dims).
    *   **Body:** A grid of integers representing Soil IDs for every node.
    *   **Order:** `Vertical_Nodes` rows × `Lateral_Nodes` columns.

### Mode B: Profile Mode (Ranges)
*   **Trigger:** Header contains counts `N_Blocks`, `Type`.
*   **Format:**
    *   **Line 1:** `N_Blocks` (int), `Type` (int).
    *   **Body (`N` lines):**
        *   `Start_V`, `End_V`, `Start_L`, `End_L`, `Soil_ID`
        *   **Type 0:** Coordinates are relative (0.0–1.0).
        *   **Type 1:** Coordinates are absolute node indices (Integers).

---

## 6. Time Series (`timeser` / `.dat`)
**Purpose:** Rainfall and evaporation data.
**Subroutine:** `rdts` (implied)

*   **Structure:**
    *   Lines starting with `#` or `%` are comments.
    *   **Columns:** `Time` (seconds), `Flag` (usually 1), `Value` (intensity in m/s).
    *   **Note:** Time units can vary; ensure consistency with Run File settings.

---

## 7. Output Files (`out/`)
*   **`bilanz.csv`**: Water balance time series.
    *   Columns: `Time`, `Balance`, `Inflow`, `Outflow`, `Storage_Change`, ...
*   **`theta.out` / `psi.out`**: Spatial fields.
    *   **Format:** Blocks of data separated by headers `Time: <value>`.
    *   **Body:** 2D Grid of values matching mesh dimensions (`nv` × `nl`).

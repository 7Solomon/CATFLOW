# CATFLOW Data Format Specification

THIS IS BASED ON `CATFLOW.FOR` and `rd_wr.for` source code.

## 1. Global Control File (`CATFLOW.IN`)
**Purpose:** Points to the specific simulation run file.

*   **Format:** Plain text, single line.
*   **Structure:**
    *   `Filename` [whitespace] `ScaleFactor`
*   **Example:**
    ```text
    run_01.in       2.0
    ```
*   **Parsing Strategy:**
    1.  Read the first line.
    2.  Split by **whitespace** (not by `%`).
    3.  Token 0 is the filename.

---

## 2. Run File (e.g., `run_01.in`)
**Purpose:** Defines simulation timing, physics parameters, and paths to input files.

*   **Structure:**
    *   **Header (Lines 1–19):** Fixed-order configuration values.
        1.  `Start Time` (String, e.g., `01.01.2004 00:00:00.00`)
        2.  `End Time` (String)
        3.  `Time Offset` (Float)
        4.  `Method` (String, e.g., `pic`)
        5.  `dtbach` (Float, max channel time step)
        6.  `qtol` (Float, drainage threshold)
        7.  `dt_max` (Float)
        8.  `dt_min` (Float)
        9.  `dt_init` (Float)
        *   ... followed by physics parameters.
    *   **File Paths:** Valid paths appearing after the header.
*   **Parsing Strategy:**
    1.  Read the first ~20 lines by index to extract simulation settings.
    2.  Iterate through **all** lines to find file paths using Regex (e.g., looking for `.geo`, `soils.def`, `timeser`).
    3.  Strip comments (starting with `%`) before processing paths.

---

## 3. Geometry File (`.geo`)
**Purpose:** Defines the 2D finite element mesh coordinates and structure.
**Important:** Do **not** expect text headers like "HANG" or "COORDINATES".

*   **Structure:**
    1.  **Header (Line 1):** `Vertical_Nodes` (int), `Lateral_Nodes` (int), `Width` (float), `Slope_ID` (int).
    2.  **Reference (Line 2):** 3 Floats (`X`, `Y`, `Z` reference coords).
    3.  **Dimensions (Line 3):** 3 Floats (`Surface_Area`, `Width`, `Length`).
    4.  **Block 1 (Eta):** `Vertical_Nodes` floats (Vertical relative coordinates, 0.0–1.0).
    5.  **Block 2 (Xsi):** `Lateral_Nodes` floats (Lateral relative coordinates, 0.0–1.0).
    6.  **Block 3 (Nodes):** Detailed node data (X, Z coordinates, neighbor indices).
*   **Parsing Strategy:**
    1.  Read **all numbers** in the file into a single flat list of floats.
    2.  **Slice** the list based on the counts found in the first 2 numbers:
        *   `n_rows` = numbers[0]
        *   `n_cols` = numbers[1]
        *   Skip 6 numbers (Ref & Dims).
        *   `Layer_Depths` = Next `n_rows` numbers.
        *   `Lateral_Coords` = Next `n_cols` numbers.

---

## 4. Soil Definitions (`soils.def`)
**Purpose:** Defines hydraulic parameters (`Ks`, `Theta_s`, etc.) for each soil ID.

*   **Structure:**
    1.  **Count (Line 1):** `N_Soils` (integer).
    2.  **Soil Block (Repeats `N` times):**
        *   **Name Line:** Text description (e.g., `Sandy Loam`). **No quotes required.**
        *   **ID Line:** `Soil_ID` (integer).
        *   **Parameters:** Block of floats (`Theta_s`, `Theta_r`, `Alpha`, `n`, `Ks`).
*   **Parsing Strategy:**
    1.  Read `N_Soils`.
    2.  Loop `N` times.
    3.  Read the **ID** (integer).
    4.  Read the subsequent float block as parameters.
    5.  Ignore lines containing only zeros (`0. 0. 0.`).

---

## 5. Soil Assignment (`.bod`)
**Purpose:** Maps Soil IDs to mesh nodes.
**Format:** Can be **Matrix** (grid) or **Profile** (depth ranges).

*   **Profile Mode (Common):**
    *   **Check:** Data lines contain floating point numbers (e.g., `0.0`, `1.0`).
    *   **Structure:**
        *   `Start_V` (float), `End_V` (float)  [Vertical Range 0-1]
        *   `Start_L` (float), `End_L` (float)  [Lateral Range 0-1]
        *   `Soil_ID` (integer)
    *   **Action:** You must map these ranges to your mesh nodes manually (i.e., if a node's relative coordinate falls in this range, assign the ID).

*   **Matrix Mode:**
    *   **Check:** Data contains only integers.
    *   **Structure:** A flat list or grid of `Vertical_Nodes * Lateral_Nodes` integers.

---

## 6. Forcing Data (`timeser` / `precip`)
**Purpose:** Time-variant boundary conditions (Rainfall, Evaporation).

*   **Structure:**
    *   Standard ASCII columns.
    *   **Col 1:** Time (seconds or days).
    *   **Col 2:** Value (Rainfall intensity).
*   **Parsing Strategy:**
    1.  Standard CSV/Whitespace parsing.
    2.  Skip lines starting with `%` or `#`.
    3.  **Warning:** Ensure your parser handles `run_01.in` pointing to a **directory** (e.g., `in/precip`) by looking for a `.dat` file inside it, or pointing directly to a file.

---

## 7. Optional Files
*   **`surface.pob`**: Properties for surface nodes. Expects exactly `Lateral_Nodes` entries.
*   **`boundary.rb`**: Boundary condition flags (Dirichlet/Neumann) for domain edges.
*   **`printout.prt`**: Output simulation times.
    *   Format: `Date Time` (String) + `Seconds` (Float).

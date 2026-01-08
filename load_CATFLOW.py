import os
import subprocess
import numpy as np
import pandas as pd
from pathlib import Path
from datetime import datetime, timedelta
from typing import Dict, List, Tuple, Optional, Union
import re

class CATFLOWModel:
    """
    Main wrapper class for CATFLOW model.
    Handles reading existing configs, creating new configs, running the executable,
    and parsing output data.
    """
    
    def __init__(self, model_dir: str = "ft_backend", executable: str = "catflow.exe"):
        """
        Initialize CATFLOW model wrapper
        
        Parameters:
        -----------
        model_dir : str
            Path to model directory containing executable and input files (default: ft_backend)
        executable : str
            Name of CATFLOW executable
        """
        self.model_dir = Path(model_dir)
        self.executable = (self.model_dir / executable).resolve() 

        
        # State storage
        self.config = {}        # Paths to active control files
        self.params = {}        # Simulation parameters (dt, time, etc)
        self.files = {}         # Paths to input/output files parsed from run file
        self.geometry = {}      # Mesh data (x_coords, elevations)
        
        if not self.model_dir.exists():
            raise FileNotFoundError(f"Model directory not found: {model_dir}")

    # =========================================================================
    #  READING OF FILES
    # =========================================================================

    def load_current_config(self):
        """
        Orchestrator: Reads CATFLOW.IN -> Run File -> Geometry.
        Call this immediately after initialization to load existing state.
        """
        # 1. Find which run file is active from CATFLOW.IN
        try:
            run_filename = self.read_main_control()
            print(f"Active run file detected: {run_filename}")
            
            # 2. Parse that run file to get parameters and file paths
            self.read_run_file(run_filename)
            
            # 3. (Optional) Read geometry if available in the parsed config
            # We look for a file key containing 'hillgeo' or 'hang'
            geo_path = None
            if 'inputs' in self.files:
                for key, path in self.files['inputs'].items():
                    if 'hillgeo' in key or 'hang' in path:
                        geo_path = path
                        break
            
            if geo_path:
                self.read_geometry(geo_path)
                print(f"Geometry loaded from {geo_path}")
                
        except Exception as e:
            print(f"Error loading configuration: {e}")
            print("Ensure folder structure matches standard CATFLOW layout.")

    def read_main_control(self) -> str:
        """Reads CATFLOW.IN to find the active run file"""
        control_file = self.model_dir / "CATFLOW.IN"
        if not control_file.exists():
            raise FileNotFoundError(f"CATFLOW.IN not found in {self.model_dir}")
            
        with open(control_file, 'r') as f:
            # Format is typically: filename scale
            line = f.readline().strip()
            parts = line.split()
            self.config['control_file'] = str(control_file)
            self.config['run_file'] = str(self.model_dir / parts[0])
            return parts[0] # Return the filename (e.g., run_01.in)

    def read_run_file(self, filename: str):
        """
        Parses the .in run configuration file.
        Reconstructs simulation parameters and file paths.
        """
        file_path = self.model_dir / filename
        
        with open(file_path, 'r') as f:
            lines = [l.strip() for l in f.readlines()]

        # Parse simulation parameters (Fixed line format)
        try:
            self.params['start_time'] = lines[0].split('%')[0].strip()
            self.params['end_time'] = lines[1].split('%')[0].strip()
            self.params['method'] = lines[3].split('%')[0].strip()
            self.params['dt_max'] = float(lines[6].split('%')[0])
            self.params['dt_min'] = float(lines[7].split('%')[0])
            self.params['dt_init'] = float(lines[8].split('%')[0])
        except (IndexError, ValueError) as e:
            print(f"Warning: Could not parse all simulation parameters from {filename}")

        # Find where file section starts
        curr_idx = 0
        n_outputs = 0
        
        for idx, line in enumerate(lines):
            if "number of output files" in line:
                n_outputs = int(line.split()[0])
                curr_idx = idx
                break
        
        # Skip the flags line (0 1 0 1...)
        curr_idx += 2 
        
        # Read Output Files
        outputs = {}
        for i in range(n_outputs):
            if curr_idx + i >= len(lines): break
            line = lines[curr_idx + i]
            parts = line.split('%')
            path = parts[0].strip()
            # Try to get description comment, else use index
            key = parts[1].strip() if len(parts) > 1 else f"out_{i}"
            outputs[key] = path
            
        curr_idx += n_outputs
        
        # Read Input Files
        try:
            n_inputs_line = lines[curr_idx]
            n_inputs = int(n_inputs_line.split()[0])
            curr_idx += 1
            
            inputs = {}
            # Standard keys to identify files by name
            known_inputs = ['soils', 'timeser', 'lu_file', 'winddir', 'hillgeo', 
                            'soil_horizons', 'printout', 'surface', 'boundary']
            
            for i in range(n_inputs):
                if curr_idx + i >= len(lines): break
                path = lines[curr_idx + i].split('%')[0].strip()
                
                # Heuristic to guess key from filename
                key = f"in_{i}"
                for k in known_inputs:
                    if k in path or Path(path).stem in k:
                        key = k
                        break
                inputs[key] = path

            self.files = {'outputs': outputs, 'inputs': inputs}
            
        except (IndexError, ValueError):
            print("Warning: Could not fully parse input file list.")

    def read_geometry(self, relative_path: str):
        """
        Reads a .geo file into numpy arrays.
        Handles Fortran-style whitespace formatting.
        """
        full_path = self.model_dir / relative_path
        if not full_path.exists():
            print(f"Geometry file not found: {full_path}")
            return

        with open(full_path, 'r') as f:
            # Read all tokens (strings split by whitespace)
            content = f.read().split() 
            
        try:
            # Parse Header (HANG 1 nv nl width)
            # content[0] is 'HANG', [1] is '1'
            n_layers = int(content[2])
            n_columns = int(content[3])
            width = float(content[5])
            
            # Extract only numbers, skipping comments
            raw_numbers = []
            # Start after header
            for token in content[6:]:
                # Filter out comments (starting with %) or non-numeric words
                if '%' in token or any(c.isalpha() for c in token):
                    continue
                try:
                    raw_numbers.append(float(token))
                except ValueError:
                    continue
                    
            raw_numbers = np.array(raw_numbers)
            
            # Expected data structure:
            # 1. x_coords (n_columns)
            # 2. layers (n_layers * n_columns)
            # 3. elevations (n_columns)
            
            ptr = 0
            
            # X Coordinates
            self.geometry['x_coords'] = raw_numbers[ptr : ptr + n_columns]
            ptr += n_columns
            
            # Soil Layers Matrix (reshaped)
            self.geometry['layers'] = raw_numbers[ptr : ptr + (n_layers * n_columns)].reshape(n_layers, n_columns)
            ptr += (n_layers * n_columns)
            
            # Surface Elevations
            self.geometry['elevations'] = raw_numbers[ptr : ptr + n_columns]
            
            self.geometry['meta'] = {'width': width, 'n_layers': n_layers, 'n_cols': n_columns}
            
        except Exception as e:
            print(f"Failed to parse geometry file: {e}")

    # =========================================================================
    #  CREATION METHODS (Original functionality, preserved for editing)
    # =========================================================================


    def create_main_control(self, run_file: str = "run_01.in", scale: float = 2.0):
        """Create main control file (CATFLOW.IN)"""
        content = f"{run_file}                       {scale:.1f}\n"
        control_file = self.model_dir / "CATFLOW.IN"
        with open(control_file, 'w') as f:
            f.write(content)
        self.config['control_file'] = str(control_file)

    # =========================================================================
    #  EXECUTION & OUTPUT METHODS
    # =========================================================================

    def run(self, verbose: bool = True) -> subprocess.CompletedProcess:
        """Run CATFLOW model"""
        if not self.executable.exists():
            raise FileNotFoundError(f"Executable not found: {self.executable}")
        
        original_dir = os.getcwd()
        os.chdir(self.model_dir)
        
        try:
            result = subprocess.run(
                [str(self.executable)],
                capture_output=True,
                text=True,
                check=False
            )
            
            if verbose:
                print("STDOUT:", result.stdout)
                if result.stderr:
                    print("\nSTDERR:", result.stderr)
            return result
        finally:
            os.chdir(original_dir)

    def read_water_balance(self, file_path: str = "out/bilanz.csv") -> pd.DataFrame:
        """Read water balance output file"""
        full_path = self.model_dir / file_path
        if not full_path.exists():
            print(f"File not found: {full_path}")
            return pd.DataFrame()

        df = pd.read_csv(full_path, sep=';', header=None)
        
        columns = [
            'hillslope', 'timestep', 'time_s', 'balance_total', 
            'balance_in', 'balance_sink', 'balance_boundary',
            'flux_top', 'flux_right', 'flux_bottom', 'flux_left',
            'runoff_cum', 'runoff_coeff', 'precip', 'precip2',
            'interception', 'evaporation', 'transpiration'
        ]
        
        n_cols = len(df.columns)
        if n_cols > len(columns):
            n_solutes = (n_cols - len(columns)) // 3
            for i in range(n_solutes):
                columns.extend([f'mass_left_s{i+1}', f'mass_bottom_s{i+1}', f'mass_right_s{i+1}'])
        
        df.columns = columns[:n_cols]
        df['datetime'] = pd.to_datetime(df['time_s'], unit='s', origin='unix')
        return df

    def read_spatial_output(self, file_path: str, n_layers: int = None, n_columns: int = None) -> Dict[float, np.ndarray]:
        """Read spatial output file (theta, psi, etc.)"""
        # If dimensions not provided, try to use loaded geometry
        if n_layers is None and 'meta' in self.geometry:
            n_layers = self.geometry['meta']['n_layers']
        if n_columns is None and 'meta' in self.geometry:
            n_columns = self.geometry['meta']['n_cols']
            
        if n_layers is None or n_columns is None:
            raise ValueError("Must load geometry or provide n_layers/n_columns explicitly")

        full_path = self.model_dir / file_path
        results = {}
        current_time = None
        data_buffer = []
        
        with open(full_path, 'r') as f:
            for line in f:
                time_match = re.search(r'Time:\s+([\d.]+)', line)
                if time_match:
                    if current_time is not None and data_buffer:
                        try:
                            array = np.array(data_buffer).reshape(n_layers, n_columns)
                            results[current_time] = array
                        except ValueError:
                            pass # Skip incomplete steps
                    current_time = float(time_match.group(1))
                    data_buffer = []
                    continue
                
                values = line.split()
                if values:
                    try:
                        data_buffer.extend([float(v) for v in values])
                    except ValueError:
                        continue
        
        if current_time is not None and data_buffer:
            try:
                array = np.array(data_buffer).reshape(n_layers, n_columns)
                results[current_time] = array
            except ValueError:
                pass
        
        return results

import os
import subprocess
import numpy as np
import pandas as pd
from pathlib import Path
from datetime import datetime, timedelta
from typing import Dict, List, Tuple, Optional, Union
import re


class CATFLOWModel:
    """Main wrapper class for CATFLOW model"""
    
    def __init__(self, model_dir: str, executable: str = "catflow.exe"):
        """
        Initialize CATFLOW model wrapper
        
        Parameters:
        -----------
        model_dir : str
            Path to model directory containing executable and input files
        executable : str
            Name of CATFLOW executable
        """
        self.model_dir = Path(model_dir)
        self.executable = self.model_dir / executable
        self.config = {}
        
        if not self.model_dir.exists():
            raise FileNotFoundError(f"Model directory not found: {model_dir}")
    
    def create_run_file(self, 
                       start_time: str,
                       end_time: str,
                       method: str = 'pic',
                       dt_max: float = 86400.0,
                       dt_min: float = 0.01,
                       dt_init: float = 10.0,
                       output_files: Optional[Dict[str, str]] = None,
                       input_files: Optional[Dict[str, str]] = None,
                       **kwargs) -> str:
        """
        Create run configuration file (*.in)
        
        Parameters:
        -----------
        start_time : str
            Start time in format 'DD.MM.YYYY HH:MM:SS.ss'
        end_time : str
            End time in format 'DD.MM.YYYY HH:MM:SS.ss'
        method : str
            Solution method: 'exp', 'adi', 'apk', 'bcg', 'pic', 'mix'
        dt_max : float
            Maximum time step [s]
        dt_min : float
            Minimum time step [s]
        dt_init : float
            Initial time step [s]
        output_files : dict
            Dictionary of output file paths
        input_files : dict
            Dictionary of input file paths
        **kwargs : dict
            Additional parameters
        
        Returns:
        --------
        str : Path to created run file
        """
        
        # Default output files
        default_outputs = {
            'log': 'out/log.out',
            'vg_tab': 'out/vg_tab.out',
            'bilanz': 'out/bilanz.csv',
            'theta': 'out/theta.out',
            'psi': 'out/psi.out',
            'psi_fin': 'out/psi.fin',
            'fl_xsi': 'out/fl_xsi.out',
            'fl_eta': 'out/fl_eta.out',
            'senken': 'out/senken.out',
            'qoben': 'out/qoben.out',
            'evapo': 'out/evapo.out',
            'gang': 'out/gang.out',
            'hko': 'out/hko.out',
            'sko': 'out/sko.out'
        }
        
        if output_files:
            default_outputs.update(output_files)
        
        # Default input files
        default_inputs = {
            'soils': 'in/soil/soils.def',
            'timeser': 'in/control/timeser.def',
            'lu_file': 'in/landuse/lu_file.def',
            'winddir': 'in/climate/winddir.def',
            'hillgeo': 'in/hillgeo/hang1.geo',
            'soil_horizons': 'in/soil/soil_horizons.bod',
            'printout': 'in/control/printout.prt',
            'surface': 'in/landuse/surface.pob',
            'boundary': 'in/control/boundary.rb'
        }
        
        if input_files:
            default_inputs.update(input_files)
        
        # Build run file content
        lines = [
            f"{start_time}          % start time",
            f"{end_time}          % end time",
            "        0.0                     % offset",
            f"{method}                             % computation method",
            f"       {kwargs.get('dtbach', 3600.0):.1f}                    % dtbach [s]",
            f"          {kwargs.get('qtol', 1.e-6):.1e}                 % qtol",
            f"      {dt_max:.2f}                    % dt_max [s]",
            f"          {dt_min:.2f}                  % dt_min [s]",
            f"         {dt_init:.2f}                  % dt [s] initial",
            f"          {kwargs.get('d_Th_opt', 0.030):.3f}                 % d_Th_opt",
            f"          {kwargs.get('d_Phi_opt', 0.030):.3f}                 % d_Phi_opt",
            f"          {kwargs.get('n_gr', 5)}                     % n_gr",
            f"         {kwargs.get('it_max', 12)}                     % it_max",
            f"          {kwargs.get('piceps', 1.e-3):.1e}                 % piceps",
            f"          {kwargs.get('cgeps', 5.e-6):.1e}                 % cgeps",
            f"         {kwargs.get('rlongi', 15.0):.1f}                    % rlongi",
            f"          {kwargs.get('longi', 9.746):.3f}                 % longi",
            f"         {kwargs.get('lati', 47.35):.2f}                  % lati",
            f"          {kwargs.get('istact', 0)}                     % istact",
            f"        {kwargs.get('seed', -80)}		        % Seed",
            f"{kwargs.get('interaction', 'noiact')}                          % interaction",
            f"     {len(default_outputs)}                         % number of output files",
        ]
        
        # Output file flags (1 = write, 0 = don't write)
        output_flags = ' '.join(['1'] * len(default_outputs))
        lines.append(output_flags)
        
        # Add output file paths
        for key, path in default_outputs.items():
            lines.append(f"{path:<40}% {key}")
        
        # Add input file count and paths
        lines.append(f"          {len(default_inputs)}")
        for key, path in default_inputs.items():
            lines.append(f"{path:<40}")
        
        # Write to file
        run_file = self.model_dir / "run_01.in"
        with open(run_file, 'w') as f:
            f.write('\n'.join(lines))
        
        self.config['run_file'] = str(run_file)
        return str(run_file)
    
    def create_main_control(self, run_file: str = "run_01.in", 
                           scale: float = 2.0):
        """
        Create main control file (CATFLOW.IN)
        
        Parameters:
        -----------
        run_file : str
            Name of run configuration file
        scale : float
            Scaling factor
        """
        content = f"{run_file}                       {scale:.1f}\n"
        
        control_file = self.model_dir / "CATFLOW.IN"
        with open(control_file, 'w') as f:
            f.write(content)
        
        self.config['control_file'] = str(control_file)
    
    def create_geometry(self,
                       x_coords: np.ndarray,
                       elevations: np.ndarray,
                       soil_layers: np.ndarray,
                       hillslope_width: float = 1.0,
                       output_file: str = "in/hillgeo/hang1.geo"):
        """
        Create hillslope geometry file
        
        Parameters:
        -----------
        x_coords : np.ndarray
            Lateral coordinates [m]
        elevations : np.ndarray
            Surface elevations [m] for each x-coordinate
        soil_layers : np.ndarray
            Depths of soil layer boundaries [m] (negative, from surface)
        hillslope_width : float
            Width of hillslope [m]
        output_file : str
            Output file path
        """
        geo_file = self.model_dir / output_file
        geo_file.parent.mkdir(parents=True, exist_ok=True)
        
        n_layers = len(soil_layers)
        n_columns = len(x_coords)
        
        with open(geo_file, 'w') as f:
            # Header
            f.write(f"HANG           1\n")
            f.write(f"{n_layers:5d}{n_columns:5d}           % nv, nl\n")
            f.write(f"{hillslope_width:10.3f}           % hillslope width\n")
            
            # Lateral coordinates
            f.write("\n% Lateral coordinates [m]\n")
            for i, x in enumerate(x_coords):
                f.write(f"{x:10.3f}")
                if (i + 1) % 8 == 0:
                    f.write("\n")
            if len(x_coords) % 8 != 0:
                f.write("\n")
            
            # Layer depths for each column
            f.write("\n% Layer depths [m] (from surface, negative)\n")
            for layer in soil_layers:
                for col in range(n_columns):
                    f.write(f"{layer:10.3f}")
                    if (col + 1) % 8 == 0:
                        f.write("\n")
                if n_columns % 8 != 0:
                    f.write("\n")
            
            # Surface elevations
            f.write("\n% Surface elevations [m]\n")
            for i, elev in enumerate(elevations):
                f.write(f"{elev:10.3f}")
                if (i + 1) % 8 == 0:
                    f.write("\n")
            if len(elevations) % 8 != 0:
                f.write("\n")
    
    def create_soil_horizons(self,
                            soil_type_matrix: np.ndarray,
                            output_file: str = "in/soil/soil_horizons.bod"):
        """
        Create soil horizon assignment file
        
        Parameters:
        -----------
        soil_type_matrix : np.ndarray
            Matrix (n_layers x n_columns) of soil type indices
        output_file : str
            Output file path
        """
        bod_file = self.model_dir / output_file
        bod_file.parent.mkdir(parents=True, exist_ok=True)
        
        with open(bod_file, 'w') as f:
            f.write(" HANG           1\n")
            
            for row in soil_type_matrix:
                line = ''.join([f'{int(val):3d}' for val in row])
                f.write(f"{line}\n")
    
    def create_printout_times(self,
                             start_time: datetime,
                             end_time: datetime,
                             interval: timedelta,
                             output_file: str = "in/control/printout.prt"):
        """
        Create printout times file
        
        Parameters:
        -----------
        start_time : datetime
            Start time
        end_time : datetime
            End time
        interval : timedelta
            Output interval
        output_file : str
            Output file path
        """
        prt_file = self.model_dir / output_file
        prt_file.parent.mkdir(parents=True, exist_ok=True)
        
        times = []
        current = start_time
        while current <= end_time:
            times.append(current)
            current += interval
        
        with open(prt_file, 'w') as f:
            f.write("HANG           1\n")
            f.write(f"{len(times):10d}           % number of output times\n")
            
            for t in times:
                time_str = t.strftime("%d.%m.%Y %H:%M:%S.00")
                seconds = (t - start_time).total_seconds()
                f.write(f"{time_str}  {seconds:15.2f}    1\n")
    
    def run(self, verbose: bool = True) -> subprocess.CompletedProcess:
        """
        Run CATFLOW model
        
        Parameters:
        -----------
        verbose : bool
            Print output to console
        
        Returns:
        --------
        subprocess.CompletedProcess
            Result of model execution
        """
        if not self.executable.exists():
            raise FileNotFoundError(f"Executable not found: {self.executable}")
        
        # Change to model directory
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
                print("STDOUT:")
                print(result.stdout)
                if result.stderr:
                    print("\nSTDERR:")
                    print(result.stderr)
            
            return result
            
        finally:
            os.chdir(original_dir)
    
    def read_water_balance(self, file_path: str = "out/bilanz.csv") -> pd.DataFrame:
        """
        Read water balance output file
        
        Parameters:
        -----------
        file_path : str
            Path to balance file
        
        Returns:
        --------
        pd.DataFrame
            Water balance data
        """
        full_path = self.model_dir / file_path
        
        # Read CSV with semicolon separator
        df = pd.read_csv(full_path, sep=';', header=None)
        
        # Define column names based on CATFLOW output
        columns = [
            'hillslope', 'timestep', 'time_s', 'balance_total', 
            'balance_in', 'balance_sink', 'balance_boundary',
            'flux_top', 'flux_right', 'flux_bottom', 'flux_left',
            'runoff_cum', 'runoff_coeff', 'precip', 'precip2',
            'interception', 'evaporation', 'transpiration'
        ]
        
        # Add solute mass columns if present
        n_cols = len(df.columns)
        if n_cols > len(columns):
            n_solutes = (n_cols - len(columns)) // 3
            for i in range(n_solutes):
                columns.extend([
                    f'mass_left_s{i+1}',
                    f'mass_bottom_s{i+1}',
                    f'mass_right_s{i+1}'
                ])
        
        df.columns = columns[:n_cols]
        
        # Convert time to datetime
        df['datetime'] = pd.to_datetime(df['time_s'], unit='s', origin='unix')
        
        return df
    
    def read_spatial_output(self, 
                           file_path: str,
                           n_layers: int,
                           n_columns: int) -> Dict[float, np.ndarray]:
        """
        Read spatial output file (theta, psi, etc.)
        
        Parameters:
        -----------
        file_path : str
            Path to output file
        n_layers : int
            Number of soil layers
        n_columns : int
            Number of columns
        
        Returns:
        --------
        dict
            Dictionary with time as key and 2D arrays as values
        """
        full_path = self.model_dir / file_path
        
        results = {}
        current_time = None
        data_buffer = []
        
        with open(full_path, 'r') as f:
            for line in f:
                # Check for time marker
                time_match = re.search(r'Time:\s+([\d.]+)', line)
                if time_match:
                    # Save previous data if exists
                    if current_time is not None and data_buffer:
                        array = np.array(data_buffer).reshape(n_layers, n_columns)
                        results[current_time] = array
                    
                    current_time = float(time_match.group(1))
                    data_buffer = []
                    continue
                
                # Parse data line
                values = line.split()
                if values:
                    try:
                        data_buffer.extend([float(v) for v in values])
                    except ValueError:
                        continue
        
        # Save last dataset
        if current_time is not None and data_buffer:
            array = np.array(data_buffer).reshape(n_layers, n_columns)
            results[current_time] = array
        
        return results
    
    def read_time_series(self, file_path: str) -> pd.DataFrame:
        """
        Read time series output (e.g., qoben.out)
        
        Parameters:
        -----------
        file_path : str
            Path to time series file
        
        Returns:
        --------
        pd.DataFrame
            Time series data
        """
        full_path = self.model_dir / file_path
        
        # Read file and parse
        data = []
        with open(full_path, 'r') as f:
            for line in f:
                if line.strip() and not line.startswith('#'):
                    values = line.split()
                    if len(values) >= 2:
                        try:
                            time = float(values[0])
                            value = float(values[1])
                            data.append([time, value])
                        except ValueError:
                            continue
        
        df = pd.DataFrame(data, columns=['time_s', 'value'])
        return df


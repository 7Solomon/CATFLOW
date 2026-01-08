import pandas as pd
import numpy as np
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, Optional
import re

@dataclass
class SimulationResults:
    """
    Holds all output data from a simulation run.
    """
    # Global Time Series (bilanz.csv)
    water_balance: pd.DataFrame
    
    # Spatial Fields (theta.out, psi.out)
    # Dictionary mapping Time -> 2D Array (Layers x Cols)
    moisture_fields: Dict[float, np.ndarray]
    pressure_fields: Dict[float, np.ndarray]

    @classmethod
    def load_from_folder(cls, folder_path: str, n_layers: int, n_cols: int) -> 'SimulationResults':
        folder = Path(folder_path)
        
        # 1. Load Bilanz
        bilanz_path = folder / "out/bilanz.csv"
        if bilanz_path.exists():
            df = pd.read_csv(bilanz_path, sep=';', header=None)
            # Assign columns (simplified standard set)
            cols = ['hillslope', 'timestep', 'time_s', 'balance_total', 'balance_in', 'balance_sink', 
                    'balance_bound', 'flux_top', 'flux_right', 'flux_bottom', 'flux_left', 
                    'runoff_cum', 'runoff_coeff', 'precip', 'precip2', 'intercept', 'evap', 'transp']
            # Truncate or extend columns as needed
            df.columns = cols[:len(df.columns)]
        else:
            df = pd.DataFrame()

        # 2. Load Spatial Fields
        theta = cls._parse_spatial_file(folder / "out/theta.out", n_layers, n_cols)
        psi = cls._parse_spatial_file(folder / "out/psi.out", n_layers, n_cols)
        
        return cls(water_balance=df, moisture_fields=theta, pressure_fields=psi)

    @staticmethod
    def _parse_spatial_file(path: Path, n_layers: int, n_cols: int) -> Dict[float, np.ndarray]:
        results = {}
        if not path.exists(): return results
        
        current_time = None
        buffer = []
        
        with open(path, 'r') as f:
            for line in f:
                # Detect "Time: 1234.5"
                if "Time:" in line:
                    # Save previous block
                    if current_time is not None and buffer:
                        try:
                            arr = np.array(buffer)
                            # Only reshape if size matches (handle partial writes)
                            if arr.size == n_layers * n_cols:
                                results[current_time] = arr.reshape(n_layers, n_cols)
                        except: pass
                    
                    # Start new block
                    try:
                        match = re.search(r'Time:\s+([\d.eE+-]+)', line)
                        current_time = float(match.group(1)) if match else 0.0
                    except: current_time = 0.0
                    buffer = []
                else:
                    # Collect numbers
                    try:
                        buffer.extend([float(x) for x in line.split()])
                    except: pass
                    
        # Save last block
        if current_time is not None and buffer:
             arr = np.array(buffer)
             if arr.size == n_layers * n_cols:
                 results[current_time] = arr.reshape(n_layers, n_cols)
                 
        return results

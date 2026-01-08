import numpy as np
import pandas as pd
from datetime import datetime
from typing import Dict, List, Tuple, Optional, Union
import re

class BoundaryConditions:
    """BCs"""
    
    @staticmethod
    def create_rainfall_series(times: List[datetime],
                               values: List[float],
                               output_file: str,
                               time_unit: str = 's',
                               value_unit: str = 'm/s'):
        # Convert time unit to seconds
        unit_factors = {'s': 1, 'min': 60, 'h': 3600, 'd': 86400}
        factor = unit_factors.get(time_unit, 1)
        
        with open(output_file, 'w') as f:
            f.write(f"# Rainfall time series\n")
            f.write(f"# Time unit: {time_unit}, Value unit: {value_unit}\n")
            
            base_time = times[0]
            for t, v in zip(times, values):
                elapsed = (t - base_time).total_seconds() / factor
                f.write(f"{elapsed:15.6f}  1  {v:12.6e}\n")
    
    @staticmethod
    def create_constant_bc(value: float,
                          bc_type: int,
                          output_file: str):
        with open(output_file, 'w') as f:
            f.write(f"0.0  {bc_type}  {value:12.6e}\n")
            f.write(f"1e20 {bc_type}  {value:12.6e}\n")


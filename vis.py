import pandas as pd
import numpy as np
from typing import List

class Visualization:
    """Helper class for visualizing CATFLOW results"""
    
    @staticmethod
    def plot_water_balance(df: pd.DataFrame, 
                          components: List[str] = None,
                          save_path: str = None):
        """
        Plot water balance components
        
        Parameters:
        -----------
        df : pd.DataFrame
            Water balance dataframe
        components : List[str]
            Components to plot
        save_path : str
            Path to save figure
        """
        import matplotlib.pyplot as plt
        
        if components is None:
            components = ['precip', 'evaporation', 'transpiration', 
                         'runoff_cum', 'balance_total']
        
        fig, ax = plt.subplots(figsize=(12, 6))
        
        for comp in components:
            if comp in df.columns:
                ax.plot(df['datetime'], df[comp], label=comp)
        
        ax.set_xlabel('Time')
        ax.set_ylabel('Cumulative flux [m³]')
        ax.legend()
        ax.grid(True, alpha=0.3)
        
        if save_path:
            plt.savefig(save_path, dpi=300, bbox_inches='tight')
        
        plt.show()
    
    @staticmethod
    def plot_soil_moisture_profile(data: np.ndarray,
                                   depths: np.ndarray,
                                   x_coords: np.ndarray,
                                   time_label: str = "",
                                   save_path: str = None):
        """
        Plot 2D soil moisture distribution
        
        Parameters:
        -----------
        data : np.ndarray
            2D array of soil moisture values
        depths : np.ndarray
            Depth coordinates [m]
        x_coords : np.ndarray
            Lateral coordinates [m]
        time_label : str
            Time label for title
        save_path : str
            Path to save figure
        """
        import matplotlib.pyplot as plt
        
        fig, ax = plt.subplots(figsize=(12, 6))
        
        im = ax.contourf(x_coords, depths, data, levels=20, cmap='Blues')
        ax.set_xlabel('Distance [m]')
        ax.set_ylabel('Depth [m]')
        ax.set_title(f'Soil Moisture Distribution - {time_label}')
        
        cbar = plt.colorbar(im, ax=ax)
        cbar.set_label('Volumetric water content [-]')
        
        if save_path:
            plt.savefig(save_path, dpi=300, bbox_inches='tight')
        
        plt.show()
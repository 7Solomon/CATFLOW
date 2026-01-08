from typing import Dict, List

class SoilParameters:
    """Soil hydraulic parameters"""
    
    @staticmethod
    def van_genuchten(theta_s: float,
                    theta_r: float,
                    alpha: float,
                    n: float,
                    k_sat: float,
                    name: str = "VG_Soil") -> Dict:
        m = 1 - 1/n
        return {
            'name': name,
            'model': 1,  # Van Genuchten
            'theta_s': theta_s,
            'theta_r': theta_r,
            'alpha': alpha,
            'n': n,
            'm': m,
            'k_sat': k_sat,
            'l': 0.5  # Pore connectivity parameter
        }
    
    @staticmethod
    def write_soil_definition(soils: List[Dict],
                            output_file: str):
        """
        Write soil parameter definition file, compatible with THE CATFLOW
        """
        with open(output_file, 'w') as f:
            f.write(f"{len(soils)}           % Number of soil types\n")
            
            for i, soil in enumerate(soils, 1):
                f.write(f"\n% Soil type {i}: {soil['name']}\n")
                f.write(f"{i:3d}  {soil['model']:2d}  '{soil['name']}'\n")
                f.write(f"  {soil['theta_s']:.4f}  {soil['theta_r']:.4f}  ")
                f.write(f"{soil['alpha']:.6f}  {soil['n']:.4f}  ")
                f.write(f"{soil['k_sat']:.6e}\n")


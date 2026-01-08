import subprocess
import os
import shutil
from pathlib import Path
from comparator import CATFLOWComparator
from diagnostic import CATFLOWDiagnostic
from model.project import CATFLOWProject
from model.outputs import SimulationResults

class CATFLOWRunner:
    def __init__(self, executable_path: str):
        self.executable = Path(executable_path).resolve()
        if not self.executable.exists():
            raise FileNotFoundError(f"Solver not found at {self.executable}")

    def run(self, project: CATFLOWProject, working_dir: str = "ft_backend") -> CATFLOWProject:
        """
        Runs the solver on the given project.
        
        Args:
            project: The project object (used for dimensions when parsing output).
            working_dir: The directory where the simulation runs.
            write_inputs: If True, writes the python project state to .in files before running.
                          If False, assumes .in files already exist in working_dir.
        """
        work_path = Path(working_dir).resolve()
    
        original_dir = os.getcwd()
        os.chdir(work_path)
        try:
            print(f"Executing: {self.executable.name}")
            result = subprocess.run([str(self.executable)], check=False, capture_output=True, text=True)
            print("Solver finished.")
            if result.returncode != 0:
                print(f"Warning: Solver exited with code {result.returncode}")
                # print(result.stderr) # Uncomment to debug
        except Exception as e:
            print(f"Execution failed: {e}")
        finally:
            os.chdir(original_dir)
            
        # C. Collect Results
        # We need the mesh dimensions to parse spatial outputs.
        # If the project wasn't loaded fully (e.g. just a wrapper), this might fail.
        if project.mesh:
            print("Parsing results...")
            results = SimulationResults.load_from_folder(
                str(work_path), 
                n_layers=project.mesh.n_layers, 
                n_cols=project.mesh.n_columns
            )
            project.results = results
            print(f"Loaded {len(results.water_balance)} time steps.")
        else:
            print("Warning: Project has no mesh loaded. Cannot parse spatial results.")
            
        return project
    


def RUN():
    base_data_folder = "ft_backend" 
    #runner = CATFLOWRunner(f"{base_data_folder}/catflow.exe")

    #project = CATFLOWProject.from_legacy_folder(base_data_folder)
    #project.summary()
    project = CATFLOWProject.load("TEST/new")
    project.write_to_folder(base_data_folder)


def diagnose():
    import sys
    #diagnostic = CATFLOWDiagnostic("ft_backend")
    #results = diagnostic.run_full_diagnostic()
    #sys.exit(len(results['errors']))
    comp = CATFLOWComparator("IN_TEMPLATE", "ft_backend")
    comp.compare()


if __name__ == "__main__":
    diagnose()
    #RUN()
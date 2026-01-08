import subprocess
import os
import shutil
from pathlib import Path
from model.project import CATFLOWProject
from model.outputs import SimulationResults

class CATFLOWRunner:
    def __init__(self, executable_path: str):
        self.executable = Path(executable_path).resolve()
        if not self.executable.exists():
            raise FileNotFoundError(f"Solver not found at {self.executable}")

    def run(self, 
            project: CATFLOWProject, 
            working_dir: str = "ft_backend", 
            write_inputs: bool = False) -> CATFLOWProject:
        """
        Runs the solver on the given project.
        
        Args:
            project: The project object (used for dimensions when parsing output).
            working_dir: The directory where the simulation runs.
            write_inputs: If True, writes the python project state to .in files before running.
                          If False, assumes .in files already exist in working_dir.
        """
        work_path = Path(working_dir).resolve()
        
        # A. Clean & Create Directory (only if we are writing new inputs)
        #if write_inputs:
        #    if work_path.exists():
        #        # Optional: shutil.rmtree(work_path) to start clean
        #        pass
        #    work_path.mkdir(parents=True, exist_ok=True)
        #    
        #    print(f"--- Generating Inputs in {work_path} ---")
        #    project.write_to_folder(str(work_path))
        #else:
        #    print(f"--- Using Existing Inputs in {work_path} ---")
        #    if not work_path.exists():
        #        raise FileNotFoundError(f"Working directory {work_path} does not exist!")

        # B. Execute
        original_dir = os.getcwd()
        os.chdir(work_path)
        try:
            print(f"Executing: {self.executable.name}")
            # Capture output so we can see if it actually ran
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

if __name__ == "__main__":
    base_data_folder = "ft_backend" 
    runner = CATFLOWRunner(f"{base_data_folder}/catflow.exe")

    project = CATFLOWProject.from_legacy_folder(base_data_folder)
    
    print("Running in existing folder...")
    project = runner.run(project, working_dir=base_data_folder)

    # 5. ANALYZE
    if project.results:
        print(project.results.water_balance.head())
        
        # Access spatial moisture at t=3600.0
        # moisture_map = project.results.moisture_fields.get(3600.0)

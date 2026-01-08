import subprocess
import os
from pathlib import Path
import pandas as pd
from data_types import CATFLOWProject

class CATFLOWRunner:
    def __init__(self, executable_path: str):
        self.executable = Path(executable_path).resolve()
        if not self.executable.exists():
            raise FileNotFoundError(f"Solver not found at {self.executable}")

    def run_project(self, project: CATFLOWProject, working_dir: str = "temp_run"):
        """
        Takes a Project object, writes it to disk, runs it, and returns results.
        """
        work_path = Path(working_dir).resolve()
        work_path.mkdir(parents=True, exist_ok=True)
        
        print(f"Preparing simulation for '{project.name}' in {work_path}...")
        
        # 1. Write the project state to legacy files
        # (Assuming you implemented write_to_execution_folder in the dataclass)
        # project.write_to_execution_folder(work_path)
        
        # NOTE: For now, if you are just reading existing files, 
        # you might assume the files are already there.
        
        # 2. Execute
        original_dir = os.getcwd()
        os.chdir(work_path)
        try:
            print("Running Solver...")
            result = subprocess.run(
                [str(self.executable)],
                capture_output=True,
                text=True
            )
            print("Solver finished.")
            if result.stderr: print("Errors:", result.stderr)
            
        finally:
            os.chdir(original_dir)
            
        # 3. Read Results (Bilanz)
        results_path = work_path / "out" / "bilanz.csv"
        if results_path.exists():
            return pd.read_csv(results_path, sep=';', header=None)
        return None

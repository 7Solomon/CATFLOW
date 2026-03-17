import shutil
import uuid
import subprocess
import os
import platform
import asyncio
from pathlib import Path
from typing import Optional


from managers.sessions import session_store

class WorkspaceManager:
    def __init__(self, base_dir: str = "./workspaces", binary_path: str = "./bin/catflow"):
        self.base_dir = Path(base_dir)
        self.base_dir.mkdir(parents=True, exist_ok=True)
        self.binary_path = Path(binary_path)
        
        # Ensure binary dir exists or print warning
        if not self.binary_path.parent.exists():
            print(f"WARNING: Binary folder {self.binary_path.parent} does not exist.")

    def create_session(self, source_path: str) -> str:
        """Creates a new isolated workspace from a source folder"""
        session_id = str(uuid.uuid4())
        target_dir = self.base_dir / session_id
        
        print(f"Creating workspace: {target_dir} from {source_path}")
        # Copy files to workspace (Fast isolation)
        shutil.copytree(source_path, target_dir)
        
        return session_id

    def get_project_path(self, session_id: str) -> Path:
        return self.base_dir / session_id

    def delete_session(self, session_id: str):
        path = self.get_project_path(session_id)
        if path.exists():
            shutil.rmtree(path)

    async def run_simulation_task(self, session_id: str):
        """
        Runs the binary inside the workspace.
        Updates session status in the store: running -> completed/failed.
        """
        cwd = self.get_project_path(session_id)
        
        # 1. Update Status -> RUNNING
        session_data = session_store.get_session(session_id)
        if session_data:
            session_data['status'] = 'running'
            session_store.save_session(session_id, session_data)

        # 2. Determine Executable Path
        # Docker usually runs Linux, but dev might be Windows
        exe_name = "catflow.exe" if platform.system() == "Windows" else "catflow"
        # Assuming binary_path points to the file base name without extension in config
        # or points to the folder. Let's assume it points to the file base "./bin/catflow"
        exe_path = self.binary_path.parent / exe_name
        
        log_file_path = cwd / "simulation.log"

        try:
            if not exe_path.exists():
                raise FileNotFoundError(f"Binary not found at {exe_path}")

            print(f"[{session_id}] Starting simulation...")
            
            # 3. Run Process (Blocking call in a thread to avoid freezing async loop)
            # We open the log file to redirect stdout/stderr
            with open(log_file_path, "w") as log_file:
                # We use asyncio.to_thread to run the blocking subprocess call safely
                return_code = await asyncio.to_thread(
                    self._execute_subprocess, 
                    str(exe_path.resolve()), 
                    str(cwd), 
                    log_file
                )

            # 4. Update Status based on result
            if session_data:
                # Reload session data in case it changed (unlikely here but good practice)
                session_data = session_store.get_session(session_id) or session_data
                
                if return_code == 0:
                    session_data['status'] = 'completed'
                    print(f"[{session_id}] Simulation completed successfully.")
                else:
                    session_data['status'] = 'failed'
                    session_data['error'] = f"Process exited with code {return_code}"
                    print(f"[{session_id}] Simulation failed with code {return_code}.")
                
                session_store.save_session(session_id, session_data)

        except Exception as e:
            print(f"[{session_id}] Simulation Error: {e}")
            if session_data:
                session_data['status'] = 'error'
                session_data['error'] = str(e)
                session_store.save_session(session_id, session_data)
                
            # Log exception to file too
            with open(log_file_path, "a") as f:
                f.write(f"\nCRITICAL ERROR: {str(e)}\n")

    def _execute_subprocess(self, exe: str, cwd: str, log_file) -> int:
        """Helper to run subprocess synchronously (to be threaded)"""
        process = subprocess.run(
            [exe], 
            cwd=cwd,
            stdout=log_file,
            stderr=subprocess.STDOUT
        )
        return process.returncode

workspace_manager = WorkspaceManager()

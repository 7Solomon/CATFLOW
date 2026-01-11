import subprocess
import os
import shutil
from pathlib import Path
from comparator import CATFLOWComparator
from diagnostic import CATFLOWDiagnostic
from model.outputs import SimulationResults
from model.project import CATFLOWProject

def RUN():
    base_data_folder = "ft_backend" 
    #runner = CATFLOWRunner(f"{base_data_folder}/catflow.exe")

    #project = CATFLOWProject.from_legacy_folder("IN_TEMPLATE")
    #project.summary()
#
    #project = CATFLOWProject.load("TEST/new")
    #


def diagnose():
    import sys
    #diagnostic = CATFLOWDiagnostic("ft_backend")
    #results = diagnostic.run_full_diagnostic()
    #sys.exit(len(results['errors']))
    project = CATFLOWProject.from_legacy_folder("backend/IN_TEMPLATE")
    #project.summary()
    project.write_to_folder("backend/ft_backend")
    
    comp = CATFLOWComparator("backend/IN_TEMPLATE", "backend/ft_backend")
    comp.compare()


if __name__ == "__main__":
    diagnose()
    #RUN()
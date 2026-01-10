from typing import Optional
from fastapi import HTTPException

from model.project import CATFLOWProject

current_project: Optional[CATFLOWProject] = None
project_source_path: Optional[str] = None

def set_current_project(project):
    global current_project
    current_project = project

def get_project_or_404() -> CATFLOWProject:
    if current_project is None:
        raise HTTPException(status_code=404, detail="No project loaded")
    return current_project

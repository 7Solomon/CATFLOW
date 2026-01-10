from fastapi import HTTPException, APIRouter
from typing import List, Dict
from pathlib import Path
from state import get_project_or_404, set_current_project, project_source_path
from response import ProjectLoadRequest, ProjectSummary
from model.project import CATFLOWProject

router = APIRouter(prefix="/api/project")

@router.post("/load")
async def load_project(request: ProjectLoadRequest):
    """Load a CATFLOW project from a legacy folder"""
    global project_source_path
    folder_path = request.path
    try:
        path = Path(folder_path)
        if not path.exists():
            raise HTTPException(status_code=404, detail=f"Folder not found: {folder_path}")
            
        current_project = CATFLOWProject.from_legacy_folder(str(path))
        set_current_project(current_project)
        project_source_path = str(path)
        
        summary_data = await get_project_summary()
        return {
            "status": "success",
            "message": f"Loaded project from {folder_path}",
            "summary": summary_data
        }
    except Exception as e:
        print(e)
        raise HTTPException(status_code=500, detail=f"Failed to load project: {str(e)}")

@router.get("/summary", response_model=ProjectSummary)
async def get_project_summary():
    """Get high-level project summary"""
    project = get_project_or_404()
    return ProjectSummary(
        name=project.name,
        n_hills=len(project.hills),
        has_soil_library=project.soil_library is not None,
        has_forcing=project.forcing is not None,
        has_land_use=project.land_use_library is not None,
        has_wind=project.wind_library is not None,
        simulation_start=project.run_control.start_time if project.run_control else None,
        simulation_end=project.run_control.end_time if project.run_control else None,
        method=project.run_control.method if project.run_control else None
    )

@router.get("/config")
async def get_run_config():
    """Get detailed run configuration"""
    project = get_project_or_404()
    if not project.run_control:
        return {}
        
    rc = project.run_control
    return {
        "timing": {
            "start_time": rc.start_time,
            "end_time": rc.end_time,
            "offset": rc.offset,
            "dt_max": rc.dt_max,
            "dt_min": rc.dt_min,
            "dt_init": rc.dt_init
        },
        "solver": {
            "method": rc.method,
            "it_max": rc.it_max,
            "piceps": rc.piceps,
            "cgeps": rc.cgeps,
            "d_th_opt": rc.d_th_opt,
            "d_phi_opt": rc.d_phi_opt
        },
        "location": {
            "longitude": rc.longi,
            "latitude": rc.lati,
            "ref_longitude": rc.rlongi
        },
        "output_files": rc.output_files
    }

@router.get("/files")
async def get_project_files():
    """List all input files associated with the project"""
    project = get_project_or_404()
    return {
        "input_files": project.run_control.input_files if project.run_control else [],
        "output_files": project.run_control.output_files if project.run_control else []
    }


@router.get("/dimensions")
async def get_project_dimensions():
    """Get global mesh dimensions summary"""
    project = get_project_or_404()
    
    total_nodes = sum(
        (h.mesh.n_layers * h.mesh.n_columns) 
        for h in project.hills 
        if h.mesh
    )
    
    return {
        "n_hills": len(project.hills),
        "total_nodes": total_nodes,
        "hill_dimensions": [
            {
                "id": h.id, 
                "rows": h.mesh.n_layers if h.mesh else 0,
                "cols": h.mesh.n_columns if h.mesh else 0
            } 
            for h in project.hills
        ]
    }

@router.get("/validation")
async def validate_project():
    """Check for missing data or configuration issues"""
    project = get_project_or_404()
    issues = []
    
    if not project.soil_library:
        issues.append({"type": "error", "message": "Soil library is missing"})
        
    if not project.forcing:
        issues.append({"type": "error", "message": "Forcing data is missing"})
        
    for hill in project.hills:
        if not hill.mesh:
             issues.append({"type": "error", "message": f"Hill {hill.id} has no mesh"})
        if not hill.soil_map:
             issues.append({"type": "warning", "message": f"Hill {hill.id} has no soil map"})
             
    return {
        "valid": len(issues) == 0,
        "issues": issues
    }
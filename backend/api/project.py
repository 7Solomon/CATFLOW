from fastapi import HTTPException, APIRouter
from pathlib import Path
import os

from state import get_project_or_404, set_current_project, project_source_path, TEMPLATE_FOLDER
from response import ProjectLoadRequest, ProjectSummary
from model.project import CATFLOWProject

router = APIRouter(prefix="/api/project")

from fastapi import HTTPException, APIRouter
from pathlib import Path
import os
from state import get_project_or_404, set_current_project, project_source_path, TEMPLATE_FOLDER
from response import ProjectLoadRequest, ProjectSummary
from model.project import CATFLOWProject

router = APIRouter(prefix="/api/project")

@router.post("/list")
async def list_project():
    try:
        if not os.path.exists(TEMPLATE_FOLDER):
             raise HTTPException(status_code=500, detail=f"Template folder '{TEMPLATE_FOLDER}' not configured on server")
             
        templates = [d for d in os.listdir(TEMPLATE_FOLDER) 
                     if os.path.isdir(os.path.join(TEMPLATE_FOLDER, d))]
        
        return {
            "status": "success",
            "data": templates
        }
    except Exception as e:
        print(f"Error listing projects: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to list projects: {str(e)}")

@router.post("/load")
async def load_project(request: ProjectLoadRequest):
    """Load a CATFLOW project from the template folder"""
    global project_source_path
    
    # Request path is just the folder name (e.g., "Weiherbach")
    folder_name = request.path
    
    # Construct full path
    full_path = Path(TEMPLATE_FOLDER) / folder_name
    
    try:
        if not full_path.exists():
            raise HTTPException(status_code=404, detail=f"Project folder not found: {folder_name}")
            
        print(f"Loading project from: {full_path}")
        current_project = CATFLOWProject.from_legacy_folder(str(full_path))
        set_current_project(current_project)
        project_source_path = str(full_path)
        
        summary_data = await get_project_summary()
        return {
            "status": "success",
            "message": f"Loaded project {folder_name}",
            "summary": summary_data
        }
    except Exception as e:
        print(f"Error loading project: {e}")
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
    # Map your RunControl attributes to the response
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
    
    # Updated to use 'header.iacnv' and 'header.iacnl'
    total_nodes = 0
    hill_dims = []

    for h in project.hills:
        rows = 0
        cols = 0
        if h.mesh and h.mesh.header:
            rows = h.mesh.header.iacnv  # Vertical nodes
            cols = h.mesh.header.iacnl  # Lateral nodes
            total_nodes += (rows * cols)
            
        hill_dims.append({
            "id": h.id, 
            "rows": rows,
            "cols": cols
        })
    
    return {
        "n_hills": len(project.hills),
        "total_nodes": total_nodes,
        "hill_dimensions": hill_dims
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

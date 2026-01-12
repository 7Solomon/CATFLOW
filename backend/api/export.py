from fastapi import HTTPException, APIRouter
from typing import List
from pathlib import Path
from response import WritePreview
from state import get_project_or_404, project_source_path

router = APIRouter(prefix="/api/export")

@router.post("/preview", response_model=WritePreview)
async def preview_export(target_folder: str):
    """Preview what files will be created during export"""
    project = get_project_or_404()
    raise NotImplementedError("YIKES")
    
    files = {
        "Control Files": ["CATFLOW.IN", "run_01.in"],
        "Global Libraries": [
            "in/soil/soils.def",
            "in/control/timeser.def",
            "in/landuse/lu_file.def",
            "in/climate/winddir.def"
        ],
        "Precipitation Data": [],
        "Climate Data": [],
        "Land Use Data": []
    }
    
    warnings = []
    
    # Add forcing files
    if project.forcing:
        files["Precipitation Data"] = [f"in/precip/{p.filename}" for p in project.forcing.precip_data]
        files["Climate Data"] = [f"in/climate/{c.filename}" for c in project.forcing.climate_data]
        
        if project.forcing.landuse_timeline:
            files["Land Use Data"].append("in/landuse/lu_ts.dat")
            for period in project.forcing.landuse_timeline.periods:
                files["Land Use Data"].append(f"in/landuse/{period.lookup.filename}")
    
    # Add hill files
    for i, hill in enumerate(project.hills):
        prefix = f"in/hill_{i+1}"
        hill_files = [
            f"{prefix}/hang.geo",
            f"{prefix}/soils.bod",
            f"{prefix}/kstat.dat",
            f"{prefix}/thstat.dat",
            f"{prefix}/profil.mak",
            f"{prefix}/control.cv",
            f"{prefix}/initial.ini",
            f"{prefix}/printout.prt",
            f"{prefix}/surface.pob",
            f"{prefix}/boundary.rb"
        ]
        files[f"Hill {i+1}"] = hill_files
    
    # Check for potential issues
    if not project.soil_library:
        warnings.append("Soil library is missing")
    if not project.forcing:
        warnings.append("Forcing configuration is missing")
    
    total = sum(len(v) for v in files.values())
    
    return WritePreview(
        target_folder=target_folder,
        files_to_create=files,
        total_files=total,
        warnings=warnings
    )


@router.post("/write")
async def write_project(target_folder: str):
    """Export the project to a new folder"""
    project = get_project_or_404()
    
    try:
        project.write_to_folder(target_folder, project_source_path)
        return {
            "status": "success",
            "message": f"Project written to {target_folder}",
            "folder": target_folder
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Export failed: {str(e)}")

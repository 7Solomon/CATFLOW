from fastapi import HTTPException, APIRouter
from typing import List, Dict, Any
from api.utils import numpy_to_list
from response import ForcingOverview
from state import get_project_or_404

router = APIRouter(prefix="/api/forcing")

@router.get("/overview", response_model=ForcingOverview)
async def get_forcing_overview():
    """Get overview of forcing data"""
    project = get_project_or_404()
    if not project.forcing:
        return ForcingOverview(
            n_precip_files=0,
            n_climate_files=0,
            has_landuse_timeline=False,
            precip_filenames=[],
            climate_filenames=[]
        )
    
    return ForcingOverview(
        n_precip_files=len(project.forcing.precip_data),
        n_climate_files=len(project.forcing.climate_data),
        has_landuse_timeline=project.forcing.landuse_timeline is not None,
        precip_filenames=[p.filename for p in project.forcing.precip_data],
        climate_filenames=[c.filename for c in project.forcing.climate_data]
    )

@router.get("/precipitation/{index}")
async def get_precipitation_data(index: int):
    """Get precipitation time series data"""
    project = get_project_or_404()
    if not project.forcing or index >= len(project.forcing.precip_data):
        raise HTTPException(status_code=404, detail="Precipitation data not found")
    
    precip = project.forcing.precip_data[index]
    return {
        "filename": precip.filename,
        "header_date": precip.header_date,
        "factor_t": precip.factor_t,
        "factor_v": precip.factor_v,
        "n_records": len(precip.data),
        "data_preview": numpy_to_list(precip.data[:100]) if len(precip.data) > 0 else []
    }

@router.get("/climate/{index}")
async def get_climate_data(index: int):
    """Get climate time series data"""
    project = get_project_or_404()
    if not project.forcing or index >= len(project.forcing.climate_data):
        raise HTTPException(status_code=404, detail="Climate data not found")
    
    climate = project.forcing.climate_data[index]
    return {
        "filename": climate.filename,
        "header_date": climate.header_date,
        "n_records": len(climate.data),
        "data_preview": numpy_to_list(climate.data[:100]) if len(climate.data) > 0 else []
    }

@router.get("/landuse/timeline")
async def get_landuse_timeline():
    """Get Land Use Timeline structure"""
    project = get_project_or_404()
    if not project.forcing or not project.forcing.landuse_timeline:
        raise HTTPException(status_code=404, detail="Land use timeline not found")
    
    timeline = project.forcing.landuse_timeline
    return {
        "periods": [
            {
                "time": p.time,
                "lookup_file": p.lookup.filename,
                "mappings": p.lookup.mappings  # Dictionary of id -> plant_id mappings
            }
            for p in timeline.periods
        ]
    }

@router.get("/landuse/library")
async def get_landuse_library():
    """Get all plant definitions from the library"""
    project = get_project_or_404()
    if not project.forcing or not project.forcing.landuse_library:
        return []
    
    return [
        {
            "id": p.id,
            "name": p.name,
            "type": p.type
        }
        for p in project.forcing.landuse_library.plants
    ]

@router.get("/landuse/plant/{plant_id}")
async def get_plant_details(plant_id: int):
    """Get specific parameters for a plant definition"""
    project = get_project_or_404()
    if not project.forcing or not project.forcing.landuse_library:
        raise HTTPException(status_code=404, detail="Land use library not loaded")
        
    plant = next((p for p in project.forcing.landuse_library.plants if p.id == plant_id), None)
    if not plant:
        raise HTTPException(status_code=404, detail=f"Plant ID {plant_id} not found")
        
    return {
        "id": plant.id,
        "name": plant.name,
        "parameters": plant.parameters  # Dictionary of parameter tables
    }


@router.get("/files")
async def get_forcing_files():
    """Get lists of boundary and sink files"""
    project = get_project_or_404()
    if not project.forcing:
        return {"boundary_files": [], "sink_files": []}
        
    return {
        "boundary_files": project.forcing.boundary_files,
        "sink_files": project.forcing.sink_files
    }
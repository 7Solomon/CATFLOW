from fastapi import HTTPException, APIRouter
from typing import List, Dict
from state import get_project_or_404

router = APIRouter(prefix="/api/wind")

@router.get("/library")
async def get_wind_library():
    """Get all wind sector definitions"""
    project = get_project_or_404()
    if not project.wind_library:
        return []
        
    return [
        {
            "id": sector.id,
            "angle_start": sector.angle_start,
            "angle_end": sector.angle_end,
            "exposure_factor": sector.exposure_factor,
            "description": sector.description
        }
        for sector in project.wind_library.sectors
    ]

from fastapi import APIRouter
from state import get_project_or_404

router = APIRouter(prefix="/api/wind")

@router.get("/library")
async def get_wind_library():
    """Get all wind sector definitions"""
    project = get_project_or_404()
    if not project.wind_library:
        return []
    
    # Calculate start angles based on previous sector's upper_angle
    sectors = []
    prev_angle = 0.0
    
    for sector in project.wind_library.sectors:
        sectors.append({
            "angle_start": prev_angle,
            "angle_end": sector.upper_angle,
            "exposure_factor": sector.exposure_factor
        })
        prev_angle = sector.upper_angle
        
    return sectors

from fastapi import HTTPException, APIRouter
from typing import List
from pathlib import Path
from state import get_project_or_404
from response import SoilTypeDTO

router = APIRouter(prefix="/api/soil")

@router.get("/library", response_model=List[SoilTypeDTO])
async def get_soil_library():
    """Get all soil types from the library"""
    project = get_project_or_404()
    
    if not project.soil_library:
        return []
    
    return [
        SoilTypeDTO(
            id=s.id,
            name=s.name,
            ks=s.ks,
            theta_s=s.theta_s,
            theta_r=s.theta_r,
            alpha=s.alpha,
            n_param=s.n_param,
            model_id=s.model_id
        )
        for s in project.soil_library.soils
    ]


@router.get("/api/soil/{soil_id}")
async def get_soil_details(soil_id: int):
    """Get detailed parameters for a specific soil type"""
    project = get_project_or_404()
    
    if not project.soil_library:
        raise HTTPException(status_code=404, detail="No soil library loaded")
    
    soil = next((s for s in project.soil_library.soils if s.id == soil_id), None)
    if not soil:
        raise HTTPException(status_code=404, detail=f"Soil ID {soil_id} not found")
    
    return {
        "id": soil.id,
        "name": soil.name,
        "hydraulic_model": soil.model_id,
        "table_size": soil.table_size,
        "anisotropy": {"x": soil.anisotropy_x, "z": soil.anisotropy_z},
        "parameters": {
            "ks": soil.ks,
            "theta_s": soil.theta_s,
            "theta_r": soil.theta_r,
            "alpha": soil.alpha,
            "n": soil.n_param
        },
        "extra_params": soil.extra_params
    }


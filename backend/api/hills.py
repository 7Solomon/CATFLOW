from fastapi import HTTPException, APIRouter
from typing import List
from pathlib import Path
from api.utils import numpy_to_list
from response import HillSummary, InitialConditionData, MeshCoordinates, SoilMapData

from state import get_project_or_404
import numpy as np

router = APIRouter(prefix="/api/hills")

@router.get("/", response_model=List[HillSummary])
async def get_hills():
    """Get summary of all hills"""
    project = get_project_or_404()
    
    summaries = []
    for hill in project.hills:
        unique_ids = []
        if hill.soil_map:
            unique_ids = np.unique(hill.soil_map.assignment_matrix).tolist()
        
        summaries.append(HillSummary(
            id=hill.id,
            name=hill.name,
            n_layers=hill.mesh.n_layers if hill.mesh else 0,
            n_columns=hill.mesh.n_columns if hill.mesh else 0,
            total_nodes=(hill.mesh.n_layers * hill.mesh.n_columns) if hill.mesh else 0,
            has_soil_map=hill.soil_map is not None,
            has_surface_map=hill.surface_map is not None,
            has_macropores=hill.macropores is not None,
            has_boundary=hill.boundary is not None,
            has_initial_cond=hill.initial_cond is not None,
            unique_soil_ids=unique_ids
        ))
    
    return summaries


@router.get("/{hill_id}/mesh", response_model=MeshCoordinates)
async def get_hill_mesh(hill_id: int):
    """Get mesh coordinates for visualization"""
    project = get_project_or_404()
    
    hill = next((h for h in project.hills if h.id == hill_id), None)
    if not hill or not hill.mesh:
        raise HTTPException(status_code=404, detail=f"Hill {hill_id} or mesh not found")
    
    return MeshCoordinates(
        x_coords=numpy_to_list(hill.mesh.x_nodes),
        z_coords=numpy_to_list(hill.mesh.z_nodes),
        n_layers=hill.mesh.n_layers,
        n_columns=hill.mesh.n_columns
    )


@router.get("/{hill_id}/soil-map", response_model=SoilMapData)
async def get_soil_map(hill_id: int):
    """Get soil ID assignments for each node"""
    project = get_project_or_404()
    
    hill = next((h for h in project.hills if h.id == hill_id), None)
    if not hill or not hill.soil_map:
        raise HTTPException(status_code=404, detail="Soil map not found")
    
    matrix = hill.soil_map.assignment_matrix
    return SoilMapData(
        matrix=numpy_to_list(matrix),
        unique_ids=np.unique(matrix).tolist(),
        n_layers=matrix.shape[0],
        n_columns=matrix.shape[1]
    )


@router.get("/{hill_id}/initial-condition", response_model=InitialConditionData)
async def get_initial_condition(hill_id: int):
    """Get initial condition matrix"""
    project = get_project_or_404()
    
    hill = next((h for h in project.hills if h.id == hill_id), None)
    if not hill or not hill.initial_cond:
        raise HTTPException(status_code=404, detail="Initial condition not found")
    
    vals = hill.initial_cond.values
    return InitialConditionData(
        values=numpy_to_list(vals),
        type_id=hill.initial_cond.type_id,
        n_layers=vals.shape[0],
        n_columns=vals.shape[1],
        min_value=float(np.min(vals)),
        max_value=float(np.max(vals))
    )

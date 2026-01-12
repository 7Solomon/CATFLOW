from fastapi import HTTPException, APIRouter
from typing import List
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
            n_layers=hill.mesh.header.iacnv if hill.mesh else 0,
            n_columns=hill.mesh.header.iacnl if hill.mesh else 0,
            total_nodes=(hill.mesh.header.iacnv * hill.mesh.header.iacnl) if hill.mesh else 0,
            has_soil_map=hill.soil_map is not None,
            has_surface_map=hill.surface_map is not None,
            has_macropores=hill.macropores is not None,
            has_boundary=hill.boundary is not None,
            has_initial_cond=hill.initial_cond_sat is not None,
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
    
    n_layers = hill.mesh.header.iacnv
    n_columns = hill.mesh.header.iacnl
    
    # Extracts X (sko) and Z (hko) for EVERY node.
    x_grid = hill.mesh.data['sko'] # Shape (cols, rows)
    z_grid = hill.mesh.data['hko'] # Shape (cols, rows)
    
    # Convert to standard Python lists
    # Note: If you want [row][col] format (n_layers, n_columns), transpose (.T)
    # Current shape (cols, rows) -> x_grid[i] is a column.
    
    # Assuming MeshCoordinates expects List[List[float]]
    return MeshCoordinates(
        x_coords=x_grid.tolist(), 
        z_coords=z_grid.tolist(),
        n_layers=n_layers,
        n_columns=n_columns
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
        n_layers=matrix.shape[1],  # Note: shape is (n_columns, n_layers)
        n_columns=matrix.shape[0]
    )

@router.get("/{hill_id}/surface-map")
async def get_surface_map(hill_id: int):
    """Get surface assignments (landuse and climate IDs per column)"""
    project = get_project_or_404()
    hill = next((h for h in project.hills if h.id == hill_id), None)
    if not hill or not hill.surface_map:
        raise HTTPException(status_code=404, detail="Surface map not found")
    
    # Extract IDs from surface_data list
    landuse_ids = [row.land_use_id for row in hill.surface_map.surface_data]
    climate_ids = [row.climat_id for row in hill.surface_map.surface_data]
    
    return {
        "landuse_ids": landuse_ids,
        "climate_ids": climate_ids
    }

@router.get("/{hill_id}/boundary")
async def get_boundary_conditions(hill_id: int):
    """Get boundary condition IDs and sink terms"""
    project = get_project_or_404()
    hill = next((h for h in project.hills if h.id == hill_id), None)
    if not hill or not hill.boundary:
        raise HTTPException(status_code=404, detail="Boundary conditions not found")
        
    return {
        "edges": {
            "top": numpy_to_list(hill.boundary.top),
            "bottom": numpy_to_list(hill.boundary.bottom),
            "left": numpy_to_list(hill.boundary.left),
            "right": numpy_to_list(hill.boundary.right)
        },
        "sinks": {
            "matrix": numpy_to_list(hill.boundary.sinks),
            "unique_ids": np.unique(hill.boundary.sinks).tolist()
        }
    }

@router.get("/{hill_id}/macropores")
async def get_macropores(hill_id: int):
    """Get macropore factor matrix"""
    project = get_project_or_404()
    hill = next((h for h in project.hills if h.id == hill_id), None)
    if not hill or not hill.macropores:
        raise HTTPException(status_code=404, detail="Macropore data not found")
    
    # Extract fmac field from structured array
    fmac_matrix = hill.macropores.data['fmac']
    
    return {
        "matrix": numpy_to_list(fmac_matrix),
        "min": float(np.min(fmac_matrix)),
        "max": float(np.max(fmac_matrix)),
        "amac": numpy_to_list(hill.macropores.data['amac']),
        "beta": numpy_to_list(hill.macropores.data['beta'])
    }

@router.get("/{hill_id}/heterogeneity/k")
async def get_k_heterogeneity(hill_id: int):
    """Get hydraulic conductivity scaling map"""
    project = get_project_or_404()
    hill = next((h for h in project.hills if h.id == hill_id), None)
    if not hill or not hill.k_scaling:
        raise HTTPException(status_code=404, detail="K scaling map not found")
        
    return {
        "matrix": numpy_to_list(hill.k_scaling.factors),
        "stats": {
            "min": float(np.min(hill.k_scaling.factors)),
            "max": float(np.max(hill.k_scaling.factors)),
            "mean": float(np.mean(hill.k_scaling.factors))
        }
    }

@router.get("/{hill_id}/heterogeneity/theta")
async def get_theta_heterogeneity(hill_id: int):
    """Get porosity scaling map"""
    project = get_project_or_404()
    hill = next((h for h in project.hills if h.id == hill_id), None)
    if not hill or not hill.theta_scaling:
        raise HTTPException(status_code=404, detail="Theta scaling map not found")
        
    return {
        "matrix": numpy_to_list(hill.theta_scaling.factors),
        "stats": {
            "min": float(np.min(hill.theta_scaling.factors)),
            "max": float(np.max(hill.theta_scaling.factors)),
            "mean": float(np.mean(hill.theta_scaling.factors))
        }
    }

@router.get("/{hill_id}/initial-condition", response_model=InitialConditionData)
async def get_initial_condition(hill_id: int):
    """Get initial condition matrix"""
    project = get_project_or_404()
    hill = next((h for h in project.hills if h.id == hill_id), None)
    if not hill or not hill.initial_cond_sat:
        raise HTTPException(status_code=404, detail="Initial condition not found")
        
    vals = hill.initial_cond_sat.data
    return InitialConditionData(
        values=numpy_to_list(vals),
        type_id=hill.initial_cond_sat.type,
        n_layers=vals.shape[1],  # Shape is (n_columns, n_layers)
        n_columns=vals.shape[0],
        min_value=float(np.min(vals)),
        max_value=float(np.max(vals))
    )

@router.get("/{hill_id}/printout")
async def get_printout_config(hill_id: int):
    """Get printout times configuration"""
    project = get_project_or_404()
    hill = next((h for h in project.hills if h.id == hill_id), None)
    if not hill or not hill.printout:
        raise HTTPException(status_code=404, detail="Printout configuration not found")
    
    # Extract times from output_steps tuples
    times = [t for t, _ in hill.printout.output_steps]
    
    return {
        "times": numpy_to_list(times),
        "n_times": len(times),
        "reference_time": hill.printout.reference_time.isoformat(),
        "time_factor": hill.printout.time_factor
    }

@router.get("/{hill_id}/control-volume")
async def get_control_volume(hill_id: int):
    """Get control volume definition"""
    project = get_project_or_404()
    hill = next((h for h in project.hills if h.id == hill_id), None)
    if not hill or not hill.cv_def:
        raise HTTPException(status_code=404, detail="Control volume not found")
    
    return {
        "blocks": hill.cv_def.blocks,
        "n_blocks": len(hill.cv_def.blocks)
    }
from fastapi import HTTPException, APIRouter
from typing import Dict, List, Optional
import numpy as np
from api.utils import numpy_to_list, dataframe_to_json
from state import get_project_or_404

router = APIRouter(prefix="/api/results")

@router.get("/available")
async def check_results_availability():
    """Check if simulation results are loaded"""
    project = get_project_or_404()
    has_results = hasattr(project, 'results') and project.results is not None
    
    if not has_results:
        return {"available": False, "timesteps": []}
        
    return {
        "available": True,
        "timesteps": list(project.results.times) if hasattr(project.results, 'times') else []
    }

@router.get("/balance")
async def get_water_balance():
    """Get water balance time series"""
    project = get_project_or_404()
    if not hasattr(project, 'results') or not project.results:
        raise HTTPException(status_code=404, detail="No simulation results found")
        
    return dataframe_to_json(project.results.water_balance)

@router.get("/moisture/{time_idx}")
async def get_moisture_field(time_idx: int):
    """Get spatial moisture field for a specific time index"""
    project = get_project_or_404()
    if not hasattr(project, 'results') or not project.results:
        raise HTTPException(status_code=404, detail="No simulation results found")
        
    if time_idx not in project.results.moisture_fields:
        raise HTTPException(status_code=404, detail=f"Time index {time_idx} not found")
        
    data = project.results.moisture_fields[time_idx]
    return {
        "time_index": time_idx,
        "data": numpy_to_list(data),
        "stats": {
            "min": float(np.min(data)),
            "max": float(np.max(data)),
            "mean": float(np.mean(data))
        }
    }

@router.get("/pressure/{time_idx}")
async def get_pressure_field(time_idx: int):
    """Get spatial pressure (psi) field for a specific time index"""
    project = get_project_or_404()
    if not hasattr(project, 'results') or not project.results:
        raise HTTPException(status_code=404, detail="No simulation results found")
        
    if time_idx not in project.results.pressure_fields:
        raise HTTPException(status_code=404, detail=f"Time index {time_idx} not found")
        
    data = project.results.pressure_fields[time_idx]
    return {
        "time_index": time_idx,
        "data": numpy_to_list(data),
        "stats": {
            "min": float(np.min(data)),
            "max": float(np.max(data)),
            "mean": float(np.mean(data))
        }
    }

@router.get("/compare/{time1}/{time2}")
async def compare_timesteps(time1: int, time2: int):
    """Compare moisture fields between two timesteps"""
    project = get_project_or_404()
    if not hasattr(project, 'results') or not project.results:
        raise HTTPException(status_code=404, detail="No simulation results found")
    
    if time1 not in project.results.moisture_fields or time2 not in project.results.moisture_fields:
        raise HTTPException(status_code=404, detail="One or more time indices not found")
        
    field1 = project.results.moisture_fields[time1]
    field2 = project.results.moisture_fields[time2]
    
    diff = field2 - field1
    
    return {
        "time_start": time1,
        "time_end": time2,
        "difference_matrix": numpy_to_list(diff),
        "stats": {
            "max_change": float(np.max(np.abs(diff))),
            "mean_change": float(np.mean(diff))
        }
    }

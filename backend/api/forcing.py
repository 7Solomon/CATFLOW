from fastapi import HTTPException, APIRouter
from typing import List
from pathlib import Path
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


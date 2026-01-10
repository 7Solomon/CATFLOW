from pydantic import BaseModel
from typing import List, Dict, Optional

class ProjectLoadRequest(BaseModel):
    path: str
    
class ProjectSummary(BaseModel):
    name: str
    n_hills: int
    has_soil_library: bool
    has_forcing: bool
    has_land_use: bool
    has_wind: bool
    simulation_start: Optional[str]
    simulation_end: Optional[str]
    method: Optional[str]


class SoilTypeDTO(BaseModel):
    id: int
    name: str
    ks: float
    theta_s: float
    theta_r: float
    alpha: float
    n_param: float
    model_id: int


class HillSummary(BaseModel):
    id: int
    name: str
    n_layers: int
    n_columns: int
    total_nodes: int
    has_soil_map: bool
    has_surface_map: bool
    has_macropores: bool
    has_boundary: bool
    has_initial_cond: bool
    unique_soil_ids: List[int]


class MeshCoordinates(BaseModel):
    x_coords: List[List[float]]
    z_coords: List[List[float]]
    n_layers: int
    n_columns: int


class SoilMapData(BaseModel):
    matrix: List[List[int]]
    unique_ids: List[int]
    n_layers: int
    n_columns: int


class InitialConditionData(BaseModel):
    values: List[List[float]]
    type_id: str
    n_layers: int
    n_columns: int
    min_value: float
    max_value: float


class ForcingOverview(BaseModel):
    n_precip_files: int
    n_climate_files: int
    has_landuse_timeline: bool
    precip_filenames: List[str]
    climate_filenames: List[str]


class WritePreview(BaseModel):
    """Preview of what will be written to disk"""
    target_folder: str
    files_to_create: Dict[str, List[str]]  # {category: [file paths]}
    total_files: int
    warnings: List[str]


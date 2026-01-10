export interface ProjectSummary {
    name: string;
    n_hills: number;
    simulation_start: string | null;
    simulation_end: string | null;
    method: string | null;
}

export interface SoilType {
    id: number;
    name: string;
    ks: number;
    theta_s: number;
    theta_r: number;
    alpha: number;
    n_param: number;
}

export interface Hill {
    id: number;
    name: string;
    n_layers: number;
    n_columns: number;
    total_nodes: number;
    has_soil_map: boolean;
    has_surface_map: boolean;
    has_macropores: boolean;
    has_boundary: boolean;
    has_initial_cond: boolean;
    unique_soil_ids: number[];
}



export interface ForcingOverview {
    n_precip_files: number;
    n_climate_files: number;
    precip_filenames: string[];
    climate_filenames: string[];
    has_landuse_timeline: boolean;
}


export interface FullProjectData {
    summary: ProjectSummary;
    config: {
        timing: any;
        solver: SolverConfig;
        location: any;
    };
    soils: SoilType[];
    hills: Hill[];
    forcing: ForcingOverview;
    wind?: WindConfig;
    landuse?: LandUseConfig;
}

export interface WindConfig {
    n_sectors: number;
    sectors: { angle: number; factor: number }[];
}

export interface LandUseType {
    id: number;
    name: string;
    has_params: boolean;
}

export interface LandUseConfig {
    types: LandUseType[];
}

export interface SolverConfig {
    method: string;
    it_max: number;
    piceps: number;
    cgeps: number;
    d_th_opt: number;
    d_phi_opt: number;
    n_gr: number;
}



export interface ValidationResult {
    valid: boolean;
    issues: { type: 'error' | 'warning'; message: string }[];
}


export interface WindSector {
    id: number;
    angle_start: number;
    angle_end: number;
    exposure_factor: number;
    description: string;
}

export interface ClimateData {
    filename: string;
    header_date: string;
    n_records: number;
}

export interface LandUsePeriod {
    time: number;
    lookup_file: string;
}

export interface HydraulicCurve {
    psi: number[];
    theta: number[];
    metadata: { model: string; params: any };
}

export interface WaterBalance {
    columns: string[];
    index: any[];
    data: number[][];
}
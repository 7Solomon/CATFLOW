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
    config: any; // Define fully if needed
    soils: SoilType[];
    hills: Hill[];
    forcing: ForcingOverview;
}

import type { FullProjectData } from '../types';

const API_BASE = '/api';

export const projectApi = {
    load: async (folderPath: string) => {
        const res = await fetch(`${API_BASE}/project/load`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ path: folderPath })
        });
        if (!res.ok) throw new Error('Failed to load project');
        return res.json();
    },

    fetchAllData: async (): Promise<FullProjectData> => {
        const [summary, config, soils, hills, forcing] = await Promise.all([
            fetch(`${API_BASE}/project/summary`).then(r => r.json()),
            fetch(`${API_BASE}/project/config`).then(r => r.json()),
            fetch(`${API_BASE}/soil/library`).then(r => r.json()),
            fetch(`${API_BASE}/hills`).then(r => r.json()),
            fetch(`${API_BASE}/forcing/overview`).then(r => r.json())
        ]);
        return { summary, config, soils, hills, forcing };
    },

    fetchValidation: async () => {
        const res = await fetch(`${API_BASE}/project/validation`);
        return res.json();
    },

    fetchDimensions: async () => {
        const res = await fetch(`${API_BASE}/project/dimensions`);
        return res.json();
    },

    fetchWindLibrary: async () => {
        const res = await fetch(`${API_BASE}/wind/library`);
        return res.json();
    },

    fetchLandUseTimeline: async () => {
        const res = await fetch(`${API_BASE}/forcing/landuse/timeline`);
        return res.json();
    },
    fetchLandUseLibrary: async () => {
        const res = await fetch(`${API_BASE}/forcing/landuse/library`);
        return res.json();
    },

    fetchLandUseType: async (id: number) => {
        const res = await fetch(`${API_BASE}/forcing/landuse/type/${id}`);
        return res.json();
    },

    fetchHillMap: async (hillId: number, mapType: 'mesh' | 'soil-map' | 'surface-map' | 'boundary' | 'macropores') => {
        const res = await fetch(`${API_BASE}/hills/${hillId}/${mapType}`);
        return res.json();
    },


    fetchSoilCurve: async (soilId: number) => {
        const res = await fetch(`${API_BASE}/soil/${soilId}/curves`);
        return res.json();
    },

    fetchResultsAvailability: async () => {
        const res = await fetch(`${API_BASE}/results/available`);
        return res.json();
    },

    fetchWaterBalance: async () => {
        const res = await fetch(`${API_BASE}/results/balance`);
        return res.json();
    },

    previewExport: async (target: string) => {
        const res = await fetch(`${API_BASE}/export/preview?target_folder=${target}`, {
            method: 'POST'
        });
        return res.json();
    }
};

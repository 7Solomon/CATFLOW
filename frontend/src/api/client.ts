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

    previewExport: async (target: string) => {
        const res = await fetch(`${API_BASE}/export/preview?target_folder=${target}`, {
            method: 'POST'
        });
        return res.json();
    }
};

import { useState } from 'react';
import { projectApi } from '../api/client';
import type { FullProjectData } from '../types';

export const useProject = () => {
    const [data, setData] = useState<FullProjectData | null>(null);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState<string | null>(null);

    const loadProject = async (path: string) => {
        setLoading(true);
        setError(null);
        try {
            await projectApi.load(path); // 1. Tell backend to load
            const allData = await projectApi.fetchAllData(); // 2. Fetch fresh state
            setData(allData);
        } catch (err: any) {
            setError(err.message || 'Unknown error');
        } finally {
            setLoading(false);
        }
    };

    return { data, loading, error, loadProject };
};

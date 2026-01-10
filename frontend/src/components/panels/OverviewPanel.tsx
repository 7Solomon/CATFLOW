import { useEffect, useState } from 'react';
import { Activity, AlertTriangle, CheckCircle, Maximize } from 'lucide-react';
import { projectApi } from '../../api/client';
import type { FullProjectData, ValidationResult } from '../../types';

export const OverviewPanel = ({ project }: { project: FullProjectData }) => {
    const [validation, setValidation] = useState<ValidationResult | null>(null);
    const [dimensions, setDimensions] = useState<any>(null);

    useEffect(() => {
        projectApi.fetchValidation().then(setValidation);
        projectApi.fetchDimensions().then(setDimensions);
    }, [project]);

    return (
        <div className="space-y-6">
            {/* Existing Stats Cards */}
            {/* ... */}

            {/* Health Check Section */}
            <div className="bg-slate-800/50 p-6 rounded-xl border border-slate-700">
                <h3 className="text-lg font-semibold text-slate-100 flex items-center gap-2 mb-4">
                    <Activity className="text-indigo-400" size={20} />
                    Project Health
                </h3>

                {validation ? (
                    <div className="space-y-3">
                        <div className={`flex items-center gap-3 p-3 rounded-lg ${validation.valid ? 'bg-green-500/10 text-green-400' : 'bg-amber-500/10 text-amber-400'}`}>
                            {validation.valid ? <CheckCircle size={20} /> : <AlertTriangle size={20} />}
                            <span className="font-medium">{validation.valid ? "Configuration Valid" : "Issues Detected"}</span>
                        </div>
                        {validation.issues.map((issue, i) => (
                            <div key={i} className="text-sm text-slate-400 ml-8 list-disc">
                                • {issue.message}
                            </div>
                        ))}
                    </div>
                ) : (
                    <div className="text-slate-500">Running validation...</div>
                )}
            </div>

            {/* Global Dimensions */}
            {dimensions && (
                <div className="bg-slate-800/50 p-6 rounded-xl border border-slate-700">
                    <h3 className="text-lg font-semibold text-slate-100 flex items-center gap-2 mb-4">
                        <Maximize className="text-cyan-400" size={20} />
                        Global Mesh Dimensions
                    </h3>
                    <div className="grid grid-cols-2 gap-4">
                        <div className="p-3 bg-slate-900/50 rounded-lg">
                            <div className="text-slate-400 text-xs uppercase">Total Nodes</div>
                            <div className="text-2xl font-mono text-white">{dimensions.total_nodes.toLocaleString()}</div>
                        </div>
                        <div className="p-3 bg-slate-900/50 rounded-lg">
                            <div className="text-slate-400 text-xs uppercase">Simulated Hills</div>
                            <div className="text-2xl font-mono text-white">{dimensions.n_hills}</div>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
};

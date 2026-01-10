import { useState } from 'react';
import type { Hill } from '../../types';

export const HillsPanel = ({ hills }: { hills: Hill[] }) => {
    const [selectedHillId, setSelectedHillId] = useState<number | null>(hills[0]?.id || null);
    const selectedHill = hills.find(h => h.id === selectedHillId);

    return (
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
            {/* List */}
            <div className="bg-slate-800/50 backdrop-blur-sm rounded-xl p-6 border border-slate-700">
                <h3 className="text-xl font-semibold mb-4">Hills</h3>
                <div className="space-y-2">
                    {hills.map(hill => (
                        <button
                            key={hill.id}
                            onClick={() => setSelectedHillId(hill.id)}
                            className={`w-full p-4 rounded-lg text-left transition-all ${selectedHillId === hill.id
                                ? 'bg-gradient-to-r from-blue-500 to-cyan-500 shadow-lg text-white'
                                : 'bg-slate-700/50 hover:bg-slate-600/50 text-slate-300'
                                }`}
                        >
                            <div className="font-semibold">{hill.name}</div>
                            <div className="text-sm opacity-80">{hill.n_layers} × {hill.n_columns} nodes</div>
                        </button>
                    ))}
                </div>
            </div>

            {/* Details */}
            {selectedHill && (
                <div className="lg:col-span-2 bg-slate-800/50 backdrop-blur-sm rounded-xl p-6 border border-slate-700">
                    <h3 className="text-xl font-semibold mb-4">Hill {selectedHill.name} Details</h3>
                    <div className="grid grid-cols-2 gap-4 text-sm text-slate-300">
                        <div>Total Nodes: <span className="font-mono text-white">{selectedHill.total_nodes}</span></div>
                        <div>Dimensions: <span className="font-mono text-white">{selectedHill.n_layers} rows × {selectedHill.n_columns} cols</span></div>
                        <div>Soil Maps: <span className="font-mono text-white">{selectedHill.has_soil_map ? 'Yes' : 'No'}</span></div>
                    </div>
                    {/* You can add the Mesh/Heatmap visualization here later */}
                </div>
            )}
        </div>
    );
};

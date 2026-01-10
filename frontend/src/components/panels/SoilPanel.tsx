import { useState } from 'react';
import { ChevronDown, ChevronRight } from 'lucide-react';
import type { SoilType } from '../../types';
import { projectApi } from '../../api/client';

export const SoilPanel = ({ soils }: { soils: SoilType[] }) => {
    const [expandedSoil, setExpandedSoil] = useState<number | null>(null);

    return (
        <div className="space-y-4">
            <div className="bg-slate-800/50 backdrop-blur-sm rounded-xl p-6 border border-slate-700">
                <h3 className="text-xl font-semibold mb-4">Soil Library ({soils.length} types)</h3>
                <div className="space-y-3">
                    {soils.map(soil => (
                        <div key={soil.id} className="bg-slate-700/50 rounded-lg overflow-hidden">
                            <button
                                onClick={() => setExpandedSoil(expandedSoil === soil.id ? null : soil.id)}
                                className="w-full p-4 flex items-center justify-between hover:bg-slate-600/50 transition-colors"
                            >
                                <div className="flex items-center gap-4">
                                    <div className="w-12 h-12 rounded-lg bg-gradient-to-br from-amber-500 to-orange-600 flex items-center justify-center font-bold text-white">
                                        {soil.id}
                                    </div>
                                    <div className="text-left">
                                        <div className="font-semibold">{soil.name}</div>
                                        <div className="text-sm text-slate-400">K<sub>sat</sub>: {soil.ks.toExponential(2)} m/s</div>
                                    </div>
                                </div>
                                {expandedSoil === soil.id ? <ChevronDown className="w-5 h-5" /> : <ChevronRight className="w-5 h-5" />}
                            </button>

                            {expandedSoil === soil.id && (
                                <div className="mt-4 p-4 bg-slate-900/50 rounded-lg">
                                    <div className="p-4 border-t border-slate-600 grid grid-cols-2 gap-3 text-sm text-slate-300">
                                        <div>θ<sub>s</sub>: <span className="font-mono text-white">{soil.theta_s.toFixed(3)}</span></div>
                                        <div>θ<sub>r</sub>: <span className="font-mono text-white">{soil.theta_r.toFixed(3)}</span></div>
                                        <div>α: <span className="font-mono text-white">{soil.alpha.toFixed(4)}</span></div>
                                        <div>n: <span className="font-mono text-white">{soil.n_param.toFixed(3)}</span></div>
                                    </div>

                                    <div className="mt-4 border-t border-slate-700 pt-4">
                                        <button
                                            className="text-xs bg-indigo-500/20 text-indigo-400 px-3 py-1 rounded hover:bg-indigo-500/30 transition-colors"
                                            onClick={async (e) => {
                                                e.stopPropagation();
                                                const curve = await projectApi.fetchSoilCurve(soil.id);
                                                console.log("Curve Data:", curve);
                                                alert(`Fetched ${curve.theta.length} points for ${soil.name}`);
                                            }}
                                        >
                                            Generate Hydraulic Curve
                                        </button>
                                    </div>
                                </div>
                            )}
                        </div>
                    ))}
                </div>
            </div>
        </div >
    );
};

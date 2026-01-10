import { useState, useEffect } from 'react';
import { CloudRain, Sun, Wind, Layers } from 'lucide-react';
import { projectApi } from '../../api/client';

export const ForcingPanel = ({ forcing }: { forcing: any }) => {
    const [activeTab, setActiveTab] = useState<'precip' | 'climate' | 'landuse' | 'wind'>('precip');
    const [windData, setWindData] = useState<any[]>([]);
    const [timeline, setTimeline] = useState<any>(null);

    useEffect(() => {
        if (activeTab === 'wind' && !windData.length) {
            projectApi.fetchWindLibrary().then(setWindData);
        }
        if (activeTab === 'landuse' && !timeline) {
            projectApi.fetchLandUseTimeline().then(setTimeline);
        }
    }, [activeTab]);

    return (
        <div className="h-full flex flex-col">
            {/* Tabs */}
            <div className="flex border-b border-slate-700 mb-4">
                {[
                    { id: 'precip', label: 'Precipitation', icon: CloudRain },
                    { id: 'climate', label: 'Climate', icon: Sun },
                    { id: 'landuse', label: 'Land Use', icon: Layers },
                    { id: 'wind', label: 'Wind', icon: Wind },
                ].map(tab => (
                    <button
                        key={tab.id}
                        onClick={() => setActiveTab(tab.id as any)}
                        className={`flex items-center gap-2 px-4 py-2 border-b-2 transition-colors ${activeTab === tab.id
                                ? 'border-indigo-500 text-indigo-400'
                                : 'border-transparent text-slate-400 hover:text-slate-200'
                            }`}
                    >
                        <tab.icon size={16} />
                        {tab.label}
                    </button>
                ))}
            </div>

            <div className="flex-1 overflow-auto">
                {activeTab === 'precip' && (
                    <div className="space-y-2">
                        {forcing.precip_filenames.map((f: string, i: number) => (
                            <div key={i} className="p-3 bg-slate-800 rounded flex justify-between">
                                <span>{f}</span>
                                <span className="text-xs text-slate-500 bg-slate-900 px-2 py-1 rounded">Index {i}</span>
                            </div>
                        ))}
                    </div>
                )}

                {activeTab === 'landuse' && timeline && (
                    <div className="space-y-4">
                        <h3 className="text-slate-300 font-medium">Timeline Periods</h3>
                        {timeline.periods.map((p: any, i: number) => (
                            <div key={i} className="flex items-center gap-4 p-3 bg-slate-800/50 rounded border border-slate-700">
                                <div className="w-24 text-right font-mono text-indigo-400">{p.time}s</div>
                                <div className="h-px bg-slate-600 flex-1"></div>
                                <div className="text-slate-300">{p.lookup_file}</div>
                            </div>
                        ))}
                    </div>
                )}

                {activeTab === 'wind' && (
                    <div className="grid grid-cols-2 gap-4">
                        {windData.map((sector: any) => (
                            <div key={sector.id} className="p-4 bg-slate-800 rounded border border-slate-700">
                                <div className="text-lg font-bold text-white mb-1">Sector {sector.id}</div>
                                <div className="text-sm text-slate-400 mb-2">{sector.angle_start}° - {sector.angle_end}°</div>
                                <div className="text-xs uppercase tracking-wider text-slate-500">Exposure Factor</div>
                                <div className="text-xl text-indigo-400">{sector.exposure_factor}</div>
                            </div>
                        ))}
                    </div>
                )}
            </div>
        </div>
    );
};

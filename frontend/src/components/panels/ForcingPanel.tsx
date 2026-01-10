import { useState, useEffect } from 'react';
import { CloudRain, Sun, Wind, Layers, ChevronDown, ChevronRight, FileText } from 'lucide-react';
import { projectApi } from '../../api/client';

export const ForcingPanel = ({ forcing }: { forcing: any }) => {
    const [activeTab, setActiveTab] = useState<'precip' | 'climate' | 'landuse' | 'wind'>('precip');
    const [windData, setWindData] = useState<any[]>([]);
    const [timeline, setTimeline] = useState<any>(null);
    const [landUseTypes, setLandUseTypes] = useState<any[]>([]);
    const [selectedType, setSelectedType] = useState<number | null>(null);
    const [typeDetails, setTypeDetails] = useState<any>(null);

    useEffect(() => {
        if (activeTab === 'wind' && !windData.length) {
            projectApi.fetchWindLibrary().then(setWindData);
        }
        if (activeTab === 'landuse') {
            if (!timeline) projectApi.fetchLandUseTimeline().then(setTimeline);
            if (!landUseTypes.length) projectApi.fetchLandUseLibrary().then(setLandUseTypes);
        }
    }, [activeTab]);

    // Fetch details when a specific land use type is expanded
    useEffect(() => {
        if (selectedType !== null) {
            projectApi.fetchLandUseType(selectedType).then(setTypeDetails);
        }
    }, [selectedType]);

    return (
        <div className="h-full flex flex-col">
            {/* Tabs */}
            <div className="flex border-b border-slate-700 mb-4 bg-slate-900/50">
                {[
                    { id: 'precip', label: 'Precipitation', icon: CloudRain },
                    { id: 'climate', label: 'Climate', icon: Sun },
                    { id: 'landuse', label: 'Land Use', icon: Layers },
                    { id: 'wind', label: 'Wind', icon: Wind },
                ].map(tab => (
                    <button
                        key={tab.id}
                        onClick={() => setActiveTab(tab.id as any)}
                        className={`flex items-center gap-2 px-4 py-3 border-b-2 transition-colors ${activeTab === tab.id
                                ? 'border-indigo-500 text-indigo-400 bg-slate-800/50'
                                : 'border-transparent text-slate-400 hover:text-slate-200 hover:bg-slate-800/30'
                            }`}
                    >
                        <tab.icon size={16} />
                        {tab.label}
                    </button>
                ))}
            </div>

            <div className="flex-1 overflow-auto px-1">

                {/* === LAND USE TAB === */}
                {activeTab === 'landuse' && (
                    <div className="space-y-6">

                        {/* Timeline Section */}
                        {timeline && (
                            <div className="space-y-3">
                                <h3 className="text-slate-300 font-medium flex items-center gap-2">
                                    <Clock size={16} /> Simulation Timeline
                                </h3>
                                <div className="bg-slate-800 rounded-lg overflow-hidden border border-slate-700">
                                    {timeline.periods.map((p: any, i: number) => (
                                        <div key={i} className="flex items-center p-3 border-b border-slate-700 last:border-0 hover:bg-slate-700/30 transition-colors">
                                            <div className="w-24 font-mono text-indigo-400 font-bold">{p.start_time}</div>
                                            <div className="flex-1">
                                                <div className="text-sm text-slate-300">{p.lookup_file}</div>
                                                <div className="text-xs text-slate-500">
                                                    {Object.keys(p.mappings).length} active mappings
                                                </div>
                                            </div>
                                        </div>
                                    ))}
                                    {timeline.end_time && (
                                        <div className="p-3 bg-slate-900/50 text-slate-500 text-sm flex items-center gap-2">
                                            <span className="w-24 font-mono">END</span>
                                            <span>{timeline.end_time}</span>
                                        </div>
                                    )}
                                </div>
                            </div>
                        )}

                        {/* Library Section */}
                        <div>
                            <h3 className="text-slate-300 font-medium mb-3 flex items-center gap-2">
                                <FileText size={16} /> Plant Library
                            </h3>
                            <div className="space-y-2">
                                {landUseTypes.map(type => (
                                    <div key={type.id} className="bg-slate-800 rounded-lg border border-slate-700 overflow-hidden">
                                        <button
                                            onClick={() => setSelectedType(selectedType === type.id ? null : type.id)}
                                            className="w-full flex items-center justify-between p-3 hover:bg-slate-700/50 transition-colors text-left"
                                        >
                                            <div className="flex items-center gap-3">
                                                {selectedType === type.id ? <ChevronDown size={16} /> : <ChevronRight size={16} />}
                                                <span className="font-mono text-indigo-400 w-8">{type.id}</span>
                                                <span className="text-slate-200">{type.name}</span>
                                            </div>
                                            {type.has_definition && (
                                                <span className="text-xs bg-emerald-500/10 text-emerald-400 px-2 py-1 rounded">
                                                    Defined
                                                </span>
                                            )}
                                        </button>

                                        {/* Detailed Parameter Table */}
                                        {selectedType === type.id && typeDetails?.definition && (
                                            <div className="p-4 bg-slate-900/50 border-t border-slate-700 overflow-x-auto">
                                                <div className="text-xs text-slate-400 mb-2">
                                                    File: {typeDetails.definition.filename}
                                                </div>
                                                <table className="w-full text-xs text-right">
                                                    <thead className="text-slate-500 font-mono bg-slate-800">
                                                        <tr>
                                                            <th className="p-2 text-left">Day</th>
                                                            {typeDetails.definition.headers.map((h: string) => (
                                                                <th key={h} className="p-2">{h}</th>
                                                            ))}
                                                        </tr>
                                                    </thead>
                                                    <tbody className="font-mono text-slate-300">
                                                        {typeDetails.definition.table.map((row: any, idx: number) => (
                                                            <tr key={idx} className="border-b border-slate-800 hover:bg-slate-800/30">
                                                                <td className="p-2 text-left text-indigo-300">{row.day}</td>
                                                                {row.values.map((v: number, vIdx: number) => (
                                                                    <td key={vIdx} className="p-2">{v.toFixed(3)}</td>
                                                                ))}
                                                            </tr>
                                                        ))}
                                                    </tbody>
                                                </table>
                                            </div>
                                        )}
                                    </div>
                                ))}
                            </div>
                        </div>
                    </div>
                )}

                {/* === WIND TAB === */}
                {activeTab === 'wind' && (
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                        {windData.map((sector: any, i: number) => (
                            <div key={i} className="p-4 bg-slate-800 rounded-lg border border-slate-700 relative overflow-hidden group hover:border-indigo-500/50 transition-colors">
                                <div className="absolute top-0 right-0 p-4 opacity-10 group-hover:opacity-20 transition-opacity">
                                    <Wind size={64} />
                                </div>
                                <div className="text-xs uppercase text-slate-500 font-bold mb-1">
                                    Sector {i + 1}
                                </div>
                                <div className="text-2xl text-white font-light mb-4">
                                    {sector.angle_start}° <span className="text-slate-600">to</span> {sector.angle_end}°
                                </div>
                                <div className="flex items-center justify-between bg-slate-900/50 p-3 rounded">
                                    <span className="text-sm text-slate-400">Exposure Factor</span>
                                    <span className="text-lg font-mono text-indigo-400">{sector.exposure_factor.toFixed(2)}</span>
                                </div>
                            </div>
                        ))}
                    </div>
                )}

                {/* Existing Precip/Climate Placeholders */}
                {activeTab === 'precip' && (
                    <div className="text-slate-400 p-4">Select a precipitation file to preview...</div>
                )}
                {activeTab === 'climate' && (
                    <div className="text-slate-400 p-4">Select a climate file to preview...</div>
                )}
            </div>
        </div>
    );
};

// Add this import if missing
import { Clock } from 'lucide-react';

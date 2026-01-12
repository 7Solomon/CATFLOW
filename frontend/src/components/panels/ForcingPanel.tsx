import { useState, useEffect } from 'react';
import { CloudRain, Sun, Wind, Layers, ChevronDown, ChevronRight, FileText, BarChart3, Clock, Loader2 } from 'lucide-react';
import { projectApi } from '../../api/client';

// Simple table component for previewing time series data
const TimeSeriesPreview = ({ data, type }: { data: any, type: 'precip' | 'climate' }) => {
    if (!data) return null;

    // Define headers based on data type
    const headers = type === 'precip'
        ? ['Time (s)', 'Intensity (m/s)']
        : ['Time (s)', 'Rad', 'NetRad', 'Temp', 'Hum', 'WindV', 'WindDir'];

    return (
        <div className="bg-slate-900 rounded-lg border border-slate-700 overflow-hidden flex flex-col h-full max-h-[600px]">
            <div className="p-3 bg-slate-800 border-b border-slate-700 flex justify-between items-center shrink-0">
                <div className="flex flex-col">
                    <span className="font-mono text-sm text-indigo-300">{data.filename}</span>
                    <span className="text-xs text-slate-500 font-mono mt-0.5">Ref: {data.header_date}</span>
                </div>
                <span className="text-xs bg-slate-700 px-2 py-1 rounded text-slate-300 font-mono">
                    {data.n_records.toLocaleString()} records
                </span>
            </div>

            <div className="overflow-auto flex-1 custom-scrollbar">
                <table className="w-full text-xs text-right font-mono relative border-collapse">
                    <thead className="bg-slate-800 text-slate-500 sticky top-0 z-10 shadow-sm">
                        <tr>
                            {headers.map((h, i) => (
                                <th key={i} className="p-3 font-medium bg-slate-800 border-b border-slate-700">
                                    {h}
                                </th>
                            ))}
                        </tr>
                    </thead>
                    <tbody className="text-slate-300">
                        {data.data_preview.map((row: number[], i: number) => (
                            <tr key={i} className="border-b border-slate-800/50 hover:bg-slate-800/50 transition-colors">
                                {row.map((val: number, j: number) => (
                                    <td key={j} className="p-2 border-r border-slate-800/30 last:border-0">
                                        {val.toExponential(4)}
                                    </td>
                                ))}
                            </tr>
                        ))}
                    </tbody>
                </table>

                {data.n_records > 100 && (
                    <div className="p-3 text-center text-xs text-slate-500 bg-slate-900/80 sticky bottom-0 border-t border-slate-800 backdrop-blur-sm">
                        ... and {data.n_records - 100} more records ...
                    </div>
                )}
            </div>
        </div>
    );
};

export const ForcingPanel = ({ forcing }: { forcing: any }) => {
    const [activeTab, setActiveTab] = useState<'precip' | 'climate' | 'landuse' | 'wind'>('precip');

    // --- State: Land Use & Wind ---
    const [windData, setWindData] = useState<any[]>([]);
    const [timeline, setTimeline] = useState<any>(null);
    const [landUseTypes, setLandUseTypes] = useState<any[]>([]);
    const [selectedType, setSelectedType] = useState<number | null>(null);
    const [typeDetails, setTypeDetails] = useState<any>(null);

    // --- State: Precip & Climate ---
    const [selectedFileIndex, setSelectedFileIndex] = useState<number | null>(null);
    const [fileData, setFileData] = useState<any>(null);
    const [loadingFile, setLoadingFile] = useState(false);

    // Reset selection when tab changes
    useEffect(() => {
        setSelectedFileIndex(null);
        setFileData(null);
        setLoadingFile(false);
    }, [activeTab]);

    // Data Fetching for Wind/LandUse (Lazy load on tab switch)
    useEffect(() => {
        if (activeTab === 'wind' && !windData.length) {
            projectApi.fetchWindLibrary().then(setWindData).catch(console.error);
        }
        if (activeTab === 'landuse') {
            if (!timeline) projectApi.fetchLandUseTimeline().then(setTimeline).catch(console.error);
            if (!landUseTypes.length) projectApi.fetchLandUseLibrary().then(setLandUseTypes).catch(console.error);
        }
    }, [activeTab]);

    // Fetch details when a specific land use type is expanded
    useEffect(() => {
        if (selectedType !== null) {
            projectApi.fetchLandUseType(selectedType).then(setTypeDetails).catch(console.error);
        }
    }, [selectedType]);

    // Handler for Precip/Climate File Selection
    const handleFileSelect = async (index: number) => {
        if (selectedFileIndex === index && fileData) return; // Don't refetch if already selected

        setSelectedFileIndex(index);
        setLoadingFile(true);
        try {
            let data;
            if (activeTab === 'precip') {
                data = await projectApi.fetchPrecipitation(index);
            } else if (activeTab === 'climate') {
                data = await projectApi.fetchClimate(index);
            }
            setFileData(data);
        } catch (err) {
            console.error("Failed to fetch file data:", err);
            setFileData(null);
        } finally {
            setLoadingFile(false);
        }
    };

    return (
        <div className="h-full flex flex-col">
            {/* Tabs Header */}
            <div className="flex border-b border-slate-700 mb-6 bg-slate-900/50 rounded-t-lg">
                {[
                    { id: 'precip', label: 'Precipitation', icon: CloudRain },
                    { id: 'climate', label: 'Climate', icon: Sun },
                    { id: 'landuse', label: 'Land Use', icon: Layers },
                    { id: 'wind', label: 'Wind', icon: Wind },
                ].map(tab => (
                    <button
                        key={tab.id}
                        onClick={() => setActiveTab(tab.id as any)}
                        className={`flex items-center gap-2 px-6 py-4 border-b-2 transition-all font-medium ${activeTab === tab.id
                                ? 'border-indigo-500 text-indigo-400 bg-slate-800/50'
                                : 'border-transparent text-slate-400 hover:text-slate-200 hover:bg-slate-800/30'
                            }`}
                    >
                        <tab.icon size={18} />
                        {tab.label}
                    </button>
                ))}
            </div>

            <div className="flex-1 overflow-hidden px-1">

                {/* === PRECIPITATION & CLIMATE TABS === */}
                {(activeTab === 'precip' || activeTab === 'climate') && (
                    <div className="grid grid-cols-12 gap-6 h-full pb-2">
                        {/* Sidebar: File List */}
                        <div className="col-span-3 border-r border-slate-700 pr-4 space-y-3 overflow-y-auto">
                            <h3 className="text-xs font-bold text-slate-500 uppercase tracking-wider mb-2 px-2">
                                Available Files
                            </h3>

                            {(activeTab === 'precip' ? forcing.precip_filenames : forcing.climate_filenames).map((fname: string, idx: number) => (
                                <button
                                    key={idx}
                                    onClick={() => handleFileSelect(idx)}
                                    className={`w-full text-left p-3 rounded-lg border transition-all flex items-center justify-between group ${selectedFileIndex === idx
                                            ? 'bg-indigo-600 border-indigo-500 text-white shadow-lg ring-1 ring-indigo-400'
                                            : 'bg-slate-800 border-slate-700 text-slate-300 hover:border-slate-500 hover:bg-slate-700'
                                        }`}
                                >
                                    <div className="flex items-center gap-3 overflow-hidden">
                                        <FileText size={16} className={selectedFileIndex === idx ? 'text-indigo-200' : 'text-slate-500'} />
                                        <span className="font-mono text-xs truncate" title={fname}>{fname}</span>
                                    </div>
                                    {selectedFileIndex === idx && <ChevronRight size={14} className="shrink-0" />}
                                </button>
                            ))}

                            {(activeTab === 'precip' ? forcing.precip_filenames : forcing.climate_filenames).length === 0 && (
                                <div className="text-slate-500 text-sm italic p-4 text-center border border-dashed border-slate-800 rounded-lg">
                                    No files loaded.
                                </div>
                            )}
                        </div>

                        {/* Main Content: Preview Area */}
                        <div className="col-span-9 h-full overflow-hidden flex flex-col">
                            {loadingFile ? (
                                <div className="flex flex-col items-center justify-center h-full text-slate-500 gap-3">
                                    <Loader2 className="animate-spin text-indigo-500" size={32} />
                                    <span>Loading data...</span>
                                </div>
                            ) : fileData ? (
                                <div className="flex flex-col h-full animate-in fade-in duration-300">
                                    <div className="flex items-center justify-between mb-4 shrink-0">
                                        <h3 className="text-xl font-light text-white flex items-center gap-2">
                                            <BarChart3 className="text-indigo-400" />
                                            Data Preview
                                        </h3>
                                        <div className="flex gap-2">
                                            {fileData.factor_t && (
                                                <div className="text-xs font-mono bg-slate-800 border border-slate-700 px-2 py-1 rounded text-slate-400">
                                                    Factor T: {fileData.factor_t}
                                                </div>
                                            )}
                                        </div>
                                    </div>
                                    <div className="flex-1 overflow-hidden">
                                        <TimeSeriesPreview data={fileData} type={activeTab} />
                                    </div>
                                </div>
                            ) : (
                                <div className="flex flex-col items-center justify-center h-full text-slate-600 border-2 border-dashed border-slate-800 rounded-xl bg-slate-900/30">
                                    {activeTab === 'precip' ? (
                                        <CloudRain size={64} className="mb-4 opacity-20" />
                                    ) : (
                                        <Sun size={64} className="mb-4 opacity-20" />
                                    )}
                                    <p className="text-lg font-medium">Select a file to view data</p>
                                    <p className="text-sm text-slate-500">Choose from the list on the left</p>
                                </div>
                            )}
                        </div>
                    </div>
                )}

                {/* === LAND USE TAB === */}
                {activeTab === 'landuse' && (
                    <div className="space-y-8 overflow-y-auto h-full pr-2">
                        {/* Timeline Section */}
                        {timeline && (
                            <div className="space-y-4">
                                <h3 className="text-slate-300 font-medium flex items-center gap-2 border-b border-slate-800 pb-2">
                                    <Clock size={18} className="text-indigo-400" /> Simulation Timeline
                                </h3>
                                <div className="bg-slate-800 rounded-lg overflow-hidden border border-slate-700 shadow-sm">
                                    {timeline.periods.map((p: any, i: number) => (
                                        <div key={i} className="flex items-center p-4 border-b border-slate-700 last:border-0 hover:bg-slate-700/30 transition-colors group">
                                            <div className="w-32 font-mono text-indigo-400 font-bold border-r border-slate-700 mr-4 pr-4 text-right">
                                                {p.start_time.toExponential ? p.start_time.toExponential(2) : p.start_time} s
                                            </div>
                                            <div className="flex-1">
                                                <div className="text-sm text-slate-200 font-medium mb-1 flex items-center gap-2">
                                                    <FileText size={14} className="text-slate-500" />
                                                    {p.lookup_file}
                                                </div>
                                                <div className="text-xs text-slate-500 flex gap-4">
                                                    <span>{Object.keys(p.mappings).length} active mappings</span>
                                                    <span className="text-slate-600">|</span>
                                                    <span>Column Index: {p.column_idx}</span>
                                                </div>
                                            </div>
                                        </div>
                                    ))}
                                    {timeline.end_time && (
                                        <div className="p-3 bg-slate-900/50 text-slate-500 text-sm flex items-center gap-4">
                                            <span className="w-32 text-right font-mono pr-4 border-r border-slate-800">END</span>
                                            <span className="font-mono">{timeline.end_time} s</span>
                                        </div>
                                    )}
                                </div>
                            </div>
                        )}

                        {/* Library Section */}
                        <div>
                            <h3 className="text-slate-300 font-medium mb-4 flex items-center gap-2 border-b border-slate-800 pb-2">
                                <Layers size={18} className="text-indigo-400" /> Plant Library
                            </h3>
                            <div className="space-y-2">
                                {landUseTypes.map(type => (
                                    <div key={type.id} className="bg-slate-800 rounded-lg border border-slate-700 overflow-hidden transition-all duration-200 hover:border-slate-600">
                                        <button
                                            onClick={() => setSelectedType(selectedType === type.id ? null : type.id)}
                                            className="w-full flex items-center justify-between p-3 hover:bg-slate-700/50 transition-colors text-left"
                                        >
                                            <div className="flex items-center gap-4">
                                                {selectedType === type.id
                                                    ? <ChevronDown size={18} className="text-indigo-400" />
                                                    : <ChevronRight size={18} className="text-slate-500" />
                                                }
                                                <span className="font-mono text-indigo-400 w-8 text-lg font-bold">{type.id}</span>
                                                <span className="text-slate-200 font-medium">{type.name}</span>
                                            </div>
                                            {type.has_definition && (
                                                <span className="text-xs bg-emerald-500/10 text-emerald-400 border border-emerald-500/20 px-2 py-1 rounded">
                                                    Defined
                                                </span>
                                            )}
                                        </button>

                                        {/* Detailed Parameter Table */}
                                        {selectedType === type.id && typeDetails?.definition && (
                                            <div className="p-4 bg-slate-900/50 border-t border-slate-700 overflow-x-auto animate-in slide-in-from-top-2 duration-200">
                                                <div className="flex justify-between items-center mb-3">
                                                    <div className="text-xs text-slate-400 flex items-center gap-2">
                                                        <FileText size={12} />
                                                        Source: <span className="text-slate-300 font-mono">{typeDetails.definition.filename}</span>
                                                    </div>
                                                </div>

                                                <div className="border border-slate-700 rounded-lg overflow-hidden">
                                                    <table className="w-full text-xs text-right">
                                                        <thead className="text-slate-400 font-mono bg-slate-800">
                                                            <tr>
                                                                <th className="p-2 text-left bg-slate-800/80 sticky left-0 z-10">Day</th>
                                                                {typeDetails.definition.headers.map((h: string) => (
                                                                    <th key={h} className="p-2 whitespace-nowrap">{h}</th>
                                                                ))}
                                                            </tr>
                                                        </thead>
                                                        <tbody className="font-mono text-slate-300">
                                                            {typeDetails.definition.table.map((row: any, idx: number) => (
                                                                <tr key={idx} className="border-b border-slate-800 last:border-0 hover:bg-slate-800/30">
                                                                    <td className="p-2 text-left text-indigo-300 bg-slate-900/50 sticky left-0 border-r border-slate-800 font-bold">
                                                                        {row.day}
                                                                    </td>
                                                                    {row.values.map((v: number, vIdx: number) => (
                                                                        <td key={vIdx} className="p-2 text-slate-400">
                                                                            {v.toFixed(3)}
                                                                        </td>
                                                                    ))}
                                                                </tr>
                                                            ))}
                                                        </tbody>
                                                    </table>
                                                </div>
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
                    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 overflow-y-auto h-full pr-2 pb-4">
                        {windData.map((sector: any, i: number) => (
                            <div key={i} className="p-5 bg-slate-800 rounded-lg border border-slate-700 relative overflow-hidden group hover:border-indigo-500/50 transition-all hover:shadow-lg hover:shadow-indigo-500/5">
                                <div className="absolute -top-6 -right-6 p-4 opacity-5 group-hover:opacity-10 transition-opacity rotate-12">
                                    <Wind size={120} />
                                </div>
                                <div className="text-xs uppercase text-slate-500 font-bold mb-2 tracking-widest">
                                    Sector {i + 1}
                                </div>
                                <div className="text-3xl text-white font-light mb-6 flex items-baseline gap-2">
                                    {sector.angle_start}°
                                    <span className="text-base text-slate-600 font-normal">to</span>
                                    {sector.angle_end}°
                                </div>
                                <div className="flex items-center justify-between bg-slate-900/50 p-3 rounded border border-slate-700/50">
                                    <span className="text-sm text-slate-400">Exposure Factor</span>
                                    <span className="text-lg font-mono text-indigo-400 font-bold">{sector.exposure_factor.toFixed(2)}</span>
                                </div>
                            </div>
                        ))}
                    </div>
                )}
            </div>
        </div>
    );
};

import { Droplets, Wind, FileText, CheckCircle, AlertCircle } from 'lucide-react';
import type { ForcingOverview } from '../../types';

export const ForcingPanel = ({ forcing }: { forcing: ForcingOverview }) => (
    <div className="grid grid-cols-1 md:grid-cols-2 gap-6">

        {/* Precipitation Card */}
        <div className="bg-slate-800/50 backdrop-blur-sm rounded-xl p-6 border border-slate-700">
            <h3 className="text-xl font-semibold mb-4 flex items-center gap-2">
                <Droplets className="w-5 h-5 text-blue-400" />
                Precipitation Data
            </h3>
            <div className="space-y-4">
                <div className="flex items-end gap-2">
                    <div className="text-4xl font-bold text-white">{forcing.n_precip_files}</div>
                    <div className="text-sm text-slate-400 mb-1.5">Time series files loaded</div>
                </div>

                {/* File List */}
                <div className="space-y-1 max-h-40 overflow-y-auto pr-2 custom-scrollbar">
                    {forcing.precip_filenames.length > 0 ? (
                        forcing.precip_filenames.map((name, i) => (
                            <div key={i} className="text-sm bg-slate-700/30 px-3 py-2 rounded flex items-center gap-2 text-slate-300 border border-slate-700/50">
                                <FileText className="w-4 h-4 text-blue-400/70" />
                                <span className="font-mono text-xs truncate">{name}</span>
                            </div>
                        ))
                    ) : (
                        <div className="text-sm text-slate-500 italic">No precipitation files linked</div>
                    )}
                </div>
            </div>
        </div>

        {/* Climate Card */}
        <div className="bg-slate-800/50 backdrop-blur-sm rounded-xl p-6 border border-slate-700">
            <h3 className="text-xl font-semibold mb-4 flex items-center gap-2">
                <Wind className="w-5 h-5 text-cyan-400" />
                Climate Data
            </h3>
            <div className="space-y-4">
                <div className="flex items-end gap-2">
                    <div className="text-4xl font-bold text-white">{forcing.n_climate_files}</div>
                    <div className="text-sm text-slate-400 mb-1.5">Climate tables loaded</div>
                </div>

                {/* File List */}
                <div className="space-y-1 max-h-40 overflow-y-auto pr-2 custom-scrollbar">
                    {forcing.climate_filenames.length > 0 ? (
                        forcing.climate_filenames.map((name, i) => (
                            <div key={i} className="text-sm bg-slate-700/30 px-3 py-2 rounded flex items-center gap-2 text-slate-300 border border-slate-700/50">
                                <FileText className="w-4 h-4 text-cyan-400/70" />
                                <span className="font-mono text-xs truncate">{name}</span>
                            </div>
                        ))
                    ) : (
                        <div className="text-sm text-slate-500 italic">No climate files linked</div>
                    )}
                </div>
            </div>
        </div>

        {/* Land Use Status (Full Width) */}
        <div className="md:col-span-2 bg-slate-800/50 backdrop-blur-sm rounded-xl p-6 border border-slate-700 flex items-center justify-between">
            <div>
                <h3 className="text-lg font-semibold text-white">Land Use Timeline</h3>
                <p className="text-sm text-slate-400">Controls vegetation changes over simulation time</p>
            </div>
            <div className={`flex items-center gap-2 px-4 py-2 rounded-full border ${forcing.has_landuse_timeline ? 'bg-green-500/10 border-green-500/30 text-green-400' : 'bg-slate-700/30 border-slate-600 text-slate-400'}`}>
                {forcing.has_landuse_timeline ? <CheckCircle className="w-4 h-4" /> : <AlertCircle className="w-4 h-4" />}
                <span className="text-sm font-medium">{forcing.has_landuse_timeline ? 'Configured' : 'Not Configured'}</span>
            </div>
        </div>
    </div>
);

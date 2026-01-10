import { Layers, Map, Droplets, FileText } from 'lucide-react';
import { StatCard } from '../ui/StatCard';
import type { FullProjectData } from '../../types';

export const OverviewPanel = ({ project }: { project: FullProjectData }) => (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <StatCard icon={<Layers className="w-6 h-6" />} title="Hills" value={project.summary.n_hills} subtitle="Spatial domains" color="blue" />
        <StatCard icon={<Map className="w-6 h-6" />} title="Soil Types" value={project.soils.length} subtitle="In library" color="green" />
        <StatCard icon={<Droplets className="w-6 h-6" />} title="Precipitation" value={project.forcing.n_precip_files} subtitle="Time series" color="cyan" />
        <StatCard icon={<FileText className="w-6 h-6" />} title="Method" value={project.summary.method || 'N/A'} subtitle="Solver" color="purple" />

        <div className="col-span-full bg-slate-800/50 backdrop-blur-sm rounded-xl p-6 border border-slate-700">
            <h3 className="text-xl font-semibold mb-4 flex items-center gap-2">
                <FileText className="w-5 h-5 text-blue-400" /> Simulation Configuration
            </h3>
            <div className="grid grid-cols-2 gap-4 text-sm text-slate-300">
                <div>Start: <span className="text-white font-mono">{project.summary.simulation_start}</span></div>
                <div>End: <span className="text-white font-mono">{project.summary.simulation_end}</span></div>
                {/* Add more config details here if needed from project.config */}
            </div>
        </div>
    </div>
);

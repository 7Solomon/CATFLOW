import { Clock, MapPin, Activity } from 'lucide-react';
import type { FullProjectData } from '../../types';

export const ConfigPanel = ({ project }: { project: FullProjectData }) => {
    const { config } = project;


    if (!config) return <div className="p-8 text-slate-500">No configuration loaded</div>;

    const Section = ({ icon: Icon, title, children }: any) => (
        <div className="bg-slate-800/50 rounded-xl border border-slate-700 overflow-hidden mb-6">
            <div className="bg-slate-900/50 px-4 py-3 border-b border-slate-700 flex items-center gap-2">
                <Icon size={18} className="text-indigo-400" />
                <h3 className="font-semibold text-slate-200">{title}</h3>
            </div>
            <div className="p-4 grid grid-cols-2 gap-4">{children}</div>
        </div>
    );

    const Param = ({ label, value, unit = '' }: any) => (
        <div>
            <div className="text-xs text-slate-500 uppercase tracking-wider mb-1">{label}</div>
            <div className="text-slate-200 font-mono">
                {value} <span className="text-slate-500 text-sm">{unit}</span>
            </div>
        </div>
    );

    return (
        <div className="h-full overflow-auto pr-2">
            <Section icon={Clock} title="Simulation Timing">
                <Param label="Start Time" value={config.timing.start_time.toExponential(2)} unit="s" />
                <Param label="End Time" value={config.timing.end_time.toExponential(2)} unit="s" />
                <Param label="Max Time Step" value={config.timing.dt_max} unit="s" />
                <Param label="Min Time Step" value={config.timing.dt_min} unit="s" />
                <Param label="Initial Step" value={config.timing.dt_init} unit="s" />
                <Param label="Time Offset" value={config.timing.offset} unit="s" />
            </Section>

            <Section icon={Activity} title="Solver Settings">
                <Param label="Method" value={config.solver.method} />
                <Param label="Max Iterations" value={config.solver.it_max} />
                <Param label="Picard Epsilon" value={config.solver.piceps.toExponential(1)} />
                <Param label="CG Epsilon" value={config.solver.cgeps.toExponential(1)} />
                <Param label="Theta Opt" value={config.solver.d_th_opt} />
                <Param label="Phi Opt" value={config.solver.d_phi_opt} />
            </Section>

            <Section icon={MapPin} title="Global Location">
                <Param label="Latitude" value={config.location.latitude.toFixed(4)} unit="°" />
                <Param label="Longitude" value={config.location.longitude.toFixed(4)} unit="°" />
                <Param label="Ref. Longitude" value={config.location.ref_longitude.toFixed(4)} unit="°" />
            </Section>

        </div>
    );
};

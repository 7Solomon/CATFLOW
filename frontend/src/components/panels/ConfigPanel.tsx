import { Clock, MapPin, Activity } from 'lucide-react';
import { useTranslation } from 'react-i18next';
import type { FullProjectData } from '../../types';

export const ConfigPanel = ({ project }: { project: FullProjectData }) => {
    const { t } = useTranslation();
    const config = project?.config;

    if (!config) return <div className="p-8 text-slate-500">{t('panels.config.noConfig')}</div>;

    // Default empty objects to prevent crashes
    const timing = config.timing || {};
    const solver = config.solver || {};
    const location = config.location || {};

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
                {value !== undefined && value !== null ? value : <span className="text-slate-600">-</span>}
                <span className="text-slate-500 text-sm ml-1">{unit}</span>
            </div>
        </div>
    );

    // Helper to safely format numbers, even if they come as strings
    const formatExp = (val: any, digits = 2) => {
        if (val === undefined || val === null) return undefined;
        const num = Number(val);
        return !isNaN(num) ? num.toExponential(digits) : val;
    };

    const formatFixed = (val: any, digits = 4) => {
        if (val === undefined || val === null) return undefined;
        const num = Number(val);
        return !isNaN(num) ? num.toFixed(digits) : val;
    };

    return (
        <div className="h-full overflow-auto pr-2">
            <Section icon={Clock} title={t('panels.config.timing')}>
                {/* Use helper function to convert string->number before formatting */}
                <Param label={t('panels.config.paramStartTime')} value={formatExp(timing.start_time)} unit="s" />
                <Param label={t('panels.config.paramEndTime')} value={formatExp(timing.end_time)} unit="s" />

                {/* These are usually simple numbers/strings, render as is */}
                <Param label={t('panels.config.paramMaxTimeStep')} value={timing.dt_max} unit="s" />
                <Param label={t('panels.config.paramMinTimeStep')} value={timing.dt_min} unit="s" />
                <Param label={t('panels.config.paramInitialStep')} value={timing.dt_init} unit="s" />
                <Param label={t('panels.config.paramTimeOffset')} value={timing.offset} unit="s" />
            </Section>

            <Section icon={Activity} title={t('panels.config.solver')}>
                <Param label={t('panels.config.paramMethod')} value={solver.method} />
                <Param label={t('panels.config.paramMaxIterations')} value={solver.it_max} />
                <Param label={t('panels.config.paramPicardEpsilon')} value={formatExp(solver.piceps, 1)} />
                <Param label={t('panels.config.paramCGEpsilon')} value={formatExp(solver.cgeps, 1)} />
                <Param label={t('panels.config.paramThetaOpt')} value={solver.d_th_opt} />
                <Param label={t('panels.config.paramPhiOpt')} value={solver.d_phi_opt} />
            </Section>

            <Section icon={MapPin} title={t('panels.config.location')}>
                <Param label={t('panels.config.paramLatitude')} value={formatFixed(location.latitude)} unit="°" />
                <Param label={t('panels.config.paramLongitude')} value={formatFixed(location.longitude)} unit="°" />
                <Param label={t('panels.config.paramRefLongitude')} value={formatFixed(location.ref_longitude)} unit="°" />
            </Section>
        </div>
    );
};

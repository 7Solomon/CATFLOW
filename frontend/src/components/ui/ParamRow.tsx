interface ParamRowProps {
    label: string;
    value: string | number;
}

export const ParamRow = ({ label, value }: ParamRowProps) => (
    <div className="flex justify-between items-center text-sm border-b border-slate-700/50 pb-1 last:border-0 last:pb-0">
        <span className="text-slate-400">{label}</span>
        <span className="font-mono text-white">{value}</span>
    </div>
);

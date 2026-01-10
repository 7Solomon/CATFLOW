interface StatusBadgeProps {
    label: string;
    status: boolean;
}

export const StatusBadge = ({ label, status }: StatusBadgeProps) => (
    <div className={`flex items-center justify-between px-3 py-2 rounded-lg ${status ? 'bg-green-500/20 border border-green-500/30' : 'bg-slate-700/30 border border-slate-600'
        }`}>
        <span className="text-sm text-slate-200">{label}</span>
        <div className={`w-2 h-2 rounded-full ${status ? 'bg-green-400' : 'bg-slate-500'}`} />
    </div>
);

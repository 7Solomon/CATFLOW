import type { ReactNode } from 'react';

interface StatCardProps {
    icon: ReactNode;
    title: string;
    value: string | number;
    subtitle?: string;
    color: 'blue' | 'green' | 'cyan' | 'purple' | 'yellow';
}

const colors = {
    blue: 'from-blue-500 to-cyan-500',
    green: 'from-green-500 to-emerald-500',
    cyan: 'from-cyan-500 to-teal-500',
    purple: 'from-purple-500 to-pink-500',
    yellow: 'from-yellow-500 to-orange-500'
};

export const StatCard = ({ icon, title, value, subtitle, color }: StatCardProps) => (
    <div className="bg-slate-800/50 backdrop-blur-sm rounded-xl p-6 border border-slate-700">
        <div className={`w-12 h-12 rounded-lg bg-gradient-to-br ${colors[color]} flex items-center justify-center mb-4 text-white`}>
            {icon}
        </div>
        <div className="text-sm text-slate-400 mb-1">{title}</div>
        <div className="text-3xl font-bold mb-1">{value}</div>
        {subtitle && <div className="text-xs text-slate-500">{subtitle}</div>}
    </div>
);

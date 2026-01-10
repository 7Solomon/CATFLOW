import React, { type ReactNode } from 'react';

interface StatCardProps {
    icon: ReactNode;
    title: string;
    value: string | number;
    color: 'blue' | 'green' | 'cyan' | 'purple' | 'yellow';
}

const colorClasses = {
    blue: 'from-blue-500 to-blue-600',
    green: 'from-green-500 to-green-600',
    cyan: 'from-cyan-500 to-cyan-600',
    purple: 'from-purple-500 to-purple-600',
    yellow: 'from-yellow-500 to-orange-500'
};

export const StatCard = ({ icon, title, value, color }: StatCardProps) => {
    return (
        <div className="bg-slate-800/50 rounded-xl p-6 border border-slate-700">
            <div className={`w-12 h-12 rounded-lg bg-gradient-to-br ${colorClasses[color]} flex items-center justify-center mb-3 text-white`}>
                {React.isValidElement(icon)
                    ? React.cloneElement(icon as React.ReactElement<{ className?: string }>, { className: 'w-6 h-6' })
                    : icon}
            </div>
            <div className="text-sm text-slate-400 mb-1">{title}</div>
            <div className="text-2xl font-bold">{value}</div>
        </div>
    );
};

import React, { type ReactNode } from 'react';

interface InfoCardProps {
    title: string;
    icon: ReactNode;
    children: ReactNode;
}

export const InfoCard = ({ title, icon, children }: InfoCardProps) => (
    <div className="bg-slate-800/50 rounded-xl p-6 border border-slate-700">
        <h3 className="text-lg font-semibold mb-4 flex items-center gap-2 text-slate-200">
            {React.isValidElement(icon)
                ? React.cloneElement(icon as React.ReactElement<{ className?: string }>, { className: 'w-5 h-5 text-blue-400' })
                : icon}
            {title}
        </h3>
        {children}
    </div>
);

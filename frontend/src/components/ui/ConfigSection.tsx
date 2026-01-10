import React, { type ReactNode } from 'react';

interface ConfigSectionProps {
    title: string;
    icon: ReactNode;
    children: ReactNode;
}

export const ConfigSection = ({ title, icon, children }: ConfigSectionProps) => (
    <div className="bg-slate-800/50 rounded-xl p-6 border border-slate-700">
        <h3 className="text-lg font-semibold mb-4 flex items-center gap-2">
            {React.isValidElement(icon)
                ? React.cloneElement(icon as React.ReactElement<{ className?: string }>, { className: 'w-5 h-5 text-cyan-400' })
                : icon}
            {title}
        </h3>
        <div className="space-y-3">
            {children}
        </div>
    </div>
);

import React, { type ReactNode } from 'react';
import { FileText } from 'lucide-react';

interface FileListCardProps {
    title: string;
    icon: ReactNode;
    files: string[];
    color: 'blue' | 'cyan';
    onSelect?: (file: string) => void;
}

export const FileListCard = ({ title, icon, files, color, onSelect }: FileListCardProps) => {
    return (
        <div className="bg-slate-800/50 rounded-xl p-6 border border-slate-700">
            <h3 className="text-lg font-semibold mb-4 flex items-center gap-2">
                {React.isValidElement(icon) ? React.cloneElement(icon as React.ReactElement<{ className?: string }>, { className: `w-5 h-5 ${color === 'blue' ? 'text-blue-400' : 'text-cyan-400'}` }) : icon}
                {title}
            </h3>
            <div className="text-3xl font-bold mb-4">{files.length}</div>
            <div className="space-y-2 max-h-48 overflow-y-auto pr-2 custom-scrollbar">
                {files.length > 0 ? (
                    files.map((file, i) => (
                        <div
                            key={i}
                            onClick={() => onSelect && onSelect(file)}
                            className={`flex items-center gap-2 bg-slate-700/30 px-3 py-2 rounded text-sm transition-colors ${onSelect ? 'cursor-pointer hover:bg-slate-600/50' : ''}`}
                        >
                            <FileText className="w-4 h-4 text-slate-400" />
                            <span className="font-mono text-xs truncate text-slate-300">{file}</span>
                        </div>
                    ))
                ) : (
                    <div className="text-slate-500 italic text-sm">No files found</div>
                )}
            </div>
        </div>
    );
};

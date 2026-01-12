import { useState, useEffect } from 'react';
import { X, Folder, Loader2, ChevronRight } from 'lucide-react';
import { projectApi } from '../../api/client';

interface LoadProjectModalProps {
    isOpen: boolean;
    onClose: () => void;
    onLoad: (path: string) => void;
}

export const LoadProjectModal = ({ isOpen, onClose, onLoad }: LoadProjectModalProps) => {
    const [projects, setProjects] = useState<string[]>([]);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState<string | null>(null);

    useEffect(() => {
        if (isOpen) {
            loadList();
        }
    }, [isOpen]);

    const loadList = async () => {
        setLoading(true);
        setError(null);
        try {
            const res = await projectApi.listProjects();
            setProjects(res.data);
        } catch (err) {
            setError("Failed to load project list");
        } finally {
            setLoading(false);
        }
    };

    if (!isOpen) return null;

    return (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm animate-in fade-in duration-200">
            <div className="bg-slate-900 border border-slate-700 rounded-xl shadow-2xl w-full max-w-md overflow-hidden">
                <div className="flex justify-between items-center p-4 border-b border-slate-700 bg-slate-800/50">
                    <h3 className="text-lg font-semibold text-white flex items-center gap-2">
                        <Folder className="text-indigo-400" size={20} />
                        Select Project
                    </h3>
                    <button onClick={onClose} className="text-slate-400 hover:text-white transition-colors">
                        <X size={20} />
                    </button>
                </div>

                <div className="p-2 max-h-[60vh] overflow-y-auto">
                    {loading ? (
                        <div className="flex justify-center items-center py-12 text-indigo-400">
                            <Loader2 className="animate-spin" size={32} />
                        </div>
                    ) : error ? (
                        <div className="p-4 text-center text-red-400 bg-red-900/10 rounded m-2">
                            {error}
                            <button onClick={loadList} className="block mx-auto mt-2 text-sm text-indigo-400 hover:underline">Retry</button>
                        </div>
                    ) : projects.length === 0 ? (
                        <div className="p-8 text-center text-slate-500">
                            No projects found in template folder.
                        </div>
                    ) : (
                        <div className="space-y-1">
                            {projects.map((proj) => (
                                <button
                                    key={proj}
                                    onClick={() => onLoad(proj)}
                                    className="w-full flex items-center justify-between p-3 rounded-lg hover:bg-slate-800 transition-all text-left group border border-transparent hover:border-slate-700"
                                >
                                    <div className="flex items-center gap-3">
                                        <div className="bg-slate-800 group-hover:bg-indigo-500/20 p-2 rounded transition-colors">
                                            <Folder size={18} className="text-slate-400 group-hover:text-indigo-400" />
                                        </div>
                                        <span className="text-slate-200 font-medium">{proj}</span>
                                    </div>
                                    <ChevronRight size={16} className="text-slate-600 group-hover:text-indigo-400 opacity-0 group-hover:opacity-100 transition-all -translate-x-2 group-hover:translate-x-0" />
                                </button>
                            ))}
                        </div>
                    )}
                </div>

                <div className="p-3 bg-slate-800/30 border-t border-slate-700 text-xs text-slate-500 text-center">
                    Select a folder to initialize the workspace
                </div>
            </div>
        </div>
    );
};

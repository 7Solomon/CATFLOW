import { useState } from 'react';
import { Download, AlertTriangle, FileText, ChevronRight, ChevronDown, Folder, CheckCircle } from 'lucide-react';
import { projectApi } from '../../api/client'; // Adjust path based on your structure

interface ExportPreview {
    target_folder: string;
    total_files: number;
    warnings: string[];
    files_to_create: Record<string, string[]>; // Category -> File list
}

export const ExportPanel = () => {
    const [preview, setPreview] = useState<ExportPreview | null>(null);
    const [loading, setLoading] = useState(false);

    const handleGeneratePreview = async () => {
        setLoading(true);
        try {
            // You can make this dynamic if needed, for now using a default output name
            const data = await projectApi.previewExport("ft_backend_export");
            setPreview(data);
        } catch (e) {
            console.error(e);
        } finally {
            setLoading(false);
        }
    };

    if (!preview) {
        return (
            <div className="flex flex-col items-center justify-center py-20 bg-slate-800/30 rounded-xl border border-dashed border-slate-700">
                <Download className="w-16 h-16 text-slate-600 mb-4" />
                <h3 className="text-xl font-semibold text-slate-300 mb-2">Ready to Export?</h3>
                <p className="text-slate-500 mb-6">Generate a preview to check all files before writing to disk.</p>
                <button
                    onClick={handleGeneratePreview}
                    disabled={loading}
                    className="px-6 py-3 bg-gradient-to-r from-emerald-500 to-green-600 rounded-lg font-semibold hover:shadow-lg hover:shadow-green-500/20 transition-all text-white disabled:opacity-50"
                >
                    {loading ? 'Analyzing Project...' : 'Generate Export Preview'}
                </button>
            </div>
        );
    }

    return (
        <div className="space-y-6">
            {/* Summary Header */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                <div className="bg-slate-800/50 p-6 rounded-xl border border-slate-700">
                    <div className="text-slate-400 text-sm mb-1">Total Files</div>
                    <div className="text-3xl font-bold text-white">{preview.total_files}</div>
                </div>
                <div className="bg-slate-800/50 p-6 rounded-xl border border-slate-700">
                    <div className="text-slate-400 text-sm mb-1">Target Folder</div>
                    <div className="text-lg font-mono text-emerald-400 truncate" title={preview.target_folder}>
                        ./{preview.target_folder}
                    </div>
                </div>
                <div className={`p-6 rounded-xl border ${preview.warnings.length > 0 ? 'bg-amber-500/10 border-amber-500/30' : 'bg-slate-800/50 border-slate-700'}`}>
                    <div className="text-slate-400 text-sm mb-1">Status</div>
                    <div className={`text-lg font-bold flex items-center gap-2 ${preview.warnings.length > 0 ? 'text-amber-400' : 'text-green-400'}`}>
                        {preview.warnings.length > 0 ? <AlertTriangle className="w-5 h-5" /> : <CheckCircle className="w-5 h-5" />}
                        {preview.warnings.length > 0 ? `${preview.warnings.length} Warnings` : 'Ready'}
                    </div>
                </div>
            </div>

            {/* Warnings List */}
            {preview.warnings.length > 0 && (
                <div className="bg-amber-950/30 border border-amber-500/30 rounded-xl p-4">
                    <h4 className="font-semibold text-amber-400 mb-2 flex items-center gap-2">
                        <AlertTriangle className="w-4 h-4" /> configuration Issues
                    </h4>
                    <ul className="list-disc list-inside space-y-1 text-sm text-amber-200/80">
                        {preview.warnings.map((w, i) => <li key={i}>{w}</li>)}
                    </ul>
                </div>
            )}

            {/* File Tree */}
            <div className="bg-slate-900/50 rounded-xl border border-slate-700 overflow-hidden">
                <div className="p-4 bg-slate-800/50 border-b border-slate-700 font-semibold text-slate-300">
                    File Structure Preview
                </div>
                <div className="p-4 space-y-2">
                    {Object.entries(preview.files_to_create).map(([category, files]) => (
                        <FileCategory key={category} name={category} files={files} />
                    ))}
                </div>
            </div>
        </div>
    );
};

// Helper Sub-component for Tree View
const FileCategory = ({ name, files }: { name: string, files: string[] }) => {
    const [isOpen, setIsOpen] = useState(false);

    if (files.length === 0) return null;

    return (
        <div className="rounded-lg overflow-hidden border border-slate-700/50 bg-slate-800/20">
            <button
                onClick={() => setIsOpen(!isOpen)}
                className="w-full flex items-center justify-between p-3 hover:bg-slate-700/30 transition-colors text-left"
            >
                <div className="flex items-center gap-2.5">
                    <Folder className={`w-4 h-4 ${isOpen ? 'text-blue-400' : 'text-slate-500'}`} />
                    <span className="font-medium text-slate-300">{name}</span>
                    <span className="text-xs bg-slate-700 px-2 py-0.5 rounded text-slate-400">{files.length}</span>
                </div>
                {isOpen ? <ChevronDown className="w-4 h-4 text-slate-500" /> : <ChevronRight className="w-4 h-4 text-slate-500" />}
            </button>

            {isOpen && (
                <div className="bg-slate-900/30 border-t border-slate-700/50 p-2 pl-4 grid grid-cols-1 md:grid-cols-2 gap-2">
                    {files.map((f, i) => (
                        <div key={i} className="flex items-center gap-2 text-xs font-mono text-slate-400 hover:text-slate-200 py-1">
                            <FileText className="w-3.5 h-3.5 opacity-50" />
                            {f}
                        </div>
                    ))}
                </div>
            )}
        </div>
    );
};

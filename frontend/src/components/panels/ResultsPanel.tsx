import { useState, useEffect } from 'react';
import { BarChart2, Droplets } from 'lucide-react';
import { projectApi } from '../../api/client';

export const ResultsPanel = () => {
    const [available, setAvailable] = useState<boolean>(false);
    const [waterBalance, setWaterBalance] = useState<any>(null);

    useEffect(() => {
        checkAvailability();
    }, []);

    const checkAvailability = async () => {
        const status = await projectApi.fetchResultsAvailability();
        setAvailable(status.available);
        if (status.available) {
            const wb = await projectApi.fetchWaterBalance();
            setWaterBalance(wb);
        }
    };

    if (!available) {
        return (
            <div className="h-full flex flex-col items-center justify-center text-slate-500">
                <BarChart2 size={48} className="mb-4 opacity-50" />
                <p>No simulation results found.</p>
                <p className="text-sm mt-2">Run the simulation to generate output data.</p>
            </div>
        );
    }

    return (
        <div className="h-full overflow-auto">
            <h2 className="text-xl text-white font-semibold mb-6">Simulation Results</h2>

            {/* Water Balance Summary */}
            <div className="bg-slate-800 p-4 rounded-xl border border-slate-700 mb-6">
                <h3 className="text-lg text-indigo-400 mb-4 flex items-center gap-2">
                    <Droplets size={20} /> Water Balance
                </h3>

                {waterBalance ? (
                    <div className="overflow-x-auto">
                        <table className="w-full text-sm text-left text-slate-300">
                            <thead className="text-xs text-slate-500 uppercase bg-slate-900/50">
                                <tr>
                                    {waterBalance.columns.map((col: string) => (
                                        <th key={col} className="px-4 py-3">{col}</th>
                                    ))}
                                </tr>
                            </thead>
                            <tbody>
                                {waterBalance.data.slice(0, 10).map((row: any[], i: number) => (
                                    <tr key={i} className="border-b border-slate-700/50 hover:bg-slate-700/30">
                                        {row.map((cell, j) => (
                                            <td key={j} className="px-4 py-2 font-mono">
                                                {typeof cell === 'number' ? cell.toExponential(2) : cell}
                                            </td>
                                        ))}
                                    </tr>
                                ))}
                            </tbody>
                        </table>
                        <div className="text-xs text-slate-500 mt-2 text-center p-2">
                            Showing first 10 timesteps of {waterBalance.data.length}
                        </div>
                    </div>
                ) : (
                    <div>Loading water balance...</div>
                )}
            </div>
        </div>
    );
};

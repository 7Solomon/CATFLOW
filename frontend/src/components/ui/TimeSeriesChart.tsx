import {
    LineChart, Line, XAxis, YAxis, CartesianGrid,
    Tooltip, ResponsiveContainer
} from 'recharts';

interface DataPoint {
    time: number | string;
    value: number;
}

interface TimeSeriesChartProps {
    data: DataPoint[];
    color?: string;
    yLabel?: string;
    xLabel?: string;
}

export const TimeSeriesChart = ({
    data,
    color = "#3b82f6",
    yLabel = "Value",
    xLabel = "Time"
}: TimeSeriesChartProps) => {
    if (!data || data.length === 0) {
        return (
            <div className="h-64 flex items-center justify-center bg-slate-900/50 rounded-lg text-slate-500 border border-slate-700 border-dashed">
                No data available to plot
            </div>
        );
    }

    return (
        <div className="h-64 w-full bg-slate-800/50 p-4 rounded-xl border border-slate-700">
            <ResponsiveContainer width="100%" height="100%">
                <LineChart data={data} margin={{ top: 5, right: 20, bottom: 20, left: 0 }}>
                    <CartesianGrid strokeDasharray="3 3" stroke="#334155" />
                    <XAxis
                        dataKey="time"
                        stroke="#94a3b8"
                        tick={{ fill: '#94a3b8', fontSize: 12 }}
                        label={{ value: xLabel, position: 'insideBottom', offset: -10, fill: '#64748b' }}
                    />
                    <YAxis
                        stroke="#94a3b8"
                        tick={{ fill: '#94a3b8', fontSize: 12 }}
                        label={{ value: yLabel, angle: -90, position: 'insideLeft', fill: '#64748b' }}
                    />
                    <Tooltip
                        contentStyle={{ backgroundColor: '#1e293b', borderColor: '#334155', color: '#f1f5f9' }}
                        itemStyle={{ color: color }}
                        labelStyle={{ color: '#94a3b8' }}
                    />
                    <Line
                        type="monotone"
                        dataKey="value"
                        stroke={color}
                        strokeWidth={2}
                        dot={false}
                        activeDot={{ r: 6 }}
                    />
                </LineChart>
            </ResponsiveContainer>
        </div>
    );
};

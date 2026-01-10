import { useState } from 'react';

interface HeatmapGridProps {
    data: number[][]; // 2D array [rows][cols]
    colorScale?: (val: number) => string;
}

export const HeatmapGrid = ({ data, colorScale }: HeatmapGridProps) => {
    const [hovered, setHovered] = useState<{ r: number, c: number, val: number } | null>(null);

    if (!data || data.length === 0) return null;

    const rows = data.length;
    const cols = data[0].length;

    // Default color scale (blue gradient) if none provided
    const defaultColorScale = (val: number) => {
        // Hash function to give different IDs different colors nicely
        const hues = [210, 150, 45, 280, 10, 320]; // Blue, Green, Orange, Purple, Red, Pink
        const hue = hues[val % hues.length] || 0;
        return `hsl(${hue}, 70%, 50%)`;
    };

    const getColor = colorScale || defaultColorScale;

    return (
        <div className="relative overflow-hidden rounded-lg border border-slate-700 bg-slate-900">
            <div
                className="grid"
                style={{
                    gridTemplateColumns: `repeat(${cols}, 1fr)`,
                    aspectRatio: `${cols}/${rows}` // Keep physical aspect ratio
                }}
                onMouseLeave={() => setHovered(null)}
            >
                {data.flatMap((row, r) =>
                    row.map((val, c) => (
                        <div
                            key={`${r}-${c}`}
                            className="w-full h-full transition-opacity hover:opacity-80"
                            style={{ backgroundColor: getColor(val) }}
                            onMouseEnter={() => setHovered({ r, c, val })}
                        />
                    ))
                )}
            </div>

            {/* Hover Tooltip */}
            {hovered && (
                <div className="absolute bottom-2 right-2 bg-slate-900/90 text-white text-xs px-2 py-1 rounded border border-slate-600 shadow-xl pointer-events-none">
                    Cell ({hovered.r}, {hovered.c}): <strong>Value {hovered.val}</strong>
                </div>
            )}
        </div>
    );
};

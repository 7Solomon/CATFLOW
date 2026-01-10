import { useRef, useEffect, useState } from 'react';
import { projectApi } from '../api/client';

interface NodeData {
    x: number;
    z: number;
    row: number;
    col: number;
    soilId?: number;
}

export const HillVisualizer = ({ hillId }: { hillId: number }) => {
    const canvasRef = useRef<HTMLCanvasElement>(null);
    const containerRef = useRef<HTMLDivElement>(null);

    const [mesh, setMesh] = useState<any>(null);
    const [soilMap, setSoilMap] = useState<any>(null);
    const [hoverInfo, setHoverInfo] = useState<NodeData | null>(null);
    const [scale, setScale] = useState({ x: 1, z: 1, offX: 0, offZ: 0 });

    // 1. Fetch Data
    useEffect(() => {
        Promise.all([
            projectApi.fetchHillMap(hillId, 'mesh'),
            projectApi.fetchHillMap(hillId, 'soil-map')
        ]).then(([meshData, soilData]) => {
            setMesh(meshData);
            setSoilMap(soilData);
        });
    }, [hillId]);

    // 2. Render Canvas
    useEffect(() => {
        if (!mesh || !soilMap || !canvasRef.current || !containerRef.current) return;

        const canvas = canvasRef.current;
        const ctx = canvas.getContext('2d');
        if (!ctx) return;

        // Resize canvas to container
        const { width, height } = containerRef.current.getBoundingClientRect();
        canvas.width = width;
        canvas.height = height;

        // Calculate bounds
        const minX = Math.min(...mesh.x_coords.flat());
        const maxX = Math.max(...mesh.x_coords.flat());
        const minZ = Math.min(...mesh.z_coords.flat());
        const maxZ = Math.max(...mesh.z_coords.flat());

        // Calculate scaling to fit with padding
        const padding = 40;
        const dataW = maxX - minX;
        const dataH = maxZ - minZ;
        const scaleX = (width - padding * 2) / dataW;
        const scaleZ = (height - padding * 2) / dataH;

        // Keep aspect ratio reasonable (optional, but good for physics)
        // const s = Math.min(scaleX, scaleZ); 

        // Transform function
        const toScreenX = (x: number) => padding + (x - minX) * scaleX;
        const toScreenZ = (z: number) => height - padding - (z - minZ) * scaleZ; // Flip Y

        setScale({ x: scaleX, z: scaleZ, offX: minX, offZ: minZ }); // Store for mouse interaction

        // --- DRAWING ---
        ctx.clearRect(0, 0, width, height);

        // Draw Elements (Quads)
        const nRows = mesh.n_layers;
        const nCols = mesh.n_columns;

        // Helper to get node index
        const idx = (r: number, c: number) => r * nCols + c;

        // Colors for soil types
        const colors = ['#475569', '#d97706', '#16a34a', '#2563eb', '#9333ea', '#db2777'];

        for (let r = 0; r < nRows - 1; r++) {
            for (let c = 0; c < nCols - 1; c++) {
                // Get 4 corners of element
                const x1 = mesh.x_coords[r][c];
                const z1 = mesh.z_coords[r][c];
                const x2 = mesh.x_coords[r][c + 1];
                const z2 = mesh.z_coords[r][c + 1];
                const x3 = mesh.x_coords[r + 1][c + 1];
                const z3 = mesh.z_coords[r + 1][c + 1];
                const x4 = mesh.x_coords[r + 1][c];
                const z4 = mesh.z_coords[r + 1][c];

                const soilId = soilMap.matrix[r][c];

                ctx.beginPath();
                ctx.moveTo(toScreenX(x1), toScreenZ(z1));
                ctx.lineTo(toScreenX(x2), toScreenZ(z2));
                ctx.lineTo(toScreenX(x3), toScreenZ(z3));
                ctx.lineTo(toScreenX(x4), toScreenZ(z4));
                ctx.closePath();

                // Fill based on soil
                ctx.fillStyle = colors[soilId % colors.length] || '#ccc';
                ctx.fill();

                // Stroke grid lines
                ctx.strokeStyle = 'rgba(255,255,255,0.1)';
                ctx.stroke();
            }
        }

    }, [mesh, soilMap]);

    // 3. Handle Mouse Hover
    const handleMouseMove = (e: React.MouseEvent) => {
        if (!mesh || !soilMap) return;

        const rect = canvasRef.current!.getBoundingClientRect();
        const mouseX = e.clientX - rect.left;
        const mouseY = e.clientY - rect.top;

        // Inverse transform to find nearest node
        // Since grid is irregular, brute force distance check is safest for < 10k nodes
        // For larger grids, we'd need a spatial index (QuadTree)

        let minDist = Infinity;
        let nearest: NodeData | null = null;
        const threshold = 15; // pixels

        // Re-calculate screen coords logic (duplicate of render for now)
        const { width, height } = rect;
        const minX = Math.min(...mesh.x_coords.flat());
        const minZ = Math.min(...mesh.z_coords.flat());
        const maxX = Math.max(...mesh.x_coords.flat());
        const maxZ = Math.max(...mesh.z_coords.flat());
        const padding = 40;
        const scaleX = (width - padding * 2) / (maxX - minX);
        const scaleZ = (height - padding * 2) / (maxZ - minZ);

        const toScreenX = (x: number) => padding + (x - minX) * scaleX;
        const toScreenZ = (z: number) => height - padding - (z - minZ) * scaleZ;

        for (let r = 0; r < mesh.n_layers; r++) {
            for (let c = 0; c < mesh.n_columns; c++) {
                const sx = toScreenX(mesh.x_coords[r][c]);
                const sz = toScreenZ(mesh.z_coords[r][c]);

                const dist = Math.hypot(sx - mouseX, sz - mouseY);
                if (dist < threshold && dist < minDist) {
                    minDist = dist;
                    nearest = {
                        x: mesh.x_coords[r][c],
                        z: mesh.z_coords[r][c],
                        row: r,
                        col: c,
                        soilId: soilMap.matrix[r][c] // Note: soil map is usually cell-centered or node-centered? Assumed node for now
                    };
                }
            }
        }

        setHoverInfo(nearest);
    };

    return (
        <div className="relative w-full h-[500px] bg-slate-900 rounded-xl overflow-hidden border border-slate-700" ref={containerRef}>
            <canvas
                ref={canvasRef}
                onMouseMove={handleMouseMove}
                onMouseLeave={() => setHoverInfo(null)}
                className="cursor-crosshair w-full h-full"
            />

            {/* Tooltip Overlay */}
            {hoverInfo && (
                <div className="absolute top-4 right-4 bg-slate-800/90 backdrop-blur p-4 rounded-lg border border-slate-600 shadow-xl text-sm z-10">
                    <div className="font-semibold text-indigo-400 mb-2">Node Inspector</div>
                    <div className="grid grid-cols-2 gap-x-4 gap-y-1 text-slate-300">
                        <span>Index:</span> <span className="font-mono text-white">[{hoverInfo.row}, {hoverInfo.col}]</span>
                        <span>X-Coord:</span> <span className="font-mono text-white">{hoverInfo.x.toFixed(2)}m</span>
                        <span>Z-Coord:</span> <span className="font-mono text-white">{hoverInfo.z.toFixed(2)}m</span>
                        <span>Soil ID:</span> <span className="font-mono text-amber-400">{hoverInfo.soilId}</span>
                    </div>
                </div>
            )}

            <div className="absolute bottom-4 left-4 text-xs text-slate-500 pointer-events-none">
                Hover over grid points to inspect
            </div>
        </div>
    );
};

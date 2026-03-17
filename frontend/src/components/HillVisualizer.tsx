import { useRef, useEffect, useState, useCallback } from 'react';
import { useTranslation } from 'react-i18next';
import { projectApi } from '../api/client';

// ─── Types ────────────────────────────────────────────────────────────────────

interface MeshData {
    x_coords: number[][];   // shape: [n_columns][n_layers]  (iacnl × iacnv)
    z_coords: number[][];   // shape: [n_columns][n_layers]
    n_layers: number;       // iacnv  (depth direction)
    n_columns: number;      // iacnl  (lateral direction)
}

interface HoverInfo {
    screenX: number;
    screenY: number;
    col: number;    // lateral index (0..n_columns-1)
    row: number;    // depth index   (0..n_layers-1)
    x: number;
    z: number;
    value: number | null;
    label: string;
}

type LayerKey = 'soil' | 'k_scaling' | 'theta_scaling' | 'initial_cond' | 'macropores';
type LayerLabelKey = 'hillVisualizer.soilTypes' | 'hillVisualizer.ksatScaling' | 'hillVisualizer.thetaSScaling' | 'hillVisualizer.initialSaturation' | 'hillVisualizer.macropores';

interface LayerConfig {
    key: LayerKey;
    label: LayerLabelKey;
    endpoint: string;
    matrixPath: (d: any) => number[][];
    minPath: (d: any) => number;
    maxPath: (d: any) => number;
    isCategorical: boolean;
    colorScheme: 'soil' | 'blues' | 'oranges' | 'greens' | 'purples';
}

// ─── Layer definitions ────────────────────────────────────────────────────────

const LAYERS: LayerConfig[] = [
    {
        key: 'soil',
        label: 'hillVisualizer.soilTypes',
        endpoint: 'soil-map',
        matrixPath: (d) => d.matrix,
        minPath: (d) => Math.min(...d.unique_ids),
        maxPath: (d) => Math.max(...d.unique_ids),
        isCategorical: true,
        colorScheme: 'soil',
    },
    {
        key: 'k_scaling',
        label: 'hillVisualizer.ksatScaling',
        endpoint: 'heterogeneity/k',
        matrixPath: (d) => d.matrix,
        minPath: (d) => d.stats.min,
        maxPath: (d) => d.stats.max,
        isCategorical: false,
        colorScheme: 'oranges',
    },
    {
        key: 'theta_scaling',
        label: 'hillVisualizer.thetaSScaling',
        endpoint: 'heterogeneity/theta',
        matrixPath: (d) => d.matrix,
        minPath: (d) => d.stats.min,
        maxPath: (d) => d.stats.max,
        isCategorical: false,
        colorScheme: 'blues',
    },
    {
        key: 'initial_cond',
        label: 'hillVisualizer.initialSaturation',
        endpoint: 'initial-condition',
        matrixPath: (d) => d.values,
        minPath: (d) => d.min_value,
        maxPath: (d) => d.max_value,
        isCategorical: false,
        colorScheme: 'blues',
    },
    {
        key: 'macropores',
        label: 'hillVisualizer.macropores',
        endpoint: 'macropores',
        matrixPath: (d) => d.matrix,
        minPath: (d) => d.min,
        maxPath: (d) => d.max,
        isCategorical: false,
        colorScheme: 'purples',
    },
];

// ─── Color helpers ────────────────────────────────────────────────────────────

// Categorical colors for soil IDs
const SOIL_COLORS = [
    '#94a3b8', // gray   – ID 0
    '#d97706', // amber  – ID 1
    '#16a34a', // green  – ID 2
    '#2563eb', // blue   – ID 3
    '#9333ea', // purple – ID 4
    '#db2777', // pink   – ID 5
    '#0891b2', // cyan   – ID 6
    '#b45309', // brown  – ID 7
];

function lerp(a: number, b: number, t: number) {
    return a + (b - a) * t;
}

function colorForContinuous(t: number, scheme: string): string {
    // t in [0,1]
    const c = Math.max(0, Math.min(1, t));
    switch (scheme) {
        case 'blues': {
            const r = Math.round(lerp(236, 30, c));
            const g = Math.round(lerp(245, 100, c));
            const b = Math.round(lerp(255, 200, c));
            return `rgb(${r},${g},${b})`;
        }
        case 'oranges': {
            const r = Math.round(lerp(255, 180, c));
            const g = Math.round(lerp(237, 60, c));
            const b = Math.round(lerp(213, 10, c));
            return `rgb(${r},${g},${b})`;
        }
        case 'greens': {
            const r = Math.round(lerp(240, 20, c));
            const g = Math.round(lerp(255, 140, c));
            const b = Math.round(lerp(240, 30, c));
            return `rgb(${r},${g},${b})`;
        }
        case 'purples': {
            const r = Math.round(lerp(245, 80, c));
            const g = Math.round(lerp(240, 30, c));
            const b = Math.round(lerp(255, 180, c));
            return `rgb(${r},${g},${b})`;
        }
        default:
            return `rgb(200,200,200)`;
    }
}

// ─── Component ────────────────────────────────────────────────────────────────

export const HillVisualizer = ({ hillId }: { hillId: number }) => {
    const { t } = useTranslation();
    const canvasRef = useRef<HTMLCanvasElement>(null);
    const containerRef = useRef<HTMLDivElement>(null);

    const [mesh, setMesh] = useState<MeshData | null>(null);
    const [layerData, setLayerData] = useState<Record<string, any>>({});
    const [activeLayer, setActiveLayer] = useState<LayerKey>('soil');
    const [lockAspect, setLockAspect] = useState(false);
    const [hoverInfo, setHoverInfo] = useState<HoverInfo | null>(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);

    // ── 1. Fetch mesh once ──────────────────────────────────────────────────────
    useEffect(() => {
        setLoading(true);
        setError(null);
        projectApi
            .fetchHillMap(hillId, 'mesh')
            .then((data: MeshData) => setMesh(data))
            .catch((e: any) => setError(String(e)))
            .finally(() => setLoading(false));
    }, [hillId]);

    // ── 2. Fetch layer data on demand ───────────────────────────────────────────
    useEffect(() => {
        if (layerData[activeLayer]) return; // already cached
        const cfg = LAYERS.find((l) => l.key === activeLayer);
        if (!cfg) return;

        projectApi
            .fetchHillMap(hillId, cfg.endpoint)
            .then((data: any) => setLayerData((prev) => ({ ...prev, [activeLayer]: data })))
            .catch((e: any) => setError(String(e)));
    }, [hillId, activeLayer, layerData]);

    // ── 3. Build screen-space transform ────────────────────────────────────────
    //    Returns helpers given canvas dimensions; memoised on deps.
    const buildTransform = useCallback(
        (width: number, height: number) => {
            if (!mesh) return null;
            const padding = 48;

            // Flatten all x and z to find physical bounds
            const allX = mesh.x_coords.flat();
            const allZ = mesh.z_coords.flat();
            const minX = Math.min(...allX);
            const maxX = Math.max(...allX);
            const minZ = Math.min(...allZ);
            const maxZ = Math.max(...allZ);

            const dataW = maxX - minX || 1;
            const dataH = maxZ - minZ || 1;

            let scaleX = (width - padding * 2) / dataW;
            let scaleZ = (height - padding * 2) / dataH;

            if (lockAspect) {
                const s = Math.min(scaleX, scaleZ);
                scaleX = s;
                scaleZ = s;
            }

            const toScreenX = (x: number) => padding + (x - minX) * scaleX;
            // Z increases downward in screen coords, but elevation increases upward → flip
            const toScreenZ = (z: number) => height - padding - (z - minZ) * scaleZ;

            return { toScreenX, toScreenZ, minX, minZ, maxX, maxZ, scaleX, scaleZ, padding };
        },
        [mesh, lockAspect]
    );

    // ── 4. Render canvas ────────────────────────────────────────────────────────
    useEffect(() => {
        if (!mesh || !canvasRef.current || !containerRef.current) return;

        const currentLayerData = layerData[activeLayer];
        if (!currentLayerData) return;

        const cfg = LAYERS.find((l) => l.key === activeLayer)!;
        const matrix = cfg.matrixPath(currentLayerData);
        const minVal = cfg.minPath(currentLayerData);
        const maxVal = cfg.maxPath(currentLayerData);
        const valRange = maxVal - minVal || 1;

        const canvas = canvasRef.current;
        const ctx = canvas.getContext('2d');
        if (!ctx) return;

        const { width, height } = containerRef.current.getBoundingClientRect();
        canvas.width = width;
        canvas.height = height;

        const tr = buildTransform(width, height);
        if (!tr) return;
        const { toScreenX, toScreenZ } = tr;

        ctx.clearRect(0, 0, width, height);

        // Draw quad elements (each element spans [col, col+1] × [row, row+1])
        // mesh.x_coords is indexed [col][row]
        const nCols = mesh.n_columns;
        const nRows = mesh.n_layers;

        for (let c = 0; c < nCols - 1; c++) {
            for (let r = 0; r < nRows - 1; r++) {
                // 4 corners of the quad
                const x1 = mesh.x_coords[c][r], z1 = mesh.z_coords[c][r];
                const x2 = mesh.x_coords[c + 1][r], z2 = mesh.z_coords[c + 1][r];
                const x3 = mesh.x_coords[c + 1][r + 1], z3 = mesh.z_coords[c + 1][r + 1];
                const x4 = mesh.x_coords[c][r + 1], z4 = mesh.z_coords[c][r + 1];

                // Cell value: use top-left node of the quad (c, r)
                const rawVal = matrix?.[c]?.[r] ?? 0;

                let fillColor: string;
                if (cfg.isCategorical) {
                    fillColor = SOIL_COLORS[rawVal % SOIL_COLORS.length] ?? '#ccc';
                } else {
                    const t = (rawVal - minVal) / valRange;
                    fillColor = colorForContinuous(t, cfg.colorScheme);
                }

                ctx.beginPath();
                ctx.moveTo(toScreenX(x1), toScreenZ(z1));
                ctx.lineTo(toScreenX(x2), toScreenZ(z2));
                ctx.lineTo(toScreenX(x3), toScreenZ(z3));
                ctx.lineTo(toScreenX(x4), toScreenZ(z4));
                ctx.closePath();
                ctx.fillStyle = fillColor;
                ctx.fill();
                ctx.strokeStyle = 'rgba(255,255,255,0.08)';
                ctx.lineWidth = 0.5;
                ctx.stroke();
            }
        }

        // Draw surface row highlight (top row of nodes, r=0)
        ctx.beginPath();
        ctx.moveTo(toScreenX(mesh.x_coords[0][0]), toScreenZ(mesh.z_coords[0][0]));
        for (let c = 1; c < nCols; c++) {
            ctx.lineTo(toScreenX(mesh.x_coords[c][0]), toScreenZ(mesh.z_coords[c][0]));
        }
        ctx.strokeStyle = 'rgba(251,191,36,0.7)'; // amber surface line
        ctx.lineWidth = 1.5;
        ctx.stroke();
    }, [mesh, layerData, activeLayer, lockAspect, buildTransform]);

    // ── 5. Hover hit-test ───────────────────────────────────────────────────────
    const handleMouseMove = useCallback(
        (e: React.MouseEvent) => {
            if (!mesh || !canvasRef.current) return;

            const rect = canvasRef.current.getBoundingClientRect();
            const mouseX = e.clientX - rect.left;
            const mouseY = e.clientY - rect.top;

            const tr = buildTransform(rect.width, rect.height);
            if (!tr) return;
            const { toScreenX, toScreenZ } = tr;

            const cfg = LAYERS.find((l) => l.key === activeLayer)!;
            const currentLayerData = layerData[activeLayer];
            const matrix = currentLayerData ? cfg.matrixPath(currentLayerData) : null;

            let minDist = Infinity;
            let nearest: HoverInfo | null = null;
            const threshold = 18;

            for (let c = 0; c < mesh.n_columns; c++) {
                for (let r = 0; r < mesh.n_layers; r++) {
                    const sx = toScreenX(mesh.x_coords[c][r]);
                    const sz = toScreenZ(mesh.z_coords[c][r]);
                    const dist = Math.hypot(sx - mouseX, sz - mouseY);
                    if (dist < threshold && dist < minDist) {
                        minDist = dist;
                        nearest = {
                            screenX: sx,
                            screenY: sz,
                            col: c,
                            row: r,
                            x: mesh.x_coords[c][r],
                            z: mesh.z_coords[c][r],
                            value: matrix?.[c]?.[r] ?? null,
                            label: cfg.label,
                        };
                    }
                }
            }

            setHoverInfo(nearest);
        },
        [mesh, layerData, activeLayer, buildTransform]
    );

    // ── 6. Legend data ──────────────────────────────────────────────────────────
    const renderLegend = () => {
        const cfg = LAYERS.find((l) => l.key === activeLayer)!;
        const currentLayerData = layerData[activeLayer];
        if (!currentLayerData) return null;

        if (cfg.isCategorical) {
            const ids = currentLayerData.unique_ids as number[];
            return (
                <div className="flex flex-col gap-1.5">
                    {ids.map((id) => (
                        <div key={id} className="flex items-center gap-2 text-xs text-slate-300">
                            <div
                                className="w-3 h-3 rounded-sm flex-shrink-0"
                                style={{ backgroundColor: SOIL_COLORS[id % SOIL_COLORS.length] }}
                            />
                            <span>Soil {id}</span>
                        </div>
                    ))}
                </div>
            );
        } else {
            const minVal = cfg.minPath(currentLayerData);
            const maxVal = cfg.maxPath(currentLayerData);
            const stops = [0, 0.25, 0.5, 0.75, 1];
            return (
                <div className="flex flex-col gap-1">
                    <div
                        className="w-full h-3 rounded"
                        style={{
                            background: `linear-gradient(to right, ${stops
                                .map((t) => colorForContinuous(t, cfg.colorScheme))
                                .join(', ')})`,
                        }}
                    />
                    <div className="flex justify-between text-xs text-slate-400">
                        <span>{minVal.toFixed(3)}</span>
                        <span>{maxVal.toFixed(3)}</span>
                    </div>
                </div>
            );
        }
    };

    // ── Render ──────────────────────────────────────────────────────────────────
    return (
        <div className="flex flex-col gap-3">
            {/* Toolbar */}
            <div className="flex items-center gap-2 flex-wrap">
                {LAYERS.map((layer) => (
                    <button
                        key={layer.key}
                        onClick={() => setActiveLayer(layer.key)}
                        className={`px-3 py-1.5 rounded-md text-xs font-medium transition-colors ${activeLayer === layer.key
                            ? 'bg-indigo-600 text-white'
                            : 'bg-slate-700 text-slate-300 hover:bg-slate-600'
                            }`}
                    >
                        {t(layer.label)}
                    </button>
                ))}
                <div className="ml-auto flex items-center gap-2 text-xs text-slate-400">
                    <label className="flex items-center gap-1.5 cursor-pointer select-none">
                        <input
                            type="checkbox"
                            checked={lockAspect}
                            onChange={(e) => setLockAspect(e.target.checked)}
                            className="accent-indigo-500"
                        />
                        {t('hillVisualizer.lockAspectRatio')}
                    </label>
                </div>
            </div>

            {/* Canvas + overlay panels */}
            <div
                className="relative w-full h-[520px] bg-slate-900 rounded-xl overflow-hidden border border-slate-700"
                ref={containerRef}
            >
                {loading && (
                    <div className="absolute inset-0 flex items-center justify-center text-slate-500 text-sm">
                        {t('hillVisualizer.loadingMesh')}
                    </div>
                )}
                {error && (
                    <div className="absolute inset-0 flex items-center justify-center text-red-400 text-sm px-8 text-center">
                        {error}
                    </div>
                )}

                <canvas
                    ref={canvasRef}
                    onMouseMove={handleMouseMove}
                    onMouseLeave={() => setHoverInfo(null)}
                    className="cursor-crosshair w-full h-full"
                />

                {/* Surface line label */}
                <div className="absolute top-3 left-3 flex items-center gap-1.5 text-xs text-amber-400/80 pointer-events-none">
                    <div className="w-5 h-0.5 bg-amber-400/70" />
                    {t('hillVisualizer.surface')}
                </div>

                {/* Node tooltip */}
                {hoverInfo && (
                    <div className="absolute top-4 right-4 bg-slate-800/95 backdrop-blur-sm p-3 rounded-lg border border-slate-600 shadow-xl text-xs z-10 min-w-[160px]">
                        <div className="font-semibold text-indigo-400 mb-2 text-xs uppercase tracking-wide">
                            {t('hillVisualizer.nodeInspector')}
                        </div>
                        <div className="grid grid-cols-2 gap-x-3 gap-y-1 text-slate-300">
                            <span>{t('hillVisualizer.nodeIndex')}</span>
                            <span className="font-mono text-white">
                                [{hoverInfo.col}, {hoverInfo.row}]
                            </span>
                            <span>{t('hillVisualizer.coordinateX')}</span>
                            <span className="font-mono text-white">{hoverInfo.x.toFixed(2)} m</span>
                            <span>{t('hillVisualizer.coordinateZ')}</span>
                            <span className="font-mono text-white">{hoverInfo.z.toFixed(2)} m</span>
                            <span>{hoverInfo.label}</span>
                            <span className="font-mono text-amber-400">
                                {hoverInfo.value !== null
                                    ? typeof hoverInfo.value === 'number' && !Number.isInteger(hoverInfo.value)
                                        ? hoverInfo.value.toFixed(4)
                                        : String(hoverInfo.value)
                                    : '—'}
                            </span>
                        </div>
                    </div>
                )}

                {/* Legend */}
                <div className="absolute bottom-4 left-4 bg-slate-800/90 backdrop-blur-sm p-3 rounded-lg border border-slate-700 min-w-[140px] max-w-[180px]">
                    <div className="text-xs font-medium text-slate-400 mb-2 uppercase tracking-wide">
                        {t((LAYERS.find((l) => l.key === activeLayer) ?? LAYERS[0]).label)}
                    </div>
                    {renderLegend()}
                </div>

                {/* Grid info */}
                {mesh && (
                    <div className="absolute bottom-4 right-4 text-xs text-slate-600 pointer-events-none text-right">
                        {mesh.n_columns} × {mesh.n_layers} nodes
                    </div>
                )}
            </div>
        </div>
    );
};
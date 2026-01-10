// src/App.tsx
import { useState } from 'react';
import { Loader2, Upload, AlertCircle } from 'lucide-react';
import { useProject } from './hooks/useProject';
import { OverviewPanel } from './components/panels/OverviewPanel';
import { SoilPanel } from './components/panels/SoilPanel';
import { HillsPanel } from './components/panels/HillsPanel';
// New imports
import { ForcingPanel } from './components/panels/ForcingPanel';
import { ExportPanel } from './components/panels/ExportPanel';
import { ConfigPanel } from './components/panels/ConfigPanel';

function App() {
  const { data: project, loading, error, loadProject } = useProject();
  const [activeTab, setActiveTab] = useState('overview');

  // Define tabs here for cleaner rendering
  const tabs = ['overview', 'config', 'soil', 'hills', 'forcing', 'export'];

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-900 via-blue-900 to-slate-900 text-white p-8">
      <div className="max-w-7xl mx-auto">

        {/* Header */}
        <div className="mb-8 flex justify-between items-center">
          <div>
            <h1 className="text-4xl font-bold bg-gradient-to-r from-blue-400 to-cyan-400 bg-clip-text text-transparent">
              CATFLOW
            </h1>
            <p className="text-slate-400 mt-2">Hydrological Data Vis Stuff</p>
          </div>

          {!project && (
            <button
              onClick={() => loadProject('IN_TEMPLATE')}
              disabled={loading}
              className="px-6 py-3 bg-gradient-to-r from-blue-500 to-cyan-500 rounded-lg font-semibold hover:shadow-lg transition-all flex items-center gap-2"
            >
              {loading ? <Loader2 className="animate-spin" /> : <Upload />}
              {loading ? 'Loading...' : 'Load Project'}
            </button>
          )}
        </div>

        {/* Error Banner */}
        {error && (
          <div className="mb-6 bg-red-500/20 border border-red-500 rounded-lg p-4 flex items-center gap-3">
            <AlertCircle className="text-red-400" />
            <span className="text-red-200">{error}</span>
          </div>
        )}

        {/* Main Content */}
        {project && (
          <>
            {/* Tabs */}
            <div className="flex gap-2 mb-6 bg-slate-800/50 p-2 rounded-lg backdrop-blur-sm overflow-x-auto">
              {tabs.map(tab => (
                <button
                  key={tab}
                  onClick={() => setActiveTab(tab)}
                  className={`px-6 py-3 rounded-lg font-medium transition-all whitespace-nowrap ${activeTab === tab
                    ? 'bg-blue-600 shadow-lg text-white'
                    : 'hover:bg-slate-700/50 text-slate-300'
                    }`}
                >
                  {tab.charAt(0).toUpperCase() + tab.slice(1)}
                </button>
              ))}
            </div>

            {/* Panel Rendering */}
            <div className="animate-in fade-in duration-300">
              {activeTab === 'overview' && <OverviewPanel project={project} />}
              {activeTab === 'config' && <ConfigPanel project={project} />}
              {activeTab === 'soil' && <SoilPanel soils={project.soils} />}
              {activeTab === 'hills' && <HillsPanel hills={project.hills} />}
              {activeTab === 'forcing' && <ForcingPanel forcing={project.forcing} />}
              {activeTab === 'export' && <ExportPanel />}
            </div>
          </>
        )}
      </div>
    </div>
  );
}

export default App;

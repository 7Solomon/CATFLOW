import { useState } from 'react';
import { Loader2, Upload, AlertCircle } from 'lucide-react';
import { useProject } from './hooks/useProject';
import { OverviewPanel } from './components/panels/OverviewPanel';
import { SoilPanel } from './components/panels/SoilPanel';
import { HillsPanel } from './components/panels/HillsPanel';
import { ForcingPanel } from './components/panels/ForcingPanel';
import { ExportPanel } from './components/panels/ExportPanel';
import { ConfigPanel } from './components/panels/ConfigPanel';
import { LoadProjectModal } from './components/modals/LoadprojectModal';

function App() {
  const { data: project, loading, error, loadProject } = useProject();
  const [activeTab, setActiveTab] = useState('overview');
  const [isLoadModalOpen, setIsLoadModalOpen] = useState(false); // State for modal

  const tabs = ['overview', 'config', 'soil', 'hills', 'forcing', 'export'];

  const handleProjectSelect = (path: string) => {
    loadProject(path);
    setIsLoadModalOpen(false);
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-900 via-blue-900 to-slate-900 text-white p-8">
      <div className="max-w-7xl mx-auto">

        {/* Modal */}
        <LoadProjectModal
          isOpen={isLoadModalOpen}
          onClose={() => setIsLoadModalOpen(false)}
          onLoad={handleProjectSelect}
        />

        {/* Header */}
        <div className="mb-8 flex justify-between items-center">
          <div>
            <h1 className="text-4xl font-bold bg-gradient-to-r from-blue-400 to-cyan-400 bg-clip-text text-transparent">
              CATFLOW
            </h1>
            <p className="text-slate-400 mt-2">Hydrological Data Vis Stuff</p>
          </div>

          <button
            onClick={() => setIsLoadModalOpen(true)} // Open modal instead of direct load
            disabled={loading}
            className="px-6 py-3 bg-gradient-to-r from-blue-500 to-cyan-500 rounded-lg font-semibold hover:shadow-lg transition-all flex items-center gap-2 disabled:opacity-50 disabled:cursor-not-allowed"
          >
            {loading ? <Loader2 className="animate-spin" /> : <Upload />}
            {loading ? 'Loading...' : (project ? 'Switch Project' : 'Load Project')}
          </button>
        </div>

        {/* Error Banner */}
        {error && (
          <div className="mb-6 bg-red-500/20 border border-red-500 rounded-lg p-4 flex items-center gap-3 animate-in fade-in slide-in-from-top-4">
            <AlertCircle className="text-red-400" />
            <span className="text-red-200">{error}</span>
          </div>
        )}

        {/* Main Content */}
        {project && (
          <>
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

        {!project && !loading && (
          <div className="flex flex-col items-center justify-center h-[60vh] text-slate-500 border-2 border-dashed border-slate-700 rounded-3xl bg-slate-800/20">
            <Upload size={64} className="mb-6 opacity-20" />
            <h2 className="text-2xl font-semibold mb-2">No Project Loaded</h2>
            <p className="mb-8">Select a template folder to begin visualization</p>
            <button
              onClick={() => setIsLoadModalOpen(true)}
              className="px-8 py-3 bg-slate-800 hover:bg-slate-700 rounded-full font-medium transition-colors border border-slate-600 hover:border-indigo-400 hover:text-indigo-300"
            >
              Browse Projects
            </button>
          </div>
        )}
      </div>
    </div>
  );
}

export default App;

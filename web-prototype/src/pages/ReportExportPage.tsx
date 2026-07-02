import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { ChevronLeft, FileText, Download, Calendar, Filter, Check, Clock } from 'lucide-react'

interface ExportHistoryItem {
  id: string
  type: string
  dateRange: string
  exportTime: string
  format: string
  size: string
  status: string
}

const reportTypes = [
  { id: 'weekly', name: '周报告', desc: '最近7天的行为数据汇总' },
  { id: 'monthly', name: '月报告', desc: '最近30天的行为数据汇总' },
  { id: 'behavior', name: '行为分析', desc: '详细的行为模式分析报告' },
  { id: 'agenda', name: '事程统计', desc: '事程完成情况统计报告' },
]

const exportFormats = [
  { id: 'pdf', name: 'PDF', icon: '📄' },
  { id: 'excel', name: 'Excel', icon: '📊' },
  { id: 'word', name: 'Word', icon: '📝' },
]

const ReportExportPage = () => {
  const navigate = useNavigate()
  const [selectedType, setSelectedType] = useState('weekly')
  const [selectedFormat, setSelectedFormat] = useState('pdf')
  const [exportHistory, setExportHistory] = useState<ExportHistoryItem[]>([
    { id: '1', type: '周报告', dateRange: '2026/06/23 - 2026/06/29', exportTime: '2026/06/30 08:30', format: 'PDF', size: '2.3 MB', status: '已完成' },
    { id: '2', type: '月报告', dateRange: '2026/06/01 - 2026/06/30', exportTime: '2026/07/01 09:15', format: 'PDF', size: '8.7 MB', status: '已完成' },
    { id: '3', type: '行为分析', dateRange: '2026/06/01 - 2026/06/30', exportTime: '2026/07/01 10:00', format: 'Excel', size: '1.2 MB', status: '处理中' },
  ])

  // 开关状态
  const [includeCharts, setIncludeCharts] = useState(true)
  const [includeTimeline, setIncludeTimeline] = useState(true)
  const [anonymize, setAnonymize] = useState(false)

  // 导出状态
  const [exporting, setExporting] = useState(false)
  const [exportSuccess, setExportSuccess] = useState(false)

  const handleExport = () => {
    setExporting(true)
    setTimeout(() => {
      setExporting(false)
      setExportSuccess(true)
      const now = new Date()
      const newItem: ExportHistoryItem = {
        id: `exp-${Date.now()}`,
        type: reportTypes.find(t => t.id === selectedType)?.name || '报告',
        dateRange: '2026/07/01 - 2026/07/07',
        exportTime: `${now.getFullYear()}/${String(now.getMonth() + 1).padStart(2, '0')}/${String(now.getDate()).padStart(2, '0')} ${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}`,
        format: exportFormats.find(f => f.id === selectedFormat)?.name || 'PDF',
        size: `${(Math.random() * 5 + 1).toFixed(1)} MB`,
        status: '已完成',
      }
      setExportHistory(prev => [newItem, ...prev])
      setTimeout(() => setExportSuccess(false), 2000)
    }, 1500)
  }

  return (
    <div className="page-enter min-h-screen bg-bg-primary pb-24">
      <header className="px-4 py-3 bg-bg-secondary border-b border-border flex items-center justify-between sticky top-0 z-40">
        <button className="w-8 h-8 flex items-center justify-center text-text-primary transition-fast active:opacity-60" onClick={() => navigate(-1)}><ChevronLeft size={24} /></button>
        <h1 className="text-body font-semibold text-text-primary">报告导出</h1>
        <div className="w-8 h-8" />
      </header>

      <section className="px-4 mt-4">
        <div className="px-1 py-2 flex items-center gap-2">
          <FileText size={16} className="text-accent" />
          <h2 className="text-body-small font-semibold text-text-secondary">选择报告类型</h2>
        </div>
        <div className="space-y-2">
          {reportTypes.map((type) => (
            <button key={type.id} onClick={() => setSelectedType(type.id)} className={`w-full p-4 rounded-lg transition-fast text-left ${selectedType === type.id ? 'bg-accent-light border-2 border-accent' : 'bg-bg-secondary card-shadow'}`}>
              <div className="flex items-center justify-between">
                <div>
                  <div className="text-body-small font-medium text-text-primary">{type.name}</div>
                  <div className="text-caption text-text-tertiary mt-1">{type.desc}</div>
                </div>
                {selectedType === type.id && <Check size={20} className="text-accent" />}
              </div>
            </button>
          ))}
        </div>
      </section>

      <section className="px-4 mt-6">
        <div className="px-1 py-2 flex items-center gap-2">
          <Calendar size={16} className="text-accent" />
          <h2 className="text-body-small font-semibold text-text-secondary">时间范围</h2>
        </div>
        <div className="bg-bg-secondary rounded-lg card-shadow p-4">
          <div className="flex items-center justify-between">
            <div>
              <div className="text-caption text-text-secondary mb-1">开始日期</div>
              <div className="text-body-small font-medium text-text-primary">2026/06/23</div>
            </div>
            <div className="w-8 h-px bg-border" />
            <div>
              <div className="text-caption text-text-secondary mb-1">结束日期</div>
              <div className="text-body-small font-medium text-text-primary">2026/06/29</div>
            </div>
            <Calendar size={20} className="text-accent" />
          </div>
        </div>
      </section>

      <section className="px-4 mt-6">
        <div className="px-1 py-2 flex items-center gap-2">
          <Download size={16} className="text-accent" />
          <h2 className="text-body-small font-semibold text-text-secondary">导出格式</h2>
        </div>
        <div className="flex gap-3">
          {exportFormats.map((format) => (
            <button key={format.id} onClick={() => setSelectedFormat(format.id)} className={`flex-1 p-4 rounded-lg transition-fast ${selectedFormat === format.id ? 'bg-accent-light border-2 border-accent' : 'bg-bg-secondary card-shadow'}`}>
              <div className="text-2xl mb-2">{format.icon}</div>
              <div className={`text-caption font-medium ${selectedFormat === format.id ? 'text-accent' : 'text-text-primary'}`}>{format.name}</div>
            </button>
          ))}
        </div>
      </section>

      <section className="px-4 mt-6">
        <div className="px-1 py-2 flex items-center gap-2">
          <Filter size={16} className="text-accent" />
          <h2 className="text-body-small font-semibold text-text-secondary">导出选项</h2>
        </div>
        <div className="bg-bg-secondary rounded-lg card-shadow overflow-hidden">
          <div className="p-4 border-b border-border">
            <div className="flex items-center justify-between">
              <div>
                <div className="text-body-small font-medium text-text-primary">包含图表</div>
                <div className="text-caption text-text-tertiary mt-1">在报告中包含数据可视化图表</div>
              </div>
              <button onClick={() => setIncludeCharts(!includeCharts)} className={`relative w-11 h-6 rounded-full transition-fast ${includeCharts ? 'bg-success' : 'bg-bg-tertiary'}`}>
                <div className={`absolute top-0.5 w-5 h-5 bg-white rounded-full shadow-sm transition-fast ${includeCharts ? 'left-[22px]' : 'left-0.5'}`} />
              </button>
            </div>
          </div>
          <div className="p-4 border-b border-border">
            <div className="flex items-center justify-between">
              <div>
                <div className="text-body-small font-medium text-text-primary">包含时间线</div>
                <div className="text-caption text-text-tertiary mt-1">导出详细的时间线记录</div>
              </div>
              <button onClick={() => setIncludeTimeline(!includeTimeline)} className={`relative w-11 h-6 rounded-full transition-fast ${includeTimeline ? 'bg-success' : 'bg-bg-tertiary'}`}>
                <div className={`absolute top-0.5 w-5 h-5 bg-white rounded-full shadow-sm transition-fast ${includeTimeline ? 'left-[22px]' : 'left-0.5'}`} />
              </button>
            </div>
          </div>
          <div className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <div className="text-body-small font-medium text-text-primary">脱敏处理</div>
                <div className="text-caption text-text-tertiary mt-1">隐藏敏感信息保护隐私</div>
              </div>
              <button onClick={() => setAnonymize(!anonymize)} className={`relative w-11 h-6 rounded-full transition-fast ${anonymize ? 'bg-success' : 'bg-bg-tertiary'}`}>
                <div className={`absolute top-0.5 w-5 h-5 bg-white rounded-full shadow-sm transition-fast ${anonymize ? 'left-[22px]' : 'left-0.5'}`} />
              </button>
            </div>
          </div>
        </div>
      </section>

      <section className="px-4 mt-6">
        <div className="px-1 py-2 flex items-center gap-2">
          <Clock size={16} className="text-accent" />
          <h2 className="text-body-small font-semibold text-text-secondary">导出历史</h2>
        </div>
        <div className="bg-bg-secondary rounded-lg card-shadow overflow-hidden">
          {exportHistory.map((item, index) => (
            <div key={item.id} className={`p-4 ${index < exportHistory.length - 1 ? 'border-b border-border' : ''}`}>
              <div className="flex items-start justify-between">
                <div className="flex-1">
                  <div className="flex items-center gap-2">
                    <span className="text-body-small font-medium text-text-primary">{item.type}</span>
                    <span className={`px-2 py-0.5 rounded-sm text-caption ${item.status === '已完成' ? 'bg-success-light text-success' : 'bg-warning-light text-warning'}`}>{item.status}</span>
                  </div>
                  <div className="text-caption text-text-secondary mt-1">{item.dateRange}</div>
                  <div className="flex items-center gap-3 mt-2 text-caption text-text-tertiary">
                    <span>{item.format}</span>
                    <span>{item.size}</span>
                    <span>{item.exportTime}</span>
                  </div>
                </div>
                {item.status === '已完成' && (
                  <button className="px-3 py-1.5 bg-accent-light rounded-md text-accent text-caption font-medium transition-fast active:bg-accent/10">下载</button>
                )}
              </div>
            </div>
          ))}
        </div>
      </section>

      <div className="sticky bottom-0 left-0 right-0 bg-bg-secondary border-t border-border px-4 py-3 z-40 safe-area-bottom">
        <button className="w-full py-3 bg-accent rounded-md text-white text-body-small font-medium transition-fast active:bg-text-primary button-shadow flex items-center justify-center gap-2" onClick={handleExport} disabled={exporting}>
          {exporting ? (
            <>
              <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
              生成中...
            </>
          ) : exportSuccess ? (
            <>
              <Check size={18} />
              导出成功
            </>
          ) : (
            <>
              <Download size={18} />
              生成并导出报告
            </>
          )}
        </button>
      </div>
    </div>
  )
}

export default ReportExportPage

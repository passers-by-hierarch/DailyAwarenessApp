import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { ChevronLeft, Calendar, TrendingUp, Clock, Target, Activity, BarChart2, ArrowUp, ArrowDown, Filter } from 'lucide-react'

// 行为分析 mock 数据
const behaviorAnalysis = {
  behaviorType: '喝水',
  period: '2026/06/01 - 2026/06/30',
  totalRecords: 89,
  avgDaily: 2.97,
  avgDailyChange: 12,
  peakTime: '10:00-12:00',
  completionRate: 95,
  completionChange: 5,
  trend: [
    { week: '第1周', count: 18 },
    { week: '第2周', count: 22 },
    { week: '第3周', count: 24 },
    { week: '第4周', count: 25 },
  ],
  timeDistribution: [
    { period: '06:00-09:00', count: 15, percentage: 17 },
    { period: '09:00-12:00', count: 32, percentage: 36 },
    { period: '12:00-15:00', count: 18, percentage: 20 },
    { period: '15:00-18:00', count: 14, percentage: 16 },
    { period: '18:00-21:00', count: 10, percentage: 11 },
  ],
  relatedAgendas: [
    { id: '1', content: '早上喝水', time: '08:00', completed: 28, total: 30 },
    { id: '2', content: '午餐后喝水', time: '13:00', completed: 26, total: 30 },
    { id: '3', content: '下午喝水', time: '16:00', completed: 22, total: 30 },
  ],
  suggestions: [
    '建议在下午增加一次喝水提醒',
    '晚上喝水时间可以适当提前',
    '保持当前良好的饮水习惯',
  ],
}

const BehaviorAnalysisPage = () => {
  const navigate = useNavigate()
  const [selectedPeriod, setSelectedPeriod] = useState('month')

  return (
    <div className="page-enter min-h-screen bg-bg-primary pb-8">
      {/* 顶部导航栏 */}
      <header className="px-4 py-3 bg-bg-secondary border-b border-border flex items-center justify-between sticky top-0 z-40">
        <button
          className="w-8 h-8 flex items-center justify-center text-text-primary transition-fast active:opacity-60"
          onClick={() => navigate(-1)}
        >
          <ChevronLeft size={24} />
        </button>
        <h1 className="text-body font-semibold text-text-primary">行为详情分析</h1>
        <button className="w-8 h-8 flex items-center justify-center text-text-primary transition-fast active:opacity-60">
          <Filter size={20} />
        </button>
      </header>

      {/* 行为类型头部 */}
      <section className="px-4 pt-4">
        <div className="bg-gradient-to-br from-info to-info/80 rounded-xl p-4 text-white">
          <div className="flex items-center justify-between mb-3">
            <div className="flex items-center gap-2">
              <Activity size={20} />
              <span className="text-body font-medium">{behaviorAnalysis.behaviorType}</span>
            </div>
            <div className="flex gap-2">
              {['week', 'month'].map((period) => (
                <button
                  key={period}
                  onClick={() => setSelectedPeriod(period)}
                  className={`px-3 py-1 rounded-md text-caption transition-fast ${
                    selectedPeriod === period
                      ? 'bg-white text-info'
                      : 'bg-white/20 text-white'
                  }`}
                >
                  {period === 'week' ? '本周' : '本月'}
                </button>
              ))}
            </div>
          </div>

          <div className="text-caption opacity-80">{behaviorAnalysis.period}</div>

          {/* 核心指标 */}
          <div className="grid grid-cols-3 gap-3 mt-4 pt-4 border-t border-white/20">
            <div className="text-center">
              <div className="text-h3 font-semibold">{behaviorAnalysis.totalRecords}</div>
              <div className="text-caption opacity-80 mt-1">总次数</div>
            </div>
            <div className="text-center">
              <div className="text-h3 font-semibold">{behaviorAnalysis.avgDaily}</div>
              <div className="text-caption opacity-80 mt-1">日均次数</div>
            </div>
            <div className="text-center">
              <div className="text-h3 font-semibold">{behaviorAnalysis.completionRate}%</div>
              <div className="text-caption opacity-80 mt-1">完成率</div>
            </div>
          </div>
        </div>
      </section>

      {/* 变化趋势 */}
      <section className="px-4 mt-6">
        <div className="px-1 py-2 flex items-center gap-2">
          <TrendingUp size={16} className="text-accent" />
          <h2 className="text-body-small font-semibold text-text-secondary">变化趋势</h2>
        </div>

        <div className="bg-bg-secondary rounded-lg card-shadow p-4">
          <div className="flex items-end justify-around h-32 mb-2">
            {behaviorAnalysis.trend.map((item, index) => (
              <div key={index} className="flex flex-col items-center gap-1">
                <div className="text-caption text-accent font-medium">{item.count}</div>
                <div
                  className="w-12 bg-info/30 rounded-t transition-all"
                  style={{ height: `${(item.count / 30) * 100}%` }}
                />
              </div>
            ))}
          </div>
          <div className="flex justify-around text-caption text-text-tertiary mt-2">
            {behaviorAnalysis.trend.map((item) => (
              <span key={item.week}>{item.week}</span>
            ))}
          </div>
        </div>
      </section>

      {/* 时间分布 */}
      <section className="px-4 mt-6">
        <div className="px-1 py-2 flex items-center gap-2">
          <Clock size={16} className="text-accent" />
          <h2 className="text-body-small font-semibold text-text-secondary">时间分布</h2>
        </div>

        <div className="bg-bg-secondary rounded-lg card-shadow p-4">
          <div className="space-y-3">
            {behaviorAnalysis.timeDistribution.map((item, index) => (
              <div key={index}>
                <div className="flex items-center justify-between mb-1.5">
                  <span className="text-body-small text-text-primary">{item.period}</span>
                  <span className="text-body-small font-medium text-accent">{item.percentage}%</span>
                </div>
                <div className="h-2 bg-bg-tertiary rounded-full overflow-hidden">
                  <div
                    className="h-full bg-info rounded-full transition-all"
                    style={{ width: `${item.percentage}%` }}
                  />
                </div>
                <div className="text-caption text-text-tertiary mt-1">{item.count}次</div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* 统计对比 */}
      <section className="px-4 mt-6">
        <div className="px-1 py-2 flex items-center gap-2">
          <BarChart2 size={16} className="text-accent" />
          <h2 className="text-body-small font-semibold text-text-secondary">统计对比</h2>
        </div>

        <div className="grid grid-cols-2 gap-3">
          <div className="bg-bg-secondary rounded-lg card-shadow p-4">
            <div className="flex items-center justify-between mb-2">
              <span className="text-caption text-text-secondary">日均次数</span>
              {behaviorAnalysis.avgDailyChange > 0 ? (
                <ArrowUp size={14} className="text-success" />
              ) : (
                <ArrowDown size={14} className="text-danger" />
              )}
            </div>
            <div className="text-h3 font-semibold text-text-primary">{behaviorAnalysis.avgDaily}</div>
            <div className={`text-caption mt-1 ${
              behaviorAnalysis.avgDailyChange > 0 ? 'text-success' : 'text-danger'
            }`}>
              较上期 {behaviorAnalysis.avgDailyChange > 0 ? '+' : ''}{behaviorAnalysis.avgDailyChange}%
            </div>
          </div>

          <div className="bg-bg-secondary rounded-lg card-shadow p-4">
            <div className="flex items-center justify-between mb-2">
              <span className="text-caption text-text-secondary">完成率</span>
              {behaviorAnalysis.completionChange > 0 ? (
                <ArrowUp size={14} className="text-success" />
              ) : (
                <ArrowDown size={14} className="text-danger" />
              )}
            </div>
            <div className="text-h3 font-semibold text-text-primary">{behaviorAnalysis.completionRate}%</div>
            <div className={`text-caption mt-1 ${
              behaviorAnalysis.completionChange > 0 ? 'text-success' : 'text-danger'
            }`}>
              较上期 {behaviorAnalysis.completionChange > 0 ? '+' : ''}{behaviorAnalysis.completionChange}%
            </div>
          </div>
        </div>
      </section>

      {/* 关联事程 */}
      <section className="px-4 mt-6">
        <div className="px-1 py-2 flex items-center gap-2">
          <Target size={16} className="text-accent" />
          <h2 className="text-body-small font-semibold text-text-secondary">关联事程</h2>
        </div>

        <div className="bg-bg-secondary rounded-lg card-shadow overflow-hidden">
          {behaviorAnalysis.relatedAgendas.map((agenda, index) => (
            <div
              key={agenda.id}
              className={`p-4 ${index < behaviorAnalysis.relatedAgendas.length - 1 ? 'border-b border-border' : ''}`}
            >
              <div className="flex items-center justify-between mb-2">
                <div className="flex items-center gap-2">
                  <span className="text-time font-mono text-text-secondary">{agenda.time}</span>
                  <span className="text-body-small font-medium text-text-primary">{agenda.content}</span>
                </div>
                <span className={`px-2 py-0.5 rounded-sm text-caption ${
                  agenda.completed / agenda.total >= 0.9 ? 'bg-success-light text-success' : 'bg-warning-light text-warning'
                }`}>
                  {Math.round((agenda.completed / agenda.total) * 100)}%
                </span>
              </div>
              <div className="h-1.5 bg-bg-tertiary rounded-full overflow-hidden">
                <div
                  className="h-full bg-accent rounded-full transition-all"
                  style={{ width: `${(agenda.completed / agenda.total) * 100}%` }}
                />
              </div>
              <div className="text-caption text-text-tertiary mt-1">
                完成 {agenda.completed}/{agenda.total} 次
              </div>
            </div>
          ))}
        </div>
      </section>

      {/* 改进建议 */}
      <section className="px-4 mt-6">
        <div className="px-1 py-2 flex items-center gap-2">
          <Activity size={16} className="text-accent" />
          <h2 className="text-body-small font-semibold text-text-secondary">改进建议</h2>
        </div>

        <div className="bg-bg-secondary rounded-lg card-shadow p-4">
          <div className="space-y-3">
            {behaviorAnalysis.suggestions.map((suggestion, index) => (
              <div key={index} className="flex items-start gap-2">
                <div className="w-6 h-6 bg-info-light rounded-md flex items-center justify-center shrink-0">
                  <span className="text-caption text-info font-medium">{index + 1}</span>
                </div>
                <span className="text-body-small text-text-primary leading-relaxed">{suggestion}</span>
              </div>
            ))}
          </div>
        </div>
      </section>
    </div>
  )
}

export default BehaviorAnalysisPage
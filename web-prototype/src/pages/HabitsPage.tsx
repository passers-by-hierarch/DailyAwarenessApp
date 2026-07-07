import { useNavigate } from 'react-router-dom'
import { ChevronRight, FileText } from 'lucide-react'
import TagShowcase from '../components/TagShowcase'
import { mockStatsData, mockSuggestions } from '../data/mockData'

const HabitsPage = () => {
  const navigate = useNavigate()

  return (
    <div className="page-enter">
      {/* 顶部导航 */}
      <header className="px-4 py-4 bg-bg-primary flex justify-between items-center">
        <h1 className="text-title-medium font-semibold text-text-primary">习惯</h1>
      </header>

      {/* 时间范围选择 */}
      <div className="px-4 py-2 flex gap-4 items-center">
        <button className="text-body-small font-medium text-accent border-b-2 border-accent pb-1">
          本周
        </button>
        <button className="text-body-small font-medium text-text-secondary">
          本月
        </button>
        <button className="text-body-small font-medium text-text-secondary">
          自定义
        </button>
        <button
          className="ml-auto text-body-small font-medium text-info flex items-center gap-1 transition-fast active:opacity-60"
          onClick={() => navigate('/weekly-report')}
        >
          <FileText size={14} />
          周报详情
        </button>
      </div>

      {/* 核心指标卡 */}
      <div className="px-4 mt-2">
        <div className="bg-bg-secondary rounded-lg card-shadow p-5 text-center">
          <div className="text-body-small text-text-secondary mb-2">本周完成率</div>
          <div className="text-stat-large text-accent font-semibold">
            {mockStatsData.completionRate}%
          </div>
          <div className="flex items-center justify-center gap-1 mt-2">
            <span className="text-success font-medium">↑{mockStatsData.trendValue}%</span>
          </div>
          <div className="text-body-small text-text-secondary mt-1">
            较上周提升{mockStatsData.trendValue}个百分点
          </div>
        </div>
      </div>

      {/* 热力图 */}
      <section className="mt-4">
        <div className="px-4 py-2 flex items-center gap-2">
          <div className="w-1.5 h-1.5 bg-accent rounded-full" />
          <h2 className="text-body-small font-semibold text-text-secondary">近7天完成热力图</h2>
        </div>

        <div className="px-4">
          <div className="bg-bg-secondary rounded-lg card-shadow p-4">
            <div className="space-y-3">
              {mockStatsData.heatmap.map((row, rowIndex) => (
                <div key={rowIndex} className="flex items-center gap-2">
                  <div className="w-14 text-body-small text-text-primary">
                    {mockStatsData.heatmapLabels[rowIndex]}
                  </div>
                  <div className="flex gap-1">
                    {row.map((completed, colIndex) => (
                      <div
                        key={colIndex}
                        className={`w-9 h-6 rounded-sm ${
                          completed ? 'bg-success' : 'bg-bg-tertiary'
                        }`}
                      />
                    ))}
                  </div>
                </div>
              ))}
            </div>

            <div className="flex gap-1 mt-3 ml-14">
              {mockStatsData.heatmapDays.map((day) => (
                <div key={day} className="w-9 text-caption text-text-tertiary text-center">
                  {day}
                </div>
              ))}
            </div>
          </div>
        </div>
      </section>

      {/* 行为排行 */}
      <section className="mt-4">
        <div className="px-4 py-2 flex items-center gap-2">
          <div className="w-1.5 h-1.5 bg-accent rounded-full" />
          <h2 className="text-body-small font-semibold text-text-secondary">行为排行</h2>
        </div>

        <div className="px-4">
          <button
            className="w-full bg-bg-secondary rounded-lg card-shadow p-4 mb-2 transition-fast active:bg-bg-tertiary"
            onClick={() => navigate('/behavior-analysis/1')}
          >
            <div className="flex justify-between items-center">
              <span className="text-body-small font-semibold text-text-secondary">最规律行为</span>
              <div className="flex items-center gap-2">
                <span className="text-body font-medium text-text-primary">{mockStatsData.topRegular.name}</span>
                <span className="text-body-small font-mono text-success">{mockStatsData.topRegular.count} ✓</span>
                <ChevronRight size={16} className="text-text-tertiary" />
              </div>
            </div>
          </button>

          <button
            className="w-full bg-bg-secondary rounded-lg card-shadow p-4 transition-fast active:bg-bg-tertiary"
            onClick={() => navigate('/behavior-analysis/2')}
          >
            <div className="flex justify-between items-center">
              <span className="text-body-small font-semibold text-text-secondary">最易遗漏</span>
              <div className="flex items-center gap-2">
                <span className="text-body font-medium text-text-primary">{mockStatsData.topMissed.name}</span>
                <span className="text-body-small font-mono text-warning">{mockStatsData.topMissed.count} ⚠</span>
                <ChevronRight size={16} className="text-text-tertiary" />
              </div>
            </div>
          </button>
        </div>
      </section>

      {/* 标签集锦区块 */}
      <TagShowcase />

      {/* 策略优化建议 */}
      <section className="mt-4">
        <div className="px-4 py-2 flex items-center gap-2">
          <div className="w-1.5 h-1.5 bg-accent rounded-full" />
          <h2 className="text-body-small font-semibold text-text-secondary">策略优化建议</h2>
        </div>

        <div className="px-4">
          {mockSuggestions.map((suggestion) => (
            <div key={suggestion.id} className="bg-bg-secondary rounded-lg card-shadow p-4 mb-2">
              <div className="text-body-small text-text-secondary mb-2">
                💡 发现：{suggestion.discovery}
              </div>
              <div className="text-body font-medium text-text-primary mb-3">
                建议：{suggestion.suggestion}
              </div>
              <div className="flex gap-2">
                <button className="px-6 py-2 rounded-md bg-accent text-white text-body-small font-medium transition-fast active:bg-text-primary">
                  ✓ 接受
                </button>
                <button className="px-6 py-2 rounded-md bg-bg-tertiary text-text-secondary text-body-small font-medium transition-fast active:bg-border">
                  ✗ 忽略
                </button>
              </div>
            </div>
          ))}
        </div>
      </section>

      {/* 底部留白 */}
      <div className="h-8" />
    </div>
  )
}

export default HabitsPage

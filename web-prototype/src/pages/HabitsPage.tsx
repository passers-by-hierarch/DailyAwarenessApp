import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { ChevronRight, Plus, FileText } from 'lucide-react'
import AgendaItem from '../components/AgendaItem'
import CreateAgendaModal from '../components/CreateAgendaModal'
import TagShowcase from '../components/TagShowcase'
import { mockStatsData, mockSuggestions } from '../data/mockData'
import { useAppStore } from '../store/appStore'

const HabitsPage = () => {
  const navigate = useNavigate()
  const [activeTab, setActiveTab] = useState<'agenda' | 'stats'>('agenda')
  const [selectedDate, setSelectedDate] = useState(2)
  const [showCreateModal, setShowCreateModal] = useState(false)

  // 从 store 获取事程和常用事程
  const agendaItems = useAppStore(s => s.agendaItems)
  const frequentAgendas = useAppStore(s => s.frequentAgendas)
  const addAgenda = useAppStore(s => s.addAgenda)
  const deleteAgenda = useAppStore(s => s.deleteAgenda)
  
  // 日期选择器数据
  const dates = [
    { day: '29', label: '周六' },
    { day: '30', label: '周日' },
    { day: '1', label: '今天', isToday: true },
    { day: '2', label: '周三' },
    { day: '3', label: '周四' },
  ]
  
  return (
    <div className="page-enter">
      {/* 顶部导航 */}
      <header className="px-4 py-4 bg-bg-primary flex justify-between items-center">
        <h1 className="text-title-medium font-semibold text-text-primary">习惯</h1>
        <button 
          className="text-body-small font-medium text-info flex items-center gap-1"
          onClick={() => navigate('/frequent-agenda')}
        >
          常用事程
          <ChevronRight size={16} />
        </button>
      </header>
      
      {/* Segment切换 */}
      <div className="px-4 py-2">
        <div className="bg-bg-tertiary rounded-md p-1 flex">
          <button
            className={`flex-1 py-2.5 rounded-sm transition-fast ${
              activeTab === 'agenda'
                ? 'bg-bg-secondary text-accent font-semibold card-shadow'
                : 'text-text-secondary'
            }`}
            onClick={() => setActiveTab('agenda')}
          >
            事程
          </button>
          <button
            className={`flex-1 py-2.5 rounded-sm transition-fast ${
              activeTab === 'stats'
                ? 'bg-bg-secondary text-accent font-semibold card-shadow'
                : 'text-text-secondary'
            }`}
            onClick={() => setActiveTab('stats')}
          >
            统计
          </button>
        </div>
      </div>
      
      {/* 事程Tab */}
      {activeTab === 'agenda' && (
        <>
          {/* 视图切换 */}
          <div className="px-4 py-2 flex gap-4">
            <button className="text-body-small font-medium text-accent border-b-2 border-accent pb-1">
              日视图
            </button>
            <button className="text-body-small font-medium text-text-secondary">
              周视图
            </button>
          </div>
          
          {/* 日期选择器 */}
          <div className="px-4 py-2">
            <div className="flex items-center gap-2">
              <button className="w-6 h-6 flex items-center justify-center text-text-tertiary">
                ‹
              </button>
              
              <div className="flex gap-2 overflow-x-auto">
                {dates.map((date, index) => (
                  <button
                    key={index}
                    className={`px-3 py-2 rounded-md transition-fast ${
                      selectedDate === index
                        ? 'bg-accent-light text-accent font-semibold border-b-2 border-accent'
                        : 'text-text-secondary'
                    }`}
                    onClick={() => setSelectedDate(index)}
                  >
                    <div className="text-body-small">{date.day}</div>
                    <div className="text-caption text-text-tertiary">{date.label}</div>
                  </button>
                ))}
              </div>
              
              <button className="w-6 h-6 flex items-center justify-center text-text-tertiary">
                ›
              </button>
            </div>
          </div>
          
          {/* 事程列表 */}
          <div className="px-4 mt-2">
            {/* 已完成 */}
            <div className="text-caption text-text-tertiary mb-2">已完成 ({agendaItems.filter(a => a.status === 'completed').length})</div>
            {agendaItems
              .filter(a => a.status === 'completed')
              .map((agenda) => (
                <AgendaItem
                  key={agenda.id}
                  id={agenda.id}
                  time={agenda.time}
                  content={agenda.content}
                  note={agenda.note}
                  isMustDo={agenda.isMustDo}
                  status={agenda.status}
                  remainingTime={agenda.remainingTime}
                  onClick={() => navigate(`/agenda/${agenda.id}`)}
                  onDelete={deleteAgenda}
                />
              ))}

            {/* 待进行 */}
            <div className="text-caption text-text-tertiary mb-2 mt-4">待进行 ({agendaItems.filter(a => a.status === 'pending').length})</div>
            {agendaItems
              .filter(a => a.status === 'pending')
              .map((agenda) => (
                <AgendaItem
                  key={agenda.id}
                  id={agenda.id}
                  time={agenda.time}
                  content={agenda.content}
                  note={agenda.note}
                  isMustDo={agenda.isMustDo}
                  status={agenda.status}
                  remainingTime={agenda.remainingTime}
                  onClick={() => navigate(`/agenda/${agenda.id}`)}
                  onDelete={deleteAgenda}
                />
              ))}
          </div>
          
          {/* 悬浮创建按钮 */}
          <button 
            className="absolute bottom-6 right-4 w-14 h-14 bg-accent rounded-full fab-shadow flex items-center justify-center transition-fast active:scale-95 z-40"
            onClick={() => setShowCreateModal(true)}
          >
            <Plus size={28} className="text-white" />
          </button>
          
          {/* 创建事程弹窗 */}
          <CreateAgendaModal
            visible={showCreateModal}
            onClose={() => setShowCreateModal(false)}
            onSelect={(type) => {
              setShowCreateModal(false)
              if (type === 'frequent') navigate('/frequent-agenda')
              else if (type === 'voice' || type === 'text') navigate('/create-agenda')
            }}
          />
        </>
      )}
      
      {/* 统计Tab */}
      {activeTab === 'stats' && (
        <>
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
        </>
      )}
      
      {/* 底部留白 */}
      <div className="h-8" />
    </div>
  )
}

export default HabitsPage
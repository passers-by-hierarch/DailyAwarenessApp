import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import TimelineItem from '../components/TimelineItem'
import AgendaItem from '../components/AgendaItem'
import { useAppStore } from '../store/appStore'

type TabType = 'timeline' | 'agenda'

const HomePage = () => {
  const navigate = useNavigate()
  const [activeTab, setActiveTab] = useState<TabType>('timeline')

  // 从 store 获取实时数据
  const timelineRecords = useAppStore(s => s.timelineRecords)
  const agendaItems = useAppStore(s => s.agendaItems)
  const deleteAgenda = useAppStore(s => s.deleteAgenda)

  // 获取当前日期信息
  const now = new Date()
  const dateStr = `${now.getMonth() + 1}月${now.getDate()}日`
  const dayStr = ['星期日', '星期一', '星期二', '星期三', '星期四', '星期五', '星期六'][now.getDay()]

  // 计算完成率
  const completedCount = agendaItems.filter(a => a.status === 'completed').length
  const totalCount = agendaItems.length

  // 问候语
  const hour = now.getHours()
  let greeting = '早上好'
  if (hour >= 12 && hour < 18) greeting = '下午好'
  if (hour >= 18) greeting = '晚上好'

  const tabs: { key: TabType; label: string; count: number }[] = [
    { key: 'timeline', label: '时间线', count: timelineRecords.length },
    { key: 'agenda', label: '待办事程', count: agendaItems.filter(a => a.status === 'pending').length },
  ]

  return (
    <div className="page-enter flex flex-col h-full">
      {/* 顶部状态区 - 固定 */}
      <header className="px-4 py-4 bg-bg-primary shrink-0">
        <div className="flex justify-between items-start">
          <div>
            <h1 className="text-body font-semibold text-text-primary">
              {dateStr} {dayStr}
            </h1>
            <p className="text-body-small text-text-secondary mt-1">
              {greeting}，今天已完成{completedCount}项事程
            </p>
          </div>
          <div className="text-caption font-medium text-accent">
            今日 {completedCount}/{totalCount}
          </div>
        </div>
      </header>

      {/* Tab切换 - 固定 */}
      <div className="px-4 py-2 bg-bg-primary shrink-0">
        <div className="flex bg-bg-secondary rounded-lg p-1">
          {tabs.map((tab) => (
            <button
              key={tab.key}
              className={`flex-1 py-2 rounded-md text-body-small font-medium transition-fast ${
                activeTab === tab.key
                  ? 'bg-white text-text-primary shadow-sm'
                  : 'text-text-secondary'
              }`}
              onClick={() => setActiveTab(tab.key)}
            >
              {tab.label}
              {tab.count > 0 && (
                <span className={`ml-1.5 px-1.5 py-0.5 rounded-full text-caption ${
                  activeTab === tab.key ? 'bg-accent text-white' : 'bg-bg-tertiary text-text-tertiary'
                }`}>
                  {tab.count}
                </span>
              )}
            </button>
          ))}
        </div>
      </div>

      {/* Tab内容区 - 可滚动 */}
      <section className="flex-1 overflow-y-auto px-4 bg-bg-primary">
        {activeTab === 'timeline' && (
          <div className="pb-4">
            {timelineRecords.length === 0 ? (
              <div className="bg-bg-secondary rounded-lg card-shadow py-8 text-center">
                <div className="text-3xl mb-2">🎤</div>
                <div className="text-body-small text-text-secondary">点击下方语音按钮开始记录</div>
              </div>
            ) : (
              timelineRecords.map((record) => (
                <TimelineItem
                  key={record.id}
                  time={record.time}
                  content={record.content}
                  matchedAgenda={record.matchedAgenda}
                  status={record.status}
                  tags={record.tags}
                  onClick={() => navigate(`/timeline/${record.id}`)}
                />
              ))
            )}
          </div>
        )}

        {activeTab === 'agenda' && (
          <div className="pb-4">
            {agendaItems.filter(a => a.status === 'pending').length === 0 ? (
              <div className="bg-bg-secondary rounded-lg card-shadow py-8 text-center">
                <div className="text-3xl mb-2">✅</div>
                <div className="text-body-small text-text-secondary">暂无待办事程</div>
              </div>
            ) : (
              agendaItems
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
                ))
            )}
          </div>
        )}
      </section>
    </div>
  )
}

export default HomePage
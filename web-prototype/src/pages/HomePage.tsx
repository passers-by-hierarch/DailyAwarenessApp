import { useState, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import { ChevronDown, Calendar, ChevronLeft, ChevronRight, X, Plus, Bell, Check, Clock } from 'lucide-react'
import TimelineItem from '../components/TimelineItem'
import AgendaItem from '../components/AgendaItem'
import { useAppStore } from '../store/appStore'
import CreateAgendaModal from '../components/CreateAgendaModal'

type TabType = 'timeline' | 'agenda'

const ymd = (d: Date) =>
  `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`

// 生成本月日历网格（含上月末尾和下月开头的占位）
const genCalendarGrid = (year: number, month: number) => {
  // month: 0-11
  const firstDay = new Date(year, month, 1)
  const lastDay = new Date(year, month + 1, 0)
  const startWeekday = firstDay.getDay() // 0=周日
  const daysInMonth = lastDay.getDate()
  const cells: Array<{ day: number | null; date?: string }> = []
  // 前置空格
  for (let i = 0; i < startWeekday; i++) cells.push({ day: null })
  for (let d = 1; d <= daysInMonth; d++) {
    cells.push({ day: d, date: ymd(new Date(year, month, d)) })
  }
  return cells
}

const HomePage = () => {
  const navigate = useNavigate()
  const [activeTab, setActiveTab] = useState<TabType>('timeline')
  const [showCalendar, setShowCalendar] = useState(false)
  const [showCreateModal, setShowCreateModal] = useState(false)
  const todayYmd = (() => { const t = new Date(); return ymd(t) })()
  const [selectedDateKey, setSelectedDateKey] = useState(todayYmd)
  // 日历当前显示的月份
  const [calYear, setCalYear] = useState(() => new Date().getFullYear())
  const [calMonth, setCalMonth] = useState(() => new Date().getMonth())

  // 从 store 获取实时数据
  const timelineRecords = useAppStore(s => s.timelineRecords)
  const agendaItems = useAppStore(s => s.agendaItems)
  const deleteAgenda = useAppStore(s => s.deleteAgenda)
  const activeReminder = useAppStore(s => s.activeReminder)
  const dismissReminder = useAppStore(s => s.dismissReminder)
  const checkAgendaReminders = useAppStore(s => s.checkAgendaReminders)
  const completeAgenda = useAppStore(s => s.completeAgenda)
  const generateAgendaRecommendations = useAppStore(s => s.generateAgendaRecommendations)

  useEffect(() => {
    generateAgendaRecommendations()
  }, [generateAgendaRecommendations])

  useEffect(() => {
    const timer = setInterval(() => {
      checkAgendaReminders()
    }, 60000)
    checkAgendaReminders()
    return () => clearInterval(timer)
  }, [checkAgendaReminders])

  // 按选中日期过滤
  const dayTimelineRecords = timelineRecords.filter(r => r.date === selectedDateKey)
  const dayAgendaItems = agendaItems.filter(a => a.date === selectedDateKey)

  const isToday = selectedDateKey === todayYmd
  const today = new Date()

  // 选中日期的显示文本
  const selectedDateStr = (() => {
    const [y, m, d] = selectedDateKey.split('-')
    const dt = new Date(Number(y), Number(m) - 1, Number(d))
    const dow = ['星期日', '星期一', '星期二', '星期三', '星期四', '星期五', '星期六'][dt.getDay()]
    const prefix = isToday ? '今天 ' : ''
    return `${prefix}${Number(m)}月${Number(d)}日 ${dow}`
  })()

  // 事程分组
  const visibleAgendas = dayAgendaItems
  const nowMinutes = today.getHours() * 60 + today.getMinutes()

  const getEffectiveStatus = (agenda: typeof dayAgendaItems[0]) => {
    if (agenda.status === 'pending' && isToday) {
      const [h, m] = agenda.time.split(':').map(Number)
      if (h * 60 + m < nowMinutes) return 'expired'
    }
    return agenda.status
  }

  const pendingAgendas = visibleAgendas
    .filter(a => getEffectiveStatus(a) === 'pending')
    .sort((a, b) => a.time.localeCompare(b.time))
  const expiredAgendas = visibleAgendas
    .filter(a => getEffectiveStatus(a) === 'expired')
    .sort((a, b) => b.time.localeCompare(a.time))
  const completedAgendas = visibleAgendas.filter(a => a.status === 'completed')

  // 计算完成率
  const completedCount = visibleAgendas.filter(a => a.status === 'completed').length
  const totalCount = visibleAgendas.length

  // 问候语
  const hour = today.getHours()
  let greeting = '早上好'
  if (hour >= 12 && hour < 18) greeting = '下午好'
  if (hour >= 18) greeting = '晚上好'

  const tabs: { key: TabType; label: string; countLabel: string; count: number }[] = [
    { key: 'timeline', label: '时间线', countLabel: String(dayTimelineRecords.length), count: dayTimelineRecords.length },
    { key: 'agenda', label: '事程', countLabel: `${pendingAgendas.length}/${totalCount}`, count: totalCount },
  ]

  // 有记录的日期集合（用于日历显示）
  const datesWithRecords = (() => {
    const set = new Set<string>()
    timelineRecords.forEach(r => set.add(r.date))
    agendaItems.forEach(a => set.add(a.date))
    return set
  })()

  // 日历网格
  const calCells = genCalendarGrid(calYear, calMonth)
  const monthLabel = `${calYear}年${calMonth + 1}月`

  const prevMonth = () => {
    if (calMonth === 0) { setCalYear(y => y - 1); setCalMonth(11) }
    else setCalMonth(m => m - 1)
  }
  const nextMonth = () => {
    if (calMonth === 11) { setCalYear(y => y + 1); setCalMonth(0) }
    else setCalMonth(m => m + 1)
  }

  return (
    <div className="page-enter flex flex-col h-full">
      {/* 顶部状态区 - 固定，点击日期可展开日历 */}
      <header className="px-4 py-4 bg-bg-primary shrink-0">
        <div className="flex justify-between items-start">
          <button
            className="flex items-center gap-1.5 transition-fast active:opacity-60"
            onClick={() => setShowCalendar(true)}
          >
            <h1 className="text-body font-semibold text-text-primary">
              {selectedDateStr}
            </h1>
            <ChevronDown size={18} className="text-text-secondary" />
          </button>
          {isToday ? (
            <div className="text-caption font-medium text-accent">
              {totalCount > 0 ? `今日 ${completedCount}/${totalCount}` : '今日'}
            </div>
          ) : (
            <button
              className="text-caption font-medium text-accent active:opacity-60 transition-fast"
              onClick={() => setSelectedDateKey(todayYmd)}
            >
              回到今天
            </button>
          )}
        </div>
        {isToday && (
          <p className="text-body-small text-text-secondary mt-1">
            {greeting}，今天已完成{completedCount}项事程
          </p>
        )}
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
                  {tab.countLabel}
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
            {dayTimelineRecords.length === 0 ? (
              <div className="bg-bg-secondary rounded-lg card-shadow py-8 text-center mt-3">
                <div className="text-3xl mb-2">📭</div>
                <div className="text-body-small text-text-secondary">
                  {isToday ? '点击下方语音按钮开始记录' : '该日无时间线记录'}
                </div>
              </div>
            ) : (
              dayTimelineRecords.map((record) => (
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
            {/* 添加新事程按钮 */}
            {isToday && (
              <div className="pt-3">
                <button
                  className="w-full h-11 rounded-md bg-bg-secondary card-shadow flex items-center justify-center gap-2 transition-fast active:opacity-80"
                  onClick={() => setShowCreateModal(true)}
                >
                  <Plus size={18} className="text-accent" />
                  <span className="text-body-small font-medium text-text-primary">添加新事程</span>
                </button>
              </div>
            )}

            {/* 空状态 */}
            {dayAgendaItems.length === 0 ? (
              <div className="bg-bg-secondary rounded-lg card-shadow py-8 text-center mt-3">
                <div className="text-3xl mb-2">📭</div>
                <div className="text-body-small text-text-secondary">
                  {isToday ? '暂无今日事程' : '该日无事程记录'}
                </div>
                {isToday && (
                  <div className="text-caption text-text-tertiary mt-1">点击下方"+"添加新事程</div>
                )}
              </div>
            ) : (
              <>
                {/* 待进行 */}
                {pendingAgendas.length > 0 && (
                  <>
                    <div className="text-caption text-text-tertiary mt-3 mb-2 px-1">
                      待进行 ({pendingAgendas.length})
                    </div>
                    {pendingAgendas.map((agenda) => (
                      <AgendaItem
                        key={agenda.id}
                        id={agenda.id}
                        time={agenda.time}
                        content={agenda.content}
                        note={agenda.note}
                        isMustDo={agenda.isMustDo}
                        status={agenda.status}
                        remainingTime={agenda.remainingTime}
                        isHighFrequency={agenda.isHighFrequency}
                        onClick={() => navigate(`/agenda/${agenda.id}`)}
                        onDelete={deleteAgenda}
                      />
                    ))}
                  </>
                )}

                {/* 已过期 */}
                {expiredAgendas.length > 0 && (
                  <>
                    <div className="text-caption text-text-tertiary mt-4 mb-2 px-1">
                      已过期 ({expiredAgendas.length})
                    </div>
                    {expiredAgendas.map((agenda) => (
                      <AgendaItem
                        key={agenda.id}
                        id={agenda.id}
                        time={agenda.time}
                        content={agenda.content}
                        note={agenda.note}
                        isMustDo={agenda.isMustDo}
                        status="expired"
                        remainingTime={agenda.remainingTime}
                        isHighFrequency={agenda.isHighFrequency}
                        onClick={() => navigate(`/agenda/${agenda.id}`)}
                        onDelete={deleteAgenda}
                      />
                    ))}
                  </>
                )}

                {/* 已完成 - 放下边 */}
                {completedAgendas.length > 0 && (
                  <>
                    <div className="text-caption text-text-tertiary mt-4 mb-2 px-1">
                      已完成 ({completedAgendas.length})
                    </div>
                    {completedAgendas.map((agenda) => (
                      <AgendaItem
                        key={agenda.id}
                        id={agenda.id}
                        time={agenda.time}
                        content={agenda.content}
                        note={agenda.note}
                        isMustDo={agenda.isMustDo}
                        status={agenda.status}
                        remainingTime={agenda.remainingTime}
                        isHighFrequency={agenda.isHighFrequency}
                        onClick={() => navigate(`/agenda/${agenda.id}`)}
                        onDelete={deleteAgenda}
                      />
                    ))}
                  </>
                )}
              </>
            )}
          </div>
        )}
      </section>

      {/* 日历弹窗 */}
      {showCalendar && (
        <div className="fixed inset-0 z-50 flex items-center justify-center px-6">
          <div className="absolute inset-0 bg-black/40" onClick={() => setShowCalendar(false)} />
          <div className="relative w-full max-w-[340px] bg-bg-secondary rounded-xl overflow-hidden">
            {/* 顶部：关闭 + 月份切换 */}
            <div className="flex items-center justify-between px-3 py-3.5 border-b border-border">
              <button
                className="w-8 h-8 flex items-center justify-center text-text-tertiary active:opacity-60"
                onClick={() => setShowCalendar(false)}
              >
                <X size={18} />
              </button>
              <div className="flex items-center gap-2">
                <button
                  className="w-8 h-8 flex items-center justify-center text-text-secondary active:opacity-60"
                  onClick={prevMonth}
                >
                  <ChevronLeft size={18} />
                </button>
                <div className="flex items-center gap-1.5 min-w-[90px] justify-center">
                  <Calendar size={14} className="text-accent" />
                  <span className="text-body-small font-semibold text-text-primary">{monthLabel}</span>
                </div>
                <button
                  className="w-8 h-8 flex items-center justify-center text-text-secondary active:opacity-60"
                  onClick={nextMonth}
                >
                  <ChevronRight size={18} />
                </button>
              </div>
              {/* 占位保持两侧对称 */}
              <div className="w-8 h-8" />
            </div>

            {/* 星期表头 */}
            <div className="grid grid-cols-7 px-3 pt-3 pb-1">
              {['日', '一', '二', '三', '四', '五', '六'].map((w) => (
                <div key={w} className="text-center text-caption text-text-tertiary py-1">{w}</div>
              ))}
            </div>

            {/* 日期网格 - 固定6行高度避免月份切换时尺寸变化 */}
            <div className="grid grid-cols-7 px-3 pb-3 gap-y-1" style={{ minHeight: '252px' }}>
              {calCells.map((cell, i) => {
                if (cell.day === null) {
                  return <div key={i} className="aspect-square" />
                }
                const dateKey = cell.date!
                const hasRecord = datesWithRecords.has(dateKey)
                const isSelected = selectedDateKey === dateKey
                const isTodayCell = todayYmd === dateKey
                return (
                  <button
                    key={i}
                    className="aspect-square flex items-center justify-center relative"
                    onClick={() => {
                      setSelectedDateKey(dateKey)
                      setShowCalendar(false)
                    }}
                  >
                    <span
                      className={`w-9 h-9 rounded-full flex items-center justify-center text-body-small transition-fast ${
                        isSelected
                          ? 'bg-accent-light text-accent ring-2 ring-accent font-semibold'
                          : isTodayCell
                            ? 'text-accent font-semibold border border-accent'
                            : hasRecord
                              ? 'text-text-primary font-medium'
                              : 'text-text-tertiary'
                      }`}
                    >
                      {cell.day}
                    </span>
                  </button>
                )
              })}
            </div>

            {/* 图例 */}
            <div className="px-4 py-3 border-t border-border flex items-center justify-center gap-4">
              <div className="flex items-center gap-1">
                <span className="w-3 h-3 rounded-full bg-bg-tertiary" />
                <span className="text-caption text-text-tertiary">无记录</span>
              </div>
              <div className="flex items-center gap-1">
                <span className="w-3 h-3 rounded-full bg-text-primary" />
                <span className="text-caption text-text-tertiary">有记录</span>
              </div>
              <div className="flex items-center gap-1">
                <span className="w-3 h-3 rounded-full bg-accent-light ring-1 ring-accent" />
                <span className="text-caption text-text-tertiary">已选</span>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* 添加事程弹窗 */}
      <CreateAgendaModal
        visible={showCreateModal}
        onClose={() => setShowCreateModal(false)}
        onNavigateFrequent={() => navigate('/frequent-agenda')}
      />

      {/* 到时提醒弹窗 */}
      {activeReminder && (
        <div className="fixed inset-0 z-[60] flex items-center justify-center px-6">
          <div className="absolute inset-0 bg-black/50" onClick={dismissReminder} />
          <div className="relative w-full max-w-[320px] bg-bg-secondary rounded-xl overflow-hidden animate-[pageEnter_250ms_ease-out]">
            {/* 顶部提醒图标 */}
            <div className="pt-6 pb-4 flex flex-col items-center">
              <div className="w-16 h-16 rounded-full bg-accent-light flex items-center justify-center mb-3 animate-bounce">
                <Bell size={32} className="text-accent" />
              </div>
              <h2 className="text-title-small font-semibold text-text-primary">事程提醒</h2>
              <p className="text-caption text-text-tertiary mt-1">到了该做这件事的时间了</p>
            </div>

            {/* 事程内容 */}
            <div className="px-5 pb-4">
              <div className="bg-bg-tertiary rounded-lg p-4">
                <div className="flex items-center gap-2 mb-2">
                  <Clock size={16} className="text-accent" />
                  <span className="text-body font-semibold text-accent font-mono">{activeReminder.time}</span>
                  {activeReminder.isMustDo && (
                    <span className="ml-auto text-caption px-2 py-0.5 bg-danger-light text-danger rounded-sm">必做</span>
                  )}
                </div>
                <div className="text-body text-text-primary">{activeReminder.content}</div>
              </div>
            </div>

            {/* 操作按钮 */}
            <div className="px-5 pb-5 flex gap-3">
              <button
                className="flex-1 py-3 bg-bg-tertiary rounded-lg text-body-small font-medium text-text-secondary active:bg-border transition-fast"
                onClick={dismissReminder}
              >
                稍后提醒
              </button>
              <button
                className="flex-1 py-3 bg-accent rounded-lg text-white text-body-small font-medium active:bg-text-primary transition-fast flex items-center justify-center gap-1.5"
                onClick={() => {
                  completeAgenda(activeReminder.id)
                  dismissReminder()
                }}
              >
                <Check size={16} />
                已完成
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

export default HomePage

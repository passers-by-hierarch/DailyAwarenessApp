import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { ChevronLeft, Calendar, TrendingUp, CheckCircle, Clock, Target, Award, ArrowUp, ArrowDown, Minus, Share2, Copy, Mail, MessageCircle, Check } from 'lucide-react'

const weeklyReport = {
  weekRange: '2026/06/23 - 2026/06/29',
  completionRate: 87,
  totalAgendas: 56,
  completedAgendas: 49,
  skippedAgendas: 3,
  delayedAgendas: 4,
  behaviorCount: 124,
  score: 92,
  scoreChange: 5,
  categories: [
    { name: '服药', total: 14, completed: 14, rate: 100 },
    { name: '喝水', total: 21, completed: 19, rate: 90 },
    { name: '锻炼', total: 7, completed: 5, rate: 71 },
    { name: '休息', total: 14, completed: 11, rate: 79 },
  ],
  dailyStats: [
    { day: '一', date: '23', rate: 92 },
    { day: '二', date: '24', rate: 85 },
    { day: '三', date: '25', rate: 78 },
    { day: '四', date: '26', rate: 95 },
    { day: '五', date: '27', rate: 88 },
    { day: '六', date: '28', rate: 82 },
    { day: '日', date: '29', rate: 90 },
  ],
  highlights: [
    { type: 'success', text: '服药完成率100%，坚持得很好！' },
    { type: 'success', text: '本周行为记录增加15条' },
    { type: 'warning', text: '锻炼完成率较上周下降10%' },
  ],
  suggestions: [
    '建议增加户外活动时间',
    '可以设置更多喝水提醒',
    '保持当前的服药习惯',
  ],
}

const WeeklyReportPage = () => {
  const navigate = useNavigate()
  const [showShare, setShowShare] = useState(false)
  const [shareSuccess, setShareSuccess] = useState(false)

  const getChangeIcon = (change: number) => {
    if (change > 0) return <ArrowUp size={14} className="text-success" />
    if (change < 0) return <ArrowDown size={14} className="text-danger" />
    return <Minus size={14} className="text-text-tertiary" />
  }

  const shareOptions = [
    { id: 'copy', name: '复制链接', icon: Copy },
    { id: 'mail', name: '发送邮件', icon: Mail },
    { id: 'message', name: '发送消息', icon: MessageCircle },
  ]

  const handleShare = (optionId: string) => {
    setShowShare(false)
    setTimeout(() => {
      setShareSuccess(true)
      setTimeout(() => setShareSuccess(false), 2000)
    }, 300)
  }

  return (
    <div className="page-enter min-h-screen bg-bg-primary pb-8">
      <header className="px-4 py-3 bg-bg-secondary border-b border-border flex items-center justify-between sticky top-0 z-40">
        <button className="w-8 h-8 flex items-center justify-center text-text-primary transition-fast active:opacity-60" onClick={() => navigate(-1)}><ChevronLeft size={24} /></button>
        <h1 className="text-body font-semibold text-text-primary">周报详情</h1>
        <button className="text-body-small font-medium text-info transition-fast active:opacity-60 flex items-center gap-1" onClick={() => setShowShare(true)}>
          <Share2 size={16} />
          分享
        </button>
      </header>

      <section className="px-4 pt-4">
        <div className="bg-gradient-to-br from-accent to-accent/80 rounded-xl p-4 text-white">
          <div className="flex items-center justify-between mb-4">
            <div className="flex items-center gap-2">
              <Calendar size={18} />
              <span className="text-body-small">{weeklyReport.weekRange}</span>
            </div>
            <div className="flex items-center gap-1 px-2 py-1 bg-white/20 rounded-md">
              <Award size={14} />
              <span className="text-caption">本周报告</span>
            </div>
          </div>
          <div className="text-center py-6">
            <div className="text-h1 font-bold mb-2">{weeklyReport.score}</div>
            <div className="text-body-small opacity-90">综合评分</div>
            <div className="flex items-center justify-center gap-1 mt-2">
              {getChangeIcon(weeklyReport.scoreChange)}
              <span className="text-caption">较上周 {weeklyReport.scoreChange > 0 ? '+' : ''}{weeklyReport.scoreChange}分</span>
            </div>
          </div>
          <div className="grid grid-cols-3 gap-3 pt-4 border-t border-white/20">
            <div className="text-center">
              <div className="text-h3 font-semibold">{weeklyReport.completionRate}%</div>
              <div className="text-caption opacity-80 mt-1">完成率</div>
            </div>
            <div className="text-center">
              <div className="text-h3 font-semibold">{weeklyReport.completedAgendas}</div>
              <div className="text-caption opacity-80 mt-1">已完成</div>
            </div>
            <div className="text-center">
              <div className="text-h3 font-semibold">{weeklyReport.behaviorCount}</div>
              <div className="text-caption opacity-80 mt-1">行为记录</div>
            </div>
          </div>
        </div>
      </section>

      <section className="px-4 mt-6">
        <div className="px-1 py-2 flex items-center gap-2">
          <TrendingUp size={16} className="text-accent" />
          <h2 className="text-body-small font-semibold text-text-secondary">每日完成趋势</h2>
        </div>
        <div className="bg-bg-secondary rounded-lg card-shadow p-4">
          <div className="flex items-end justify-around h-32 mb-2">
            {weeklyReport.dailyStats.map((stat, index) => (
              <div key={index} className="flex flex-col items-center gap-1">
                <div className="text-caption text-accent font-medium">{stat.rate}%</div>
                <div className="w-8 rounded-t transition-all" style={{ height: `${stat.rate}%`, backgroundColor: stat.rate >= 85 ? '#10B981' : stat.rate >= 70 ? '#F59E0B' : '#EF4444' }} />
              </div>
            ))}
          </div>
          <div className="flex justify-around text-caption text-text-tertiary">
            {weeklyReport.dailyStats.map((stat) => (
              <div key={stat.date} className="text-center">
                <div className="font-medium">{stat.day}</div>
                <div className="text-caption">{stat.date}</div>
              </div>
            ))}
          </div>
        </div>
      </section>

      <section className="px-4 mt-6">
        <div className="px-1 py-2 flex items-center gap-2">
          <Target size={16} className="text-accent" />
          <h2 className="text-body-small font-semibold text-text-secondary">分类统计</h2>
        </div>
        <div className="bg-bg-secondary rounded-lg card-shadow overflow-hidden">
          {weeklyReport.categories.map((category, index) => (
            <div key={category.name} className={`p-4 ${index < weeklyReport.categories.length - 1 ? 'border-b border-border' : ''}`}>
              <div className="flex items-center justify-between mb-2">
                <span className="text-body-small font-medium text-text-primary">{category.name}</span>
                <span className={`text-body-small font-semibold ${category.rate >= 90 ? 'text-success' : category.rate >= 70 ? 'text-warning' : 'text-danger'}`}>{category.rate}%</span>
              </div>
              <div className="h-2 bg-bg-tertiary rounded-full overflow-hidden">
                <div className="h-full rounded-full transition-all" style={{ width: `${category.rate}%`, backgroundColor: category.rate >= 90 ? '#10B981' : category.rate >= 70 ? '#F59E0B' : '#EF4444' }} />
              </div>
              <div className="flex justify-between mt-2 text-caption text-text-tertiary">
                <span>完成 {category.completed}/{category.total}</span>
              </div>
            </div>
          ))}
        </div>
      </section>

      <section className="px-4 mt-6">
        <div className="px-1 py-2 flex items-center gap-2">
          <CheckCircle size={16} className="text-accent" />
          <h2 className="text-body-small font-semibold text-text-secondary">事程统计</h2>
        </div>
        <div className="grid grid-cols-3 gap-3">
          <div className="bg-bg-secondary rounded-lg card-shadow p-4 text-center">
            <div className="w-10 h-10 bg-success-light rounded-lg mx-auto flex items-center justify-center mb-2"><CheckCircle size={20} className="text-success" /></div>
            <div className="text-h3 font-semibold text-text-primary">{weeklyReport.completedAgendas}</div>
            <div className="text-caption text-text-tertiary mt-1">已完成</div>
          </div>
          <div className="bg-bg-secondary rounded-lg card-shadow p-4 text-center">
            <div className="w-10 h-10 bg-warning-light rounded-lg mx-auto flex items-center justify-center mb-2"><Clock size={20} className="text-warning" /></div>
            <div className="text-h3 font-semibold text-text-primary">{weeklyReport.delayedAgendas}</div>
            <div className="text-caption text-text-tertiary mt-1">已延后</div>
          </div>
          <div className="bg-bg-secondary rounded-lg card-shadow p-4 text-center">
            <div className="w-10 h-10 bg-bg-tertiary rounded-lg mx-auto flex items-center justify-center mb-2"><Minus size={20} className="text-text-tertiary" /></div>
            <div className="text-h3 font-semibold text-text-primary">{weeklyReport.skippedAgendas}</div>
            <div className="text-caption text-text-tertiary mt-1">已跳过</div>
          </div>
        </div>
      </section>

      <section className="px-4 mt-6">
        <div className="px-1 py-2 flex items-center gap-2">
          <Award size={16} className="text-accent" />
          <h2 className="text-body-small font-semibold text-text-secondary">本周亮点</h2>
        </div>
        <div className="space-y-2">
          {weeklyReport.highlights.map((highlight, index) => (
            <div key={index} className={`p-3 rounded-lg ${highlight.type === 'success' ? 'bg-success-light' : 'bg-warning-light'}`}>
              <div className="flex items-start gap-2">
                <div className={`w-5 h-5 rounded-full flex items-center justify-center shrink-0 mt-0.5 ${highlight.type === 'success' ? 'bg-success/20' : 'bg-warning/20'}`}>
                  {highlight.type === 'success' ? <CheckCircle size={12} className="text-success" /> : <Clock size={12} className="text-warning" />}
                </div>
                <span className={`text-body-small ${highlight.type === 'success' ? 'text-success' : 'text-warning'}`}>{highlight.text}</span>
              </div>
            </div>
          ))}
        </div>
      </section>

      <section className="px-4 mt-6">
        <div className="px-1 py-2 flex items-center gap-2">
          <Target size={16} className="text-accent" />
          <h2 className="text-body-small font-semibold text-text-secondary">改进建议</h2>
        </div>
        <div className="bg-bg-secondary rounded-lg card-shadow p-4">
          <div className="space-y-3">
            {weeklyReport.suggestions.map((suggestion, index) => (
              <div key={index} className="flex items-start gap-2">
                <div className="w-6 h-6 bg-accent-light rounded-md flex items-center justify-center shrink-0">
                  <span className="text-caption text-accent font-medium">{index + 1}</span>
                </div>
                <span className="text-body-small text-text-primary leading-relaxed">{suggestion}</span>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* 分享弹窗 */}
      {showShare && (
        <div className="fixed inset-0 z-50 flex items-end justify-center">
          <div className="absolute inset-0 bg-black/40" onClick={() => setShowShare(false)} />
          <div className="relative w-full max-w-[390px] bg-bg-secondary rounded-t-xl px-4 pt-5 pb-6 animate-[pageEnter_250ms_ease-out]">
            <div className="w-10 h-1 bg-bg-tertiary rounded-full mx-auto mb-4" />
            <h2 className="text-title-small font-semibold text-text-primary text-center mb-4">分享周报</h2>
            <div className="grid grid-cols-3 gap-3">
              {shareOptions.map((option) => (
                <button key={option.id} className="flex flex-col items-center gap-2 p-4 bg-bg-tertiary rounded-lg transition-fast active:bg-border" onClick={() => handleShare(option.id)}>
                  <div className="w-12 h-12 bg-accent-light rounded-full flex items-center justify-center">
                    <option.icon size={22} className="text-accent" />
                  </div>
                  <span className="text-caption text-text-primary">{option.name}</span>
                </button>
              ))}
            </div>
            <button className="w-full mt-4 py-3 bg-bg-tertiary rounded-md text-body-small font-medium text-text-secondary active:bg-border transition-fast" onClick={() => setShowShare(false)}>取消</button>
          </div>
        </div>
      )}

      {/* 分享成功提示 */}
      {shareSuccess && (
        <div className="fixed inset-0 z-[60] flex items-center justify-center">
          <div className="bg-success/90 text-white px-6 py-4 rounded-lg flex items-center gap-2">
            <Check size={20} />
            <span className="text-body-small font-medium">分享成功</span>
          </div>
        </div>
      )}
    </div>
  )
}

export default WeeklyReportPage

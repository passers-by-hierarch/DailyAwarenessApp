import { useNavigate } from 'react-router-dom'
import { ChevronLeft, Plus, Clock, TrendingUp } from 'lucide-react'
import { useAppStore } from '../store/appStore'

// 常用事程图标映射
const iconMap: Record<string, string> = {
  '早上吃药': '💊',
  '吃午饭': '🍚',
  '喝水': '💧',
}

const FrequentAgendaPage = () => {
  const navigate = useNavigate()
  const frequentAgendas = useAppStore(s => s.frequentAgendas)
  const addAgenda = useAppStore(s => s.addAgenda)

  // 添加为今日事程
  const handleAddToday = (content: string, avgTime: string) => {
    addAgenda({
      icon: iconMap[content] || '📋',
      time: avgTime,
      content,
      isMustDo: false,
      category: '生活',
      note: undefined,
    })
    navigate(-1)
  }

  return (
    <div className="page-enter min-h-screen bg-bg-primary pb-8">
      {/* 顶部导航栏 */}
      <header className="px-4 py-3 bg-bg-secondary border-b border-border flex items-center justify-between sticky top-0 z-40">
        {/* 返回按钮 */}
        <button
          className="w-8 h-8 flex items-center justify-center text-text-primary transition-fast active:opacity-60"
          onClick={() => navigate(-1)}
        >
          <ChevronLeft size={24} />
        </button>

        {/* 标题 */}
        <h1 className="text-body font-semibold text-text-primary">常用事程</h1>

        {/* 添加按钮 */}
        <button
          className="w-8 h-8 flex items-center justify-center text-text-primary transition-fast active:opacity-60"
          onClick={() => navigate('/create-agenda')}
        >
          <Plus size={22} />
        </button>
      </header>

      {/* 提示区 */}
      <div className="px-4 py-3">
        <div className="bg-info-light rounded-md px-4 py-3 flex items-center gap-2">
          <span className="text-base">💡</span>
          <span className="text-body-small text-info">系统已自动识别您的高频行为，点击添加为今日事程</span>
        </div>
      </div>

      {/* 常用事程列表 */}
      <section className="px-4">
        <div className="text-caption font-semibold text-text-tertiary mb-2 px-1">
          共 {frequentAgendas.length} 项
        </div>

        <div className="space-y-2.5">
          {frequentAgendas.map((agenda) => (
            <div
              key={agenda.id}
              className="bg-bg-secondary rounded-lg card-shadow p-4"
            >
              {/* 顶部：图标 + 名称 + 来源标签 */}
              <div className="flex items-start gap-3">
                {/* 图标 */}
                <div className="w-12 h-12 bg-bg-tertiary rounded-lg flex items-center justify-center text-2xl shrink-0">
                  {iconMap[agenda.content] || '📋'}
                </div>

                {/* 内容 */}
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2 flex-wrap">
                    <span className="text-body font-medium text-text-primary">
                      {agenda.content}
                    </span>
                    {/* 来源标签 */}
                    <span
                      className={`px-2 py-0.5 rounded-sm text-caption ${
                        agenda.isAutoExtracted
                          ? 'bg-info-light text-info'
                          : 'bg-accent-light text-accent'
                      }`}
                    >
                      {agenda.isAutoExtracted ? '自动提取' : '手动添加'}
                    </span>
                  </div>

                  {/* 统计信息 */}
                  <div className="flex items-center gap-3 mt-2">
                    {/* 平均时间 */}
                    <div className="flex items-center gap-1 text-caption text-text-secondary">
                      <Clock size={12} />
                      <span>{agenda.avgTime}</span>
                    </div>
                    {/* 连续天数 */}
                    <div className="flex items-center gap-1 text-caption text-text-secondary">
                      <TrendingUp size={12} />
                      <span>连续{agenda.consecutiveDays}天</span>
                    </div>
                  </div>
                </div>

                {/* 匹配率 */}
                <div className="text-right shrink-0">
                  <div className="text-body-small font-semibold text-accent">
                    {agenda.matchRate}%
                  </div>
                  <div className="text-caption text-text-tertiary">匹配率</div>
                </div>
              </div>

              {/* 底部添加按钮 */}
              <button
                className="w-full mt-3 py-2.5 bg-accent-light rounded-md text-accent text-body-small font-medium transition-fast active:bg-accent/10 flex items-center justify-center gap-1.5"
                onClick={() => handleAddToday(agenda.content, agenda.avgTime)}
              >
                <Plus size={14} />
                添加为今日
              </button>
            </div>
          ))}
        </div>
      </section>
    </div>
  )
}

export default FrequentAgendaPage

import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Tag, ChevronRight, Settings, Hash, Activity, Package, ShoppingCart, MapPin, X, Check } from 'lucide-react'
import { useAppStore, SYSTEM_TAGS, type TagColor } from '../store/appStore'

// 标签颜色映射
const colorClassMap: Record<TagColor, { color: string; bg: string; ring: string }> = {
  accent:  { color: 'text-accent',         bg: 'bg-accent-light',  ring: 'ring-accent' },
  info:    { color: 'text-info',           bg: 'bg-info-light',    ring: 'ring-info' },
  warning: { color: 'text-warning',        bg: 'bg-warning-light', ring: 'ring-warning' },
  success: { color: 'text-success',        bg: 'bg-success-light', ring: 'ring-success' },
  danger:  { color: 'text-danger',         bg: 'bg-danger-light',  ring: 'ring-danger' },
  gray:    { color: 'text-text-secondary', bg: 'bg-bg-tertiary',   ring: 'ring-text-tertiary' },
  purple:  { color: 'text-purple-600',     bg: 'bg-purple-100',    ring: 'ring-purple-400' },
}

const systemTagIcon: Record<string, React.ReactNode> = {
  behavior: <Activity size={10} />,
  item:     <Package size={10} />,
  shopping: <ShoppingCart size={10} />,
  event:    <MapPin size={10} />,
}

type TimeRange = 'week' | 'month' | 'all'

const TagShowcase = () => {
  const navigate = useNavigate()
  const getAllTagsWithStats = useAppStore(s => s.getAllTagsWithStats)
  const getRecordsByTag = useAppStore(s => s.getRecordsByTag)
  const getTagDef = useAppStore(s => s.getTagDef)

  // 时间范围切换
  const [timeRange, setTimeRange] = useState<TimeRange>('all')
  // 展开的标签ID
  const [expandedTagId, setExpandedTagId] = useState<string | null>(null)

  // 获取所有标签统计
  const allTags = getAllTagsWithStats()

  // 简单的时间范围过滤（mock：本周/本月/全部，这里仅做演示，实际按记录的 time 字段无法严格过滤，暂用全部数据）
  // 注：mock 数据中的 time 是 HH:MM 格式，没有日期，所以这里统一用全部数据演示
  const filterByTimeRange = <T,>(arr: T[]): T[] => {
    // 实际场景需要根据日期字段过滤，这里返回全部
    return arr
  }

  // 渲染标签图标
  const renderIcon = (tag: { system: boolean; id: string; icon: string }, size = 10) => {
    if (tag.system) {
      const icon = systemTagIcon[tag.id]
      return icon ? <span className="[&>svg]:w-[10px] [&>svg]:h-[10px]">{icon}</span> : <Hash size={size} />
    }
    return tag.icon && tag.icon.length <= 2 ? <span className="text-[10px]">{tag.icon}</span> : <Hash size={size} />
  }

  return (
    <section className="mt-4">
      {/* 区块标题 */}
      <div className="px-4 py-2 flex items-center justify-between">
        <div className="flex items-center gap-2">
          <div className="w-1.5 h-1.5 bg-accent rounded-full" />
          <h2 className="text-body-small font-semibold text-text-secondary">标签集锦</h2>
        </div>
        <button
          className="flex items-center gap-1 text-caption text-text-secondary active:opacity-60"
          onClick={() => navigate('/tag-management')}
        >
          <Settings size={12} />
          管理
        </button>
      </div>

      {/* 时间范围切换 */}
      <div className="px-4 mb-2">
        <div className="flex gap-1 bg-bg-tertiary rounded-md p-1">
          {([
            { key: 'week' as TimeRange, label: '本周' },
            { key: 'month' as TimeRange, label: '本月' },
            { key: 'all' as TimeRange, label: '全部' },
          ]).map((opt) => (
            <button
              key={opt.key}
              className={`flex-1 py-1.5 rounded text-caption font-medium transition-fast ${
                timeRange === opt.key ? 'bg-bg-secondary text-accent' : 'text-text-secondary'
              }`}
              onClick={() => setTimeRange(opt.key)}
            >
              {opt.label}
            </button>
          ))}
        </div>
      </div>

      {/* 标签卡片网格 */}
      <div className="px-4">
        <div className="grid grid-cols-4 gap-2">
          {allTags.map((t) => {
            const colorCls = colorClassMap[t.color]
            const isExpanded = expandedTagId === t.id
            return (
              <button
                key={t.id}
                className={`relative rounded-lg p-3 flex flex-col items-center justify-center transition-fast active:scale-[0.97] ${
                  isExpanded ? `${colorCls.bg} ring-1 ${colorCls.ring}` : 'bg-bg-secondary card-shadow'
                }`}
                onClick={() => setExpandedTagId(isExpanded ? null : t.id)}
              >
                <div className={`w-8 h-8 rounded-full ${colorCls.bg} ${colorCls.color} flex items-center justify-center mb-1`}>
                  {renderIcon(t)}
                </div>
                <div className={`text-caption font-medium ${isExpanded ? colorCls.color : 'text-text-primary'} truncate max-w-full`}>
                  {t.name}
                </div>
                <div className={`text-time font-mono ${isExpanded ? colorCls.color : 'text-accent'}`}>
                  {t.count}
                </div>
              </button>
            )
          })}
        </div>
      </div>

      {/* 展开的标签详情：显示该标签下的记录列表 */}
      {expandedTagId && (
        <div className="px-4 mt-3 animate-[pageEnter_250ms_ease-out]">
          {(() => {
            const def = getTagDef(expandedTagId)
            if (!def) {
              return (
                <div className="bg-bg-secondary rounded-lg card-shadow p-4 text-center">
                  <div className="text-body-small text-text-tertiary">该标签已被删除</div>
                </div>
              )
            }
            const records = filterByTimeRange(getRecordsByTag(expandedTagId))
            const colorCls = colorClassMap[def.color]
            return (
              <div className="bg-bg-secondary rounded-lg card-shadow p-4">
                {/* 标签标题 */}
                <div className="flex items-center justify-between mb-3">
                  <div className="flex items-center gap-2">
                    <span className={`inline-flex items-center gap-0.5 px-2 py-0.5 rounded-sm ${colorCls.bg} ${colorCls.color} text-caption`}>
                      {renderIcon(def, 12)}
                      {def.name}
                    </span>
                    <span className="text-body-small font-medium text-text-primary">
                      {records.length} 条记录
                    </span>
                  </div>
                  <button
                    className="text-text-tertiary active:opacity-60"
                    onClick={() => setExpandedTagId(null)}
                  >
                    <X size={16} />
                  </button>
                </div>

                {/* 记录列表（最多展示5条） */}
                {records.length === 0 ? (
                  <div className="text-center py-4 text-body-small text-text-tertiary">
                    暂无记录
                  </div>
                ) : (
                  <div className="space-y-2">
                    {records.slice(0, 5).map((r) => (
                      <button
                        key={r.id}
                        className="w-full flex items-start gap-3 p-3 bg-bg-tertiary rounded-md transition-fast active:bg-border text-left"
                        onClick={() => navigate(`/timeline/${r.id}`)}
                      >
                        <div className="text-time font-mono text-text-secondary shrink-0 pt-0.5">
                          {r.time}
                        </div>
                        <div className="flex-1 min-w-0">
                          <div className="text-body-small font-medium text-text-primary truncate">
                            {r.content}
                          </div>
                          {/* 该记录的其他标签 */}
                          {r.tags.length > 1 && (
                            <div className="flex flex-wrap gap-1 mt-1">
                              {r.tags.filter(t => t !== expandedTagId).map((tagId) => {
                                const otherDef = getTagDef(tagId)
                                if (!otherDef) return null
                                const otherColor = colorClassMap[otherDef.color]
                                return (
                                  <span
                                    key={tagId}
                                    className={`text-[10px] px-1 py-0 rounded-sm ${otherColor.bg} ${otherColor.color}`}
                                  >
                                    {otherDef.name}
                                  </span>
                                )
                              })}
                            </div>
                          )}
                        </div>
                        <ChevronRight size={14} className="text-text-tertiary shrink-0 mt-1" />
                      </button>
                    ))}
                    {records.length > 5 && (
                      <button
                        className="w-full text-center text-caption text-accent py-2 active:opacity-60"
                        onClick={() => navigate(`/tag-records/${expandedTagId}`)}
                      >
                        查看全部 {records.length} 条 →
                      </button>
                    )}
                  </div>
                )}
              </div>
            )
          })()}
        </div>
      )}
    </section>
  )
}

export default TagShowcase

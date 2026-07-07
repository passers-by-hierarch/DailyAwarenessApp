import { Check, Package, ShoppingCart, Activity, MapPin, Hash, PlusCircle } from 'lucide-react'
import { useAppStore, SYSTEM_TAGS, type TagColor } from '../store/appStore'

interface TimelineItemProps {
  time: string
  content: string
  matchedAgenda?: string
  status: 'matched' | 'unmatched'
  // 标签ID数组（系统标签 + 自定义标签）
  tags?: string[]
  onClick?: () => void
}

// 标签颜色映射到 Tailwind 类名
const colorClassMap: Record<TagColor, { color: string; bg: string }> = {
  accent:  { color: 'text-accent',      bg: 'bg-accent-light' },
  info:    { color: 'text-info',        bg: 'bg-info-light' },
  warning: { color: 'text-warning',     bg: 'bg-warning-light' },
  success: { color: 'text-success',     bg: 'bg-success-light' },
  danger:  { color: 'text-danger',      bg: 'bg-danger-light' },
  gray:    { color: 'text-text-secondary', bg: 'bg-bg-tertiary' },
  purple:  { color: 'text-purple-600',  bg: 'bg-purple-100' },
}

// 系统标签图标映射
const systemTagIcon: Record<string, React.ReactNode> = {
  behavior: <Activity size={12} />,
  item:     <Package size={12} />,
  shopping: <ShoppingCart size={12} />,
  event:    <MapPin size={12} />,
}

const TimelineItem = ({ time, content, matchedAgenda, status, tags = ['event'], onClick }: TimelineItemProps) => {
  const getTagDef = useAppStore(s => s.getTagDef)

  return (
    <div
      className="bg-bg-secondary rounded-lg item-shadow mb-2 overflow-hidden transition-fast active:bg-bg-tertiary cursor-pointer"
      onClick={onClick}
    >
      <div className="flex items-start p-4">
        {/* 时间戳 */}
        <div className="w-12 text-time font-mono text-text-secondary shrink-0">
          {time}
        </div>

        {/* 内容区 */}
        <div className="flex-1 pl-3 min-w-0">
          {/* 多标签展示 */}
          <div className="flex items-center gap-1.5 mb-1 flex-wrap">
            {tags.map((tagId) => {
              const def = getTagDef(tagId)
              // 已删除的自定义标签 → 灰色显示
              if (!def) {
                return (
                  <span
                    key={tagId}
                    className="inline-flex items-center gap-0.5 px-1.5 py-0.5 rounded-sm bg-bg-tertiary text-text-tertiary text-caption line-through shrink-0"
                  >
                    <Hash size={12} />
                    已删除
                  </span>
                )
              }
              const colorCls = colorClassMap[def.color]
              // 系统标签用 lucide 图标，自定义标签用 emoji 或默认 #
              const icon = def.system
                ? (systemTagIcon[def.id] ?? <Hash size={12} />)
                : (def.icon && def.icon.length <= 2 ? <span className="text-[10px]">{def.icon}</span> : <Hash size={12} />)
              return (
                <span
                  key={tagId}
                  className={`inline-flex items-center gap-0.5 px-1.5 py-0.5 rounded-sm ${colorCls.bg} ${colorCls.color} text-caption shrink-0`}
                >
                  {icon}
                  {def.name}
                </span>
              )
            })}
          </div>

          <div className="text-body font-medium text-text-primary">
            {content}
          </div>

          {/* 匹配 / 创建事程标签 */}
          {status === 'matched' && matchedAgenda && (
            <div className="inline-flex items-center gap-1 mt-2 px-2.5 py-1 rounded-md bg-success-light text-success text-caption">
              <Check size={12} />
              <span>已匹配 {matchedAgenda}</span>
            </div>
          )}
          {status === 'unmatched' && matchedAgenda && (
            <div className="inline-flex items-center gap-1 mt-2 px-2.5 py-1 rounded-md bg-accent-light text-accent text-caption">
              <PlusCircle size={12} />
              <span>已创建事程 {matchedAgenda}</span>
            </div>
          )}
        </div>
      </div>
    </div>
  )
}

export default TimelineItem

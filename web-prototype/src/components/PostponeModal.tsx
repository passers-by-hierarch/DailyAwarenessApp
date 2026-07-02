import { X } from 'lucide-react'

interface PostponeModalProps {
  visible: boolean
  onClose: () => void
  onSelect: (minutes: number) => void
}

const PostponeModal = ({ visible, onClose, onSelect }: PostponeModalProps) => {
  if (!visible) return null

  // 延后时间选项
  const options = [
    { minutes: 5, label: '5分钟后' },
    { minutes: 10, label: '10分钟后' },
    { minutes: 15, label: '15分钟后' },
    { minutes: 30, label: '30分钟后' },
  ]

  return (
    <div className="fixed inset-0 z-50 flex items-end justify-center">
      {/* 半透明遮罩层 */}
      <div
        className="absolute inset-0 bg-black/40"
        onClick={onClose}
      />

      {/* 底部弹窗 */}
      <div className="relative w-full max-w-[390px] bg-bg-secondary rounded-t-xl px-4 pt-5 pb-6 animate-[pageEnter_250ms_ease-out]">
        {/* 顶部拖动条 */}
        <div className="w-10 h-1 bg-bg-tertiary rounded-full mx-auto mb-4" />

        {/* 标题 */}
        <h2 className="text-title-small font-semibold text-text-primary text-center mb-5">
          选择延后时间
        </h2>

        {/* 选项列表 */}
        <div className="space-y-2.5">
          {options.map((option) => (
            <button
              key={option.minutes}
              className="w-full flex items-center justify-between py-4 px-4 bg-bg-tertiary rounded-lg transition-fast active:bg-border"
              onClick={() => {
                onSelect(option.minutes)
                onClose()
              }}
            >
              {/* 标签 */}
              <span className="text-body font-medium text-text-primary">
                {option.label}
              </span>

              {/* 箭头指示 */}
              <span className="text-text-tertiary text-body">›</span>
            </button>
          ))}
        </div>

        {/* 取消按钮 */}
        <button
          className="w-full mt-5 py-3.5 bg-bg-tertiary rounded-lg text-body font-medium text-text-secondary transition-fast active:bg-border flex items-center justify-center gap-2"
          onClick={onClose}
        >
          <X size={16} />
          取消
        </button>
      </div>
    </div>
  )
}

export default PostponeModal

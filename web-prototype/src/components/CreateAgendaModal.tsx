import { ChevronRight, X } from 'lucide-react'

interface CreateAgendaModalProps {
  visible: boolean
  onClose: () => void
  onSelect: (type: 'voice' | 'text' | 'frequent') => void
}

const CreateAgendaModal = ({ visible, onClose, onSelect }: CreateAgendaModalProps) => {
  if (!visible) return null

  // 选项配置
  const options = [
    {
      type: 'voice' as const,
      icon: '🎙',
      title: '语音创建',
      desc: '按住说话，自动识别记录',
    },
    {
      type: 'text' as const,
      icon: '✏',
      title: '文字创建',
      desc: '手动输入事程内容和时间',
    },
    {
      type: 'frequent' as const,
      icon: '⭐',
      title: '从常用事程选择',
      desc: '快速添加常用的高频行为',
    },
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
          创建事程
        </h2>

        {/* 选项列表 */}
        <div className="space-y-2.5">
          {options.map((option) => (
            <button
              key={option.type}
              className="w-full flex items-center gap-3 p-4 bg-bg-tertiary rounded-lg transition-fast active:bg-border"
              onClick={() => {
                onSelect(option.type)
                onClose()
              }}
            >
              {/* 图标 */}
              <div className="w-11 h-11 bg-bg-secondary rounded-full flex items-center justify-center text-xl shrink-0">
                {option.icon}
              </div>

              {/* 文字 */}
              <div className="flex-1 text-left">
                <div className="text-body font-medium text-text-primary">
                  {option.title}
                </div>
                <div className="text-caption text-text-secondary mt-0.5">
                  {option.desc}
                </div>
              </div>

              {/* 右侧箭头 */}
              <ChevronRight size={18} className="text-text-tertiary shrink-0" />
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

export default CreateAgendaModal

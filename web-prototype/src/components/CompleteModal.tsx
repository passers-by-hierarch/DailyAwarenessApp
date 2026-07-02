import { Check, X } from 'lucide-react'

interface CompleteModalProps {
  visible: boolean
  onClose: () => void
  onConfirm: () => void
  agendaContent: string
  agendaTime: string
}

const CompleteModal = ({
  visible,
  onClose,
  onConfirm,
  agendaContent,
  agendaTime,
}: CompleteModalProps) => {
  if (!visible) return null

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center px-6">
      {/* 半透明遮罩层 */}
      <div
        className="absolute inset-0 bg-black/40"
        onClick={onClose}
      />

      {/* 居中弹窗 */}
      <div className="relative w-full max-w-[300px] bg-bg-secondary rounded-lg overflow-hidden">
        {/* 标题 */}
        <h2 className="text-title-small font-semibold text-text-primary text-center pt-6 px-5">
          确认完成？
        </h2>

        {/* 内容 */}
        <div className="px-5 py-4">
          <div className="bg-bg-tertiary rounded-md p-4 text-center">
            {/* 事程名称 */}
            <div className="text-body font-medium text-text-primary">
              {agendaContent}
            </div>

            {/* 时间 */}
            <div className="text-time font-mono text-text-secondary mt-2">
              {agendaTime}
            </div>
          </div>
        </div>

        {/* 按钮组 */}
        <div className="flex gap-3 px-5 pb-6">
          {/* 确认按钮 */}
          <button
            className="flex-1 py-3 bg-accent rounded-md text-white text-body-small font-medium transition-fast active:bg-text-primary flex items-center justify-center gap-1.5 button-shadow"
            onClick={onConfirm}
          >
            <Check size={16} />
            确认
          </button>

          {/* 取消按钮 */}
          <button
            className="flex-1 py-3 bg-bg-tertiary rounded-md text-text-secondary text-body-small font-medium transition-fast active:bg-border flex items-center justify-center gap-1.5"
            onClick={onClose}
          >
            <X size={16} />
            取消
          </button>
        </div>
      </div>
    </div>
  )
}

export default CompleteModal

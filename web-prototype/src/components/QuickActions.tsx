import { useState } from 'react'
import { Pencil, Plus, X, Send, Sparkles } from 'lucide-react'
import { useNavigate } from 'react-router-dom'
import { useAppStore } from '../store/appStore'

interface QuickActionsProps {
  onCreateAgenda?: () => void
}

const QuickActions = ({ onCreateAgenda }: QuickActionsProps) => {
  const navigate = useNavigate()
  const submitVoiceRecord = useAppStore(s => s.submitVoiceRecord)
  const getTagDef = useAppStore(s => s.getTagDef)

  // 文字输入弹窗状态
  const [showInput, setShowInput] = useState(false)
  const [inputText, setInputText] = useState('')
  const [submitted, setSubmitted] = useState<{ tags: string[] } | null>(null)

  // 快捷示例
  const samplePhrases: { text: string; label: string }[] = [
    { text: '回家，钥匙放在门口鞋柜上了', label: '回家放钥匙' },
    { text: '在超市买了苹果2斤，牛奶3瓶', label: '买东西' },
    { text: '正在喝水', label: '喝水' },
    { text: '拿了快递', label: '拿快递' },
  ]

  // 提交文字记录到时间线
  const handleSubmit = () => {
    if (!inputText.trim()) return
    const result = submitVoiceRecord(inputText.trim())
    setSubmitted({ tags: result.tags })
    setInputText('')
    setTimeout(() => {
      setSubmitted(null)
      setShowInput(false)
    }, 1500)
  }

  // 关闭弹窗
  const handleClose = () => {
    setShowInput(false)
    setInputText('')
    setSubmitted(null)
  }

  return (
    <div className="px-4 py-1.5 flex gap-2">
      {/* 手动输入按钮 - 文字录入时间线记录 */}
      <button
        className="flex-1 h-9 rounded-md bg-bg-tertiary flex items-center justify-center gap-1.5 transition-fast active:bg-border"
        onClick={() => setShowInput(true)}
      >
        <Pencil size={16} className="text-text-secondary" />
        <span className="text-caption font-medium text-text-primary">手动输入</span>
      </button>

      {/* 快速事程按钮 - 弹窗选择创建方式 */}
      <button
        className="flex-1 h-9 rounded-md bg-bg-tertiary flex items-center justify-center gap-1.5 transition-fast active:bg-border"
        onClick={onCreateAgenda}
      >
        <Plus size={16} className="text-text-secondary" />
        <span className="text-caption font-medium text-text-primary">快速事程</span>
      </button>

      {/* 文字输入弹窗 */}
      {showInput && (
        <div className="fixed inset-0 z-50 flex items-end justify-center">
          <div className="absolute inset-0 bg-black/40" onClick={handleClose} />
          <div className="relative w-full max-w-[390px] bg-bg-secondary rounded-t-xl px-4 pt-5 pb-6 animate-[pageEnter_250ms_ease-out]">
            {/* 顶部拖动条 */}
            <div className="w-10 h-1 bg-bg-tertiary rounded-full mx-auto mb-4" />

            {/* 标题 */}
            <div className="flex items-center justify-between mb-3">
              <div className="flex items-center gap-2">
                <Sparkles size={16} className="text-accent" />
                <h2 className="text-title-small font-semibold text-text-primary">记录现在</h2>
              </div>
              <button
                className="w-6 h-6 flex items-center justify-center text-text-secondary active:opacity-60"
                onClick={handleClose}
              >
                <X size={18} />
              </button>
            </div>

            {/* 提示 */}
            <p className="text-caption text-text-tertiary mb-3">输入你现在正在做什么，系统会自动识别标签</p>

            {/* 输入框 */}
            <textarea
              value={inputText}
              onChange={(e) => setInputText(e.target.value)}
              placeholder="如：回家，钥匙放在门口鞋柜上了"
              rows={3}
              className="w-full bg-bg-tertiary rounded-md px-3 py-2.5 text-body text-text-primary outline-none focus:ring-2 focus:ring-accent resize-none placeholder:text-text-tertiary mb-3"
              autoFocus
            />

            {/* 快捷示例 */}
            <div className="flex flex-wrap gap-2 mb-4">
              {samplePhrases.map((p) => (
                <button
                  key={p.label}
                  className="px-2.5 py-1.5 bg-bg-tertiary rounded-md text-caption text-text-secondary active:bg-border transition-fast"
                  onClick={() => setInputText(p.text)}
                >
                  {p.label}
                </button>
              ))}
            </div>

            {/* 操作按钮 */}
            <div className="flex gap-3">
              <button
                className="flex-1 py-3 bg-bg-tertiary rounded-md text-body-small font-medium text-text-secondary active:bg-border transition-fast"
                onClick={handleClose}
              >
                取消
              </button>
              <button
                className="flex-1 py-3 bg-accent rounded-md text-white text-body-small font-medium active:bg-text-primary transition-fast flex items-center justify-center gap-1.5"
                onClick={handleSubmit}
                disabled={!inputText.trim()}
              >
                <Send size={16} />
                记录
              </button>
            </div>

            {/* 提交成功提示 */}
            {submitted && submitted.tags.length > 0 && (
              <div className="mt-3 pt-3 border-t border-border flex items-center justify-center gap-1.5">
                <span className="text-caption text-success">已记录到时间线</span>
                {submitted.tags.map((tagId, idx) => {
                  const def = getTagDef(tagId)
                  return (
                    <span
                      key={idx}
                      className="text-caption px-1.5 py-0.5 bg-accent-light text-accent rounded-sm"
                    >
                      {def?.name ?? '已删除'}
                    </span>
                  )
                })}
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  )
}

export default QuickActions

import { useState, useEffect } from 'react'
import { X, Check, Clock, Sparkles, ChevronUp, ChevronDown } from 'lucide-react'
import { useAppStore, PendingAgendaItem } from '../store/appStore'

interface AgendaConfirmModalProps {
  visible: boolean
  onClose: () => void
}

const sourceLabels: Record<PendingAgendaItem['timeSource'], { label: string; color: string; icon: string }> = {
  'user-specified': { label: '您指定的时间', color: 'text-accent', icon: '🎯' },
  'history': { label: '根据您的习惯推荐', color: 'text-success', icon: '📊' },
  'common-sense': { label: '根据常识推荐', color: 'text-info', icon: '💡' },
  'current': { label: '当前时间', color: 'text-text-tertiary', icon: '⏰' },
}

const AgendaConfirmModal = ({ visible, onClose }: AgendaConfirmModalProps) => {
  const pendingAgendaConfirm = useAppStore(s => s.pendingAgendaConfirm)
  const confirmPendingAgenda = useAppStore(s => s.confirmPendingAgenda)
  const rejectPendingAgenda = useAppStore(s => s.rejectPendingAgenda)
  const updatePendingAgendaTime = useAppStore(s => s.updatePendingAgendaTime)
  const clearPendingAgenda = useAppStore(s => s.clearPendingAgenda)

  const [editingId, setEditingId] = useState<string | null>(null)

  useEffect(() => {
    if (!visible) {
      setEditingId(null)
    }
  }, [visible])

  if (!visible || pendingAgendaConfirm.length === 0) return null

  const handleConfirm = () => {
    const ids = pendingAgendaConfirm.map(p => p.id)
    confirmPendingAgenda(ids)
    onClose()
  }

  const handleReject = () => {
    const ids = pendingAgendaConfirm.map(p => p.id)
    rejectPendingAgenda(ids)
    onClose()
  }

  const handleTimeChange = (id: string, delta: number) => {
    const item = pendingAgendaConfirm.find(p => p.id === id)
    if (!item) return
    const [h, m] = item.time.split(':').map(Number)
    let totalMinutes = h * 60 + m + delta
    if (totalMinutes < 0) totalMinutes = 0
    if (totalMinutes > 24 * 60 - 1) totalMinutes = 24 * 60 - 1
    const newH = Math.floor(totalMinutes / 60)
    const newM = totalMinutes % 60
    const newTime = `${String(newH).padStart(2, '0')}:${String(newM).padStart(2, '0')}`
    updatePendingAgendaTime(id, newTime)
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center px-6">
      <div className="absolute inset-0 bg-black/40" onClick={handleReject} />

      <div className="relative w-full max-w-[340px] bg-bg-secondary rounded-xl overflow-hidden animate-[pageEnter_250ms_ease-out]">
        {/* 顶部 */}
        <div className="px-4 pt-4 pb-3 border-b border-border">
          <div className="flex items-center justify-between mb-2">
            <div className="flex items-center gap-2">
              <Sparkles size={18} className="text-accent" />
              <h2 className="text-title-small font-semibold text-text-primary">
                为您创建{pendingAgendaConfirm.length}项事程
              </h2>
            </div>
            <button
              className="w-7 h-7 flex items-center justify-center text-text-tertiary active:opacity-60 rounded-full hover:bg-bg-tertiary"
              onClick={handleReject}
            >
              <X size={16} />
            </button>
          </div>
          <p className="text-caption text-text-tertiary">
            系统已智能设置提醒时间，您可以调整或确认
          </p>
        </div>

        {/* 事程列表 */}
        <div className="px-4 py-3 max-h-[50vh] overflow-y-auto space-y-2.5">
          {pendingAgendaConfirm.map((item) => {
            const sourceInfo = sourceLabels[item.timeSource]
            const isEditing = editingId === item.id
            return (
              <div
                key={item.id}
                className="bg-bg-tertiary rounded-lg p-3"
              >
                <div className="flex items-start gap-3">
                  {/* 时间选择 */}
                  <div className="flex flex-col items-center shrink-0">
                    {isEditing ? (
                      <>
                        <button
                          className="w-8 h-6 flex items-center justify-center text-accent active:opacity-60"
                          onClick={() => handleTimeChange(item.id, 5)}
                        >
                          <ChevronUp size={18} />
                        </button>
                        <div className="text-body font-bold text-text-primary font-mono">
                          {item.time}
                        </div>
                        <button
                          className="w-8 h-6 flex items-center justify-center text-accent active:opacity-60"
                          onClick={() => handleTimeChange(item.id, -5)}
                        >
                          <ChevronDown size={18} />
                        </button>
                      </>
                    ) : (
                      <button
                        className="flex flex-col items-center active:opacity-60"
                        onClick={() => setEditingId(isEditing ? null : item.id)}
                      >
                        <div className="text-title-small font-bold text-accent font-mono">
                          {item.time}
                        </div>
                        <div className="text-caption text-text-tertiary mt-0.5 flex items-center gap-1">
                          <Clock size={12} />
                          点击调整
                        </div>
                      </button>
                    )}
                  </div>

                  {/* 内容 */}
                  <div className="flex-1 min-w-0">
                    <div className="text-body font-medium text-text-primary">
                      {item.content}
                      {item.isMustDo && (
                        <span className="ml-1.5 text-caption text-danger">必做</span>
                      )}
                    </div>
                    <div className={`text-caption mt-1 flex items-center gap-1 ${sourceInfo.color}`}>
                      <span>{sourceInfo.icon}</span>
                      <span>{sourceInfo.label}</span>
                    </div>
                  </div>
                </div>

                {isEditing && (
                  <div className="mt-2 pt-2 border-t border-border flex gap-2">
                    <button
                      className="flex-1 py-1.5 text-caption text-text-secondary bg-bg-secondary rounded-md active:bg-border"
                      onClick={() => handleTimeChange(item.id, -30)}
                    >
                      -30分
                    </button>
                    <button
                      className="flex-1 py-1.5 text-caption text-text-secondary bg-bg-secondary rounded-md active:bg-border"
                      onClick={() => handleTimeChange(item.id, -10)}
                    >
                      -10分
                    </button>
                    <button
                      className="flex-1 py-1.5 text-caption text-text-secondary bg-bg-secondary rounded-md active:bg-border"
                      onClick={() => handleTimeChange(item.id, 10)}
                    >
                      +10分
                    </button>
                    <button
                      className="flex-1 py-1.5 text-caption text-text-secondary bg-bg-secondary rounded-md active:bg-border"
                      onClick={() => handleTimeChange(item.id, 30)}
                    >
                      +30分
                    </button>
                  </div>
                )}
              </div>
            )
          })}
        </div>

        {/* 底部按钮 */}
        <div className="px-4 py-3 border-t border-border flex gap-3">
          <button
            className="flex-1 py-3 bg-bg-tertiary rounded-lg text-body font-medium text-text-secondary active:bg-border transition-fast"
            onClick={handleReject}
          >
            取消
          </button>
          <button
            className="flex-1 py-3 bg-accent rounded-lg text-white text-body font-medium active:bg-text-primary transition-fast flex items-center justify-center gap-1.5"
            onClick={handleConfirm}
          >
            <Check size={18} />
            确认创建
          </button>
        </div>
      </div>
    </div>
  )
}

export default AgendaConfirmModal

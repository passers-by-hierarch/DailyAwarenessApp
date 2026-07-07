import { useState, useRef, useEffect } from 'react'
import { Mic, Check, Keyboard, X, Send, Sparkles } from 'lucide-react'
import { useAppStore } from '../store/appStore'
import AgendaConfirmModal from './AgendaConfirmModal'

const samplePhrases: { text: string; label: string }[] = [
  { text: '回家，钥匙放在门口鞋柜上了', label: '回家放钥匙' },
  { text: '在超市买了苹果2斤，牛奶3瓶', label: '买东西' },
  { text: '正在喝水', label: '喝水（完成）' },
  { text: '拿了快递', label: '拿快递' },
  { text: '记得下午3点吃药', label: '提醒吃药' },
  { text: '别忘了早上吃药，中午吃饭，晚上运动', label: '多项提醒' },
  { text: '刚吃完午饭', label: '刚吃完（完成）' },
]

const VoiceButton = () => {
  const submitVoiceRecord = useAppStore(s => s.submitVoiceRecord)
  const getTagDef = useAppStore(s => s.getTagDef)
  const pendingAgendaConfirm = useAppStore(s => s.pendingAgendaConfirm)

  const [status, setStatus] = useState<'idle' | 'recording'>('idle')
  const [recordSeconds, setRecordSeconds] = useState(0)
  const [submitted, setSubmitted] = useState<{ tags: string[]; agendaCreated: number; isAgendaCreation: boolean; needsConfirm: boolean } | null>(null)
  const [showInput, setShowInput] = useState(false)
  const [inputText, setInputText] = useState('')
  const [inputSubmitted, setInputSubmitted] = useState<{ tags: string[]; agendaCreated: number; isAgendaCreation: boolean; needsConfirm: boolean } | null>(null)
  const [showConfirmModal, setShowConfirmModal] = useState(false)

  const timerRef = useRef<ReturnType<typeof setInterval> | null>(null)
  const stopTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null)

  const startRecording = () => {
    setStatus('recording')
    setRecordSeconds(0)
    timerRef.current = setInterval(() => {
      setRecordSeconds(s => s + 1)
    }, 1000)
    stopTimerRef.current = setTimeout(() => {
      stopRecording()
    }, 3000)
  }

  const stopRecording = () => {
    if (timerRef.current) clearInterval(timerRef.current)
    if (stopTimerRef.current) clearTimeout(stopTimerRef.current)
    setRecordSeconds(0)
    const text = samplePhrases[Math.floor(Math.random() * samplePhrases.length)].text
    const result = submitVoiceRecord(text)
    setSubmitted({ tags: result.tags, agendaCreated: result.agendaCreated, isAgendaCreation: result.isAgendaCreation, needsConfirm: result.needsConfirm })
    setStatus('idle')
    if (result.needsConfirm) {
      setTimeout(() => {
        setShowConfirmModal(true)
        setSubmitted(null)
      }, 800)
    } else {
      setTimeout(() => setSubmitted(null), 2500)
    }
  }

  const manualStop = () => {
    if (recordSeconds >= 1) {
      stopRecording()
    }
  }

  const handleSubmitText = () => {
    if (!inputText.trim()) return
    const result = submitVoiceRecord(inputText.trim())
    setInputSubmitted({ tags: result.tags, agendaCreated: result.agendaCreated, isAgendaCreation: result.isAgendaCreation, needsConfirm: result.needsConfirm })
    setInputText('')
    if (result.needsConfirm) {
      setTimeout(() => {
        setShowConfirmModal(true)
        setInputSubmitted(null)
        setShowInput(false)
      }, 800)
    } else {
      setTimeout(() => {
        setInputSubmitted(null)
        setShowInput(false)
      }, 1500)
    }
  }

  const handleCloseInput = () => {
    setShowInput(false)
    setInputText('')
    setInputSubmitted(null)
  }

  useEffect(() => {
    return () => {
      if (timerRef.current) clearInterval(timerRef.current)
      if (stopTimerRef.current) clearTimeout(stopTimerRef.current)
    }
  }, [])

  const voiceBtn = (() => {
    if (status === 'recording') {
      return (
        <button
          className="flex-1 rounded-lg voice-button-gradient flex items-center justify-center gap-3 transition-fast active:scale-[0.98] button-shadow h-12"
          onClick={manualStop}
        >
          <Mic size={24} className="text-white animate-pulse" />
          <span className="text-body-small text-white font-medium">
            正在录音... {String(recordSeconds).padStart(2, '0')}s
          </span>
          <div className="flex items-center gap-0.5">
            {[1, 2, 3, 4].map((i) => (
              <div
                key={i}
                className="w-1 bg-white/80 rounded-full wave-bar"
                style={{
                  height: `${8 + (i % 3) * 4}px`,
                  animationDelay: `${i * 0.08}s`,
                }}
              />
            ))}
          </div>
        </button>
      )
    }

    if (submitted && submitted.tags.length > 0) {
      const isCreate = submitted.isAgendaCreation
      const needsConfirm = submitted.needsConfirm
      return (
        <div className={`flex-1 rounded-lg flex items-center justify-center gap-2 button-shadow h-12 px-3 ${needsConfirm ? 'bg-accent-light' : isCreate ? 'bg-accent-light' : 'voice-button-gradient'}`}>
          <Check size={20} className={`shrink-0 ${needsConfirm ? 'text-accent' : isCreate ? 'text-accent' : 'text-white'}`} />
          <span className={`text-body-small font-medium shrink-0 ${needsConfirm ? 'text-accent' : isCreate ? 'text-accent' : 'text-white'}`}>
            {needsConfirm
              ? submitted.agendaCreated > 1
                ? `${submitted.agendaCreated}项事程待确认`
                : '事程待确认'
              : isCreate
                ? submitted.agendaCreated > 1
                  ? `已创建${submitted.agendaCreated}项事程`
                  : '已创建事程'
                : '已记录'}
          </span>
          <div className="flex items-center gap-1 flex-wrap">
            {submitted.tags.slice(0, 2).map((tagId, idx) => {
              const def = getTagDef(tagId)
              return (
                <span
                  key={idx}
                  className={`text-caption px-1.5 py-0.5 rounded-sm ${needsConfirm || isCreate ? 'bg-accent/20 text-accent' : 'bg-white/25 text-white'}`}
                >
                  {def?.name ?? '已删除'}
                </span>
              )
            })}
          </div>
        </div>
      )
    }

    return (
      <button
        className="flex-1 rounded-lg voice-button-gradient flex items-center justify-center gap-3 transition-fast active:scale-[0.98] button-shadow h-12"
        onClick={startRecording}
      >
        <Mic size={24} className="text-white" />
        <span className="text-body-small text-white/90 font-medium">
          点击说话，记录现在在做什么
        </span>
        <div className="flex items-center gap-0.5">
          {[1, 2, 3, 4, 5].map((i) => (
            <div
              key={i}
              className="w-1 bg-white/40 rounded-full wave-bar"
              style={{
                height: `${6 + (i % 3) * 3}px`,
                animationDelay: `${i * 0.1}s`,
              }}
            />
          ))}
        </div>
      </button>
    )
  })()

  return (
    <>
      <div className="px-4 py-2 flex items-center gap-2">
        <button
          className="w-12 h-12 rounded-lg bg-bg-tertiary flex items-center justify-center shrink-0 transition-fast active:bg-border"
          onClick={() => setShowInput(true)}
          title="手动输入"
        >
          <Keyboard size={20} className="text-text-secondary" />
        </button>
        {voiceBtn}
      </div>

      {/* 文字输入弹窗 */}
      {showInput && (
        <div className="fixed inset-0 z-50 flex items-end justify-center">
          <div className="absolute inset-0 bg-black/40" onClick={handleCloseInput} />
          <div className="relative w-full max-w-[390px] bg-bg-secondary rounded-t-xl px-4 pt-5 pb-6 animate-[pageEnter_250ms_ease-out]">
            <div className="w-10 h-1 bg-bg-tertiary rounded-full mx-auto mb-4" />
            <div className="flex items-center justify-between mb-3">
              <div className="flex items-center gap-2">
                <Sparkles size={16} className="text-accent" />
                <h2 className="text-title-small font-semibold text-text-primary">记录现在</h2>
              </div>
              <button
                className="w-6 h-6 flex items-center justify-center text-text-secondary active:opacity-60"
                onClick={handleCloseInput}
              >
                <X size={18} />
              </button>
            </div>
            <p className="text-caption text-text-tertiary mb-3">输入你现在正在做什么，系统会自动识别标签</p>
            <textarea
              value={inputText}
              onChange={(e) => setInputText(e.target.value)}
              placeholder="如：回家，钥匙放在门口鞋柜上了"
              rows={3}
              className="w-full bg-bg-tertiary rounded-md px-3 py-2.5 text-body text-text-primary outline-none focus:ring-2 focus:ring-accent resize-none placeholder:text-text-tertiary mb-3"
              autoFocus
            />
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
            <div className="flex gap-3">
              <button
                className="flex-1 py-3 bg-bg-tertiary rounded-md text-body-small font-medium text-text-secondary active:bg-border transition-fast"
                onClick={handleCloseInput}
              >
                取消
              </button>
              <button
                className="flex-1 py-3 bg-accent rounded-md text-white text-body-small font-medium active:bg-text-primary transition-fast flex items-center justify-center gap-1.5"
                onClick={handleSubmitText}
                disabled={!inputText.trim()}
              >
                <Send size={16} />
                记录
              </button>
            </div>
            {inputSubmitted && inputSubmitted.tags.length > 0 && (
              <div className="mt-3 pt-3 border-t border-border flex items-center justify-center gap-1.5 flex-wrap">
                <span className={`text-caption ${inputSubmitted.needsConfirm || inputSubmitted.isAgendaCreation ? 'text-accent' : 'text-success'}`}>
                  {inputSubmitted.needsConfirm
                    ? inputSubmitted.agendaCreated > 1
                      ? `${inputSubmitted.agendaCreated}项事程待确认`
                      : '事程待确认'
                    : inputSubmitted.isAgendaCreation
                      ? inputSubmitted.agendaCreated > 1
                        ? `已创建${inputSubmitted.agendaCreated}项事程`
                        : '已创建事程'
                      : '已记录到时间线'}
                </span>
                {inputSubmitted.tags.map((tagId, idx) => {
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

      {/* 事程确认弹窗 */}
      <AgendaConfirmModal
        visible={showConfirmModal}
        onClose={() => setShowConfirmModal(false)}
      />
    </>
  )
}

export default VoiceButton

import { useState, useRef, useEffect } from 'react'
import { Mic, Check } from 'lucide-react'
import { useAppStore } from '../store/appStore'

// 快捷示例语句（覆盖4种类型 + 多标签场景）
const samplePhrases: { text: string; label: string }[] = [
  { text: '回家，钥匙放在门口鞋柜上了', label: '回家放钥匙' },
  { text: '在超市买了苹果2斤，牛奶3瓶', label: '买东西' },
  { text: '正在喝水', label: '喝水' },
  { text: '拿了快递', label: '拿快递' },
]

const VoiceButton = () => {
  const submitVoiceRecord = useAppStore(s => s.submitVoiceRecord)
  const getTagDef = useAppStore(s => s.getTagDef)

  // 录音状态：idle 待机 / recording 录音中
  const [status, setStatus] = useState<'idle' | 'recording'>('idle')
  // 录音计时
  const [recordSeconds, setRecordSeconds] = useState(0)
  // 提交成功提示（含标签ID列表，渲染时查 getTagDef）
  const [submitted, setSubmitted] = useState<{ tags: string[] } | null>(null)

  const timerRef = useRef<ReturnType<typeof setInterval> | null>(null)
  const stopTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null)

  // 开始录音
  const startRecording = () => {
    setStatus('recording')
    setRecordSeconds(0)
    timerRef.current = setInterval(() => {
      setRecordSeconds(s => s + 1)
    }, 1000)
    // 模拟：3秒后自动停止并直接提交
    stopTimerRef.current = setTimeout(() => {
      stopRecording()
    }, 3000)
  }

  // 停止录音 → 直接提交到时间线（无确认步骤）
  const stopRecording = () => {
    if (timerRef.current) clearInterval(timerRef.current)
    if (stopTimerRef.current) clearTimeout(stopTimerRef.current)
    setRecordSeconds(0)
    // 模拟语音识别结果（从示例中随机或默认第一条）
    const text = samplePhrases[Math.floor(Math.random() * samplePhrases.length)].text
    const result = submitVoiceRecord(text)
    // 显示提交成功提示
    setSubmitted({ tags: result.tags })
    setStatus('idle')
    setTimeout(() => setSubmitted(null), 2000)
  }

  // 手动停止
  const manualStop = () => {
    if (recordSeconds >= 1) {
      stopRecording()
    }
  }

  // 清理定时器
  useEffect(() => {
    return () => {
      if (timerRef.current) clearInterval(timerRef.current)
      if (stopTimerRef.current) clearTimeout(stopTimerRef.current)
    }
  }, [])

  // ===== 录音中状态 =====
  if (status === 'recording') {
    return (
      <div className="px-4 py-2">
        <button
          className="w-full rounded-lg voice-button-gradient flex items-center justify-center gap-3 transition-fast active:scale-[0.98] button-shadow h-12"
          onClick={manualStop}
        >
          <Mic size={24} className="text-white animate-pulse" />
          <span className="text-body-small text-white font-medium">
            正在录音... {String(recordSeconds).padStart(2, '0')}s
          </span>
          {/* 波形动画 */}
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
      </div>
    )
  }

  // ===== 提交成功提示 =====
  if (submitted && submitted.tags.length > 0) {
    return (
      <div className="px-4 py-2">
        <div className="rounded-lg voice-button-gradient flex items-center justify-center gap-2 button-shadow h-12">
          <Check size={20} className="text-white" />
          <span className="text-body-small text-white font-medium">已记录</span>
          <div className="flex items-center gap-1">
            {submitted.tags.slice(0, 3).map((tagId, idx) => {
              const def = getTagDef(tagId)
              return (
                <span
                  key={idx}
                  className="text-caption px-1.5 py-0.5 bg-white/25 text-white rounded-sm"
                >
                  {def?.name ?? '已删除'}
                </span>
              )
            })}
          </div>
        </div>
      </div>
    )
  }

  // ===== 待机状态 =====
  return (
    <div className="px-4 py-2">
      <button
        className="w-full rounded-lg voice-button-gradient flex items-center justify-center gap-3 transition-fast active:scale-[0.98] button-shadow h-12"
        onClick={startRecording}
      >
        <Mic size={24} className="text-white" />
        <span className="text-body-small text-white/90 font-medium">
          点击说话，记录现在在做什么
        </span>
        {/* 波形动画 */}
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
    </div>
  )
}

export default VoiceButton

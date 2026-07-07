import { useState, useRef } from 'react'
import { X, Mic, Check, Clock, Sparkles, Bell, ChevronRight } from 'lucide-react'
import { useAppStore } from '../store/appStore'

interface CreateAgendaModalProps {
  visible: boolean
  onClose: () => void
  onNavigateFrequent?: () => void
}

type Step = 'select' | 'voice' | 'text'
type AgendaLevel = '普通' | '重要' | '必做'

const CreateAgendaModal = ({ visible, onClose, onNavigateFrequent }: CreateAgendaModalProps) => {
  const addAgenda = useAppStore(s => s.addAgenda)
  const inferAgendaTimeByContent = useAppStore(s => s.inferAgendaTimeByContent)
  const inferAgendaTimeByCommonSense = useAppStore(s => s.inferAgendaTimeByCommonSense)
  const autoDetectIcon = useAppStore(s => s.autoDetectIcon)

  const [step, setStep] = useState<Step>('select')
  const [isRecording, setIsRecording] = useState(false)
  const [voiceHint, setVoiceHint] = useState('')

  // 表单状态
  const [formTime, setFormTime] = useState('')
  const [formContent, setFormContent] = useState('')
  const [formIcon, setFormIcon] = useState('📋')
  const [formLevel, setFormLevel] = useState<AgendaLevel>('普通')
  const [formTimeSource, setFormTimeSource] = useState<string>('')

  const recordTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null)

  if (!visible) return null

  const resetForm = () => {
    setFormTime('')
    setFormContent('')
    setFormIcon('📋')
    setFormLevel('普通')
    setFormTimeSource('')
    setVoiceHint('')
  }

  const handleClose = () => {
    setStep('select')
    resetForm()
    onClose()
  }

  const handleSelectVoice = () => {
    resetForm()
    setStep('voice')
  }

  const handleSelectText = () => {
    resetForm()
    const now = new Date()
    setFormTime(`${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}`)
    setFormTimeSource('当前时间')
    setStep('text')
  }

  // 语音录入
  const handleVoiceStart = () => {
    setIsRecording(true)
    setVoiceHint('正在录音...松开自动识别')
    recordTimerRef.current = setTimeout(() => {
      handleVoiceEnd()
    }, 3000)
  }

  const handleVoiceEnd = () => {
    if (recordTimerRef.current) {
      clearTimeout(recordTimerRef.current)
      recordTimerRef.current = null
    }
    setIsRecording(false)

    // 模拟语音识别
    const sampleTexts = ['记得吃药', '下午3点开会', '别忘了喝水', '晚饭后散步']
    const text = sampleTexts[Math.floor(Math.random() * sampleTexts.length)]

    // 提取时间
    let extractedTime = ''
    const hhmmMatch = text.match(/(\d{1,2})[:：](\d{2})/)
    const pointMatch = text.match(/(\d{1,2})点(?:(\d{1,2})分)?/)
    const periodMatch = text.match(/(早上|上午|中午|下午|晚上|凌晨)(\d{1,2})?(?:点)?(?:(\d{1,2})分)?/)

    if (hhmmMatch) {
      extractedTime = `${String(Number(hhmmMatch[1])).padStart(2, '0')}:${hhmmMatch[2]}`
    } else if (pointMatch) {
      const hour = Number(pointMatch[1])
      const min = pointMatch[2] ? Number(pointMatch[2]) : 0
      let finalHour = hour
      if ((text.includes('下午') || text.includes('晚上')) && hour < 12) finalHour = hour + 12
      extractedTime = `${String(finalHour).padStart(2, '0')}:${String(min).padStart(2, '0')}`
    } else if (periodMatch) {
      const period = periodMatch[1]
      const hour = periodMatch[2] ? Number(periodMatch[2]) : null
      const min = periodMatch[3] ? Number(periodMatch[3]) : 0
      if (hour !== null) {
        let finalHour = hour
        if ((period === '下午' || period === '晚上') && hour < 12) finalHour = hour + 12
        extractedTime = `${String(finalHour).padStart(2, '0')}:${String(min).padStart(2, '0')}`
      }
    }

    // 提取内容
    let extractedContent = text
      .replace(/^(记得|别忘了|提醒我|要记得|一定要|需要|要做|得去|准备)[，, ]?/, '')
      .replace(/(早上|上午|中午|下午|晚上|凌晨)?\d{1,2}点(?:\d{1,2}分)?[钟]?[，, ]?/, '')
      .replace(/\d{1,2}[:：]\d{2}[，, ]?/, '')
      .trim()

    // 智能推断时间
    if (!extractedTime) {
      const fromHistory = inferAgendaTimeByContent(extractedContent)
      if (fromHistory) {
        extractedTime = fromHistory
        setFormTimeSource('根据习惯推荐')
      } else {
        const fromCommon = inferAgendaTimeByCommonSense(extractedContent)
        if (fromCommon) {
          extractedTime = fromCommon
          setFormTimeSource('根据常识推荐')
        } else {
          const now = new Date()
          extractedTime = `${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}`
          setFormTimeSource('当前时间')
        }
      }
    } else {
      setFormTimeSource('已识别时间')
    }

    // 自动识别图标
    const detectedIcon = autoDetectIcon(extractedContent)

    setFormTime(extractedTime)
    setFormContent(extractedContent)
    setFormIcon(detectedIcon)
    setVoiceHint('已识别，可修改后保存')

    // 自动切换到文字编辑步骤，方便用户修改
    setTimeout(() => {
      setStep('text')
    }, 600)
  }

  // 保存事程
  const handleSave = () => {
    if (!formContent.trim()) return
    addAgenda({
      icon: formIcon,
      time: formTime,
      content: formContent,
      isMustDo: formLevel === '必做',
      category: formLevel,
    })
    handleClose()
  }

  return (
    <div className="fixed inset-0 z-50 flex items-end justify-center">
      <div className="absolute inset-0 bg-black/40" onClick={handleClose} />

      <div className="relative w-full max-w-[390px] bg-bg-secondary rounded-t-xl overflow-hidden animate-[pageEnter_250ms_ease-out]">
        {/* 顶部拖动条 + 关闭 */}
        <div className="flex items-center justify-between px-4 pt-4 pb-2">
          <div className="w-10 h-1 bg-bg-tertiary rounded-full mx-0" />
          <button
            className="w-7 h-7 flex items-center justify-center text-text-tertiary active:opacity-60"
            onClick={handleClose}
          >
            <X size={16} />
          </button>
        </div>

        {/* ===== 步骤1：选择方式 ===== */}
        {step === 'select' && (
          <div className="px-4 pb-6">
            <h2 className="text-title-small font-semibold text-text-primary text-center mb-4">创建事程</h2>

            {/* 语音创建 */}
            <button
              className="w-full flex items-center gap-3 p-4 bg-accent-light rounded-lg mb-2.5 transition-fast active:bg-accent/15"
              onClick={handleSelectVoice}
            >
              <div className="w-11 h-11 bg-accent rounded-full flex items-center justify-center text-white shrink-0">
                <Mic size={20} />
              </div>
              <div className="flex-1 text-left">
                <div className="text-body font-medium text-accent">语音创建</div>
                <div className="text-caption text-text-secondary mt-0.5">按住说话，自动识别内容和时间</div>
              </div>
            </button>

            {/* 文字创建 */}
            <button
              className="w-full flex items-center gap-3 p-4 bg-bg-tertiary rounded-lg mb-2.5 transition-fast active:bg-border"
              onClick={handleSelectText}
            >
              <div className="w-11 h-11 bg-bg-secondary rounded-full flex items-center justify-center text-xl shrink-0">✏</div>
              <div className="flex-1 text-left">
                <div className="text-body font-medium text-text-primary">文字创建</div>
                <div className="text-caption text-text-secondary mt-0.5">手动输入事程内容和时间</div>
              </div>
              <ChevronRight size={18} className="text-text-tertiary shrink-0" />
            </button>

            {/* 常用事程 */}
            <button
              className="w-full flex items-center gap-3 p-4 bg-bg-tertiary rounded-lg transition-fast active:bg-border"
              onClick={() => { handleClose(); onNavigateFrequent?.() }}
            >
              <div className="w-11 h-11 bg-bg-secondary rounded-full flex items-center justify-center text-xl shrink-0">⭐</div>
              <div className="flex-1 text-left">
                <div className="text-body font-medium text-text-primary">从常用事程选择</div>
                <div className="text-caption text-text-secondary mt-0.5">快速添加常用的高频行为</div>
              </div>
              <ChevronRight size={18} className="text-text-tertiary shrink-0" />
            </button>
          </div>
        )}

        {/* ===== 步骤2：语音录入 ===== */}
        {step === 'voice' && (
          <div className="px-4 pb-6">
            <h2 className="text-title-small font-semibold text-text-primary text-center mb-6">按住说话</h2>

            {/* 语音按钮 */}
            <button
              className={`w-full rounded-xl flex items-center justify-center gap-3 transition-fast active:scale-[0.98] h-20 ${
                isRecording
                  ? 'bg-danger text-white animate-pulse'
                  : 'bg-accent text-white button-shadow'
              }`}
              onPointerDown={handleVoiceStart}
              onPointerUp={handleVoiceEnd}
              onPointerLeave={() => isRecording && handleVoiceEnd()}
            >
              <Mic size={28} />
              <span className="text-body font-medium">
                {isRecording ? '松开自动识别' : '按住说话，创建事程'}
              </span>
            </button>

            {voiceHint && (
              <div className="mt-3 flex items-center justify-center gap-1.5 text-caption text-accent">
                <Sparkles size={12} />
                {voiceHint}
              </div>
            )}

            <button
              className="w-full mt-5 py-3 bg-bg-tertiary rounded-lg text-body font-medium text-text-secondary active:bg-border transition-fast"
              onClick={() => setStep('select')}
            >
              返回
            </button>
          </div>
        )}

        {/* ===== 步骤3：编辑确认 ===== */}
        {step === 'text' && (
          <div className="px-4 pb-6">
            <h2 className="text-title-small font-semibold text-text-primary text-center mb-4">
              {formContent ? '确认事程' : '创建事程'}
            </h2>

            {/* 图标 + 内容 */}
            <div className="flex items-center gap-3 mb-3">
              <div className="w-12 h-12 bg-bg-tertiary rounded-lg flex items-center justify-center text-2xl shrink-0">
                {formIcon}
              </div>
              <input
                type="text"
                value={formContent}
                placeholder="事程内容"
                onChange={(e) => {
                  setFormContent(e.target.value)
                  if (e.target.value) {
                    setFormIcon(autoDetectIcon(e.target.value))
                  }
                }}
                className="flex-1 bg-bg-tertiary rounded-md px-3 py-3 text-body text-text-primary outline-none focus:ring-2 focus:ring-accent placeholder:text-text-tertiary"
                autoFocus
              />
            </div>

            {/* 时间 */}
            <div className="flex items-center gap-2 mb-3">
              <Clock size={16} className="text-accent shrink-0" />
              <input
                type="text"
                value={formTime}
                placeholder="时间 如 15:00"
                onChange={(e) => {
                  setFormTime(e.target.value)
                  setFormTimeSource('')
                }}
                className="flex-1 bg-bg-tertiary rounded-md px-3 py-2.5 text-body text-text-primary outline-none focus:ring-2 focus:ring-accent placeholder:text-text-tertiary font-mono"
              />
              {formTimeSource && (
                <span className="text-caption text-accent shrink-0 flex items-center gap-1">
                  <Sparkles size={10} />
                  {formTimeSource}
                </span>
              )}
            </div>

            {/* 事程级别 */}
            <div className="py-2.5 border-t border-border">
              <div className="flex items-center gap-2 mb-2">
                <Bell size={16} className="text-accent" />
                <span className="text-body-small font-medium text-text-primary">事程级别</span>
              </div>
              <div className="flex gap-2">
                {(['普通', '重要', '必做'] as AgendaLevel[]).map((level) => (
                  <button
                    key={level}
                    className={`flex-1 py-2 rounded-md text-body-small font-medium transition-fast ${
                      formLevel === level
                        ? level === '必做'
                          ? 'bg-danger text-white'
                          : level === '重要'
                            ? 'bg-warning text-white'
                            : 'bg-accent text-white'
                        : 'bg-bg-tertiary text-text-secondary active:bg-border'
                    }`}
                    onClick={() => setFormLevel(level)}
                  >
                    {level}
                  </button>
                ))}
              </div>
            </div>

            {/* 提示 */}
            <div className="mt-3 mb-2">
              <p className="text-caption text-text-tertiary">
                提醒策略可在「我的 → 提醒规则」中设置
              </p>
            </div>

            {/* 操作按钮 */}
            <div className="flex gap-3 mt-2">
              <button
                className="flex-1 py-3 bg-bg-tertiary rounded-lg text-body-small font-medium text-text-secondary active:bg-border transition-fast"
                onClick={() => setStep('select')}
              >
                取消
              </button>
              <button
                className="flex-1 py-3 bg-accent rounded-lg text-white text-body-small font-medium active:bg-text-primary transition-fast flex items-center justify-center gap-1.5"
                onClick={handleSave}
                disabled={!formContent.trim()}
              >
                <Check size={16} />
                创建
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  )
}

export default CreateAgendaModal

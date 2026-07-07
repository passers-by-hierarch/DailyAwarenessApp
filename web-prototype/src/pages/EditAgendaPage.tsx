import { useState, useEffect, useRef } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { ChevronLeft, Save, Mic, AlertTriangle, Clock, Sparkles } from 'lucide-react'
import { useAppStore } from '../store/appStore'

const EditAgendaPage = () => {
  const navigate = useNavigate()
  const { id } = useParams()

  const existingAgenda = useAppStore(s => s.agendaItems.find(a => a.id === id))
  const addAgenda = useAppStore(s => s.addAgenda)
  const updateAgenda = useAppStore(s => s.updateAgenda)
  const submitVoiceRecord = useAppStore(s => s.submitVoiceRecord)
  const inferAgendaTimeByContent = useAppStore(s => s.inferAgendaTimeByContent)
  const inferAgendaTimeByCommonSense = useAppStore(s => s.inferAgendaTimeByCommonSense)

  const isEditMode = !!id

  const [agenda, setAgenda] = useState({
    icon: '📋',
    time: '',
    content: '',
    isMustDo: false,
  })

  // 语音录入状态
  const [isRecording, setIsRecording] = useState(false)
  const [voiceHint, setVoiceHint] = useState('')
  const recordTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null)

  useEffect(() => {
    if (isEditMode && existingAgenda) {
      setAgenda({
        icon: existingAgenda.icon || '📋',
        time: existingAgenda.time,
        content: existingAgenda.content,
        isMustDo: existingAgenda.isMustDo,
      })
    } else {
      // 创建模式：默认当前时间
      const now = new Date()
      setAgenda(prev => ({
        ...prev,
        time: `${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}`,
      }))
    }
  }, [isEditMode, existingAgenda])

  // 按住开始语音录入
  const handleVoiceStart = () => {
    setIsRecording(true)
    setVoiceHint('正在录音...松开自动识别')
    // 3秒后自动停止
    recordTimerRef.current = setTimeout(() => {
      handleVoiceEnd()
    }, 3000)
  }

  // 松开结束语音录入，模拟识别
  const handleVoiceEnd = () => {
    if (recordTimerRef.current) {
      clearTimeout(recordTimerRef.current)
      recordTimerRef.current = null
    }
    setIsRecording(false)
    setVoiceHint('')

    // 模拟语音识别结果（测试用）
    const sampleTexts = ['记得吃药', '下午3点开会', '别忘了喝水', '晚饭后散步']
    const text = sampleTexts[Math.floor(Math.random() * sampleTexts.length)]

    // 用 parseVoiceText 解析时间和内容
    const result = submitVoiceRecord(text)
    // 从解析结果中提取时间和内容
    if (result.isAgendaCreation && result.agendaCreated > 0) {
      // 从 pendingAgendaConfirm 中获取最新添加的
      // 但这里我们直接解析文本更简单
    }

    // 直接从文本中提取
    let extractedTime = ''
    let extractedContent = text

    // 提取时间
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

    // 提取内容（去掉提醒词和时间）
    extractedContent = text
      .replace(/^(记得|别忘了|提醒我|要记得|一定要|需要|要做|得去|准备)[，, ]?/, '')
      .replace(/(早上|上午|中午|下午|晚上|凌晨)?\d{1,2}点(?:\d{1,2}分)?[钟]?[，, ]?/, '')
      .replace(/\d{1,2}[:：]\d{2}[，, ]?/, '')
      .trim()

    // 如果没有明确时间，智能推断
    if (!extractedTime) {
      const fromHistory = inferAgendaTimeByContent(extractedContent)
      if (fromHistory) {
        extractedTime = fromHistory
        setVoiceHint(`根据您的习惯推荐: ${fromHistory}`)
      } else {
        const fromCommon = inferAgendaTimeByCommonSense(extractedContent)
        if (fromCommon) {
          extractedTime = fromCommon
          setVoiceHint(`根据常识推荐: ${fromCommon}`)
        } else {
          const now = new Date()
          extractedTime = `${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}`
          setVoiceHint('使用当前时间')
        }
      }
    } else {
      setVoiceHint('已识别时间')
    }

    setAgenda(prev => ({
      ...prev,
      time: extractedTime,
      content: extractedContent,
    }))

    setTimeout(() => setVoiceHint(''), 3000)
  }

  // 保存事程
  const handleSave = () => {
    if (!agenda.content.trim()) {
      alert('请输入事程内容')
      return
    }
    if (!agenda.time.trim()) {
      alert('请输入事程时间')
      return
    }
    if (isEditMode && existingAgenda) {
      updateAgenda(existingAgenda.id, {
        icon: agenda.icon,
        time: agenda.time,
        content: agenda.content,
        isMustDo: agenda.isMustDo,
      })
    } else {
      addAgenda({
        icon: agenda.icon,
        time: agenda.time,
        content: agenda.content,
        isMustDo: agenda.isMustDo,
      })
    }
    navigate(-1)
  }

  return (
    <div className="page-enter min-h-screen bg-bg-primary pb-24">
      {/* 顶部导航栏 */}
      <header className="px-4 py-3 bg-bg-secondary border-b border-border flex items-center justify-between sticky top-0 z-40">
        <button
          className="w-8 h-8 flex items-center justify-center text-text-primary transition-fast active:opacity-60"
          onClick={() => navigate(-1)}
        >
          <ChevronLeft size={24} />
        </button>
        <h1 className="text-body font-semibold text-text-primary">{isEditMode ? '编辑事程' : '创建事程'}</h1>
        <button
          className="text-body-small font-medium text-accent transition-fast active:opacity-60 flex items-center gap-1"
          onClick={handleSave}
        >
          <Save size={16} />
          保存
        </button>
      </header>

      {/* 语音录入区 */}
      <section className="px-4 pt-4">
        <button
          className={`w-full rounded-lg flex items-center justify-center gap-3 transition-fast active:scale-[0.98] h-14 ${
            isRecording
              ? 'bg-danger text-white animate-pulse'
              : 'bg-accent text-white button-shadow'
          }`}
          onPointerDown={handleVoiceStart}
          onPointerUp={handleVoiceEnd}
          onPointerLeave={() => isRecording && handleVoiceEnd()}
        >
          <Mic size={22} />
          <span className="text-body font-medium">
            {isRecording ? '松开自动识别' : '按住说话，创建事程'}
          </span>
        </button>
        {voiceHint && (
          <div className="mt-2 flex items-center justify-center gap-1.5 text-caption text-accent">
            <Sparkles size={12} />
            {voiceHint}
          </div>
        )}
      </section>

      {/* 基本信息 */}
      <section className="px-4 mt-4">
        <div className="bg-bg-secondary rounded-lg card-shadow p-4">
          {/* 时间 */}
          <div className="mb-4">
            <label className="text-body-small font-semibold text-text-secondary mb-2 flex items-center gap-1.5">
              <Clock size={14} />
              事程时间
            </label>
            <input
              type="text"
              value={agenda.time}
              placeholder="例如: 15:00"
              onChange={(e) => setAgenda({ ...agenda, time: e.target.value })}
              className="w-full bg-bg-tertiary rounded-md px-4 py-3 text-body text-text-primary outline-none focus:ring-2 focus:ring-accent placeholder:text-text-tertiary"
            />
          </div>

          {/* 内容 */}
          <div className="mb-4">
            <label className="text-body-small font-semibold text-text-secondary mb-2 block">事程内容</label>
            <input
              type="text"
              value={agenda.content}
              placeholder="例如: 吃药"
              onChange={(e) => setAgenda({ ...agenda, content: e.target.value })}
              className="w-full bg-bg-tertiary rounded-md px-4 py-3 text-body text-text-primary outline-none focus:ring-2 focus:ring-accent placeholder:text-text-tertiary"
            />
          </div>

          {/* 图标选择 */}
          <div className="mb-4">
            <label className="text-body-small font-semibold text-text-secondary mb-2 block">图标</label>
            <div className="flex gap-2 overflow-x-auto pb-2">
              {['📋', '💊', '🍚', '💧', '🏃', '📖', '🛏', '🧹', '🛒', '✈️'].map((icon) => (
                <button
                  key={icon}
                  className={`w-11 h-11 bg-bg-tertiary rounded-lg flex items-center justify-center text-xl transition-fast shrink-0 ${
                    agenda.icon === icon ? 'ring-2 ring-accent bg-accent-light' : 'active:bg-bg-tertiary'
                  }`}
                  onClick={() => setAgenda({ ...agenda, icon })}
                >
                  {icon}
                </button>
              ))}
            </div>
          </div>

          {/* 必做标记 */}
          <div className="flex items-center justify-between py-3 border-t border-border">
            <div className="flex items-center gap-2">
              <AlertTriangle size={18} className="text-danger" />
              <div>
                <div className="text-body-small font-medium text-text-primary">必做事程</div>
                <div className="text-caption text-text-tertiary">强制提醒，不可跳过</div>
              </div>
            </div>
            <button
              className={`relative w-11 h-6 rounded-full transition-fast ${
                agenda.isMustDo ? 'bg-danger' : 'bg-bg-tertiary'
              }`}
              onClick={() => setAgenda({ ...agenda, isMustDo: !agenda.isMustDo })}
            >
              <div
                className={`absolute top-0.5 w-5 h-5 bg-white rounded-full shadow-sm transition-fast ${
                  agenda.isMustDo ? 'left-[22px]' : 'left-0.5'
                }`}
              />
            </button>
          </div>
        </div>
      </section>

      {/* 提示 */}
      <div className="px-4 mt-4">
        <div className="bg-info-light rounded-md px-4 py-3">
          <p className="text-caption text-info">
            提醒规则可在「我的 → 提醒规则」中统一设置
          </p>
        </div>
      </div>

      {/* 底部保存按钮 */}
      <div className="sticky bottom-0 left-0 right-0 bg-bg-secondary border-t border-border px-4 py-3 flex gap-3 z-40">
        <button
          className="flex-1 py-3 bg-accent rounded-md text-white text-body-small font-medium transition-fast active:bg-text-primary button-shadow"
          onClick={handleSave}
        >
          {isEditMode ? '保存事程' : '创建事程'}
        </button>
        <button
          className="flex-1 py-3 bg-bg-tertiary rounded-md text-text-secondary text-body-small font-medium transition-fast active:bg-border"
          onClick={() => navigate(-1)}
        >
          取消
        </button>
      </div>
    </div>
  )
}

export default EditAgendaPage

import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import {
  ChevronLeft, Bell, Clock, AlertCircle, Check, Plus, Settings,
  Trash2, RotateCcw, Edit3, Volume2, Vibrate, Smartphone, MessageSquare,
  Mic, Zap, ArrowDown,
} from 'lucide-react'

// 提醒方式配置
const allReminderMethods = [
  { id: 'notification', name: '通知栏', icon: Smartphone },
  { id: 'sound', name: '声音', icon: Volume2 },
  { id: 'vibrate', name: '震动', icon: Vibrate },
  { id: 'popup', name: '弹窗', icon: MessageSquare },
  { id: 'voice', name: '语音播报', icon: Mic },
]

// 条件触发类型
const conditionTypes = [
  { id: 'time', name: '时间触发', desc: '指定时间点自动触发', icon: '⏰' },
  { id: 'location', name: '到达位置', desc: '到达指定位置时触发', icon: '📍' },
  { id: 'behavior', name: '行为联动', desc: '完成某行为后触发', icon: '🔗' },
  { id: 'weather', name: '天气触发', desc: '根据天气情况触发', icon: '🌤' },
]

interface LevelStrategy {
  id: string
  name: string
  desc: string
  color: string
  advanceTime: string
  repeatInterval: string
  maxTimes: string
  allowDelay: boolean
  allowSkip: boolean
  sound: string
  volume: string
  methods: string[]
}

interface CustomStrategy {
  id: string
  name: string
  keyword: string
  level: string
  advanceTime: string
  repeatInterval: string
  maxTimes: string
  methods: string[]
  condition: string
}

// 原始默认级别策略（用于一键复原）
const defaultLevels: LevelStrategy[] = [
  {
    id: 'normal',
    name: '普通',
    desc: '日常事项，温和提醒',
    color: 'accent',
    advanceTime: '10分钟',
    repeatInterval: '15分钟',
    maxTimes: '3次',
    allowDelay: true,
    allowSkip: true,
    sound: '柔和',
    volume: '中',
    methods: ['notification', 'sound'],
  },
  {
    id: 'important',
    name: '重要',
    desc: '重要事项，适度提醒',
    color: 'warning',
    advanceTime: '15分钟',
    repeatInterval: '10分钟',
    maxTimes: '5次',
    allowDelay: true,
    allowSkip: false,
    sound: '标准',
    volume: '高',
    methods: ['notification', 'sound', 'vibrate'],
  },
  {
    id: 'must',
    name: '必做',
    desc: '必做事项，强制提醒',
    color: 'danger',
    advanceTime: '20分钟',
    repeatInterval: '5分钟',
    maxTimes: '10次',
    allowDelay: false,
    allowSkip: false,
    sound: '紧急',
    volume: '最高',
    methods: ['notification', 'sound', 'vibrate', 'popup'],
  },
]

const ReminderRulesPage = () => {
  const navigate = useNavigate()

  const [levels, setLevels] = useState<LevelStrategy[]>(defaultLevels.map(l => ({ ...l, methods: [...l.methods] })))
  const [editingLevel, setEditingLevel] = useState<LevelStrategy | null>(null)
  const [customStrategies, setCustomStrategies] = useState<CustomStrategy[]>([
    {
      id: 'c1',
      name: '吃药专属提醒',
      keyword: '吃药',
      level: '必做',
      advanceTime: '10分钟',
      repeatInterval: '5分钟',
      maxTimes: '5次',
      methods: ['notification', 'sound', 'popup'],
      condition: 'time',
    },
  ])
  const [showAddCustom, setShowAddCustom] = useState(false)
  const [editingCustom, setEditingCustom] = useState<CustomStrategy | null>(null)

  // 一键复原
  const handleReset = () => {
    setLevels(defaultLevels.map(l => ({ ...l, methods: [...l.methods] })))
    setEditingLevel(null)
  }

  // 保存级别策略编辑
  const handleSaveLevel = (level: LevelStrategy) => {
    setLevels(levels.map(l => l.id === level.id ? level : l))
    setEditingLevel(null)
  }

  // 自定义策略操作
  const handleDeleteCustom = (id: string) => {
    setCustomStrategies(customStrategies.filter(s => s.id !== id))
  }

  const handleSaveCustom = (strategy: CustomStrategy) => {
    if (editingCustom) {
      setCustomStrategies(customStrategies.map(s => s.id === strategy.id ? strategy : s))
    } else {
      setCustomStrategies([...customStrategies, { ...strategy, id: Date.now().toString() }])
    }
    setEditingCustom(null)
    setShowAddCustom(false)
  }

  // 颜色映射（避免 Tailwind 动态类名问题）
  const colorMap: Record<string, { bg: string; text: string; ring: string }> = {
    accent: { bg: 'bg-accent-light', text: 'text-accent', ring: 'ring-accent' },
    warning: { bg: 'bg-warning-light', text: 'text-warning', ring: 'ring-warning' },
    danger: { bg: 'bg-danger-light', text: 'text-danger', ring: 'ring-danger' },
  }

  return (
    <div className="page-enter min-h-screen bg-bg-primary pb-8">
      {/* 顶部导航栏 */}
      <header className="px-4 py-3 bg-bg-secondary border-b border-border flex items-center justify-between sticky top-0 z-40">
        <button
          className="w-8 h-8 flex items-center justify-center text-text-primary transition-fast active:opacity-60"
          onClick={() => navigate(-1)}
        >
          <ChevronLeft size={24} />
        </button>
        <h1 className="text-body font-semibold text-text-primary">提醒规则</h1>
        <button
          className="flex items-center gap-1 text-caption text-accent font-medium active:opacity-60"
          onClick={handleReset}
        >
          <RotateCcw size={14} />
          复原
        </button>
      </header>

      {/* 优先级说明 */}
      <div className="px-4 py-3">
        <div className="bg-info-light rounded-md px-4 py-3">
          <div className="flex items-center gap-2 mb-2">
            <AlertCircle size={16} className="text-info shrink-0" />
            <span className="text-body-small font-semibold text-info">提醒优先级</span>
          </div>
          <div className="flex items-center gap-2 text-caption text-info ml-6">
            <span className="px-2 py-0.5 bg-white/50 rounded-sm">自定义策略</span>
            <ArrowDown size={10} className="rotate-[-90deg]" />
            <span className="px-2 py-0.5 bg-white/50 rounded-sm">级别策略</span>
          </div>
          <p className="text-caption text-info mt-2 ml-6">
            创建事程时选择级别，自动应用对应策略；匹配到关键词时使用自定义策略覆盖
          </p>
        </div>
      </div>

      {/* 级别策略（三套同时生效） */}
      <section className="px-4 mt-2">
        <div className="px-1 py-2 flex items-center gap-2">
          <Bell size={16} className="text-accent" />
          <h2 className="text-body-small font-semibold text-text-secondary">级别策略</h2>
          <span className="text-caption text-text-tertiary">按事程级别自动触发</span>
        </div>

        <div className="space-y-2.5">
          {levels.map((level) => {
            const c = colorMap[level.color]
            const isModified = JSON.stringify(level) !== JSON.stringify(defaultLevels.find(d => d.id === level.id))
            return (
              <div key={level.id} className="bg-bg-secondary rounded-lg card-shadow p-4">
                {/* 顶部标题 */}
                <div className="flex items-center justify-between mb-3">
                  <div className="flex items-center gap-2">
                    <div className={`w-8 h-8 rounded-md flex items-center justify-center ${c.bg} ${c.text}`}>
                      <Bell size={16} />
                    </div>
                    <div>
                      <div className="text-body-small font-semibold text-text-primary flex items-center gap-1.5">
                        {level.name}
                        {isModified && (
                          <span className="text-caption text-warning">●已修改</span>
                        )}
                      </div>
                      <div className="text-caption text-text-tertiary">{level.desc}</div>
                    </div>
                  </div>
                  <button
                    className="px-3 py-1.5 rounded-md text-caption font-medium bg-bg-tertiary text-text-secondary active:bg-border transition-fast flex items-center gap-1"
                    onClick={() => setEditingLevel(level)}
                  >
                    <Edit3 size={12} />
                    编辑
                  </button>
                </div>

                {/* 配置详情 */}
                <div className="grid grid-cols-2 gap-x-4 gap-y-2 mb-3">
                  <div className="flex items-center gap-1">
                    <Clock size={12} className="text-text-secondary" />
                    <span className="text-caption text-text-secondary">提前{level.advanceTime}</span>
                  </div>
                  <div className="flex items-center gap-1">
                    <Clock size={12} className="text-text-secondary" />
                    <span className="text-caption text-text-secondary">间隔{level.repeatInterval}</span>
                  </div>
                  <div className="flex items-center gap-1">
                    <Bell size={12} className="text-text-secondary" />
                    <span className="text-caption text-text-secondary">最多{level.maxTimes}</span>
                  </div>
                  <div className="flex items-center gap-1">
                    <Check size={12} className={level.allowDelay ? 'text-success' : 'text-text-tertiary'} />
                    <span className={`text-caption ${level.allowDelay ? 'text-success' : 'text-text-tertiary'}`}>
                      {level.allowDelay ? '可延后' : '不可延后'}
                    </span>
                  </div>
                </div>

                {/* 提醒方式 */}
                <div className="flex flex-wrap gap-1.5 pt-2 border-t border-border">
                  {level.methods.map(mId => {
                    const m = allReminderMethods.find(am => am.id === mId)
                    if (!m) return null
                    const Icon = m.icon
                    return (
                      <span key={mId} className={`flex items-center gap-1 px-2 py-1 rounded-sm ${c.bg} ${c.text}`}>
                        <Icon size={11} />
                        <span className="text-caption">{m.name}</span>
                      </span>
                    )
                  })}
                  <span className="flex items-center gap-1 px-2 py-1 rounded-sm bg-bg-tertiary text-text-tertiary">
                    <Volume2 size={11} />
                    <span className="text-caption">{level.sound}·{level.volume}</span>
                  </span>
                </div>
              </div>
            )
          })}
        </div>
      </section>

      {/* 自定义策略 */}
      <section className="px-4 mt-6">
        <div className="px-1 py-2 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <Zap size={16} className="text-accent" />
            <h2 className="text-body-small font-semibold text-text-secondary">自定义策略</h2>
            <span className="text-caption text-text-tertiary">关键词覆盖</span>
          </div>
          <button
            className="text-caption text-accent font-medium flex items-center gap-1 active:opacity-60"
            onClick={() => { setEditingCustom(null); setShowAddCustom(true) }}
          >
            <Plus size={14} />
            添加
          </button>
        </div>

        {customStrategies.length === 0 ? (
          <div className="bg-bg-secondary rounded-lg card-shadow py-8 text-center">
            <div className="text-2xl mb-2">📋</div>
            <div className="text-body-small text-text-secondary mb-1">暂无自定义策略</div>
            <div className="text-caption text-text-tertiary">为特定行为设置专属提醒规则</div>
          </div>
        ) : (
          <div className="space-y-2.5">
            {customStrategies.map((strategy) => (
              <div key={strategy.id} className="bg-bg-secondary rounded-lg card-shadow p-4">
                <div className="flex items-center justify-between mb-2">
                  <div className="flex items-center gap-2">
                    <span className="px-2 py-0.5 bg-accent-light text-accent rounded-sm text-caption font-medium">
                      {strategy.keyword}
                    </span>
                    <span className="text-body-small font-medium text-text-primary">{strategy.name}</span>
                    <span className={`px-1.5 py-0.5 rounded-sm text-caption ${
                      strategy.level === '必做' ? 'bg-danger-light text-danger' :
                      strategy.level === '重要' ? 'bg-warning-light text-warning' : 'bg-accent-light text-accent'
                    }`}>
                      {strategy.level}
                    </span>
                  </div>
                  <div className="flex items-center gap-2">
                    <button
                      className="text-caption text-accent active:opacity-60"
                      onClick={() => { setEditingCustom(strategy); setShowAddCustom(true) }}
                    >
                      编辑
                    </button>
                    <button
                      className="text-text-tertiary active:opacity-60"
                      onClick={() => handleDeleteCustom(strategy.id)}
                    >
                      <Trash2 size={14} />
                    </button>
                  </div>
                </div>
                <div className="flex flex-wrap gap-x-4 gap-y-1 mb-2">
                  <span className="text-caption text-text-secondary">提前{strategy.advanceTime}</span>
                  <span className="text-caption text-text-secondary">间隔{strategy.repeatInterval}</span>
                  <span className="text-caption text-text-secondary">最多{strategy.maxTimes}次</span>
                  <span className="text-caption text-text-secondary flex items-center gap-1">
                    {conditionTypes.find(c => c.id === strategy.condition)?.icon}
                    {conditionTypes.find(c => c.id === strategy.condition)?.name}
                  </span>
                </div>
                <div className="flex flex-wrap gap-1.5 pt-2 border-t border-border">
                  {strategy.methods.map(mId => {
                    const m = allReminderMethods.find(am => am.id === mId)
                    if (!m) return null
                    const Icon = m.icon
                    return (
                      <span key={mId} className="flex items-center gap-1 px-2 py-1 rounded-sm bg-accent-light text-accent">
                        <Icon size={11} />
                        <span className="text-caption">{m.name}</span>
                      </span>
                    )
                  })}
                </div>
              </div>
            ))}
          </div>
        )}
      </section>

      {/* 级别策略编辑弹窗 */}
      {editingLevel && (
        <LevelStrategyEditor
          level={editingLevel}
          onClose={() => setEditingLevel(null)}
          onSave={handleSaveLevel}
        />
      )}

      {/* 自定义策略弹窗 */}
      {showAddCustom && (
        <CustomStrategyEditor
          strategy={editingCustom}
          onClose={() => { setShowAddCustom(false); setEditingCustom(null) }}
          onSave={handleSaveCustom}
        />
      )}
    </div>
  )
}

// ===== 级别策略编辑器 =====
const LevelStrategyEditor = ({ level, onClose, onSave }: {
  level: LevelStrategy
  onClose: () => void
  onSave: (l: LevelStrategy) => void
}) => {
  const [form, setForm] = useState<LevelStrategy>({ ...level, methods: [...level.methods] })

  const timeOptions = ['5分钟', '10分钟', '15分钟', '20分钟', '30分钟']
  const intervalOptions = ['3分钟', '5分钟', '10分钟', '15分钟', '30分钟']
  const timesOptions = ['3次', '5次', '10次', '不限']
  const soundOptions = ['柔和', '标准', '紧急']
  const volumeOptions = ['低', '中', '高', '最高']

  const toggleMethod = (id: string) => {
    setForm(prev => ({
      ...prev,
      methods: prev.methods.includes(id) ? prev.methods.filter(x => x !== id) : [...prev.methods, id],
    }))
  }

  const OptionGroup = ({ label, options, value, onChange }: {
    label: string
    options: string[]
    value: string
    onChange: (v: string) => void
  }) => (
    <div className="mb-3">
      <label className="text-body-small font-semibold text-text-secondary mb-2 block">{label}</label>
      <div className="flex flex-wrap gap-2">
        {options.map(opt => (
          <button
            key={opt}
            className={`px-3 py-1.5 rounded-md text-caption transition-fast ${
              value === opt ? 'bg-accent text-white' : 'bg-bg-tertiary text-text-secondary'
            }`}
            onClick={() => onChange(opt)}
          >
            {opt}
          </button>
        ))}
      </div>
    </div>
  )

  return (
    <div className="fixed inset-0 z-50 flex items-end justify-center">
      <div className="absolute inset-0 bg-black/40" onClick={onClose} />
      <div className="relative w-full max-w-[390px] bg-bg-secondary rounded-t-xl px-4 pt-5 pb-6 animate-[pageEnter_250ms_ease-out] max-h-[85vh] overflow-y-auto">
        <div className="w-10 h-1 bg-bg-tertiary rounded-full mx-auto mb-4" />

        <h2 className="text-title-small font-semibold text-text-primary text-center mb-1">
          编辑{form.name}策略
        </h2>
        <p className="text-caption text-text-tertiary text-center mb-4">{form.desc}</p>

        <OptionGroup label="提前提醒" options={timeOptions} value={form.advanceTime}
          onChange={(v) => setForm({ ...form, advanceTime: v })} />
        <OptionGroup label="重复间隔" options={intervalOptions} value={form.repeatInterval}
          onChange={(v) => setForm({ ...form, repeatInterval: v })} />
        <OptionGroup label="最大次数" options={timesOptions} value={form.maxTimes}
          onChange={(v) => setForm({ ...form, maxTimes: v })} />

        {/* 提醒方式 */}
        <div className="mb-3">
          <label className="text-body-small font-semibold text-text-secondary mb-2 block">提醒方式</label>
          <div className="grid grid-cols-3 gap-2">
            {allReminderMethods.map(m => {
              const Icon = m.icon
              const enabled = form.methods.includes(m.id)
              return (
                <button
                  key={m.id}
                  className={`flex flex-col items-center gap-1 py-2.5 rounded-md transition-fast ${
                    enabled ? 'bg-success-light text-success' : 'bg-bg-tertiary text-text-tertiary'
                  }`}
                  onClick={() => toggleMethod(m.id)}
                >
                  <Icon size={18} />
                  <span className="text-caption">{m.name}</span>
                </button>
              )
            })}
          </div>
        </div>

        <OptionGroup label="提示音" options={soundOptions} value={form.sound}
          onChange={(v) => setForm({ ...form, sound: v })} />
        <OptionGroup label="音量" options={volumeOptions} value={form.volume}
          onChange={(v) => setForm({ ...form, volume: v })} />

        {/* 开关项 */}
        <div className="space-y-2 mb-4">
          <div className="flex items-center justify-between py-2">
            <span className="text-body-small text-text-primary">允许延后</span>
            <button
              className={`relative w-10 h-5.5 rounded-full transition-fast ${form.allowDelay ? 'bg-success' : 'bg-bg-tertiary'}`}
              onClick={() => setForm({ ...form, allowDelay: !form.allowDelay })}
            >
              <div className={`absolute top-0.5 w-4.5 h-4.5 bg-white rounded-full shadow-sm transition-fast ${form.allowDelay ? 'left-[18px]' : 'left-0.5'}`} />
            </button>
          </div>
          <div className="flex items-center justify-between py-2">
            <span className="text-body-small text-text-primary">允许跳过</span>
            <button
              className={`relative w-10 h-5.5 rounded-full transition-fast ${form.allowSkip ? 'bg-success' : 'bg-bg-tertiary'}`}
              onClick={() => setForm({ ...form, allowSkip: !form.allowSkip })}
            >
              <div className={`absolute top-0.5 w-4.5 h-4.5 bg-white rounded-full shadow-sm transition-fast ${form.allowSkip ? 'left-[18px]' : 'left-0.5'}`} />
            </button>
          </div>
        </div>

        <div className="flex gap-3">
          <button
            className="flex-1 py-3 bg-bg-tertiary rounded-md text-body-small font-medium text-text-secondary active:bg-border"
            onClick={onClose}
          >
            取消
          </button>
          <button
            className="flex-1 py-3 bg-accent rounded-md text-white text-body-small font-medium active:bg-text-primary"
            onClick={() => onSave(form)}
          >
            保存
          </button>
        </div>
      </div>
    </div>
  )
}

// ===== 自定义策略编辑器 =====
const CustomStrategyEditor = ({ strategy, onClose, onSave }: {
  strategy: CustomStrategy | null
  onClose: () => void
  onSave: (s: CustomStrategy) => void
}) => {
  const [name, setName] = useState(strategy?.name ?? '')
  const [keyword, setKeyword] = useState(strategy?.keyword ?? '')
  const [level, setLevel] = useState(strategy?.level ?? '普通')
  const [advanceTime, setAdvanceTime] = useState(strategy?.advanceTime ?? '10分钟')
  const [repeatInterval, setRepeatInterval] = useState(strategy?.repeatInterval ?? '5分钟')
  const [maxTimes, setMaxTimes] = useState(strategy?.maxTimes ?? '5次')
  const [selectedMethods, setSelectedMethods] = useState<string[]>(strategy?.methods ?? ['notification', 'sound'])
  const [condition, setCondition] = useState(strategy?.condition ?? 'time')

  const toggleMethod = (m: string) => {
    setSelectedMethods(prev => prev.includes(m) ? prev.filter(x => x !== m) : [...prev, m])
  }

  const handleSave = () => {
    if (!name.trim() || !keyword.trim()) return
    onSave({
      id: strategy?.id ?? '',
      name: name.trim(),
      keyword: keyword.trim(),
      level,
      advanceTime,
      repeatInterval,
      maxTimes,
      methods: selectedMethods,
      condition,
    })
  }

  return (
    <div className="fixed inset-0 z-50 flex items-end justify-center">
      <div className="absolute inset-0 bg-black/40" onClick={onClose} />
      <div className="relative w-full max-w-[390px] bg-bg-secondary rounded-t-xl px-4 pt-5 pb-6 animate-[pageEnter_250ms_ease-out] max-h-[85vh] overflow-y-auto">
        <div className="w-10 h-1 bg-bg-tertiary rounded-full mx-auto mb-4" />

        <h2 className="text-title-small font-semibold text-text-primary text-center mb-4">
          {strategy ? '编辑策略' : '新建策略'}
        </h2>

        <div className="mb-3">
          <label className="text-body-small font-semibold text-text-secondary mb-2 block">策略名称</label>
          <input
            type="text"
            value={name}
            placeholder="如：吃药专属提醒"
            onChange={(e) => setName(e.target.value)}
            className="w-full bg-bg-tertiary rounded-md px-3 py-2.5 text-body text-text-primary outline-none focus:ring-2 focus:ring-accent placeholder:text-text-tertiary"
            autoFocus
          />
        </div>

        <div className="mb-3">
          <label className="text-body-small font-semibold text-text-secondary mb-2 block">触发关键词</label>
          <input
            type="text"
            value={keyword}
            placeholder="如：吃药"
            onChange={(e) => setKeyword(e.target.value)}
            className="w-full bg-bg-tertiary rounded-md px-3 py-2.5 text-body text-text-primary outline-none focus:ring-2 focus:ring-accent placeholder:text-text-tertiary"
          />
          <p className="text-caption text-text-tertiary mt-1">事程内容包含此词时自动应用此策略</p>
        </div>

        <div className="mb-3">
          <label className="text-body-small font-semibold text-text-secondary mb-2 block">事程级别</label>
          <div className="flex gap-2">
            {['普通', '重要', '必做'].map(l => (
              <button
                key={l}
                className={`flex-1 py-2 rounded-md text-body-small font-medium transition-fast ${
                  level === l
                    ? l === '必做' ? 'bg-danger text-white'
                    : l === '重要' ? 'bg-warning text-white'
                    : 'bg-accent text-white'
                    : 'bg-bg-tertiary text-text-secondary'
                }`}
                onClick={() => setLevel(l)}
              >
                {l}
              </button>
            ))}
          </div>
        </div>

        <div className="mb-3">
          <label className="text-body-small font-semibold text-text-secondary mb-2 block">触发条件</label>
          <div className="grid grid-cols-2 gap-2">
            {conditionTypes.map(cond => (
              <button
                key={cond.id}
                className={`flex items-center gap-2 p-2.5 rounded-md transition-fast ${
                  condition === cond.id ? 'bg-accent text-white' : 'bg-bg-tertiary text-text-secondary'
                }`}
                onClick={() => setCondition(cond.id)}
              >
                <span>{cond.icon}</span>
                <span className="text-caption">{cond.name}</span>
              </button>
            ))}
          </div>
        </div>

        <div className="mb-3">
          <label className="text-body-small font-semibold text-text-secondary mb-2 block">提前提醒</label>
          <div className="flex flex-wrap gap-2">
            {['5分钟', '10分钟', '15分钟', '20分钟'].map(t => (
              <button
                key={t}
                className={`px-3 py-1.5 rounded-md text-caption transition-fast ${
                  advanceTime === t ? 'bg-accent text-white' : 'bg-bg-tertiary text-text-secondary'
                }`}
                onClick={() => setAdvanceTime(t)}
              >
                {t}
              </button>
            ))}
          </div>
        </div>

        <div className="mb-3">
          <label className="text-body-small font-semibold text-text-secondary mb-2 block">重复间隔</label>
          <div className="flex flex-wrap gap-2">
            {['3分钟', '5分钟', '10分钟', '15分钟'].map(t => (
              <button
                key={t}
                className={`px-3 py-1.5 rounded-md text-caption transition-fast ${
                  repeatInterval === t ? 'bg-accent text-white' : 'bg-bg-tertiary text-text-secondary'
                }`}
                onClick={() => setRepeatInterval(t)}
              >
                {t}
              </button>
            ))}
          </div>
        </div>

        <div className="mb-3">
          <label className="text-body-small font-semibold text-text-secondary mb-2 block">最大次数</label>
          <div className="flex flex-wrap gap-2">
            {['3次', '5次', '10次', '不限'].map(t => (
              <button
                key={t}
                className={`px-3 py-1.5 rounded-md text-caption transition-fast ${
                  maxTimes === t ? 'bg-accent text-white' : 'bg-bg-tertiary text-text-secondary'
                }`}
                onClick={() => setMaxTimes(t)}
              >
                {t}
              </button>
            ))}
          </div>
        </div>

        <div className="mb-4">
          <label className="text-body-small font-semibold text-text-secondary mb-2 block">提醒方式</label>
          <div className="grid grid-cols-3 gap-2">
            {allReminderMethods.map(m => {
              const Icon = m.icon
              const enabled = selectedMethods.includes(m.id)
              return (
                <button
                  key={m.id}
                  className={`flex flex-col items-center gap-1 py-2.5 rounded-md transition-fast ${
                    enabled ? 'bg-success-light text-success' : 'bg-bg-tertiary text-text-tertiary'
                  }`}
                  onClick={() => toggleMethod(m.id)}
                >
                  <Icon size={18} />
                  <span className="text-caption">{m.name}</span>
                </button>
              )
            })}
          </div>
        </div>

        <div className="flex gap-3">
          <button
            className="flex-1 py-3 bg-bg-tertiary rounded-md text-body-small font-medium text-text-secondary active:bg-border"
            onClick={onClose}
          >
            取消
          </button>
          <button
            className="flex-1 py-3 bg-accent rounded-md text-white text-body-small font-medium active:bg-text-primary"
            onClick={handleSave}
            disabled={!name.trim() || !keyword.trim()}
          >
            保存
          </button>
        </div>
      </div>
    </div>
  )
}

export default ReminderRulesPage

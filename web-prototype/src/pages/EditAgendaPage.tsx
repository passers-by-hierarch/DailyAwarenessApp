import { useState, useEffect } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { ChevronLeft, Clock, Bell, AlertTriangle, Tag, MapPin, Cloud, Link, Mic, Edit3, Save } from 'lucide-react'
import { useAppStore } from '../store/appStore'

const EditAgendaPage = () => {
  const navigate = useNavigate()
  const { id } = useParams()

  // 从 store 获取事程（编辑模式）和操作方法
  const existingAgenda = useAppStore(s => s.agendaItems.find(a => a.id === id))
  const addAgenda = useAppStore(s => s.addAgenda)
  const updateAgenda = useAppStore(s => s.updateAgenda)

  // 是否为编辑模式
  const isEditMode = !!id

  // 事程基础信息
  const [agenda, setAgenda] = useState({
    icon: '💊',
    time: '15:00',
    content: '',
    isMustDo: false,
    category: '生活',
    note: '',
  })

  // 编辑模式下，用 store 中的事程数据预填表单
  useEffect(() => {
    if (isEditMode && existingAgenda) {
      setAgenda({
        icon: existingAgenda.icon || '📋',
        time: existingAgenda.time,
        content: existingAgenda.content,
        isMustDo: existingAgenda.isMustDo,
        category: existingAgenda.category || '生活',
        note: existingAgenda.note || '',
      })
    }
  }, [isEditMode, existingAgenda])

  // 提醒级别
  const [reminderLevel, setReminderLevel] = useState('普通')

  // 提醒方式开关
  const [reminderMethods, setReminderMethods] = useState([
    { id: '1', name: '通知栏', enabled: true },
    { id: '2', name: '声音', enabled: true },
    { id: '3', name: '震动', enabled: true },
    { id: '4', name: '弹窗', enabled: true },
    { id: '5', name: '语音播报', enabled: false },
  ])

  // 时间设置
  const [timeSettings, setTimeSettings] = useState({
    advanceTime: '10分钟',
    repeatInterval: '5分钟',
    maxTimes: '5次',
  })

  // 行为选项
  const [behaviorOptions, setBehaviorOptions] = useState({
    allowDelay: false,
    allowSkip: false,
  })

  // 输入框组件
  const InputField = ({ label, value, placeholder, onChange }: { label: string; value: string; placeholder?: string; onChange: (value: string) => void }) => (
    <div className="mb-4">
      <label className="text-body-small font-semibold text-text-secondary mb-2 block">{label}</label>
      <input
        type="text"
        value={value}
        placeholder={placeholder}
        onChange={(e) => onChange(e.target.value)}
        className="w-full bg-bg-tertiary rounded-md px-4 py-3 text-body text-text-primary outline-none focus:ring-2 focus:ring-accent placeholder:text-text-tertiary"
      />
    </div>
  )

  // 切换提醒方式
  const toggleReminderMethod = (id: string) => {
    setReminderMethods(
      reminderMethods.map(method =>
        method.id === id ? { ...method, enabled: !method.enabled } : method
      )
    )
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
      // 编辑模式：更新现有事程
      updateAgenda(existingAgenda.id, {
        icon: agenda.icon,
        time: agenda.time,
        content: agenda.content,
        isMustDo: agenda.isMustDo,
        category: agenda.category,
        note: agenda.note,
      })
    } else {
      // 创建模式：新增事程
      addAgenda({
        icon: agenda.icon,
        time: agenda.time,
        content: agenda.content,
        isMustDo: agenda.isMustDo,
        category: agenda.category,
        note: agenda.note,
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

      {/* 基本信息 */}
      <section className="px-4 pt-4">
        <div className="px-1 py-2 flex items-center gap-2">
          <Edit3 size={16} className="text-accent" />
          <h2 className="text-body-small font-semibold text-text-secondary">基本信息</h2>
        </div>

        <div className="bg-bg-secondary rounded-lg card-shadow p-4">
          {/* 图标选择 */}
          <div className="mb-4">
            <label className="text-body-small font-semibold text-text-secondary mb-2 block">事程图标</label>
            <div className="flex gap-2 overflow-x-auto pb-2">
              {['💊', '🍚', '💧', '🏃', '📖', '🛏', '📱', '🧹', '🛒', '✈️'].map((icon) => (
                <button
                  key={icon}
                  className={`w-12 h-12 bg-bg-tertiary rounded-lg flex items-center justify-center text-2xl transition-fast ${
                    agenda.icon === icon ? 'ring-2 ring-accent bg-accent-light' : 'active:bg-bg-tertiary'
                  }`}
                  onClick={() => setAgenda({ ...agenda, icon })}
                >
                  {icon}
                </button>
              ))}
            </div>
          </div>

          {/* 时间 */}
          <InputField
            label="事程时间"
            value={agenda.time}
            placeholder="例如: 15:00"
            onChange={(value) => setAgenda({ ...agenda, time: value })}
          />

          {/* 内容 */}
          <InputField
            label="事程内容"
            value={agenda.content}
            placeholder="例如: 吃药"
            onChange={(value) => setAgenda({ ...agenda, content: value })}
          />

          {/* 分类 */}
          <div className="mb-4">
            <label className="text-body-small font-semibold text-text-secondary mb-2 block">事程分类</label>
            <div className="flex gap-2 overflow-x-auto pb-2">
              {['健康', '饮食', '运动', '学习', '生活', '工作', '社交'].map((cat) => (
                <button
                  key={cat}
                  className={`px-4 py-2 rounded-md text-body-small font-medium transition-fast ${
                    agenda.category === cat
                      ? 'bg-accent text-white'
                      : 'bg-bg-tertiary text-text-secondary active:bg-border'
                  }`}
                  onClick={() => setAgenda({ ...agenda, category: cat })}
                >
                  {cat}
                </button>
              ))}
            </div>
          </div>

          {/* 备注 */}
          <InputField
            label="备注"
            value={agenda.note}
            placeholder="例如: 饭后服用"
            onChange={(value) => setAgenda({ ...agenda, note: value })}
          />

          {/* 必做标记 */}
          <div className="flex items-center justify-between py-3 border-t border-border">
            <div className="flex items-center gap-2">
              <AlertTriangle size={18} className="text-danger" />
              <div>
                <div className="text-body-small font-medium text-text-primary">必做事程</div>
                <div className="text-caption text-text-tertiary">强制提醒,不可跳过</div>
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

      {/* 提醒规则 */}
      <section className="px-4 mt-4">
        <div className="px-1 py-2 flex items-center gap-2">
          <Bell size={16} className="text-accent" />
          <h2 className="text-body-small font-semibold text-text-secondary">提醒规则</h2>
        </div>

        <div className="bg-bg-secondary rounded-lg card-shadow p-4">
          {/* 提醒级别 */}
          <div className="mb-4">
            <label className="text-body-small font-semibold text-text-secondary mb-2 block">提醒级别</label>
            <div className="flex gap-2">
              {['普通', '重要', '必做'].map((level) => (
                <button
                  key={level}
                  className={`flex-1 py-2.5 rounded-md text-body-small font-medium transition-fast ${
                    reminderLevel === level
                      ? level === '必做' ? 'bg-danger text-white' :
                        level === '重要' ? 'bg-warning text-white' : 'bg-accent text-white'
                      : 'bg-bg-tertiary text-text-secondary active:bg-border'
                  }`}
                  onClick={() => setReminderLevel(level)}
                >
                  {level}
                </button>
              ))}
            </div>
          </div>

          {/* 提醒方式 */}
          <div className="mb-4">
            <label className="text-body-small font-semibold text-text-secondary mb-2 block">提醒方式</label>
            <div className="flex flex-wrap gap-2">
              {reminderMethods.map((method) => (
                <button
                  key={method.id}
                  className={`flex items-center gap-1.5 px-3 py-2 rounded-md transition-fast ${
                    method.enabled
                      ? 'bg-success-light text-success'
                      : 'bg-bg-tertiary text-text-tertiary'
                  }`}
                  onClick={() => toggleReminderMethod(method.id)}
                >
                  <div className={`w-4 h-4 rounded-full border-2 ${
                    method.enabled ? 'bg-success border-success' : 'border-text-tertiary'
                  }`} />
                  <span className="text-caption">{method.name}</span>
                </button>
              ))}
            </div>
          </div>

          {/* 时间设置 */}
          <div className="space-y-3">
            <div className="flex items-center justify-between py-2.5 border-b border-border">
              <span className="text-body-small text-text-secondary">提前提醒时间</span>
              <div className="flex gap-2">
                {['5分钟', '10分钟', '15分钟', '20分钟'].map((time) => (
                  <button
                    key={time}
                    className={`px-3 py-1 rounded-sm text-caption transition-fast ${
                      timeSettings.advanceTime === time
                        ? 'bg-accent text-white'
                        : 'bg-bg-tertiary text-text-secondary active:bg-border'
                    }`}
                    onClick={() => setTimeSettings({ ...timeSettings, advanceTime: time })}
                  >
                    {time}
                  </button>
                ))}
              </div>
            </div>

            <div className="flex items-center justify-between py-2.5 border-b border-border">
              <span className="text-body-small text-text-secondary">重复提醒间隔</span>
              <div className="flex gap-2">
                {['5分钟', '10分钟', '15分钟'].map((time) => (
                  <button
                    key={time}
                    className={`px-3 py-1 rounded-sm text-caption transition-fast ${
                      timeSettings.repeatInterval === time
                        ? 'bg-accent text-white'
                        : 'bg-bg-tertiary text-text-secondary active:bg-border'
                    }`}
                    onClick={() => setTimeSettings({ ...timeSettings, repeatInterval: time })}
                  >
                    {time}
                  </button>
                ))}
              </div>
            </div>

            <div className="flex items-center justify-between py-2.5">
              <span className="text-body-small text-text-secondary">最大提醒次数</span>
              <div className="flex gap-2">
                {['3次', '5次', '10次'].map((times) => (
                  <button
                    key={times}
                    className={`px-3 py-1 rounded-sm text-caption transition-fast ${
                      timeSettings.maxTimes === times
                        ? 'bg-accent text-white'
                        : 'bg-bg-tertiary text-text-secondary active:bg-border'
                    }`}
                    onClick={() => setTimeSettings({ ...timeSettings, maxTimes: times })}
                  >
                    {times}
                  </button>
                ))}
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* 行为选项 */}
      <section className="px-4 mt-4">
        <div className="px-1 py-2 flex items-center gap-2">
          <Tag size={16} className="text-accent" />
          <h2 className="text-body-small font-semibold text-text-secondary">行为选项</h2>
        </div>

        <div className="bg-bg-secondary rounded-lg card-shadow p-4">
          {/* 允许延后 */}
          <div className="flex items-center justify-between py-3 border-b border-border">
            <div className="flex items-center gap-2">
              <Clock size={18} className="text-text-secondary" />
              <div>
                <div className="text-body-small font-medium text-text-primary">允许延后</div>
                <div className="text-caption text-text-tertiary">用户可推迟提醒</div>
              </div>
            </div>
            <button
              className={`relative w-11 h-6 rounded-full transition-fast ${
                behaviorOptions.allowDelay ? 'bg-success' : 'bg-bg-tertiary'
              }`}
              onClick={() => setBehaviorOptions({ ...behaviorOptions, allowDelay: !behaviorOptions.allowDelay })}
              disabled={agenda.isMustDo}
            >
              <div
                className={`absolute top-0.5 w-5 h-5 bg-white rounded-full shadow-sm transition-fast ${
                  behaviorOptions.allowDelay ? 'left-[22px]' : 'left-0.5'
                } ${agenda.isMustDo ? 'opacity-50' : ''}`}
              />
            </button>
          </div>

          {/* 允许跳过 */}
          <div className="flex items-center justify-between py-3">
            <div className="flex items-center gap-2">
              <Tag size={18} className="text-text-secondary" />
              <div>
                <div className="text-body-small font-medium text-text-primary">允许跳过</div>
                <div className="text-caption text-text-tertiary">用户可跳过事程</div>
              </div>
            </div>
            <button
              className={`relative w-11 h-6 rounded-full transition-fast ${
                behaviorOptions.allowSkip ? 'bg-success' : 'bg-bg-tertiary'
              }`}
              onClick={() => setBehaviorOptions({ ...behaviorOptions, allowSkip: !behaviorOptions.allowSkip })}
              disabled={agenda.isMustDo}
            >
              <div
                className={`absolute top-0.5 w-5 h-5 bg-white rounded-full shadow-sm transition-fast ${
                  behaviorOptions.allowSkip ? 'left-[22px]' : 'left-0.5'
                } ${agenda.isMustDo ? 'opacity-50' : ''}`}
              />
            </button>
          </div>

          {agenda.isMustDo && (
            <div className="mt-3 bg-danger-light rounded-md p-3 text-caption text-danger">
              必做事程不允许延后或跳过
            </div>
          )}
        </div>
      </section>

      {/* 条件触发 */}
      <section className="px-4 mt-4">
        <div className="px-1 py-2 flex items-center gap-2">
          <MapPin size={16} className="text-accent" />
          <h2 className="text-body-small font-semibold text-text-secondary">条件触发(可选)</h2>
        </div>

        <div className="bg-bg-secondary rounded-lg card-shadow p-4">
          {/* 地理位置触发 */}
          <div className="flex items-center gap-3 py-3 border-b border-border">
            <div className="w-8 h-8 bg-bg-tertiary rounded-md flex items-center justify-center">
              <MapPin size={16} className="text-text-secondary" />
            </div>
            <div className="flex-1 min-w-0">
              <div className="text-body-small font-medium text-text-primary">地理位置触发</div>
              <div className="text-caption text-text-tertiary mt-0.5">到达指定地点时提醒</div>
            </div>
            <button className="text-info text-caption font-medium">设置</button>
          </div>

          {/* 天气条件触发 */}
          <div className="flex items-center gap-3 py-3 border-b border-border">
            <div className="w-8 h-8 bg-bg-tertiary rounded-md flex items-center justify-center">
              <Cloud size={16} className="text-text-secondary" />
            </div>
            <div className="flex-1 min-w-0">
              <div className="text-body-small font-medium text-text-primary">天气条件触发</div>
              <div className="text-caption text-text-tertiary mt-0.5">根据天气变化提醒</div>
            </div>
            <button className="text-info text-caption font-medium">设置</button>
          </div>

          {/* 行为链触发 */}
          <div className="flex items-center gap-3 py-3">
            <div className="w-8 h-8 bg-bg-tertiary rounded-md flex items-center justify-center">
              <Link size={16} className="text-text-secondary" />
            </div>
            <div className="flex-1 min-w-0">
              <div className="text-body-small font-medium text-text-primary">行为链触发</div>
              <div className="text-caption text-text-tertiary mt-0.5">某行为完成后提醒</div>
            </div>
            <button className="text-info text-caption font-medium">设置</button>
          </div>
        </div>
      </section>

      {/* 快速录入 */}
      <section className="px-4 mt-4">
        <button className="w-full py-4 bg-accent-light rounded-lg text-accent text-body-small font-medium flex items-center justify-center gap-2 transition-fast active:bg-accent/10">
          <Mic size={18} />
          语音快速录入事程
        </button>
      </section>

      {/* 底部操作按钮 */}
      <div className="sticky bottom-0 left-0 right-0 bg-bg-secondary border-t border-border px-4 py-3 flex gap-3 z-40 safe-area-bottom">
        <button
          className="flex-1 py-3 bg-accent rounded-md text-white text-body-small font-medium transition-fast active:bg-text-primary button-shadow"
          onClick={handleSave}
        >
          {isEditMode ? '保存事程' : '创建事程'}
        </button>

        <button
          className="flex-1 py-3 bg-danger-light rounded-md text-danger text-body-small font-medium transition-fast active:bg-danger-light/80"
          onClick={() => navigate(-1)}
        >
          取消
        </button>
      </div>
    </div>
  )
}

export default EditAgendaPage
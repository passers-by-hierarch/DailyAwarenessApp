import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { ChevronLeft, Moon, Plus, Clock, Bell, Trash2, Edit, X, Check } from 'lucide-react'

interface QuietHour {
  id: string
  name: string
  startTime: string
  endTime: string
  enabled: boolean
  repeat: string
  allowEmergency: boolean
}

const repeatOptions = ['每天', '工作日', '周末', '周一', '周二', '周三', '周四', '周五', '周六', '周日']

// 免打扰时段 mock 数据
const initialQuietHours: QuietHour[] = [
  { id: '1', name: '夜间休息', startTime: '22:00', endTime: '07:00', enabled: true, repeat: '每天', allowEmergency: true },
  { id: '2', name: '午休时间', startTime: '12:30', endTime: '14:00', enabled: true, repeat: '工作日', allowEmergency: true },
  { id: '3', name: '周末早晨', startTime: '07:00', endTime: '09:00', enabled: false, repeat: '周末', allowEmergency: false },
]

const QuietHoursPage = () => {
  const navigate = useNavigate()
  const [quietHours, setQuietHours] = useState<QuietHour[]>(initialQuietHours)

  // 弹窗状态
  const [showAdd, setShowAdd] = useState(false)
  const [showEdit, setShowEdit] = useState(false)
  const [selectedItem, setSelectedItem] = useState<QuietHour | null>(null)
  const [formError, setFormError] = useState('')

  // 表单状态
  const [newItem, setNewItem] = useState({
    name: '',
    startTime: '22:00',
    endTime: '07:00',
    repeat: '每天',
    allowEmergency: true,
  })

  // 切换启用状态
  const toggleEnabled = (id: string) => {
    setQuietHours(prev => prev.map(item => item.id === id ? { ...item, enabled: !item.enabled } : item))
  }

  // 删除时段（带确认）
  const [deleteConfirmId, setDeleteConfirmId] = useState<string | null>(null)

  const confirmDelete = () => {
    if (deleteConfirmId) {
      setQuietHours(prev => prev.filter(item => item.id !== deleteConfirmId))
      setDeleteConfirmId(null)
    }
  }

  // 打开添加弹窗
  const openAdd = () => {
    setNewItem({ name: '', startTime: '22:00', endTime: '07:00', repeat: '每天', allowEmergency: true })
    setFormError('')
    setShowAdd(true)
  }

  // 打开编辑弹窗
  const openEdit = (item: QuietHour) => {
    setSelectedItem(item)
    setNewItem({ name: item.name, startTime: item.startTime, endTime: item.endTime, repeat: item.repeat, allowEmergency: item.allowEmergency })
    setFormError('')
    setShowEdit(true)
  }

  // 保存（添加或编辑）
  const handleSave = () => {
    if (!newItem.name.trim()) {
      setFormError('请输入时段名称')
      return
    }
    if (newItem.startTime === newItem.endTime) {
      setFormError('开始时间和结束时间不能相同')
      return
    }
    if (selectedItem) {
      // 编辑
      setQuietHours(prev => prev.map(item => item.id === selectedItem.id ? { ...item, ...newItem } : item))
      setShowEdit(false)
    } else {
      // 添加
      const item: QuietHour = {
        ...newItem,
        id: `qh-${Date.now()}`,
        enabled: true,
      }
      setQuietHours(prev => [...prev, item])
      setShowAdd(false)
    }
    setFormError('')
    setSelectedItem(null)
  }

  // 生成时间选项
  const generateTimeOptions = () => {
    const options: string[] = []
    for (let h = 0; h < 24; h++) {
      for (let m = 0; m < 60; m += 15) {
        options.push(`${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}`)
      }
    }
    return options
  }

  return (
    <div className="page-enter min-h-screen bg-bg-primary pb-24">
      {/* 顶部导航栏 */}
      <header className="px-4 py-3 bg-bg-secondary border-b border-border flex items-center justify-between sticky top-0 z-40">
        <button className="w-8 h-8 flex items-center justify-center text-text-primary transition-fast active:opacity-60" onClick={() => navigate(-1)}>
          <ChevronLeft size={24} />
        </button>
        <h1 className="text-body font-semibold text-text-primary">免打扰时段</h1>
        <button className="w-8 h-8 flex items-center justify-center text-accent transition-fast active:opacity-60" onClick={openAdd}>
          <Plus size={22} />
        </button>
      </header>

      {/* 提示区 */}
      <div className="px-4 py-3">
        <div className="bg-info-light rounded-md px-4 py-3 flex items-start gap-2">
          <Moon size={18} className="text-info mt-0.5 shrink-0" />
          <div className="flex-1">
            <span className="text-body-small text-info">在免打扰时段内，系统将静音非紧急通知，确保您的休息时间不被打扰</span>
          </div>
        </div>
      </div>

      {/* 免打扰时段列表 */}
      <section className="px-4 mt-2">
        <div className="px-1 py-2 flex items-center gap-2">
          <Clock size={16} className="text-accent" />
          <h2 className="text-body-small font-semibold text-text-secondary">已设时段</h2>
        </div>

        <div className="space-y-3">
          {quietHours.map((item) => (
            <div key={item.id} className="bg-bg-secondary rounded-lg card-shadow p-4">
              <div className="flex items-center justify-between mb-3">
                <div className="flex items-center gap-2">
                  <div className={`w-8 h-8 rounded-md flex items-center justify-center ${item.enabled ? 'bg-accent-light' : 'bg-bg-tertiary'}`}>
                    <Moon size={16} className={item.enabled ? 'text-accent' : 'text-text-tertiary'} />
                  </div>
                  <div>
                    <span className="text-body-small font-medium text-text-primary">{item.name}</span>
                    <span className={`ml-2 px-2 py-0.5 rounded-sm text-caption ${item.enabled ? 'bg-success-light text-success' : 'bg-bg-tertiary text-text-tertiary'}`}>
                      {item.enabled ? '已开启' : '已关闭'}
                    </span>
                  </div>
                </div>
                <button onClick={() => toggleEnabled(item.id)} className={`relative w-11 h-6 rounded-full transition-fast ${item.enabled ? 'bg-success' : 'bg-bg-tertiary'}`}>
                  <div className={`absolute top-0.5 w-5 h-5 bg-white rounded-full shadow-sm transition-fast ${item.enabled ? 'left-[22px]' : 'left-0.5'}`} />
                </button>
              </div>

              <div className="bg-bg-tertiary rounded-md p-3 mb-3">
                <div className="flex items-center justify-between">
                  <div className="text-center flex-1">
                    <div className="text-caption text-text-secondary mb-1">开始时间</div>
                    <div className="text-time font-mono text-text-primary">{item.startTime}</div>
                  </div>
                  <div className="px-3">
                    <div className="w-8 h-px bg-border" />
                  </div>
                  <div className="text-center flex-1">
                    <div className="text-caption text-text-secondary mb-1">结束时间</div>
                    <div className="text-time font-mono text-text-primary">{item.endTime}</div>
                  </div>
                </div>
              </div>

              <div className="flex items-center gap-4 text-caption text-text-secondary mb-3">
                <div className="flex items-center gap-1"><Clock size={12} /><span>{item.repeat}</span></div>
                <div className="flex items-center gap-1"><Bell size={12} /><span>{item.allowEmergency ? '允许紧急通知' : '全部静音'}</span></div>
              </div>

              <div className="flex gap-2">
                <button className="flex-1 py-2 bg-accent-light rounded-md text-accent text-caption font-medium transition-fast active:bg-accent/10 flex items-center justify-center gap-1" onClick={() => openEdit(item)}>
                  <Edit size={14} />
                  编辑
                </button>
                <button className="flex-1 py-2 bg-danger-light rounded-md text-danger text-caption font-medium transition-fast active:bg-danger-light/80 flex items-center justify-center gap-1" onClick={() => setDeleteConfirmId(item.id)}>
                  <Trash2 size={14} />
                  删除
                </button>
              </div>
            </div>
          ))}
        </div>
      </section>

      {/* 空状态 */}
      {quietHours.length === 0 && (
        <div className="px-4 py-12 text-center">
          <Moon size={48} className="mx-auto text-text-tertiary mb-4" />
          <div className="text-body text-text-secondary mb-2">暂无免打扰时段</div>
          <div className="text-caption text-text-tertiary">点击右上角添加新的时段</div>
        </div>
      )}

      {/* 底部操作按钮 */}
      <div className="sticky bottom-0 left-0 right-0 bg-bg-secondary border-t border-border px-4 py-3 z-40 safe-area-bottom">
        <button className="w-full py-3 bg-accent rounded-md text-white text-body-small font-medium transition-fast active:bg-text-primary button-shadow flex items-center justify-center gap-2" onClick={openAdd}>
          <Plus size={18} />
          添加免打扰时段
        </button>
      </div>

      {/* 添加/编辑弹窗 */}
      {(showAdd || showEdit) && (
        <div className="fixed inset-0 z-50 flex items-end justify-center">
          <div className="absolute inset-0 bg-black/40" onClick={() => { setShowAdd(false); setShowEdit(false); setSelectedItem(null) }} />
          <div className="relative w-full max-w-[390px] bg-bg-secondary rounded-t-xl px-4 pt-5 pb-6 animate-[pageEnter_250ms_ease-out]">
            <div className="w-10 h-1 bg-bg-tertiary rounded-full mx-auto mb-4" />
            <div className="flex items-center justify-between mb-3">
              <h2 className="text-title-small font-semibold text-text-primary">{showEdit ? '编辑免打扰时段' : '添加免打扰时段'}</h2>
              <button className="w-6 h-6 flex items-center justify-center text-text-secondary" onClick={() => { setShowAdd(false); setShowEdit(false); setSelectedItem(null) }}><X size={18} /></button>
            </div>
            <div className="space-y-3">
              <div>
                <label className="text-caption text-text-secondary block mb-1.5">时段名称</label>
                <input type="text" value={newItem.name} onChange={(e) => { setNewItem({ ...newItem, name: e.target.value }); setFormError('') }} placeholder="如：夜间休息、午休时间" className="w-full bg-bg-tertiary rounded-md px-3 py-2.5 text-body-small text-text-primary outline-none focus:ring-2 focus:ring-accent placeholder:text-text-tertiary" />
              </div>
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="text-caption text-text-secondary block mb-1.5">开始时间</label>
                  <select value={newItem.startTime} onChange={(e) => setNewItem({ ...newItem, startTime: e.target.value })} className="w-full bg-bg-tertiary rounded-md px-3 py-2.5 text-body-small text-text-primary outline-none focus:ring-2 focus:ring-accent">
                    {generateTimeOptions().map(t => <option key={t} value={t}>{t}</option>)}
                  </select>
                </div>
                <div>
                  <label className="text-caption text-text-secondary block mb-1.5">结束时间</label>
                  <select value={newItem.endTime} onChange={(e) => setNewItem({ ...newItem, endTime: e.target.value })} className="w-full bg-bg-tertiary rounded-md px-3 py-2.5 text-body-small text-text-primary outline-none focus:ring-2 focus:ring-accent">
                    {generateTimeOptions().map(t => <option key={t} value={t}>{t}</option>)}
                  </select>
                </div>
              </div>
              <div>
                <label className="text-caption text-text-secondary block mb-1.5">重复周期</label>
                <div className="flex flex-wrap gap-2">
                  {repeatOptions.map((r) => (
                    <button key={r} className={`px-3 py-2 rounded-md text-body-small font-medium transition-fast ${newItem.repeat === r ? 'bg-accent-light text-accent ring-1 ring-accent' : 'bg-bg-tertiary text-text-secondary'}`} onClick={() => setNewItem({ ...newItem, repeat: r })}>{r}</button>
                  ))}
                </div>
              </div>
              <div>
                <label className="text-caption text-text-secondary block mb-1.5">紧急通知</label>
                <div className="flex flex-wrap gap-2">
                  {[{ key: 'true', label: '允许紧急通知' }, { key: 'false', label: '全部静音' }].map((opt) => (
                    <button key={opt.key} className={`flex-1 px-3 py-2 rounded-md text-body-small font-medium transition-fast ${newItem.allowEmergency === (opt.key === 'true') ? 'bg-accent-light text-accent ring-1 ring-accent' : 'bg-bg-tertiary text-text-secondary'}`} onClick={() => setNewItem({ ...newItem, allowEmergency: opt.key === 'true' })}>{opt.label}</button>
                  ))}
                </div>
              </div>
            </div>
            {formError && <div className="text-caption text-danger mt-3">{formError}</div>}
            <div className="flex gap-3 mt-4">
              <button className="flex-1 py-3 bg-bg-tertiary rounded-md text-body-small font-medium text-text-secondary active:bg-border transition-fast" onClick={() => { setShowAdd(false); setShowEdit(false); setSelectedItem(null) }}>取消</button>
              <button className="flex-1 py-3 bg-accent rounded-md text-white text-body-small font-medium active:bg-text-primary transition-fast flex items-center justify-center gap-1.5" onClick={handleSave}>
                <Check size={16} />
                {showEdit ? '保存' : '添加'}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* 删除确认弹窗 */}
      {deleteConfirmId && (
        <div className="fixed inset-0 z-50 flex items-center justify-center px-6">
          <div className="absolute inset-0 bg-black/40" onClick={() => setDeleteConfirmId(null)} />
          <div className="relative w-full max-w-[300px] bg-bg-secondary rounded-lg overflow-hidden">
            <h2 className="text-title-small font-semibold text-text-primary text-center pt-6 px-5">确认删除？</h2>
            <div className="px-5 py-4">
              <div className="bg-bg-tertiary rounded-md p-3 text-center">
                <div className="text-body-small font-medium text-text-primary">删除后该时段将不再生效</div>
              </div>
            </div>
            <div className="flex gap-3 px-5 pb-6">
              <button className="flex-1 py-3 bg-danger rounded-md text-white text-body-small font-medium transition-fast active:bg-danger/80" onClick={confirmDelete}>删除</button>
              <button className="flex-1 py-3 bg-bg-tertiary rounded-md text-text-secondary text-body-small font-medium transition-fast active:bg-border" onClick={() => setDeleteConfirmId(null)}>取消</button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

export default QuietHoursPage

import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { ChevronLeft, Plus, Phone, MapPin, Shield, AlertTriangle, Bell, X, Check, Trash2, Edit2 } from 'lucide-react'

interface EmergencyContact {
  id: string
  name: string
  phone: string
  priority: number
}

interface SafetyZone {
  id: string
  name: string
  address: string
  radius: string
  enabled: boolean
}

// 初始 mock 数据
const initialContacts: EmergencyContact[] = [
  { id: '1', name: '女儿 · 小明', phone: '138-1234-5678', priority: 1 },
  { id: '2', name: '儿子 · 大强', phone: '139-8765-4321', priority: 2 },
]

const initialZones: SafetyZone[] = [
  { id: '1', name: '家', address: '北京市朝阳区XX小区', radius: '500米', enabled: true },
  { id: '2', name: '社区医院', address: '北京市朝阳区XX医院', radius: '200米', enabled: false },
]

const initialAlertConditions = [
  { id: '1', label: '离开安全围栏超过1小时', enabled: true },
  { id: '2', label: '连续3天未记录任何行为', enabled: true },
  { id: '3', label: '必做事程超时2小时未完成', enabled: true },
]

const radiusOptions = ['100米', '200米', '500米', '1000米', '2000米']

const EmergencySettingsPage = () => {
  const navigate = useNavigate()

  // 状态
  const [contacts, setContacts] = useState<EmergencyContact[]>(initialContacts)
  const [zones, setZones] = useState<SafetyZone[]>(initialZones)
  const [alertConditions, setAlertConditions] = useState(initialAlertConditions)

  // 弹窗状态
  const [showAddContact, setShowAddContact] = useState(false)
  const [showEditContact, setShowEditContact] = useState(false)
  const [showDeleteContact, setShowDeleteContact] = useState(false)
  const [showAddZone, setShowAddZone] = useState(false)
  const [showEditZone, setShowEditZone] = useState(false)
  const [showTestResult, setShowTestResult] = useState(false)

  // 表单状态
  const [selectedContact, setSelectedContact] = useState<EmergencyContact | null>(null)
  const [selectedZone, setSelectedZone] = useState<SafetyZone | null>(null)
  const [newContact, setNewContact] = useState({ name: '', phone: '', priority: 1 })
  const [newZone, setNewZone] = useState({ name: '', address: '', radius: '500米', enabled: true })
  const [formError, setFormError] = useState('')

  // 切换开关
  const toggleCondition = (id: string) => {
    setAlertConditions(alertConditions.map(c => c.id === id ? { ...c, enabled: !c.enabled } : c))
  }

  const toggleZone = (id: string) => {
    setZones(zones.map(z => z.id === id ? { ...z, enabled: !z.enabled } : z))
  }

  // 添加联系人
  const handleAddContact = () => {
    if (!newContact.name.trim()) {
      setFormError('请输入姓名')
      return
    }
    if (!newContact.phone.trim()) {
      setFormError('请输入手机号')
      return
    }
    const contact: EmergencyContact = {
      ...newContact,
      id: `contact-${Date.now()}`,
      phone: `${newContact.phone.slice(0, 3)}-${newContact.phone.slice(3, 7)}-${newContact.phone.slice(7, 11)}`,
    }
    setContacts([...contacts, contact])
    setShowAddContact(false)
    setFormError('')
    setNewContact({ name: '', phone: '', priority: contacts.length + 1 })
  }

  // 编辑联系人
  const openEditContact = (contact: EmergencyContact) => {
    setSelectedContact(contact)
    setNewContact({
      name: contact.name,
      phone: contact.phone.replace(/-/g, ''),
      priority: contact.priority,
    })
    setShowEditContact(true)
  }

  const handleEditContact = () => {
    if (!newContact.name.trim()) {
      setFormError('请输入姓名')
      return
    }
    if (!newContact.phone.trim()) {
      setFormError('请输入手机号')
      return
    }
    if (selectedContact) {
      setContacts(contacts.map(c => c.id === selectedContact.id ? {
        ...c,
        name: newContact.name,
        phone: `${newContact.phone.slice(0, 3)}-${newContact.phone.slice(3, 7)}-${newContact.phone.slice(7, 11)}`,
        priority: newContact.priority,
      } : c))
    }
    setShowEditContact(false)
    setFormError('')
  }

  // 删除联系人
  const openDeleteContact = (contact: EmergencyContact) => {
    setSelectedContact(contact)
    setShowDeleteContact(true)
  }

  const confirmDeleteContact = () => {
    if (selectedContact) {
      setContacts(contacts.filter(c => c.id !== selectedContact.id))
    }
    setShowDeleteContact(false)
    setSelectedContact(null)
  }

  // 添加安全围栏
  const handleAddZone = () => {
    if (!newZone.name.trim()) {
      setFormError('请输入围栏名称')
      return
    }
    if (!newZone.address.trim()) {
      setFormError('请输入地址')
      return
    }
    const zone: SafetyZone = {
      ...newZone,
      id: `zone-${Date.now()}`,
    }
    setZones([...zones, zone])
    setShowAddZone(false)
    setFormError('')
    setNewZone({ name: '', address: '', radius: '500米', enabled: true })
  }

  // 编辑安全围栏
  const openEditZone = (zone: SafetyZone) => {
    setSelectedZone(zone)
    setNewZone({
      name: zone.name,
      address: zone.address,
      radius: zone.radius,
      enabled: zone.enabled,
    })
    setShowEditZone(true)
  }

  const handleEditZone = () => {
    if (!newZone.name.trim()) {
      setFormError('请输入围栏名称')
      return
    }
    if (!newZone.address.trim()) {
      setFormError('请输入地址')
      return
    }
    if (selectedZone) {
      setZones(zones.map(z => z.id === selectedZone.id ? {
        ...z,
        name: newZone.name,
        address: newZone.address,
        radius: newZone.radius,
        enabled: newZone.enabled,
      } : z))
    }
    setShowEditZone(false)
    setFormError('')
  }

  // 测试求助
  const handleTestSOS = () => {
    setShowTestResult(true)
    setTimeout(() => setShowTestResult(false), 3000)
  }

  return (
    <div className="page-enter min-h-screen bg-bg-primary pb-8">
      {/* 顶部导航栏 */}
      <header className="px-4 py-3 bg-bg-secondary border-b border-border flex items-center justify-between sticky top-0 z-40">
        <button className="w-8 h-8 flex items-center justify-center text-text-primary transition-fast active:opacity-60" onClick={() => navigate(-1)}>
          <ChevronLeft size={24} />
        </button>
        <h1 className="text-body font-semibold text-text-primary">紧急求助设置</h1>
        <button className="w-8 h-8 flex items-center justify-center text-text-primary transition-fast active:opacity-60" onClick={() => setShowAddContact(true)}>
          <Plus size={22} />
        </button>
      </header>

      {/* SOS紧急联系人 */}
      <section className="px-4 mt-4">
        <div className="px-1 py-2 flex items-center gap-2">
          <Phone size={16} className="text-danger" />
          <h2 className="text-body-small font-semibold text-text-secondary">SOS紧急联系人</h2>
        </div>

        {contacts.length === 0 ? (
          <div className="bg-bg-secondary rounded-lg card-shadow p-8 text-center">
            <div className="text-4xl mb-2">📞</div>
            <div className="text-body-small text-text-secondary mb-1">还没有紧急联系人</div>
            <div className="text-caption text-text-tertiary mb-4">添加紧急联系人，在紧急情况下通知他们</div>
            <button className="px-4 py-2 bg-danger rounded-md text-white text-body-small font-medium active:bg-danger/80 transition-fast" onClick={() => setShowAddContact(true)}>
              添加联系人
            </button>
          </div>
        ) : (
          <div className="space-y-2.5">
            {contacts.map((contact) => (
              <div key={contact.id} className="bg-bg-secondary rounded-lg card-shadow p-4">
                <div className="flex items-start gap-3">
                  <div className="w-12 h-12 bg-danger-light rounded-full flex items-center justify-center shrink-0">
                    <span className="text-xl">📞</span>
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2">
                      <span className="text-body font-medium text-text-primary">{contact.name}</span>
                      <span className="px-2 py-0.5 rounded-sm bg-danger-light text-caption text-danger">优先级 {contact.priority}</span>
                    </div>
                    <div className="flex items-center gap-1 mt-1.5">
                      <Phone size={12} className="text-text-secondary" />
                      <span className="text-caption text-text-secondary">{contact.phone}</span>
                    </div>
                  </div>
                </div>
                <div className="flex gap-2 mt-3">
                  <button className="flex-1 py-2 bg-accent-light rounded-md text-accent text-caption font-medium transition-fast active:bg-accent/10 flex items-center justify-center gap-1" onClick={() => openEditContact(contact)}>
                    <Edit2 size={12} />
                    编辑
                  </button>
                  <button className="flex-1 py-2 bg-danger-light rounded-md text-danger text-caption font-medium transition-fast active:bg-danger-light/80 flex items-center justify-center gap-1" onClick={() => openDeleteContact(contact)}>
                    <Trash2 size={12} />
                    删除
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}
      </section>

      {/* 安全围栏设置 */}
      <section className="px-4 mt-6">
        <div className="px-1 py-2 flex items-center gap-2">
          <MapPin size={16} className="text-accent" />
          <h2 className="text-body-small font-semibold text-text-secondary">安全围栏</h2>
        </div>

        <div className="bg-bg-secondary rounded-lg card-shadow overflow-hidden">
          {zones.length === 0 ? (
            <div className="p-6 text-center">
              <div className="text-4xl mb-2">📍</div>
              <div className="text-body-small text-text-secondary">还没有安全围栏</div>
            </div>
          ) : (
            zones.map((zone, index) => (
              <div key={zone.id} className={`p-4 ${index < zones.length - 1 ? 'border-b border-border' : ''}`}>
                <div className="flex items-start justify-between gap-3">
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2 mb-1.5">
                      <span className="text-body-small font-medium text-text-primary">{zone.name}</span>
                      <span className={`px-2 py-0.5 rounded-sm text-caption ${zone.enabled ? 'bg-success-light text-success' : 'bg-bg-tertiary text-text-tertiary'}`}>
                        {zone.enabled ? '已开启' : '已关闭'}
                      </span>
                    </div>
                    <div className="flex items-center gap-1 mb-1">
                      <MapPin size={12} className="text-text-secondary" />
                      <span className="text-caption text-text-secondary">{zone.address}</span>
                    </div>
                    <div className="text-caption text-text-tertiary">围栏半径: {zone.radius}</div>
                  </div>
                  <div className="flex items-center gap-2">
                    <button className={`relative w-11 h-6 rounded-full transition-fast shrink-0 ${zone.enabled ? 'bg-success' : 'bg-bg-tertiary'}`} onClick={() => toggleZone(zone.id)}>
                      <div className={`absolute top-0.5 w-5 h-5 bg-white rounded-full shadow-sm transition-fast ${zone.enabled ? 'left-[22px]' : 'left-0.5'}`} />
                    </button>
                    <button className="text-info text-caption font-medium transition-fast active:opacity-60" onClick={() => openEditZone(zone)}>
                      <Edit2 size={14} />
                    </button>
                  </div>
                </div>
              </div>
            ))
          )}
        </div>

        <button className="w-full mt-2.5 py-3 bg-accent-light rounded-lg text-accent text-body-small font-medium flex items-center justify-center gap-2 transition-fast active:bg-accent/10" onClick={() => setShowAddZone(true)}>
          <Plus size={16} />
          添加安全围栏
        </button>
      </section>

      {/* 一键求助测试 */}
      <section className="px-4 mt-6">
        <div className="bg-danger-light rounded-lg card-shadow p-4 border-2 border-danger">
          <div className="flex items-center gap-2 mb-3">
            <AlertTriangle size={20} className="text-danger" />
            <h3 className="text-body font-semibold text-danger">一键求助测试</h3>
          </div>
          <p className="text-body-small text-text-secondary mb-3">点击下方按钮测试SOS功能,将向所有紧急联系人发送测试通知</p>
          <button className="w-full py-3 bg-danger rounded-md text-white text-body-small font-medium transition-fast active:bg-danger/80 button-shadow" onClick={handleTestSOS}>
            发送测试求助
          </button>
        </div>
      </section>

      {/* 自动报警条件 */}
      <section className="px-4 mt-6">
        <div className="px-1 py-2 flex items-center gap-2">
          <Shield size={16} className="text-accent" />
          <h2 className="text-body-small font-semibold text-text-secondary">自动报警条件</h2>
        </div>

        <div className="bg-bg-secondary rounded-lg card-shadow p-4">
          <div className="text-body-small text-text-secondary mb-3">以下情况发生时,系统将自动向紧急联系人发送通知</div>
          <div className="space-y-3">
            {alertConditions.map((condition) => (
              <div key={condition.id} className="flex items-center justify-between py-2.5">
                <div className="flex items-center gap-2">
                  <Bell size={14} className="text-text-secondary" />
                  <span className="text-body-small text-text-primary">{condition.label}</span>
                </div>
                <button className={`relative w-11 h-6 rounded-full transition-fast ${condition.enabled ? 'bg-success' : 'bg-bg-tertiary'}`} onClick={() => toggleCondition(condition.id)}>
                  <div className={`absolute top-0.5 w-5 h-5 bg-white rounded-full shadow-sm transition-fast ${condition.enabled ? 'left-[22px]' : 'left-0.5'}`} />
                </button>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* 添加联系人弹窗 */}
      {showAddContact && (
        <div className="fixed inset-0 z-50 flex items-end justify-center">
          <div className="absolute inset-0 bg-black/40" onClick={() => setShowAddContact(false)} />
          <div className="relative w-full max-w-[390px] bg-bg-secondary rounded-t-xl px-4 pt-5 pb-6 animate-[pageEnter_250ms_ease-out]">
            <div className="w-10 h-1 bg-bg-tertiary rounded-full mx-auto mb-4" />
            <div className="flex items-center justify-between mb-3">
              <h2 className="text-title-small font-semibold text-text-primary">添加紧急联系人</h2>
              <button className="w-6 h-6 flex items-center justify-center text-text-secondary" onClick={() => setShowAddContact(false)}><X size={18} /></button>
            </div>
            <div className="space-y-3">
              <div>
                <label className="text-caption text-text-secondary block mb-1.5">姓名</label>
                <input type="text" value={newContact.name} onChange={(e) => { setNewContact({ ...newContact, name: e.target.value }); setFormError('') }} placeholder="输入姓名" className="w-full bg-bg-tertiary rounded-md px-3 py-2.5 text-body-small text-text-primary outline-none focus:ring-2 focus:ring-accent placeholder:text-text-tertiary" />
              </div>
              <div>
                <label className="text-caption text-text-secondary block mb-1.5">手机号</label>
                <input type="tel" value={newContact.phone} onChange={(e) => { setNewContact({ ...newContact, phone: e.target.value.replace(/\D/g, '').slice(0, 11) }); setFormError('') }} placeholder="输入手机号" className="w-full bg-bg-tertiary rounded-md px-3 py-2.5 text-body-small text-text-primary outline-none focus:ring-2 focus:ring-accent placeholder:text-text-tertiary" />
              </div>
              <div>
                <label className="text-caption text-text-secondary block mb-1.5">优先级</label>
                <input type="number" min="1" max="10" value={newContact.priority} onChange={(e) => setNewContact({ ...newContact, priority: parseInt(e.target.value) || 1 })} className="w-full bg-bg-tertiary rounded-md px-3 py-2.5 text-body-small text-text-primary outline-none focus:ring-2 focus:ring-accent" />
              </div>
            </div>
            {formError && <div className="text-caption text-danger mt-3">{formError}</div>}
            <div className="flex gap-3 mt-4">
              <button className="flex-1 py-3 bg-bg-tertiary rounded-md text-body-small font-medium text-text-secondary active:bg-border transition-fast" onClick={() => setShowAddContact(false)}>取消</button>
              <button className="flex-1 py-3 bg-danger rounded-md text-white text-body-small font-medium active:bg-danger/80 transition-fast" onClick={handleAddContact}>添加</button>
            </div>
          </div>
        </div>
      )}

      {/* 编辑联系人弹窗 */}
      {showEditContact && (
        <div className="fixed inset-0 z-50 flex items-end justify-center">
          <div className="absolute inset-0 bg-black/40" onClick={() => setShowEditContact(false)} />
          <div className="relative w-full max-w-[390px] bg-bg-secondary rounded-t-xl px-4 pt-5 pb-6 animate-[pageEnter_250ms_ease-out]">
            <div className="w-10 h-1 bg-bg-tertiary rounded-full mx-auto mb-4" />
            <div className="flex items-center justify-between mb-3">
              <h2 className="text-title-small font-semibold text-text-primary">编辑紧急联系人</h2>
              <button className="w-6 h-6 flex items-center justify-center text-text-secondary" onClick={() => setShowEditContact(false)}><X size={18} /></button>
            </div>
            <div className="space-y-3">
              <div>
                <label className="text-caption text-text-secondary block mb-1.5">姓名</label>
                <input type="text" value={newContact.name} onChange={(e) => { setNewContact({ ...newContact, name: e.target.value }); setFormError('') }} className="w-full bg-bg-tertiary rounded-md px-3 py-2.5 text-body-small text-text-primary outline-none focus:ring-2 focus:ring-accent" />
              </div>
              <div>
                <label className="text-caption text-text-secondary block mb-1.5">手机号</label>
                <input type="tel" value={newContact.phone} onChange={(e) => { setNewContact({ ...newContact, phone: e.target.value.replace(/\D/g, '').slice(0, 11) }); setFormError('') }} className="w-full bg-bg-tertiary rounded-md px-3 py-2.5 text-body-small text-text-primary outline-none focus:ring-2 focus:ring-accent" />
              </div>
              <div>
                <label className="text-caption text-text-secondary block mb-1.5">优先级</label>
                <input type="number" min="1" max="10" value={newContact.priority} onChange={(e) => setNewContact({ ...newContact, priority: parseInt(e.target.value) || 1 })} className="w-full bg-bg-tertiary rounded-md px-3 py-2.5 text-body-small text-text-primary outline-none focus:ring-2 focus:ring-accent" />
              </div>
            </div>
            {formError && <div className="text-caption text-danger mt-3">{formError}</div>}
            <div className="flex gap-3 mt-4">
              <button className="flex-1 py-3 bg-bg-tertiary rounded-md text-body-small font-medium text-text-secondary active:bg-border transition-fast" onClick={() => setShowEditContact(false)}>取消</button>
              <button className="flex-1 py-3 bg-accent rounded-md text-white text-body-small font-medium active:bg-text-primary transition-fast" onClick={handleEditContact}>保存</button>
            </div>
          </div>
        </div>
      )}

      {/* 删除联系人确认弹窗 */}
      {showDeleteContact && selectedContact && (
        <div className="fixed inset-0 z-50 flex items-center justify-center px-6">
          <div className="absolute inset-0 bg-black/40" onClick={() => setShowDeleteContact(false)} />
          <div className="relative w-full max-w-[300px] bg-bg-secondary rounded-lg overflow-hidden">
            <h2 className="text-title-small font-semibold text-text-primary text-center pt-6 px-5">确认删除？</h2>
            <div className="px-5 py-4">
              <div className="bg-bg-tertiary rounded-md p-3 text-center">
                <div className="text-lg mb-1">📞</div>
                <div className="text-body-small font-medium text-text-primary">{selectedContact.name}</div>
                <div className="text-caption text-text-tertiary mt-1">删除后将无法接收紧急通知</div>
              </div>
            </div>
            <div className="flex gap-3 px-5 pb-6">
              <button className="flex-1 py-3 bg-danger rounded-md text-white text-body-small font-medium transition-fast active:bg-danger/80" onClick={confirmDeleteContact}>删除</button>
              <button className="flex-1 py-3 bg-bg-tertiary rounded-md text-text-secondary text-body-small font-medium transition-fast active:bg-border" onClick={() => setShowDeleteContact(false)}>取消</button>
            </div>
          </div>
        </div>
      )}

      {/* 添加安全围栏弹窗 */}
      {showAddZone && (
        <div className="fixed inset-0 z-50 flex items-end justify-center">
          <div className="absolute inset-0 bg-black/40" onClick={() => setShowAddZone(false)} />
          <div className="relative w-full max-w-[390px] bg-bg-secondary rounded-t-xl px-4 pt-5 pb-6 animate-[pageEnter_250ms_ease-out]">
            <div className="w-10 h-1 bg-bg-tertiary rounded-full mx-auto mb-4" />
            <div className="flex items-center justify-between mb-3">
              <h2 className="text-title-small font-semibold text-text-primary">添加安全围栏</h2>
              <button className="w-6 h-6 flex items-center justify-center text-text-secondary" onClick={() => setShowAddZone(false)}><X size={18} /></button>
            </div>
            <div className="space-y-3">
              <div>
                <label className="text-caption text-text-secondary block mb-1.5">围栏名称</label>
                <input type="text" value={newZone.name} onChange={(e) => { setNewZone({ ...newZone, name: e.target.value }); setFormError('') }} placeholder="如：家、社区医院" className="w-full bg-bg-tertiary rounded-md px-3 py-2.5 text-body-small text-text-primary outline-none focus:ring-2 focus:ring-accent placeholder:text-text-tertiary" />
              </div>
              <div>
                <label className="text-caption text-text-secondary block mb-1.5">地址</label>
                <input type="text" value={newZone.address} onChange={(e) => { setNewZone({ ...newZone, address: e.target.value }); setFormError('') }} placeholder="输入详细地址" className="w-full bg-bg-tertiary rounded-md px-3 py-2.5 text-body-small text-text-primary outline-none focus:ring-2 focus:ring-accent placeholder:text-text-tertiary" />
              </div>
              <div>
                <label className="text-caption text-text-secondary block mb-1.5">围栏半径</label>
                <div className="flex flex-wrap gap-2">
                  {radiusOptions.map((r) => (
                    <button key={r} className={`px-3 py-2 rounded-md text-body-small font-medium transition-fast ${newZone.radius === r ? 'bg-accent-light text-accent ring-1 ring-accent' : 'bg-bg-tertiary text-text-secondary'}`} onClick={() => setNewZone({ ...newZone, radius: r })}>{r}</button>
                  ))}
                </div>
              </div>
            </div>
            {formError && <div className="text-caption text-danger mt-3">{formError}</div>}
            <div className="flex gap-3 mt-4">
              <button className="flex-1 py-3 bg-bg-tertiary rounded-md text-body-small font-medium text-text-secondary active:bg-border transition-fast" onClick={() => setShowAddZone(false)}>取消</button>
              <button className="flex-1 py-3 bg-accent rounded-md text-white text-body-small font-medium active:bg-text-primary transition-fast" onClick={handleAddZone}>添加</button>
            </div>
          </div>
        </div>
      )}

      {/* 编辑安全围栏弹窗 */}
      {showEditZone && (
        <div className="fixed inset-0 z-50 flex items-end justify-center">
          <div className="absolute inset-0 bg-black/40" onClick={() => setShowEditZone(false)} />
          <div className="relative w-full max-w-[390px] bg-bg-secondary rounded-t-xl px-4 pt-5 pb-6 animate-[pageEnter_250ms_ease-out]">
            <div className="w-10 h-1 bg-bg-tertiary rounded-full mx-auto mb-4" />
            <div className="flex items-center justify-between mb-3">
              <h2 className="text-title-small font-semibold text-text-primary">编辑安全围栏</h2>
              <button className="w-6 h-6 flex items-center justify-center text-text-secondary" onClick={() => setShowEditZone(false)}><X size={18} /></button>
            </div>
            <div className="space-y-3">
              <div>
                <label className="text-caption text-text-secondary block mb-1.5">围栏名称</label>
                <input type="text" value={newZone.name} onChange={(e) => { setNewZone({ ...newZone, name: e.target.value }); setFormError('') }} className="w-full bg-bg-tertiary rounded-md px-3 py-2.5 text-body-small text-text-primary outline-none focus:ring-2 focus:ring-accent" />
              </div>
              <div>
                <label className="text-caption text-text-secondary block mb-1.5">地址</label>
                <input type="text" value={newZone.address} onChange={(e) => { setNewZone({ ...newZone, address: e.target.value }); setFormError('') }} className="w-full bg-bg-tertiary rounded-md px-3 py-2.5 text-body-small text-text-primary outline-none focus:ring-2 focus:ring-accent" />
              </div>
              <div>
                <label className="text-caption text-text-secondary block mb-1.5">围栏半径</label>
                <div className="flex flex-wrap gap-2">
                  {radiusOptions.map((r) => (
                    <button key={r} className={`px-3 py-2 rounded-md text-body-small font-medium transition-fast ${newZone.radius === r ? 'bg-accent-light text-accent ring-1 ring-accent' : 'bg-bg-tertiary text-text-secondary'}`} onClick={() => setNewZone({ ...newZone, radius: r })}>{r}</button>
                  ))}
                </div>
              </div>
            </div>
            {formError && <div className="text-caption text-danger mt-3">{formError}</div>}
            <div className="flex gap-3 mt-4">
              <button className="flex-1 py-3 bg-bg-tertiary rounded-md text-body-small font-medium text-text-secondary active:bg-border transition-fast" onClick={() => setShowEditZone(false)}>取消</button>
              <button className="flex-1 py-3 bg-accent rounded-md text-white text-body-small font-medium active:bg-text-primary transition-fast" onClick={handleEditZone}>保存</button>
            </div>
          </div>
        </div>
      )}

      {/* 测试结果提示 */}
      {showTestResult && (
        <div className="fixed inset-0 z-[60] flex items-center justify-center px-6">
          <div className="absolute inset-0 bg-black/40" />
          <div className="relative w-full max-w-[280px] bg-bg-secondary rounded-lg p-6 text-center animate-[pageEnter_250ms_ease-out]">
            <div className="w-14 h-14 bg-success-light rounded-full flex items-center justify-center mx-auto mb-3">
              <Check size={24} className="text-success" />
            </div>
            <div className="text-body font-semibold text-text-primary">测试通知已发送</div>
            <div className="text-caption text-text-tertiary mt-1">已向 {contacts.length} 位紧急联系人发送测试消息</div>
          </div>
        </div>
      )}
    </div>
  )
}

export default EmergencySettingsPage

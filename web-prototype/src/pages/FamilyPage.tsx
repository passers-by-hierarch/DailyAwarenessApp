import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { ChevronLeft, Plus, Shield, X, Check, User, Phone, Settings2, Trash2 } from 'lucide-react'

interface FamilyMember {
  id: string
  avatar: string
  name: string
  relationship: string
  phone: string
  permission: 'full' | 'view' | 'limited'
}

const permissionLabels: Record<FamilyMember['permission'], string> = {
  full: '完整查看 + 代问 + 代设置',
  view: '仅查看今日状态',
  limited: '仅查看健康数据',
}

const avatarOptions = ['👩', '👨', '👵', '👴', '👧', '👦']

// 初始 mock 数据
const initialFamilyMembers: FamilyMember[] = [
  { id: '1', avatar: '👩', name: '小明', relationship: '女儿', phone: '138****5678', permission: 'full' },
  { id: '2', avatar: '👨', name: '大强', relationship: '儿子', phone: '139****1234', permission: 'view' },
]

// 异常通知设置项
const notificationSettings = [
  { id: '1', label: '连续2天未记录行为', desc: '系统将自动通知所有已绑定家属', enabled: true },
  { id: '2', label: '必做事程超时未完成', desc: '必做事程超时未确认时通知家属', enabled: true },
  { id: '3', label: '离开安全区域', desc: '检测到离开设定区域时通知家属', enabled: false },
]

const FamilyPage = () => {
  const navigate = useNavigate()
  const [members, setMembers] = useState<FamilyMember[]>(initialFamilyMembers)
  const [settings, setSettings] = useState(notificationSettings)

  // 弹窗状态
  const [showInvite, setShowInvite] = useState(false)
  const [showDeleteConfirm, setShowDeleteConfirm] = useState(false)
  const [showPermissionEdit, setShowPermissionEdit] = useState(false)
  const [selectedMember, setSelectedMember] = useState<FamilyMember | null>(null)

  // 表单状态
  const [newMember, setNewMember] = useState({
    avatar: avatarOptions[0],
    name: '',
    relationship: '',
    phone: '',
    permission: 'full' as FamilyMember['permission'],
  })
  const [inviteError, setInviteError] = useState('')

  // 切换开关
  const toggleSetting = (id: string) => {
    setSettings(settings.map((s) => (s.id === id ? { ...s, enabled: !s.enabled } : s)))
  }

  // 打开邀请弹窗
  const openInvite = () => {
    setNewMember({
      avatar: avatarOptions[0],
      name: '',
      relationship: '',
      phone: '',
      permission: 'full',
    })
    setInviteError('')
    setShowInvite(true)
  }

  // 创建新家属
  const handleInvite = () => {
    if (!newMember.name.trim()) {
      setInviteError('请输入姓名')
      return
    }
    if (!newMember.phone.trim()) {
      setInviteError('请输入手机号')
      return
    }
    const member: FamilyMember = {
      ...newMember,
      id: `member-${Date.now()}`,
      phone: `${newMember.phone.slice(0, 3)}****${newMember.phone.slice(-4)}`,
    }
    setMembers([...members, member])
    setShowInvite(false)
  }

  // 打开解绑确认
  const openDeleteConfirm = (member: FamilyMember) => {
    setSelectedMember(member)
    setShowDeleteConfirm(true)
  }

  // 确认解绑
  const confirmDelete = () => {
    if (selectedMember) {
      setMembers(members.filter(m => m.id !== selectedMember.id))
    }
    setShowDeleteConfirm(false)
    setSelectedMember(null)
  }

  // 打开修改权限弹窗
  const openPermissionEdit = (member: FamilyMember) => {
    setSelectedMember(member)
    setShowPermissionEdit(true)
  }

  // 保存权限修改
  const savePermission = (permission: FamilyMember['permission']) => {
    if (selectedMember) {
      setMembers(members.map(m => m.id === selectedMember.id ? { ...m, permission } : m))
    }
    setShowPermissionEdit(false)
    setSelectedMember(null)
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
        <h1 className="text-body font-semibold text-text-primary">家属管理</h1>
        <button
          className="flex items-center gap-0.5 text-info transition-fast active:opacity-60"
          onClick={openInvite}
        >
          <Plus size={18} />
          <span className="text-body-small font-medium">邀请</span>
        </button>
      </header>

      {/* 提示区 */}
      <div className="px-4 py-3">
        <div className="bg-info-light rounded-md px-4 py-3 flex items-center gap-2">
          <span className="text-base">💡</span>
          <span className="text-body-small text-info">
            绑定家属后，他们可以远程查看您的状态并在紧急情况下收到通知
          </span>
        </div>
      </div>

      {/* 已绑定家属列表 */}
      <section className="px-4">
        <div className="text-caption font-semibold text-text-tertiary mb-2 px-1">
          已绑定家属（{members.length}）
        </div>

        {members.length === 0 ? (
          <div className="bg-bg-secondary rounded-lg card-shadow p-8 text-center">
            <div className="text-4xl mb-2">👨‍👩‍👧</div>
            <div className="text-body-small text-text-secondary mb-1">还没有绑定家属</div>
            <div className="text-caption text-text-tertiary mb-4">邀请家人，让他们关心您的日常</div>
            <button
              className="px-4 py-2 bg-accent rounded-md text-white text-body-small font-medium active:bg-text-primary transition-fast"
              onClick={openInvite}
            >
              邀请家属
            </button>
          </div>
        ) : (
          <div className="space-y-2.5">
            {members.map((member) => (
              <div
                key={member.id}
                className="bg-bg-secondary rounded-lg card-shadow p-4"
              >
                <div className="flex items-start gap-3">
                  <div className="w-12 h-12 bg-accent-light rounded-full flex items-center justify-center text-2xl shrink-0">
                    {member.avatar}
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="text-body font-medium text-text-primary">
                      {member.relationship} · {member.name}
                    </div>
                    <div className="text-caption text-text-secondary mt-0.5">
                      {member.phone}
                    </div>
                    <div className="text-caption text-accent mt-1">
                      {permissionLabels[member.permission]}
                    </div>
                  </div>
                </div>

                <div className="flex gap-2 mt-3">
                  <button
                    className="flex-1 py-2 bg-accent-light rounded-md text-accent text-caption font-medium transition-fast active:bg-accent/10 flex items-center justify-center gap-1"
                    onClick={() => openPermissionEdit(member)}
                  >
                    <Settings2 size={12} />
                    修改权限
                  </button>
                  <button
                    className="flex-1 py-2 bg-danger-light rounded-md text-danger text-caption font-medium transition-fast active:bg-danger-light/80 flex items-center justify-center gap-1"
                    onClick={() => openDeleteConfirm(member)}
                  >
                    <Trash2 size={12} />
                    解绑
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}
      </section>

      {/* 异常通知设置区 */}
      <section className="px-4 mt-6">
        <div className="px-1 py-2 flex items-center gap-2">
          <Shield size={16} className="text-accent" />
          <h2 className="text-body-small font-semibold text-text-secondary">异常自动通知家属</h2>
        </div>

        <div className="bg-bg-secondary rounded-lg card-shadow overflow-hidden">
          {settings.map((setting, index) => (
            <div
              key={setting.id}
              className={`p-4 ${index < settings.length - 1 ? 'border-b border-border' : ''}`}
            >
              <div className="flex items-start justify-between gap-3">
                <div className="flex-1 min-w-0">
                  <div className="text-body-small font-medium text-text-primary">{setting.label}</div>
                  <div className="text-caption text-text-tertiary mt-1 leading-relaxed">{setting.desc}</div>
                </div>
                <button
                  className={`relative w-11 h-6 rounded-full transition-fast shrink-0 ${setting.enabled ? 'bg-success' : 'bg-bg-tertiary'}`}
                  onClick={() => toggleSetting(setting.id)}
                >
                  <div
                    className={`absolute top-0.5 w-5 h-5 bg-white rounded-full shadow-sm transition-fast ${setting.enabled ? 'left-[22px]' : 'left-0.5'}`}
                  />
                </button>
              </div>
            </div>
          ))}
        </div>
      </section>

      {/* 邀请家属弹窗 */}
      {showInvite && (
        <div className="fixed inset-0 z-50 flex items-end justify-center">
          <div className="absolute inset-0 bg-black/40" onClick={() => setShowInvite(false)} />
          <div className="relative w-full max-w-[390px] bg-bg-secondary rounded-t-xl px-4 pt-5 pb-6 animate-[pageEnter_250ms_ease-out]">
            <div className="w-10 h-1 bg-bg-tertiary rounded-full mx-auto mb-4" />
            <div className="flex items-center justify-between mb-3">
              <h2 className="text-title-small font-semibold text-text-primary">邀请家属</h2>
              <button className="w-6 h-6 flex items-center justify-center text-text-secondary" onClick={() => setShowInvite(false)}>
                <X size={18} />
              </button>
            </div>

            <div className="space-y-3">
              {/* 选择头像 */}
              <div>
                <label className="text-caption text-text-secondary block mb-1.5">选择头像</label>
                <div className="flex gap-2">
                  {avatarOptions.map((av) => (
                    <button
                      key={av}
                      className={`w-10 h-10 rounded-full flex items-center justify-center text-xl transition-fast ${
                        newMember.avatar === av ? 'bg-accent-light ring-2 ring-accent' : 'bg-bg-tertiary'
                      }`}
                      onClick={() => setNewMember({ ...newMember, avatar: av })}
                    >
                      {av}
                    </button>
                  ))}
                </div>
              </div>

              {/* 姓名 */}
              <div>
                <label className="text-caption text-text-secondary block mb-1.5">姓名</label>
                <input
                  type="text"
                  value={newMember.name}
                  onChange={(e) => setNewMember({ ...newMember, name: e.target.value })}
                  placeholder="输入家属姓名"
                  className="w-full bg-bg-tertiary rounded-md px-3 py-2.5 text-body-small text-text-primary outline-none focus:ring-2 focus:ring-accent placeholder:text-text-tertiary"
                />
              </div>

              {/* 关系 */}
              <div>
                <label className="text-caption text-text-secondary block mb-1.5">关系</label>
                <input
                  type="text"
                  value={newMember.relationship}
                  onChange={(e) => setNewMember({ ...newMember, relationship: e.target.value })}
                  placeholder="如：女儿、儿子、老伴"
                  className="w-full bg-bg-tertiary rounded-md px-3 py-2.5 text-body-small text-text-primary outline-none focus:ring-2 focus:ring-accent placeholder:text-text-tertiary"
                />
              </div>

              {/* 手机号 */}
              <div>
                <label className="text-caption text-text-secondary block mb-1.5">手机号</label>
                <input
                  type="tel"
                  value={newMember.phone}
                  onChange={(e) => setNewMember({ ...newMember, phone: e.target.value.replace(/\D/g, '').slice(0, 11) })}
                  placeholder="输入手机号"
                  className="w-full bg-bg-tertiary rounded-md px-3 py-2.5 text-body-small text-text-primary outline-none focus:ring-2 focus:ring-accent placeholder:text-text-tertiary"
                />
              </div>

              {/* 权限 */}
              <div>
                <label className="text-caption text-text-secondary block mb-1.5">权限</label>
                <div className="space-y-1.5">
                  {(['full', 'view', 'limited'] as FamilyMember['permission'][]).map((p) => (
                    <button
                      key={p}
                      className={`w-full text-left px-3 py-2.5 rounded-md transition-fast ${
                        newMember.permission === p ? 'bg-accent-light ring-1 ring-accent' : 'bg-bg-tertiary'
                      }`}
                      onClick={() => setNewMember({ ...newMember, permission: p })}
                    >
                      <div className="flex items-center justify-between">
                        <span className={`text-body-small font-medium ${newMember.permission === p ? 'text-accent' : 'text-text-primary'}`}>
                          {permissionLabels[p]}
                        </span>
                        {newMember.permission === p && <Check size={14} className="text-accent" />}
                      </div>
                    </button>
                  ))}
                </div>
              </div>
            </div>

            {inviteError && <div className="text-caption text-danger mt-3">{inviteError}</div>}

            <div className="flex gap-3 mt-4">
              <button
                className="flex-1 py-3 bg-bg-tertiary rounded-md text-body-small font-medium text-text-secondary active:bg-border transition-fast"
                onClick={() => setShowInvite(false)}
              >
                取消
              </button>
              <button
                className="flex-1 py-3 bg-accent rounded-md text-white text-body-small font-medium active:bg-text-primary transition-fast"
                onClick={handleInvite}
              >
                发送邀请
              </button>
            </div>
          </div>
        </div>
      )}

      {/* 删除确认弹窗 */}
      {showDeleteConfirm && selectedMember && (
        <div className="fixed inset-0 z-50 flex items-center justify-center px-6">
          <div className="absolute inset-0 bg-black/40" onClick={() => setShowDeleteConfirm(false)} />
          <div className="relative w-full max-w-[300px] bg-bg-secondary rounded-lg overflow-hidden">
            <h2 className="text-title-small font-semibold text-text-primary text-center pt-6 px-5">确认解绑？</h2>
            <div className="px-5 py-4">
              <div className="bg-bg-tertiary rounded-md p-3 text-center">
                <div className="text-lg mb-1">{selectedMember.avatar}</div>
                <div className="text-body-small font-medium text-text-primary">
                  {selectedMember.relationship} · {selectedMember.name}
                </div>
                <div className="text-caption text-text-tertiary mt-1">解绑后对方将无法查看您的状态</div>
              </div>
            </div>
            <div className="flex gap-3 px-5 pb-6">
              <button
                className="flex-1 py-3 bg-danger rounded-md text-white text-body-small font-medium transition-fast active:bg-danger/80"
                onClick={confirmDelete}
              >
                解绑
              </button>
              <button
                className="flex-1 py-3 bg-bg-tertiary rounded-md text-text-secondary text-body-small font-medium transition-fast active:bg-border"
                onClick={() => setShowDeleteConfirm(false)}
              >
                取消
              </button>
            </div>
          </div>
        </div>
      )}

      {/* 修改权限弹窗 */}
      {showPermissionEdit && selectedMember && (
        <div className="fixed inset-0 z-50 flex items-center justify-center px-6">
          <div className="absolute inset-0 bg-black/40" onClick={() => setShowPermissionEdit(false)} />
          <div className="relative w-full max-w-[320px] bg-bg-secondary rounded-lg overflow-hidden">
            <div className="flex items-center justify-between px-5 pt-5 pb-3">
              <h2 className="text-body font-semibold text-text-primary">修改权限</h2>
              <button className="w-6 h-6 flex items-center justify-center text-text-secondary" onClick={() => setShowPermissionEdit(false)}>
                <X size={18} />
              </button>
            </div>
            <div className="px-5 pb-5">
              <div className="text-body-small text-text-secondary mb-3">为 {selectedMember.name} 设置权限：</div>
              <div className="space-y-2">
                {(['full', 'view', 'limited'] as FamilyMember['permission'][]).map((p) => (
                  <button
                    key={p}
                    className={`w-full text-left px-3 py-3 rounded-md transition-fast ${
                      selectedMember.permission === p ? 'bg-accent-light ring-1 ring-accent' : 'bg-bg-tertiary'
                    }`}
                    onClick={() => savePermission(p)}
                  >
                    <div className="flex items-center justify-between">
                      <span className={`text-body-small font-medium ${selectedMember.permission === p ? 'text-accent' : 'text-text-primary'}`}>
                        {permissionLabels[p]}
                      </span>
                      {selectedMember.permission === p && <Check size={14} className="text-accent" />}
                    </div>
                  </button>
                ))}
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

export default FamilyPage

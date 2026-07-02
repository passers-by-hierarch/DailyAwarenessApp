import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { ChevronLeft, Plus, Check, X, Edit2, Trash2, Hash, Activity, Package, ShoppingCart, MapPin } from 'lucide-react'
import { useAppStore, SYSTEM_TAGS, MAX_CUSTOM_TAGS, type TagColor } from '../store/appStore'

// 标签颜色映射
const colorClassMap: Record<TagColor, { color: string; bg: string; ring: string }> = {
  accent:  { color: 'text-accent',         bg: 'bg-accent-light',  ring: 'ring-accent' },
  info:    { color: 'text-info',           bg: 'bg-info-light',    ring: 'ring-info' },
  warning: { color: 'text-warning',        bg: 'bg-warning-light', ring: 'ring-warning' },
  success: { color: 'text-success',        bg: 'bg-success-light', ring: 'ring-success' },
  danger:  { color: 'text-danger',         bg: 'bg-danger-light',  ring: 'ring-danger' },
  gray:    { color: 'text-text-secondary', bg: 'bg-bg-tertiary',   ring: 'ring-text-tertiary' },
  purple:  { color: 'text-purple-600',     bg: 'bg-purple-100',    ring: 'ring-purple-400' },
}

const systemTagIcon: Record<string, React.ReactNode> = {
  behavior: <Activity size={14} />,
  item:     <Package size={14} />,
  shopping: <ShoppingCart size={14} />,
  event:    <MapPin size={14} />,
}

const TagManagementPage = () => {
  const navigate = useNavigate()
  const customTags = useAppStore(s => s.customTags)
  const addCustomTag = useAppStore(s => s.addCustomTag)
  const deleteCustomTag = useAppStore(s => s.deleteCustomTag)
  const renameCustomTag = useAppStore(s => s.renameCustomTag)
  const getAllTagsWithStats = useAppStore(s => s.getAllTagsWithStats)

  // 新建标签弹窗
  const [showCreate, setShowCreate] = useState(false)
  const [newName, setNewName] = useState('')
  const [newColor, setNewColor] = useState<TagColor>('purple')
  const [newIcon, setNewIcon] = useState('')
  const [createError, setCreateError] = useState('')

  // 重命名弹窗
  const [showRename, setShowRename] = useState(false)
  const [renameId, setRenameId] = useState('')
  const [renameName, setRenameName] = useState('')
  const [renameError, setRenameError] = useState('')

  // 删除确认
  const [deleteId, setDeleteId] = useState<string | null>(null)
  const deleteTag = deleteId ? customTags.find(t => t.id === deleteId) : null

  // 所有标签的统计数据
  const allTagsWithStats = getAllTagsWithStats()
  const systemTagsWithStats = allTagsWithStats.filter(t => t.system)
  const customTagsWithStats = allTagsWithStats.filter(t => !t.system)

  // 创建标签
  const handleCreate = () => {
    if (!newName.trim()) {
      setCreateError('请输入标签名')
      return
    }
    const result = addCustomTag({
      name: newName.trim(),
      color: newColor,
      icon: newIcon.trim() || '#',
    })
    if (!result.success) {
      setCreateError(result.error || '创建失败')
      return
    }
    // 重置并关闭
    setNewName('')
    setNewColor('purple')
    setNewIcon('')
    setCreateError('')
    setShowCreate(false)
  }

  // 打开重命名弹窗
  const openRename = (id: string, currentName: string) => {
    setRenameId(id)
    setRenameName(currentName)
    setRenameError('')
    setShowRename(true)
  }

  // 确认重命名
  const handleRename = () => {
    if (!renameName.trim()) {
      setRenameError('请输入标签名')
      return
    }
    const result = renameCustomTag(renameId, renameName.trim())
    if (!result.success) {
      setRenameError(result.error || '重命名失败')
      return
    }
    setShowRename(false)
  }

  // 渲染标签图标
  const renderIcon = (tag: { system: boolean; id: string; icon: string }) => {
    if (tag.system) {
      return systemTagIcon[tag.id] ?? <Hash size={14} />
    }
    return tag.icon && tag.icon.length <= 2 ? <span className="text-[12px]">{tag.icon}</span> : <Hash size={14} />
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
        <h1 className="text-body font-semibold text-text-primary">标签管理</h1>
        <div className="w-8" />
      </header>

      {/* 标签数量提示 */}
      <div className="px-4 pt-4">
        <div className="bg-accent-light rounded-md px-4 py-3 flex items-center justify-between">
          <div>
            <div className="text-body-small font-medium text-accent">我的自定义标签</div>
            <div className="text-caption text-accent/70 mt-0.5">系统标签不可删除，自定义标签可重命名/删除</div>
          </div>
          <div className="text-body font-semibold text-accent">
            {customTags.length}<span className="text-caption text-accent/70">/{MAX_CUSTOM_TAGS}</span>
          </div>
        </div>
      </div>

      {/* 系统标签区 */}
      <section className="px-4 mt-4">
        <div className="px-1 py-2 flex items-center gap-2">
          <div className="w-1.5 h-1.5 bg-accent rounded-full" />
          <h2 className="text-body-small font-semibold text-text-secondary">系统标签（不可删除）</h2>
        </div>

        <div className="bg-bg-secondary rounded-lg card-shadow overflow-hidden">
          {systemTagsWithStats.map((t, idx) => {
            const colorCls = colorClassMap[t.color]
            return (
              <div
                key={t.id}
                className={`flex items-center gap-3 p-4 ${idx > 0 ? 'border-t border-border' : ''}`}
              >
                <div className={`w-10 h-10 rounded-md flex items-center justify-center ${colorCls.bg} ${colorCls.color}`}>
                  {renderIcon(t)}
                </div>
                <div className="flex-1">
                  <div className="text-body-small font-medium text-text-primary">{t.name}</div>
                  <div className="text-caption text-text-tertiary mt-0.5">
                    使用 {t.count} 次 · {t.lastUsed === '未使用' ? '未使用' : `最近 ${t.lastUsed}`}
                  </div>
                </div>
                <span className="px-2 py-0.5 rounded-sm bg-bg-tertiary text-caption text-text-tertiary">系统</span>
              </div>
            )
          })}
        </div>
      </section>

      {/* 我的标签区 */}
      <section className="px-4 mt-4">
        <div className="px-1 py-2 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <div className="w-1.5 h-1.5 bg-accent rounded-full" />
            <h2 className="text-body-small font-semibold text-text-secondary">我的标签</h2>
          </div>
          <button
            className="flex items-center gap-1 text-caption text-accent active:opacity-60"
            onClick={() => setShowCreate(true)}
            disabled={customTags.length >= MAX_CUSTOM_TAGS}
          >
            <Plus size={12} />
            新建
          </button>
        </div>

        {customTagsWithStats.length === 0 ? (
          <div className="bg-bg-secondary rounded-lg card-shadow p-8 text-center">
            <div className="text-4xl mb-2">🏷</div>
            <div className="text-body-small text-text-secondary mb-1">还没有自定义标签</div>
            <div className="text-caption text-text-tertiary mb-4">创建标签来更好地分类你的记录</div>
            <button
              className="px-4 py-2 bg-accent rounded-md text-white text-body-small font-medium active:bg-text-primary transition-fast"
              onClick={() => setShowCreate(true)}
            >
              新建第一个标签
            </button>
          </div>
        ) : (
          <div className="bg-bg-secondary rounded-lg card-shadow overflow-hidden">
            {customTagsWithStats.map((t, idx) => {
              const colorCls = colorClassMap[t.color]
              return (
                <div
                  key={t.id}
                  className={`flex items-center gap-3 p-4 ${idx > 0 ? 'border-t border-border' : ''}`}
                >
                  <div className={`w-10 h-10 rounded-md flex items-center justify-center ${colorCls.bg} ${colorCls.color}`}>
                    {renderIcon(t)}
                  </div>
                  <div className="flex-1">
                    <div className="text-body-small font-medium text-text-primary">{t.name}</div>
                    <div className="text-caption text-text-tertiary mt-0.5">
                      使用 {t.count} 次 · {t.lastUsed === '未使用' ? '未使用' : `最近 ${t.lastUsed}`}
                    </div>
                  </div>
                  {/* 操作按钮 */}
                  <div className="flex items-center gap-1">
                    <button
                      className="w-8 h-8 flex items-center justify-center text-text-secondary active:bg-bg-tertiary rounded-md transition-fast"
                      onClick={() => openRename(t.id, t.name)}
                    >
                      <Edit2 size={14} />
                    </button>
                    <button
                      className="w-8 h-8 flex items-center justify-center text-danger active:bg-danger-light rounded-md transition-fast"
                      onClick={() => setDeleteId(t.id)}
                    >
                      <Trash2 size={14} />
                    </button>
                  </div>
                </div>
              )
            })}
          </div>
        )}
      </section>

      {/* 说明 */}
      <section className="px-4 mt-4">
        <div className="bg-bg-tertiary rounded-md p-4">
          <div className="text-caption text-text-secondary leading-relaxed">
            <div className="font-medium text-text-primary mb-1.5">说明</div>
            • 删除自定义标签后，历史记录中的该标签会显示为"已删除"灰色标记<br />
            • 标签名最多 8 个字，不可与已有标签重名<br />
            • 自定义标签最多 {MAX_CUSTOM_TAGS} 个
          </div>
        </div>
      </section>

      {/* 新建标签弹窗 */}
      {showCreate && (
        <div className="fixed inset-0 z-50 flex items-center justify-center px-6">
          <div className="absolute inset-0 bg-black/40" onClick={() => setShowCreate(false)} />
          <div className="relative w-full max-w-[320px] bg-bg-secondary rounded-lg overflow-hidden">
            <div className="flex items-center justify-between px-5 pt-5 pb-3">
              <h2 className="text-body font-semibold text-text-primary">新建标签</h2>
              <button
                className="w-6 h-6 flex items-center justify-center text-text-secondary active:opacity-60"
                onClick={() => setShowCreate(false)}
              >
                <X size={18} />
              </button>
            </div>

            <div className="px-5 pb-5">
              {/* 标签名 */}
              <div className="mb-3">
                <label className="text-caption text-text-secondary block mb-1.5">标签名称</label>
                <input
                  type="text"
                  value={newName}
                  onChange={(e) => { setNewName(e.target.value); setCreateError('') }}
                  placeholder="如：运动、就医、陪孙子"
                  maxLength={8}
                  className="w-full bg-bg-tertiary rounded-md px-3 py-2.5 text-body-small text-text-primary outline-none focus:ring-2 focus:ring-accent placeholder:text-text-tertiary"
                />
              </div>

              {/* 颜色选择 */}
              <div className="mb-3">
                <label className="text-caption text-text-secondary block mb-1.5">选择颜色</label>
                <div className="flex gap-2">
                  {(['accent', 'info', 'warning', 'success', 'danger', 'purple', 'gray'] as TagColor[]).map((c) => {
                    const colorCls = colorClassMap[c]
                    const selected = newColor === c
                    return (
                      <button
                        key={c}
                        className={`w-8 h-8 rounded-full ${colorCls.bg} ${colorCls.color} flex items-center justify-center transition-fast ${
                          selected ? 'ring-2 ring-offset-2 ring-offset-bg-secondary ' + colorCls.ring : ''
                        }`}
                        onClick={() => setNewColor(c)}
                      >
                        {selected && <Check size={14} />}
                      </button>
                    )
                  })}
                </div>
              </div>

              {/* 图标选择（可选） */}
              <div className="mb-4">
                <label className="text-caption text-text-secondary block mb-1.5">
                  选择图标 <span className="text-text-tertiary">（可选，默认用 #）</span>
                </label>
                <div className="flex flex-wrap gap-2">
                  {['#', '🏃', '💊', '📚', '🎯', '🚗', '✈️', '🎵', '☕', '🌳', '👨‍👩‍👦', '🐾'].map((ic) => (
                    <button
                      key={ic}
                      className={`w-9 h-9 rounded-md flex items-center justify-center text-body transition-fast ${
                        newIcon === ic ? 'bg-accent-light ring-1 ring-accent' : 'bg-bg-tertiary'
                      }`}
                      onClick={() => setNewIcon(ic)}
                    >
                      {ic === '#' ? <Hash size={14} /> : <span>{ic}</span>}
                    </button>
                  ))}
                </div>
              </div>

              {createError && (
                <div className="text-caption text-danger mb-3">{createError}</div>
              )}

              <div className="flex gap-3">
                <button
                  className="flex-1 py-2.5 bg-bg-tertiary rounded-md text-body-small font-medium text-text-secondary active:bg-border transition-fast"
                  onClick={() => setShowCreate(false)}
                >
                  取消
                </button>
                <button
                  className="flex-1 py-2.5 bg-accent rounded-md text-white text-body-small font-medium active:bg-text-primary transition-fast"
                  onClick={handleCreate}
                >
                  创建
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* 重命名弹窗 */}
      {showRename && (
        <div className="fixed inset-0 z-50 flex items-center justify-center px-6">
          <div className="absolute inset-0 bg-black/40" onClick={() => setShowRename(false)} />
          <div className="relative w-full max-w-[300px] bg-bg-secondary rounded-lg overflow-hidden">
            <div className="flex items-center justify-between px-5 pt-5 pb-3">
              <h2 className="text-body font-semibold text-text-primary">重命名标签</h2>
              <button
                className="w-6 h-6 flex items-center justify-center text-text-secondary active:opacity-60"
                onClick={() => setShowRename(false)}
              >
                <X size={18} />
              </button>
            </div>

            <div className="px-5 pb-5">
              <input
                type="text"
                value={renameName}
                onChange={(e) => { setRenameName(e.target.value); setRenameError('') }}
                placeholder="输入新名称"
                maxLength={8}
                className="w-full bg-bg-tertiary rounded-md px-3 py-2.5 text-body-small text-text-primary outline-none focus:ring-2 focus:ring-accent placeholder:text-text-tertiary mb-3"
                autoFocus
              />
              {renameError && (
                <div className="text-caption text-danger mb-3">{renameError}</div>
              )}
              <div className="flex gap-3">
                <button
                  className="flex-1 py-2.5 bg-bg-tertiary rounded-md text-body-small font-medium text-text-secondary active:bg-border transition-fast"
                  onClick={() => setShowRename(false)}
                >
                  取消
                </button>
                <button
                  className="flex-1 py-2.5 bg-accent rounded-md text-white text-body-small font-medium active:bg-text-primary transition-fast"
                  onClick={handleRename}
                >
                  保存
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* 删除确认弹窗 */}
      {deleteTag && (
        <div className="fixed inset-0 z-50 flex items-center justify-center px-6">
          <div className="absolute inset-0 bg-black/40" onClick={() => setDeleteId(null)} />
          <div className="relative w-full max-w-[300px] bg-bg-secondary rounded-lg overflow-hidden">
            <h2 className="text-title-small font-semibold text-text-primary text-center pt-6 px-5">确认删除标签？</h2>
            <div className="px-5 py-4">
              <div className="bg-bg-tertiary rounded-md p-3 text-center">
                <div className="text-body-small font-medium text-text-primary">{deleteTag.name}</div>
                <div className="text-caption text-text-tertiary mt-1">历史记录中将显示为"已删除"灰色标记</div>
              </div>
            </div>
            <div className="flex gap-3 px-5 pb-6">
              <button
                className="flex-1 py-3 bg-danger rounded-md text-white text-body-small font-medium transition-fast active:bg-danger/80"
                onClick={() => {
                  deleteCustomTag(deleteTag.id)
                  setDeleteId(null)
                }}
              >
                删除
              </button>
              <button
                className="flex-1 py-3 bg-bg-tertiary rounded-md text-text-secondary text-body-small font-medium transition-fast active:bg-border"
                onClick={() => setDeleteId(null)}
              >
                取消
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

export default TagManagementPage

import { useState } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { ChevronLeft, Clock, Mic, Link, Check, X, Brain, Package, ShoppingCart, Activity, MapPin, Hash, Tag, Sparkles, Plus, MessageSquare, Square, Volume2 } from 'lucide-react'
import { useAppStore, SYSTEM_TAGS, type TagColor } from '../store/appStore'

// 标签颜色映射到 Tailwind 类名
const colorClassMap: Record<TagColor, { color: string; bg: string; ring: string }> = {
  accent:  { color: 'text-accent',         bg: 'bg-accent-light',  ring: 'ring-accent' },
  info:    { color: 'text-info',           bg: 'bg-info-light',    ring: 'ring-info' },
  warning: { color: 'text-warning',        bg: 'bg-warning-light', ring: 'ring-warning' },
  success: { color: 'text-success',        bg: 'bg-success-light', ring: 'ring-success' },
  danger:  { color: 'text-danger',         bg: 'bg-danger-light',  ring: 'ring-danger' },
  gray:    { color: 'text-text-secondary', bg: 'bg-bg-tertiary',   ring: 'ring-text-tertiary' },
  purple:  { color: 'text-purple-600',     bg: 'bg-purple-100',    ring: 'ring-purple-400' },
}

// 系统标签图标映射
const systemTagIcon: Record<string, React.ReactNode> = {
  behavior: <Activity size={12} />,
  item:     <Package size={12} />,
  shopping: <ShoppingCart size={12} />,
  event:    <MapPin size={12} />,
}

const TimelineDetailPage = () => {
  const navigate = useNavigate()
  const { id } = useParams()
  const recordId = id

  // 从 store 中查找记录
  const record = useAppStore(s => s.timelineRecords.find(r => r.id === recordId))
  const updateRecordTags = useAppStore(s => s.updateRecordTags)
  const setTagPreference = useAppStore(s => s.setTagPreference)
  const customTags = useAppStore(s => s.customTags)
  const getTagDef = useAppStore(s => s.getTagDef)
  const addCustomTag = useAppStore(s => s.addCustomTag)
  const addNoteToRecord = useAppStore(s => s.addNoteToRecord)
  const deleteNoteFromRecord = useAppStore(s => s.deleteNoteFromRecord)

  // 标签编辑弹窗
  const [showTagEditor, setShowTagEditor] = useState(false)
  const [editingTags, setEditingTags] = useState<string[]>([])
  // 新建标签子弹窗
  const [showCreateTag, setShowCreateTag] = useState(false)
  const [newTagName, setNewTagName] = useState('')
  const [newTagColor, setNewTagColor] = useState<TagColor>('purple')
  const [newTagIcon, setNewTagIcon] = useState('')
  const [createError, setCreateError] = useState('')

  // 删除确认
  const [showDeleteConfirm, setShowDeleteConfirm] = useState(false)

  // 补充记录
  const [isRecordingNote, setIsRecordingNote] = useState(false)
  // 补充记录语音播放（TTS朗读）
  const [playingNoteId, setPlayingNoteId] = useState<string | null>(null)
  // 原始语音播放
  const [isPlayingOriginal, setIsPlayingOriginal] = useState(false)
  // 长按删除
  const [longPressNoteId, setLongPressNoteId] = useState<string | null>(null)
  const [showDeleteNoteConfirm, setShowDeleteNoteConfirm] = useState(false)

  // 通用TTS朗读
  const speak = (content: string, onEnd?: () => void) => {
    if (!window.speechSynthesis || !window.SpeechSynthesisUtterance) {
      // 不支持，模拟3秒
      onEnd && setTimeout(onEnd, 3000)
      return
    }
    window.speechSynthesis.cancel()
    const utter = new window.SpeechSynthesisUtterance(content)
    utter.lang = 'zh-CN'
    utter.rate = 0.95
    utter.onend = () => onEnd?.()
    utter.onerror = () => onEnd?.()
    window.speechSynthesis.speak(utter)
  }

  // 播放/停止原始语音
  const handleTogglePlayOriginal = () => {
    if (isPlayingOriginal) {
      window.speechSynthesis?.cancel()
      setIsPlayingOriginal(false)
      return
    }
    setIsPlayingOriginal(true)
    speak(record.content, () => setIsPlayingOriginal(false))
  }

  // 播放/停止补充记录
  const handleTogglePlayNote = (noteId: string, content: string) => {
    if (playingNoteId === noteId) {
      window.speechSynthesis?.cancel()
      setPlayingNoteId(null)
      return
    }
    setPlayingNoteId(noteId)
    speak(content, () => setPlayingNoteId(null))
  }

  // 长按删除补充记录
  const startLongPress = (noteId: string) => {
    const timer = setTimeout(() => {
      setLongPressNoteId(noteId)
      setShowDeleteNoteConfirm(true)
    }, 600)
    ;(window as any).__noteLongPressTimer = timer
  }
  const cancelLongPress = () => {
    if ((window as any).__noteLongPressTimer) {
      clearTimeout((window as any).__noteLongPressTimer)
      ;(window as any).__noteLongPressTimer = null
    }
  }

  // 模拟语音识别补充内容的候选
  const sampleNoteRecognitions = [
    '后来又移动到了其他地方',
    '顺便还做了一些其他事情',
    '当时的情况是这样的',
    '补充一些细节信息',
    '记得不是很清楚，大概是这个时间',
  ]

  // 开始录音（模拟3秒后自动结束）
  const handleStartNoteVoice = () => {
    if (isRecordingNote) return
    setIsRecordingNote(true)
    const timer = setTimeout(() => {
      handleStopNoteVoice()
    }, 3000)
    // 用 ref 保存 timer（这里直接挂到 window 上简化）
    ;(window as any).__noteVoiceTimer = timer
  }

  // 停止录音，模拟识别结果直接保存为补充记录
  const handleStopNoteVoice = () => {
    setIsRecordingNote(false)
    if ((window as any).__noteVoiceTimer) {
      clearTimeout((window as any).__noteVoiceTimer)
      ;(window as any).__noteVoiceTimer = null
    }
    // 随机生成识别结果，直接保存
    const randomText = sampleNoteRecognitions[Math.floor(Math.random() * sampleNoteRecognitions.length)]
    addNoteToRecord(record.id, randomText)
  }

  // 切换录音状态
  const handleToggleNoteVoice = () => {
    if (isRecordingNote) {
      handleStopNoteVoice()
    } else {
      handleStartNoteVoice()
    }
  }

  // 删除补充记录
  const handleDeleteNote = () => {
    if (longPressNoteId) {
      deleteNoteFromRecord(record.id, longPressNoteId)
      setLongPressNoteId(null)
    }
    setShowDeleteNoteConfirm(false)
  }

  // 如果记录不存在
  if (!record) {
    return (
      <div className="page-enter min-h-screen bg-bg-primary flex flex-col items-center justify-center">
        <div className="text-4xl mb-3">📭</div>
        <div className="text-body text-text-secondary mb-4">记录不存在</div>
        <button
          className="px-6 py-2.5 bg-accent rounded-md text-white text-body-small font-medium"
          onClick={() => navigate(-1)}
        >
          返回
        </button>
      </div>
    )
  }

  // 标签 + 抽取数据
  const tags = record.tags
  const extractedData = record.extractedData as Partial<Record<string, any>>

  // 打开标签编辑器
  const openTagEditor = () => {
    setEditingTags([...tags])
    setShowTagEditor(true)
  }

  // 切换标签选中状态
  const toggleTag = (tagId: string) => {
    if (editingTags.includes(tagId)) {
      // 至少保留一个标签
      if (editingTags.length > 1) {
        setEditingTags(editingTags.filter(x => x !== tagId))
      }
    } else {
      setEditingTags([...editingTags, tagId])
    }
  }

  // 保存标签修改 + 记忆偏好
  const saveTags = () => {
    updateRecordTags(record.id, editingTags)
    // 记忆用户偏好：根据抽取数据的核心关键词作为 key
    let prefKey: string | undefined
    if (extractedData.item?.itemName) prefKey = `item:${extractedData.item.itemName}`
    else if (extractedData.shopping?.store) prefKey = `shopping:${extractedData.shopping.store}`
    else if (extractedData.behavior?.behavior) prefKey = `behavior:${extractedData.behavior.behavior}`
    if (prefKey) {
      setTagPreference(prefKey, editingTags)
    }
    setShowTagEditor(false)
  }

  // 创建新标签
  const handleCreateTag = () => {
    if (!newTagName.trim()) {
      setCreateError('请输入标签名')
      return
    }
    const result = addCustomTag({
      name: newTagName.trim(),
      color: newTagColor,
      icon: newTagIcon.trim() || '#',
    })
    if (!result.success) {
      setCreateError(result.error || '创建失败')
      return
    }
    // 创建成功后，自动选中新标签
    // 注意：addCustomTag 用 genId() 生成ID，我们需要重新获取最新的 customTags
    // 但由于 Zustand 是同步的，下一个渲染周期会拿到新标签
    // 这里用 setTimeout 等待状态更新
    setTimeout(() => {
      const latestCustomTags = useAppStore.getState().customTags
      const newTag = latestCustomTags[latestCustomTags.length - 1]
      if (newTag) {
        setEditingTags([...editingTags, newTag.id])
      }
      // 重置表单
      setNewTagName('')
      setNewTagColor('purple')
      setNewTagIcon('')
      setCreateError('')
      setShowCreateTag(false)
    }, 0)
  }

  // 渲染标签徽章（系统标签 + 自定义标签 + 已删除标签）
  const renderTagBadge = (tagId: string, size: 'sm' | 'md' = 'md') => {
    const def = getTagDef(tagId)
    const padding = size === 'sm' ? 'px-1.5 py-0.5' : 'px-2 py-1'
    if (!def) {
      return (
        <span className={`inline-flex items-center gap-0.5 ${padding} rounded-sm bg-bg-tertiary text-text-tertiary text-caption line-through`}>
          <Hash size={12} />
          已删除
        </span>
      )
    }
    const colorCls = colorClassMap[def.color]
    const icon = def.system
      ? (systemTagIcon[def.id] ?? <Hash size={12} />)
      : (def.icon && def.icon.length <= 2 ? <span className="text-[10px]">{def.icon}</span> : <Hash size={12} />)
    return (
      <span className={`inline-flex items-center gap-0.5 ${padding} rounded-sm ${colorCls.bg} ${colorCls.color} text-caption`}>
        {icon}
        {def.name}
      </span>
    )
  }

  // 信息行组件
  const InfoRow = ({ label, value, valueClass = 'text-text-primary' }: { label: string; value: string; valueClass?: string }) => (
    <div className="flex items-center justify-between py-2.5">
      <span className="text-body-small text-text-secondary">{label}</span>
      <span className={`text-body-small font-medium ${valueClass}`}>{value}</span>
    </div>
  )

  // 抽取数据展示组件（按标签类型，仅系统标签有抽取数据）
  const ExtractedDataSection = ({ tagId }: { tagId: string }) => {
    // 仅系统4类标签有抽取数据展示
    const systemKey = tagId as 'behavior' | 'item' | 'shopping' | 'event'
    const data = extractedData[systemKey]
    if (!data) return null
    const def = getTagDef(tagId)
    if (!def) return null
    const colorCls = colorClassMap[def.color]
    const icon = systemTagIcon[tagId] ?? <Hash size={12} />

    return (
      <div className="bg-bg-tertiary rounded-md p-3 mb-2">
        <div className="flex items-center gap-1.5 mb-2">
          <span className={`inline-flex items-center gap-0.5 px-1.5 py-0.5 rounded-sm ${colorCls.bg} ${colorCls.color} text-caption`}>
            {icon}
            {def.name}
          </span>
        </div>

        {tagId === 'behavior' && (
          <div className="space-y-1.5">
            <div className="flex justify-between">
              <span className="text-body-small text-text-secondary">行为名称</span>
              <span className="text-body-small font-medium text-text-primary">{data.behavior}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-body-small text-text-secondary">行为分类</span>
              <span className="text-body-small font-medium text-text-primary">{data.category}</span>
            </div>
          </div>
        )}

        {tagId === 'item' && (
          <div className="space-y-1.5">
            <div className="flex justify-between">
              <span className="text-body-small text-text-secondary">物品名称</span>
              <span className="text-body-small font-medium text-text-primary">{data.itemName}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-body-small text-text-secondary">存放位置</span>
              <span className="text-body-small font-medium text-success">{data.location}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-body-small text-text-secondary">操作类型</span>
              <span className="text-body-small font-medium text-text-primary">
                {data.action === 'place' ? '放置' : data.action === 'take' ? '拿取' : '找到'}
              </span>
            </div>
            <div className="mt-2 pt-2 border-t border-border flex items-center gap-1.5">
              <Check size={12} className="text-success" />
              <span className="text-caption text-success">已自动同步到物品位置记忆</span>
            </div>
          </div>
        )}

        {tagId === 'shopping' && (
          <div className="space-y-2">
            {data.store && (
              <div className="flex justify-between">
                <span className="text-body-small text-text-secondary">购买地点</span>
                <span className="text-body-small font-medium text-text-primary">{data.store}</span>
              </div>
            )}
            <div>
              <div className="text-body-small text-text-secondary mb-1.5">购买清单</div>
              <div className="space-y-1">
                {data.items.map((item: any, i: number) => (
                  <div key={i} className="flex items-center justify-between bg-bg-secondary rounded-md px-3 py-1.5">
                    <span className="text-body-small font-medium text-text-primary">{item.name}</span>
                    <span className="text-body-small text-accent font-mono">{item.quantity}{item.unit}</span>
                  </div>
                ))}
              </div>
            </div>
            <div className="mt-2 pt-2 border-t border-border flex items-center gap-1.5">
              <Check size={12} className="text-success" />
              <span className="text-caption text-success">已自动保存到购物记录</span>
            </div>
          </div>
        )}

        {tagId === 'event' && (
          <div className="space-y-1.5">
            <div className="flex justify-between">
              <span className="text-body-small text-text-secondary">事件</span>
              <span className="text-body-small font-medium text-text-primary">{data.event}</span>
            </div>
            {data.location && (
              <div className="flex justify-between">
                <span className="text-body-small text-text-secondary">地点</span>
                <span className="text-body-small font-medium text-text-primary">{data.location}</span>
              </div>
            )}
          </div>
        )}
      </div>
    )
  }

  // 匹配的事程
  const matchedAgenda = record.matchedAgenda ? {
    time: record.matchedAgenda.match(/\d{2}:\d{2}/)?.[0] || '15:00',
    content: record.matchedAgenda.replace(/\d{2}:\d{2}/, '').trim() || '事程',
    status: '已匹配',
  } : undefined

  // 系统标签中有抽取数据的
  const systemTagsWithData = tags.filter(t => extractedData[t])

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
        <h1 className="text-body font-semibold text-text-primary">时间线详情</h1>
        <button
          className="text-body-small font-medium text-danger transition-fast active:opacity-60"
          onClick={() => setShowDeleteConfirm(true)}
        >
          删除
        </button>
      </header>

      {/* 基本信息卡 */}
      <section className="px-4 pt-4">
        <div className="bg-bg-secondary rounded-lg card-shadow p-4">
          {/* 时间 + 内容 */}
          <div className="flex items-start gap-3">
            <div className="w-12 h-12 bg-success-light rounded-lg flex items-center justify-center shrink-0">
              <Clock size={24} className="text-success" />
            </div>

            <div className="flex-1 min-w-0">
              <div className="flex items-center gap-2 flex-wrap">
                <span className="text-time font-mono text-text-secondary">
                  {record.time}
                </span>
                <span className={`px-2 py-0.5 rounded-sm text-caption ${record.status === 'matched' ? 'bg-success-light text-success' : record.matchedAgenda ? 'bg-accent-light text-accent' : 'bg-bg-tertiary text-text-secondary'}`}>
                  {record.status === 'matched' ? '已匹配' : record.matchedAgenda ? '已创建事程' : '未匹配'}
                </span>
              </div>
              <div className="text-body font-medium text-text-primary mt-1.5">
                {record.content}
              </div>
            </div>
          </div>

          {/* 分割线 */}
          <div className="h-px bg-border my-3" />

          {/* 标签展示 + 修改入口 */}
          <div className="py-2">
            <div className="flex items-center justify-between mb-2">
              <span className="text-body-small text-text-secondary">智能标签</span>
              <button
                className="flex items-center gap-1 text-caption text-accent active:opacity-60"
                onClick={openTagEditor}
              >
                <Tag size={12} />
                修改标签
              </button>
            </div>
            <div className="flex flex-wrap gap-1.5">
              {tags.map((tagId) => renderTagBadge(tagId))}
            </div>
            <div className="text-caption text-text-tertiary mt-1.5">
              标签不准？点击"修改标签"调整，系统会记住你的偏好
            </div>
          </div>
        </div>
      </section>

      {/* 原始语音内容 */}
      <section className="px-4 mt-4">
        <div className="px-1 py-2 flex items-center gap-2">
          <Mic size={16} className="text-accent" />
          <h2 className="text-body-small font-semibold text-text-secondary">原始语音内容</h2>
        </div>

        <div className="bg-bg-secondary rounded-lg card-shadow p-4">
          {/* 语音播放器 - 可点击播放 */}
          <button
            type="button"
            className={`w-full flex items-center gap-3 mb-3 transition-fast active:opacity-70 ${isPlayingOriginal ? 'opacity-90' : ''}`}
            onClick={handleTogglePlayOriginal}
          >
            <div className={`w-10 h-10 rounded-full flex items-center justify-center shrink-0 transition-fast ${isPlayingOriginal ? 'bg-danger' : 'bg-accent'}`}>
              {isPlayingOriginal ? <Square size={16} className="text-white fill-current" /> : <Mic size={18} className="text-white" />}
            </div>
            <div className="flex-1">
              <div className="flex items-center gap-1">
                {[8, 16, 12, 20, 10, 18, 14, 22, 8, 16].map((height, i) => (
                  <div
                    key={i}
                    className={`w-1 rounded-full transition-fast ${isPlayingOriginal ? 'bg-danger animate-pulse' : 'bg-accent'}`}
                    style={{ height: `${height}px`, animationDelay: `${i * 100}ms` }}
                  />
                ))}
              </div>
              <div className="flex justify-between mt-2">
                <span className="text-caption text-text-tertiary">{isPlayingOriginal ? '正在播放...' : '0:02'}</span>
              </div>
            </div>
          </button>

          {/* 文字内容 */}
          <div className="bg-bg-tertiary rounded-md p-3">
            <div className={`text-body-small leading-relaxed ${isPlayingOriginal ? 'text-accent' : 'text-text-primary'}`}>
              {record.content}
            </div>
          </div>
        </div>
      </section>

      {/* 补充记录 */}
      <section className="px-4 mt-4">
        <div className="px-1 py-2 flex items-center gap-2">
          <MessageSquare size={16} className="text-accent" />
          <h2 className="text-body-small font-semibold text-text-secondary">补充记录</h2>
          <span className="text-caption text-text-tertiary ml-auto">{record.notes.length}条</span>
        </div>

        <div className="bg-bg-secondary rounded-lg card-shadow p-4">
          {/* 已有补充记录列表 - 样式类似原始语音但稍小 */}
          {record.notes.length > 0 && (
            <div className="space-y-3 mb-3">
              {record.notes.map((note) => {
                const isPlaying = playingNoteId === note.id
                return (
                  <div
                    key={note.id}
                    className="bg-bg-tertiary rounded-md p-3 select-none"
                    onPointerDown={() => startLongPress(note.id)}
                    onPointerUp={cancelLongPress}
                    onPointerLeave={cancelLongPress}
                    onContextMenu={(e) => { e.preventDefault(); setLongPressNoteId(note.id); setShowDeleteNoteConfirm(true) }}
                  >
                    <div className="flex items-start gap-3">
                      {/* 左侧时间 */}
                      <div className="w-12 text-time font-mono text-text-secondary shrink-0 pt-0.5">
                        {note.createdAt}
                      </div>
                      {/* 播放按钮 */}
                      <button
                        type="button"
                        className={`w-6 h-6 rounded-full flex items-center justify-center shrink-0 mt-0.5 transition-fast ${
                          isPlaying ? 'bg-danger text-white' : 'bg-accent-light text-accent active:opacity-60'
                        }`}
                        onClick={() => handleTogglePlayNote(note.id, note.content)}
                      >
                        {isPlaying ? (
                          <Square size={9} className="fill-current" />
                        ) : (
                          <Volume2 size={12} />
                        )}
                      </button>
                      {/* 右侧文字内容 */}
                      <div className={`flex-1 min-w-0 text-body-small leading-relaxed ${isPlaying ? 'text-accent' : 'text-text-primary'}`}>
                        {note.content}
                      </div>
                    </div>
                  </div>
                )
              })}
            </div>
          )}

          {/* 添加补充记录 - 直接开始录音 */}
          {isRecordingNote ? (
            <button
              type="button"
              className="w-full py-4 bg-danger rounded-md text-white text-body-small font-semibold flex items-center justify-center gap-2 active:bg-danger/80 transition-fast animate-pulse"
              onClick={handleToggleNoteVoice}
            >
              <span className="flex items-center gap-0.5">
                {[6, 12, 8, 14, 6, 10, 8].map((h, i) => (
                  <span
                    key={i}
                    className="w-1 bg-white rounded-full animate-pulse"
                    style={{ height: `${h}px`, animationDelay: `${i * 120}ms` }}
                  />
                ))}
              </span>
              点击停止录音，自动保存
            </button>
          ) : (
            <button
              className="w-full py-3 bg-bg-tertiary rounded-md border border-dashed border-border flex items-center justify-center gap-2 text-text-secondary active:bg-border transition-fast"
              onClick={() => handleStartNoteVoice()}
            >
              <Mic size={16} />
              <span className="text-body-small font-medium">语音补充记录</span>
            </button>
          )}
          <div className="text-caption text-text-tertiary text-center mt-2">
            长按已添加的记录可删除
          </div>
        </div>
      </section>

      {/* 删除补充记录确认弹窗 */}
      {showDeleteNoteConfirm && (
        <div className="fixed inset-0 z-50 flex items-center justify-center px-6">
          <div className="absolute inset-0 bg-black/40" onClick={() => { setShowDeleteNoteConfirm(false); setLongPressNoteId(null) }} />
          <div className="relative w-full max-w-[300px] bg-bg-secondary rounded-lg overflow-hidden">
            <h2 className="text-title-small font-semibold text-text-primary text-center pt-6 px-5">删除这条补充记录？</h2>
            <div className="flex gap-3 px-5 py-5">
              <button
                className="flex-1 py-3 bg-danger rounded-md text-white text-body-small font-medium transition-fast active:bg-danger/80"
                onClick={handleDeleteNote}
              >
                删除
              </button>
              <button
                className="flex-1 py-3 bg-bg-tertiary rounded-md text-text-secondary text-body-small font-medium transition-fast active:bg-border"
                onClick={() => { setShowDeleteNoteConfirm(false); setLongPressNoteId(null) }}
              >
                取消
              </button>
            </div>
          </div>
        </div>
      )}

      {/* 智能识别结果（仅展示有抽取数据的系统标签） */}
      {systemTagsWithData.length > 0 && (
        <section className="px-4 mt-4">
          <div className="px-1 py-2 flex items-center gap-2">
            <Brain size={16} className="text-accent" />
            <h2 className="text-body-small font-semibold text-text-secondary">
              智能识别结果（{systemTagsWithData.length}个标签）
            </h2>
          </div>

          <div className="bg-bg-secondary rounded-lg card-shadow p-4">
            {/* 遍历有抽取数据的系统标签 */}
            {systemTagsWithData.map((tagId) => (
              <ExtractedDataSection key={tagId} tagId={tagId} />
            ))}
          </div>
        </section>
      )}

      {/* 关联的事程 */}
      {matchedAgenda ? (
        <section className="px-4 mt-4">
          <div className="px-1 py-2 flex items-center gap-2">
            {record.status === 'matched' ? (
              <>
                <Link size={16} className="text-success" />
                <h2 className="text-body-small font-semibold text-text-secondary">已匹配的事程</h2>
              </>
            ) : (
              <>
                <Link size={16} className="text-accent" />
                <h2 className="text-body-small font-semibold text-text-secondary">创建的事程</h2>
              </>
            )}
          </div>

          <div className="bg-bg-secondary rounded-lg card-shadow p-4">
            <div className="flex items-start gap-3">
              <div className={`w-10 h-10 rounded-lg flex items-center justify-center shrink-0 ${record.status === 'matched' ? 'bg-success-light' : 'bg-accent-light'}`}>
                {record.status === 'matched' ? (
                  <Check size={20} className="text-success" />
                ) : (
                  <Plus size={20} className="text-accent" />
                )}
              </div>
              <div className="flex-1 min-w-0">
                <div className="flex items-center gap-2">
                  <span className="text-time font-mono text-text-secondary">
                    {matchedAgenda.time}
                  </span>
                  <span className={`px-2 py-0.5 rounded-sm text-caption ${record.status === 'matched' ? 'bg-success-light text-success' : 'bg-accent-light text-accent'}`}>
                    {record.status === 'matched' ? matchedAgenda.status : '待办'}
                  </span>
                </div>
                <div className="text-body-small font-medium text-text-primary mt-1.5">
                  {matchedAgenda.content}
                </div>
              </div>
            </div>
          </div>
        </section>
      ) : (
        <section className="px-4 mt-4">
          <div className="px-1 py-2 flex items-center gap-2">
            <Link size={16} className="text-text-tertiary" />
            <h2 className="text-body-small font-semibold text-text-secondary">未匹配到事程</h2>
          </div>
          <div className="bg-bg-secondary rounded-lg card-shadow p-4 text-center">
            <div className="text-body-small text-text-secondary">该记录为独立事件，未关联任何事程</div>
          </div>
        </section>
      )}

      {/* 删除确认弹窗 */}
      {showDeleteConfirm && (
        <div className="fixed inset-0 z-50 flex items-center justify-center px-6">
          <div className="absolute inset-0 bg-black/40" onClick={() => setShowDeleteConfirm(false)} />
          <div className="relative w-full max-w-[300px] bg-bg-secondary rounded-lg overflow-hidden">
            <h2 className="text-title-small font-semibold text-text-primary text-center pt-6 px-5">确认删除？</h2>
            <div className="px-5 py-4">
              <div className="bg-bg-tertiary rounded-md p-3 text-center">
                <div className="text-body-small text-text-primary">{record.content}</div>
                <div className="text-time font-mono text-text-secondary mt-1">{record.time}</div>
              </div>
            </div>
            <div className="flex gap-3 px-5 pb-6">
              <button
                className="flex-1 py-3 bg-danger rounded-md text-white text-body-small font-medium transition-fast active:bg-danger/80"
                onClick={() => navigate(-1)}
              >
                删除
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

      {/* 标签编辑弹窗 */}
      {showTagEditor && (
        <div className="fixed inset-0 z-50 flex items-end justify-center">
          <div className="absolute inset-0 bg-black/40" onClick={() => setShowTagEditor(false)} />
          <div className="relative w-full max-w-[390px] bg-bg-secondary rounded-t-xl px-4 pt-5 pb-6 animate-[pageEnter_250ms_ease-out] max-h-[85vh] overflow-y-auto">
            {/* 顶部拖动条 */}
            <div className="w-10 h-1 bg-bg-tertiary rounded-full mx-auto mb-4" />

            {/* 标题 */}
            <div className="flex items-center justify-between mb-2">
              <div className="flex items-center gap-2">
                <Sparkles size={16} className="text-accent" />
                <h2 className="text-title-small font-semibold text-text-primary">修改标签</h2>
              </div>
              <button
                className="w-6 h-6 flex items-center justify-center text-text-secondary active:opacity-60"
                onClick={() => setShowTagEditor(false)}
              >
                <X size={18} />
              </button>
            </div>

            {/* 提示 */}
            <p className="text-caption text-text-tertiary mb-4">
              选择合适的标签，系统会记住你的偏好，下次同类话语自动应用
            </p>

            {/* 系统标签区 */}
            <div className="mb-3">
              <div className="text-caption text-text-tertiary mb-2 font-medium">系统标签</div>
              <div className="space-y-2">
                {SYSTEM_TAGS.map((t) => {
                  const colorCls = colorClassMap[t.color]
                  const selected = editingTags.includes(t.id)
                  return (
                    <button
                      key={t.id}
                      className={`w-full flex items-center gap-3 p-3 rounded-lg transition-fast active:bg-bg-tertiary ${
                        selected ? `${colorCls.bg} ring-1 ${colorCls.ring}` : 'bg-bg-tertiary'
                      }`}
                      onClick={() => toggleTag(t.id)}
                    >
                      <div className={`w-8 h-8 rounded-md flex items-center justify-center ${colorCls.bg} ${colorCls.color}`}>
                        {systemTagIcon[t.id]}
                      </div>
                      <span className={`flex-1 text-left text-body-small font-medium ${selected ? colorCls.color : 'text-text-primary'}`}>
                        {t.name}
                      </span>
                      {selected && (
                        <Check size={16} className={colorCls.color} />
                      )}
                    </button>
                  )
                })}
              </div>
            </div>

            {/* 自定义标签区 */}
            <div className="mb-3">
              <div className="text-caption text-text-tertiary mb-2 font-medium">我的标签</div>
              {customTags.length === 0 ? (
                <div className="text-caption text-text-tertiary text-center py-3 bg-bg-tertiary rounded-md">
                  暂无自定义标签
                </div>
              ) : (
                <div className="space-y-2">
                  {customTags.map((t) => {
                    const colorCls = colorClassMap[t.color]
                    const selected = editingTags.includes(t.id)
                    const icon = t.icon && t.icon.length <= 2 ? <span className="text-[12px]">{t.icon}</span> : <Hash size={12} />
                    return (
                      <button
                        key={t.id}
                        className={`w-full flex items-center gap-3 p-3 rounded-lg transition-fast active:bg-bg-tertiary ${
                          selected ? `${colorCls.bg} ring-1 ${colorCls.ring}` : 'bg-bg-tertiary'
                        }`}
                        onClick={() => toggleTag(t.id)}
                      >
                        <div className={`w-8 h-8 rounded-md flex items-center justify-center ${colorCls.bg} ${colorCls.color}`}>
                          {icon}
                        </div>
                        <span className={`flex-1 text-left text-body-small font-medium ${selected ? colorCls.color : 'text-text-primary'}`}>
                          {t.name}
                        </span>
                        {selected && (
                          <Check size={16} className={colorCls.color} />
                        )}
                      </button>
                    )
                  })}
                </div>
              )}
            </div>

            {/* 新建标签入口 */}
            <button
              className="w-full flex items-center gap-2 p-3 rounded-lg border border-dashed border-border text-text-secondary active:bg-bg-tertiary transition-fast mb-5"
              onClick={() => setShowCreateTag(true)}
            >
              <Plus size={16} />
              <span className="text-body-small font-medium">新建标签</span>
            </button>

            {/* 操作按钮 */}
            <div className="flex gap-3">
              <button
                className="flex-1 py-3 bg-bg-tertiary rounded-md text-body-small font-medium text-text-secondary active:bg-border transition-fast"
                onClick={() => setShowTagEditor(false)}
              >
                取消
              </button>
              <button
                className="flex-1 py-3 bg-accent rounded-md text-white text-body-small font-medium active:bg-text-primary transition-fast flex items-center justify-center gap-1.5"
                onClick={saveTags}
              >
                <Check size={16} />
                保存并记忆
              </button>
            </div>
          </div>
        </div>
      )}

      {/* 新建标签子弹窗 */}
      {showCreateTag && (
        <div className="fixed inset-0 z-[60] flex items-center justify-center px-6">
          <div className="absolute inset-0 bg-black/50" onClick={() => setShowCreateTag(false)} />
          <div className="relative w-full max-w-[320px] bg-bg-secondary rounded-lg overflow-hidden">
            {/* 标题 */}
            <div className="flex items-center justify-between px-5 pt-5 pb-3">
              <h2 className="text-body font-semibold text-text-primary">新建标签</h2>
              <button
                className="w-6 h-6 flex items-center justify-center text-text-secondary active:opacity-60"
                onClick={() => setShowCreateTag(false)}
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
                  value={newTagName}
                  onChange={(e) => { setNewTagName(e.target.value); setCreateError('') }}
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
                    const selected = newTagColor === c
                    return (
                      <button
                        key={c}
                        className={`w-8 h-8 rounded-full ${colorCls.bg} ${colorCls.color} flex items-center justify-center transition-fast ${
                          selected ? 'ring-2 ring-offset-2 ring-offset-bg-secondary ' + colorCls.ring : ''
                        }`}
                        onClick={() => setNewTagColor(c)}
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
                        newTagIcon === ic ? 'bg-accent-light ring-1 ring-accent' : 'bg-bg-tertiary'
                      }`}
                      onClick={() => setNewTagIcon(ic)}
                    >
                      {ic === '#' ? <Hash size={14} /> : <span>{ic}</span>}
                    </button>
                  ))}
                </div>
              </div>

              {/* 错误提示 */}
              {createError && (
                <div className="text-caption text-danger mb-3">{createError}</div>
              )}

              {/* 操作按钮 */}
              <div className="flex gap-3">
                <button
                  className="flex-1 py-2.5 bg-bg-tertiary rounded-md text-body-small font-medium text-text-secondary active:bg-border transition-fast"
                  onClick={() => setShowCreateTag(false)}
                >
                  取消
                </button>
                <button
                  className="flex-1 py-2.5 bg-accent rounded-md text-white text-body-small font-medium active:bg-text-primary transition-fast"
                  onClick={handleCreateTag}
                >
                  创建
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

export default TimelineDetailPage

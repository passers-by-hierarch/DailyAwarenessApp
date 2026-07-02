import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { ChevronLeft, Search, Clock, MessageCircle, Trash2, Calendar, Filter, Check } from 'lucide-react'

interface ChatItem {
  id: string
  title: string
  preview: string
  date: string
  time: string
  messageCount: number
  category: string
}

const initialChatHistory: ChatItem[] = [
  { id: '1', title: '关于喝水习惯的讨论', preview: '好的，我会帮您设置每天喝水的提醒...', date: '2026-07-01', time: '14:30', messageCount: 12, category: '健康管理' },
  { id: '2', title: '查询明天的日程安排', preview: '明天您有3个事程：早上8点吃药...', date: '2026-06-30', time: '18:45', messageCount: 5, category: '日程查询' },
  { id: '3', title: '添加新的服药提醒', preview: '已为您添加新的服药提醒，每天早上8点...', date: '2026-06-30', time: '09:15', messageCount: 8, category: '提醒设置' },
  { id: '4', title: '询问天气情况', preview: '今天天气晴朗，气温28°C，适合户外活动...', date: '2026-06-29', time: '08:00', messageCount: 3, category: '日常咨询' },
  { id: '5', title: '调整锻炼计划', preview: '已根据您的要求调整了锻炼计划...', date: '2026-06-28', time: '20:30', messageCount: 15, category: '计划调整' },
  { id: '6', title: '查看本周报告', preview: '本周您完成了87%的事程，表现很好...', date: '2026-06-28', time: '10:00', messageCount: 6, category: '数据查询' },
  { id: '7', title: '物品存放位置记录', preview: '已记录：老花镜放在客厅茶几上...', date: '2026-06-27', time: '16:20', messageCount: 4, category: '物品管理' },
  { id: '8', title: '紧急联系人设置', preview: '已添加新的紧急联系人：女儿小明...', date: '2026-06-26', time: '11:30', messageCount: 7, category: '设置管理' },
]

const categories = [
  { id: 'all', name: '全部' },
  { id: 'health', name: '健康管理' },
  { id: 'schedule', name: '日程查询' },
  { id: 'reminder', name: '提醒设置' },
  { id: 'daily', name: '日常咨询' },
  { id: 'plan', name: '计划调整' },
  { id: 'data', name: '数据查询' },
  { id: 'item', name: '物品管理' },
]

const ChatHistoryPage = () => {
  const navigate = useNavigate()
  const [searchText, setSearchText] = useState('')
  const [selectedCategory, setSelectedCategory] = useState('all')
  const [chatHistory, setChatHistory] = useState<ChatItem[]>(initialChatHistory)

  // 删除确认弹窗状态
  const [deleteConfirmId, setDeleteConfirmId] = useState<string | null>(null)
  const [showClearConfirm, setShowClearConfirm] = useState(false)

  const filteredChats = chatHistory.filter(chat => {
    const matchSearch = searchText === '' || chat.title.includes(searchText) || chat.preview.includes(searchText)
    const matchCategory = selectedCategory === 'all' || chat.category === categories.find(c => c.id === selectedCategory)?.name
    return matchSearch && matchCategory
  })

  const groupedChats = filteredChats.reduce((groups, chat) => {
    const date = chat.date
    if (!groups[date]) groups[date] = []
    groups[date].push(chat)
    return groups
  }, {} as Record<string, ChatItem[]>)

  const formatDate = (dateStr: string) => {
    const today = '2026-07-01'
    const yesterday = '2026-06-30'
    if (dateStr === today) return '今天'
    if (dateStr === yesterday) return '昨天'
    return dateStr
  }

  const deleteChat = (id: string) => {
    setChatHistory(prev => prev.filter(item => item.id !== id))
    setDeleteConfirmId(null)
  }

  const clearAllChats = () => {
    setChatHistory([])
    setShowClearConfirm(false)
  }

  return (
    <div className="page-enter min-h-screen bg-bg-primary pb-24">
      <header className="px-4 py-3 bg-bg-secondary border-b border-border sticky top-0 z-40">
        <div className="flex items-center justify-between mb-3">
          <button className="w-8 h-8 flex items-center justify-center text-text-primary transition-fast active:opacity-60" onClick={() => navigate(-1)}><ChevronLeft size={24} /></button>
          <h1 className="text-body font-semibold text-text-primary">历史对话</h1>
          <button className="text-body-small font-medium text-danger transition-fast active:opacity-60" onClick={() => setShowClearConfirm(true)}>清空</button>
        </div>
        <div className="relative">
          <Search size={18} className="absolute left-3 top-1/2 -translate-y-1/2 text-text-tertiary" />
          <input type="text" placeholder="搜索对话内容..." value={searchText} onChange={(e) => setSearchText(e.target.value)} className="w-full pl-10 pr-4 py-2.5 bg-bg-tertiary rounded-lg text-body-small text-text-primary placeholder-text-tertiary focus:outline-none focus:ring-2 focus:ring-accent/30" />
        </div>
      </header>

      <div className="px-4 py-3 overflow-x-auto">
        <div className="flex gap-2 whitespace-nowrap">
          {categories.map((category) => (
            <button key={category.id} onClick={() => setSelectedCategory(category.id)} className={`px-4 py-2 rounded-full text-caption font-medium transition-fast ${selectedCategory === category.id ? 'bg-accent text-white' : 'bg-bg-secondary text-text-secondary'}`}>{category.name}</button>
          ))}
        </div>
      </div>

      <section className="px-4">
        {Object.keys(groupedChats).length > 0 ? (
          Object.keys(groupedChats).map((date) => (
            <div key={date} className="mb-6">
              <div className="flex items-center gap-2 px-1 py-2">
                <Calendar size={14} className="text-text-tertiary" />
                <span className="text-caption text-text-tertiary">{formatDate(date)}</span>
              </div>
              <div className="space-y-2">
                {groupedChats[date].map((chat) => (
                  <div key={chat.id} onClick={() => navigate(`/chat/${chat.id}`)} className="bg-bg-secondary rounded-lg card-shadow p-4 cursor-pointer transition-fast active:bg-bg-tertiary">
                    <div className="flex items-start justify-between gap-3">
                      <div className="flex-1 min-w-0">
                        <div className="flex items-center gap-2 mb-1.5">
                          <h3 className="text-body-small font-medium text-text-primary truncate">{chat.title}</h3>
                          <span className="px-2 py-0.5 rounded-sm bg-accent-light text-caption text-accent shrink-0">{chat.category}</span>
                        </div>
                        <p className="text-caption text-text-secondary line-clamp-2">{chat.preview}</p>
                      </div>
                      <button onClick={(e) => { e.stopPropagation(); setDeleteConfirmId(chat.id) }} className="p-2 text-text-tertiary hover:text-danger transition-fast shrink-0"><Trash2 size={16} /></button>
                    </div>
                    <div className="flex items-center gap-4 mt-3 pt-3 border-t border-border">
                      <div className="flex items-center gap-1 text-caption text-text-tertiary"><Clock size={12} /><span>{chat.time}</span></div>
                      <div className="flex items-center gap-1 text-caption text-text-tertiary"><MessageCircle size={12} /><span>{chat.messageCount} 条消息</span></div>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          ))
        ) : (
          <div className="py-12 text-center">
            <MessageCircle size={48} className="mx-auto text-text-tertiary mb-4" />
            <div className="text-body text-text-secondary mb-2">暂无对话记录</div>
            <div className="text-caption text-text-tertiary">开始新的对话后，记录将显示在这里</div>
          </div>
        )}
      </section>

      <div className="sticky bottom-0 left-0 right-0 bg-bg-secondary border-t border-border px-4 py-3 z-40 safe-area-bottom">
        <button onClick={() => navigate('/chat')} className="w-full py-3 bg-accent rounded-md text-white text-body-small font-medium transition-fast active:bg-text-primary button-shadow flex items-center justify-center gap-2">
          <MessageCircle size={18} />
          开始新对话
        </button>
      </div>

      {/* 删除单条确认弹窗 */}
      {deleteConfirmId && (
        <div className="fixed inset-0 z-50 flex items-center justify-center px-6">
          <div className="absolute inset-0 bg-black/40" onClick={() => setDeleteConfirmId(null)} />
          <div className="relative w-full max-w-[300px] bg-bg-secondary rounded-lg overflow-hidden">
            <h2 className="text-title-small font-semibold text-text-primary text-center pt-6 px-5">确认删除？</h2>
            <div className="px-5 py-4">
              <div className="bg-bg-tertiary rounded-md p-3 text-center">
                <div className="text-body-small font-medium text-text-primary">删除后将无法恢复该对话</div>
              </div>
            </div>
            <div className="flex gap-3 px-5 pb-6">
              <button className="flex-1 py-3 bg-danger rounded-md text-white text-body-small font-medium transition-fast active:bg-danger/80" onClick={() => deleteChat(deleteConfirmId!)}>删除</button>
              <button className="flex-1 py-3 bg-bg-tertiary rounded-md text-text-secondary text-body-small font-medium transition-fast active:bg-border" onClick={() => setDeleteConfirmId(null)}>取消</button>
            </div>
          </div>
        </div>
      )}

      {/* 清空全部确认弹窗 */}
      {showClearConfirm && (
        <div className="fixed inset-0 z-50 flex items-center justify-center px-6">
          <div className="absolute inset-0 bg-black/40" onClick={() => setShowClearConfirm(false)} />
          <div className="relative w-full max-w-[300px] bg-bg-secondary rounded-lg overflow-hidden">
            <h2 className="text-title-small font-semibold text-text-primary text-center pt-6 px-5">确认清空？</h2>
            <div className="px-5 py-4">
              <div className="bg-bg-tertiary rounded-md p-3 text-center">
                <div className="text-body-small font-medium text-text-primary">将删除所有历史对话记录，此操作不可恢复</div>
              </div>
            </div>
            <div className="flex gap-3 px-5 pb-6">
              <button className="flex-1 py-3 bg-danger rounded-md text-white text-body-small font-medium transition-fast active:bg-danger/80" onClick={clearAllChats}>清空全部</button>
              <button className="flex-1 py-3 bg-bg-tertiary rounded-md text-text-secondary text-body-small font-medium transition-fast active:bg-border" onClick={() => setShowClearConfirm(false)}>取消</button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

export default ChatHistoryPage

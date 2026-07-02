import { useState, useRef, useEffect } from 'react'
import { Mic, History, Send } from 'lucide-react'
import { useNavigate } from 'react-router-dom'
import { mockChatMessages, mockQuickQuestions } from '../data/mockData'

interface ChatMessage {
  id: string
  role: 'user' | 'assistant'
  content: string
  timestamp: string
  source?: string
}

const AskPage = () => {
  const navigate = useNavigate()
  const [inputText, setInputText] = useState('')
  const [messages, setMessages] = useState<ChatMessage[]>(mockChatMessages)
  const [isLoading, setIsLoading] = useState(false)
  const [isRecording, setIsRecording] = useState(false)
  const messagesEndRef = useRef<HTMLDivElement>(null)
  const voiceTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null)

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' })
  }

  useEffect(() => {
    scrollToBottom()
  }, [messages])

  const getNowTime = () => {
    const now = new Date()
    return `${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}`
  }

  const generateReply = (question: string): string => {
    if (question.includes('吃药') || question.includes('服药')) {
      return '好的，我来帮您查看服药提醒。\n\n您今天还有以下药物需要服用：\n• 早上8点：降压药（已完成）\n• 下午3点：维生素（待进行）\n• 晚上9点：安眠药（待进行）\n\n需要我帮您调整提醒时间吗？'
    }
    if (question.includes('天气')) {
      return '今天天气晴朗，气温26°C ~ 32°C，湿度65%。\n\n建议：\n• 适合户外活动\n• 注意防晒补水\n• 早晚温差不大，穿舒适的夏装即可'
    }
    if (question.includes('事程') || question.includes('日程') || question.includes('安排')) {
      return '我来帮您查看今天的事程安排：\n\n📋 今日事程（共5项）\n• 08:00 吃降压药 ✅ 已完成\n• 09:15 早上吃药 ⏰ 待验证\n• 15:00 吃降压药 ⏰ 待进行（必做）\n• 18:00 运动 ⏰ 待验证\n• 21:00 吃安眠药 ⏰ 待进行（必做）\n\n需要我帮您添加新的事程吗？'
    }
    if (question.includes('物品') || question.includes('钥匙') || question.includes('放')) {
      return '我来帮您查找物品位置记录：\n\n🔍 最近记录：\n• 钥匙 — 门口鞋柜上（2小时前）\n• 老花镜 — 客厅茶几上（昨天）\n• 钱包 — 卧室床头柜（3天前）\n\n您想找什么物品？我可以帮您详细查看。'
    }
    return `好的，我收到您的问题了："${question}"\n\n这是一个很好的问题！让我为您解答...\n\n（模拟回复中，实际使用时会接入AI服务）`
  }

  const handleSend = () => {
    if (!inputText.trim() || isLoading) return

    const userMsg: ChatMessage = {
      id: `msg-${Date.now()}`,
      role: 'user',
      content: inputText.trim(),
      timestamp: getNowTime(),
    }

    setMessages(prev => [...prev, userMsg])
    const question = inputText.trim()
    setInputText('')
    setIsLoading(true)

    setTimeout(() => {
      const reply: ChatMessage = {
        id: `msg-${Date.now() + 1}`,
        role: 'assistant',
        content: generateReply(question),
        timestamp: getNowTime(),
      }
      setMessages(prev => [...prev, reply])
      setIsLoading(false)
    }, 1200)
  }

  const handleQuickQuestion = (text: string) => {
    setInputText(text)
  }

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault()
      handleSend()
    }
  }

  // 模拟语音识别的问题
  const voiceSamples = [
    '我的钥匙放在哪里了？',
    '今天吃什么药？',
    '今天天气怎么样？',
    '我今天的日程安排是什么？',
    '昨天我做了什么？',
  ]

  // 语音按钮：点击开始/停止录音
  const handleVoiceToggle = () => {
    if (isRecording) {
      // 停止录音 → 模拟识别 → 直接发送
      if (voiceTimerRef.current) {
        clearTimeout(voiceTimerRef.current)
        voiceTimerRef.current = null
      }
      setIsRecording(false)
      const text = voiceSamples[Math.floor(Math.random() * voiceSamples.length)]
      setInputText(text)
      // 直接发送
      const userMsg: ChatMessage = {
        id: `msg-${Date.now()}`,
        role: 'user',
        content: text,
        timestamp: getNowTime(),
      }
      setMessages(prev => [...prev, userMsg])
      setInputText('')
      setIsLoading(true)
      setTimeout(() => {
        const reply: ChatMessage = {
          id: `msg-${Date.now() + 1}`,
          role: 'assistant',
          content: generateReply(text),
          timestamp: getNowTime(),
        }
        setMessages(prev => [...prev, reply])
        setIsLoading(false)
      }, 1200)
    } else {
      // 开始录音
      setIsRecording(true)
      // 模拟：3秒后自动停止
      voiceTimerRef.current = setTimeout(() => {
        handleVoiceToggle()
      }, 3000)
    }
  }

  return (
    <div className="flex flex-col h-full">
      <header className="px-4 py-4 bg-bg-primary flex justify-between items-center shrink-0">
        <h1 className="text-title-medium font-semibold text-text-primary">问一问</h1>
        <button className="text-body-small font-medium text-info flex items-center gap-1 transition-fast active:opacity-60" onClick={() => navigate('/chat-history')}>
          <History size={16} />
          历史记录
        </button>
      </header>

      <section className="px-4 py-2 bg-bg-primary shrink-0">
        <div className="text-body-small text-text-secondary mb-3">常见问题</div>
        <div className="flex gap-2 overflow-x-auto pb-2">
          {mockQuickQuestions.map((q) => (
            <button key={q.id} className="flex items-center gap-2 px-4 py-2 bg-bg-secondary rounded-md card-shadow transition-fast active:bg-bg-tertiary" onClick={() => handleQuickQuestion(q.text)}>
              <span className="text-lg">{q.icon}</span>
              <span className="text-body-small text-text-primary whitespace-nowrap">{q.text}</span>
            </button>
          ))}
        </div>
      </section>

      <section className="px-4 py-2 flex-1 overflow-y-auto bg-bg-primary">
        {messages.map((message) => (
          <div key={message.id} className={`mb-4 ${message.role === 'user' ? 'flex justify-end' : ''}`}>
            {message.role === 'user' ? (
              <div className="bg-accent text-white rounded-xl px-4 py-3 max-w-[80%]">
                <div className="text-body">{message.content}</div>
                <div className="text-caption text-white/70 mt-1">{message.timestamp}</div>
              </div>
            ) : (
              <div className="bg-bg-secondary rounded-xl px-4 py-3 max-w-[90%] card-shadow">
                <div className="flex items-center gap-2 mb-2">
                  <div className="w-6 h-6 bg-accent-light rounded-full flex items-center justify-center">
                    <span className="text-caption font-semibold text-accent">AI</span>
                  </div>
                  <span className="text-body-small font-medium text-text-secondary">助理</span>
                </div>
                <div className="text-body text-text-primary leading-relaxed whitespace-pre-line">{message.content}</div>
                {message.source && <div className="text-caption text-text-tertiary mt-2">{message.source}</div>}
                <div className="text-caption text-text-tertiary mt-1">{message.timestamp}</div>
              </div>
            )}
          </div>
        ))}
        {isLoading && (
          <div className="mb-4">
            <div className="bg-bg-secondary rounded-xl px-4 py-3 max-w-[90%] card-shadow inline-block">
              <div className="flex items-center gap-2 mb-2">
                <div className="w-6 h-6 bg-accent-light rounded-full flex items-center justify-center">
                  <span className="text-caption font-semibold text-accent">AI</span>
                </div>
                <span className="text-body-small font-medium text-text-secondary">助理</span>
              </div>
              <div className="flex gap-1">
                <div className="w-2 h-2 bg-accent rounded-full animate-bounce" style={{ animationDelay: '0ms' }} />
                <div className="w-2 h-2 bg-accent rounded-full animate-bounce" style={{ animationDelay: '150ms' }} />
                <div className="w-2 h-2 bg-accent rounded-full animate-bounce" style={{ animationDelay: '300ms' }} />
              </div>
            </div>
          </div>
        )}
        <div ref={messagesEndRef} />
      </section>

      <div className="bg-bg-secondary border-t border-border px-4 py-3 shrink-0">
        <div className="bg-bg-tertiary rounded-md px-4 py-3 mb-3 flex items-center gap-3">
          {isRecording ? (
            <div className="flex-1 flex items-center gap-2">
              <div className="flex items-center gap-0.5">
                {[1, 2, 3, 4].map((i) => (
                  <div key={i} className="w-1 bg-accent rounded-full wave-bar" style={{ height: `${8 + (i % 3) * 4}px`, animationDelay: `${i * 0.1}s` }} />
                ))}
              </div>
              <span className="text-body-small text-accent font-medium">正在聆听...点击停止</span>
            </div>
          ) : (
            <input
              type="text"
              placeholder="输入您的问题..."
              value={inputText}
              onChange={(e) => setInputText(e.target.value)}
              onKeyDown={handleKeyDown}
              className="flex-1 text-body text-text-primary bg-transparent outline-none placeholder:text-text-tertiary"
            />
          )}
          {inputText.trim() && (
            <button className="w-8 h-8 bg-accent rounded-full flex items-center justify-center text-white shrink-0 transition-fast active:scale-95" onClick={handleSend} disabled={isLoading}>
              <Send size={16} />
            </button>
          )}
        </div>

        <div className="flex justify-center">
          <button
            className={`w-20 h-12 voice-button-gradient rounded-xl flex items-center justify-center transition-fast active:scale-[0.98] button-shadow ${isRecording ? 'ring-2 ring-white/50' : ''}`}
            onClick={handleVoiceToggle}
          >
            <Mic size={32} className={`text-white ${isRecording ? 'animate-pulse' : ''}`} />
          </button>
        </div>
      </div>
    </div>
  )
}

export default AskPage

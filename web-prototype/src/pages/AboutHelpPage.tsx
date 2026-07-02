import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { ChevronLeft, Info, HelpCircle, MessageCircle, FileText, Shield, Smartphone, ChevronRight, ExternalLink, Mail, Phone, Book, Video, Award, Clock, Send, Check, X } from 'lucide-react'

interface FaqItem {
  id: string
  question: string
  answer: string
  expanded: boolean
}

const initialFaqs: FaqItem[] = [
  { id: '1', question: '如何添加新的事程？', answer: '您可以通过语音输入或手动输入的方式添加新事程。点击主页的"+"按钮，然后说出您想记录的事项即可。', expanded: false },
  { id: '2', question: '提醒为什么不响？', answer: '请检查以下几点：1. 手机是否开启了静音模式；2. 应用是否有通知权限；3. 事程的提醒时间是否设置正确。', expanded: false },
  { id: '3', question: '如何导出我的数据？', answer: '进入"设置-报告导出"页面，选择需要导出的数据类型和时间范围，点击"生成并导出报告"即可。', expanded: false },
  { id: '4', question: 'SOS紧急求助如何使用？', answer: '在紧急情况下，长按主页的SOS按钮3秒，系统将自动向您预设的紧急联系人发送求助信息。', expanded: false },
]

const AboutHelpPage = () => {
  const navigate = useNavigate()
  const [faqs, setFaqs] = useState<FaqItem[]>(initialFaqs)
  const [showFeedback, setShowFeedback] = useState(false)
  const [feedbackSuccess, setFeedbackSuccess] = useState(false)

  // 反馈表单状态
  const [feedbackType, setFeedbackType] = useState('suggest')
  const [feedbackContent, setFeedbackContent] = useState('')
  const [feedbackError, setFeedbackError] = useState('')

  const feedbackTypes = [
    { id: 'suggest', name: '功能建议' },
    { id: 'bug', name: '问题反馈' },
    { id: 'complaint', name: '意见投诉' },
    { id: 'other', name: '其他' },
  ]

  const toggleFaq = (id: string) => {
    setFaqs(prev => prev.map(faq => faq.id === id ? { ...faq, expanded: !faq.expanded } : faq))
  }

  const handleSubmitFeedback = () => {
    if (!feedbackContent.trim()) {
      setFeedbackError('请输入反馈内容')
      return
    }
    setFeedbackError('')
    setShowFeedback(false)
    setTimeout(() => {
      setFeedbackSuccess(true)
      setFeedbackContent('')
      setTimeout(() => setFeedbackSuccess(false), 2000)
    }, 300)
  }

  const SettingItem = ({ icon: Icon, title, desc, onClick, showExternal = false }: { icon: React.ReactNode; title: string; desc?: string; onClick?: () => void; showExternal?: boolean }) => (
    <button onClick={onClick} className="w-full p-4 flex items-center justify-between border-b border-border last:border-0 active:bg-bg-tertiary">
      <div className="flex items-center gap-3">
        <div className="w-8 h-8 bg-accent-light rounded-md flex items-center justify-center text-accent">{Icon}</div>
        <div className="text-left">
          <div className="text-body-small font-medium text-text-primary">{title}</div>
          {desc && <div className="text-caption text-text-tertiary mt-0.5">{desc}</div>}
        </div>
      </div>
      {showExternal ? <ExternalLink size={16} className="text-text-tertiary" /> : <ChevronRight size={16} className="text-text-tertiary" />}
    </button>
  )

  return (
    <div className="page-enter min-h-screen bg-bg-primary pb-8">
      <header className="px-4 py-3 bg-bg-secondary border-b border-border flex items-center justify-between sticky top-0 z-40">
        <button className="w-8 h-8 flex items-center justify-center text-text-primary transition-fast active:opacity-60" onClick={() => navigate(-1)}><ChevronLeft size={24} /></button>
        <h1 className="text-body font-semibold text-text-primary">关于与帮助</h1>
        <button className="text-body-small font-medium text-info transition-fast active:opacity-60" onClick={() => setShowFeedback(true)}>反馈</button>
      </header>

      <section className="px-4 mt-4">
        <div className="bg-bg-secondary rounded-lg card-shadow p-6 text-center">
          <div className="w-20 h-20 bg-accent rounded-2xl mx-auto flex items-center justify-center mb-4"><Clock size={40} className="text-white" /></div>
          <h2 className="text-h3 font-semibold text-text-primary mb-1">日常意识助手</h2>
          <p className="text-body-small text-text-secondary mb-3">版本 1.0.0 (Build 20260701)</p>
          <div className="flex items-center justify-center gap-2 text-caption text-text-tertiary"><Award size={14} className="text-success" /><span>官方认证应用</span></div>
        </div>
      </section>

      <section className="px-4 mt-6">
        <div className="px-1 py-2 flex items-center gap-2">
          <HelpCircle size={16} className="text-accent" />
          <h2 className="text-body-small font-semibold text-text-secondary">快速帮助</h2>
        </div>
        <div className="grid grid-cols-2 gap-3">
          <button className="bg-bg-secondary rounded-lg card-shadow p-4 text-center transition-fast active:bg-bg-tertiary">
            <div className="w-12 h-12 bg-info-light rounded-lg mx-auto flex items-center justify-center mb-3"><Book size={24} className="text-info" /></div>
            <div className="text-body-small font-medium text-text-primary">使用指南</div>
            <div className="text-caption text-text-tertiary mt-1">详细操作说明</div>
          </button>
          <button className="bg-bg-secondary rounded-lg card-shadow p-4 text-center transition-fast active:bg-bg-tertiary">
            <div className="w-12 h-12 bg-success-light rounded-lg mx-auto flex items-center justify-center mb-3"><Video size={24} className="text-success" /></div>
            <div className="text-body-small font-medium text-text-primary">视频教程</div>
            <div className="text-caption text-text-tertiary mt-1">手把手教学</div>
          </button>
        </div>
      </section>

      <section className="px-4 mt-6">
        <div className="px-1 py-2 flex items-center gap-2">
          <MessageCircle size={16} className="text-accent" />
          <h2 className="text-body-small font-semibold text-text-secondary">常见问题</h2>
        </div>
        <div className="bg-bg-secondary rounded-lg card-shadow overflow-hidden">
          {faqs.map((faq, index) => (
            <button key={faq.id} className={`w-full p-4 text-left ${index < faqs.length - 1 ? 'border-b border-border' : ''} active:bg-bg-tertiary`} onClick={() => toggleFaq(faq.id)}>
              <div className="flex items-start gap-3">
                <div className="w-6 h-6 bg-accent-light rounded-md flex items-center justify-center shrink-0 mt-0.5">
                  <span className="text-caption text-accent font-medium">{faq.expanded ? 'A' : 'Q'}</span>
                </div>
                <div className="flex-1">
                  <div className="text-body-small font-medium text-text-primary mb-1">{faq.question}</div>
                  {faq.expanded && <div className="text-caption text-text-secondary leading-relaxed mt-2">{faq.answer}</div>}
                </div>
                <ChevronRight size={16} className={`text-text-tertiary shrink-0 mt-1 transition-transform ${faq.expanded ? 'rotate-90' : ''}`} />
              </div>
            </button>
          ))}
        </div>
      </section>

      <section className="px-4 mt-6">
        <div className="px-1 py-2 flex items-center gap-2">
          <Phone size={16} className="text-accent" />
          <h2 className="text-body-small font-semibold text-text-secondary">联系我们</h2>
        </div>
        <div className="bg-bg-secondary rounded-lg card-shadow overflow-hidden">
          <div className="border-b border-border"><SettingItem icon={<Mail size={16} />} title="发送邮件" desc="support@dailyawareness.app" showExternal /></div>
          <div className="border-b border-border"><SettingItem icon={<MessageCircle size={16} />} title="在线客服" desc="工作日 9:00-18:00" /></div>
          <SettingItem icon={<Phone size={16} />} title="客服热线" desc="400-888-8888" />
        </div>
      </section>

      <section className="px-4 mt-6">
        <div className="px-1 py-2 flex items-center gap-2">
          <FileText size={16} className="text-accent" />
          <h2 className="text-body-small font-semibold text-text-secondary">法律信息</h2>
        </div>
        <div className="bg-bg-secondary rounded-lg card-shadow overflow-hidden">
          <div className="border-b border-border"><SettingItem icon={<Shield size={16} />} title="隐私政策" /></div>
          <div className="border-b border-border"><SettingItem icon={<FileText size={16} />} title="用户协议" /></div>
          <div className="border-b border-border"><SettingItem icon={<Info size={16} />} title="开源许可证" /></div>
          <SettingItem icon={<Smartphone size={16} />} title="应用信息" desc="版本 1.0.0" />
        </div>
      </section>

      <div className="px-4 mt-8 text-center text-caption text-text-tertiary">
        <p>© 2026 日常意识助手团队</p>
        <p className="mt-1">保留所有权利</p>
      </div>

      {/* 反馈弹窗 */}
      {showFeedback && (
        <div className="fixed inset-0 z-50 flex items-end justify-center">
          <div className="absolute inset-0 bg-black/40" onClick={() => setShowFeedback(false)} />
          <div className="relative w-full max-w-[390px] bg-bg-secondary rounded-t-xl px-4 pt-5 pb-6 animate-[pageEnter_250ms_ease-out]">
            <div className="w-10 h-1 bg-bg-tertiary rounded-full mx-auto mb-4" />
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-title-small font-semibold text-text-primary">意见反馈</h2>
              <button className="w-6 h-6 flex items-center justify-center text-text-secondary" onClick={() => setShowFeedback(false)}><X size={18} /></button>
            </div>
            <div className="space-y-3">
              <div>
                <label className="text-caption text-text-secondary block mb-1.5">反馈类型</label>
                <div className="flex flex-wrap gap-2">
                  {feedbackTypes.map((type) => (
                    <button key={type.id} className={`px-3 py-2 rounded-md text-body-small font-medium transition-fast ${feedbackType === type.id ? 'bg-accent-light text-accent ring-1 ring-accent' : 'bg-bg-tertiary text-text-secondary'}`} onClick={() => setFeedbackType(type.id)}>{type.name}</button>
                  ))}
                </div>
              </div>
              <div>
                <label className="text-caption text-text-secondary block mb-1.5">反馈内容</label>
                <textarea value={feedbackContent} onChange={(e) => { setFeedbackContent(e.target.value); setFeedbackError('') }} placeholder="请详细描述您的问题或建议..." className="w-full bg-bg-tertiary rounded-md px-3 py-3 text-body-small text-text-primary outline-none focus:ring-2 focus:ring-accent placeholder:text-text-tertiary resize-none" rows={5} />
              </div>
            </div>
            {feedbackError && <div className="text-caption text-danger mt-3">{feedbackError}</div>}
            <div className="flex gap-3 mt-4">
              <button className="flex-1 py-3 bg-bg-tertiary rounded-md text-body-small font-medium text-text-secondary active:bg-border transition-fast" onClick={() => setShowFeedback(false)}>取消</button>
              <button className="flex-1 py-3 bg-accent rounded-md text-white text-body-small font-medium active:bg-text-primary transition-fast flex items-center justify-center gap-1.5" onClick={handleSubmitFeedback}>
                <Send size={16} />
                提交反馈
              </button>
            </div>
          </div>
        </div>
      )}

      {/* 反馈成功提示 */}
      {feedbackSuccess && (
        <div className="fixed inset-0 z-[60] flex items-center justify-center">
          <div className="bg-success/90 text-white px-6 py-4 rounded-lg flex items-center gap-2">
            <Check size={20} />
            <span className="text-body-small font-medium">反馈提交成功，感谢您的建议</span>
          </div>
        </div>
      )}
    </div>
  )
}

export default AboutHelpPage

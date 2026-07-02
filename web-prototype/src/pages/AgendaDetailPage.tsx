import { useState } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { ChevronLeft, ChevronRight, AlertTriangle, Check, Clock, Bell, MapPin, Cloud, Link } from 'lucide-react'
import { useAppStore } from '../store/appStore'
import CompleteModal from '../components/CompleteModal'
import PostponeModal from '../components/PostponeModal'

const AgendaDetailPage = () => {
  const navigate = useNavigate()
  const { id } = useParams()

  // 从 store 获取事程
  const agenda = useAppStore(s => s.agendaItems.find(a => a.id === id))
  const completeAgenda = useAppStore(s => s.completeAgenda)
  const postponeAgenda = useAppStore(s => s.postponeAgenda)
  const deleteAgenda = useAppStore(s => s.deleteAgenda)

  // 弹窗状态
  const [showComplete, setShowComplete] = useState(false)
  const [showPostpone, setShowPostpone] = useState(false)
  const [showDeleteConfirm, setShowDeleteConfirm] = useState(false)

  // 折叠区状态
  const [reminderOpen, setReminderOpen] = useState(true)
  const [strategyOpen, setStrategyOpen] = useState(true)
  const [conditionOpen, setConditionOpen] = useState(true)

  // 如果事程不存在
  if (!agenda) {
    return (
      <div className="page-enter min-h-screen bg-bg-primary flex flex-col items-center justify-center">
        <div className="text-4xl mb-3">📭</div>
        <div className="text-body text-text-secondary mb-4">事程不存在或已删除</div>
        <button
          className="px-6 py-2.5 bg-accent rounded-md text-white text-body-small font-medium"
          onClick={() => navigate(-1)}
        >
          返回
        </button>
      </div>
    )
  }

  // 提醒方式开关
  const reminderMethods = [
    { name: '通知栏', enabled: true },
    { name: '声音', enabled: true },
    { name: '震动', enabled: true },
    { name: '弹窗', enabled: true },
    { name: '语音', enabled: false },
  ]

  // 必做策略阶段
  const strategyPhases = [
    { name: '预提醒', trigger: '提前10分钟', method: '通知栏 + 声音' },
    { name: '首次提醒', trigger: `到点 ${agenda.time}`, method: '通知栏 + 声音 + 震动' },
    { name: '二次提醒', trigger: '延后5分钟后', method: '弹窗 + 语音播报' },
    { name: '家属通知', trigger: '超时未完成', method: '通知家属（女儿）' },
  ]

  // 条件触发项
  const conditions = [
    { name: '地理位置触发', desc: '到达指定地点时提醒', enabled: false, Icon: MapPin },
    { name: '天气条件触发', desc: '根据天气变化提醒', enabled: false, Icon: Cloud },
    { name: '行为链触发', desc: '某行为完成后提醒', enabled: false, Icon: Link },
  ]

  const statusText = agenda.status === 'completed' ? '已完成' : agenda.status === 'postponed' ? '已推迟' : '待进行'

  // 信息行组件
  const InfoRow = ({ label, value, valueClass = 'text-text-primary' }: { label: string; value: string; valueClass?: string }) => (
    <div className="flex items-center justify-between py-2.5">
      <span className="text-body-small text-text-secondary">{label}</span>
      <span className={`text-body-small font-medium ${valueClass}`}>{value}</span>
    </div>
  )

  // 完成事程
  const handleComplete = () => {
    completeAgenda(agenda.id)
    setShowComplete(false)
    navigate(-1)
  }

  // 推迟事程
  const handlePostpone = (minutes: number) => {
    postponeAgenda(agenda.id, minutes)
    setShowPostpone(false)
    navigate(-1)
  }

  // 删除事程
  const handleDelete = () => {
    deleteAgenda(agenda.id)
    setShowDeleteConfirm(false)
    navigate(-1)
  }

  return (
    <div className="page-enter min-h-screen bg-bg-primary pb-24" data-agenda-id={id ?? ''}>
      {/* 顶部导航栏 */}
      <header className="px-4 py-3 bg-bg-secondary border-b border-border flex items-center justify-between sticky top-0 z-40">
        <button
          className="w-8 h-8 flex items-center justify-center text-text-primary transition-fast active:opacity-60"
          onClick={() => navigate(-1)}
        >
          <ChevronLeft size={24} />
        </button>
        <h1 className="text-body font-semibold text-text-primary">事程详情</h1>
        <div className="flex items-center gap-3">
          <button
            className="text-body-small font-medium text-info transition-fast active:opacity-60"
            onClick={() => navigate(`/agenda/${agenda.id}/edit`)}
          >
            编辑
          </button>
          <button
            className="text-body-small font-medium text-danger transition-fast active:opacity-60"
            onClick={() => setShowDeleteConfirm(true)}
          >
            删除
          </button>
        </div>
      </header>

      {/* 基本信息卡 */}
      <section className="px-4 pt-4">
        <div className="bg-bg-secondary rounded-lg card-shadow p-4">
          {/* 顶部图标 + 时间 + 内容 */}
          <div className="flex items-start gap-3">
            <div className={`w-12 h-12 rounded-lg flex items-center justify-center shrink-0 ${agenda.isMustDo ? 'bg-danger-light' : 'bg-accent-light'}`}>
              {agenda.isMustDo ? (
                <AlertTriangle size={24} className="text-danger" />
              ) : (
                <span className="text-2xl">{agenda.icon || '📋'}</span>
              )}
            </div>

            <div className="flex-1 min-w-0">
              <div className="flex items-center gap-2">
                <span className="text-time font-mono text-text-secondary">{agenda.time}</span>
                <span className={`px-2 py-0.5 rounded-sm text-caption ${
                  agenda.status === 'completed' ? 'bg-success-light text-success' :
                  agenda.status === 'postponed' ? 'bg-warning-light text-warning' :
                  'bg-bg-tertiary text-text-secondary'
                }`}>{statusText}</span>
              </div>
              <div className="text-body font-medium text-text-primary mt-1.5">
                {agenda.content}
                {agenda.isMustDo && <span className="text-caption text-danger font-medium ml-1">(必做)</span>}
              </div>
            </div>
          </div>

          <div className="h-px bg-border my-3" />

          <div className="space-y-0.5">
            <InfoRow label="分类" value={agenda.category || '生活'} />
            <InfoRow label="备注" value={agenda.note || '无'} valueClass="text-text-secondary" />
            <InfoRow
              label="状态"
              value={statusText}
              valueClass={agenda.status === 'completed' ? 'text-success' : agenda.status === 'postponed' ? 'text-warning' : 'text-text-primary'}
            />
            {agenda.remainingTime && <InfoRow label="剩余时间" value={agenda.remainingTime} valueClass="text-warning" />}
          </div>
        </div>
      </section>

      {/* 提醒规则区 */}
      <section className="px-4 mt-4">
        <div className="bg-bg-secondary rounded-lg card-shadow overflow-hidden">
          <button
            className="w-full flex items-center justify-between p-4 transition-fast active:bg-bg-tertiary"
            onClick={() => setReminderOpen(!reminderOpen)}
          >
            <div className="flex items-center gap-2">
              <Bell size={18} className="text-accent" />
              <span className="text-body font-semibold text-text-primary">提醒规则</span>
            </div>
            <ChevronRight size={20} className={`text-text-tertiary transition-fast ${reminderOpen ? 'rotate-90' : ''}`} />
          </button>

          {reminderOpen && (
            <div className="px-4 pb-4">
              <div className="h-px bg-border mb-2" />
              <InfoRow label="提醒级别" value={agenda.isMustDo ? '必做' : '普通'} valueClass={agenda.isMustDo ? 'text-danger' : 'text-text-primary'} />
              <div className="py-2.5">
                <div className="text-body-small text-text-secondary mb-2">提醒方式</div>
                <div className="flex flex-wrap gap-2">
                  {reminderMethods.map((method) => (
                    <div
                      key={method.name}
                      className={`flex items-center gap-1 px-2.5 py-1 rounded-md ${method.enabled ? 'bg-success-light text-success' : 'bg-bg-tertiary text-text-tertiary'}`}
                    >
                      <Check size={12} strokeWidth={3} className={method.enabled ? 'opacity-100' : 'opacity-30'} />
                      <span className="text-caption">{method.name}</span>
                    </div>
                  ))}
                </div>
              </div>
              <InfoRow label="重复间隔" value="5分钟" />
              <InfoRow label="最大次数" value="5次" />
              <InfoRow label="提前提醒" value="10分钟" />
              <InfoRow label="允许延后" value={agenda.isMustDo ? '否' : '是'} valueClass={agenda.isMustDo ? 'text-text-tertiary' : 'text-success'} />
              <InfoRow label="允许跳过" value={agenda.isMustDo ? '否' : '是'} valueClass={agenda.isMustDo ? 'text-text-tertiary' : 'text-success'} />
            </div>
          )}
        </div>
      </section>

      {/* 必做策略区 */}
      {agenda.isMustDo && (
        <section className="px-4 mt-4">
          <div className="bg-bg-secondary rounded-lg card-shadow overflow-hidden">
            <button
              className="w-full flex items-center justify-between p-4 transition-fast active:bg-bg-tertiary"
              onClick={() => setStrategyOpen(!strategyOpen)}
            >
              <div className="flex items-center gap-2">
                <AlertTriangle size={18} className="text-danger" />
                <span className="text-body font-semibold text-text-primary">必做策略</span>
              </div>
              <ChevronRight size={20} className={`text-text-tertiary transition-fast ${strategyOpen ? 'rotate-90' : ''}`} />
            </button>

            {strategyOpen && (
              <div className="px-4 pb-4">
                <div className="h-px bg-border mb-3" />
                <div className="space-y-3">
                  {strategyPhases.map((phase, index) => (
                    <div key={phase.name} className="relative">
                      <div className="bg-bg-tertiary rounded-md p-3 ml-4">
                        <div className="flex items-center gap-2 mb-1.5">
                          <span className="text-body-small font-semibold text-text-primary">阶段{index + 1} · {phase.name}</span>
                        </div>
                        <div className="flex items-center gap-1 text-caption text-text-secondary mb-1">
                          <Clock size={12} /><span>触发：{phase.trigger}</span>
                        </div>
                        <div className="flex items-center gap-1 text-caption text-text-secondary">
                          <Bell size={12} /><span>方式：{phase.method}</span>
                        </div>
                      </div>
                      {index < strategyPhases.length - 1 && <div className="absolute left-1.5 top-3 w-0.5 h-full bg-border" />}
                      <div className="absolute left-0 top-3 w-3 h-3 rounded-full bg-danger border-2 border-bg-secondary" />
                    </div>
                  ))}
                </div>
              </div>
            )}
          </div>
        </section>
      )}

      {/* 条件触发区 */}
      <section className="px-4 mt-4">
        <div className="bg-bg-secondary rounded-lg card-shadow overflow-hidden">
          <button
            className="w-full flex items-center justify-between p-4 transition-fast active:bg-bg-tertiary"
            onClick={() => setConditionOpen(!conditionOpen)}
          >
            <div className="flex items-center gap-2">
              <MapPin size={18} className="text-accent" />
              <span className="text-body font-semibold text-text-primary">条件触发</span>
            </div>
            <ChevronRight size={20} className={`text-text-tertiary transition-fast ${conditionOpen ? 'rotate-90' : ''}`} />
          </button>

          {conditionOpen && (
            <div className="px-4 pb-4">
              <div className="h-px bg-border mb-2" />
              {conditions.map((condition, index) => {
                const Icon = condition.Icon
                return (
                  <div key={condition.name} className={`flex items-center gap-3 py-3 ${index < conditions.length - 1 ? 'border-b border-border' : ''}`}>
                    <div className="w-8 h-8 bg-bg-tertiary rounded-md flex items-center justify-center shrink-0">
                      <Icon size={16} className="text-text-secondary" />
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="text-body-small font-medium text-text-primary">{condition.name}</div>
                      <div className="text-caption text-text-tertiary mt-0.5">{condition.desc}</div>
                    </div>
                    <span className={`text-caption font-medium ${condition.enabled ? 'text-success' : 'text-text-tertiary'}`}>
                      {condition.enabled ? '已开启' : '关闭'}
                    </span>
                  </div>
                )
              })}
            </div>
          )}
        </div>
      </section>

      {/* 底部操作按钮 - 根据状态显示不同操作 */}
      <div className="sticky bottom-0 left-0 right-0 bg-bg-secondary border-t border-border px-4 py-3 flex gap-3 z-40 safe-area-bottom">
        {agenda.status === 'pending' ? (
          <>
            {/* 完成事程 */}
            <button
              className="flex-1 py-3 bg-accent rounded-md text-white text-body-small font-medium transition-fast active:bg-text-primary button-shadow flex items-center justify-center gap-1.5"
              onClick={() => setShowComplete(true)}
            >
              <Check size={16} />
              完成事程
            </button>
            {/* 推迟 */}
            {!agenda.isMustDo && (
              <button
                className="flex-1 py-3 bg-warning-light rounded-md text-warning text-body-small font-medium transition-fast active:bg-warning-light/80 flex items-center justify-center gap-1.5"
                onClick={() => setShowPostpone(true)}
              >
                <Clock size={16} />
                推迟
              </button>
            )}
          </>
        ) : (
          <>
            <button
              className="flex-1 py-3 bg-accent rounded-md text-white text-body-small font-medium transition-fast active:bg-text-primary button-shadow"
              onClick={() => navigate(`/agenda/${agenda.id}/edit`)}
            >
              编辑事程
            </button>
            <button
              className="flex-1 py-3 bg-danger-light rounded-md text-danger text-body-small font-medium transition-fast active:bg-danger-light/80"
              onClick={() => setShowDeleteConfirm(true)}
            >
              删除事程
            </button>
          </>
        )}
      </div>

      {/* 完成确认弹窗 */}
      <CompleteModal
        visible={showComplete}
        onClose={() => setShowComplete(false)}
        onConfirm={handleComplete}
        agendaContent={agenda.content}
        agendaTime={agenda.time}
      />

      {/* 推迟弹窗 */}
      <PostponeModal
        visible={showPostpone}
        onClose={() => setShowPostpone(false)}
        onSelect={handlePostpone}
      />

      {/* 删除确认弹窗（简易） */}
      {showDeleteConfirm && (
        <div className="fixed inset-0 z-50 flex items-center justify-center px-6">
          <div className="absolute inset-0 bg-black/40" onClick={() => setShowDeleteConfirm(false)} />
          <div className="relative w-full max-w-[300px] bg-bg-secondary rounded-lg overflow-hidden">
            <h2 className="text-title-small font-semibold text-text-primary text-center pt-6 px-5">确认删除？</h2>
            <div className="px-5 py-4">
              <div className="bg-bg-tertiary rounded-md p-4 text-center">
                <div className="text-body font-medium text-text-primary">{agenda.content}</div>
                <div className="text-time font-mono text-text-secondary mt-2">{agenda.time}</div>
              </div>
            </div>
            <div className="flex gap-3 px-5 pb-6">
              <button
                className="flex-1 py-3 bg-danger rounded-md text-white text-body-small font-medium transition-fast active:bg-danger/80 flex items-center justify-center gap-1.5"
                onClick={handleDelete}
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
    </div>
  )
}

export default AgendaDetailPage

import { useNavigate } from 'react-router-dom'
import { ChevronLeft, Bell, Clock, AlertCircle, Check, ChevronRight } from 'lucide-react'

// 预设模板 mock 数据
const presetTemplates = [
  {
    id: '1',
    name: '温和提醒',
    desc: '适合日常事项,声音温和',
    level: '普通',
    advanceTime: '10分钟',
    repeatInterval: '15分钟',
    maxTimes: '3次',
    allowDelay: true,
    allowSkip: true,
  },
  {
    id: '2',
    name: '标准提醒',
    desc: '适合重要事项,适度提醒',
    level: '重要',
    advanceTime: '15分钟',
    repeatInterval: '10分钟',
    maxTimes: '5次',
    allowDelay: true,
    allowSkip: false,
  },
  {
    id: '3',
    name: '必做提醒',
    desc: '适合必做事项,多次提醒',
    level: '必做',
    advanceTime: '20分钟',
    repeatInterval: '5分钟',
    maxTimes: '10次',
    allowDelay: false,
    allowSkip: false,
  },
]

// 提醒方式配置
const reminderMethods = [
  { id: '1', name: '通知栏', enabled: true },
  { id: '2', name: '声音', enabled: true },
  { id: '3', name: '震动', enabled: true },
  { id: '4', name: '弹窗', enabled: false },
  { id: '5', name: '语音播报', enabled: false },
]

const ReminderRulesPage = () => {
  const navigate = useNavigate()

  // 信息行组件
  const InfoRow = ({ label, value, valueClass = 'text-text-primary' }: { label: string; value: string; valueClass?: string }) => (
    <div className="flex items-center justify-between py-2.5">
      <span className="text-body-small text-text-secondary">{label}</span>
      <span className={`text-body-small font-medium ${valueClass}`}>{value}</span>
    </div>
  )

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
        <h1 className="text-body font-semibold text-text-primary">全局提醒规则</h1>
        <div className="w-8 h-8" />
      </header>

      {/* 提示区 */}
      <div className="px-4 py-3">
        <div className="bg-info-light rounded-md px-4 py-3 flex items-center gap-2">
          <AlertCircle size={18} className="text-info" />
          <span className="text-body-small text-info">
            此处设置的规则将作为新事程的默认提醒配置
          </span>
        </div>
      </div>

      {/* 默认提醒级别 */}
      <section className="px-4 mt-4">
        <div className="px-1 py-2 flex items-center gap-2">
          <Bell size={16} className="text-accent" />
          <h2 className="text-body-small font-semibold text-text-secondary">默认提醒级别</h2>
        </div>

        <div className="bg-bg-secondary rounded-lg card-shadow overflow-hidden">
          {['普通', '重要', '必做'].map((level, index) => (
            <button
              key={level}
              className={`w-full flex items-center justify-between p-4 transition-fast active:bg-bg-tertiary ${
                index < 2 ? 'border-b border-border' : ''
              } ${level === '重要' ? 'bg-accent-light' : ''}`}
            >
              <div className="flex items-center gap-3">
                <div className={`w-8 h-8 rounded-md flex items-center justify-center ${
                  level === '必做' ? 'bg-danger-light text-danger' :
                  level === '重要' ? 'bg-warning-light text-warning' : 'bg-bg-tertiary text-text-secondary'
                }`}>
                  <Bell size={16} />
                </div>
                <span className="text-body-small font-medium text-text-primary">{level}</span>
              </div>
              {level === '重要' && (
                <Check size={18} className="text-accent" />
              )}
            </button>
          ))}
        </div>
      </section>

      {/* 默认时间设置 */}
      <section className="px-4 mt-4">
        <div className="px-1 py-2 flex items-center gap-2">
          <Clock size={16} className="text-accent" />
          <h2 className="text-body-small font-semibold text-text-secondary">默认时间设置</h2>
        </div>

        <div className="bg-bg-secondary rounded-lg card-shadow p-4">
          <InfoRow label="默认提前时间" value="15分钟" valueClass="text-accent" />
          <InfoRow label="默认重复间隔" value="10分钟" valueClass="text-accent" />
          <InfoRow label="默认最大次数" value="5次" valueClass="text-accent" />
        </div>
      </section>

      {/* 默认提醒方式 */}
      <section className="px-4 mt-4">
        <div className="px-1 py-2 flex items-center gap-2">
          <Bell size={16} className="text-accent" />
          <h2 className="text-body-small font-semibold text-text-secondary">默认提醒方式</h2>
        </div>

        <div className="bg-bg-secondary rounded-lg card-shadow p-4">
          <div className="flex flex-wrap gap-2">
            {reminderMethods.map((method) => (
              <div
                key={method.id}
                className={`flex items-center gap-1 px-3 py-2 rounded-md ${
                  method.enabled
                    ? 'bg-success-light text-success'
                    : 'bg-bg-tertiary text-text-tertiary'
                }`}
              >
                <Check
                  size={14}
                  strokeWidth={3}
                  className={method.enabled ? 'opacity-100' : 'opacity-30'}
                />
                <span className="text-caption">{method.name}</span>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* 默认行为选项 */}
      <section className="px-4 mt-4">
        <div className="px-1 py-2 flex items-center gap-2">
          <Check size={16} className="text-accent" />
          <h2 className="text-body-small font-semibold text-text-secondary">默认行为选项</h2>
        </div>

        <div className="bg-bg-secondary rounded-lg card-shadow overflow-hidden">
          <div className="p-4 border-b border-border">
            <div className="flex items-center justify-between">
              <div>
                <div className="text-body-small font-medium text-text-primary">允许延后</div>
                <div className="text-caption text-text-tertiary mt-1">
                  用户可以推迟提醒
                </div>
              </div>
              <div className="flex items-center gap-2">
                <span className="text-caption text-success font-medium">是</span>
                <ChevronRight size={16} className="text-text-tertiary" />
              </div>
            </div>
          </div>

          <div className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <div className="text-body-small font-medium text-text-primary">允许跳过</div>
                <div className="text-caption text-text-tertiary mt-1">
                  用户可以跳过事程
                </div>
              </div>
              <div className="flex items-center gap-2">
                <span className="text-caption text-text-tertiary font-medium">否</span>
                <ChevronRight size={16} className="text-text-tertiary" />
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* 预设模板 */}
      <section className="px-4 mt-6">
        <div className="px-1 py-2 flex items-center gap-2">
          <AlertCircle size={16} className="text-accent" />
          <h2 className="text-body-small font-semibold text-text-secondary">预设模板一键应用</h2>
        </div>

        <div className="space-y-2.5">
          {presetTemplates.map((template) => (
            <div
              key={template.id}
              className="bg-bg-secondary rounded-lg card-shadow p-4"
            >
              {/* 顶部标题 */}
              <div className="flex items-center justify-between mb-3">
                <div className="flex items-center gap-2">
                  <div className={`w-8 h-8 rounded-md flex items-center justify-center ${
                    template.level === '必做' ? 'bg-danger-light text-danger' :
                    template.level === '重要' ? 'bg-warning-light text-warning' : 'bg-accent-light text-accent'
                  }`}>
                    <Bell size={16} />
                  </div>
                  <div>
                    <div className="text-body-small font-semibold text-text-primary">
                      {template.name}
                    </div>
                    <div className="text-caption text-text-tertiary">
                      {template.desc}
                    </div>
                  </div>
                </div>
                <span className={`px-2 py-0.5 rounded-sm text-caption ${
                  template.level === '必做' ? 'bg-danger-light text-danger' :
                  template.level === '重要' ? 'bg-warning-light text-warning' : 'bg-accent-light text-accent'
                }`}>
                  {template.level}
                </span>
              </div>

              {/* 配置详情 */}
              <div className="grid grid-cols-2 gap-x-4 gap-y-2 mb-3">
                <div className="flex items-center gap-1">
                  <Clock size={12} className="text-text-secondary" />
                  <span className="text-caption text-text-secondary">提前{template.advanceTime}</span>
                </div>
                <div className="flex items-center gap-1">
                  <Clock size={12} className="text-text-secondary" />
                  <span className="text-caption text-text-secondary">间隔{template.repeatInterval}</span>
                </div>
                <div className="flex items-center gap-1">
                  <Bell size={12} className="text-text-secondary" />
                  <span className="text-caption text-text-secondary">最多{template.maxTimes}次</span>
                </div>
                <div className="flex items-center gap-1">
                  <Check size={12} className={template.allowDelay ? 'text-success' : 'text-text-tertiary'} />
                  <span className={`text-caption ${template.allowDelay ? 'text-success' : 'text-text-tertiary'}`}>
                    {template.allowDelay ? '可延后' : '不可延后'}
                  </span>
                </div>
              </div>

              {/* 应用按钮 */}
              <button className="w-full py-2.5 bg-accent-light rounded-md text-accent text-caption font-medium transition-fast active:bg-accent/10">
                应用此模板
              </button>
            </div>
          ))}
        </div>
      </section>
    </div>
  )
}

export default ReminderRulesPage
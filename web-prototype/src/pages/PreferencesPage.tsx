import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { ChevronLeft, Sun, Moon, Type, Volume2, Globe, Palette, Clock, Bell, ChevronRight, Check } from 'lucide-react'

const PreferencesPage = () => {
  const navigate = useNavigate()
  const [preferences, setPreferences] = useState({
    fontSize: 'medium',
    volume: 80,
    theme: 'light',
    language: 'zh-CN',
    timeFormat: '24h',
    dateFormat: 'YYYY-MM-DD',
    startPage: 'today',
  })

  // 字体大小选项
  const fontSizes = [
    { id: 'small', name: '小', desc: '适合视力较好的用户' },
    { id: 'medium', name: '中', desc: '默认推荐' },
    { id: 'large', name: '大', desc: '适合阅读困难的用户' },
    { id: 'xlarge', name: '特大', desc: '最大字体显示' },
  ]

  // 主题选项
  const themes = [
    { id: 'light', name: '浅色模式', icon: Sun },
    { id: 'dark', name: '深色模式', icon: Moon },
    { id: 'auto', name: '跟随系统', icon: Palette },
  ]

  // 语言选项
  const languages = [
    { id: 'zh-CN', name: '简体中文' },
    { id: 'zh-TW', name: '繁體中文' },
    { id: 'en', name: 'English' },
  ]

  // 设置项组件
  const SettingItem = ({
    icon: Icon,
    title,
    value,
    onClick,
  }: {
    icon: React.ReactNode
    title: string
    value: string
    onClick?: () => void
  }) => (
    <button
      onClick={onClick}
      className="w-full p-4 flex items-center justify-between border-b border-border last:border-0 active:bg-bg-tertiary"
    >
      <div className="flex items-center gap-3">
        <div className="w-8 h-8 bg-accent-light rounded-md flex items-center justify-center text-accent">
          {Icon}
        </div>
        <span className="text-body-small font-medium text-text-primary">{title}</span>
      </div>
      <div className="flex items-center gap-2">
        <span className="text-caption text-text-secondary">{value}</span>
        <ChevronRight size={16} className="text-text-tertiary" />
      </div>
    </button>
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
        <h1 className="text-body font-semibold text-text-primary">偏好设置</h1>
        <div className="w-8 h-8" />
      </header>

      {/* 显示设置 */}
      <section className="px-4 mt-4">
        <div className="px-1 py-2 flex items-center gap-2">
          <Sun size={16} className="text-accent" />
          <h2 className="text-body-small font-semibold text-text-secondary">显示设置</h2>
        </div>

        {/* 主题选择 */}
        <div className="bg-bg-secondary rounded-lg card-shadow p-4 mb-3">
          <div className="text-body-small font-medium text-text-primary mb-3">主题模式</div>
          <div className="grid grid-cols-3 gap-2">
            {themes.map((theme) => {
              const IconComponent = theme.icon
              return (
                <button
                  key={theme.id}
                  onClick={() => setPreferences(prev => ({ ...prev, theme: theme.id }))}
                  className={`p-3 rounded-lg transition-fast ${
                    preferences.theme === theme.id
                      ? 'bg-accent-light border-2 border-accent'
                      : 'bg-bg-tertiary border-2 border-transparent'
                  }`}
                >
                  <IconComponent
                    size={24}
                    className={preferences.theme === theme.id ? 'text-accent' : 'text-text-secondary'}
                  />
                  <div className={`text-caption mt-2 ${
                    preferences.theme === theme.id ? 'text-accent font-medium' : 'text-text-primary'
                  }`}>
                    {theme.name}
                  </div>
                </button>
              )
            })}
          </div>
        </div>

        {/* 字体大小 */}
        <div className="bg-bg-secondary rounded-lg card-shadow p-4">
          <div className="text-body-small font-medium text-text-primary mb-3">字体大小</div>
          <div className="space-y-2">
            {fontSizes.map((size) => (
              <button
                key={size.id}
                onClick={() => setPreferences(prev => ({ ...prev, fontSize: size.id }))}
                className={`w-full p-3 rounded-lg flex items-center justify-between transition-fast ${
                  preferences.fontSize === size.id
                    ? 'bg-accent-light border-2 border-accent'
                    : 'bg-bg-tertiary'
                }`}
              >
                <div>
                  <div className={`text-body-small ${
                    preferences.fontSize === size.id ? 'text-accent font-medium' : 'text-text-primary'
                  }`}>
                    {size.name}
                  </div>
                  <div className="text-caption text-text-tertiary mt-0.5">{size.desc}</div>
                </div>
                {preferences.fontSize === size.id && <Check size={18} className="text-accent" />}
              </button>
            ))}
          </div>
        </div>
      </section>

      {/* 声音设置 */}
      <section className="px-4 mt-6">
        <div className="px-1 py-2 flex items-center gap-2">
          <Volume2 size={16} className="text-accent" />
          <h2 className="text-body-small font-semibold text-text-secondary">声音设置</h2>
        </div>

        <div className="bg-bg-secondary rounded-lg card-shadow p-4">
          <div className="flex items-center justify-between mb-3">
            <div className="flex items-center gap-2">
              <Volume2 size={14} className="text-text-secondary" />
              <span className="text-body-small text-text-primary">提醒音量</span>
            </div>
            <span className="text-caption text-accent font-medium">{preferences.volume}%</span>
          </div>
          <input
            type="range"
            min="0"
            max="100"
            value={preferences.volume}
            onChange={(e) => setPreferences(prev => ({ ...prev, volume: parseInt(e.target.value) }))}
            className="w-full h-2 bg-bg-tertiary rounded-lg appearance-none cursor-pointer accent-accent"
          />
          <div className="flex justify-between mt-2 text-caption text-text-tertiary">
            <span>静音</span>
            <span>最大</span>
          </div>
        </div>
      </section>

      {/* 语言与地区 */}
      <section className="px-4 mt-6">
        <div className="px-1 py-2 flex items-center gap-2">
          <Globe size={16} className="text-accent" />
          <h2 className="text-body-small font-semibold text-text-secondary">语言与地区</h2>
        </div>

        <div className="bg-bg-secondary rounded-lg card-shadow overflow-hidden">
          <div className="border-b border-border">
            <SettingItem
              icon={<Type size={16} />}
              title="语言"
              value={languages.find(l => l.id === preferences.language)?.name || ''}
            />
          </div>
          <div className="border-b border-border">
            <SettingItem
              icon={<Clock size={16} />}
              title="时间格式"
              value={preferences.timeFormat === '24h' ? '24小时制' : '12小时制'}
            />
          </div>
          <SettingItem
            icon={<Bell size={16} />}
            title="日期格式"
            value={preferences.dateFormat}
          />
        </div>
      </section>

      {/* 提醒偏好 */}
      <section className="px-4 mt-6">
        <div className="px-1 py-2 flex items-center gap-2">
          <Bell size={16} className="text-accent" />
          <h2 className="text-body-small font-semibold text-text-secondary">提醒偏好</h2>
        </div>

        <div className="bg-bg-secondary rounded-lg card-shadow overflow-hidden">
          <div className="border-b border-border">
            <SettingItem
              icon={<Bell size={16} />}
              title="默认提前时间"
              value="15分钟"
            />
          </div>
          <div className="border-b border-border">
            <SettingItem
              icon={<Clock size={16} />}
              title="重复提醒间隔"
              value="10分钟"
            />
          </div>
          <SettingItem
            icon={<Volume2 size={16} />}
            title="提醒铃声"
            value="默认铃声"
          />
        </div>
      </section>

      {/* 起始页设置 */}
      <section className="px-4 mt-6">
        <div className="px-1 py-2 flex items-center gap-2">
          <Palette size={16} className="text-accent" />
          <h2 className="text-body-small font-semibold text-text-secondary">起始页设置</h2>
        </div>

        <div className="bg-bg-secondary rounded-lg card-shadow p-4">
          <div className="text-body-small font-medium text-text-primary mb-3">打开应用后显示</div>
          <div className="space-y-2">
            {[
              { id: 'today', name: '今日概览' },
              { id: 'agenda', name: '事程列表' },
              { id: 'timeline', name: '时间线' },
            ].map((page) => (
              <button
                key={page.id}
                onClick={() => setPreferences(prev => ({ ...prev, startPage: page.id }))}
                className={`w-full p-3 rounded-lg flex items-center justify-between transition-fast ${
                  preferences.startPage === page.id
                    ? 'bg-accent-light border-2 border-accent'
                    : 'bg-bg-tertiary'
                }`}
              >
                <span className={`text-body-small ${
                  preferences.startPage === page.id ? 'text-accent font-medium' : 'text-text-primary'
                }`}>
                  {page.name}
                </span>
                {preferences.startPage === page.id && <Check size={18} className="text-accent" />}
              </button>
            ))}
          </div>
        </div>
      </section>
    </div>
  )
}

export default PreferencesPage
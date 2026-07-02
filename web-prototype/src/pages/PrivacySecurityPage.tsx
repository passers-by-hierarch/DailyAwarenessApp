import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { ChevronLeft, Shield, Lock, Eye, Fingerprint, Smartphone, Key, Bell, ChevronRight, AlertTriangle, Check } from 'lucide-react'

const PrivacySecurityPage = () => {
  const navigate = useNavigate()
  const [settings, setSettings] = useState({
    biometric: true,
    autoLock: true,
    dataEncryption: true,
    anonymousMode: false,
    locationShare: true,
    analyticsShare: false,
  })

  // 切换设置
  const toggleSetting = (key: keyof typeof settings) => {
    setSettings(prev => ({ ...prev, [key]: !prev[key] }))
  }

  // 设置项组件
  const SettingItem = ({
    icon: Icon,
    title,
    desc,
    value,
    onChange,
    showArrow = false,
    danger = false,
  }: {
    icon: React.ReactNode
    title: string
    desc: string
    value?: boolean
    onChange?: () => void
    showArrow?: boolean
    danger?: boolean
  }) => (
    <div className={`p-4 ${showArrow ? 'cursor-pointer active:bg-bg-tertiary' : ''}`}>
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className={`w-8 h-8 rounded-md flex items-center justify-center ${
            danger ? 'bg-danger-light text-danger' : 'bg-accent-light text-accent'
          }`}>
            {Icon}
          </div>
          <div>
            <div className={`text-body-small font-medium ${danger ? 'text-danger' : 'text-text-primary'}`}>{title}</div>
            <div className="text-caption text-text-tertiary mt-0.5">{desc}</div>
          </div>
        </div>
        {typeof value === 'boolean' && onChange ? (
          <button
            onClick={onChange}
            className={`relative w-11 h-6 rounded-full transition-fast ${
              value ? 'bg-success' : 'bg-bg-tertiary'
            }`}
          >
            <div
              className={`absolute top-0.5 w-5 h-5 bg-white rounded-full shadow-sm transition-fast ${
                value ? 'left-[22px]' : 'left-0.5'
              }`}
            />
          </button>
        ) : showArrow ? (
          <ChevronRight size={20} className="text-text-tertiary" />
        ) : null}
      </div>
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
        <h1 className="text-body font-semibold text-text-primary">隐私与安全</h1>
        <div className="w-8 h-8" />
      </header>

      {/* 安全状态 */}
      <div className="px-4 py-4">
        <div className="bg-success-light rounded-lg p-4 flex items-center gap-3">
          <div className="w-12 h-12 bg-success rounded-full flex items-center justify-center">
            <Shield size={24} className="text-white" />
          </div>
          <div className="flex-1">
            <div className="text-body font-semibold text-success">安全状态良好</div>
            <div className="text-body-small text-success/80 mt-1">所有安全设置已启用</div>
          </div>
          <Check size={24} className="text-success" />
        </div>
      </div>

      {/* 生物识别与锁定 */}
      <section className="px-4 mt-2">
        <div className="px-1 py-2 flex items-center gap-2">
          <Fingerprint size={16} className="text-accent" />
          <h2 className="text-body-small font-semibold text-text-secondary">生物识别与锁定</h2>
        </div>

        <div className="bg-bg-secondary rounded-lg card-shadow overflow-hidden">
          <div className="border-b border-border">
            <SettingItem
              icon={<Fingerprint size={16} />}
              title="生物识别解锁"
              desc="使用指纹或面容解锁应用"
              value={settings.biometric}
              onChange={() => toggleSetting('biometric')}
            />
          </div>
          <div className="border-b border-border">
            <SettingItem
              icon={<Lock size={16} />}
              title="自动锁定"
              desc="离开应用后自动锁定"
              value={settings.autoLock}
              onChange={() => toggleSetting('autoLock')}
            />
          </div>
          <SettingItem
            icon={<Key size={16} />}
            title="修改密码"
            desc="设置或更改应用访问密码"
            showArrow
          />
        </div>
      </section>

      {/* 数据保护 */}
      <section className="px-4 mt-6">
        <div className="px-1 py-2 flex items-center gap-2">
          <Shield size={16} className="text-accent" />
          <h2 className="text-body-small font-semibold text-text-secondary">数据保护</h2>
        </div>

        <div className="bg-bg-secondary rounded-lg card-shadow overflow-hidden">
          <div className="border-b border-border">
            <SettingItem
              icon={<Lock size={16} />}
              title="数据加密"
              desc="本地数据采用AES-256加密"
              value={settings.dataEncryption}
              onChange={() => toggleSetting('dataEncryption')}
            />
          </div>
          <div className="border-b border-border">
            <SettingItem
              icon={<Eye size={16} />}
              title="匿名模式"
              desc="隐藏敏感信息显示"
              value={settings.anonymousMode}
              onChange={() => toggleSetting('anonymousMode')}
            />
          </div>
          <div className="border-b border-border">
            <SettingItem
              icon={<Smartphone size={16} />}
              title="数据备份"
              desc="云端加密备份您的数据"
              showArrow
            />
          </div>
          <SettingItem
            icon={<AlertTriangle size={16} />}
            title="清除所有数据"
            desc="删除所有本地和云端数据"
            showArrow
            danger
          />
        </div>
      </section>

      {/* 隐私设置 */}
      <section className="px-4 mt-6">
        <div className="px-1 py-2 flex items-center gap-2">
          <Eye size={16} className="text-accent" />
          <h2 className="text-body-small font-semibold text-text-secondary">隐私设置</h2>
        </div>

        <div className="bg-bg-secondary rounded-lg card-shadow overflow-hidden">
          <div className="border-b border-border">
            <SettingItem
              icon={<Smartphone size={16} />}
              title="位置信息共享"
              desc="允许应用获取位置信息"
              value={settings.locationShare}
              onChange={() => toggleSetting('locationShare')}
            />
          </div>
          <div className="border-b border-border">
            <SettingItem
              icon={<Bell size={16} />}
              title="使用分析共享"
              desc="帮助我们改进产品"
              value={settings.analyticsShare}
              onChange={() => toggleSetting('analyticsShare')}
            />
          </div>
          <SettingItem
            icon={<Shield size={16} />}
            title="隐私政策"
            desc="查看完整的隐私政策文档"
            showArrow
          />
        </div>
      </section>

      {/* 安全日志 */}
      <section className="px-4 mt-6">
        <div className="px-1 py-2 flex items-center gap-2">
          <AlertTriangle size={16} className="text-accent" />
          <h2 className="text-body-small font-semibold text-text-secondary">安全日志</h2>
        </div>

        <div className="bg-bg-secondary rounded-lg card-shadow p-4">
          <div className="space-y-3">
            <div className="flex items-start gap-3">
              <div className="w-2 h-2 rounded-full bg-success mt-1.5" />
              <div className="flex-1">
                <div className="text-body-small text-text-primary">成功登录</div>
                <div className="text-caption text-text-tertiary">今天 09:30 · 北京 · iPhone 14</div>
              </div>
            </div>
            <div className="flex items-start gap-3">
              <div className="w-2 h-2 rounded-full bg-success mt-1.5" />
              <div className="flex-1">
                <div className="text-body-small text-text-primary">密码修改成功</div>
                <div className="text-caption text-text-tertiary">昨天 15:20 · 北京 · iPhone 14</div>
              </div>
            </div>
            <div className="flex items-start gap-3">
              <div className="w-2 h-2 rounded-full bg-warning mt-1.5" />
              <div className="flex-1">
                <div className="text-body-small text-text-primary">登录尝试失败</div>
                <div className="text-caption text-text-tertiary">2026/06/28 22:15 · 上海 · 未知设备</div>
              </div>
            </div>
          </div>

          <button className="w-full mt-4 py-2 text-accent text-caption font-medium">
            查看全部日志
          </button>
        </div>
      </section>
    </div>
  )
}

export default PrivacySecurityPage
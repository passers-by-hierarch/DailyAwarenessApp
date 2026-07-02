import { useNavigate } from 'react-router-dom'
import { ChevronRight } from 'lucide-react'
import { mockMenuItems } from '../data/mockData'

const ProfilePage = () => {
  const navigate = useNavigate()
  
  // 功能项跳转映射
  const getItemPath = (itemId: string): string | null => {
    switch (itemId) {
      case '1': return '/items'
      case '2': return '/shopping'
      case '3': return '/family'
      case '4': return '/emergency-settings'
      case '5': return '/reminder-rules'
      case '6': return '/quiet-hours'
      case '7': return '/report-export'
      case '8': return '/health-devices'
      case '9': return '/privacy-security'
      case '10': return '/preferences'
      case '11': return '/about-help'
      default: return null
    }
  }
  
  return (
    <div className="page-enter">
      {/* 用户信息卡 */}
      <section className="px-4 pt-4">
        <div className="bg-bg-secondary rounded-lg card-shadow p-5">
          {/* 头像 + 昵称 */}
          <div className="flex items-center gap-4">
            <div className="w-16 h-16 bg-accent-light rounded-full flex items-center justify-center">
              <span className="text-2xl">👤</span>
            </div>
            <div>
              <h2 className="text-title-small font-semibold text-text-primary">用户昵称</h2>
              <p className="text-body-small text-accent mt-1">已连续使用 128 天</p>
            </div>
          </div>
        </div>
      </section>
      
      {/* 功能分组 */}
      {mockMenuItems.map((group) => (
        <section key={group.group} className="mt-6">
          {/* 分组标题 */}
          <div className="px-4 py-2">
            <h3 className="text-caption font-semibold text-text-tertiary">{group.group}</h3>
          </div>
          
          {/* 功能项列表 */}
          <div className="px-4 bg-bg-secondary rounded-lg card-shadow">
            {group.items.map((item, index) => {
              const path = getItemPath(item.id)
              return (
                <button
                  key={item.id}
                  className={`w-full flex items-center py-4 px-4 transition-fast active:bg-bg-tertiary ${
                    index < group.items.length - 1 ? 'border-b border-divider' : ''
                  }`}
                  onClick={() => path && navigate(path)}
                >
                  {/* 图标 */}
                  <span className="text-xl mr-3">{item.icon}</span>
                  
                  {/* 文字 */}
                  <div className="flex-1 text-left">
                    <div className="text-body text-text-primary">{item.text}</div>
                    {item.subtext && (
                      <div className="text-caption text-text-tertiary mt-0.5">{item.subtext}</div>
                    )}
                  </div>
                  
                  {/* 箭头 */}
                  <ChevronRight size={20} className="text-text-tertiary" />
                </button>
              )
            })}
          </div>
        </section>
      ))}
      
      {/* 底部留白 */}
      <div className="h-8" />
    </div>
  )
}

export default ProfilePage
import { useNavigate, useLocation } from 'react-router-dom'
import { Home, TrendingUp, MessageCircle, User } from 'lucide-react'
import { useAppStore } from '../store/appStore'

const BottomNav = () => {
  const navigate = useNavigate()
  const location = useLocation()
  const { setActiveTab } = useAppStore()
  
  const tabs = [
    { id: 'home', path: '/', icon: Home, label: '首页' },
    { id: 'ask', path: '/ask', icon: MessageCircle, label: '问一问' },
    { id: 'habits', path: '/habits', icon: TrendingUp, label: '习惯' },
    { id: 'profile', path: '/profile', icon: User, label: '我的' },
  ]
  
  const handleTabClick = (tab: typeof tabs[0]) => {
    setActiveTab(tab.id as 'home' | 'habits' | 'ask' | 'profile')
    navigate(tab.path)
  }
  
  const isActive = (path: string) => location.pathname === path
  
  return (
    <nav className="bg-bg-secondary border-t border-border shrink-0">
      <div className="flex justify-around items-center h-14 px-2">
        {tabs.map((tab) => {
          const Icon = tab.icon
          const active = isActive(tab.path)
          
          return (
            <button
              key={tab.id}
              onClick={() => handleTabClick(tab)}
              className={`flex flex-col items-center justify-center py-1.5 px-2 transition-fast ${
                active ? 'text-accent' : 'text-text-tertiary'
              }`}
            >
              <Icon 
                size={22} 
                strokeWidth={active ? 2.5 : 2}
                className={active ? 'scale-110' : ''}
              />
              <span className={`text-[10px] mt-0.5 ${active ? 'font-semibold' : ''}`}>
                {tab.label}
              </span>
            </button>
          )
        })}
      </div>
    </nav>
  )
}

export default BottomNav
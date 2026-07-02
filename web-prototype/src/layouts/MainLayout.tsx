import { Outlet, useLocation, useNavigate } from 'react-router-dom'
import { useState } from 'react'
import PhoneFrame from '../components/PhoneFrame'
import BottomNav from '../components/BottomNav'
import VoiceButton from '../components/VoiceButton'
import QuickActions from '../components/QuickActions'
import CreateAgendaModal from '../components/CreateAgendaModal'

const MainLayout = () => {
  const location = useLocation()
  const navigate = useNavigate()
  const isHomePage = location.pathname === '/'
  const [showCreateModal, setShowCreateModal] = useState(false)

  return (
    <PhoneFrame>
      {/* 页面内容 - 可滚动 */}
      <div className="flex-1 overflow-y-auto bg-bg-primary">
        <Outlet />
      </div>

      {/* 首页悬浮区域：快捷操作 + 语音按钮（不占用内容流空间） */}
      {isHomePage && (
        <div className="bg-bg-secondary border-t border-border shrink-0">
          <QuickActions onCreateAgenda={() => setShowCreateModal(true)} />
          <VoiceButton />
          <CreateAgendaModal
            visible={showCreateModal}
            onClose={() => setShowCreateModal(false)}
            onSelect={(type) => {
              setShowCreateModal(false)
              if (type === 'frequent') navigate('/frequent-agenda')
              else if (type === 'voice' || type === 'text') navigate('/create-agenda')
            }}
          />
        </div>
      )}

      {/* 底部导航栏 */}
      <BottomNav />
    </PhoneFrame>
  )
}

export default MainLayout
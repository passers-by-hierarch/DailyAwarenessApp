import { Outlet, useLocation } from 'react-router-dom'
import PhoneFrame from '../components/PhoneFrame'
import BottomNav from '../components/BottomNav'
import VoiceButton from '../components/VoiceButton'

const MainLayout = () => {
  const location = useLocation()
  const isHomePage = location.pathname === '/'

  return (
    <PhoneFrame>
      <div className="flex-1 overflow-y-auto bg-bg-primary">
        <Outlet />
      </div>

      {isHomePage && (
        <div className="bg-bg-secondary border-t border-border shrink-0">
          <VoiceButton />
        </div>
      )}

      <BottomNav />
    </PhoneFrame>
  )
}

export default MainLayout
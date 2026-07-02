import { BrowserRouter, Routes, Route } from 'react-router-dom'
import MainLayout from './layouts/MainLayout'
import SecondaryLayout from './layouts/SecondaryLayout'
import HomePage from './pages/HomePage'
import HabitsPage from './pages/HabitsPage'
import AskPage from './pages/AskPage'
import ProfilePage from './pages/ProfilePage'
import AgendaDetailPage from './pages/AgendaDetailPage'
import FrequentAgendaPage from './pages/FrequentAgendaPage'
import ItemsPage from './pages/ItemsPage'
import FamilyPage from './pages/FamilyPage'
import ShoppingPage from './pages/ShoppingPage'
import EmergencySettingsPage from './pages/EmergencySettingsPage'
import ReminderRulesPage from './pages/ReminderRulesPage'
import QuietHoursPage from './pages/QuietHoursPage'
import ReportExportPage from './pages/ReportExportPage'
import HealthDevicesPage from './pages/HealthDevicesPage'
import PrivacySecurityPage from './pages/PrivacySecurityPage'
import PreferencesPage from './pages/PreferencesPage'
import AboutHelpPage from './pages/AboutHelpPage'
import ItemDetailPage from './pages/ItemDetailPage'
import WeeklyReportPage from './pages/WeeklyReportPage'
import BehaviorAnalysisPage from './pages/BehaviorAnalysisPage'
import ChatHistoryPage from './pages/ChatHistoryPage'
import TimelineDetailPage from './pages/TimelineDetailPage'
import EditAgendaPage from './pages/EditAgendaPage'
import TagManagementPage from './pages/TagManagementPage'

function App() {
  return (
    <BrowserRouter>
      <Routes>
        {/* 主Tab页面（带底部导航栏） */}
        <Route path="/" element={<MainLayout />}>
          <Route index element={<HomePage />} />
          <Route path="habits" element={<HabitsPage />} />
          <Route path="ask" element={<AskPage />} />
          <Route path="profile" element={<ProfilePage />} />
        </Route>
        {/* 二级页面（有手机外壳，无底部导航栏） */}
        <Route element={<SecondaryLayout />}>
          {/* 事程相关 */}
          <Route path="/agenda/:id" element={<AgendaDetailPage />} />
          <Route path="/agenda/:id/edit" element={<EditAgendaPage />} />
          <Route path="/frequent-agenda" element={<FrequentAgendaPage />} />
          <Route path="/create-agenda" element={<EditAgendaPage />} />
          
          {/* 时间线相关 */}
          <Route path="/timeline/:id" element={<TimelineDetailPage />} />
          
          {/* 物品管理相关 */}
          <Route path="/items" element={<ItemsPage />} />
          <Route path="/items/:id" element={<ItemDetailPage />} />

          {/* 购物记录相关 */}
          <Route path="/shopping" element={<ShoppingPage />} />

          {/* 我的页面相关 */}
          <Route path="/family" element={<FamilyPage />} />
          <Route path="/emergency-settings" element={<EmergencySettingsPage />} />
          <Route path="/reminder-rules" element={<ReminderRulesPage />} />
          <Route path="/quiet-hours" element={<QuietHoursPage />} />
          <Route path="/report-export" element={<ReportExportPage />} />
          <Route path="/health-devices" element={<HealthDevicesPage />} />
          <Route path="/privacy-security" element={<PrivacySecurityPage />} />
          <Route path="/preferences" element={<PreferencesPage />} />
          <Route path="/about-help" element={<AboutHelpPage />} />
          
          {/* 统计分析相关 */}
          <Route path="/weekly-report" element={<WeeklyReportPage />} />
          <Route path="/behavior-analysis/:id" element={<BehaviorAnalysisPage />} />
          
          {/* 问一问相关 */}
          <Route path="/chat-history" element={<ChatHistoryPage />} />
          <Route path="/tag-management" element={<TagManagementPage />} />
        </Route>
      </Routes>
    </BrowserRouter>
  )
}

export default App
import { Outlet } from 'react-router-dom'
import PhoneFrame from '../components/PhoneFrame'

// 二级页面布局（有手机外壳，无底部导航栏）
const SecondaryLayout = () => {
  return (
    <PhoneFrame>
      <Outlet />
    </PhoneFrame>
  )
}

export default SecondaryLayout
import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { ChevronLeft, Watch, Activity, Heart, Thermometer, Plus, Bluetooth, RefreshCw, Check, X, Settings, Battery } from 'lucide-react'

// 已连接设备 mock 数据
const connectedDevices = [
  {
    id: '1',
    name: '华为手环 7',
    type: '手环',
    icon: 'Watch',
    status: '已连接',
    battery: 85,
    lastSync: '2分钟前',
    dataTypes: ['步数', '心率', '睡眠'],
  },
  {
    id: '2',
    name: '小米血压计',
    type: '血压计',
    icon: 'Activity',
    status: '已连接',
    battery: 100,
    lastSync: '1小时前',
    dataTypes: ['血压', '心率'],
  },
]

// 可发现设备 mock 数据
const discoverableDevices = [
  {
    id: '3',
    name: '荣耀体脂秤',
    type: '体脂秤',
    icon: 'Activity',
    rssi: -65,
  },
  {
    id: '4',
    name: '欧姆龙体温计',
    type: '体温计',
    icon: 'Thermometer',
    rssi: -72,
  },
]

// 数据同步状态
const syncStatus = [
  { type: '步数', count: '8,642', unit: '步', time: '10:30', status: 'success' },
  { type: '心率', count: '72', unit: 'bpm', time: '10:28', status: 'success' },
  { type: '血压', count: '120/80', unit: 'mmHg', time: '09:15', status: 'success' },
  { type: '睡眠', count: '7.5', unit: '小时', time: '07:00', status: 'success' },
]

const HealthDevicesPage = () => {
  const navigate = useNavigate()
  const [isScanning, setIsScanning] = useState(false)

  // 获取设备图标
  const getDeviceIcon = (iconName: string) => {
    const icons: { [key: string]: React.ReactNode } = {
      Watch: <Watch size={20} />,
      Activity: <Activity size={20} />,
      Heart: <Heart size={20} />,
      Thermometer: <Thermometer size={20} />,
    }
    return icons[iconName] || <Activity size={20} />
  }

  // 开始扫描
  const startScan = () => {
    setIsScanning(true)
    setTimeout(() => setIsScanning(false), 5000)
  }

  return (
    <div className="page-enter min-h-screen bg-bg-primary pb-24">
      {/* 顶部导航栏 */}
      <header className="px-4 py-3 bg-bg-secondary border-b border-border flex items-center justify-between sticky top-0 z-40">
        <button
          className="w-8 h-8 flex items-center justify-center text-text-primary transition-fast active:opacity-60"
          onClick={() => navigate(-1)}
        >
          <ChevronLeft size={24} />
        </button>
        <h1 className="text-body font-semibold text-text-primary">健康设备对接</h1>
        <button className="w-8 h-8 flex items-center justify-center text-accent transition-fast active:opacity-60">
          <Plus size={22} />
        </button>
      </header>

      {/* 提示区 */}
      <div className="px-4 py-3">
        <div className="bg-info-light rounded-md px-4 py-3 flex items-start gap-2">
          <Bluetooth size={18} className="text-info mt-0.5 shrink-0" />
          <div className="flex-1">
            <span className="text-body-small text-info">
              连接健康设备后，系统将自动同步健康数据并关联到日常行为记录
            </span>
          </div>
        </div>
      </div>

      {/* 已连接设备 */}
      <section className="px-4 mt-2">
        <div className="px-1 py-2 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <Check size={16} className="text-success" />
            <h2 className="text-body-small font-semibold text-text-secondary">已连接设备</h2>
          </div>
          <button className="flex items-center gap-1 text-accent text-caption font-medium">
            <RefreshCw size={14} className={isScanning ? 'animate-spin' : ''} />
            同步全部
          </button>
        </div>

        <div className="space-y-3">
          {connectedDevices.map((device) => (
            <div
              key={device.id}
              className="bg-bg-secondary rounded-lg card-shadow p-4"
            >
              {/* 设备头部 */}
              <div className="flex items-start justify-between mb-3">
                <div className="flex items-center gap-3">
                  <div className="w-12 h-12 bg-success-light rounded-lg flex items-center justify-center text-success">
                    {getDeviceIcon(device.icon)}
                  </div>
                  <div>
                    <div className="text-body-small font-medium text-text-primary">{device.name}</div>
                    <div className="flex items-center gap-2 mt-1">
                      <span className="px-2 py-0.5 rounded-sm bg-success-light text-caption text-success">
                        {device.status}
                      </span>
                      <span className="text-caption text-text-tertiary">{device.type}</span>
                    </div>
                  </div>
                </div>
                <button className="p-2 bg-bg-tertiary rounded-md transition-fast active:opacity-60">
                  <Settings size={16} className="text-text-secondary" />
                </button>
              </div>

              {/* 设备信息 */}
              <div className="bg-bg-tertiary rounded-md p-3 mb-3">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-1.5">
                    <Battery size={14} className={device.battery > 50 ? 'text-success' : device.battery > 20 ? 'text-warning' : 'text-danger'} />
                    <span className="text-caption text-text-secondary">电量</span>
                  </div>
                  <span className="text-caption font-medium text-text-primary">{device.battery}%</span>
                </div>
                <div className="flex items-center justify-between mt-2">
                  <div className="flex items-center gap-1.5">
                    <RefreshCw size={14} className="text-text-secondary" />
                    <span className="text-caption text-text-secondary">最后同步</span>
                  </div>
                  <span className="text-caption font-medium text-text-primary">{device.lastSync}</span>
                </div>
              </div>

              {/* 数据类型 */}
              <div className="flex flex-wrap gap-2">
                {device.dataTypes.map((type) => (
                  <span key={type} className="px-2 py-1 bg-accent-light rounded-md text-caption text-accent">
                    {type}
                  </span>
                ))}
              </div>
            </div>
          ))}
        </div>
      </section>

      {/* 可发现设备 */}
      <section className="px-4 mt-6">
        <div className="px-1 py-2 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <Bluetooth size={16} className="text-accent" />
            <h2 className="text-body-small font-semibold text-text-secondary">发现新设备</h2>
          </div>
          <button
            onClick={startScan}
            className="flex items-center gap-1 text-accent text-caption font-medium"
          >
            <RefreshCw size={14} className={isScanning ? 'animate-spin' : ''} />
            {isScanning ? '扫描中...' : '扫描'}
          </button>
        </div>

        <div className="space-y-2">
          {discoverableDevices.map((device) => (
            <div
              key={device.id}
              className="bg-bg-secondary rounded-lg card-shadow p-4"
            >
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 bg-bg-tertiary rounded-lg flex items-center justify-center text-text-secondary">
                    {getDeviceIcon(device.icon)}
                  </div>
                  <div>
                    <div className="text-body-small font-medium text-text-primary">{device.name}</div>
                    <div className="text-caption text-text-tertiary">{device.type} · 信号强度 {device.rssi}dBm</div>
                  </div>
                </div>
                <button className="px-3 py-1.5 bg-accent-light rounded-md text-accent text-caption font-medium transition-fast active:bg-accent/10">
                  连接
                </button>
              </div>
            </div>
          ))}
        </div>
      </section>

      {/* 最近同步数据 */}
      <section className="px-4 mt-6">
        <div className="px-1 py-2 flex items-center gap-2">
          <Heart size={16} className="text-accent" />
          <h2 className="text-body-small font-semibold text-text-secondary">最近同步数据</h2>
        </div>

        <div className="bg-bg-secondary rounded-lg card-shadow overflow-hidden">
          {syncStatus.map((item, index) => (
            <div
              key={item.type}
              className={`p-4 flex items-center justify-between ${
                index < syncStatus.length - 1 ? 'border-b border-border' : ''
              }`}
            >
              <div>
                <div className="text-body-small font-medium text-text-primary">{item.type}</div>
                <div className="text-caption text-text-tertiary">更新于 {item.time}</div>
              </div>
              <div className="text-right">
                <div className="text-body-small font-semibold text-text-primary">
                  {item.count} <span className="text-caption font-normal text-text-secondary">{item.unit}</span>
                </div>
                <Check size={14} className="text-success mt-1 inline-block" />
              </div>
            </div>
          ))}
        </div>
      </section>

      {/* 底部操作按钮 */}
      <div className="sticky bottom-0 left-0 right-0 bg-bg-secondary border-t border-border px-4 py-3 z-40 safe-area-bottom">
        <button
          onClick={startScan}
          className="w-full py-3 bg-accent rounded-md text-white text-body-small font-medium transition-fast active:bg-text-primary button-shadow flex items-center justify-center gap-2"
        >
          <Bluetooth size={18} />
          扫描并添加设备
        </button>
      </div>
    </div>
  )
}

export default HealthDevicesPage
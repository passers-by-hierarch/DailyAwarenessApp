import { ReactNode } from 'react'

interface PhoneFrameProps {
  children: ReactNode
}

const PhoneFrame = ({ children }: PhoneFrameProps) => {
  return (
    <div className="min-h-screen bg-bg-tertiary flex justify-center items-start py-6 px-4">
      {/* 手机外壳 - iPhone 14尺寸 */}
      <div
        className="w-full max-w-[390px] bg-bg-primary rounded-[40px] shadow-xl relative border-[10px] border-black flex flex-col transform-gpu overflow-hidden"
        style={{ height: '844px' }}
      >
        {/* 顶部状态栏 */}
        <div className="h-11 bg-bg-secondary flex items-center justify-between px-6 relative shrink-0">
          <div className="text-body-small font-semibold text-text-primary">9:41</div>
          <div className="absolute left-1/2 -translate-x-1/2 top-2 w-24 h-6 bg-black rounded-full" />
          <div className="flex items-center gap-1.5">
            <div className="flex items-end gap-0.5 h-3">
              <div className="w-0.5 h-1 bg-text-primary rounded-sm" />
              <div className="w-0.5 h-1.5 bg-text-primary rounded-sm" />
              <div className="w-0.5 h-2 bg-text-primary rounded-sm" />
              <div className="w-0.5 h-2.5 bg-text-primary rounded-sm" />
            </div>
            <div className="w-3 h-3 relative">
              <div className="absolute inset-0 rounded-full border-[1.5px] border-text-primary" />
              <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-1 h-1 bg-text-primary rounded-full" />
            </div>
            <div className="flex items-center gap-0.5">
              <div className="relative w-6 h-3 border border-text-primary rounded-sm">
                <div className="absolute top-1/2 left-0.5 -translate-y-1/2 w-4 h-1.5 bg-text-primary rounded-[1px]" />
              </div>
              <div className="w-0.5 h-1.5 bg-text-primary rounded-r-sm" />
            </div>
          </div>
        </div>

        {/* 中间内容区域 - 包含页面内容 + 底部导航 */}
        <div className="flex-1 flex flex-col overflow-y-auto overflow-x-hidden bg-bg-primary relative">
          {children}
        </div>

        {/* 底部 Home Indicator */}
        <div className="h-8 bg-bg-secondary flex items-center justify-center shrink-0">
          <div className="w-32 h-1 bg-text-primary rounded-full opacity-80" />
        </div>
      </div>
    </div>
  )
}

export default PhoneFrame
import { useState, useRef, useEffect } from 'react'
import { Clock, AlertTriangle, Check, Trash2, XCircle } from 'lucide-react'

interface AgendaItemProps {
  id: string
  time: string
  content: string
  note?: string
  isMustDo: boolean
  status: 'completed' | 'pending' | 'skipped' | 'postponed' | 'expired'
  remainingTime?: string
  isHighFrequency?: boolean
  onClick?: () => void
  onDelete?: (id: string) => void
}

const AgendaItem = ({ id, time, content, note, isMustDo, status, remainingTime, isHighFrequency, onClick, onDelete }: AgendaItemProps) => {
  const [translateX, setTranslateX] = useState(0)
  const [startX, setStartX] = useState(0)
  const [isDragging, setIsDragging] = useState(false)
  const [showConfirm, setShowConfirm] = useState(false)
  const containerRef = useRef<HTMLDivElement>(null)
  const maxSwipe = -80

  const getStatusStyle = () => {
    switch (status) {
      case 'completed':
        return { icon: Check, bgClass: 'bg-success-light', textClass: 'text-success', label: '已完成' }
      case 'pending':
        return { icon: Clock, bgClass: isMustDo ? 'bg-danger-light' : 'bg-warning-light', textClass: isMustDo ? 'text-danger' : 'text-warning', label: isMustDo ? '待进行' : '待验证' }
      case 'skipped':
        return { icon: Clock, bgClass: 'bg-bg-tertiary', textClass: 'text-text-tertiary', label: '已跳过' }
      case 'postponed':
        return { icon: Clock, bgClass: 'bg-bg-tertiary', textClass: 'text-text-tertiary', label: '已推迟' }
      case 'expired':
        return { icon: XCircle, bgClass: 'bg-bg-tertiary', textClass: 'text-text-tertiary', label: '已过期' }
    }
  }

  const statusStyle = getStatusStyle()
  const StatusIcon = statusStyle.icon

  const handleTouchStart = (e: React.TouchEvent) => {
    setStartX(e.touches[0].clientX)
    setIsDragging(true)
  }

  const handleTouchMove = (e: React.TouchEvent) => {
    if (!isDragging) return
    const diff = e.touches[0].clientX - startX
    const newTranslate = Math.max(maxSwipe, Math.min(0, diff))
    setTranslateX(newTranslate)
  }

  const handleTouchEnd = () => {
    setIsDragging(false)
    if (translateX < maxSwipe / 2) {
      setTranslateX(maxSwipe)
    } else {
      setTranslateX(0)
    }
  }

  const handleMouseDown = (e: React.MouseEvent) => {
    setStartX(e.clientX)
    setIsDragging(true)
  }

  const handleMouseMove = (e: MouseEvent) => {
    if (!isDragging) return
    const diff = e.clientX - startX
    const newTranslate = Math.max(maxSwipe, Math.min(0, diff))
    setTranslateX(newTranslate)
  }

  const handleMouseUp = () => {
    setIsDragging(false)
    if (translateX < maxSwipe / 2) {
      setTranslateX(maxSwipe)
    } else {
      setTranslateX(0)
    }
  }

  useEffect(() => {
    if (isDragging) {
      document.addEventListener('mousemove', handleMouseMove)
      document.addEventListener('mouseup', handleMouseUp)
      return () => {
        document.removeEventListener('mousemove', handleMouseMove)
        document.removeEventListener('mouseup', handleMouseUp)
      }
    }
  }, [isDragging])

  const handleDelete = () => {
    if (onDelete) onDelete(id)
    setTranslateX(0)
    setShowConfirm(false)
  }

  return (
    <div className="relative overflow-hidden mb-2" ref={containerRef}>
      <div className="absolute right-0 top-0 bottom-0 w-20 bg-danger flex items-center justify-center rounded-r-lg">
        {showConfirm ? (
          <button onClick={(e) => { e.stopPropagation(); handleDelete() }} className="text-white flex flex-col items-center gap-1">
            <Check size={20} />
            <span className="text-caption">确认</span>
          </button>
        ) : (
          <button onClick={(e) => { e.stopPropagation(); setShowConfirm(true) }} className="text-white flex flex-col items-center gap-1">
            <Trash2 size={20} />
            <span className="text-caption">删除</span>
          </button>
        )}
      </div>
      <div
        className={`bg-bg-secondary rounded-lg card-shadow overflow-hidden transition-transform ${isDragging ? '' : 'duration-200'} ${isMustDo && status !== 'expired' ? 'border-l-4 border-danger' : ''} ${onClick ? 'cursor-pointer' : ''}`}
        style={{ transform: `translateX(${translateX}px)` }}
        onTouchStart={handleTouchStart}
        onTouchMove={handleTouchMove}
        onTouchEnd={handleTouchEnd}
        onMouseDown={handleMouseDown}
        onClick={onClick}
      >
        <div className="flex items-center p-4">
          <div className="flex flex-col items-center mr-3 shrink-0">
            <div className={`w-7 h-7 rounded-full ${statusStyle.bgClass} flex items-center justify-center`}>
              {isMustDo && status === 'pending' ? (
                <AlertTriangle size={16} className={statusStyle.textClass} />
              ) : (
                <StatusIcon size={16} className={statusStyle.textClass} />
              )}
            </div>
            {isHighFrequency && <span className="mt-1 px-1.5 py-0.5 bg-purple-100 text-purple-600 rounded-sm text-xs font-medium">高频</span>}
          </div>
          <div className={`w-12 text-time font-mono shrink-0 ${status === 'expired' ? 'text-text-tertiary' : 'text-text-secondary'}`}>{time}</div>
          <div className="flex-1 pl-3 min-w-0">
            <div className="flex items-center gap-2">
              <span className={`text-body font-medium truncate ${status === 'expired' ? 'text-text-tertiary line-through' : 'text-text-primary'}`}>{content}</span>
            </div>
            {note && <div className="text-caption text-text-tertiary mt-1 truncate">{note}</div>}
            {status === 'pending' && remainingTime && <div className="text-caption text-text-tertiary mt-1">{remainingTime}</div>}
          </div>
          <div className={`px-3 py-1.5 rounded-md ${statusStyle.bgClass} ${statusStyle.textClass} text-caption font-medium shrink-0`}>
            {statusStyle.label}
          </div>
        </div>
      </div>
    </div>
  )
}

export default AgendaItem

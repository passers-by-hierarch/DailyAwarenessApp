import { Plus } from 'lucide-react'

interface QuickActionsProps {
  onCreateAgenda?: () => void
}

const QuickActions = ({ onCreateAgenda }: QuickActionsProps) => {
  return (
    <div className="px-4 pt-3 pb-1">
      <button
        className="w-full h-10 rounded-md bg-bg-tertiary flex items-center justify-center gap-2 transition-fast active:bg-border"
        onClick={onCreateAgenda}
      >
        <Plus size={18} className="text-accent" />
        <span className="text-body-small font-medium text-text-primary">添加新事程</span>
      </button>
    </div>
  )
}

export default QuickActions

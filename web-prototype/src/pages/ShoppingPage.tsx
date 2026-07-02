import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { ChevronLeft, Plus, Mic, ShoppingCart, Calendar, MapPin, Clock, X, Check } from 'lucide-react'
import { useAppStore } from '../store/appStore'

const ShoppingPage = () => {
  const navigate = useNavigate()

  // 从 store 获取购物记录和操作
  const shoppingRecords = useAppStore(s => s.shoppingRecords)
  const addShoppingRecord = useAppStore(s => s.addShoppingRecord)

  // 添加记录弹窗状态
  const [showAddModal, setShowAddModal] = useState(false)
  const [newRecord, setNewRecord] = useState({
    store: '',
    itemsText: '', // 格式: 商品1数量单位,商品2数量单位
  })

  // 解析商品文本（格式：苹果2斤,牛奶3瓶）
  const parseItemsText = (text: string) => {
    const parts = text.split(/[，,、]/).map(s => s.trim()).filter(Boolean)
    return parts.map(part => {
      const m = part.match(/([\u4e00-\u9fa5A-Za-z]+?)(\d+(?:\.\d+)?)\s*(斤|公斤|克|千克|瓶|个|盒|袋|包|只|箱|打|份|升|毫升)?/)
      if (m) {
        return { name: m[1], quantity: m[2], unit: m[3] || '份' }
      }
      return { name: part, quantity: '1', unit: '份' }
    })
  }

  // 提交添加购物记录
  const handleAddRecord = () => {
    const store = newRecord.store.trim()
    const items = parseItemsText(newRecord.itemsText)
    if (!store || items.length === 0) return
    const now = new Date()
    const date = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}`
    const time = `${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}`
    addShoppingRecord({
      date,
      time,
      store,
      items,
      source: 'manual',
      rawText: '',
    })
    setNewRecord({ store: '', itemsText: '' })
    setShowAddModal(false)
  }

  // 按日期倒序排列
  const sortedRecords = [...shoppingRecords].sort((a, b) => {
    const dateA = `${a.date} ${a.time}`
    const dateB = `${b.date} ${b.time}`
    return dateB.localeCompare(dateA)
  })

  // 统计数据
  const monthlyCount = shoppingRecords.length
  const totalItems = shoppingRecords.reduce(
    (sum, record) => sum + record.items.length,
    0
  )

  return (
    <div className="page-enter min-h-screen bg-bg-primary pb-8">
      {/* 顶部导航栏 */}
      <header className="px-4 py-3 bg-bg-secondary border-b border-border flex items-center justify-between sticky top-0 z-40">
        <button
          className="w-8 h-8 flex items-center justify-center text-text-primary transition-fast active:opacity-60"
          onClick={() => navigate(-1)}
        >
          <ChevronLeft size={24} />
        </button>
        <h1 className="text-body font-semibold text-text-primary">购物记录</h1>
        <button
          className="w-8 h-8 flex items-center justify-center text-text-primary transition-fast active:opacity-60"
          onClick={() => setShowAddModal(true)}
        >
          <Plus size={22} />
        </button>
      </header>

      {/* 提示区 */}
      <div className="px-4 pt-4">
        <div className="bg-accent-light rounded-lg p-3 flex items-start gap-2">
          <Mic size={16} className="text-accent shrink-0 mt-0.5" />
          <div className="flex-1">
            <div className="text-body-small text-accent font-medium">语音自动识别</div>
            <div className="text-caption text-accent/80 mt-1">
              系统会自动从您的语音记录中识别购物信息
            </div>
          </div>
        </div>
      </div>

      {/* 统计概览卡片 */}
      <div className="px-4 mt-3">
        <div className="bg-bg-secondary rounded-lg card-shadow p-4">
          <div className="flex items-center gap-1.5 mb-3">
            <ShoppingCart size={14} className="text-accent" />
            <span className="text-caption font-semibold text-text-tertiary">本月概览</span>
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div className="text-center">
              <div className="text-2xl font-bold text-accent">{monthlyCount}</div>
              <div className="text-caption text-text-secondary mt-1">购物次数</div>
            </div>
            <div className="text-center">
              <div className="text-2xl font-bold text-accent">{totalItems}</div>
              <div className="text-caption text-text-secondary mt-1">商品总数</div>
            </div>
          </div>
        </div>
      </div>

      {/* 购物记录列表 */}
      <section className="px-4 mt-4">
        <div className="text-caption font-semibold text-text-tertiary mb-3 px-1">
          共 {sortedRecords.length} 条记录
        </div>

        {sortedRecords.length === 0 ? (
          <div className="bg-bg-secondary rounded-lg card-shadow py-12 text-center">
            <div className="text-4xl mb-3">🛒</div>
            <div className="text-body-small text-text-secondary">暂无购物记录</div>
          </div>
        ) : (
          <div className="space-y-3">
            {sortedRecords.map((record) => (
              <div
                key={record.id}
                className="bg-bg-secondary rounded-lg card-shadow p-3 transition-fast active:bg-bg-tertiary cursor-pointer"
              >
                {/* 顶部：日期时间 + 商店名称 + 来源标签 */}
                <div className="flex items-center justify-between mb-3">
                  <div className="flex items-center gap-2 min-w-0">
                    <div className="w-8 h-8 bg-accent-light rounded-lg flex items-center justify-center shrink-0">
                      <ShoppingCart size={16} className="text-accent" />
                    </div>
                    <div className="min-w-0">
                      <div className="text-body-small font-medium text-text-primary truncate">
                        {record.store}
                      </div>
                      <div className="flex items-center gap-2 mt-0.5">
                        <span className="text-caption text-text-tertiary flex items-center gap-0.5">
                          <Calendar size={10} />
                          {record.date}
                        </span>
                        <span className="text-caption text-text-tertiary flex items-center gap-0.5">
                          <Clock size={10} />
                          {record.time}
                        </span>
                      </div>
                    </div>
                  </div>
                  {record.source === 'voice' ? (
                    <span className="flex items-center gap-0.5 px-1.5 py-0.5 bg-accent-light text-accent text-caption rounded-sm shrink-0">
                      <Mic size={10} />
                      语音
                    </span>
                  ) : (
                    <span className="flex items-center gap-0.5 px-1.5 py-0.5 bg-bg-tertiary text-text-secondary text-caption rounded-sm shrink-0">
                      手动
                    </span>
                  )}
                </div>

                {/* 商品列表 */}
                <div className="bg-bg-tertiary rounded-md p-2 mb-2">
                  <div className="flex items-center gap-1 mb-1.5 px-1">
                    <MapPin size={10} className="text-success" />
                    <span className="text-caption text-text-tertiary">商品清单</span>
                  </div>
                  <div className="space-y-1">
                    {record.items.map((item, idx) => (
                      <div
                        key={idx}
                        className="flex items-center justify-between px-2 py-1.5 bg-bg-secondary rounded-sm"
                      >
                        <span className="text-body-small text-text-primary">
                          {item.name}
                        </span>
                        <span className="text-caption text-text-secondary">
                          {item.quantity} {item.unit}
                        </span>
                      </div>
                    ))}
                  </div>
                </div>

                {/* 语音原文 */}
                {record.source === 'voice' && record.rawText && (
                  <div className="flex items-start gap-1.5 mt-2 px-1">
                    <Mic size={12} className="text-accent shrink-0 mt-0.5" />
                    <div className="flex-1 text-caption text-text-secondary italic">
                      "{record.rawText}"
                    </div>
                  </div>
                )}
              </div>
            ))}
          </div>
        )}
      </section>

      {/* 添加购物记录弹窗 */}
      {showAddModal && (
        <div className="fixed inset-0 z-50 flex items-end justify-center">
          <div className="absolute inset-0 bg-black/40" onClick={() => setShowAddModal(false)} />
          <div className="relative w-full max-w-[390px] bg-bg-secondary rounded-t-xl px-4 pt-5 pb-6 animate-[pageEnter_250ms_ease-out]">
            {/* 顶部拖动条 */}
            <div className="w-10 h-1 bg-bg-tertiary rounded-full mx-auto mb-4" />

            {/* 标题 */}
            <div className="flex items-center justify-between mb-5">
              <h2 className="text-title-small font-semibold text-text-primary">添加购物记录</h2>
              <button
                className="w-6 h-6 flex items-center justify-center text-text-secondary active:opacity-60"
                onClick={() => setShowAddModal(false)}
              >
                <X size={18} />
              </button>
            </div>

            {/* 商店名称 */}
            <div className="mb-4">
              <label className="text-body-small font-semibold text-text-secondary mb-2 block">商店/地点</label>
              <input
                type="text"
                value={newRecord.store}
                onChange={(e) => setNewRecord({ ...newRecord, store: e.target.value })}
                placeholder="例如: 超市、菜市场、药店"
                className="w-full bg-bg-tertiary rounded-md px-4 py-3 text-body text-text-primary outline-none focus:ring-2 focus:ring-accent placeholder:text-text-tertiary"
              />
            </div>

            {/* 商品列表 */}
            <div className="mb-4">
              <label className="text-body-small font-semibold text-text-secondary mb-2 block">商品清单</label>
              <input
                type="text"
                value={newRecord.itemsText}
                onChange={(e) => setNewRecord({ ...newRecord, itemsText: e.target.value })}
                placeholder="格式: 苹果2斤,牛奶3瓶"
                className="w-full bg-bg-tertiary rounded-md px-4 py-3 text-body text-text-primary outline-none focus:ring-2 focus:ring-accent placeholder:text-text-tertiary"
              />
              <div className="text-caption text-text-tertiary mt-1.5">
                用逗号分隔多个商品，格式为 商品名+数量+单位
              </div>
              {/* 解析预览 */}
              {newRecord.itemsText && (
                <div className="mt-2 flex flex-wrap gap-1.5">
                  {parseItemsText(newRecord.itemsText).map((item, i) => (
                    <span key={i} className="px-2 py-1 bg-accent-light text-accent text-caption rounded-sm">
                      {item.name} × {item.quantity}{item.unit}
                    </span>
                  ))}
                </div>
              )}
            </div>

            {/* 操作按钮 */}
            <div className="flex gap-3">
              <button
                className="flex-1 py-3 bg-bg-tertiary rounded-md text-body-small font-medium text-text-secondary active:bg-border transition-fast"
                onClick={() => setShowAddModal(false)}
              >
                取消
              </button>
              <button
                className="flex-1 py-3 bg-accent rounded-md text-white text-body-small font-medium active:bg-text-primary transition-fast flex items-center justify-center gap-1.5"
                onClick={handleAddRecord}
                disabled={!newRecord.store.trim() || !newRecord.itemsText.trim()}
              >
                <Check size={16} />
                添加
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

export default ShoppingPage

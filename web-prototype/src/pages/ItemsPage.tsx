import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { ChevronLeft, Plus, Search, Mic, TrendingUp, MapPin, Clock, X, Check } from 'lucide-react'
import { useAppStore } from '../store/appStore'

// 可选图标
const iconOptions = ['🔑', '📋', '💳', '📱', '🎧', '🔧', '👓', '💼', '📷', '💍', '💊', '📚']

const ItemsPage = () => {
  const navigate = useNavigate()
  const [searchKeyword, setSearchKeyword] = useState('')
  const [activeTab, setActiveTab] = useState<'items' | 'voice'>('items')

  // 从 store 获取物品和操作
  const items = useAppStore(s => s.items)
  const addItem = useAppStore(s => s.addItem)

  // 添加物品弹窗状态
  const [showAddModal, setShowAddModal] = useState(false)
  const [newItem, setNewItem] = useState({ icon: '🔑', name: '', location: '' })

  // 过滤物品
  const filteredItems = items.filter(
    (item) =>
      item.name.includes(searchKeyword) ||
      item.location.includes(searchKeyword)
  )

  // 从时间线中提取物品类型的语音记录
  const timelineRecords = useAppStore(s => s.timelineRecords)
  const voiceItemRecords = timelineRecords
    .filter(r => r.tags.includes('item') && r.extractedData?.item?.itemName && r.extractedData?.item?.location)
    .map(r => ({
      id: r.id,
      content: r.content,
      item: r.extractedData.item.itemName,
      location: r.extractedData.item.location,
      time: r.time,
    }))

  // 过滤语音记录
  const filteredVoiceRecords = voiceItemRecords.filter(
    (record) =>
      record.item.includes(searchKeyword) ||
      record.location.includes(searchKeyword) ||
      record.content.includes(searchKeyword)
  )

  // 提交添加物品
  const handleAddItem = () => {
    if (!newItem.name.trim() || !newItem.location.trim()) return
    addItem({
      icon: newItem.icon,
      name: newItem.name.trim(),
      location: newItem.location.trim(),
      source: 'manual',
    })
    setNewItem({ icon: '🔑', name: '', location: '' })
    setShowAddModal(false)
  }

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
        <h1 className="text-body font-semibold text-text-primary">物品位置记忆</h1>
        <button
          className="w-8 h-8 flex items-center justify-center text-text-primary transition-fast active:opacity-60"
          onClick={() => setShowAddModal(true)}
        >
          <Plus size={22} />
        </button>
      </header>

      {/* 搜索框 */}
      <div className="px-4 py-3">
        <div className="bg-bg-tertiary rounded-md px-4 py-2.5 flex items-center gap-2">
          <Search size={18} className="text-text-tertiary shrink-0" />
          <input
            type="text"
            value={searchKeyword}
            onChange={(e) => setSearchKeyword(e.target.value)}
            placeholder="搜索物品或位置..."
            className="flex-1 text-body-small text-text-primary bg-transparent outline-none placeholder:text-text-tertiary"
          />
          {searchKeyword && (
            <button
              className="text-text-tertiary text-caption"
              onClick={() => setSearchKeyword('')}
            >
              清除
            </button>
          )}
        </div>
      </div>

      {/* Tab切换 */}
      <div className="px-4 pb-2">
        <div className="flex gap-2">
          <button
            className={`flex-1 py-2 rounded-md text-body-small font-medium transition-fast ${
              activeTab === 'items'
                ? 'bg-accent-light text-accent'
                : 'bg-bg-tertiary text-text-secondary'
            }`}
            onClick={() => setActiveTab('items')}
          >
            📦 物品列表
          </button>
          <button
            className={`flex-1 py-2 rounded-md text-body-small font-medium transition-fast ${
              activeTab === 'voice'
                ? 'bg-accent-light text-accent'
                : 'bg-bg-tertiary text-text-secondary'
            }`}
            onClick={() => setActiveTab('voice')}
          >
            🎤 语音记录抽取
          </button>
        </div>
      </div>

      {/* 物品列表Tab */}
      {activeTab === 'items' && (
        <section className="px-4">
          {/* 统计信息 */}
          <div className="text-caption font-semibold text-text-tertiary mb-3 px-1">
            共 {filteredItems.length} 件物品
          </div>

          {filteredItems.length === 0 ? (
            <div className="bg-bg-secondary rounded-lg card-shadow py-12 text-center">
              <div className="text-4xl mb-3">🔍</div>
              <div className="text-body-small text-text-secondary">未找到相关物品</div>
            </div>
          ) : (
            <div className="grid grid-cols-2 gap-2.5">
              {filteredItems.map((item) => (
                <div
                  key={item.id}
                  className="bg-bg-secondary rounded-lg card-shadow p-3 transition-fast active:bg-bg-tertiary cursor-pointer"
                  onClick={() => navigate(`/items/${item.id}`)}
                >
                  {/* 顶部：图标 + 来源标记 */}
                  <div className="flex items-start justify-between mb-2">
                    <div className="w-12 h-12 bg-bg-tertiary rounded-lg flex items-center justify-center text-2xl">
                      {item.icon}
                    </div>
                    {item.source === 'voice' && (
                      <span className="flex items-center gap-0.5 px-1.5 py-0.5 bg-success-light text-success text-caption rounded-sm">
                        <Mic size={10} />
                        语音
                      </span>
                    )}
                  </div>

                  {/* 名称 */}
                  <div className="text-body-small font-medium text-text-primary">
                    {item.name}
                  </div>

                  {/* 当前位置 */}
                  <div className="flex items-center gap-1 mt-1">
                    <MapPin size={11} className="text-success" />
                    <span className="text-caption text-text-secondary">{item.location}</span>
                  </div>

                  {/* 位置规律（最常放置） */}
                  <div className="mt-2 pt-2 border-t border-border">
                    <div className="flex items-center gap-1 mb-1">
                      <TrendingUp size={10} className="text-accent" />
                      <span className="text-caption text-text-tertiary">位置规律</span>
                    </div>
                    {/* 位置分布条 */}
                    <div className="flex h-1.5 rounded-full overflow-hidden bg-bg-tertiary">
                      {item.locationHistory.map((loc, i) => (
                        <div
                          key={i}
                          className={`h-full ${i === 0 ? 'bg-accent' : i === 1 ? 'bg-accent/50' : 'bg-accent/25'}`}
                          style={{ width: `${loc.percent}%` }}
                        />
                      ))}
                    </div>
                    <div className="text-caption text-text-tertiary mt-1">
                      最常放: {item.locationHistory[0].location} ({item.locationHistory[0].percent}%)
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}

          {/* 位置变化提示 */}
          <div className="mt-4 bg-info-light rounded-lg p-3 flex items-start gap-2">
            <span className="text-body-small">💡</span>
            <div className="flex-1">
              <div className="text-body-small text-info font-medium">智能提示</div>
              <div className="text-caption text-info/80 mt-1">
                系统会自动从您的语音记录中识别物品位置信息，并总结放置规律。当物品出现在新位置时会自动更新记录。
              </div>
            </div>
          </div>
        </section>
      )}

      {/* 语音记录抽取Tab */}
      {activeTab === 'voice' && (
        <section className="px-4">
          {/* 说明 */}
          <div className="bg-accent-light rounded-lg p-3 flex items-start gap-2 mb-3">
            <Mic size={16} className="text-accent shrink-0 mt-0.5" />
            <div className="flex-1">
              <div className="text-body-small text-accent font-medium">语音自动抽取</div>
              <div className="text-caption text-accent/80 mt-1">
                以下记录从您的日常语音中自动识别物品位置信息
              </div>
            </div>
          </div>

          {/* 语音记录列表 */}
          {filteredVoiceRecords.length === 0 ? (
            <div className="bg-bg-secondary rounded-lg card-shadow py-12 text-center">
              <div className="text-4xl mb-3">🎤</div>
              <div className="text-body-small text-text-secondary">暂无语音记录</div>
              <div className="text-caption text-text-tertiary mt-1">
                在首页录音时提到物品位置即可自动记录
              </div>
            </div>
          ) : (
            <div className="space-y-2.5">
              {filteredVoiceRecords.map((record) => {
                // 找到对应物品
                const matchedItem = items.find(i => i.name === record.item)
                return (
                  <div
                    key={record.id}
                    className="bg-bg-secondary rounded-lg card-shadow p-3 transition-fast active:bg-bg-tertiary cursor-pointer"
                    onClick={() => matchedItem && navigate(`/items/${matchedItem.id}`)}
                  >
                    {/* 顶部：语音标识 + 时间 */}
                    <div className="flex items-center justify-between mb-2">
                      <div className="flex items-center gap-1.5">
                        <div className="w-6 h-6 bg-accent-light rounded-full flex items-center justify-center">
                          <Mic size={12} className="text-accent" />
                        </div>
                        <span className="text-caption text-text-tertiary flex items-center gap-1">
                          <Clock size={10} />
                          {record.time}
                        </span>
                      </div>
                      {matchedItem && (
                        <span className="text-lg">{matchedItem.icon}</span>
                      )}
                    </div>

                    {/* 语音内容 */}
                    <div className="text-body-small text-text-primary mb-2">
                      "{record.content}"
                    </div>

                    {/* 抽取结果 */}
                    <div className="flex items-center gap-2 flex-wrap">
                      <span className="px-2 py-0.5 bg-accent-light text-accent text-caption rounded-sm">
                        {record.item}
                      </span>
                      <span className="text-text-tertiary text-caption">→</span>
                      <span className="px-2 py-0.5 bg-success-light text-success text-caption rounded-sm flex items-center gap-1">
                        <MapPin size={10} />
                        {record.location}
                      </span>
                    </div>
                  </div>
                )
              })}
            </div>
          )}

          {/* 底部提示 */}
          <div className="mt-4 text-center">
            <button className="text-body-small text-info font-medium transition-fast active:opacity-60">
              共 {filteredVoiceRecords.length} 条语音记录
            </button>
          </div>
        </section>
      )}

      {/* 添加物品弹窗 */}
      {showAddModal && (
        <div className="fixed inset-0 z-50 flex items-end justify-center">
          <div className="absolute inset-0 bg-black/40" onClick={() => setShowAddModal(false)} />
          <div className="relative w-full max-w-[390px] bg-bg-secondary rounded-t-xl px-4 pt-5 pb-6 animate-[pageEnter_250ms_ease-out]">
            {/* 顶部拖动条 */}
            <div className="w-10 h-1 bg-bg-tertiary rounded-full mx-auto mb-4" />

            {/* 标题 */}
            <div className="flex items-center justify-between mb-5">
              <h2 className="text-title-small font-semibold text-text-primary">添加物品</h2>
              <button
                className="w-6 h-6 flex items-center justify-center text-text-secondary active:opacity-60"
                onClick={() => setShowAddModal(false)}
              >
                <X size={18} />
              </button>
            </div>

            {/* 图标选择 */}
            <div className="mb-4">
              <label className="text-body-small font-semibold text-text-secondary mb-2 block">选择图标</label>
              <div className="flex gap-2 overflow-x-auto pb-2">
                {iconOptions.map((icon) => (
                  <button
                    key={icon}
                    className={`w-11 h-11 rounded-lg flex items-center justify-center text-xl transition-fast ${
                      newItem.icon === icon ? 'ring-2 ring-accent bg-accent-light' : 'bg-bg-tertiary'
                    }`}
                    onClick={() => setNewItem({ ...newItem, icon })}
                  >
                    {icon}
                  </button>
                ))}
              </div>
            </div>

            {/* 物品名称 */}
            <div className="mb-4">
              <label className="text-body-small font-semibold text-text-secondary mb-2 block">物品名称</label>
              <input
                type="text"
                value={newItem.name}
                onChange={(e) => setNewItem({ ...newItem, name: e.target.value })}
                placeholder="例如: 钥匙、护照、身份证"
                className="w-full bg-bg-tertiary rounded-md px-4 py-3 text-body text-text-primary outline-none focus:ring-2 focus:ring-accent placeholder:text-text-tertiary"
              />
            </div>

            {/* 放置位置 */}
            <div className="mb-5">
              <label className="text-body-small font-semibold text-text-secondary mb-2 block">放置位置</label>
              <input
                type="text"
                value={newItem.location}
                onChange={(e) => setNewItem({ ...newItem, location: e.target.value })}
                placeholder="例如: 门口鞋柜、抽屉里"
                className="w-full bg-bg-tertiary rounded-md px-4 py-3 text-body text-text-primary outline-none focus:ring-2 focus:ring-accent placeholder:text-text-tertiary"
              />
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
                onClick={handleAddItem}
                disabled={!newItem.name.trim() || !newItem.location.trim()}
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

export default ItemsPage

import { useNavigate } from 'react-router-dom'
import { ChevronLeft, MapPin, Clock, Calendar, Edit, Trash2, Bell, Tag, Camera, FileText, AlertCircle, Mic, TrendingUp, History } from 'lucide-react'

// 物品详情 mock 数据
const itemDetail = {
  id: '1',
  name: '老花镜',
  category: '常用物品',
  location: '客厅茶几',
  lastSeen: '2026-07-01 09:30',
  addDate: '2026-01-15',
  reminder: '离开家时提醒',
  tags: ['眼镜', '常用', '重要'],
  notes: '父亲常用的老花镜，看书看报必备',
  photos: [
    'https://picsum.photos/200/200?random=1',
    'https://picsum.photos/200/200?random=2',
  ],
  usageCount: 156,
  source: 'voice',
  // 位置历史记录（从语音记录中抽取 + 手动设置）
  locationHistory: [
    { date: '2026-07-01', time: '09:30', location: '客厅茶几', source: 'voice', content: '老花镜放在茶几上了' },
    { date: '2026-06-30', time: '10:15', location: '书房', source: 'voice', content: '在书房看完报纸放下了眼镜' },
    { date: '2026-06-29', time: '08:45', location: '客厅茶几', source: 'voice', content: '眼镜放在客厅了' },
    { date: '2026-06-28', time: '20:30', location: '床头柜', source: 'voice', content: '睡前把眼镜放在床头柜' },
    { date: '2026-06-28', time: '09:00', location: '客厅茶几', source: 'manual', content: '' },
    { date: '2026-06-27', time: '15:20', location: '书房', source: 'voice', content: '在书房看书' },
  ],
  // 位置规律统计
  locationPattern: [
    { location: '客厅茶几', count: 89, percent: 57 },
    { location: '书房', count: 42, percent: 27 },
    { location: '床头柜', count: 18, percent: 12 },
    { location: '其他', count: 7, percent: 4 },
  ],
  recentUsage: [
    { date: '2026-07-01', time: '09:30', location: '客厅' },
    { date: '2026-06-30', time: '10:15', location: '书房' },
    { date: '2026-06-29', time: '08:45', location: '客厅' },
  ],
}

const ItemDetailPage = () => {
  const navigate = useNavigate()

  // 信息行组件
  const InfoRow = ({ icon: Icon, label, value, valueClass = 'text-text-primary' }: {
    icon: React.ReactNode
    label: string
    value: string
    valueClass?: string
  }) => (
    <div className="flex items-center gap-3 py-2">
      <div className="w-5 flex justify-center text-text-secondary">
        {Icon}
      </div>
      <span className="text-body-small text-text-secondary w-20">{label}</span>
      <span className={`text-body-small font-medium ${valueClass}`}>{value}</span>
    </div>
  )

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
        <h1 className="text-body font-semibold text-text-primary">物品详情</h1>
        <div className="flex items-center gap-3">
          <button className="text-body-small font-medium text-info transition-fast active:opacity-60">
            编辑
          </button>
          <button className="text-body-small font-medium text-danger transition-fast active:opacity-60">
            删除
          </button>
        </div>
      </header>

      {/* 物品基本信息 */}
      <section className="px-4 pt-4">
        <div className="bg-bg-secondary rounded-lg card-shadow p-4">
          {/* 头部：图标 + 名称 + 分类 */}
          <div className="flex items-start gap-4">
            <div className="w-16 h-16 bg-accent-light rounded-xl flex items-center justify-center shrink-0">
              <span className="text-3xl">👓</span>
            </div>
            <div className="flex-1 min-w-0">
              <div className="flex items-center gap-2">
                <h2 className="text-h3 font-semibold text-text-primary mb-1">{itemDetail.name}</h2>
                {itemDetail.source === 'voice' && (
                  <span className="flex items-center gap-0.5 px-1.5 py-0.5 bg-success-light text-success text-caption rounded-sm">
                    <Mic size={10} />
                    语音抽取
                  </span>
                )}
              </div>
              <span className="px-2 py-0.5 rounded-sm bg-accent-light text-caption text-accent">
                {itemDetail.category}
              </span>
            </div>
          </div>

          {/* 照片 */}
          {itemDetail.photos.length > 0 && (
            <div className="flex gap-2 mt-4 overflow-x-auto pb-2">
              {itemDetail.photos.map((photo, index) => (
                <div
                  key={index}
                  className="w-20 h-20 rounded-lg bg-bg-tertiary shrink-0 overflow-hidden"
                >
                  <div className="w-full h-full bg-bg-tertiary flex items-center justify-center">
                    <Camera size={24} className="text-text-tertiary" />
                  </div>
                </div>
              ))}
            </div>
          )}

          {/* 分割线 */}
          <div className="h-px bg-border my-4" />

          {/* 详细信息 */}
          <div className="space-y-1">
            <InfoRow
              icon={<MapPin size={14} />}
              label="存放位置"
              value={itemDetail.location}
              valueClass="text-success"
            />
            <InfoRow
              icon={<Clock size={14} />}
              label="最后见到"
              value={itemDetail.lastSeen}
            />
            <InfoRow
              icon={<Calendar size={14} />}
              label="添加日期"
              value={itemDetail.addDate}
            />
            <InfoRow
              icon={<Bell size={14} />}
              label="提醒设置"
              value={itemDetail.reminder}
              valueClass="text-accent"
            />
          </div>
        </div>
      </section>

      {/* 位置规律总结 */}
      <section className="px-4 mt-4">
        <div className="px-1 py-2 flex items-center gap-2">
          <TrendingUp size={16} className="text-accent" />
          <h2 className="text-body-small font-semibold text-text-secondary">位置规律总结</h2>
        </div>

        <div className="bg-bg-secondary rounded-lg card-shadow p-4">
          {/* 总体分布条 */}
          <div className="flex h-3 rounded-full overflow-hidden bg-bg-tertiary mb-3">
            {itemDetail.locationPattern.map((loc, i) => (
              <div
                key={i}
                className={`h-full ${i === 0 ? 'bg-accent' : i === 1 ? 'bg-accent/60' : i === 2 ? 'bg-accent/30' : 'bg-accent/15'}`}
                style={{ width: `${loc.percent}%` }}
              />
            ))}
          </div>

          {/* 各位置详情 */}
          <div className="space-y-2.5">
            {itemDetail.locationPattern.map((loc, index) => (
              <div key={index} className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <div className={`w-2 h-2 rounded-full ${index === 0 ? 'bg-accent' : index === 1 ? 'bg-accent/60' : index === 2 ? 'bg-accent/30' : 'bg-accent/15'}`} />
                  <span className="text-body-small text-text-primary">{loc.location}</span>
                  {index === 0 && (
                    <span className="px-1.5 py-0.5 bg-success-light text-success text-caption rounded-sm">
                      最常放
                    </span>
                  )}
                </div>
                <div className="flex items-center gap-3">
                  <span className="text-caption text-text-tertiary">{loc.count}次</span>
                  <span className="text-body-small font-mono font-medium text-text-secondary w-10 text-right">{loc.percent}%</span>
                </div>
              </div>
            ))}
          </div>

          {/* 规律提示 */}
          <div className="mt-3 pt-3 border-t border-border bg-info-light/50 -mx-4 -mb-4 px-4 py-3 rounded-b-lg">
            <div className="flex items-start gap-2">
              <span className="text-body-small">💡</span>
              <div className="flex-1">
                <div className="text-caption text-info font-medium">规律分析</div>
                <div className="text-caption text-text-secondary mt-1">
                  此物品最常放在 <span className="text-success font-medium">客厅茶几</span>（57%），
                  其次是 <span className="text-text-primary">书房</span>（27%）。
                  通常在看完书报后放置。
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* 放置位置历史 */}
      <section className="px-4 mt-4">
        <div className="px-1 py-2 flex items-center gap-2">
          <History size={16} className="text-accent" />
          <h2 className="text-body-small font-semibold text-text-secondary">放置位置历史</h2>
        </div>

        <div className="bg-bg-secondary rounded-lg card-shadow overflow-hidden">
          {itemDetail.locationHistory.map((record, index) => (
            <div
              key={index}
              className={`p-4 ${index < itemDetail.locationHistory.length - 1 ? 'border-b border-border' : ''}`}
            >
              <div className="flex items-start gap-3">
                {/* 时间线圆点 */}
                <div className="flex flex-col items-center shrink-0">
                  <div className={`w-2.5 h-2.5 rounded-full ${record.source === 'voice' ? 'bg-success' : 'bg-accent'}`} />
                  {index < itemDetail.locationHistory.length - 1 && (
                    <div className="w-0.5 h-8 bg-border mt-1" />
                  )}
                </div>

                {/* 内容 */}
                <div className="flex-1 min-w-0">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-2">
                      <span className="text-body-small font-medium text-text-primary">
                        {record.location}
                      </span>
                      {record.source === 'voice' ? (
                        <span className="flex items-center gap-0.5 px-1.5 py-0.5 bg-success-light text-success text-caption rounded-sm">
                          <Mic size={9} />
                          语音
                        </span>
                      ) : (
                        <span className="px-1.5 py-0.5 bg-bg-tertiary text-text-tertiary text-caption rounded-sm">
                          手动
                        </span>
                      )}
                    </div>
                    <span className="text-caption text-text-tertiary">
                      {record.date} {record.time}
                    </span>
                  </div>

                  {/* 语音原始内容 */}
                  {record.source === 'voice' && record.content && (
                    <div className="text-caption text-text-secondary mt-1 italic">
                      "{record.content}"
                    </div>
                  )}
                </div>
              </div>
            </div>
          ))}
        </div>

        {/* 查看更多 */}
        <button className="w-full py-2.5 mt-2 text-body-small text-info font-medium transition-fast active:opacity-60">
          查看全部历史记录 →
        </button>
      </section>

      {/* 标签 */}
      <section className="px-4 mt-4">
        <div className="px-1 py-2 flex items-center gap-2">
          <Tag size={16} className="text-accent" />
          <h2 className="text-body-small font-semibold text-text-secondary">标签</h2>
        </div>

        <div className="flex flex-wrap gap-2">
          {itemDetail.tags.map((tag) => (
            <span
              key={tag}
              className="px-3 py-1.5 bg-bg-secondary rounded-md text-body-small text-text-primary"
            >
              #{tag}
            </span>
          ))}
          <button className="px-3 py-1.5 border border-dashed border-border rounded-md text-body-small text-text-tertiary">
            + 添加标签
          </button>
        </div>
      </section>

      {/* 备注 */}
      <section className="px-4 mt-4">
        <div className="px-1 py-2 flex items-center gap-2">
          <FileText size={16} className="text-accent" />
          <h2 className="text-body-small font-semibold text-text-secondary">备注</h2>
        </div>

        <div className="bg-bg-secondary rounded-lg card-shadow p-4">
          <p className="text-body-small text-text-primary leading-relaxed">
            {itemDetail.notes}
          </p>
        </div>
      </section>

      {/* 使用统计 */}
      <section className="px-4 mt-4">
        <div className="px-1 py-2 flex items-center gap-2">
          <AlertCircle size={16} className="text-accent" />
          <h2 className="text-body-small font-semibold text-text-secondary">使用统计</h2>
        </div>

        <div className="bg-bg-secondary rounded-lg card-shadow p-4">
          <div className="flex items-center justify-between mb-4">
            <span className="text-body-small text-text-secondary">累计使用次数</span>
            <span className="text-h3 font-semibold text-accent">{itemDetail.usageCount}次</span>
          </div>

          {/* 使用趋势图 */}
          <div className="h-24 bg-bg-tertiary rounded-lg flex items-end justify-around px-4 py-3">
            {[40, 65, 45, 80, 55, 70, 90].map((height, index) => (
              <div
                key={index}
                className="w-6 bg-accent/30 rounded-t"
                style={{ height: `${height}%` }}
              />
            ))}
          </div>
          <div className="flex justify-around mt-2 text-caption text-text-tertiary">
            <span>一</span>
            <span>二</span>
            <span>三</span>
            <span>四</span>
            <span>五</span>
            <span>六</span>
            <span>日</span>
          </div>
        </div>
      </section>

      {/* 底部操作按钮 */}
      <div className="sticky bottom-0 left-0 right-0 bg-bg-secondary border-t border-border px-4 py-3 flex gap-3 z-40 safe-area-bottom">
        <button className="flex-1 py-3 bg-accent rounded-md text-white text-body-small font-medium transition-fast active:bg-text-primary button-shadow flex items-center justify-center gap-2">
          <Edit size={18} />
          编辑物品
        </button>

        <button className="flex-1 py-3 bg-danger-light rounded-md text-danger text-body-small font-medium transition-fast active:bg-danger-light/80 flex items-center justify-center gap-2">
          <Trash2 size={18} />
          删除物品
        </button>
      </div>
    </div>
  )
}

export default ItemDetailPage

import { create } from 'zustand'
import {
  mockTimelineRecords,
  mockAgendaItems,
  mockShoppingRecords,
  mockFrequentAgendas,
} from '../data/mockData'

// ===== 类型定义 =====
export type TimelineType = 'behavior' | 'item' | 'shopping' | 'event'
export type AgendaStatus = 'pending' | 'completed' | 'postponed' | 'expired'

// ===== 标签系统 =====
export type TagColor = 'accent' | 'info' | 'warning' | 'success' | 'danger' | 'gray' | 'purple'

export interface TagDef {
  id: string           // 系统标签用英文key，自定义标签用 genId()
  name: string         // 显示名
  color: TagColor      // 主题色
  icon: string         // lucide图标名 / emoji
  system: boolean      // true=系统内置不可删, false=用户自定义
  createdAt: string    // 创建时间
  usageCount: number   // 使用次数（统计用，自动维护）
}

// 系统内置标签（不可删除，不可改名）
export const SYSTEM_TAGS: TagDef[] = [
  { id: 'behavior', name: '行为活动', color: 'accent',  icon: 'activity',   system: true,  createdAt: '', usageCount: 0 },
  { id: 'item',     name: '物品位置', color: 'info',     icon: 'package',    system: true,  createdAt: '', usageCount: 0 },
  { id: 'shopping', name: '购物记录', color: 'warning',  icon: 'cart',       system: true,  createdAt: '', usageCount: 0 },
  { id: 'event',    name: '日常事件', color: 'gray',     icon: 'map',        system: true,  createdAt: '', usageCount: 0 },
]

// 自定义标签数量上限
export const MAX_CUSTOM_TAGS = 20

export interface NoteEntry {
  id: string
  content: string
  createdAt: string
}

export interface TimelineRecord {
  id: string
  date: string
  time: string
  content: string
  matchedAgenda?: string
  status: 'matched' | 'unmatched'
  tags: string[]
  extractedData: Partial<Record<string, any>>
  notes: NoteEntry[]
}

export interface AgendaItem {
  id: string
  date: string
  time: string
  content: string
  note?: string
  isMustDo: boolean
  status: AgendaStatus
  remainingTime?: string
  category?: string
  icon?: string
  isHighFrequency?: boolean
}

export interface DailyAgenda {
  id: string
  time: string
  content: string
  icon: string
  isMustDo: boolean
  category: string
  enabled: boolean
}

export interface AgendaRecommendation {
  id: string
  content: string
  time: string
  icon: string
  frequency: number
  source: 'history' | 'common-sense'
}

export interface PendingAgendaItem {
  id: string
  content: string
  time: string
  isMustDo: boolean
  timeSource: 'user-specified' | 'history' | 'common-sense' | 'current'
}

export interface ShoppingItem {
  name: string
  quantity: string
  unit: string
}

export interface ShoppingRecord {
  id: string
  date: string
  time: string
  store: string
  items: ShoppingItem[]
  source: 'voice' | 'manual'
  rawText: string
}

export interface LocationHistory {
  location: string
  count: number
  percent: number
}

export interface ItemRecord {
  id: string
  icon: string
  name: string
  location: string
  locationHistory: LocationHistory[]
  source: 'voice' | 'manual'
  lastUpdate: string
}

// ===== 模拟语音识别解析器（多标签） =====
// 一句话可以同时命中多个类型，返回所有命中的标签ID + 对应抽取数据
// 例: "回家，钥匙放在门口鞋柜" → tags: ['event', 'item']
export function parseVoiceText(text: string): {
  tags: string[]
  extractedData: Partial<Record<string, any>>
  sideEffects?: {
    shoppingRecord?: Omit<ShoppingRecord, 'id'>
    itemUpdate?: { name: string; location: string }
    agenda?: Omit<AgendaItem, 'id' | 'date'>
    agendaList?: Omit<AgendaItem, 'id' | 'date'>[]
  }
} {
  const t = text.trim()
  const tags: string[] = []
  const extractedData: Partial<Record<string, any>> = {}
  let sideEffects: {
    shoppingRecord?: Omit<ShoppingRecord, 'id'>
    itemUpdate?: { name: string; location: string }
    agenda?: Omit<AgendaItem, 'id' | 'date'>
  } = {}

  // 1) 物品位置：匹配 "XX放在YY" 或 "把XX放在YY"
  const itemPlaceMatch = t.match(/(?:把)?([\u4e00-\u9fa5A-Za-z]{1,8}?)(?:放|搁|塞)在?(?:了)?([\u4e00-\u9fa5A-Za-z]+?)(?:上|里|下|旁边|边|里面|上面|下面)?[了]?$/)
  if (itemPlaceMatch && itemPlaceMatch[1] && itemPlaceMatch[2]) {
    const itemName = itemPlaceMatch[1].trim()
    const location = itemPlaceMatch[2].trim()
    tags.push('item')
    extractedData.item = { itemName, location, action: 'place' }
    sideEffects.itemUpdate = { name: itemName, location }
  }

  // 2) 购物：匹配 "在XX买了YY"
  const buyMatch = t.match(/在?(.+?)买了(.+)/)
  if (buyMatch) {
    const store = buyMatch[1].trim()
    const itemsText = buyMatch[2].trim()
    const itemRegex = /([\u4e00-\u9fa5A-Za-z]+?)(\d+(?:\.\d+)?)\s*(斤|公斤|克|千克|瓶|个|盒|袋|包|只|箱|打|份|升|毫升)/g
    const items: ShoppingItem[] = []
    let m
    while ((m = itemRegex.exec(itemsText)) !== null) {
      items.push({ name: m[1], quantity: m[2], unit: m[3] })
    }
    if (items.length === 0) {
      const names = itemsText.split(/[，,、和]/).map(s => s.trim()).filter(Boolean)
      names.forEach(n => items.push({ name: n, quantity: '1', unit: '份' }))
    }
    const now = new Date()
    const date = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}`
    const time = `${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}`
    tags.push('shopping')
    extractedData.shopping = { items, store }
    sideEffects.shoppingRecord = {
      date, time,
      store: store || '商店',
      items,
      source: 'voice',
      rawText: t,
    }
  }

  // 3) 行为活动：匹配事程关键词
  const behaviorKeywords = ['吃', '喝', '睡', '运动', '散步', '跑步', '洗澡', '洗漱', '起床', '吃药', '吃饭', '午饭', '早饭', '晚饭', '喝水']
  const matchedKeyword = behaviorKeywords.find(kw => t.includes(kw))
  if (matchedKeyword) {
    tags.push('behavior')
    extractedData.behavior = { behavior: matchedKeyword, category: '健康', duration: undefined }
  }

  // 4) 日常事件：默认标签（几乎所有话语都会有这个基础标签）
  //    但如果话语只是单纯的行为/购物（没有其他动作），不重复加 event
  //    如"喝水"只有 behavior，"回家放钥匙"有 event + item
  const hasOtherAction = tags.length > 0
  // 检测是否有"事件性"动词（回家、出门、拿快递、到、去等）
  const eventKeywords = ['回家', '出门', '下班', '到', '去', '拿', '取', '送', '接', '回', '来', '走']
  const hasEventKeyword = eventKeywords.some(kw => t.includes(kw))
  if (hasEventKeyword || !hasOtherAction) {
    tags.push('event')
    extractedData.event = { event: t, location: undefined }
  }

  // 5) 事程识别：AI判断用户是在"汇报已完成"还是"设置提醒"
  //    - 完成时/进行时 → 匹配已有事程（标记完成）
  //    - 将来时/计划时 → 创建新事程（待办）
  //    支持一句话拆多个事程

  const reminderKeywords = ['记得', '别忘了', '提醒我', '要记得', '一定要', '需要', '要做', '得去', '准备']
  const mustDoKeywords = ['必做', '必须', '一定', '务必']
  // 完成时 / 进行时信号词 → 表示正在做或已经做完
  const completedKeywords = [
    '正在', '在', '刚', '刚刚', '已经', '过了', '完了', '吃完了', '喝完了',
    '吃过了', '喝过了', '做完了', '了',
  ]
  // 明确的过去式后缀
  const pastSuffixes = ['完了', '过了', '好了', '完', '过']

  // 智能判断一句话是"创建提醒"还是"完成事程"
  const detectAgendaIntent = (text: string): 'create' | 'complete' | 'none' => {
    const s = text.trim()
    if (s.length === 0) return 'none'

    // 1. 明显提醒词 → 创建
    if (reminderKeywords.some(kw => s.includes(kw))) return 'create'

    // 2. "明天"/"下周"等明确未来时间 → 创建
    if (s.includes('明天') || s.includes('下周') || s.includes('下次') || s.includes('以后')) return 'create'

    // 3. 明确完成时 → 完成
    const completedPatterns = [
      /刚[做吃吃喝喝完]完/,    // 刚做完、刚吃完
      /已经[做吃吃喝喝]完?了?/, // 已经吃完、已经做完了
      /正在[做吃吃喝喝运动走跑]/, // 正在吃、正在运动
      /[吃喝][完过]了?/,       // 吃完了、喝过
    ]
    if (completedPatterns.some(p => p.test(s))) return 'complete'

    // 4. 句子结尾是"了" 且 没有时间词 → 完成
    if (s.endsWith('了') && !s.match(/点|分|小时|分钟/)) return 'complete'

    // 5. 有明确时间 + 动作 → 需要判断时间是否已过
    const timeMatch = s.match(/(\d{1,2})[:：点](\d{2})?分?/)
    if (timeMatch) {
      const hour = Number(timeMatch[1])
      const minute = timeMatch[2] ? Number(timeMatch[2]) : 0
      const now = new Date()
      const currentHour = now.getHours()
      const currentMinute = now.getMinutes()

      // 如果是"下午/晚上 + 小时<12"，加12
      let finalHour = hour
      if ((s.includes('下午') || s.includes('晚上')) && hour < 12) finalHour = hour + 12

      const targetMinutes = finalHour * 60 + minute
      const currentMinutes = currentHour * 60 + currentMinute

      // 时间已过（2小时内算刚做完）→ 完成
      if (targetMinutes < currentMinutes && currentMinutes - targetMinutes < 180) {
        return 'complete'
      }
      // 时间还没到 → 创建
      if (targetMinutes > currentMinutes) {
        return 'create'
      }
    }

    // 6. 有"要/得"等计划词 → 创建
    if (/^要[做吃喝运动去]/.test(s) || /得[做吃喝运动去]/.test(s)) return 'create'

    // 7. 单纯的行为词（如"喝水"、"吃药"、"吃饭"）→ 默认视为完成（陈述事实）
    //    由调用方决定是否匹配已有事程
    return 'complete'
  }

  // 单段事程解析（只解析时间+内容，不判断意图）
  const parseAgendaSegment = (seg: string): { time: string; content: string; isMustDo: boolean } | null => {
    const s = seg.trim()
    if (s.length === 0) return null

    const segIsMustDo = mustDoKeywords.some(kw => s.includes(kw))

    let segTime = ''
    const hhmmMatch = s.match(/(\d{1,2})[:：](\d{2})/)
    const pointMatch = s.match(/(\d{1,2})点(?:(\d{1,2})分)?/)
    const periodMatch = s.match(/(早上|上午|中午|下午|晚上|凌晨)(\d{1,2})?(?:点)?(?:(\d{1,2})分)?/)

    if (hhmmMatch) {
      segTime = `${String(Number(hhmmMatch[1])).padStart(2, '0')}:${hhmmMatch[2]}`
    } else if (pointMatch) {
      const hour = Number(pointMatch[1])
      const min = pointMatch[2] ? Number(pointMatch[2]) : 0
      let finalHour = hour
      if ((s.includes('下午') || s.includes('晚上')) && hour < 12) finalHour = hour + 12
      if (s.includes('凌晨') && hour === 12) finalHour = 0
      segTime = `${String(finalHour).padStart(2, '0')}:${String(min).padStart(2, '0')}`
    } else if (periodMatch) {
      const period = periodMatch[1]
      const hour = periodMatch[2] ? Number(periodMatch[2]) : null
      const min = periodMatch[3] ? Number(periodMatch[3]) : 0
      if (hour !== null) {
        let finalHour = hour
        if ((period === '下午' || period === '晚上') && hour < 12) finalHour = hour + 12
        if (period === '凌晨' && hour === 12) finalHour = 0
        segTime = `${String(finalHour).padStart(2, '0')}:${String(min).padStart(2, '0')}`
      }
    }

    // 提取事程核心内容
    let segContent = s
      .replace(/^(记得|别忘了|提醒我|要记得|一定要|需要|要做|得去|准备)[，, ]?/, '')
      .replace(/^(正在|刚|刚刚|已经|在)/, '')
      .replace(/(早上|上午|中午|下午|晚上|凌晨)?\d{1,2}点(?:\d{1,2}分)?[钟]?[，, ]?/, '')
      .replace(/\d{1,2}[:：]\d{2}[，, ]?/, '')
      .replace(/[（(]?必做[）)]?/, '')
      .replace(/[完过了好]$/, '')
      .trim()
    segContent = segContent.replace(/^(去|要|做|得)/, '').trim()

    if (segContent.length === 0) return null

    const now = new Date()
    const defaultTime = segTime || `${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}`
    return { time: defaultTime, content: segContent, isMustDo: segIsMustDo }
  }

  // 判断整句话意图
  const overallIntent = detectAgendaIntent(t)

  if (overallIntent === 'create') {
    // 创建事程：尝试拆分多个
    const segments = t.split(/[，、；。]|还有|然后|再|和/g).map(s => s.trim()).filter(Boolean)
    if (segments.length > 1) {
      const agendas: Omit<AgendaItem, 'id' | 'date'>[] = []
      let inheritCreate = false
      for (const seg of segments) {
        const segIntent = inheritCreate || detectAgendaIntent(seg) === 'create'
        if (segIntent) {
          const result = parseAgendaSegment(seg)
          if (result) {
            agendas.push({
              ...result,
              status: 'pending',
              remainingTime: '今日提醒',
            })
            inheritCreate = true
          }
        }
      }
      if (agendas.length > 1) {
        sideEffects.agendaList = agendas
      } else if (agendas.length === 1) {
        sideEffects.agenda = agendas[0]
      }
    } else {
      const result = parseAgendaSegment(t)
      if (result) {
        sideEffects.agenda = {
          ...result,
          status: 'pending',
          remainingTime: '今日提醒',
        }
      }
    }
  }
  // complete 意图不在 parseVoiceText 里处理，留给 submitVoiceRecord 去匹配已有事程

  // 保证至少有一个类型
  if (tags.length === 0) {
    tags.push('event')
    extractedData.event = { event: t, location: undefined }
  }

  return { tags, extractedData, sideEffects }
}

// ===== 生成 ID =====
const genId = () => Date.now().toString() + Math.floor(Math.random() * 1000).toString()

// 当前时间 HH:MM
const nowTime = () => {
  const n = new Date()
  return `${String(n.getHours()).padStart(2, '0')}:${String(n.getMinutes()).padStart(2, '0')}`
}

// ===== Store 定义 =====
interface AppState {
  // 导航
  activeTab: 'home' | 'habits' | 'ask' | 'profile'
  setActiveTab: (tab: 'home' | 'habits' | 'ask' | 'profile') => void
  habitsActiveTab: 'agenda' | 'stats'
  setHabitsActiveTab: (tab: 'agenda' | 'stats') => void

  // 事程
  agendaItems: AgendaItem[]
  addAgenda: (agenda: Omit<AgendaItem, 'id' | 'status' | 'remainingTime'> & { status?: AgendaStatus; remainingTime?: string }) => void
  updateAgenda: (id: string, patch: Partial<AgendaItem>) => void
  completeAgenda: (id: string) => void
  postponeAgenda: (id: string, minutes: number) => void
  deleteAgenda: (id: string) => void

  agendaRecommendations: AgendaRecommendation[]
  generateAgendaRecommendations: () => void
  applyRecommendation: (id: string) => void
  dismissRecommendation: (id: string) => void

  // 时间线
  timelineRecords: TimelineRecord[]
  addTimelineRecord: (record: Omit<TimelineRecord, 'id'>) => string
  // 修改某条时间线记录的标签（用户手动调整）
  updateRecordTags: (id: string, tags: string[]) => void
  // 添加补充记录
  addNoteToRecord: (id: string, content: string) => void
  // 删除补充记录
  deleteNoteFromRecord: (recordId: string, noteId: string) => void
  // 标签偏好记忆：用户修改过的话语关键词 → 偏好标签集合
  tagPreferences: Record<string, string[]>
  setTagPreference: (key: string, tags: string[]) => void

  // ===== 自定义标签管理 =====
  customTags: TagDef[]
  addCustomTag: (tag: Omit<TagDef, 'id' | 'system' | 'createdAt' | 'usageCount'>) => { success: boolean; error?: string }
  deleteCustomTag: (id: string) => void
  renameCustomTag: (id: string, name: string) => { success: boolean; error?: string }
  // 获取全部标签（系统 + 自定义），含使用次数
  getAllTagsWithStats: () => Array<TagDef & { count: number; lastUsed: string }>
  // 按标签ID筛选时间线记录
  getRecordsByTag: (tagId: string) => TimelineRecord[]
  // 根据标签ID获取标签定义（找不到返回 null，表示已删除标签）
  getTagDef: (tagId: string) => TagDef | null

  // 购物
  shoppingRecords: ShoppingRecord[]
  addShoppingRecord: (record: Omit<ShoppingRecord, 'id'>) => void

  // 物品
  items: ItemRecord[]
  addItem: (item: Omit<ItemRecord, 'id' | 'locationHistory' | 'lastUpdate'> & { locationHistory?: LocationHistory[] }) => void
  updateItemLocation: (name: string, location: string) => void

  // 语音录入：综合处理（一句话 → 多标签识别 → 单条时间线记录 → 按需同步购物/物品/事程）
  submitVoiceRecord: (text: string) => { timelineId: string; tags: string[]; extractedData: Partial<Record<string, any>>; agendaCreated: number; isAgendaCreation: boolean; needsConfirm: boolean }

  // 常用事程
  frequentAgendas: typeof mockFrequentAgendas

  // 根据内容关键词推断历史平均时间
  inferAgendaTimeByContent: (content: string) => string | null

  // 基于常识的默认时间推荐
  inferAgendaTimeByCommonSense: (content: string) => string | null

  // 根据内容自动识别图标
  autoDetectIcon: (content: string) => string

  // ===== 待确认事程 =====
  pendingAgendaConfirm: PendingAgendaItem[]
  addPendingAgenda: (items: PendingAgendaItem[]) => void
  confirmPendingAgenda: (ids: string[]) => void
  rejectPendingAgenda: (ids: string[]) => void
  clearPendingAgenda: () => void
  updatePendingAgendaTime: (id: string, time: string) => void

  // ===== 到时提醒 =====
  activeReminder: AgendaItem | null
  dismissReminder: () => void
  checkAgendaReminders: () => AgendaItem | null
}

export const useAppStore = create<AppState>((set, get) => ({
  // ===== 导航 =====
  activeTab: 'home',
  setActiveTab: (tab) => set({ activeTab: tab }),
  habitsActiveTab: 'agenda',
  setHabitsActiveTab: (tab) => set({ habitsActiveTab: tab }),

  // ===== 事程 =====
  agendaItems: mockAgendaItems as AgendaItem[],
  addAgenda: (agenda) => {
    const now = new Date()
    const todayStr = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}`
    set((state) => ({
      agendaItems: [
        ...state.agendaItems,
        {
          ...agenda,
          id: genId(),
          date: agenda.date ?? todayStr,
          status: agenda.status ?? 'pending',
          remainingTime: agenda.remainingTime ?? '未到时间',
        },
      ],
    }))
  },
  updateAgenda: (id, patch) => set((state) => ({
    agendaItems: state.agendaItems.map(a => a.id === id ? { ...a, ...patch } : a),
  })),
  completeAgenda: (id) => set((state) => ({
    agendaItems: state.agendaItems.map(a =>
      a.id === id ? { ...a, status: 'completed' as AgendaStatus, remainingTime: undefined } : a
    ),
  })),
  postponeAgenda: (id, minutes) => set((state) => ({
    agendaItems: state.agendaItems.map(a =>
      a.id === id
        ? { ...a, status: 'postponed' as AgendaStatus, remainingTime: `推迟${minutes}分钟` }
        : a
    ),
  })),
  deleteAgenda: (id) => set((state) => ({
    agendaItems: state.agendaItems.filter(a => a.id !== id),
  })),

  // ===== AI智能事程推荐 =====
  agendaRecommendations: [] as AgendaRecommendation[],

  // ===== 时间线 =====
  timelineRecords: mockTimelineRecords as TimelineRecord[],
  addTimelineRecord: (record) => {
    const id = genId()
    const now = new Date()
    const todayStr = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}`
    const fullRecord = { ...record, id, date: record.date ?? todayStr }
    set((state) => ({
      timelineRecords: [fullRecord, ...state.timelineRecords],
    }))
    // 自动维护标签 usageCount
    const st = get()
    record.tags.forEach((tagId) => {
      const sysTag = SYSTEM_TAGS.find(t => t.id === tagId)
      if (sysTag) {
        sysTag.usageCount += 1
      } else {
        const custom = st.customTags.find(t => t.id === tagId)
        if (custom) custom.usageCount += 1
      }
    })
    return id
  },
  updateRecordTags: (id, tags) => {
    const st = get()
    const oldRecord = st.timelineRecords.find(r => r.id === id)
    // 计算标签变化：旧标签 -1，新标签 +1
    if (oldRecord) {
      const oldTags = oldRecord.tags
      const removed = oldTags.filter(t => !tags.includes(t))
      const added = tags.filter(t => !oldTags.includes(t))
      // 这里不直接改 SYSTEM_TAGS 的 usageCount（系统标签计数动态从 timelineRecords 计算）
      // 自定义标签 usageCount 也不直接改，getAllTagsWithStats 会动态计算
      // 此处仅更新记录本身
    }
    set((state) => ({
      timelineRecords: state.timelineRecords.map(r =>
        r.id === id ? { ...r, tags } : r
      ),
    }))
  },
  addNoteToRecord: (id, content) => {
    const now = new Date()
    const timeStr = `${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}`
    set((state) => ({
      timelineRecords: state.timelineRecords.map(r =>
        r.id === id
          ? {
              ...r,
              notes: [
                ...r.notes,
                { id: genId(), content, createdAt: timeStr },
              ],
            }
          : r
      ),
    }))
  },
  deleteNoteFromRecord: (recordId, noteId) => set((state) => ({
    timelineRecords: state.timelineRecords.map(r =>
      r.id === recordId
        ? { ...r, notes: r.notes.filter(n => n.id !== noteId) }
        : r
    ),
  })),
  // 标签偏好记忆：空对象，用户修改标签时逐步填充
  tagPreferences: {},
  setTagPreference: (key, tags) => set((state) => ({
    tagPreferences: { ...state.tagPreferences, [key]: tags },
  })),

  // ===== 自定义标签管理 =====
  customTags: [
    { id: 'custom_sport',  name: '运动', color: 'purple', icon: '🏃', system: false, createdAt: '2026-06-20', usageCount: 0 },
    { id: 'custom_medical', name: '就医', color: 'danger', icon: '💊', system: false, createdAt: '2026-06-25', usageCount: 0 },
    { id: 'custom_family',  name: '陪孙子', color: 'success', icon: '👨‍👩‍👦', system: false, createdAt: '2026-06-28', usageCount: 0 },
  ],
  addCustomTag: (tag) => {
    const st = get()
    if (st.customTags.length >= MAX_CUSTOM_TAGS) {
      return { success: false, error: `自定义标签最多 ${MAX_CUSTOM_TAGS} 个` }
    }
    // 名称唯一校验
    const allNames = [...SYSTEM_TAGS.map(t => t.name), ...st.customTags.map(t => t.name)]
    if (allNames.includes(tag.name)) {
      return { success: false, error: '标签名已存在' }
    }
    const newTag: TagDef = {
      ...tag,
      id: genId(),
      system: false,
      createdAt: new Date().toISOString().split('T')[0],
      usageCount: 0,
    }
    set((state) => ({ customTags: [...state.customTags, newTag] }))
    return { success: true }
  },
  deleteCustomTag: (id) => set((state) => ({
    customTags: state.customTags.filter(t => t.id !== id),
    // 注意：历史记录中的 tags 数组中该标签ID保留，渲染时显示为"已删除标签"
  })),
  renameCustomTag: (id, name) => {
    // 名称唯一校验
    const st = get()
    const allNames = [...SYSTEM_TAGS.map(t => t.name), ...st.customTags.filter(t => t.id !== id).map(t => t.name)]
    if (allNames.includes(name)) {
      return { success: false, error: '标签名已存在' }
    }
    set((state) => ({
      customTags: state.customTags.map(t => t.id === id ? { ...t, name } : t),
    }))
    return { success: true }
  },
  getAllTagsWithStats: () => {
    const st = get()
    const allTags: Array<TagDef & { count: number; lastUsed: string }> = []
    // 统计每个标签的使用次数和最近使用时间
    const computeStats = (tagId: string) => {
      const records = st.timelineRecords.filter(r => r.tags.includes(tagId))
      return {
        count: records.length,
        lastUsed: records.length > 0 ? records[0].time : '未使用',
      }
    }
    // 系统标签
    SYSTEM_TAGS.forEach(t => {
      const stats = computeStats(t.id)
      allTags.push({ ...t, ...stats, usageCount: stats.count })
    })
    // 自定义标签
    st.customTags.forEach(t => {
      const stats = computeStats(t.id)
      allTags.push({ ...t, ...stats, usageCount: stats.count })
    })
    // 按使用次数降序
    return allTags.sort((a, b) => b.count - a.count)
  },
  getRecordsByTag: (tagId) => {
    const st = get()
    return st.timelineRecords.filter(r => r.tags.includes(tagId))
  },
  getTagDef: (tagId) => {
    const st = get()
    const sysTag = SYSTEM_TAGS.find(t => t.id === tagId)
    if (sysTag) return sysTag
    return st.customTags.find(t => t.id === tagId) ?? null
  },

  // ===== 购物 =====
  shoppingRecords: mockShoppingRecords as ShoppingRecord[],
  addShoppingRecord: (record) => set((state) => ({
    shoppingRecords: [{ ...record, id: genId() }, ...state.shoppingRecords],
  })),

  // ===== 物品 =====
  items: [
    { id: '1', icon: '🔑', name: '钥匙', location: '门口鞋柜', locationHistory: [{ location: '门口鞋柜', count: 42, percent: 75 }, { location: '茶几', count: 8, percent: 14 }, { location: '裤子口袋', count: 6, percent: 11 }], source: 'voice', lastUpdate: '今天 09:30' },
    { id: '2', icon: '📋', name: '护照', location: '衣柜二层', locationHistory: [{ location: '衣柜二层', count: 15, percent: 88 }, { location: '书房抽屉', count: 2, percent: 12 }], source: 'manual', lastUpdate: '2026-06-15' },
    { id: '3', icon: '💳', name: '身份证', location: '抽屉里', locationHistory: [{ location: '抽屉里', count: 20, percent: 65 }, { location: '钱包', count: 11, percent: 35 }], source: 'voice', lastUpdate: '昨天 14:00' },
    { id: '4', icon: '📱', name: '手机', location: '床头柜上', locationHistory: [{ location: '床头柜上', count: 30, percent: 50 }, { location: '沙发', count: 18, percent: 30 }, { location: '餐桌', count: 12, percent: 20 }], source: 'voice', lastUpdate: '今天 10:15' },
    { id: '5', icon: '🎧', name: '耳机', location: '电脑桌旁', locationHistory: [{ location: '电脑桌旁', count: 25, percent: 80 }, { location: '背包', count: 5, percent: 16 }, { location: '床头柜', count: 1, percent: 4 }], source: 'manual', lastUpdate: '2026-06-28' },
    { id: '6', icon: '🔧', name: '工具箱', location: '阳台储物柜', locationHistory: [{ location: '阳台储物柜', count: 28, percent: 100 }], source: 'manual', lastUpdate: '2026-06-20' },
  ],
  addItem: (item) => set((state) => ({
    items: [
      ...state.items,
      {
        ...item,
        id: genId(),
        locationHistory: item.locationHistory ?? [{ location: item.location, count: 1, percent: 100 }],
        lastUpdate: '刚刚',
      },
    ],
  })),
  updateItemLocation: (name, location) => set((state) => ({
    items: state.items.map(it => {
      if (it.name !== name) return it
      // 更新位置历史：把新位置加入或累加
      const existing = it.locationHistory.find(h => h.location === location)
      let newHistory
      if (existing) {
        newHistory = it.locationHistory.map(h =>
          h.location === location ? { ...h, count: h.count + 1 } : h
        )
      } else {
        newHistory = [{ location, count: 1 }, ...it.locationHistory]
      }
      // 重新计算百分比
      const total = newHistory.reduce((s, h) => s + h.count, 0)
      newHistory = newHistory.map(h => ({ ...h, percent: Math.round((h.count / total) * 100) }))
        .sort((a, b) => b.count - a.count)
      return {
        ...it,
        location,
        locationHistory: newHistory,
        source: 'voice' as const,
        lastUpdate: '刚刚',
      }
    }),
  })),

  // ===== 综合语音录入（单条记录 + 多标签 + 偏好查询 + 待确认事程） =====
  submitVoiceRecord: (text) => {
    const t = text.trim()
    const time = nowTime()
    const now = new Date()
    const todayStr = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}`

    // 1) 智能解析多标签
    const parsed = parseVoiceText(t)
    let tags = parsed.tags
    let extractedData = parsed.extractedData

    // 2) 查询用户标签偏好
    let prefKey: string | undefined
    if (extractedData.item?.itemName) prefKey = `item:${extractedData.item.itemName}`
    else if (extractedData.shopping?.store) prefKey = `shopping:${extractedData.shopping.store}`
    else if (extractedData.behavior?.behavior) prefKey = `behavior:${extractedData.behavior.behavior}`

    const state = get()
    if (prefKey && state.tagPreferences[prefKey]) {
      tags = state.tagPreferences[prefKey]
    }

    // 3) 事程处理：新建 or 匹配完成
    let matchedAgenda: string | undefined
    let recordStatus: 'matched' | 'unmatched' = 'unmatched'
    let agendaCreatedCount = 0
    let isAgendaCreation = false
    let needsConfirm = false

    const hasAgendaList = parsed.sideEffects?.agendaList && parsed.sideEffects.agendaList.length > 0
    const hasSingleAgenda = !!parsed.sideEffects?.agenda

    // 判断时间是否是"默认当前时间"（即用户没说具体时间）
    const defaultTimeStr = `${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}`
    const isDefaultTime = (t: string) => t === defaultTimeStr

    // 智能推断时间函数，返回时间和来源
    const smartTime = (ag: { time: string; content: string }): { time: string; source: PendingAgendaItem['timeSource'] } => {
      if (!isDefaultTime(ag.time)) return { time: ag.time, source: 'user-specified' }
      const fromHistory = get().inferAgendaTimeByContent(ag.content)
      if (fromHistory) return { time: fromHistory, source: 'history' }
      const fromCommon = get().inferAgendaTimeByCommonSense(ag.content)
      if (fromCommon) return { time: fromCommon, source: 'common-sense' }
      return { time: ag.time, source: 'current' }
    }

    if (hasAgendaList) {
      // 多事程：加入待确认队列
      isAgendaCreation = true
      needsConfirm = true
      const list = parsed.sideEffects!.agendaList!
      const pendingList: PendingAgendaItem[] = []
      for (const ag of list) {
        const { time: finalTime, source } = smartTime(ag)
        pendingList.push({
          id: genId(),
          content: ag.content,
          time: finalTime,
          isMustDo: ag.isMustDo,
          timeSource: source,
        })
        agendaCreatedCount++
      }
      get().addPendingAgenda(pendingList)
      matchedAgenda = `${pendingList[0].time}${pendingList[0].content}${pendingList.length > 1 ? ` 等${pendingList.length}项` : ''}`
    } else if (hasSingleAgenda) {
      // 单事程：加入待确认队列
      isAgendaCreation = true
      needsConfirm = true
      const ag = parsed.sideEffects!.agenda!
      const { time: finalTime, source } = smartTime(ag)
      const pendingItem: PendingAgendaItem = {
        id: genId(),
        content: ag.content,
        time: finalTime,
        isMustDo: ag.isMustDo,
        timeSource: source,
      }
      get().addPendingAgenda([pendingItem])
      agendaCreatedCount = 1
      matchedAgenda = `${finalTime}${ag.content}`
    } else {
      // 没有识别出新建事程 → 尝试匹配已有事程（表示完成了）
      let matchKeyword = ''
      if (extractedData.behavior?.behavior) {
        matchKeyword = extractedData.behavior.behavior
      } else if (extractedData.event?.event) {
        const eventText = extractedData.event.event as string
        const actionMatch = eventText.match(/(吃|喝|运动|散步|跑步|拿|取|买|去|回)[\u4e00-\u9fa5]{0,3}/)
        if (actionMatch) matchKeyword = actionMatch[0]
      }

      if (matchKeyword) {
        const matched = get().agendaItems.find(a =>
          a.date === todayStr && a.status === 'pending' && a.content.includes(matchKeyword)
        )
        if (matched) {
          matchedAgenda = `${matched.time}${matched.content}`
          recordStatus = 'matched'
          get().completeAgenda(matched.id)
        }
      }
    }

    // 4) 写入单条时间线记录（多标签）
    const timelineId = get().addTimelineRecord({
      time,
      content: t,
      matchedAgenda,
      status: recordStatus,
      tags,
      extractedData,
    })

    // 5) 副作用：同步购物记录
    if (parsed.sideEffects?.shoppingRecord) {
      get().addShoppingRecord(parsed.sideEffects.shoppingRecord)
    }
    // 6) 副作用：同步物品位置
    if (parsed.sideEffects?.itemUpdate) {
      get().updateItemLocation(parsed.sideEffects.itemUpdate.name, parsed.sideEffects.itemUpdate.location)
    }

    return { timelineId, tags, extractedData, agendaCreated: agendaCreatedCount, isAgendaCreation, needsConfirm }
  },

  // ===== 常用事程 =====
  frequentAgendas: mockFrequentAgendas,

  // ===== 辅助：根据内容关键词推断历史平均时间 =====
  inferAgendaTimeByContent: (content: string): string | null => {
    const st = get()
    const records = st.timelineRecords.filter(r => r.tags.includes('behavior'))
    if (records.length === 0) return null

    let keyword = ''
    const behaviorMatch = content.match(/(吃药|吃饭|早饭|午饭|晚饭|运动|散步|喝水|睡觉|起床|洗漱)/)
    if (behaviorMatch) {
      keyword = behaviorMatch[1]
    } else {
      keyword = content.slice(0, 2)
    }

    const matchedRecords = records.filter(r => r.content.includes(keyword))
    if (matchedRecords.length === 0) return null

    let totalMinutes = 0
    for (const r of matchedRecords) {
      const [h, m] = r.time.split(':').map(Number)
      totalMinutes += h * 60 + m
    }
    const avgMinutes = Math.round(totalMinutes / matchedRecords.length)
    const avgHour = Math.floor(avgMinutes / 60)
    const avgMin = avgMinutes % 60
    return `${String(avgHour).padStart(2, '0')}:${String(avgMin).padStart(2, '0')}`
  },

  // ===== 辅助：基于常识的默认时间推荐 =====
  inferAgendaTimeByCommonSense: (content: string): string | null => {
    const s = content
    // 早餐相关
    if (/早饭|早餐/.test(s)) return '07:30'
    // 午餐相关
    if (/午饭|午餐|吃中饭/.test(s)) return '12:00'
    // 晚餐相关
    if (/晚饭|晚餐|吃晚饭/.test(s)) return '18:00'
    // 吃药（默认饭后）
    if (/吃药/.test(s)) return '08:00'
    // 起床
    if (/起床/.test(s)) return '07:00'
    // 睡觉/休息
    if (/睡觉|休息/.test(s)) return '22:00'
    // 运动/散步（默认傍晚）
    if (/运动|散步|跑步|锻炼/.test(s)) return '18:30'
    // 喝水（当前时间往后推1小时）
    if (/喝水/.test(s)) {
      const now = new Date()
      const h = Math.min(23, now.getHours() + 1)
      return `${String(h).padStart(2, '0')}:00`
    }
    // 洗漱
    if (/洗漱|洗脸|刷牙/.test(s)) return '07:15'
    return null
  },

  // ===== 根据内容自动识别图标 =====
  autoDetectIcon: (content: string): string => {
    const s = content
    if (/药/.test(s)) return '💊'
    if (/饭|餐|食/.test(s)) return '🍚'
    if (/水|喝/.test(s)) return '💧'
    if (/运动|散步|跑步|锻炼|走/.test(s)) return '🏃'
    if (/睡|休息|午休/.test(s)) return '🛏'
    if (/读|看|学|书/.test(s)) return '📖'
    if (/买|购|超市/.test(s)) return '🛒'
    if (/洗|清洁|打扫/.test(s)) return '🧹'
    if (/车|出行|出发|出差|飞/.test(s)) return '✈️'
    if (/会|开|办公|工作/.test(s)) return '📋'
    return '📋'
  },

  // ===== AI智能事程推荐 =====
  generateAgendaRecommendations: () => {
    const st = get()
    const now = new Date()
    const todayStr = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}`

    const todayAgendas = st.agendaItems.filter(a => a.date === todayStr)
    const todayContents = todayAgendas.map(a => a.content)
    const addedContents = new Set<string>()
    const newAgendas: AgendaItem[] = []

    // 1. 从历史记录中提取高频行为
    const behaviorRecords = st.timelineRecords.filter(r => r.tags.includes('behavior'))
    const behaviorCounts: Record<string, { count: number; times: number[] }> = {}

    for (const record of behaviorRecords) {
      const content = record.content
      const keywordMatch = content.match(/(吃药|吃饭|早饭|午饭|晚饭|运动|散步|跑步|喝水|睡觉|起床|洗漱|阅读|锻炼)/)
      let keyword = keywordMatch ? keywordMatch[1] : content.slice(0, 2)
      
      if (!behaviorCounts[keyword]) {
        behaviorCounts[keyword] = { count: 0, times: [] }
      }
      behaviorCounts[keyword].count++
      
      const [h, m] = record.time.split(':').map(Number)
      behaviorCounts[keyword].times.push(h * 60 + m)
    }

    // 筛选频率 >= 3次的行为
    const highFreqBehaviors = Object.entries(behaviorCounts)
      .filter(([, data]) => data.count >= 3)
      .sort((a, b) => b[1].count - a[1].count)

    for (const [keyword, data] of highFreqBehaviors) {
      if (todayContents.some(c => c.includes(keyword)) || addedContents.has(keyword)) continue
      
      const avgMinutes = Math.round(data.times.reduce((a, b) => a + b, 0) / data.times.length)
      const avgHour = Math.floor(avgMinutes / 60)
      const avgMin = avgMinutes % 60
      const time = `${String(avgHour).padStart(2, '0')}:${String(avgMin).padStart(2, '0')}`

      newAgendas.push({
        id: genId(),
        date: todayStr,
        time,
        content: keyword,
        isMustDo: keyword.includes('药'),
        status: 'pending',
        remainingTime: '今日提醒',
        icon: st.autoDetectIcon(keyword),
        category: keyword.includes('药') ? '必做' : keyword.includes('饭') ? '重要' : '普通',
        isHighFrequency: true,
      })
      addedContents.add(keyword)
    }

    if (newAgendas.length > 0) {
      set((state) => ({
        agendaItems: [...state.agendaItems, ...newAgendas.slice(0, 5)],
      }))
    }
  },

  // ===== 待确认事程 =====
  pendingAgendaConfirm: [],
  addPendingAgenda: (items) => set((state) => ({
    pendingAgendaConfirm: [...state.pendingAgendaConfirm, ...items],
  })),
  confirmPendingAgenda: (ids) => {
    const st = get()
    const now = new Date()
    const todayStr = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}`
    const toConfirm = st.pendingAgendaConfirm.filter(p => ids.includes(p.id))
    for (const item of toConfirm) {
      st.addAgenda({
        content: item.content,
        time: item.time,
        isMustDo: item.isMustDo,
        date: todayStr,
        status: 'pending',
        remainingTime: '今日提醒',
      })
    }
    set((state) => ({
      pendingAgendaConfirm: state.pendingAgendaConfirm.filter(p => !ids.includes(p.id)),
    }))
  },
  rejectPendingAgenda: (ids) => set((state) => ({
    pendingAgendaConfirm: state.pendingAgendaConfirm.filter(p => !ids.includes(p.id)),
  })),
  clearPendingAgenda: () => set({ pendingAgendaConfirm: [] }),
  updatePendingAgendaTime: (id, time) => set((state) => ({
    pendingAgendaConfirm: state.pendingAgendaConfirm.map(p =>
      p.id === id ? { ...p, time, timeSource: 'user-specified' } : p
    ),
  })),

  // ===== 到时提醒 =====
  activeReminder: null,
  dismissReminder: () => set({ activeReminder: null }),
  checkAgendaReminders: () => {
    const st = get()
    const now = new Date()
    const todayStr = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}`
    const currentTime = `${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}`

    // 找到当前时间到点的待办事程
    const due = st.agendaItems.find(a =>
      a.date === todayStr &&
      a.status === 'pending' &&
      a.time === currentTime
    )

    if (due && !st.activeReminder) {
      set({ activeReminder: due })
      return due
    }
    return null
  },
}))

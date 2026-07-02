import { create } from 'zustand'
import {
  mockTimelineRecords,
  mockAgendaItems,
  mockShoppingRecords,
  mockFrequentAgendas,
} from '../data/mockData'

// ===== 类型定义 =====
export type TimelineType = 'behavior' | 'item' | 'shopping' | 'event'
export type AgendaStatus = 'pending' | 'completed' | 'postponed'

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

export interface TimelineRecord {
  id: string
  time: string
  content: string
  matchedAgenda?: string
  status: 'matched' | 'unmatched'
  // 标签ID数组（兼容系统标签 + 自定义标签）
  // 系统4个: 'behavior' | 'item' | 'shopping' | 'event'
  // 自定义: genId() 生成的ID
  tags: string[]
  // 每种类型对应的结构化抽取数据 { item: {...}, event: {...} }
  extractedData: Partial<Record<string, any>>
}

export interface AgendaItem {
  id: string
  time: string
  content: string
  note?: string
  isMustDo: boolean
  status: AgendaStatus
  remainingTime?: string
  category?: string
  icon?: string
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
  }
} {
  const t = text.trim()
  const tags: string[] = []
  const extractedData: Partial<Record<string, any>> = {}
  let sideEffects: {
    shoppingRecord?: Omit<ShoppingRecord, 'id'>
    itemUpdate?: { name: string; location: string }
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

  // 时间线
  timelineRecords: TimelineRecord[]
  addTimelineRecord: (record: Omit<TimelineRecord, 'id'>) => string
  // 修改某条时间线记录的标签（用户手动调整）
  updateRecordTags: (id: string, tags: string[]) => void
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

  // 语音录入：综合处理（一句话 → 多标签识别 → 单条时间线记录 → 按需同步购物/物品）
  submitVoiceRecord: (text: string) => { timelineId: string; tags: string[]; extractedData: Partial<Record<string, any>> }

  // 常用事程
  frequentAgendas: typeof mockFrequentAgendas
}

export const useAppStore = create<AppState>((set, get) => ({
  // ===== 导航 =====
  activeTab: 'home',
  setActiveTab: (tab) => set({ activeTab: tab }),
  habitsActiveTab: 'agenda',
  setHabitsActiveTab: (tab) => set({ habitsActiveTab: tab }),

  // ===== 事程 =====
  agendaItems: mockAgendaItems as AgendaItem[],
  addAgenda: (agenda) => set((state) => ({
    agendaItems: [
      ...state.agendaItems,
      {
        ...agenda,
        id: genId(),
        status: agenda.status ?? 'pending',
        remainingTime: agenda.remainingTime ?? '未到时间',
      },
    ],
  })),
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

  // ===== 时间线 =====
  timelineRecords: mockTimelineRecords as TimelineRecord[],
  addTimelineRecord: (record) => {
    const id = genId()
    set((state) => ({
      timelineRecords: [{ ...record, id }, ...state.timelineRecords],
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

  // ===== 综合语音录入（单条记录 + 多标签 + 偏好查询） =====
  submitVoiceRecord: (text) => {
    const t = text.trim()
    const time = nowTime()

    // 1) 智能解析多标签
    const parsed = parseVoiceText(t)
    let tags = parsed.tags
    let extractedData = parsed.extractedData

    // 2) 查询用户标签偏好：用话语的关键特征作为key
    //    key 提取规则：取话语中命中的核心关键词（物品名/商店名/行为词）
    let prefKey: string | undefined
    if (extractedData.item?.itemName) prefKey = `item:${extractedData.item.itemName}`
    else if (extractedData.shopping?.store) prefKey = `shopping:${extractedData.shopping.store}`
    else if (extractedData.behavior?.behavior) prefKey = `behavior:${extractedData.behavior.behavior}`

    const state = get()
    if (prefKey && state.tagPreferences[prefKey]) {
      // 用户之前修改过同类话语的标签 → 应用偏好
      tags = state.tagPreferences[prefKey]
    }

    // 3) 尝试匹配事程（基于行为关键词）
    let matchedAgenda: string | undefined
    if (tags.includes('behavior') && extractedData.behavior?.behavior) {
      const matched = state.agendaItems.find(a =>
        a.status === 'pending' && a.content.includes(extractedData.behavior!.behavior)
      )
      if (matched) {
        matchedAgenda = `${matched.time}${matched.content}`
      }
    }

    // 4) 写入单条时间线记录（多标签）
    const timelineId = get().addTimelineRecord({
      time,
      content: t,
      matchedAgenda,
      status: matchedAgenda ? 'matched' : 'unmatched',
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

    return { timelineId, tags, extractedData }
  },

  // ===== 常用事程 =====
  frequentAgendas: mockFrequentAgendas,
}))

// 模拟数据 - 时间线记录（多标签：一句话可同时属于多个类型）
// tags: 标签ID数组，系统标签用 'behavior'|'item'|'shopping'|'event'，自定义标签用 genId()
// extractedData: 按类型分组的抽取数据 { item: {...}, event: {...} }
export const mockTimelineRecords = [
  {
    id: '1',
    time: '14:30',
    content: '正在喝水',
    matchedAgenda: '15:00吃药',
    status: 'matched',
    tags: ['behavior'] as string[],
    extractedData: { behavior: { behavior: '喝水', category: '健康', duration: undefined } },
  },
  {
    id: '2',
    time: '12:00',
    content: '吃完午饭，准备休息',
    matchedAgenda: '12:00午饭',
    status: 'matched',
    tags: ['behavior'] as string[],
    extractedData: { behavior: { behavior: '吃午饭', category: '饮食', duration: undefined } },
  },
  {
    id: '3',
    time: '10:30',
    content: '回家，钥匙放在门口鞋柜上了',
    matchedAgenda: undefined,
    status: 'unmatched',
    // 多标签：既是"事件"（回家），又是"物品位置"（放钥匙）
    tags: ['event', 'item'] as string[],
    extractedData: {
      event: { event: '回家', location: undefined },
      item: { itemName: '钥匙', location: '门口鞋柜', action: 'place' },
    },
  },
  {
    id: '4',
    time: '10:00',
    content: '在超市买了苹果2斤，牛奶3瓶',
    matchedAgenda: undefined,
    status: 'unmatched',
    tags: ['shopping'] as string[],
    extractedData: {
      shopping: {
        items: [
          { name: '苹果', quantity: '2', unit: '斤' },
          { name: '牛奶', quantity: '3', unit: '瓶' },
        ],
        store: '超市',
      },
    },
  },
  {
    id: '5',
    time: '09:00',
    content: '吃完早饭，正在吃药',
    matchedAgenda: '09:00吃药',
    status: 'matched',
    tags: ['behavior'] as string[],
    extractedData: { behavior: { behavior: '吃药', category: '健康', duration: undefined } },
  },
  {
    id: '6',
    time: '08:15',
    content: '拿了快递',
    matchedAgenda: undefined,
    status: 'unmatched',
    tags: ['event'] as string[],
    extractedData: { event: { event: '拿快递', location: undefined } },
  },
  {
    id: '7',
    time: '07:30',
    content: '起床，洗漱',
    matchedAgenda: undefined,
    status: 'unmatched',
    tags: ['behavior', 'event', 'custom_sport'] as string[],
    extractedData: {
      behavior: { behavior: '起床', category: '生活', duration: undefined },
      event: { event: '洗漱', location: undefined },
    },
  },
]

// 模拟数据 - 购物记录
export const mockShoppingRecords = [
  {
    id: '1',
    date: '2026-07-02',
    time: '10:00',
    store: '超市',
    items: [
      { name: '苹果', quantity: '2', unit: '斤' },
      { name: '牛奶', quantity: '3', unit: '瓶' },
    ],
    source: 'voice' as const,
    rawText: '在超市买了苹果2斤，牛奶3瓶',
  },
  {
    id: '2',
    date: '2026-07-01',
    time: '16:30',
    store: '菜市场',
    items: [
      { name: '白菜', quantity: '1', unit: '颗' },
      { name: '猪肉', quantity: '500', unit: '克' },
      { name: '鸡蛋', quantity: '10', unit: '个' },
    ],
    source: 'voice' as const,
    rawText: '在菜市场买了白菜一颗，猪肉半斤，鸡蛋十个',
  },
  {
    id: '3',
    date: '2026-06-30',
    time: '09:00',
    store: '药店',
    items: [
      { name: '降压药', quantity: '1', unit: '盒' },
    ],
    source: 'manual' as const,
    rawText: '',
  },
]

// 模拟数据 - 事程记录
export const mockAgendaItems = [
  {
    id: '1',
    time: '09:00',
    content: '吃药',
    note: '降压药，饭后服用',
    isMustDo: false,
    status: 'completed',
    remainingTime: undefined,
  },
  {
    id: '2',
    time: '12:00',
    content: '吃午饭',
    note: undefined,
    isMustDo: false,
    status: 'completed',
    remainingTime: undefined,
  },
  {
    id: '3',
    time: '15:00',
    content: '吃降压药',
    note: undefined,
    isMustDo: true,
    status: 'pending',
    remainingTime: '还有30分钟',
  },
  {
    id: '4',
    time: '18:00',
    content: '运动',
    note: '散步30分钟',
    isMustDo: false,
    status: 'pending',
    remainingTime: '还有3小时',
  },
  {
    id: '5',
    time: '21:00',
    content: '吃安眠药',
    note: '(必做)',
    isMustDo: true,
    status: 'pending',
    remainingTime: '还有6小时',
  },
]

// 模拟数据 - 常用事程
export const mockFrequentAgendas = [
  {
    id: '1',
    content: '早上吃药',
    avgTime: '09:15',
    consecutiveDays: 12,
    matchRate: 95,
    isAutoExtracted: true,
  },
  {
    id: '2',
    content: '吃午饭',
    avgTime: '12:10',
    consecutiveDays: 14,
    matchRate: 100,
    isAutoExtracted: true,
  },
  {
    id: '3',
    content: '喝水',
    avgTime: '14:30',
    consecutiveDays: 5,
    matchRate: 60,
    isAutoExtracted: false,
  },
]

// 模拟数据 - 对话记录
export const mockChatMessages = [
  {
    id: '1',
    role: 'user' as const,
    content: '我的钥匙放在哪里了？',
    timestamp: '14:35',
    source: undefined,
  },
  {
    id: '2',
    role: 'assistant' as const,
    content: '根据您6月20日的记录，您把钥匙放在了门口鞋柜第二个抽屉里。',
    timestamp: '14:35',
    source: '来源：6月20日 08:30 时间线记录',
  },
  {
    id: '3',
    role: 'user' as const,
    content: '上周三我做了什么？',
    timestamp: '14:36',
    source: undefined,
  },
  {
    id: '4',
    role: 'assistant' as const,
    content: '上周三（6月18日）您做了以下事情：\n07:30 吃早饭\n08:00 吃降压药 ✓\n10:30 去社区医院复诊 ✓\n12:00 吃午饭\n15:00 拿快递\n18:30 散步30分钟 ✓',
    timestamp: '14:36',
    source: '来源：6月18日 时间线记录',
  },
]

// 模拟数据 - 快捷问题
export const mockQuickQuestions = [
  { id: '1', icon: '📍', text: '钥匙在哪' },
  { id: '2', icon: '📅', text: '上周做了' },
  { id: '3', icon: '📊', text: '运动几次' },
  { id: '4', icon: '💡', text: '驾照到期' },
  { id: '5', icon: '🔍', text: '其他问题' },
]

// 模拟数据 - 统计数据
export const mockStatsData = {
  completionRate: 87,
  trend: 'up',
  trendValue: 5,
  heatmap: [
    [true, true, true, true, true, true, true],    // 吃药
    [true, true, true, true, true, true, true],    // 吃饭
    [true, false, true, true, false, true, true],  // 运动
    [true, true, false, true, false, true, false], // 喝水
  ],
  heatmapLabels: ['吃药', '吃饭', '运动', '喝水'],
  heatmapDays: ['周一', '周二', '周三', '周四', '周五', '周六', '周日'],
  topRegular: { name: '吃早饭', count: '7/7天' },
  topMissed: { name: '喝水', count: '3/7天' },
}

// 模拟数据 - 策略优化建议
export const mockSuggestions = [
  {
    id: '1',
    discovery: '最近5次运动提醒都延后30分钟',
    suggestion: '将运动提醒改为18:30',
  },
  {
    id: '2',
    discovery: '每天22:00后不再记录',
    suggestion: '自动设置22:00-08:00免打扰',
  },
]

// 模拟数据 - 我的页面功能列表
export const mockMenuItems = [
  {
    group: '生活管理',
    items: [
      { id: '1', icon: '📍', text: '物品位置记忆', subtext: undefined },
      { id: '2', icon: '🛒', text: '购物记录', subtext: '语音自动记录' },
      { id: '3', icon: '👨‍👩‍👧', text: '家属管理', subtext: '已绑定2位家属' },
      { id: '4', icon: '🆘', text: '紧急求助设置', subtext: undefined },
    ],
  },
  {
    group: '系统设置',
    items: [
      { id: '5', icon: '🔔', text: '提醒规则（全局）', subtext: undefined },
      { id: '6', icon: '🔇', text: '免打扰时段', subtext: '22:00-08:00' },
      { id: '7', icon: '📄', text: '报告导出', subtext: undefined },
      { id: '8', icon: '📱', text: '健康设备对接', subtext: '已对接2个设备' },
    ],
  },
  {
    group: '其他',
    items: [
      { id: '9', icon: '🔒', text: '隐私与安全', subtext: undefined },
      { id: '10', icon: '🎨', text: '偏好设置', subtext: undefined },
      { id: '11', icon: 'ℹ️', text: '关于与帮助', subtext: undefined },
    ],
  },
]
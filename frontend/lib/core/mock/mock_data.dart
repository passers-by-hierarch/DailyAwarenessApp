import '../models/app_models.dart';

/// Mock 数据 - 对齐 web-prototype/src/data/mockData.ts
class MockData {
  MockData._();

  static String dateOffset(int days) {
    final d = DateTime.now().add(Duration(days: days));
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  static String get todayStr => dateOffset(0);
  static String get yesterdayStr => dateOffset(-1);
  static String get twoDaysAgoStr => dateOffset(-2);
  static String get threeDaysAgoStr => dateOffset(-3);
  static String get fiveDaysAgoStr => dateOffset(-5);

  static DateTime _dt(String dateStr, String timeStr) {
    final parts = dateStr.split('-');
    final timeParts = timeStr.split(':');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
      int.parse(timeParts[0]),
      int.parse(timeParts[1]),
    );
  }

  /// 时间线记录
  static List<TimelineRecord> get mockTimelineRecords => [
    TimelineRecord(
      id: '1',
      content: '正在喝水',
      time: _dt(todayStr, '14:30'),
      type: TimelineType.behavior,
      tags: ['behavior'],
      notes: [],
    ),
    TimelineRecord(
      id: '2',
      time: _dt(todayStr, '12:00'),
      content: '吃完午饭，准备休息',
      type: TimelineType.behavior,
      tags: ['behavior'],
      matchedAgenda: '12:00午饭',
    ),
    TimelineRecord(
      id: '3',
      time: _dt(todayStr, '10:30'),
      content: '回家，钥匙放在门口鞋柜上了',
      type: TimelineType.event,
      tags: ['event', 'item'],
      notes: [
        NoteEntry(
          id: 'note1',
          content: '后来又把钥匙移到了客厅茶几上',
          time: _dt(todayStr, '11:00'),
        ),
      ],
      sideEffects: SideEffects(
        itemUpdate: ItemUpdate(name: '钥匙', location: '门口鞋柜'),
      ),
    ),
    TimelineRecord(
      id: '4',
      time: _dt(todayStr, '10:00'),
      content: '在超市买了苹果2斤，牛奶3瓶',
      type: TimelineType.shopping,
      tags: ['shopping'],
      sideEffects: SideEffects(
        shoppingRecord: ShoppingRecord(
          id: 's1',
          store: '超市',
          time: _dt(todayStr, '10:00'),
          items: [
            ShoppingItem(id: 'i1', name: '苹果', quantity: 2, unit: '斤'),
            ShoppingItem(id: 'i2', name: '牛奶', quantity: 3, unit: '瓶'),
          ],
        ),
      ),
    ),
    TimelineRecord(
      id: '5',
      time: _dt(todayStr, '09:00'),
      content: '吃完早饭，正在吃药',
      type: TimelineType.behavior,
      tags: ['behavior'],
      matchedAgenda: '09:00吃药',
    ),
    TimelineRecord(
      id: '6',
      time: _dt(todayStr, '08:15'),
      content: '拿了快递',
      type: TimelineType.event,
      tags: ['event'],
    ),
    TimelineRecord(
      id: '7',
      time: _dt(todayStr, '07:30'),
      content: '起床，洗漱',
      type: TimelineType.behavior,
      tags: ['behavior', 'event'],
    ),
    TimelineRecord(
      id: '8',
      time: _dt(yesterdayStr, '19:30'),
      content: '吃完晚饭，出去散步',
      type: TimelineType.behavior,
      tags: ['behavior', 'custom_sport'],
    ),
    TimelineRecord(
      id: '9',
      time: _dt(yesterdayStr, '15:00'),
      content: '吃了降压药',
      type: TimelineType.behavior,
      tags: ['behavior'],
      matchedAgenda: '15:00吃降压药',
    ),
    TimelineRecord(
      id: '10',
      time: _dt(yesterdayStr, '12:30'),
      content: '午觉睡了一个小时',
      type: TimelineType.behavior,
      tags: ['behavior'],
    ),
    TimelineRecord(
      id: '11',
      time: _dt(twoDaysAgoStr, '10:00'),
      content: '去社区医院复诊',
      type: TimelineType.event,
      tags: ['event', 'custom_medical'],
    ),
    TimelineRecord(
      id: '12',
      time: _dt(twoDaysAgoStr, '08:00'),
      content: '吃了早饭和降压药',
      type: TimelineType.behavior,
      tags: ['behavior'],
      matchedAgenda: '08:00吃药',
    ),
    TimelineRecord(
      id: '13',
      time: _dt(threeDaysAgoStr, '16:00'),
      content: '陪孙子去公园玩',
      type: TimelineType.event,
      tags: ['event', 'custom_family'],
    ),
    TimelineRecord(
      id: '14',
      time: _dt(fiveDaysAgoStr, '09:30'),
      content: '在菜市场买了白菜一颗，猪肉半斤',
      type: TimelineType.shopping,
      tags: ['shopping'],
      sideEffects: SideEffects(
        shoppingRecord: ShoppingRecord(
          id: 's2',
          store: '菜市场',
          time: _dt(fiveDaysAgoStr, '09:30'),
          items: [
            ShoppingItem(id: 'i3', name: '白菜', quantity: 1, unit: '颗'),
            ShoppingItem(id: 'i4', name: '猪肉', quantity: 500, unit: '克'),
          ],
        ),
      ),
    ),
    TimelineRecord(
      id: '15',
      time: _dt(yesterdayStr, '18:00'),
      content: '钥匙放在门口鞋柜上',
      type: TimelineType.item,
      tags: ['item'],
      sideEffects: SideEffects(
        itemUpdate: ItemUpdate(name: '钥匙', location: '门口鞋柜'),
      ),
    ),
    TimelineRecord(
      id: '16',
      time: _dt(yesterdayStr, '08:00'),
      content: '钥匙放在客厅茶几上',
      type: TimelineType.item,
      tags: ['item'],
      sideEffects: SideEffects(
        itemUpdate: ItemUpdate(name: '钥匙', location: '客厅茶几'),
      ),
    ),
    TimelineRecord(
      id: '17',
      time: _dt(twoDaysAgoStr, '20:00'),
      content: '钥匙放在门口鞋柜上',
      type: TimelineType.item,
      tags: ['item'],
      sideEffects: SideEffects(
        itemUpdate: ItemUpdate(name: '钥匙', location: '门口鞋柜'),
      ),
    ),
    TimelineRecord(
      id: '18',
      time: _dt(twoDaysAgoStr, '09:00'),
      content: '钥匙放在卧室床头柜上',
      type: TimelineType.item,
      tags: ['item'],
      sideEffects: SideEffects(
        itemUpdate: ItemUpdate(name: '钥匙', location: '卧室床头柜'),
      ),
    ),
    TimelineRecord(
      id: '19',
      time: _dt(threeDaysAgoStr, '19:00'),
      content: '钥匙放在门口鞋柜上',
      type: TimelineType.item,
      tags: ['item'],
      sideEffects: SideEffects(
        itemUpdate: ItemUpdate(name: '钥匙', location: '门口鞋柜'),
      ),
    ),
    TimelineRecord(
      id: '20',
      time: _dt(yesterdayStr, '15:00'),
      content: '护照放在衣柜二层抽屉里',
      type: TimelineType.item,
      tags: ['item'],
      sideEffects: SideEffects(
        itemUpdate: ItemUpdate(name: '护照', location: '衣柜二层'),
      ),
    ),
    TimelineRecord(
      id: '21',
      time: _dt(twoDaysAgoStr, '10:00'),
      content: '护照放在书房书架上',
      type: TimelineType.item,
      tags: ['item'],
      sideEffects: SideEffects(
        itemUpdate: ItemUpdate(name: '护照', location: '书房书架'),
      ),
    ),
    TimelineRecord(
      id: '22',
      time: _dt(threeDaysAgoStr, '14:00'),
      content: '护照放在衣柜二层抽屉里',
      type: TimelineType.item,
      tags: ['item'],
      sideEffects: SideEffects(
        itemUpdate: ItemUpdate(name: '护照', location: '衣柜二层'),
      ),
    ),
    TimelineRecord(
      id: '23',
      time: _dt(fiveDaysAgoStr, '11:00'),
      content: '护照放在衣柜二层抽屉里',
      type: TimelineType.item,
      tags: ['item'],
      sideEffects: SideEffects(
        itemUpdate: ItemUpdate(name: '护照', location: '衣柜二层'),
      ),
    ),
  ];

  /// 事程记录
  static List<AgendaItem> get mockAgendaItems => [
    AgendaItem(id: '1', date: todayStr, time: '09:00', content: '吃药', note: '降压药，饭后服用', status: AgendaStatus.completed),
    AgendaItem(id: '2', date: todayStr, time: '12:00', content: '吃午饭', status: AgendaStatus.completed),
    AgendaItem(id: '3', date: todayStr, time: '15:00', content: '吃降压药', isMustDo: true, status: AgendaStatus.pending, remainingTime: '还有30分钟', isHighFrequency: true),
    AgendaItem(id: '4', date: todayStr, time: '18:00', content: '运动', note: '散步30分钟', status: AgendaStatus.pending, remainingTime: '还有3小时'),
    AgendaItem(id: '5', date: todayStr, time: '21:00', content: '吃安眠药', isMustDo: true, status: AgendaStatus.pending, remainingTime: '还有6小时', isHighFrequency: true),
    AgendaItem(id: '6', date: yesterdayStr, time: '08:00', content: '吃降压药', isMustDo: true, status: AgendaStatus.completed),
    AgendaItem(id: '7', date: yesterdayStr, time: '12:00', content: '吃午饭', status: AgendaStatus.completed),
    AgendaItem(id: '8', date: yesterdayStr, time: '15:00', content: '吃降压药', isMustDo: true, status: AgendaStatus.completed),
    AgendaItem(id: '9', date: yesterdayStr, time: '19:30', content: '散步', note: '小区里走一圈', status: AgendaStatus.completed),
    AgendaItem(id: '10', date: twoDaysAgoStr, time: '08:00', content: '吃药', isMustDo: true, status: AgendaStatus.completed),
    AgendaItem(id: '11', date: twoDaysAgoStr, time: '10:00', content: '去社区医院复诊', isMustDo: true, status: AgendaStatus.completed),
    AgendaItem(id: '12', date: twoDaysAgoStr, time: '12:30', content: '午饭', status: AgendaStatus.completed),
  ];

  /// 购物记录
  static List<ShoppingRecord> get mockShoppingRecords => [
    ShoppingRecord(
      id: '1',
      store: '超市',
      time: _dt('2026-07-02', '10:00'),
      items: [
        ShoppingItem(id: 's1i1', name: '苹果', quantity: 2, unit: '斤'),
        ShoppingItem(id: 's1i2', name: '牛奶', quantity: 3, unit: '瓶'),
      ],
    ),
    ShoppingRecord(
      id: '2',
      store: '菜市场',
      time: _dt('2026-07-01', '16:30'),
      items: [
        ShoppingItem(id: 's2i1', name: '白菜', quantity: 1, unit: '颗'),
        ShoppingItem(id: 's2i2', name: '猪肉', quantity: 500, unit: '克'),
        ShoppingItem(id: 's2i3', name: '鸡蛋', quantity: 10, unit: '个'),
      ],
    ),
    ShoppingRecord(
      id: '3',
      store: '药店',
      time: _dt('2026-06-30', '09:00'),
      items: [ShoppingItem(id: 's3i1', name: '降压药', quantity: 1, unit: '盒')],
    ),
  ];

  /// 常用事程
  static List<FrequentAgenda> get mockFrequentAgendas => [
    FrequentAgenda(id: '1', content: '早上吃药', avgTime: '09:15', consecutiveDays: 12, matchRate: 95, icon: '💊'),
    FrequentAgenda(id: '2', content: '吃午饭', avgTime: '12:10', consecutiveDays: 14, matchRate: 100, icon: '🍚'),
    FrequentAgenda(id: '3', content: '喝水', avgTime: '14:30', consecutiveDays: 5, matchRate: 60, icon: '💧'),
  ];

  /// 对话记录
  static List<ChatMessage> get mockChatMessages => [
    ChatMessage(id: '1', role: 'user', content: '我的钥匙放在哪里了？', time: DateTime.now()),
    ChatMessage(id: '2', role: 'assistant', content: '根据您6月20日的记录，您把钥匙放在了门口鞋柜第二个抽屉里。', time: DateTime.now()),
    ChatMessage(id: '3', role: 'user', content: '上周三我做了什么？', time: DateTime.now()),
    ChatMessage(id: '4', role: 'assistant', content: '上周三（6月18日）您做了以下事情：\n07:30 吃早饭\n08:00 吃降压药 ✓\n10:30 去社区医院复诊 ✓\n12:00 吃午饭\n15:00 拿快递\n18:30 散步30分钟 ✓', time: DateTime.now()),
  ];

  /// 快捷问题
  static List<QuickQuestion> get mockQuickQuestions => [
    QuickQuestion(id: '1', text: '钥匙在哪', category: '位置'),
    QuickQuestion(id: '2', text: '今天做了', category: '时间线'),
    QuickQuestion(id: '3', text: '鸡蛋能用多久', category: '库存'),
    QuickQuestion(id: '4', text: '分析我的习惯', category: '习惯'),
    QuickQuestion(id: '5', text: '我想学英语', category: '学习'),
    QuickQuestion(id: '6', text: '血压正常值', category: '常识'),
    QuickQuestion(id: '7', text: '今天有什么事程', category: '事程'),
    QuickQuestion(id: '8', text: '设置鸡蛋用完提醒', category: '提醒'),
  ];

  /// 统计数据
  static StatsData get mockStatsData => StatsData(
    completionRate: 87,
    heatmap: [
      [1, 1, 1, 1, 1, 1, 1],
      [1, 1, 1, 1, 1, 1, 1],
      [1, 0, 1, 1, 0, 1, 1],
      [1, 1, 0, 1, 0, 1, 0],
    ],
    topRegular: [NameCount(name: '吃早饭', count: 7), NameCount(name: '吃药', count: 6)],
    topMissed: [NameCount(name: '喝水', count: 3), NameCount(name: '运动', count: 2)],
  );

  static List<String> get heatmapLabels => ['吃药', '吃饭', '运动', '喝水'];
  static List<String> get heatmapDays => ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

  /// 策略优化建议
  static List<Suggestion> get mockSuggestions => [
    Suggestion(id: '1', text: '最近5次运动提醒都延后30分钟，建议将运动提醒改为18:30'),
    Suggestion(id: '2', text: '每天22:00后不再记录，建议自动设置22:00-08:00免打扰'),
  ];

  /// 我的页面菜单
  static List<MenuGroup> get mockMenuItems => [
    MenuGroup(
      group: '生活管理',
      items: [
        MenuItem(id: '1', title: '物品位置记忆', description: '', icon: '📍', route: '/items'),
        MenuItem(id: '2', title: '物品记录', description: '记录物品及数量', icon: '📦', route: '/shopping'),
        MenuItem(id: '3', title: '家属管理', description: '已绑定2位家属', icon: '👨‍👩‍👧', route: '/family'),
        MenuItem(id: '4', title: '紧急求助设置', description: '', icon: '🆘', route: '/emergency-settings'),
      ],
    ),
    MenuGroup(
      group: '系统设置',
      items: [
        MenuItem(id: '5', title: '提醒规则', description: '', icon: '🔔', route: '/reminder-rules'),
        MenuItem(id: '6', title: '免打扰时段', description: '22:00-08:00', icon: '🔇', route: '/quiet-hours'),
        MenuItem(id: '7', title: 'AI 智能问答设置', description: '大模型配置', icon: '🤖', route: '/ai-settings'),
        MenuItem(id: '7a', title: '意图训练管理', description: '管理意图识别模式', icon: '🧠', route: '/intent-training'),
        MenuItem(id: '8', title: '报告导出', description: '', icon: '📄', route: '/report-export'),
        MenuItem(id: '9', title: '健康设备对接', description: '已对接2个设备', icon: '📱', route: '/health-devices'),
      ],
    ),
    MenuGroup(
      group: '其他',
      items: [
        MenuItem(id: '10', title: '隐私与安全', description: '', icon: '🔒', route: '/privacy-security'),
        MenuItem(id: '11', title: '偏好设置', description: '', icon: '🎨', route: '/preferences'),
        MenuItem(id: '12', title: '关于与帮助', description: '', icon: 'ℹ️', route: '/about-help'),
      ],
    ),
  ];

  /// 物品记录
  static List<ItemRecord> get mockItems => [
    ItemRecord(
      id: '1',
      name: '钥匙',
      location: '门口鞋柜',
      tags: ['item'],
      history: [
        LocationHistory(id: 'h1', location: '门口鞋柜', time: DateTime.now()),
        LocationHistory(id: 'h2', location: '茶几', time: DateTime.now()),
      ],
    ),
    ItemRecord(
      id: '2',
      name: '护照',
      location: '衣柜二层',
      tags: ['item'],
    ),
    ItemRecord(
      id: '3',
      name: '身份证',
      location: '抽屉里',
      tags: ['item'],
    ),
    ItemRecord(
      id: '4',
      name: '手机',
      location: '床头柜上',
      tags: ['item'],
    ),
  ];

  /// 自定义标签
  static List<TagDef> get mockCustomTags => [
    TagDef(id: 'custom_sport', name: '运动', color: 'purple', icon: '🏃'),
    TagDef(id: 'custom_medical', name: '就医', color: 'danger', icon: '💊'),
    TagDef(id: 'custom_family', name: '陪孙子', color: 'success', icon: '👨‍👩‍👦'),
  ];

  /// 库存记录（从历史时间线自动推算的当前库存）
  static List<InventoryItem> get mockInventory => [
    InventoryItem(
      id: 'inv1',
      name: '降压药',
      quantity: 28,
      unit: '片',
      category: '药品',
      lastUpdated: DateTime.now(),
      logs: [
        InventoryLog(id: 'log1', change: -1, reason: '服用', time: DateTime.now().subtract(const Duration(hours: 6))),
        InventoryLog(id: 'log2', change: 30, reason: '购买入库', time: DateTime.now().subtract(const Duration(days: 15))),
      ],
    ),
    InventoryItem(
      id: 'inv2',
      name: '安眠药',
      quantity: 12,
      unit: '片',
      category: '药品',
      lastUpdated: DateTime.now(),
      logs: [
        InventoryLog(id: 'log3', change: -1, reason: '服用', time: DateTime.now().subtract(const Duration(hours: 8))),
        InventoryLog(id: 'log4', change: 14, reason: '购买入库', time: DateTime.now().subtract(const Duration(days: 7))),
      ],
    ),
    InventoryItem(
      id: 'inv3',
      name: '苹果',
      quantity: 5,
      unit: '斤',
      category: '食品',
      lastUpdated: DateTime.now(),
      logs: [
        InventoryLog(id: 'log5', change: 2, reason: '购买入库', time: DateTime.now().subtract(const Duration(hours: 5))),
      ],
    ),
    InventoryItem(
      id: 'inv4',
      name: '牛奶',
      quantity: 2,
      unit: '瓶',
      category: '食品',
      lastUpdated: DateTime.now(),
      logs: [
        InventoryLog(id: 'log6', change: -1, reason: '饮用', time: DateTime.now().subtract(const Duration(hours: 3))),
        InventoryLog(id: 'log7', change: 3, reason: '购买入库', time: DateTime.now().subtract(const Duration(hours: 5))),
      ],
    ),
    InventoryItem(
      id: 'inv5',
      name: '鸡蛋',
      quantity: 8,
      unit: '个',
      category: '食品',
      lastUpdated: DateTime.now(),
    ),
    InventoryItem(
      id: 'inv6',
      name: '白菜',
      quantity: 0.5,
      unit: '颗',
      category: '食品',
      lastUpdated: DateTime.now(),
    ),
    InventoryItem(
      id: 'inv7',
      name: '猪肉',
      quantity: 200,
      unit: '克',
      category: '食品',
      lastUpdated: DateTime.now(),
    ),
  ];

  /// 用户档案（个性化建议）
  static UserProfile get mockUserProfile => UserProfile(
    name: '王大爷',
    age: 68,
    gender: 'male',
    healthConditions: ['高血压', '轻度糖尿病'],
    preferences: ['温和运动', '室内活动', '早睡早起'],
    createdAt: DateTime(2026, 1, 1),
  );

  /// 计划模板库
  static List<PlanTemplate> get mockPlanTemplates => [
    PlanTemplate(
      id: 'tpl_hospital',
      name: '医院复诊',
      icon: '🏥',
      steps: ['提前预约挂号', '准备病历和医保卡', '按时到达医院', '就诊检查', '取药回家'],
      suggestedTimes: ['08:30', '09:00', '10:00'],
      estimatedDuration: '2-3小时',
      tips: ['建议提前30分钟到达', '记得带上身份证和医保卡', '看病前不要空腹'],
      category: '医疗',
    ),
    PlanTemplate(
      id: 'tpl_travel',
      name: '旅行准备',
      icon: '✈️',
      steps: ['整理证件（身份证、医保卡）', '准备常用药品', '收拾衣物日用品', '确认行程住宿', '出发前往车站/机场'],
      suggestedTimes: ['09:00', '14:00'],
      estimatedDuration: '半天',
      tips: ['药品要分装清晰', '重要证件分开存放', '提前2小时到达车站'],
      category: '出行',
    ),
    PlanTemplate(
      id: 'tpl_birthday',
      name: '生日准备',
      icon: '🎂',
      steps: ['确定生日主题', '购买生日蛋糕和礼物', '准备生日餐', '邀请亲友', '布置场地'],
      suggestedTimes: ['09:00', '10:00', '15:00'],
      estimatedDuration: '1天',
      tips: ['蛋糕建议当天预订', '提前1周邀请亲友', '可以准备拍照留念'],
      category: '家庭',
    ),
    PlanTemplate(
      id: 'tpl_checkup',
      name: '体检准备',
      icon: '🩺',
      steps: ['前一天22点后禁食禁水', '早上空腹前往体检中心', '携带身份证和体检单', '完成各项检查', '领取报告时间确认'],
      suggestedTimes: ['07:30', '08:00'],
      estimatedDuration: '2-3小时',
      tips: ['体检前一天清淡饮食', '穿着宽松便于检查', '记得携带历年体检报告'],
      category: '医疗',
    ),
    PlanTemplate(
      id: 'tpl_haircut',
      name: '理发',
      icon: '💈',
      steps: ['提前预约', '前往理发店', '理发', '付款回家'],
      suggestedTimes: ['09:30', '14:00', '15:00'],
      estimatedDuration: '1-1.5小时',
      tips: ['可以带上口罩', '告知理发师想要的发型'],
      category: '生活',
    ),
    PlanTemplate(
      id: 'tpl_shopping',
      name: '超市购物',
      icon: '🛒',
      steps: ['列出购物清单', '前往超市/菜市场', '按清单采购', '结账回家'],
      suggestedTimes: ['09:00', '10:00', '16:00'],
      estimatedDuration: '1-1.5小时',
      tips: ['避免在饭点购物', '可以先查看库存避免重复购买'],
      category: '生活',
    ),
    PlanTemplate(
      id: 'tpl_bank',
      name: '银行业务',
      icon: '🏦',
      steps: ['准备身份证和银行卡', '前往银行', '取号排队', '办理业务', '确认无误后离开'],
      suggestedTimes: ['09:30', '10:00', '14:00'],
      estimatedDuration: '1-2小时',
      tips: ['记得带上身份证', '大额取款注意安全'],
      category: '生活',
    ),
    PlanTemplate(
      id: 'tpl_clean',
      name: '家庭清洁',
      icon: '🧹',
      steps: ['整理杂物', '扫地拖地', '擦拭家具', '清理厨房卫生间'],
      suggestedTimes: ['09:00', '14:00', '15:00'],
      estimatedDuration: '1-2小时',
      tips: ['可以分阶段进行，避免劳累', '高处清洁要注意安全'],
      category: '家务',
    ),
  ];

  /// 习惯徽章
  static List<HabitBadge> get mockHabitBadges => [
    HabitBadge(id: 'badge_3', name: '初学者', icon: '🌱', requiredDays: 3, description: '连续坚持3天'),
    HabitBadge(id: 'badge_7', name: '一周坚持', icon: '⭐', requiredDays: 7, description: '连续坚持7天'),
    HabitBadge(id: 'badge_14', name: '两周达人', icon: '🌟', requiredDays: 14, description: '连续坚持14天'),
    HabitBadge(id: 'badge_21', name: '习惯养成', icon: '🏆', requiredDays: 21, description: '连续坚持21天，习惯已养成'),
    HabitBadge(id: 'badge_30', name: '月度冠军', icon: '👑', requiredDays: 30, description: '连续坚持30天'),
    HabitBadge(id: 'badge_100', name: '百日坚持', icon: '💎', requiredDays: 100, description: '连续坚持100天，了不起！'),
  ];
}

class MenuGroup {
  final String group;
  final List<MenuItem> items;
  const MenuGroup({required this.group, required this.items});
}

// 为 ItemRecord 添加 icon 字段扩展
extension ItemRecordIcon on ItemRecord {
  String get icon {
    const map = {'钥匙': '🔑', '护照': '📋', '身份证': '💳', '手机': '📱', '耳机': '🎧', '工具箱': '🔧'};
    return map[name] ?? '📋';
  }
}

# DailyAwarenessApp 功能详细文档

> 基于 web-prototype 源码与 Flutter Android 实现整理
> 文档版本：v1.0
> 日期：2026-07-05

---

## 一、应用概述

**DailyAwarenessApp（日常意识助手）** 是一款面向老年用户的个人记忆问答与日常管理助手，通过语音交互降低操作门槛，实现：

- **语音录入** → 自动识别多类型（行为/物品/购物/事件）+ 智能标签
- **事程管理** → AI 自动推荐 + 到时提醒 + 完成/推迟追踪
- **记忆查询** → 自然语言问答（"钥匙在哪？"）
- **习惯统计** → 热力图 + 行为排行 + 完成率追踪

---

## 二、功能层级拆解

### 1. 首页（Home）

#### 1.1 顶部状态区

**功能描述**：显示日期选择器与今日事程完成进度

**操作步骤**：
1. 点击顶部日期区域 → 弹出日历弹窗（6 行 7 列网格）
2. 选择历史日期 → 右上角显示「回到今天」绿色按钮，快速返回今日
3. 查看今日时 → 右上角显示「今日 X/Y」非点击状态文字（已完成数/总数）

---

#### 1.2 问候语

**功能描述**：根据时段动态显示问候语

**逻辑**：
- 早晨（06:00-09:00）："早上好"
- 中午（09:00-12:00）："中午好"
- 下午（12:00-18:00）："下午好"
- 晚间（18:00-22:00）："晚上好"
- 夜间（22:00-06:00）："晚安"

---

#### 1.3 时间线/事程双 Tab 切换

**功能描述**：首页核心区域支持两个子页面切换

**操作步骤**：
1. 点击「时间线」Tab → 显示当日所有语音录入记录（按时间倒序）
2. 点击「事程」Tab → 显示当日待办事项（按时间升序）

---

#### 1.4 时间线列表（Timeline）

**功能描述**：展示当日所有语音录入记录，每条记录支持多标签识别

**数据结构**：
```
TimelineRecord {
  id: string
  date: string          // YYYY-MM-DD
  time: string          // HH:mm
  content: string       // 语音原文
  matchedAgenda?: string // 关联事程（如 "15:00吃药"）
  status: 'matched' | 'unmatched' // 是否匹配到事程
  tags: string[]        // 多标签ID（behavior/item/shopping/event + 自定义）
  extractedData: {
    behavior?: { behavior: string, category: string }
    item?: { itemName: string, location: string, action: 'place' }
    shopping?: { items: ShoppingItem[], store: string }
    event?: { event: string, location?: string }
  }
  notes: NoteEntry[]    // 补充记录
}
```

**操作步骤**：
1. 点击任意时间线项 → 进入时间线详情页
2. 查看多标签徽章（不同颜色区分类型）
3. 查看匹配事程标记（绿色「✓ 已完成」或无标记）

---

#### 1.5 时间线详情页

**功能描述**：查看单条记录详情，支持补充记录添加

**操作步骤**：
1. 查看原始语音内容（含播放按钮）
2. 点击「语音输入」全宽按钮 → 开始录音（3 秒自动停止）
3. 录音停止后自动保存为补充记录
4. 补充记录显示为小播放器（w-7 h-7）+ 文字内容
5. 长按补充记录（600ms）或右键 → 弹出删除确认

**UI 约束**：
- 补充记录播放器尺寸：w-7 h-7（比原始语音 w-10 小）
- 底部提示：「长按已添加的记录可删除」

---

#### 1.6 事程列表（Agenda）

**功能描述**：展示今日待办事项，支持状态管理

**数据结构**：
```
AgendaItem {
  id: string
  date: string          // YYYY-MM-DD
  time: string          // HH:mm
  content: string       // 事程内容
  note?: string         // 备注
  isMustDo: boolean     // 是否必做
  status: 'pending' | 'completed' | 'postponed' | 'expired'
  remainingTime?: string // "还有30分钟"
  isHighFrequency?: boolean // 是否高频事程
  icon?: string         // emoji 图标
  source: 'user' | 'ai' // 来源
}
```

**状态转换逻辑**：
```
pending（待办）
  → 用户点击「完成」 → completed（已完成）
  → 用户点击「推迟」 → postponed（已推迟，显示推迟分钟数）
  → 时间已过且未完成 → expired（已过期，自动转换）
```

**操作步骤**：
1. 查看事程卡片（含图标、时间、内容、剩余时间）
2. 左滑事程卡片 → 显示红色删除区域
3. 继续滑动 → 弹出二次确认「确认删除此事程？」
4. pending 状态显示「完成」「推迟」按钮
5. 点击「完成」→ 状态变为 completed，绿色勾选标记
6. 点击「推迟」→ 弹出推迟弹窗（+10/+30/+60 分钟或自定义）

**徽章显示**：
- 必做：红色「必做」徽章
- 高频：蓝色「高频」徽章
- AI 推荐：蓝色「AI」徽章

---

#### 1.7 库存追踪（Inventory）

**功能描述**：自动追踪物品库存数量，基于时间线语音记录自动增减

**数据结构**：
```
InventoryItem {
  id: string
  name: string          // 物品名
  quantity: double      // 当前数量
  unit: string          // 单位（片/瓶/斤/个/盒...）
  category: string      // 品类（药品/食品/其他）
  lastUpdated: DateTime // 上次更新时间
  expireDate?: DateTime // 保质期（可选）
  logs: InventoryLog[]  // 变更日志（最近50条）
}

InventoryLog {
  id: string
  change: double        // 变化量（正=增加，负=减少）
  reason: string        // 原因（购买入库/消耗使用/过期丢弃...）
  time: DateTime        // 时间
}
```

**自动增减规则**：
- 购物记录 → 自动入库（正变化）
- 吃药/喝了/用了 → 自动扣减（负变化）
- 用户无需手动管理库存，全部由语音记录自动派生

---

#### 1.8 到时提醒弹窗

**功能描述**：事程时间到达时弹出全屏提醒

**触发逻辑**：
- 每分钟检查 agendaItems 中 pending 状态且 time == 当前时间的事程
- 弹出后状态变为 pending（不自动完成，需用户确认）

**弹窗内容**：
- 标题：「事程提醒」
- 内容：事程内容 + 备注
- 按钮：「完成」「推迟10分钟」「推迟30分钟」「关闭」

**操作步骤**：
1. 弹窗自动出现
2. 点击「完成」→ 标记事程完成，弹窗消失
3. 点击「推迟」→ 更新事程时间，弹窗消失
4. 点击「关闭」→ 仅关闭弹窗，事程保持 pending

---

#### 1.8 AI 智能事程推荐

**功能描述**：系统自动分析用户历史时间线，提取高频行为并生成事程推荐

**触发时机**：
- 每日首次打开首页时自动执行
- 检查当日事程列表，若高频行为未添加则推荐

**分析逻辑**（详见第四章）：
1. 从 timelineRecords 筛选 tags 包含 'behavior' 的记录
2. 提取关键词（吃药/吃饭/运动等）或前2字作为行为标识
3. 统计每个行为出现次数与时间分布
4. 筛选频次 >= 3 的行为
5. 计算平均时间 → 作为推荐时间
6. 检查当日是否已存在相同内容事程 → 跳过已存在
7. 自动添加为 agendaItem，source='ai'，isHighFrequency=true

**UI 显示**：
- 推荐事程显示蓝色「AI」徽章
- 自动添加无需用户确认（符合项目硬约束）

---

#### 1.9 添加事程弹窗

**功能描述**：手动添加事程，含图标选择与智能时间推荐

**操作步骤**：
1. 点击首页右上角「+」按钮 → 弹出添加弹窗
2. 输入事程内容（文本框）
3. 点击时间区域 → 显示智能推荐时间（三级推断）
4. 选择图标（12 个预设 emoji：💊🍚💧🏃🛏📖🛒🧹✈️📋等）
5. 开关「必做」选项
6. 点击「确认添加」→ 保存事程

**时间推断三级策略**（详见第四章）：
1. 用户指定时间（语音中包含时间）
2. 历史习惯时间（从时间线计算平均时间）
3. 常识默认时间（早饭=07:30，午饭=12:00 等）
4. 当前时间兜底

---

### 2. 问一问（Ask）

#### 2.1 核心定位

**问一问** 是用户的智能助手，具备两大核心能力：
1. **基于时间线记录回答**：能回答用户在时间线上记录的所有内容，包括物品位置、行为记录、购物记录、事程状态等
2. **常识性问题回答**：支持回答用户提出的日常生活常识问题，包括健康指标、用药建议、饮食运动、紧急处理、证件办理等

---

#### 2.2 聊天界面

**UI 结构**：
- 顶部标题栏 + 「历史」按钮（查看聊天历史）
- 快捷问题按钮（5 个预设，横向滚动）
- 消息列表（用户问题 + AI 回答，气泡样式）
- 输入框 + 发送按钮
- 思考动画（AI 分析时显示三个跳动圆点）

**预设快捷问题**：
- 📍 钥匙在哪
- 📅 上周做了
- 📊 运动几次
- 💡 驾照到期
- 🔍 其他问题

---

#### 2.3 AI 问答引擎（answerQuestion）

**功能描述**：九类问答优先级匹配 + 兜底引导（含问答助手 + 建议助手）

**匹配优先级**：
```
第一类：物品位置查询 → 第二类：库存/剩余数量查询 → 第三类：计划制定助手
→ 第四类：习惯养成助手 → 第五类：时间线记录查询 → 第六类：事程/待办查询
→ 第七类：行为统计查询 → 第八类：购物记录查询 → 第九类：常识性问题
→ 兜底：引导提示
```

---

#### 2.3.1 第一类：物品位置查询

**触发关键词**：「在哪」「放在哪」「位置」「放哪」

**检索逻辑**：
1. 先从 `items` 物品列表中查找匹配名称
2. 找到 → 返回当前存放位置 + 历史位置变迁
3. 未找到 → 从 `timelineRecords` 中查找含 'item' 标签的记录
4. 匹配 sideEffects.itemUpdate 中的物品名
5. 仍找不到 → 提示用户通过语音记录物品位置

**示例问答**：
| 用户问 | AI 答 |
|---|---|
| "钥匙在哪" | "根据您的记录，钥匙放在了门口鞋柜。历史位置：门口鞋柜→茶几" |
| "护照放在哪" | "根据7/2 10:30的记录，护照放在了衣柜二层。" |
| "手机位置" | "抱歉，我没有找到相关物品的记录。您可以通过语音告诉我物品的位置，下次就能帮您记住了。" |

---

#### 2.3.2 第二类：库存/剩余数量查询

**触发关键词**：「还剩」「还有多少」「剩多少」「多少斤/个/瓶」「吃了多少」「用了多少」「库存」

**数据来源**：
- 库存数据从时间线历史记录自动推算
- 购物记录 → 增加库存（正变化）
- 消耗记录（吃药、喝了、用了）→ 减少库存（负变化）
- 每条库存变更记录在 `logs` 中保留（最近 50 条）

**查询子类型**：

| 类型 | 触发词 | 返回内容 |
|---|---|---|
| **单物品剩余** | "降压药还剩多少" | 剩余数量 + 单位 + 还能用几天 + 上次更新时间 |
| **品类总览** | "药还剩多少" / "药品库存" | 列出所有药品类库存 |
| **使用量统计** | "吃了多少降压药" / "用了多少" | 最近7天消耗总量 + 当前剩余 |
| **库存总览** | "库存总览" / "都有多少" | 列出所有物品库存 |

**智能计算（还能用几天）**：
```
从最近30天的负向日志统计：
  totalUsed = sum(所有负变化的绝对值)
  daysUsed = 去重天数
  dailyAvg = totalUsed / daysUsed
  daysLeft = floor(当前库存 / dailyAvg)
```

**示例问答**：
| 用户问 | AI 答 |
|---|---|
| "降压药还剩多少" | "降压药还剩 28 片。\n按最近30天平均每天用 1 片计算，还能用 28 天。\n上次更新：7/5 09:00" |
| "药还剩多少" | "当前药品库存：\n• 降压药：28 片\n• 安眠药：12 片" |
| "吃了多少降压药" | "最近7天降压药用了 7 片。\n当前剩余：28 片" |
| "苹果还有几斤" | "苹果还剩 5 斤。\n上次更新：7/5 10:00" |
| "牛奶还有几瓶" | "牛奶还剩 2 瓶。\n按最近30天平均每天用 1 瓶计算，还能用 2 天。\n上次更新：7/5 14:30" |
| "库存总览" | "当前库存总览：\n• 降压药：28 片\n• 安眠药：12 片\n• 苹果：5 斤\n• 牛奶：2 瓶\n• 鸡蛋：8 个\n• 白菜：0.5 颗\n• 猪肉：200 克" |

---

#### 2.3.3 第三类：计划制定助手

**功能描述**：根据用户计划，提供时间建议、事程分解、耗时预估，并支持一键添加到待办事程

**触发关键词**：「计划」「打算」「安排」「准备」「想要」「计划要做」

**日期解析**：
| 关键词 | 日期计算 |
|---|---|
| 明天 | dateOffset(1) |
| 后天 | dateOffset(2) |
| 下周X | dateOffset(7) |
| 默认 | 今天 |

**计划分析逻辑**（_analyzePlan）：

| 计划类型 | 建议时间 | 事程分解 | 预估耗时 | 小贴士 |
|---|---|---|---|---|
| **医院/看病/复诊** | 08:30/09:00/10:00 | 预约→准备病历→到达→就诊→取药 | 2-3小时 | 提前30分钟、带身份证医保卡 |
| **购物/买菜** | 09:00/10:00/16:00 | 列清单→前往→采购→结账 | 1-1.5小时 | 避免饭点、查库存防重复 |
| **运动/散步/锻炼** | 16:00/18:30/19:00 | 换鞋→热身5分钟→运动→拉伸 | 30-60分钟 | 循序渐进、补充水分 |
| **打扫/卫生/整理** | 09:00/14:00/15:00 | 整理→扫地→擦拭→清理厨卫 | 1-2小时 | 分阶段、注意安全 |
| **做饭/做菜** | 11:00/17:00/17:30 | 准备食材→清洗切配→烹饪→收拾 | 1-1.5小时 | 注意安全、提前备料 |
| **取快递/拿快递** | 10:00/16:00/19:00 | 查看取件码→前往→核对→签收 | 15-30分钟 | 带手机、核对信息 |
| **理发/剪头发** | 09:30/14:00/15:00 | 预约→前往→理发→付款 | 1-1.5小时 | 带口罩、告知发型 |
| **银行/取钱/存钱** | 09:30/10:00/14:00 | 准备证件→前往→取号→办理 | 1-2小时 | 带身份证、注意安全 |

**示例问答**：
| 用户问 | AI 答 |
|---|---|
| "计划明天去医院" | "我来帮您制定明天的计划：\n\n📅 建议时间：08:30 / 09:00 / 10:00\n\n📋 事程分解：\n1. 提前预约挂号\n2. 准备病历和医保卡\n3. 按时到达医院\n4. 就诊检查\n5. 取药回家\n\n⏱ 预估耗时：2-3小时\n\n💡 小贴士：\n• 建议提前30分钟到达\n• 记得带上身份证和医保卡\n• 看病前不要空腹\n\n请问是否需要我将这些事程添加到您的待办列表中？" |
| "打算周末去购物" | "我来帮您制定这个周末的计划：\n\n📅 建议时间：09:00 / 10:00 / 16:00\n\n📋 事程分解：\n1. 列出购物清单\n2. 前往超市/菜市场\n3. 按清单采购\n4. 结账回家\n\n⏱ 预估耗时：1-1.5小时\n\n💡 小贴士：\n• 避免在饭点购物，人多拥挤\n• 可以先查看库存，避免重复购买\n\n请问是否需要我将这些事程添加到您的待办列表中？" |

**确认添加交互**：
- 用户回答「好」「好的」「是的」「添加」→ 自动将所有事程分解步骤添加到待办事程
- 用户回答「不」「不用」「算了」→ 取消添加

---

#### 2.3.4 第四类：习惯养成助手

**功能描述**：根据用户想要养成的习惯，提供时间建议、每日步骤、一周计划、坚持小贴士，并支持一键添加到未来7天待办事程

**触发关键词**：「习惯」「养成」「坚持」「开始」「练习」

**习惯分析逻辑**（_analyzeHabit）：

| 习惯类型 | 建议时间 | 每日步骤 | 每次耗时 | 坚持小贴士 |
|---|---|---|---|---|
| **运动/散步/锻炼** | 18:30/19:00 | 换鞋→热身5分钟→运动30分钟→拉伸 | 40分钟 | 从短到长、固定时间、找同伴 |
| **喝水/饮水** | 08:00/10:00/14:00/16:00/18:00 | 起床一杯→10点→2点→4点→6点 | 每天5杯 | 大杯子、设提醒、别等口渴 |
| **阅读/看书/学习** | 20:00/20:30 | 安静环境→读20-30页→记重点→休息 | 30分钟 | 固定时间、做笔记、别读太久 |
| **早睡/作息** | 21:30/22:00 | 21:00洗漱→21:30放下手机→22:00睡觉 | 7-8小时 | 睡前不看屏幕、泡脚、规律作息 |
| **吃药/服药** | 08:00/15:00/21:00 | 早餐后→定时→晚餐后→睡前 | 每日定时 | 设提醒、不增减药量、查有效期 |
| **冥想/放松/静心** | 08:00/21:00 | 舒适姿势→闭眼→专注呼吸→冥想5-10分钟 | 10分钟 | 呼吸平稳、从短开始、坚持更好 |
| **做家务/打扫** | 09:00/15:00 | 整理→扫地→擦拭→清理垃圾 | 30分钟 | 每天一点、放音乐、劳逸结合 |

**一周递进计划**：
- **运动**：15→20→25→30→30→35→40分钟（逐步增加）
- **阅读**：10→15→20→20→25→25页（逐步增加）
- **早睡**：22:30→22:15→22:00→22:00→21:45→21:30（逐步提前）
- **喝水**：每天5杯（保持稳定）

**示例问答**：
| 用户问 | AI 答 |
|---|---|
| "养成运动习惯" | "我来帮您规划养成「运动」习惯：\n\n⏰ 建议时间：18:30 / 19:00\n\n📅 每日步骤：\n1. 换上运动鞋\n2. 热身运动5分钟\n3. 散步/运动30分钟\n4. 拉伸放松5分钟\n\n⏱ 每次耗时：40分钟\n\n📆 一周计划：\n周一：第一天：散步15分钟\n周二：第二天：散步20分钟\n周三：第三天：散步25分钟\n周四：第四天：散步30分钟\n周五：第五天：散步30分钟\n周六：第六天：散步35分钟\n周日：第七天：散步40分钟\n\n💡 坚持小贴士：\n• 从短时间开始，逐渐增加\n• 固定时间更容易坚持\n• 可以找个同伴一起\n• 记录每天的运动情况\n\n请问是否需要我将下周的习惯养成计划添加到您的待办事程中？" |
| "开始养成早睡习惯" | "我来帮您规划养成「早睡」习惯：\n\n⏰ 建议时间：21:30 / 22:00\n\n📅 每日步骤：\n1. 21:00准备洗漱\n2. 21:30放下手机\n3. 22:00上床睡觉\n4. 保证7-8小时睡眠\n\n⏱ 每次耗时：7-8小时\n\n📆 一周计划：\n周一：22:30前睡\n周二：22:15前睡\n周三：22:00前睡\n周四：22:00前睡\n周五：21:45前睡\n周六：21:30前睡\n周日：保持规律作息\n\n💡 坚持小贴士：\n• 睡前1小时不看电子屏幕\n• 保持卧室安静黑暗\n• 睡前可以泡脚放松\n• 每天固定时间睡觉和起床\n\n请问是否需要我将下周的习惯养成计划添加到您的待办事程中？" |

**确认添加交互**：
- 用户回答「好」「好的」等确认词 → 将未来7天的习惯计划自动添加到待办事程
- 用户回答「不」「不用」等拒绝词 → 取消添加

---

#### 2.3.5 第五类：时间线记录查询

**触发关键词**：「今天/昨天/前天/上周」+ 「做了/干什么/发生/记录/做了什么/怎么样/事情/情况」

**日期解析规则**：
| 关键词 | 计算方式 |
|---|---|
| 今天/今日 | todayStr |
| 昨天/昨日 | dateOffset(-1) |
| 前天 | dateOffset(-2) |
| 大前天 | dateOffset(-3) |
| 上周一~日 | dateOffset(-7 + weekday偏移) |
| 最近N天 | DateTime.now().difference < N |

**示例问答**：
| 用户问 | AI 答 |
|---|---|
| "今天做了什么" | "今天您做了以下事情：\n14:30 正在喝水\n12:00 吃完午饭，准备休息 ✓\n10:30 回家，钥匙放在门口鞋柜上了\n..." |
| "昨天做了什么" | "昨天您做了以下事情：\n19:30 吃完晚饭，出去散步\n15:00 吃了降压药 ✓\n..." |
| "最近3天的情况" | "最近3天的记录：\n7/5 14:30 正在喝水\n7/4 19:30 吃完晚饭...\n..." |

---

#### 2.3.6 第六类：事程/待办查询

**触发关键词**：「事程」「待办」「提醒」「还有什么」「要做什么」「有什么事」

**子类**：
- 含「完成/做完」→ 返回已完成事程列表
- 默认 → 返回待办事程列表（含必做标记 + 剩余时间）

**示例问答**：
| 用户问 | AI 答 |
|---|---|
| "今天有什么事程" | "今天还有3项待办事程：\n15:00 吃降压药（必做） 还有30分钟\n18:00 运动\n21:00 吃安眠药（必做）" |
| "完成了什么" | "今天已完成2项事程：\n✓ 09:00 吃药\n✓ 12:00 吃午饭" |

---

#### 2.3.7 第七类：行为统计查询

**触发关键词**：「几次」「多少次」「完成率」「统计」「频率」

**子类**：
- 含「完成率」→ 计算整体完成率百分比
- 含行为关键词 → 从时间线统计该行为出现次数

**示例问答**：
| 用户问 | AI 答 |
|---|---|
| "运动了几次" | "您运动了3次。最近一次：18:00 运动" |
| "吃药几次" | "您吃药了5次。最近一次：09:00 吃完早饭，正在吃药" |
| "完成率多少" | "当前事程完成率为 67%（8/12）。" |

---

#### 2.3.8 第八类：购物记录查询

**触发关键词**：「买」「购物」「超市」「菜」「商店」

**示例问答**：
| 用户问 | AI 答 |
|---|---|
| "最近买了什么" | "最近的购物记录：\n7/2 在超市买了苹果2斤、牛奶3瓶\n7/1 在菜市场买了白菜1颗、猪肉500克、鸡蛋10个" |

---

#### 2.3.9 第九类：常识性问题回答

**功能描述**：覆盖老年用户常见的健康、生活、应急常识问题

**知识库覆盖范围**：

| 类别 | 触发关键词 | 回答内容 |
|---|---|---|
| **实时信息** | 几点/现在时间 | 当前时间（HH点MM分） |
| | 几号/星期几/周几 | 当前日期（年月日 星期X） |
| | 天气 | 引导查看天气应用 |
| **健康指标** | 血压+正常/多少/范围 | 正常血压范围（收缩压90-140，舒张压60-90） |
| | 血糖+正常/多少/范围 | 正常血糖范围（空腹3.9-6.1，餐后<7.8） |
| **用药常识** | 吃药+怎么/注意/饭前饭后 | 常见药物服用时间建议 |
| **饮食建议** | 饮食/吃什么/营养+注意/建议 | 老年人饮食建议（6条） |
| **运动建议** | 运动/锻炼/散步+多少/建议/多久/注意 | 老年人运动建议（6条） |
| **睡眠建议** | 睡眠/失眠/睡不着 | 老年人睡眠建议（6条） |
| **急救常识** | 急救/120/紧急 | 紧急情况处理（胸痛、脑卒中、跌倒）+ 电话 |
| **证件办理** | 驾照+到期/换 | 驾照换证流程（5条） |
| | 身份证+到期/换/补办 | 身份证换证流程（5条） |

**示例问答**：
| 用户问 | AI 答 |
|---|---|
| "几点了" | "现在是15点30分。" |
| "今天几号" | "今天是2026年7月5日，星期六。" |
| "血压正常值是多少" | "正常血压范围：\n• 收缩压（高压）：90-140 mmHg\n• 舒张压（低压）：60-90 mmHg\n• 65岁以上老人收缩压可放宽至150 mmHg\n如有异常，请及时就医。" |
| "降压药什么时候吃" | "一般用药建议：\n• 降血压药：早晨起床后服用\n• 降血糖药：饭前30分钟服用\n• 消炎药：饭后服用（减少胃肠刺激）\n• 安眠药：睡前30分钟服用\n具体用药请遵医嘱，切勿自行调整。" |
| "老年人饮食注意什么" | "老年人饮食建议：\n• 每天饮水1500-1700毫升\n• 少盐少油（盐<6克/天）\n• 多吃蔬菜水果（300-500克蔬菜/天）\n• 适量蛋白质（鸡蛋1个/天，瘦肉50-75克/天）\n• 补钙（牛奶300毫升/天）\n• 少食多餐，细嚼慢咽" |
| "睡不着怎么办" | "老年人睡眠建议：\n• 每天睡眠6-8小时为宜\n• 晚上10点前入睡最佳\n• 午睡20-30分钟，不超过1小时\n• 睡前避免饮茶、咖啡\n• 睡前可用温水泡脚15分钟\n• 长期失眠请就医，勿自行服用安眠药" |
| "驾照到期了怎么换" | "驾照到期换证：\n• 驾照有效期为6年、10年、长期\n• 到期前90天内可换证\n• 需携带：身份证、旧驾照、体检表、照片\n• 可在交管12123 APP在线办理\n• 70岁以上需每年提交体检证明" |

---

#### 2.3.10 兜底引导

**触发条件**：以上九类均未匹配

**回答内容**：
```
我暂时无法回答这个问题，您可以尝试问我：
• 物品放在哪里（如"钥匙在哪"）
• 还有多少（如"药还剩多少"）
• 计划制定（如"计划明天去医院"）
• 习惯养成（如"养成运动习惯"）
• 某天做了什么（如"昨天做了什么"）
• 今日事程（如"今天有什么事程"）
• 常识问题（如"血压正常值"）
```

---

### 3. 习惯（Habits）

#### 3.1 完成率卡片

**功能描述**：显示事程完成率与趋势

**数据来源**：
```
completedCount = agendaItems.filter(a => a.status === 'completed').length
totalCount = agendaItems.length
completionRate = (completedCount / totalCount) * 100
trend = 本周完成率 - 上周完成率 // 正数显示上升箭头
```

**UI 显示**：
- 大数字：「87%」
- 趋势箭头：绿色上升 +5% 或红色下降
- 状态文字：「完成率良好」

---

#### 3.2 热力图（Heatmap）

**功能描述**：展示一周内高频行为的执行情况

**数据结构**：
```
heatmap: [
  [true, true, true, true, true, true, true],  // 吃药 - 7天全完成
  [true, true, true, true, true, true, true],  // 吃饭
  [true, false, true, true, false, true, true], // 运动 - 周二周五未完成
  [true, true, false, true, false, true, false] // 喝水
]
heatmapLabels: ['吃药', '吃饭', '运动', '喝水']
heatmapDays: ['周一', '周二', '周三', '周四', '周五', '周六', '周日']
```

**逻辑**：
- 从 agendaItems 筛选高频事程（isHighFrequency=true）
- 检查每日是否有 completed 状态记录
- true = 绿色圆点，false = 灰色空点

---

#### 3.3 行为排行

**功能描述**：展示最常执行与最易遗漏的行为

**TopRegular（最常执行）**：
```
计算每个高频行为的 completed 记录数
排序取 Top 3
显示：「吃药 7/7天」「吃饭 7/7天」
```

**TopMissed（最易遗漏）**：
```
计算每个高频行为的未完成天数
排序取 Top 3
显示：「喝水 3/7天」「运动 2/7天」
```

---

#### 3.4 标签集锦

**功能描述**：展示所有标签的使用统计

**位置**：行为排行下方（项目硬约束）

**数据来源**：
```typescript
getAllTagsWithStats() {
  // 系统标签 + 自定义标签
  // 统计每个标签在 timelineRecords 中的出现次数
  // 最近使用时间
  // 按次数降序排列
}
```

**时间范围切换**：本周/本月/全部（项目硬约束）

---

#### 3.5 策略优化建议

**功能描述**：根据用户行为数据生成改进建议

**示例**：
```
发现：「最近5次运动提醒都延后30分钟」
建议：「将运动提醒改为18:30」

发现：「每天22:00后不再记录」
建议：「自动设置22:00-08:00免打扰」
```

---

### 4. 我的（Profile）

#### 4.1 用户卡片

**功能描述**：显示用户头像、使用天数、事程完成率

**数据**：
- 头像：渐变圆形 + 人物图标
- 使用天数：从首次使用日期计算
- 完成率：实时计算 agendaItems 完成百分比

---

#### 4.2 菜单列表（3 组 11 项）

**Group 1: 生活管理**
| ID | 功能 | 图标 | 路由 | 子功能 |
|---|---|---|---|---|
| 1 | 物品位置记忆 | 📍 | /items | 物品列表 + 详情 + 位置历史 |
| 2 | 购物记录 | 🛒 | /shopping | 购物历史列表 |
| 3 | 家属管理 | 👨‍👩‍👧 | /family | 绑定家属（2位已绑定） |
| 4 | 紧急求助设置 | 🆘 | /emergency-settings | SOS 按钮配置 |

**Group 2: 系统设置**
| ID | 功能 | 图标 | 路由 | 子功能 |
|---|---|---|---|---|
| 5 | 提醒规则（全局） | 🔔 | /reminder-rules | 三级策略配置 |
| 6 | 免打扰时段 | 🔇 | /quiet-hours | 22:00-08:00 配置 |
| 7 | 报告导出 | 📄 | /report-export | PDF/Excel 导出 |
| 8 | 健康设备对接 | 📱 | /health-devices | 已对接2个设备 |

**Group 3: 其他**
| ID | 功能 | 图标 | 路由 | 子功能 |
|---|---|---|---|---|
| 9 | 隐私与安全 | 🔒 | /privacy-security | 数据加密 + 权限管理 |
| 10 | 偏好设置 | 🎨 | /preferences | 主题 + 字号 + 语言 |
| 11 | 关于与帮助 | ℹ️ | /about-help | 版本 + FAQ + 联系 |

---

### 5. 语音按钮（VoiceButton）

#### 5.1 三态机逻辑

**状态定义**：
```
idle（待机）：
  - 显示：「语音输入」文字 + Mic 图标
  - 颜色：accent（#3D8B7A）
  - 点击 → 进入 recording

recording（录音中）：
  - 显示：「点击停止录音，自动保存」文字 + Square 图标
  - 颜色：红色脉冲动画
  - 波形动画：5 条柱状图交替缩放
  - 点击 → 进入 submitted
  - 3 秒无操作 → 自动进入 submitted

submitted（已提交）：
  - 显示：「已保存」文字 + Check 图标
  - 颜色：accent
  - 1 秒后 → 自动回到 idle
```

#### 5.2 录音流程

**操作步骤**：
1. 点击语音按钮 → 开始录音
2. 说话（最多 3 秒）
3. 点击停止按钮或等待自动停止
4. 语音转文字 → 调用 submitVoiceRecord
5. 显示「已保存」反馈
6. 自动回到待机状态

**兜底方案**：
- 若语音识别失败 → 弹出手动输入框
- 提供 7 条示例短语：「正在喝水」「钥匙放在门口鞋柜」「在超市买了苹果2斤」

---

## 三、智能解析与事程提取

### 1. parseVoiceText 多标签识别

**功能描述**：一句话同时命中多个类型，返回所有标签 + 抽取数据

**解析规则**：

#### 1.1 物品位置识别（item）

**正则**：
```typescript
/(?:把)?([\u4e00-\u9fa5A-Za-z]{1,8}?)(?:放|搁|塞)在?(?:了)?([\u4e00-\u9fa5A-Za-z]+?)(?:上|里|下|旁边|边|里面|上面|下面)?[了]?$/ 
```

**示例**：
- "钥匙放在门口鞋柜" → `tags: ['item']` + `extractedData: { itemName: '钥匙', location: '门口鞋柜', action: 'place' }`
- "把护照搁在衣柜二层里了" → `tags: ['item']`

**副作用**：
- 自动调用 `updateItemLocation(name, location)`
- 更新物品记录的位置历史

---

#### 1.2 购物记录识别（shopping）

**正则**：
```typescript
/在?(.+?)买了(.+)/
// 子匹配：物品 + 数量 + 单位
/([\u4e00-\u9fa5A-Za-z]+?)(\d+(?:\.\d+)?)\s*(斤|公斤|克|千克|瓶|个|盒|袋|包|只|箱|打|份|升|毫升)/g
```

**示例**：
- "在超市买了苹果2斤，牛奶3瓶" → `tags: ['shopping']`
  - extractedData: `{ items: [{name:'苹果',quantity:'2',unit:'斤'}, {name:'牛奶',quantity:'3',unit:'瓶'}], store: '超市' }`

**副作用**：
- 自动创建 ShoppingRecord
- 添加到购物记录列表

---

#### 1.3 行为活动识别（behavior）

**关键词匹配**：
```typescript
['吃', '喝', '睡', '运动', '散步', '跑步', '洗澡', '洗漱', '起床', '吃药', '吃饭', '午饭', '早饭', '晚饭', '喝水']
```

**示例**：
- "正在喝水" → `tags: ['behavior']` + `extractedData: { behavior: '喝水', category: '健康' }`

---

#### 1.3.5 库存消耗识别（inventoryUpdate）

**功能描述**：从语音中识别物品消耗，自动扣减库存

**正则**：
```typescript
/(?:吃了|吃|喝了|喝|用了|用|服用|服)([\u4e00-\u9fa5A-Za-z]{1,10}?)(\d+(?:\.\d+)?)?\s*(片|粒|盒|瓶|个|包|袋|支|颗|毫升|克)?/
```

**品类判断**：
- 含「药/降压/安眠/感冒」→ category = '药品'
- 含「奶/果/菜/肉/蛋/饭」→ category = '食品'
- 其他 → category = '其他'

**数量规则**：
- 有明确数量（如"吃了2片"）→ 使用指定数量
- 无明确数量（如"吃药"）→ 默认 1

**副作用**：
- 自动调用 `updateInventory(name, -quantity, unit, reason: '消耗使用')`
- 库存为 0 时不再扣减（clamp 到 0）

**示例**：
| 话语 | 库存变化 |
|---|---|
| "吃了降压药" | 降压药 -1 片 |
| "吃了2片降压药" | 降压药 -2 片 |
| "喝了一瓶牛奶" | 牛奶 -1 瓶 |
| "用了半袋米" | 米 -0.5 袋 |

---

#### 1.3.6 购物自动入库

**功能描述**：购物记录中的物品自动加入库存

**触发**：购物记录创建时同步执行

**逻辑**：
```typescript
for (item of shoppingRecord.items) {
  updateInventory(item.name, item.quantity, item.unit, reason: '购买入库')
}
```

**示例**：
- "在超市买了苹果2斤，牛奶3瓶" → 苹果 +2 斤，牛奶 +3 瓶

---

#### 1.4 日常事件识别（event）

**关键词匹配**：
```typescript
['回家', '出门', '下班', '到', '去', '拿', '取', '送', '接', '回', '来', '走']
```

**逻辑**：
- 若话语包含事件动词 → 添加 'event' 标签
- 若无其他标签 → 默认添加 'event' 作为兜底

**示例**：
- "回家，钥匙放在门口鞋柜" → `tags: ['event', 'item']`

---

#### 1.5 事程意图识别

**核心问题**：判断一句话是「创建提醒」还是「完成事程」

**判断逻辑**：

**创建事程信号**：
```typescript
reminderKeywords = ['记得', '别忘了', '提醒我', '要记得', '一定要', '需要', '要做', '得去', '准备']
mustDoKeywords = ['必做', '必须', '一定', '务必']
futureTimeKeywords = ['明天', '下周', '下次', '以后']
```

**完成事程信号**：
```typescript
completedKeywords = ['正在', '在', '刚', '刚刚', '已经', '过了', '完了', '吃完了', '喝完了', '吃过了', '做完了', '了']
pastSuffixes = ['完了', '过了', '好了', '完', '过']
```

**时间对比判断**：
```
若话语包含具体时间（如"15:00"）：
  - 时间已过（<当前时间且差值<2小时）→ 完成
  - 时间未到 → 创建
```

**示例**：
| 话语 | 判断结果 | 操作 |
|---|---|---|
| "记得吃药" | 创建 | 创建事程 "吃药" |
| "正在吃药" | 完成 | 匹配已有事程并标记完成 |
| "刚吃完午饭" | 完成 | 匹配已有事程 "午饭" |
| "明天记得去医院" | 创建 | 创建事程，日期=明天 |
| "喝水"（无其他词）| 完成 | 匹配已有事程（默认陈述事实） |

---

#### 1.6 多事程拆分

**触发条件**：一句话包含多个时间点或「还有」「然后」「再」

**示例**：
- "明天记得吃药和买菜" → 拆分为 `agendaList: [{content:'吃药',time:'09:00'}, {content:'买菜',time:'10:00'}]`

**处理**：
- 多事程 → 加入 pendingAgendaConfirm 队列
- 弹出确认弹窗让用户逐项确认

---

### 2. submitVoiceRecord 综合处理流程

**Step 1: 智能解析**
```typescript
parsed = parseVoiceText(text)
tags = parsed.tags
extractedData = parsed.extractedData
```

**Step 2: 标签偏好查询**
```typescript
// 用户曾手动调整过的话语关键词 → 使用偏好标签
if (extractedData.item?.itemName) prefKey = `item:${itemName}`
if (tagPreferences[prefKey]) tags = tagPreferences[prefKey]
```

**Step 3: 事程处理**
```typescript
if (parsed.sideEffects.agendaList) {
  // 多事程 → 加入待确认队列
  for (ag of agendaList) {
    time = smartTime(ag) // 三级推断
    pendingAgenda.push({ content, time, timeSource })
  }
} else if (parsed.sideEffects.agenda) {
  // 单事程 → 加入待确认队列
  pendingAgenda.push(smartTime(ag))
} else {
  // 无新建事程信号 → 尝试匹配已有事程
  matchKeyword = extractedData.behavior?.behavior
  matchedAgenda = agendaItems.find(a => a.content.includes(matchKeyword) && a.status === 'pending')
  if (matchedAgenda) completeAgenda(matchedAgenda.id)
}
```

**Step 4: 创建时间线记录**
```typescript
timelineId = addTimelineRecord({
  time: nowTime(),
  content: text,
  matchedAgenda: matchedAgenda ? `${matchedAgenda.time}${matchedAgenda.content}` : undefined,
  status: matchedAgenda ? 'matched' : 'unmatched',
  tags,
  extractedData,
})
```

**Step 5: 副作用同步**
```typescript
if (parsed.sideEffects.shoppingRecord) addShoppingRecord(shoppingRecord)
if (parsed.sideEffects.itemUpdate) updateItemLocation(name, location)
```

---

## 四、时间推断三级策略

### 优先级排序

```
Level 1: 用户指定时间（最优先）
Level 2: 历史习惯时间（次优先）
Level 3: 常识默认时间（再次）
Level 4: 当前时间兜底（最后）
```

### Level 1: 用户指定时间

**识别方式**：
- 话语中包含 HH:mm 格式："15:00记得吃药"
- 话语中包含「点」格式："3点记得吃药"
- 话语中包含时段："下午3点记得吃药"

**处理**：
```typescript
hhmmMatch = text.match(/(\d{1,2})[:：](\d{2})/)
pointMatch = text.match(/(\d{1,2})点(?:(\d{1,2})分)?/)
periodMatch = text.match(/(早上|上午|中午|下午|晚上|凌晨)(\d{1,2})?/)
// 下午/晚上小时<12 → +12
// 凌晨12点 → 0点
```

---

### Level 2: 历史习惯时间

**触发条件**：用户未指定时间，但历史记录中有相同行为

**计算逻辑**：
```typescript
inferAgendaTimeByContent(content) {
  keyword = content.match(/(吃药|吃饭|早饭|午饭|晚饭|运动|散步|喝水|睡觉|起床|洗漱)/)?.[1]
  matchedRecords = timelineRecords.filter(r => r.content.includes(keyword))
  
  totalMinutes = matchedRecords.reduce((sum, r) => {
    [h, m] = r.time.split(':')
    return sum + h*60 + m
  }, 0)
  
  avgMinutes = totalMinutes / matchedRecords.length
  return `${avgHour}:${avgMin}`
}
```

**示例**：
- 用户过去 10 次「吃药」平均时间 08:15 → 推荐时间 08:15
- 来源标记：timeSource = 'history'

---

### Level 3: 常识默认时间

**规则表**：
```typescript
inferAgendaTimeByCommonSense(content) {
  if (/早饭|早餐/.test(content)) return '07:30'
  if (/午饭|午餐|吃中饭/.test(content)) return '12:00'
  if (/晚饭|晚餐|吃晚饭/.test(content)) return '18:00'
  if (/吃药/.test(content)) return '08:00'  // 默认早饭后
  if (/起床/.test(content)) return '07:00'
  if (/睡觉|休息/.test(content)) return '22:00'
  if (/运动|散步|跑步|锻炼/.test(content)) return '18:30'
  if (/喝水/.test(content)) return `${当前小时+1}:00`
  if (/洗漱|洗脸|刷牙/.test(content)) return '07:15'
  return null
}
```

---

### Level 4: 当前时间兜底

**触发条件**：以上三级均未匹配

**处理**：
```typescript
time = `${now.getHours()}:${now.getMinutes()}`
timeSource = 'current'
```

---

## 五、提醒逻辑

### 1. 必做事程四阶段提醒

**策略**（项目硬约束）：
```
必做事程（isMustDo=true）触发四阶段提醒：
- 提前 30 分钟：温和提醒
- 提前 10 分钟：重要提醒
- 到时：紧急提醒
- 过后 10 分钟：超时提醒（仍可完成）
```

---

### 2. 到时检测逻辑

**触发时机**：每分钟检查（首页定时器）

**检测逻辑**：
```typescript
checkAgendaReminders() {
  nowTime = `${hour}:${minute}`
  matchedAgenda = agendaItems.find(a => 
    a.date === todayStr && 
    a.status === 'pending' && 
    a.time === nowTime
  )
  if (matchedAgenda) {
    activeReminder = matchedAgenda
    return matchedAgenda
  }
  return null
}
```

---

### 3. 提醒弹窗交互

**内容**：
- 事程图标 + 内容
- 剩余时间提示（"还有10分钟"）
- 备注（如有）

**按钮**：
- 完成 → `completeAgenda(id)`
- 推迟10分钟 → `postponeAgenda(id, 10)`
- 推迟30分钟 → `postponeAgenda(id, 30)`
- 关闭 → 仅关闭弹窗

---

## 六、标签系统

### 1. 系统内置标签（不可删除）

| ID | 名称 | 颜色 | 图标 | 说明 |
|---|---|---|---|---|
| behavior | 行为活动 | accent | 📊 | 吃药、吃饭、运动等 |
| item | 物品位置 | info | 📦 | 物品放置记录 |
| shopping | 购物记录 | warning | 🛒 | 购物清单 |
| event | 日常事件 | success | 📍 | 出门、回家、拿快递等 |

---

### 2. 自定义标签

**约束**：
- 上限 20 个（项目硬约束）
- 名称唯一校验（不可与系统标签重名）
- 可自定义颜色与图标

**删除逻辑**：
- 删除自定义标签后，历史记录中的 tags 数组保留该标签 ID
- 渲染时查找标签定义，若找不到 → 显示灰色「已删除」标签

---

### 3. 标签集锦统计

**数据来源**：
```typescript
getAllTagsWithStats() {
  // 统计每个标签在 timelineRecords 中的出现次数
  // 计算最近使用时间
  // 按次数降序排列
}
```

**时间范围切换**：
- 本周：筛选 date 在最近 7 天的记录
- 本月：筛选 date 在最近 30 天的记录
- 全部：全部记录

---

## 七、AI 智能推荐逻辑

### 1. 高频行为提取

**触发时机**：每日首次打开首页

**步骤**：

**Step 1: 筛选行为记录**
```typescript
behaviorRecords = timelineRecords.filter(r => r.tags.includes('behavior'))
```

**Step 2: 关键词提取与计数**
```typescript
behaviorCounts = {}
for (record of behaviorRecords) {
  keywordMatch = record.content.match(/(吃药|吃饭|早饭|午饭|晚饭|运动|散步|跑步|喝水|睡觉|起床|洗漱|阅读|锻炼)/)
  keyword = keywordMatch ? keywordMatch[1] : record.content.slice(0, 2)
  
  behaviorCounts[keyword] = { count: 0, times: [] }
  behaviorCounts[keyword].count++
  
  [h, m] = record.time.split(':')
  behaviorCounts[keyword].times.push(h*60 + m)
}
```

**Step 3: 筛选高频行为**
```typescript
highFreqBehaviors = Object.entries(behaviorCounts)
  .filter(([keyword, data]) => data.count >= 3)
  .sort((a, b) => b[1].count - a[1].count)
```

**Step 4: 计算平均时间**
```typescript
for ([keyword, data] of highFreqBehaviors) {
  avgMinutes = Math.round(data.times.reduce((a,b) => a+b, 0) / data.times.length)
  avgHour = Math.floor(avgMinutes / 60)
  avgMin = avgMinutes % 60
  time = `${avgHour}:${avgMin}`
}
```

**Step 5: 检查今日事程**
```typescript
todayAgendas = agendaItems.filter(a => a.date === todayStr)
todayContents = todayAgendas.map(a => a.content)

// 若今日已存在相同内容事程 → 跳过
if (todayContents.some(c => c.includes(keyword))) continue
```

**Step 6: 自动添加**
```typescript
addAgenda({
  date: todayStr,
  time: avgTime,
  content: keyword,
  icon: autoDetectIcon(keyword),
  isMustDo: false,
  source: 'ai',
  isHighFrequency: true,
})
```

---

### 2. autoDetectIcon 图标识别

```typescript
autoDetectIcon(content) {
  if (/药/.test(content)) return '💊'
  if (/饭|餐|食/.test(content)) return '🍚'
  if (/水|喝/.test(content)) return '💧'
  if (/运动|散步|跑步|锻炼|走/.test(content)) return '🏃'
  if (/睡|休息|午休/.test(content)) return '🛏'
  if (/读|看|学|书/.test(content)) return '📖'
  if (/买|购|超市/.test(content)) return '🛒'
  if (/洗|清洁|打扫/.test(content)) return '🧹'
  if (/车|出行|出发|出差|飞/.test(content)) return '✈️'
  if (/会|开|办公|工作/.test(content)) return '📋'
  return '📋'
}
```

---

## 八、已完成内容清单

### Flutter Android 实现（已构建 APK）

#### 1. 核心基础设施 ✅
| 模块 | 文件 | 说明 |
|---|---|---|
| 颜色体系 | app_colors.dart | 主题色、渐变、阴影、7 种标签颜色 |
| 数据模型 | app_models.dart | 20 个枚举 + 类定义（含库存模型） |
| Mock 数据 | mock_data.dart | 14 条时间线 + 12 条事程 + 购物/物品/对话/库存数据 |
| 状态管理 | app_store.dart | Provider + ChangeNotifier，~40 个 action |
| 路由定义 | route_names.dart | 20 条路由常量 |

---

#### 2. 布局框架 ✅
| 模块 | 文件 | 说明 |
|---|---|---|
| 主布局 | main_layout.dart | 底部导航 + 语音按钮 + SafeArea |
| 二级布局 | secondary_layout.dart | 顶部返回栏 + 标题 + 操作按钮 |
| 底部导航 | bottom_nav.dart | 4 Tab：首页→问一问→习惯→我的 |
| 应用入口 | app.dart + main.dart | MaterialApp + Provider 注册 |

---

#### 3. 共享组件 ✅
| 组件 | 文件 | 说明 |
|---|---|---|
| 语音按钮 | voice_button.dart | 三态机 + 按住-松手录音 + 波形动画 + 手动输入兜底 |
| 事程卡片 | agenda_item.dart | 左滑删除二次确认 + 必做/高频/AI 徽章 |
| 时间线项 | timeline_item.dart | 多标签徽章 + 匹配事程标记 |

---

#### 4. 四个主 Tab 页面 ✅
| 页面 | 文件 | 核心功能 |
|---|---|---|
| 首页 | home_page.dart | 时间线/事程双 Tab + 日历弹窗 + 问候语 + 到时提醒弹窗 + 添加事程弹窗 |
| 问一问 | ask_page.dart | 聊天界面 + 5 个快捷问题 + 思考动画 |
| 习惯 | habits_page.dart | 完成率卡 + 热力图 + 行为排行 + 标签集锦 + 策略建议 |
| 我的 | profile_page.dart | 用户卡 + 3 组 11 项菜单 |

---

#### 5. 二十个二级页面 ✅
| 分类 | 页面 | 文件 |
|---|---|---|
| 事程 | 详情、编辑、常用事程 | agenda_detail_page.dart, edit_agenda_page.dart, frequent_agenda_page.dart |
| 时间线 | 详情 | timeline_detail_page.dart |
| 物品 | 列表、详情 | items_page.dart, item_detail_page.dart |
| 购物 | 记录 | shopping_page.dart |
| 分析 | 周报、行为分析 | weekly_report_page.dart, behavior_analysis_page.dart |
| 问一问 | 聊天历史 | chat_history_page.dart |
| 标签 | 管理 | tag_management_page.dart |
| 我的 | 9 个子页面 | family/emergency_settings/reminder_rules/quiet_hours/report_export/health_devices/privacy_security/preferences/about_help_page.dart |

---

#### 6. 构建状态 ✅
- `flutter pub get` 成功
- `flutter analyze` 0 错误（仅 lint info/warning）
- `flutter build apk --debug` 成功
- 输出：[app-debug.apk](file:///e:/github/DailyAwarenessApp/frontend/build/app/outputs/flutter-apk/app-debug.apk) (151 MB)

---

## 九、待完成内容清单

### 1. 功能逻辑补全

| 功能 | 当前状态 | 说明 |
|---|---|---|
| 库存管理 | ✅ 完成 | 库存自动追踪 + 消耗扣减 + 还能用几天计算（库存预警/保质期提醒预留扩展位） |
| 时间推断 UI | ✅ 完成 | 首页事程 Tab 顶部显示"待确认事程"卡片，可调时间/确认/取消 |
| 提醒规则页 | ✅ 完成 | 三级策略（普通/重要/必做）支持开关 + 提前时间/重复次数配置 + 一键复原 |
| 标签管理 | ✅ 完成 | 新增/删除/重命名交互 + 20 上限校验 + 使用次数统计 |
| 热力图数据 | ✅ 完成 | computeHeatmap 从 timelineRecords 动态计算 4 行为×7 天 |
| 行为排行 | ✅ 完成 | computeBehaviorRanking 动态计算 TopRegular/TopMissed |
| 完成率 | ✅ 完成 | computeCompletionRate 按本周/本月/全部动态计算 |
| 免打扰时段 | ✅ 完成 | 总开关 + 时段选择 + 跨天检测 + 紧急提醒白名单 |

---

### 2. 已完成的功能逻辑（新增）

| 功能 | 完成状态 | 说明 |
|---|---|---|
| AI 问答引擎 | ✅ 完成 | answerQuestion 九类匹配（物品/库存/计划/习惯/时间线/事程/统计/购物/常识） |
| 库存自动追踪 | ✅ 完成 | 购物自动入库 + 消耗自动扣减 + 日志记录 |
| 库存查询 | ✅ 完成 | 剩余数量 + 还能用几天 + 品类总览 + 使用量统计 |
| 计划制定助手 | ✅ 完成 | 时间建议 + 事程分解 + 耗时预估 + 用户确认后一键添加待办 |
| 习惯养成助手 | ✅ 完成 | 时间建议 + 每日步骤 + 一周递进计划 + 坚持小贴士 + 用户确认后一键添加7天待办 |
| 物品位置查询 | ✅ 完成 | 从 items + timelineRecords 双源检索 |
| 时间线记录查询 | ✅ 完成 | 支持今天/昨天/前天/上周/最近N天 |
| 事程/待办查询 | ✅ 完成 | 待办列表 + 已完成列表 |
| 行为统计查询 | ✅ 完成 | 次数统计 + 完成率 |
| 常识性问题 | ✅ 完成 | 健康/用药/饮食/运动/睡眠/急救/证件 8 大类 |
| 日程冲突检测 | ✅ 完成 | 计划制定时检测时间冲突并警告 |
| 完成 feedback 鼓励 | ✅ 完成 | 监听时间线记录，完成事程自动鼓励+触发徽章 |
| 智能时间优化 | ✅ 完成 | 基于历史推迟率自动调整建议时间 |
| 多轮对话支持 | ✅ 完成 | 5分钟内上下文关联，支持"改到后天"等修改 |
| TTS 语音朗读 | ✅ 完成 | AI 回答支持播放/停止朗读 |
| 个性化建议 | ✅ 完成 | 基于用户档案（年龄/健康状况）附加建议 |
| 计划模板库 | ✅ 完成 | 8个常用计划模板（医院/旅行/生日/体检等） |
| 习惯徽章系统 | ✅ 完成 | 6级徽章（3/7/14/21/30/100天），自动奖励 |

---

### 3. 数据持久化 ✅

| 项目 | 状态 | 说明 |
|---|---|---|
| 本地存储引擎 | ✅ 完成 | StorageService 使用 SharedPreferences 存储 JSON |
| 启动加载 | ✅ 完成 | AppStore 构造时从 StorageService 加载所有数据 |
| 变化自动保存 | ✅ 完成 | notifyListeners 重写，触发 _persistAll() 保存全部数据 |
| 数据清空 | ✅ 完成 | clearAll() 一键清空所有本地数据 |
| 持久化数据类型 | ✅ 完成 | 时间线/事程/购物/物品/库存/自定义标签/聊天/徽章/用户档案/提醒规则/免打扰时段 |
| JSON 序列化 | ✅ 完成 | 完整的双向 JSON 转换方法，含日期/枚举/嵌套对象 |

---

### 4. 真实语音识别 ✅

| 项目 | 状态 | 说明 |
|---|---|---|
| SpeechService 服务 | ✅ 完成 | 单例模式，预留 speech_to_text 接口 |
| 按住-松手录音 | ✅ 完成 | GestureDetector onPanDown/onPanEnd/onPanCancel |
| 实时识别输出 | ✅ 完成 | resultStream 广播流，UI 实时显示识别文本 |
| 状态监听 | ✅ 完成 | stateStream 广播流 |
| 取消录音 | ✅ 完成 | 移出区域取消，不保存结果 |
| 最大录音时长 | ✅ 完成 | 60 秒自动停止 |
| 模拟识别 | ✅ 完成 | 当前模拟实现，集成 speech_to_text 后即可切换真实识别 |
| 手动输入兜底 | ✅ 完成 | 键盘图标按钮，弹出输入对话框 |

---

### 5. 提醒推送 ✅

| 项目 | 状态 | 说明 |
|---|---|---|
| NotificationService 服务 | ✅ 完成 | 单例模式，预留 flutter_local_notifications 接口 |
| 必做四阶段提醒 | ✅ 完成 | 提前30/提前10/到时/过后10分钟 |
| 普通提醒 | ✅ 完成 | 提前N分钟 + 重复M次（间隔5分钟） |
| 免打扰检测 | ✅ 完成 | isQuietHours 支持跨天（如 22:00-08:00） |
| 事程关联 | ✅ 完成 | addAgenda 自动调度、completeAgenda/postponeAgenda/deleteAgenda 自动取消 |
| 级别参数 | ✅ 完成 | 根据事程级别（普通/重要/必做）从 reminderRules 读取参数 |
| 即时通知 | ✅ 完成 | showImmediate 立即推送通知 |
| 通知流 | ✅ 完成 | notificationStream 广播流，UI 可订阅 |
| 通知类型 | ✅ 完成 | agenda/inventory/habit/badge/general 5 类 |

---

### 6. 其他优化

| 项目 | 说明 |
|---|---|
| 多语言支持 | 当前仅中文 |
| 主题切换 | 当前固定 Material 3 主题 |
| 用户数据导出 | 报告导出页面仅 UI，需实现 PDF/Excel 生成 |
| 家属管理 | 仅 UI，需实现家属绑定 + 数据共享 |

---

## 十、关键约束汇总（来自项目记忆）

| 约束 | 说明 |
|---|---|
| 时间线条目单记录创建 | 不拆分意图，一句话一条记录 |
| 语音录制无中间确认 | 录音停止直接保存 |
| 标签自动生成无预览 | 解析后直接附加标签 |
| 自定义标签上限 20 | 超出拒绝创建 |
| 已删除标签保留历史 | 显示灰色「已删除」标签 |
| 标签集锦位置 | 位于行为排行下方 |
| 标签统计时间范围 | 支持本周/本月/全部切换 |
| 新标签默认图标 | # 符号 |
| 补充记录语音输入 | 点击直接开始录音，停止自动保存 |
| 补充记录播放器尺寸 | w-7 h-7（比原始语音 w-10 小） |
| 补充记录删除交互 | 长按 600ms 或右键触发确认 |
| 语音按钮三态机 | idle/recording/submitted |
| 录音交互方式 | 按住说话，松手停止（最大60秒自动停止） |
| 语音播放动画 | 文字高亮 accent 色 + 播放器红色脉冲 |
| 事程左滑删除二次确认 | 继续滑动才弹出确认 |
| 历史日期右上角按钮 | 「回到今天」绿色按钮 |
| 今日右上角状态 | 「今日 X/Y」非点击文字 |
| AI 推荐自动添加 | 无需用户确认，蓝色 AI 徽章 |
| 必做四阶段提醒 | 提前 30/10 分钟 + 到时 + 过后 10 分钟 |

---

## 十一、问一问增强功能（已实现）

### 1. 日程冲突检测 ✅
**功能描述**：在计划制定时，自动检测与已有事程的时间冲突

**实现位置**：[app_store.dart](file:///e:/github/DailyAwarenessApp/frontend/lib/core/state/app_store.dart) `_answerPlanQuery` 方法

**场景**：用户说"计划明天去医院"，系统检测到明天 09:00 已有"吃降压药"事程

**示例输出**：
```
⚠️ 注意：明天 的 09:00 已有事程安排，建议选择其他时间。

我来帮您制定明天的计划：
📅 建议时间：08:30 / 09:00 / 10:00
...
```

### 2. 计划/习惯完成反馈 ✅
**功能描述**：用户在时间线记录完成内容时，自动给予鼓励反馈

**实现位置**：[app_store.dart](file:///e:/github/DailyAwarenessApp/frontend/lib/core/state/app_store.dart) `_checkCompletionFeedback` 方法

**触发逻辑**：
- 监听 submitVoiceRecord 中的文本
- 匹配完成信号词（做完/完成了/做好了/搞定了）
- 匹配今日 pending 状态的待办事程
- 自动标记完成 + 发送鼓励消息到聊天

**示例反馈**：
```
🎉 太棒了！您完成了「运动」！
连续坚持 7 天，继续保持！

🎉 太棒了！您完成了「散步」！

🏆 太棒了！您完成了「散步」！

太棒了！您已连续完成 7 天「散步」，获得「一周坚持」徽章 ⭐
连续坚持7天
继续保持，养成好习惯！
```

### 3. 智能推荐改进 ✅
**功能描述**：基于历史推迟率自动优化时间建议

**实现位置**：[app_store.dart](file:///e:/github/DailyAwarenessApp/frontend/lib/core/state/app_store.dart) `_optimizeTimeByHistory` 方法

**算法**：
```
1. 找出与计划内容相关的历史事程
2. 数据 >= 3 条才优化
3. 统计推迟率 = postponed / total
4. 推迟率 < 30% 不调整
5. 计算实际平均完成时间
6. 用平均时间替换首个建议时间
```

**示例**：用户历史5次运动都推迟到19:30，系统将建议时间从18:30改为19:30

### 4. 多轮对话支持 ✅
**功能描述**：支持上下文关联的多轮对话

**实现位置**：[app_store.dart](file:///e:/github/DailyAwarenessApp/frontend/lib/core/state/app_store.dart) `ConversationContext` + `_handlePlanContextUpdate` 方法

**上下文有效期**：5分钟内（[ConversationContext.isActive](file:///e:/github/DailyAwarenessApp/frontend/lib/core/models/app_models.dart#L559-L560)）

**示例对话**：
```
用户："计划明天去医院"
AI："我来帮您制定明天的计划...（可以说"改到后天"或"换个时间"来调整）"

用户："改到后天"
AI："已将计划调整到后天，时间和其他内容保持不变。是否需要添加到待办列表？"

用户："换个时间，下午3点"
AI："已将首个时间调整为 15:00，其他时间不变。是否需要添加到待办列表？"

用户："好的"
AI："已成功将 5 项事程添加到后天的待办列表中！..."
```

### 5. 语音对话优化（TTS 朗读） ✅
**功能描述**：AI 回答支持语音朗读

**实现位置**：[tts_service.dart](file:///e:/github/DailyAwarenessApp/frontend/lib/core/services/tts_service.dart) + [ask_page.dart](file:///e:/github/DailyAwarenessApp/frontend/lib/features/ask/presentation/pages/ask_page.dart#L33-L43)

**交互**：
- AI 回答气泡底部显示「🔊 朗读」按钮
- 点击开始朗读，按钮变为「⏹ 停止」
- 朗读完成自动恢复

**实现说明**：当前为模拟实现，集成 `flutter_tts` 包后即可使用真实 TTS（已预留接口）

### 6. 个性化建议 ✅
**功能描述**：根据用户档案（年龄、健康状况）提供个性化建议

**实现位置**：[app_store.dart](file:///e:/github/DailyAwarenessApp/frontend/lib/core/state/app_store.dart) `_getPersonalizedTips` 方法 + [UserProfile](file:///e:/github/DailyAwarenessApp/frontend/lib/core/models/app_models.dart#L447-L485) 模型

**用户档案**（默认）：
- 姓名：王大爷
- 年龄：68
- 健康状况：高血压、轻度糖尿病
- 偏好：温和运动、室内活动、早睡早起

**个性化触发规则**：

| 用户特征 | 计划类型 | 附加建议 |
|---|---|---|
| 高血压 | 运动 | 您有高血压，运动时注意不要剧烈，建议散步等温和运动 |
| 高血压 | 医院 | 记得告知医生您的高血压情况，按时服用降压药 |
| 糖尿病 | 吃饭 | 您有糖尿病，注意控制碳水摄入，少食多餐 |
| 糖尿病 | 医院 | 记得告知医生您的糖尿病情况 |
| 65岁以上 | 运动（非散步） | 建议选择温和运动如散步、太极，避免剧烈运动 |
| 65岁以上 | 出门 | 出门记得带好常用药品和紧急联系人电话 |

### 7. 计划模板库 ✅
**功能描述**：提供常用计划模板，用户可查询和选用

**实现位置**：[mock_data.dart](file:///e:/github/DailyAwarenessApp/frontend/lib/core/mock/mock_data.dart#L415-L497) + [app_store.dart](file:///e:/github/DailyAwarenessApp/frontend/lib/core/state/app_store.dart#L839-L852) `_answerTemplateQuery`

**模板列表**（8个）：

| 模板名 | 图标 | 类别 | 步骤数 | 预估耗时 |
|---|---|---|---|---|
| 医院复诊 | 🏥 | 医疗 | 5 | 2-3小时 |
| 旅行准备 | ✈️ | 出行 | 5 | 半天 |
| 生日准备 | 🎂 | 家庭 | 5 | 1天 |
| 体检准备 | 🩺 | 医疗 | 5 | 2-3小时 |
| 理发 | 💈 | 生活 | 4 | 1-1.5小时 |
| 超市购物 | 🛒 | 生活 | 4 | 1-1.5小时 |
| 银行业务 | 🏦 | 生活 | 5 | 1-2小时 |
| 家庭清洁 | 🧹 | 家务 | 4 | 1-2小时 |

**查询示例**：
```
用户："有哪些计划模板"
AI："📋 计划模板库（共8个）：
1. 🏥 医院复诊（医疗）
   预估：2-3小时
2. ✈️ 旅行准备（出行）
   预估：半天
..."
```

### 8. 习惯打卡激励（徽章系统） ✅
**功能描述**：连续完成习惯给予徽章奖励

**实现位置**：[app_store.dart](file:///e:/github/DailyAwarenessApp/frontend/lib/core/state/app_store.dart#L185-L217) + [HabitBadge](file:///e:/github/DailyAwarenessApp/frontend/lib/core/models/app_models.dart#L510-L525)

**徽章体系**（6个等级）：

| 徽章 | 图标 | 连续天数 | 说明 |
|---|---|---|---|
| 初学者 | 🌱 | 3 | 连续坚持3天 |
| 一周坚持 | ⭐ | 7 | 连续坚持7天 |
| 两周达人 | 🌟 | 14 | 连续坚持14天 |
| 习惯养成 | 🏆 | 21 | 连续坚持21天，习惯已养成 |
| 月度冠军 | 👑 | 30 | 连续坚持30天 |
| 百日坚持 | 💎 | 100 | 连续坚持100天，了不起！ |

**触发逻辑**：
- 用户在时间线记录完成习惯（如"做完运动了"）
- 系统自动计算连续天数 `getHabitStreak`
- 检查是否达到新徽章 `checkAndAwardBadge`
- 达到则发送奖励消息到聊天

**查询示例**：
```
用户："我有几个徽章"
AI："🏆 我的徽章：

🔒 初学者（连续3天）
🔒 一周坚持（连续7天）
🔒 两周达人（连续14天）
🔒 习惯养成（连续21天）
🔒 月度冠军（连续30天）
🔒 百日坚持（连续100天）

已获得 0/6 个徽章"

用户："运动连续几天"
AI："🏃 您已连续运动 5 天。

下一个徽章：⭐ 一周坚持（需连续7天）
还需坚持 2 天"
```

---

## 十二、文件索引

### Web-prototype 原型源码（参考）

| 文件 | 说明 |
|---|---|
| [appStore.ts](file:///e:/github/DailyAwarenessApp/web-prototype/src/store/appStore.ts) | 状态管理核心，含 parseVoiceText + submitVoiceRecord + 时间推断 |
| [mockData.ts](file:///e:/github/DailyAwarenessApp/web-prototype/src/data/mockData.ts) | Mock 数据定义 |
| [tailwind.config.js](file:///e:/github/DailyAwarenessApp/web-prototype/tailwind.config.js) | 设计系统（颜色/字号/阴影） |
| [index.css](file:///e:/github/DailyAwarenessApp/web-prototype/src/index.css) | 自定义动画（波形/脉冲） |

---

### Flutter Android 实现

| 文件 | 说明 |
|---|---|
| [app_colors.dart](file:///e:/github/DailyAwarenessApp/frontend/lib/core/constants/app_colors.dart) | 颜色体系 |
| [app_models.dart](file:///e:/github/DailyAwarenessApp/frontend/lib/core/models/app_models.dart) | 数据模型 |
| [mock_data.dart](file:///e:/github/DailyAwarenessApp/frontend/lib/core/mock/mock_data.dart) | Mock 数据 |
| [app_store.dart](file:///e:/github/DailyAwarenessApp/frontend/lib/core/state/app_store.dart) | 状态管理 |
| [voice_button.dart](file:///e:/github/DailyAwarenessApp/frontend/lib/shared/widgets/voice_button.dart) | 语音按钮组件 |
| [agenda_item.dart](file:///e:/github/DailyAwarenessApp/frontend/lib/shared/widgets/agenda_item.dart) | 事程卡片组件 |
| [home_page.dart](file:///e:/github/DailyAwarenessApp/frontend/lib/features/home/presentation/pages/home_page.dart) | 首页 |
| [ask_page.dart](file:///e:/github/DailyAwarenessApp/frontend/lib/features/ask/presentation/pages/ask_page.dart) | 问一问 |
| [habits_page.dart](file:///e:/github/DailyAwarenessApp/frontend/lib/features/habits/presentation/pages/habits_page.dart) | 习惯 |
| [profile_page.dart](file:///e:/github/DailyAwarenessApp/frontend/lib/features/profile/presentation/pages/profile_page.dart) | 我的 |

---

**文档结束**

*生成时间：2026-07-05*
*基于 web-prototype 源码 + Flutter 实现 + 项目记忆约束*
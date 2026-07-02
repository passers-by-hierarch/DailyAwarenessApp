# 03 - API接口设计

## 1. API设计规范

### 1.1 基本原则

| 原则            | 说明                                               |
| --------------- | -------------------------------------------------- |
| **RESTful风格** | 使用标准HTTP方法（GET/POST/PUT/DELETE）            |
| **资源命名**    | 使用复数名词，如 `/users`, `/agendas`, `/timeline` |
| **版本控制**    | URL路径包含版本号 `/api/v1/...`                    |
| **统一响应**    | 标准响应格式，包含code、message、data              |
| **错误处理**    | 统一错误码定义，清晰的错误信息                     |
| **认证鉴权**    | JWT Token认证，Bearer方式                          |
| **分页查询**    | 使用page/pageSize或cursor分页                      |

### 1.2 统一响应格式

```json
// 成功响应
{
  "code": 200,
  "message": "success",
  "data": {
    // 业务数据
  },
  "timestamp": "2024-06-22T14:30:00Z"
}

// 错误响应
{
  "code": 40001,
  "message": "参数错误：planned_time不能为空",
  "error": "INVALID_PARAM",
  "details": {
    "field": "planned_time",
    "reason": "required field missing"
  },
  "timestamp": "2024-06-22T14:30:00Z"
}

// 分页响应
{
  "code": 200,
  "message": "success",
  "data": {
    "items": [...],
    "pagination": {
      "page": 1,
      "pageSize": 20,
      "total": 100,
      "totalPages": 5,
      "hasNext": true
    }
  },
  "timestamp": "2024-06-22T14:30:00Z"
}
```

### 1.3 HTTP状态码使用

| 状态码  | 使用场景               |
| ------- | ---------------------- |
| **200** | 成功                   |
| **201** | 创建成功               |
| **204** | 删除成功（无返回内容） |
| **400** | 参数错误               |
| **401** | 未认证/Token失效       |
| **403** | 无权限                 |
| **404** | 资源不存在             |
| **409** | 资源冲突               |
| **429** | 请求频率超限           |
| **500** | 服务端错误             |
| **503** | 服务不可用             |

### 1.4 错误码定义

| 错误码    | 错误类型       | 说明         |
| --------- | -------------- | ------------ |
| **40001** | INVALID_PARAM  | 参数错误     |
| **40002** | MISSING_PARAM  | 缺少必填参数 |
| **40003** | INVALID_FORMAT | 格式错误     |
| **40101** | UNAUTHORIZED   | 未认证       |
| **40102** | TOKEN_EXPIRED  | Token过期    |
| **40103** | TOKEN_INVALID  | Token无效    |
| **40301** | FORBIDDEN      | 无权限       |
| **40401** | NOT_FOUND      | 资源不存在   |
| **40901** | CONFLICT       | 资源冲突     |
| **40902** | DUPLICATE      | 资源重复     |
| **50001** | INTERNAL_ERROR | 服务内部错误 |
| **50002** | DB_ERROR       | 数据库错误   |
| **50003** | ASR_ERROR      | ASR服务错误  |
| **50004** | NLP_ERROR      | NLP服务错误  |

---

## 2. 认证接口

### 2.1 用户注册

**POST /api/v1/auth/register**

请求：
```json
{
  "phone": "13800138000",
  "verifyCode": "123456",
  "nickname": "张三",
  "deviceId": "device-uuid-xxx"
}
```

响应：
```json
{
  "code": 201,
  "message": "注册成功",
  "data": {
    "user": {
      "id": "user-uuid-xxx",
      "phone": "13800138000",
      "nickname": "张三",
      "createdAt": "2024-06-22T14:30:00Z"
    },
    "token": {
      "accessToken": "jwt-access-token",
      "refreshToken": "jwt-refresh-token",
      "expiresIn": 604800  // 7天（秒）
    }
  }
}
```

### 2.2 发送验证码

**POST /api/v1/auth/send-code**

请求：
```json
{
  "phone": "13800138000",
  "type": "register"  // register/login/bind
}
```

响应：
```json
{
  "code": 200,
  "message": "验证码已发送",
  "data": {
    "expireIn": 300  // 5分钟有效
  }
}
```

### 2.3 用户登录

**POST /api/v1/auth/login**

请求：
```json
{
  "phone": "13800138000",
  "verifyCode": "123456",
  "deviceId": "device-uuid-xxx"
}
```

响应：
```json
{
  "code": 200,
  "message": "登录成功",
  "data": {
    "user": {
      "id": "user-uuid-xxx",
      "phone": "13800138000",
      "nickname": "张三",
      "avatarUrl": "https://...",
      "settings": {
        "defaultReminderLevel": "standard",
        "quietHoursStart": "22:00",
        "quietHoursEnd": "08:00"
      }
    },
    "token": {
      "accessToken": "jwt-access-token",
      "refreshToken": "jwt-refresh-token",
      "expiresIn": 604800
    }
  }
}
```

### 2.4 Token刷新

**POST /api/v1/auth/refresh**

请求：
```json
{
  "refreshToken": "jwt-refresh-token"
}
```

响应：
```json
{
  "code": 200,
  "message": "Token刷新成功",
  "data": {
    "accessToken": "new-jwt-access-token",
    "expiresIn": 604800
  }
}
```

### 2.5 家属绑定

**POST /api/v1/auth/bind-family**

请求：
```json
{
  "familyPhone": "13900139000",
  "permissionLevel": "confirmer",  // viewer/confirmer/admin
  "notifyOnMissed": true
}
```

响应：
```json
{
  "code": 200,
  "message": "绑定请求已发送",
  "data": {
    "bindingId": "binding-uuid-xxx",
    "status": "pending",
    "familyUser": {
      "phone": "13900139000",
      "nickname": "李四"
    }
  }
}
```

---

## 3. 时间线接口

### 3.1 创建时间线记录（语音上传）

**POST /api/v1/timeline/voice**

请求（multipart/form-data）：
```
voiceFile: [音频文件]
userId: user-uuid-xxx
timestamp: 2024-06-22T14:30:00Z  (可选，默认当前时间)
```

响应：
```json
{
  "code": 201,
  "message": "语音记录创建成功",
  "data": {
    "record": {
      "id": "record-uuid-xxx",
      "timestamp": "2024-06-22T14:30:00Z",
      "content": "正在吃药",
      "behaviorTag": "吃药",
      "voiceFileUrl": "https://oss.xxx.com/voice/xxx.wav",
      "voiceDuration": 3,
      "asrProvider": "xunfei",
      "matchedAgendaId": "agenda-uuid-xxx",
      "matchScore": 0.92
    },
    "matchResult": {
      "agendaId": "agenda-uuid-xxx",
      "agendaContent": "09:00 吃药",
      "matchSuccess": true,
      "timeDeviation": 30  // 分钟偏差
    }
  }
}
```

### 3.2 创建时间线记录（文字）

**POST /api/v1/timeline**

请求：
```json
{
  "content": "正在喝水",
  "timestamp": "2024-06-22T14:30:00Z",  // 可选
  "source": "manual"  // voice/manual/import
}
```

响应：
```json
{
  "code": 201,
  "message": "记录创建成功",
  "data": {
    "id": "record-uuid-xxx",
    "timestamp": "2024-06-22T14:30:00Z",
    "content": "正在喝水",
    "behaviorTag": "喝水",
    "matchedAgendaId": null,
    "matchScore": null
  }
}
```

### 3.3 获取今日时间线

**GET /api/v1/timeline/today**

查询参数：
```
page: 1 (可选)
pageSize: 50 (可选)
```

响应：
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "items": [
      {
        "id": "record-uuid-xxx",
        "timestamp": "2024-06-22T14:30:00Z",
        "content": "正在吃药",
        "behaviorTag": "吃药",
        "matchedAgendaId": "agenda-uuid-xxx",
        "matchScore": 0.92,
        "matchStatus": "matched"
      },
      {
        "id": "record-uuid-yyy",
        "timestamp": "2024-06-22T12:00:00Z",
        "content": "吃完午饭，准备休息",
        "behaviorTag": "吃午饭",
        "matchedAgendaId": "agenda-uuid-yyy",
        "matchScore": 0.88,
        "matchStatus": "matched"
      }
    ],
    "pagination": {
      "page": 1,
      "pageSize": 50,
      "total": 15,
      "hasNext": false
    },
    "summary": {
      "matchedCount": 12,
      "unmatchedCount": 3,
      "matchRate": 0.80
    }
  }
}
```

### 3.4 获取历史时间线

**GET /api/v1/timeline**

查询参数：
```
startDate: 2024-06-01 (可选)
endDate: 2024-06-22 (可选)
behaviorTag: 吃药 (可选)
page: 1
pageSize: 20
```

响应：
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "items": [...],
    "pagination": {
      "page": 1,
      "pageSize": 20,
      "total": 150,
      "totalPages": 8,
      "hasNext": true
    }
  }
}
```

### 3.5 更新时间线记录

**PUT /api/v1/timeline/{recordId}**

请求：
```json
{
  "content": "正在吃药（修正）",
  "behaviorTag": "吃药",
  "matchedAgendaId": "agenda-uuid-xxx"  // 手动指定匹配
}
```

响应：
```json
{
  "code": 200,
  "message": "记录更新成功",
  "data": {
    "id": "record-uuid-xxx",
    "content": "正在吃药（修正）",
    "behaviorTag": "吃药",
    "matchedAgendaId": "agenda-uuid-xxx",
    "updatedAt": "2024-06-22T14:35:00Z"
  }
}
```

### 3.6 删除时间线记录

**DELETE /api/v1/timeline/{recordId}**

响应：
```json
{
  "code": 204,
  "message": "记录删除成功"
}
```

---

## 4. 计划事程接口

### 4.1 创建事程

**POST /api/v1/agendas**

请求：
```json
{
  "plannedTime": "2024-06-23T09:00:00Z",
  "content": "吃药",
  "behaviorTag": "吃药",
  "agendaType": "fixed",
  "remindOffset": 5,
  "remindLevel": "important",
  "isRecurring": false,
  "source": "manual"
}
```

响应：
```json
{
  "code": 201,
  "message": "事程创建成功",
  "data": {
    "id": "agenda-uuid-xxx",
    "plannedTime": "2024-06-23T09:00:00Z",
    "content": "吃药",
    "behaviorTag": "吃药",
    "agendaType": "fixed",
    "status": "pending",
    "remindOffset": 5,
    "remindLevel": "important",
    "reminderRule": {
      "id": "rule-uuid-xxx",
      "level": "important",
      "enableNotification": true,
      "enableSound": true,
      "enableVibration": true,
      "enablePopup": true,
      "remindOffset": 5,
      "repeatInterval": 10,
      "maxReminders": 5,
      "allowSnooze": true,
      "allowSkip": false
    },
    "createdAt": "2024-06-22T14:30:00Z"
  }
}
```

### 4.2 语音创建事程（无时间智能处理）

**POST /api/v1/agendas/voice**

请求：
```json
{
  "content": "我今天准备吃药、拿快递，还想整理一下房间",
  "voiceFileUrl": "https://oss.xxx.com/voice/xxx.wav"  // 可选
}
```

响应（四层处理结果）：
```json
{
  "code": 201,
  "message": "事程创建成功",
  "data": {
    "parsedAgendas": [
      {
        "content": "吃药",
        "behaviorTag": "吃药",
        "timeSuggestion": {
          "hasHistory": true,
          "suggestedTime": "2024-06-23T09:00:00Z",
          "confidence": 0.85,
          "reason": "根据您过去7天的习惯，平均在09:15吃药"
        },
        "createdAgenda": {
          "id": "agenda-uuid-xxx",
          "plannedTime": "2024-06-23T09:00:00Z",
          "agendaType": "fixed"
        }
      },
      {
        "content": "拿快递",
        "behaviorTag": "拿快递",
        "timeSuggestion": {
          "hasHistory": false,
          "suggestedTime": null,
          "defaultRange": {
            "start": "09:00",
            "end": "21:00"
          }
        },
        "createdAgenda": {
          "id": "agenda-uuid-yyy",
          "agendaType": "floating",
          "floatingTimeRangeStart": "09:00",
          "floatingTimeRangeEnd": "21:00"
        }
      },
      {
        "content": "整理房间",
        "behaviorTag": "整理房间",
        "timeSuggestion": {
          "hasHistory": false,
          "suggestedTime": null,
          "defaultRange": {
            "start": "10:00",
            "end": "18:00"
          }
        },
        "createdAgenda": {
          "id": "agenda-uuid-zzz",
          "agendaType": "pure_record"
        }
      }
    ],
    "needConfirm": true,
    "confirmMessage": "吃药建议安排在09:00，拿快递和整理房间已设置为浮动事程，有空时提醒您。是否确认？"
  }
}
```

### 4.3 获取今日事程

**GET /api/v1/agendas/today**

查询参数：
```
status: pending,active,matched,skipped (可选，逗号分隔)
```

响应：
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "items": [
      {
        "id": "agenda-uuid-xxx",
        "plannedTime": "2024-06-23T09:00:00Z",
        "content": "吃药",
        "behaviorTag": "吃药",
        "agendaType": "fixed",
        "status": "active",
        "remindLevel": "important",
        "isForced": false,
        "matchedTimelineId": null,
        "reminderRule": {...}
      },
      {
        "id": "agenda-uuid-yyy",
        "plannedTime": "2024-06-23T12:00:00Z",
        "content": "吃午饭",
        "behaviorTag": "吃午饭",
        "status": "pending",
        "remindLevel": "standard"
      }
    ],
    "summary": {
      "total": 5,
      "matched": 2,
      "pending": 2,
      "active": 1,
      "skipped": 0
    }
  }
}
```

### 4.4 获取事程详情

**GET /api/v1/agendas/{agendaId}**

响应：
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "id": "agenda-uuid-xxx",
    "plannedTime": "2024-06-23T09:00:00Z",
    "content": "吃药",
    "behaviorTag": "吃药",
    "agendaType": "fixed",
    "status": "active",
    "remindOffset": 5,
    "remindLevel": "important",
    "isForced": false,
    "reminderRule": {
      "id": "rule-uuid-xxx",
      "level": "important",
      "enableNotification": true,
      "enableSound": true,
      "enableVibration": true,
      "enablePopup": true,
      "remindOffset": 5,
      "repeatInterval": 10,
      "maxReminders": 5,
      "allowSnooze": true,
      "allowSkip": false
    },
    "matchedTimelineId": null,
    "matchedAt": null,
    "createdAt": "2024-06-22T14:30:00Z",
    "updatedAt": "2024-06-22T14:30:00Z"
  }
}
```

### 4.5 更新事程

**PUT /api/v1/agendas/{agendaId}**

请求：
```json
{
  "plannedTime": "2024-06-23T10:00:00Z",
  "content": "吃药（调整时间）",
  "remindLevel": "forced"
}
```

响应：
```json
{
  "code": 200,
  "message": "事程更新成功",
  "data": {
    "id": "agenda-uuid-xxx",
    "plannedTime": "2024-06-23T10:00:00Z",
    "updatedAt": "2024-06-22T15:00:00Z"
  }
}
```

### 4.6 确认事程完成

**POST /api/v1/agendas/{agendaId}/confirm**

请求：
```json
{
  "timelineId": "record-uuid-xxx",  // 可选，关联时间线记录
  "confirmMethod": "manual"  // manual/voice_match
}
```

响应：
```json
{
  "code": 200,
  "message": "事程已确认完成",
  "data": {
    "id": "agenda-uuid-xxx",
    "status": "matched",
    "matchedTimelineId": "record-uuid-xxx",
    "matchedAt": "2024-06-22T15:00:00Z"
  }
}
```

### 4.7 延后事程提醒

**POST /api/v1/agendas/{agendaId}/snooze**

请求：
```json
{
  "snoozeMinutes": 10
}
```

响应：
```json
{
  "code": 200,
  "message": "提醒已延后",
  "data": {
    "nextRemindTime": "2024-06-22T15:10:00Z",
    "snoozeCount": 1,
    "maxSnooze": 5
  }
}
```

### 4.8 跳过事程

**POST /api/v1/agendas/{agendaId}/skip**

请求：
```json
{
  "reason": "今天不需要"  // 可选
}
```

响应：
```json
{
  "code": 200,
  "message": "事程已跳过",
  "data": {
    "id": "agenda-uuid-xxx",
    "status": "skipped",
    "skippedAt": "2024-06-22T15:00:00Z",
    "skipReason": "今天不需要"
  }
}
```

### 4.9 删除事程

**DELETE /api/v1/agendas/{agendaId}**

响应：
```json
{
  "code": 204,
  "message": "事程删除成功"
}
```

---

## 5. 提醒规则接口

### 5.1 获取全局默认提醒规则

**GET /api/v1/reminder-rules/default**

响应：
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "id": "rule-uuid-xxx",
    "userId": "user-uuid-xxx",
    "agendaId": null,
    "level": "standard",
    "enableNotification": true,
    "enableSound": true,
    "enableVibration": true,
    "enablePopup": false,
    "enableVoice": false,
    "vibrationStrength": "medium",
    "soundVolume": 80,
    "remindOffset": 5,
    "repeatInterval": 10,
    "maxReminders": 3,
    "allowSnooze": true,
    "allowSkip": true,
    "snoozeOptions": [5, 10, 15, 30]
  }
}
```

### 5.2 更新全局默认提醒规则

**PUT /api/v1/reminder-rules/default**

请求：
```json
{
  "level": "standard",
  "enableNotification": true,
  "enableSound": true,
  "enableVibration": true,
  "remindOffset": 10,
  "repeatInterval": 15,
  "maxReminders": 5,
  "allowSnooze": true,
  "allowSkip": true
}
```

响应：
```json
{
  "code": 200,
  "message": "默认规则更新成功",
  "data": {...}
}
```

### 5.3 获取事程提醒规则

**GET /api/v1/agendas/{agendaId}/reminder-rule**

响应：
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "id": "rule-uuid-xxx",
    "agendaId": "agenda-uuid-xxx",
    "level": "forced",
    "enableNotification": true,
    "enableSound": true,
    "enableVibration": true,
    "enablePopup": true,
    "enableVoice": false,
    "vibrationStrength": "strong",
    "remindOffset": 5,
    "repeatInterval": 5,
    "maxReminders": 10,
    "allowSnooze": true,
    "allowSkip": false,
    "escalatingStrategyId": "strategy-uuid-xxx",
    "familyNotifyOffset": 30,
    "enableGeoTrigger": false,
    "enableBehaviorChain": true,
    "behaviorChainConfig": {
      "preBehaviorTag": "吃早饭",
      "delayMinutes": 30
    }
  }
}
```

### 5.4 更新事程提醒规则

**PUT /api/v1/agendas/{agendaId}/reminder-rule**

请求：
```json
{
  "level": "forced",
  "enablePopup": true,
  "allowSkip": false,
  "escalatingStrategyId": "strategy-uuid-xxx",
  "enableBehaviorChain": true,
  "behaviorChainConfig": {
    "preBehaviorTag": "吃早饭",
    "delayMinutes": 30
  }
}
```

响应：
```json
{
  "code": 200,
  "message": "提醒规则更新成功",
  "data": {...}
}
```

### 5.5 获取升级策略列表

**GET /api/v1/escalating-strategies**

响应：
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "items": [
      {
        "id": "strategy-uuid-xxx",
        "name": "默认强制策略",
        "isDefault": true,
        "stages": [
          {
            "stageName": "pre_remind",
            "triggerOffset": -5,
            "notification": true,
            "sound": false,
            "vibration": "none",
            "popup": false,
            "voice": false,
            "familyNotify": false,
            "allowSnooze": true
          },
          {
            "stageName": "first_remind",
            "triggerOffset": 0,
            "notification": true,
            "sound": true,
            "vibration": "medium",
            "popup": true,
            "voice": false,
            "familyNotify": false,
            "allowSnooze": true
          },
          {
            "stageName": "family_notify",
            "triggerOffset": 30,
            "familyNotify": true
          }
        ]
      },
      {
        "id": "strategy-uuid-yyy",
        "name": "老人专用策略",
        "isDefault": false,
        "stages": [...]
      }
    ]
  }
}
```

### 5.6 创建自定义升级策略

**POST /api/v1/escalating-strategies**

请求：
```json
{
  "name": "我的吃药策略",
  "stages": [
    {
      "stageName": "pre_remind",
      "triggerOffset": -10,
      "notification": true,
      "sound": false
    },
    {
      "stageName": "first_remind",
      "triggerOffset": 0,
      "notification": true,
      "sound": true,
      "vibration": "medium",
      "popup": true
    },
    {
      "stageName": "family_notify",
      "triggerOffset": 15,
      "familyNotify": true
    }
  ]
}
```

响应：
```json
{
  "code": 201,
  "message": "策略创建成功",
  "data": {
    "id": "strategy-uuid-new",
    "name": "我的吃药策略",
    "stages": [...]
  }
}
```

---

## 6. 匹配引擎接口

### 6.1 手动匹配

**POST /api/v1/match/manual**

请求：
```json
{
  "timelineId": "record-uuid-xxx",
  "agendaId": "agenda-uuid-xxx"
}
```

响应：
```json
{
  "code": 200,
  "message": "匹配成功",
  "data": {
    "matchResult": {
      "timelineId": "record-uuid-xxx",
      "agendaId": "agenda-uuid-xxx",
      "matchScore": 1.0,
      "matchMethod": "manual",
      "status": "user_confirmed"
    },
    "agenda": {
      "id": "agenda-uuid-xxx",
      "status": "matched",
      "matchedAt": "2024-06-22T15:00:00Z"
    }
  }
}
```

### 6.2 取消匹配

**POST /api/v1/match/cancel**

请求：
```json
{
  "timelineId": "record-uuid-xxx",
  "agendaId": "agenda-uuid-xxx"
}
```

响应：
```json
{
  "code": 200,
  "message": "匹配已取消",
  "data": {
    "timeline": {
      "id": "record-uuid-xxx",
      "matchedAgendaId": null
    },
    "agenda": {
      "id": "agenda-uuid-xxx",
      "status": "active",
      "matchedTimelineId": null
    }
  }
}
```

### 6.3 查询待匹配事程

**GET /api/v1/match/pending**

查询参数：
```
behaviorTag: 吃药 (可选)
timeRange: 30 (可选，分钟范围)
```

响应：
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "items": [
      {
        "id": "agenda-uuid-xxx",
        "plannedTime": "2024-06-22T09:00:00Z",
        "content": "吃药",
        "behaviorTag": "吃药",
        "status": "active",
        "timeDeviation": 30  // 与当前时间的偏差
      }
    ]
  }
}
```

---

## 7. 分析接口

### 7.1 获取行为频率分析

**GET /api/v1/analytics/frequency**

查询参数：
```
period: week (可选，day/week/month)
startDate: 2024-06-01 (可选)
endDate: 2024-06-22 (可选)
```

响应：
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "period": "week",
    "behaviorFrequency": {
      "吃药": 7,
      "喝水": 3,
      "吃早饭": 7,
      "吃午饭": 7,
      "运动": 4
    },
    "topBehaviors": [
      {"tag": "吃早饭", "count": 7, "rate": 1.0},
      {"tag": "吃午饭", "count": 7, "rate": 1.0},
      {"tag": "吃药", "count": 7, "rate": 1.0}
    ],
    "lowBehaviors": [
      {"tag": "喝水", "count": 3, "rate": 0.43}
    ]
  }
}
```

### 7.2 获取匹配率趋势

**GET /api/v1/analytics/match-rate**

查询参数：
```
period: week (可选)
```

响应：
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "period": "week",
    "dailyMatchRate": [
      {"date": "2024-06-16", "rate": 0.75},
      {"date": "2024-06-17", "rate": 0.80},
      {"date": "2024-06-18", "rate": 0.85},
      {"date": "2024-06-19", "rate": 0.70},
      {"date": "2024-06-20", "rate": 0.90},
      {"date": "2024-06-21", "rate": 0.88},
      {"date": "2024-06-22", "rate": 0.80}
    ],
    "averageRate": 0.82,
    "trend": "up"  // up/down/stable
  }
}
```

### 7.3 获取异常检测报告

**GET /api/v1/analytics/anomalies**

响应：
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "anomalies": [
      {
        "type": "missed_behavior",
        "behaviorTag": "吃药",
        "description": "连续2天未记录吃药",
        "severity": "high",
        "suggestion": "请确认是否按时服药，如有遗漏请补录"
      },
      {
        "type": "time_shift",
        "behaviorTag": "运动",
        "description": "运动时间比平时晚2小时",
        "severity": "medium",
        "suggestion": "是否需要调整运动提醒时间？"
      }
    ]
  }
}
```

### 7.4 获取策略优化建议

**GET /api/v1/analytics/optimization-suggestions**

响应：
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "suggestions": [
      {
        "type": "time_adjustment",
        "agendaId": "agenda-uuid-xxx",
        "agendaContent": "运动",
        "currentSetting": "18:00",
        "suggestedSetting": "18:30",
        "reason": "您最近5次运动提醒都选择了延后30分钟",
        "confidence": 0.85,
        "autoApply": false
      },
      {
        "type": "behavior_chain",
        "agendaId": "agenda-uuid-yyy",
        "agendaContent": "吃药",
        "currentSetting": "固定时间09:00",
        "suggestedSetting": "行为链触发：吃完早饭后25分钟",
        "reason": "发现您总在早饭后25分钟吃药",
        "confidence": 0.92,
        "autoApply": true
      },
      {
        "type": "quiet_hours",
        "currentSetting": "22:00-08:00",
        "suggestedSetting": "22:00-08:00",
        "reason": "您每天22:00后不再记录行为",
        "confidence": 0.95,
        "autoApply": true
      }
    ]
  }
}
```

---

## 8. 个人记忆问答接口（P2阶段）

### 8.1 提交问题

**POST /api/v1/qa/ask**

请求：
```json
{
  "question": "我的钥匙放在哪里了？",
  "session_id": "session-uuid-xxx",
  "enable_voice": true
}
```

响应：
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "answer": "根据您的记录，钥匙放在玄关鞋柜的抽屉里（2024年6月20日记录）。",
    "answer_voice_url": "https://cdn.example.com/voice/answer-xxx.mp3",
    "confidence": 0.96,
    "session_id": "session-uuid-xxx",
    "source_records": [
      {
        "id": "item-record-uuid-001",
        "timestamp": "2024-06-20T18:30:00Z",
        "content": "钥匙：放在玄关鞋柜的抽屉里",
        "record_type": "item",
        "relevance_score": 0.95,
        "behavior_tag": null,
        "source_name": "物品位置",
        "metadata": {}
      }
    ]
  }
}
```

### 8.2 获取问答历史

**GET /api/v1/qa/history**

查询参数：
- `session_id` (可选): 会话ID，不传则返回所有历史
- `page` (可选): 页码，默认1
- `page_size` (可选): 每页数量，默认20

响应：
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "items": [
      {
        "id": "qa-history-uuid-001",
        "session_id": "session-uuid-xxx",
        "question": "我的钥匙放在哪里了？",
        "question_type": "item_location",
        "answer": "根据您的记录，钥匙放在玄关鞋柜的抽屉里。",
        "source_records": [
          {
            "id": "item-record-uuid-001",
            "timestamp": "2024-06-20T18:30:00Z",
            "content": "钥匙：放在玄关鞋柜的抽屉里",
            "record_type": "item",
            "relevance_score": 0.95
          }
        ],
        "processing_time": 320,
        "confidence": 0.96,
        "created_at": "2024-06-22T14:30:00Z"
      }
    ],
    "pagination": {
      "page": 1,
      "page_size": 20,
      "total": 15
    }
  }
}
```

### 8.3 获取会话列表

**GET /api/v1/qa/sessions**

响应：
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "items": [
      {
        "id": "session-uuid-xxx",
        "started_at": "2024-06-22T14:00:00Z",
        "ended_at": null,
        "status": "active",
        "message_count": 5
      }
    ]
  }
}
```

### 8.4 结束会话

**POST /api/v1/qa/sessions/{session_id}/end**

响应：
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "id": "session-uuid-xxx",
    "status": "ended",
    "ended_at": "2024-06-22T15:00:00Z"
  }
}
```

### 8.5 API接口数据模型

#### SourceRecord（检索记录）

| 字段            | 类型   | 必填 | 说明                                     |
| --------------- | ------ | ---- | ---------------------------------------- |
| id              | string | 是   | 记录ID                                   |
| timestamp       | string | 是   | 记录时间（ISO 8601）                     |
| content         | string | 是   | 内容摘要                                 |
| record_type     | string | 是   | 记录类型：timeline/item/knowledge/agenda |
| relevance_score | number | 是   | 相关性评分 0-1                           |
| behavior_tag    | string | 否   | 行为标签                                 |
| source_name     | string | 否   | 来源名称                                 |
| metadata        | object | 否   | 额外元数据                               |

#### QaHistoryItem（问答历史项）

| 字段            | 类型           | 必填 | 说明             |
| --------------- | -------------- | ---- | ---------------- |
| id              | string         | 是   | 历史记录ID       |
| session_id      | string         | 是   | 会话ID           |
| question        | string         | 是   | 用户问题         |
| question_type   | string         | 是   | 问题类型         |
| answer          | string         | 是   | 系统回答         |
| source_records  | SourceRecord[] | 否   | 检索记录列表     |
| processing_time | number         | 否   | 处理耗时（毫秒） |
| confidence      | number         | 否   | 置信度           |
| created_at      | string         | 是   | 创建时间         |

---

## 9. 用户设置接口

### 9.1 获取用户设置

**GET /api/v1/users/settings**

响应：
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "userId": "user-uuid-xxx",
    "nickname": "张三",
    "avatarUrl": "https://...",
    "defaultReminderLevel": "standard",
    "defaultRemindOffset": 5,
    "defaultRepeatInterval": 10,
    "defaultMaxReminders": 3,
    "allowSnoozeDefault": true,
    "allowSkipDefault": true,
    "quietHoursStart": "22:00",
    "quietHoursEnd": "08:00",
    "preferredAsrProvider": "xunfei",
    "preferredNlpProvider": "xunfei",
    "autoApplyOptimization": true,
    "weeklyReportEnabled": true
  }
}
```

### 8.2 更新用户设置

**PUT /api/v1/users/settings**

请求：
```json
{
  "nickname": "张三（新）",
  "defaultReminderLevel": "important",
  "quietHoursStart": "21:00",
  "quietHoursEnd": "07:00",
  "autoApplyOptimization": true
}
```

响应：
```json
{
  "code": 200,
  "message": "设置更新成功",
  "data": {...}
}
```

---

## 10. WebSocket接口

### 10.1 连接

**WebSocket /ws/v1/connect**

连接参数：
```
token: jwt-access-token (query参数或header)
```

### 10.2 消息类型

#### 服务端推送消息

```json
// 提醒触发
{
  "type": "reminder_triggered",
  "data": {
    "agendaId": "agenda-uuid-xxx",
    "content": "吃药",
    "plannedTime": "2024-06-22T09:00:00Z",
    "remindStage": "first_remind",
    "methods": ["notification", "sound", "vibration"]
  }
}

// 匹配成功
{
  "type": "match_success",
  "data": {
    "timelineId": "record-uuid-xxx",
    "agendaId": "agenda-uuid-xxx",
    "matchScore": 0.92
  }
}

// 家属通知
{
  "type": "family_notify",
  "data": {
    "userId": "user-uuid-xxx",
    "agendaId": "agenda-uuid-xxx",
    "content": "吃药",
    "missedDuration": 30
  }
}

// 数据同步
{
  "type": "sync_update",
  "data": {
    "entity": "agenda",
    "action": "update",
    "payload": {...}
  }
}
```

#### 客户端发送消息

```json
// 心跳
{
  "type": "ping",
  "timestamp": "2024-06-22T14:30:00Z"
}

// 提醒响应
{
  "type": "reminder_response",
  "data": {
    "agendaId": "agenda-uuid-xxx",
    "response": "confirmed",  // confirmed/snoozed/skipped
    "timestamp": "2024-06-22T14:30:00Z"
  }
}
```

---

## 11. API调用示例（Flutter）

### 11.1 Retrofit API客户端定义

```dart
// lib/core/network/api_client.dart

@RestApi(baseUrl: "https://api.daily-assistant.com/v1")
abstract class ApiClient {
  
  factory ApiClient(Dio dio, {String baseUrl}) = _ApiClient;
  
  // 认证
  @POST("/auth/login")
  Future<ApiResponse<LoginResult>> login(@Body() LoginRequest request);
  
  @POST("/auth/refresh")
  Future<ApiResponse<TokenResult>> refreshToken(@Body() RefreshRequest request);
  
  // 时间线
  @POST("/timeline")
  Future<ApiResponse<TimelineRecord>> createTimeline(@Body() CreateTimelineRequest request);
  
  @POST("/timeline/voice")
  @MultiPart()
  Future<ApiResponse<TimelineRecord>> uploadVoiceTimeline(
    @Part(name: "voiceFile") File voiceFile,
    @Part(name: "userId") String userId,
    @Part(name: "timestamp") String? timestamp,
  );
  
  @GET("/timeline/today")
  Future<ApiResponse<TimelineListResult>> getTodayTimeline(@Query("page") int? page);
  
  // 事程
  @POST("/agendas")
  Future<ApiResponse<Agenda>> createAgenda(@Body() CreateAgendaRequest request);
  
  @GET("/agendas/today")
  Future<ApiResponse<AgendaListResult>> getTodayAgendas(@Query("status") String? status);
  
  @POST("/agendas/{id}/confirm")
  Future<ApiResponse<Agenda>> confirmAgenda(@Path("id") String id, @Body() ConfirmRequest request);
  
  @POST("/agendas/{id}/snooze")
  Future<ApiResponse<SnoozeResult>> snoozeAgenda(@Path("id") String id, @Body() SnoozeRequest request);
  
  // 提醒规则
  @GET("/reminder-rules/default")
  Future<ApiResponse<ReminderRule>> getDefaultRule();
  
  @PUT("/reminder-rules/default")
  Future<ApiResponse<ReminderRule>> updateDefaultRule(@Body() UpdateRuleRequest request);
  
  // 分析
  @GET("/analytics/frequency")
  Future<ApiResponse<FrequencyResult>> getFrequencyAnalysis(@Query("period") String? period);
  
  @GET("/analytics/match-rate")
  Future<ApiResponse<MatchRateResult>> getMatchRateAnalysis(@Query("period") String? period);
  
  // 问答（P2阶段）
  @POST("/qa/ask")
  Future<ApiResponse<QaAnswerResult>> askQuestion(@Body() QaAskRequest request);
  
  @GET("/qa/history")
  Future<ApiResponse<QaHistoryListResult>> getQaHistory({
    @Query("session_id") String? sessionId,
    @Query("page") int? page,
    @Query("page_size") int? pageSize,
  });
  
  @GET("/qa/sessions")
  Future<ApiResponse<QaSessionListResult>> getQaSessions();
  
  @POST("/qa/sessions/{session_id}/end")
  Future<ApiResponse<QaSession>> endQaSession(@Path("session_id") String sessionId);
}
```

### 11.2 API调用示例

```dart
// lib/features/timeline/data/repositories/timeline_repository_impl.dart

class TimelineRepositoryImpl implements TimelineRepository {
  final ApiClient _apiClient;
  final LocalTimelineDataSource _localDataSource;
  final SyncQueueService _syncQueue;
  
  TimelineRepositoryImpl(
    this._apiClient,
    this._localDataSource,
    this._syncQueue,
  );
  
  @override
  Future<TimelineRecord> createVoiceRecord(File voiceFile) async {
    // 1. 先本地创建（离线优先）
    final localRecord = TimelineRecord(
      id: generateUUID(),
      userId: currentUser.id,
      timestamp: DateTime.now(),
      content: '', // 待ASR返回
      source: 'voice',
      syncStatus: SyncStatus.pending,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    await _localDataSource.insert(localRecord);
    
    // 2. 尝试云端同步
    try {
      final response = await _apiClient.uploadVoiceTimeline(
        voiceFile,
        currentUser.id,
        localRecord.timestamp.toIso8601String(),
      );
      
      if (response.code == 201) {
        // 更新本地记录
        final updatedRecord = response.data.copyWith(
          syncStatus: SyncStatus.synced,
        );
        await _localDataSource.update(updatedRecord);
        return updatedRecord;
      }
    } catch (e) {
      // 网络失败，加入同步队列
      await _syncQueue.addTask(SyncTask(
        type: SyncType.create,
        entity: 'timeline',
        localId: localRecord.id,
        data: {'voiceFile': voiceFile.path},
      ));
    }
    
    return localRecord;
  }
  
  @override
  Future<List<TimelineRecord>> getTodayRecords() async {
    // 优先从本地获取
    final localRecords = await _localDataSource.getTodayRecords();
    
    // 如果网络可用，同步云端数据
    if (await connectivityChecker.isConnected) {
      try {
        final response = await _apiClient.getTodayTimeline();
        if (response.code == 200) {
          // 合并云端数据
          await _mergeCloudData(response.data.items);
        }
      } catch (e) {
        // 网络失败，继续使用本地数据
      }
    }
    
    return await _localDataSource.getTodayRecords();
  }
}
```

---

## 12. 下一步

- [04-功能模块详细设计.md](./04-功能模块详细设计.md) - 各模块技术实现方案
- [05-语音识别与NLP集成方案.md](./05-语音识别与NLP集成方案.md) - AI服务集成详情
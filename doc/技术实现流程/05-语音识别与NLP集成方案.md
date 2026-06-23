# 05 - 语音识别与NLP集成方案

## 1. AI服务选型

### 1.1 服务对比

| 服务商 | ASR能力 | NLP能力 | 方言支持 | 延迟 | 成本 | 推荐场景 |
|-------|--------|--------|---------|------|------|---------|
| **讯飞开放平台** | ★★★★★ | ★★★★★ | 23种方言 | <500ms | 中 | **首选方案** |
| **阿里云语音** | ★★★★ | ★★★★ | 10种方言 | <600ms | 低 | 降级备选 |
| **腾讯云语音** | ★★★★ | ★★★ | 8种方言 | <600ms | 低 | 降级备选 |
| **百度语音** | ★★★ | ★★★ | 5种方言 | <700ms | 低 | 不推荐 |

### 1.2 选型结论

**主方案：讯飞开放平台**
- 方言支持最全（覆盖全国主要方言）
- 中文识别准确率最高（>98%）
- NLP意图识别能力强
- 实时语音识别延迟低

**降级方案：阿里云语音**
- 成本更低
- 稳定性高
- 作为讯飞服务不可用时的降级备选

---

## 2. 讯飞语音服务集成

### 2.1 讯飞开放平台API概览

| API | 功能 | 调用方式 |
|-----|------|---------|
| **语音听写（流式版）** | 实时语音转文字 | WebSocket |
| **语音听写（一句话）** | 短语音转文字 | REST API |
| **语义理解** | 意图识别、关键词提取 | REST API |
| **语音合成** | 文字转语音播报 | REST API |

### 2.2 服务端集成实现

```go
// internal/infrastructure/external/xunfei/asr_client.go

package xunfei

import (
    "bytes"
    "crypto/hmac"
    "crypto/sha256"
    "encoding/base64"
    "encoding/json"
    "fmt"
    "io"
    "mime/multipart"
    "net/http"
    "time"
)

type XunfeiASRClient struct {
    appID     string
    apiKey    string
    apiSecret string
    baseUrl   string
}

func NewXunfeiASRClient(appID, apiKey, apiSecret string) *XunfeiASRClient {
    return &XunfeiASRClient{
        appID:     appID,
        apiKey:    apiKey,
        apiSecret: apiSecret,
        baseUrl:   "https://api.xf-yun.com/v1/private/dts_send",
    }
}

// 一句话识别（适用于短语音，<60秒）
func (c *XunfeiASRClient) RecognizeShort(audioData []byte, format string) (*ASRResult, error) {
    // 构建请求
    body := &bytes.Buffer{}
    writer := multipart.NewWriter(body)
    
    // 添加音频文件
    part, err := writer.CreateFormFile("audio", "audio.wav")
    if err != nil {
        return nil, err
    }
    _, err = part.Write(audioData)
    if err != nil {
        return nil, err
    }
    
    // 添加参数
    writer.WriteField("app_id", c.appID)
    writer.WriteField("format", format) // wav/pcm/mp3
    writer.WriteField("rate", "16000")
    writer.WriteField("dev_pid", "1537") // 中文普通话
    
    writer.Close()
    
    // 构建鉴权URL
    authURL := c.buildAuthURL(c.baseUrl)
    
    // 发送请求
    req, err := http.NewRequest("POST", authURL, body)
    if err != nil {
        return nil, err
    }
    req.Header.Set("Content-Type", writer.FormDataContentType())
    
    client := &http.Client{Timeout: 30 * time.Second}
    resp, err := client.Do(req)
    if err != nil {
        return nil, err
    }
    defer resp.Body.Close()
    
    // 解析响应
    respBody, err := io.ReadAll(resp.Body)
    if err != nil {
        return nil, err
    }
    
    var result ASRResponse
    err = json.Unmarshal(respBody, &result)
    if err != nil {
        return nil, err
    }
    
    if result.Code != 0 {
        return nil, fmt.Errorf("ASR error: %s", result.Message)
    }
    
    return &ASRResult{
        Text:     result.Data.Result.Text,
        Confidence: result.Data.Result.Confidence,
        Words:    result.Data.Result.Words,
    }, nil
}

// 构建鉴权URL
func (c *XunfeiASRClient) buildAuthURL(baseURL string) string {
    now := time.Now().Format("Mon, 02 Jan 2006 15:04:05 GMT")
    
    // 生成签名
    signatureOrigin := fmt.Sprintf("host: api.xf-yun.com\ndate: %s\nGET /v1/private/dts_send HTTP/1.1", now)
    signature := c.hmacSHA256(signatureOrigin, c.apiSecret)
    
    authorizationOrigin := fmt.Sprintf("api_key=\"%s\", algorithm=\"%s\", headers=\"%s\", signature=\"%s\"",
        c.apiKey, "hmac-sha256", "host date", signature)
    authorization := base64.StdEncoding.EncodeToString([]byte(authorizationOrigin))
    
    // 构建URL
    return fmt.Sprintf("%s?authorization=%s&date=%s&host=api.xf-yun.com",
        baseURL, authorization, now)
}

func (c *XunfeiASRClient) hmacSHA256(data, key string) string {
    h := hmac.New(sha256.New, []byte(key))
    h.Write([]byte(data))
    return base64.StdEncoding.EncodeToString(h.Sum(nil))
}

type ASRResult struct {
    Text       string
    Confidence float64
    Words      []ASRWord
}

type ASRWord struct {
    Word       string
    StartTime  int
    EndTime    int
    Confidence float64
}

type ASRResponse struct {
    Code    int    `json:"code"`
    Message string `json:"message"`
    Data    struct {
        Result struct {
            Text       string    `json:"text"`
            Confidence float64   `json:"confidence"`
            Words      []ASRWord `json:"words"`
        } `json:"result"`
    } `json:"data"`
}
```

### 2.3 讯飞NLP服务集成

```go
// internal/infrastructure/external/xunfei/nlp_client.go

package xunfei

import (
    "bytes"
    "encoding/json"
    "fmt"
    "io"
    "net/http"
    "time"
)

type XunfeiNLPClient struct {
    appID     string
    apiKey    string
    apiSecret string
    baseUrl   string
}

func NewXunfeiNLPClient(appID, apiKey, apiSecret string) *XunfeiNLPClient {
    return &XunfeiNLPClient{
        appID:     appID,
        apiKey:    apiKey,
        apiSecret: apiSecret,
        baseUrl:   "https://api.xf-yun.com/v1/private/sem_send",
    }
}

// 语义理解
func (c *XunfeiNLPClient) ParseIntent(text string) (*NLPResult, error) {
    request := NLPRequest{
        AppID: c.appID,
        Text:  text,
        Scene: "daily_assistant", // 自定义场景
    }
    
    body, err := json.Marshal(request)
    if err != nil {
        return nil, err
    }
    
    authURL := c.buildAuthURL(c.baseUrl)
    
    req, err := http.NewRequest("POST", authURL, bytes.NewBuffer(body))
    if err != nil {
        return nil, err
    }
    req.Header.Set("Content-Type", "application/json")
    
    client := &http.Client{Timeout: 10 * time.Second}
    resp, err := client.Do(req)
    if err != nil {
        return nil, err
    }
    defer resp.Body.Close()
    
    respBody, err := io.ReadAll(resp.Body)
    if err != nil {
        return nil, err
    }
    
    var result NLPResponse
    err = json.Unmarshal(respBody, &result)
    if err != nil {
        return nil, err
    }
    
    if result.Code != 0 {
        return nil, fmt.Errorf("NLP error: %s", result.Message)
    }
    
    return &NLPResult{
        Intent:     result.Data.Intent,
        Keywords:   result.Data.Keywords,
        TimeExpr:   result.Data.TimeExpr,
        Entities:   result.Data.Entities,
        Confidence: result.Data.Confidence,
    }, nil
}

type NLPResult struct {
    Intent     string            // plan/record/query
    Keywords   []string          // 提取的关键词
    TimeExpr   string            // 时间表达式
    Entities   map[string]string // 其他实体
    Confidence float64
}

type NLPRequest struct {
    AppID string `json:"app_id"`
    Text  string `json:"text"`
    Scene string `json:"scene"`
}

type NLPResponse struct {
    Code    int    `json:"code"`
    Message string `json:"message"`
    Data    struct {
        Intent     string            `json:"intent"`
        Keywords   []string          `json:"keywords"`
        TimeExpr   string            `json:"time_expr"`
        Entities   map[string]string `json:"entities"`
        Confidence float64           `json:"confidence"`
    } `json:"data"`
}
```

### 2.4 AI服务编排器

```go
// internal/domain/usecase/ai_orchestrator.go

package usecase

type AIOrchestrator struct {
    xunfeiASR  *XunfeiASRClient
    xunfeiNLP *XunfeiNLPClient
    aliyunASR *AliyunASRClient  // 降级备选
    localNLP  *LocalNLPEngine   // 本地规则引擎
}

// 处理语音输入
func (o *AIOrchestrator) ProcessVoice(audioData []byte) (*VoiceProcessResult, error) {
    // 1. ASR：语音转文字
    text, err := o.performASR(audioData)
    if err != nil {
        return nil, err
    }
    
    // 2. NLP：语义理解
    nlpResult, err := o.performNLP(text)
    if err != nil {
        // NLP失败时，使用本地规则引擎
        nlpResult = o.localNLP.Parse(text)
    }
    
    // 3. 行为标签匹配
    behaviorTag := o.matchBehaviorTag(nlpResult.Keywords)
    
    return &VoiceProcessResult{
        Text:       text,
        Intent:     nlpResult.Intent,
        BehaviorTag: behaviorTag,
        TimeExpr:   nlpResult.TimeExpr,
        Confidence: nlpResult.Confidence,
    }, nil
}

// ASR处理（带降级）
func (o *AIOrchestrator) performASR(audioData []byte) (string, error) {
    // 主方案：讯飞
    result, err := o.xunfeiASR.RecognizeShort(audioData, "wav")
    if err == nil && result.Confidence > 0.8 {
        return result.Text, nil
    }
    
    // 降级方案：阿里云
    result2, err := o.aliyunASR.Recognize(audioData)
    if err == nil {
        return result2.Text, nil
    }
    
    return "", fmt.Errorf("ASR failed: %v", err)
}

// NLP处理（带降级）
func (o *AIOrchestrator) performNLP(text string) (*NLPResult, error) {
    result, err := o.xunfeiNLP.ParseIntent(text)
    if err == nil && result.Confidence > 0.7 {
        return result, nil
    }
    
    // 降级：本地规则引擎
    return o.localNLP.Parse(text), nil
}

// 行为标签匹配
func (o *AIOrchestrator) matchBehaviorTag(keywords []string) string {
    // 从行为标签库匹配
    // ...
    return ""
}
```

---

## 3. 本地NLP规则引擎

### 3.1 规则引擎设计

当云端NLP服务不可用或延迟较高时，使用本地规则引擎进行基础解析。

```go
// internal/infrastructure/nlp/local_engine.go

package nlp

type LocalNLPEngine struct {
    behaviorTagRepo BehaviorTagRepository
    rules           []NLPRule
}

type NLPRule struct {
    Pattern     string   // 正则表达式
    Intent      string   // 意图类型
    Keywords    []string // 关键词
    TimePattern string   // 时间正则
}

func NewLocalNLPEngine(repo BehaviorTagRepository) *LocalNLPEngine {
    return &LocalNLPEngine{
        behaviorTagRepo: repo,
        rules: []NLPRule{
            // 计划意图规则
            {Pattern: "准备|打算|要|想|计划", Intent: "plan", Keywords: nil},
            // 记录意图规则
            {Pattern: "正在|在|刚|已经|完成", Intent: "record", Keywords: nil},
            // 查询意图规则
            {Pattern: "今天|做了什么|查看|记录", Intent: "query", Keywords: nil},
        },
    }
}

func (e *LocalNLPEngine) Parse(text string) *NLPResult {
    result := &NLPResult{
        Intent:     "record", // 默认为记录意图
        Keywords:   []string{},
        Confidence: 0.6,      // 本地规则置信度较低
    }
    
    // 1. 检测意图
    for _, rule := range e.rules {
        if matched, _ := regexp.MatchString(rule.Pattern, text); matched {
            result.Intent = rule.Intent
            break
        }
    }
    
    // 2. 提取关键词（行为动词+名词）
    keywords := e.extractKeywords(text)
    result.Keywords = keywords
    
    // 3. 提取时间表达式
    timeExpr := e.extractTimeExpr(text)
    result.TimeExpr = timeExpr
    
    // 4. 匹配行为标签
    tags, _ := e.behaviorTagRepo.GetAllTags()
    for _, tag := range tags {
        for _, keyword := range tag.MatchKeywords {
            if strings.Contains(text, keyword) {
                result.Entities["behavior_tag"] = tag.TagName
                break
            }
        }
    }
    
    return result
}

func (e *LocalNLPEngine) extractKeywords(text string) []string {
    // 提取动词+名词组合
    patterns := []string{
        "(吃|喝|拿|取|整理|收拾|运动|锻炼|休息|睡觉)(.+)",
    }
    
    keywords := []string{}
    for _, pattern := range patterns {
        re := regexp.MustCompile(pattern)
        matches := re.FindAllString(text, -1)
        keywords = append(keywords, matches...)
    }
    
    return keywords
}

func (e *LocalNLPEngine) extractTimeExpr(text string) string {
    // 时间正则
    patterns := []string{
        "(\\d{1,2})点(\\d{1,2})分?",      // "9点30分"
        "(\\d{1,2}):(\\d{1,2})",          // "9:30"
        "(早上|上午|中午|下午|晚上|睡前)", // 时间段
        "(早饭|午饭|晚饭)后",             // 相对时间
        "(\\d+)分钟后",                   // 相对时长
    }
    
    for _, pattern := range patterns {
        re := regexp.MustCompile(pattern)
        match := re.FindString(text)
        if match != "" {
            return match
        }
    }
    
    return ""
}
```

---

## 4. Flutter客户端集成

### 4.1 语音录制与上传

```dart
// lib/features/voice/services/asr_service.dart

class AsrService {
  final ApiClient _apiClient;
  final OssUploadService _ossService;
  
  /// 识别语音
  Future<AsrResult> recognize(String filePath) async {
    // 1. 上传到OSS
    final ossUrl = await _ossService.uploadVoiceFile(filePath);
    
    // 2. 调用后端API（后端会调用讯飞ASR）
    final response = await _apiClient.processVoice(
      VoiceProcessRequest(
        voiceFileUrl: ossUrl,
      ),
    );
    
    if (response.code != 200) {
      return AsrResult(
        success: false,
        error: response.message,
      );
    }
    
    return AsrResult(
      success: true,
      text: response.data.text,
      behaviorTag: response.data.behaviorTag,
      intent: response.data.intent,
      timeExpr: response.data.timeExpr,
    );
  }
  
  /// 流式识别（实时）
  /// 使用WebSocket连接讯飞实时语音识别服务
  Future<void> recognizeStream(
    Stream<List<int>> audioStream,
    Function(AsrPartialResult) onPartialResult,
    Function(AsrResult) onFinalResult,
  ) async {
    // WebSocket连接讯飞流式ASR
    // 实时返回识别结果
    // ...
  }
}

class AsrResult {
  final bool success;
  final String? text;
  final String? behaviorTag;
  final String? intent;
  final String? timeExpr;
  final String? error;
  
  AsrResult({
    required this.success,
    this.text,
    this.behaviorTag,
    this.intent,
    this.timeExpr,
    this.error,
  });
}

class AsrPartialResult {
  final String text;
  final bool isFinal;
  
  AsrPartialResult({required this.text, this.isFinal = false});
}
```

### 4.2 OSS语音文件上传

```dart
// lib/core/services/oss_upload_service.dart

class OssUploadService {
  final ApiClient _apiClient;
  final Dio _dio;
  
  late String _bucketName;
  late String _region;
  late String _accessKeyId;
  late String _accessKeySecret;
  late String _securityToken;
  late DateTime _tokenExpireTime;
  
  /// 初始化OSS配置（从后端获取临时凭证）
  Future<void> initialize() async {
    final response = await _apiClient.getOssToken();
    
    if (response.code == 200) {
      _bucketName = response.data.bucketName;
      _region = response.data.region;
      _accessKeyId = response.data.accessKeyId;
      _accessKeySecret = response.data.accessKeySecret;
      _securityToken = response.data.securityToken;
      _tokenExpireTime = DateTime.parse(response.data.expireTime);
    }
  }
  
  /// 上传语音文件
  Future<String> uploadVoiceFile(String filePath) async {
    // 检查凭证是否过期
    if (DateTime.now().isAfter(_tokenExpireTime.subtract(Duration(minutes: 5)))) {
      await initialize();
    }
    
    // 生成OSS路径
    final fileName = 'voice_${DateTime.now().millisecondsSinceEpoch}.wav';
    final ossPath = 'voice/${fileName}';
    
    // 构建签名URL
    final signedUrl = _generateSignedUrl(ossPath);
    
    // 上传文件
    final file = File(filePath);
    final response = await _dio.put(
      signedUrl,
      data: file.openRead(),
      options: Options(
        headers: {
          'Content-Type': 'audio/wav',
          'x-oss-security-token': _securityToken,
        },
        contentType: 'audio/wav',
      ),
    );
    
    if (response.statusCode == 200) {
      return 'https://${_bucketName}.oss-${_region}.aliyuncs.com/${ossPath}';
    }
    
    throw Exception('OSS upload failed');
  }
  
  /// 生成签名URL
  String _generateSignedUrl(String objectPath) {
    // 使用阿里云OSS签名算法
    // ...
    return '';
  }
}
```

---

## 5. 服务降级策略

### 5.1 降级流程

```
┌─────────────────────────────────────────────────────────────────┐
│                    AI服务降级流程                                 │
│                                                                 │
│  ┌─────────────┐                                                │
│  │ 用户语音    │                                                │
│  │ 输入        │                                                │
│  └─────────────┘                                                │
│        │                                                        │
│        ▼                                                        │
│  ┌─────────────┐                                                │
│  │ 尝试讯飞ASR │                                                │
│  │             │                                                │
│  │ timeout=5s │                                                │
│  └─────────────┘                                                │
│        │                                                        │
│        ├───────────────────────────────────────┐                │
│        │ 成功                                 │ 失败/超时       │
│        │                                       │                │
│        ▼                                       ▼                │
│  ┌─────────────┐                        ┌─────────────┐         │
│  │ 返回文字    │                        │ 降级到阿里云│         │
│  │             │                        │ ASR         │         │
│  └─────────────┘                        └─────────────┘         │
│                                                │                │
│                                                ├───────┐        │
│                                                │成功   │失败    │
│                                                │       │        │
│                                                ▼       ▼        │
│                                        ┌─────────────┐ ┌───────┐│
│                                        │ 返回文字    │ │本地   ││
│                                        │             │ │规则   ││
│                                        └─────────────┘ │引擎   ││
│                                                        └───────┘│
│                                                                 │
│  ┌─────────────┐                                                │
│  │ 尝试讯飞NLP │                                                │
│  │             │                                                │
│  │ timeout=3s │                                                │
│  └─────────────┘                                                │
│        │                                                        │
│        ├───────────────────────────────────────┐                │
│        │ 成功                                 │ 失败/超时       │
│        │                                       │                │
│        ▼                                       ▼                │
│  ┌─────────────┐                        ┌─────────────┐         │
│  │ 返回NLP结果 │                        │ 本地规则引擎│         │
│  │             │                        │             │         │
│  │ - 意图      │                        │ - 正则匹配  │         │
│  │ - 关键词    │                        │ - 关键词库  │         │
│  │ - 时间      │                        │             │         │
│  └─────────────┘                        └─────────────┘         │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 5.2 降级配置

```yaml
# configs/ai_config.yaml

ai_services:
  asr:
    primary:
      provider: xunfei
      timeout: 5s
      retry_count: 2
      retry_interval: 1s
    fallback:
      provider: aliyun
      timeout: 5s
    local:
      enabled: true
      confidence_threshold: 0.6
      
  nlp:
    primary:
      provider: xunfei
      timeout: 3s
      retry_count: 1
    local:
      enabled: true
      rules:
        - pattern: "准备|打算|要|想"
          intent: "plan"
        - pattern: "正在|在|刚|已经"
          intent: "record"
        - pattern: "今天|做了什么"
          intent: "query"
          
  behavior_tag:
    cache_enabled: true
    cache_ttl: 24h
    local_keywords_enabled: true
```

---

## 6. 成本估算

### 6.1 讯飞开放平台定价

| 服务 | 单价 | 免费额度 | 备注 |
|-----|------|---------|------|
| **语音听写（一句话）** | 0.0033元/次 | 500次/天 | 适合短语音 |
| **语音听写（流式）** | 0.0066元/次 | 500次/天 | 实时识别 |
| **语义理解** | 0.002元/次 | 500次/天 | NLP解析 |
| **语音合成** | 0.002元/次 | 200次/天 | 提醒播报 |

### 6.2 月度成本估算（1000活跃用户）

| 项目 | 日调用量 | 月调用量 | 月成本 |
|-----|---------|---------|--------|
| ASR（一句话） | 5000次 | 150000次 | ¥495 |
| NLP语义理解 | 5000次 | 150000次 | ¥300 |
| 语音合成 | 1000次 | 30000次 | ¥60 |
| **合计** | | | **¥855/月** |

**成本优化建议：**
1. 使用免费额度（500次/天），覆盖约100用户
2. 本地规则引擎处理简单case，减少云端调用
3. 缓存高频行为标签，减少NLP调用
4. 批量处理语音文件，减少实时调用

---

## 7. 下一步

- [06-Flutter客户端架构设计.md](./06-Flutter客户端架构设计.md) - Flutter项目结构
- [07-MVP开发计划与里程碑.md](./07-MVP开发计划与里程碑.md) - 开发计划
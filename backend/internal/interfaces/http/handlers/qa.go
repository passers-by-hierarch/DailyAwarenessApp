package handlers

import (
	"fmt"
	"net/http"
	"time"

	"github.com/dailyawareness/backend/internal/domain/models"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"go.uber.org/zap"
)

// QaHandler 问答处理器
type QaHandler struct {
	*Handler
}

// NewQaHandler 创建问答处理器
func NewQaHandler(h *Handler) *QaHandler {
	return &QaHandler{Handler: h}
}

// AskRequest 提问请求
type AskRequest struct {
	Question    string  `json:"question" binding:"required"`
	SessionID   *string `json:"session_id,omitempty"`
	EnableVoice bool    `json:"enable_voice"`
}

// AskQuestion 提交问题
func (h *QaHandler) AskQuestion(c *gin.Context) {
	userID, _ := c.Get("user_id")
	var req AskRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, Error(40001, "参数错误："+err.Error()))
		return
	}

	startTime := time.Now()

	// 1. 获取或创建会话
	var session *models.QaSession
	if req.SessionID != nil {
		var existingSession models.QaSession
		if err := h.DB.Where("id = ? AND user_id = ?", *req.SessionID, userID).First(&existingSession).Error; err == nil {
			session = &existingSession
		}
	}

	if session == nil {
		session = &models.QaSession{
			UserID:    userID.(string),
			StartedAt: time.Now(),
			Status:    "active",
		}
		if err := h.DB.Create(session).Error; err != nil {
			h.Logger.Error("failed to create qa session", zap.Error(err))
			c.JSON(http.StatusInternalServerError, Error(50001, "会话创建失败"))
			return
		}
	}

	// 2. 问题分类（简化实现）
	questionType := classifyQuestion(req.Question)

	// 3. 执行检索
	sourceRecords, answer := h.searchAndGenerateAnswer(userID.(string), req.Question, questionType)

	processingTime := int(time.Since(startTime).Milliseconds())
	confidence := calculateConfidence(sourceRecords)

	// 4. 保存问答历史
	history := models.QaHistory{
		SessionID:      session.ID,
		Question:       req.Question,
		QuestionType:   &questionType,
		Answer:         answer,
		ProcessingTime: &processingTime,
		Confidence:     &confidence,
	}

	if err := h.DB.Create(&history).Error; err != nil {
		h.Logger.Error("failed to save qa history", zap.Error(err))
	}

	// 5. 构建响应
	response := gin.H{
		"answer":         answer,
		"confidence":     confidence,
		"session_id":     session.ID,
		"source_records": sourceRecords,
	}

	if req.EnableVoice {
		// TODO: 集成TTS服务生成语音回答URL
		response["answer_voice_url"] = nil
	}

	c.JSON(http.StatusOK, Success(response))
}

// GetHistory 获取问答历史
func (h *QaHandler) GetHistory(c *gin.Context) {
	userID, _ := c.Get("user_id")
	sessionID := c.Query("session_id")
	page := parsePage(c.DefaultQuery("page", "1"))
	pageSize := parsePageSize(c.DefaultQuery("page_size", "20"))

	query := h.DB.Where("session_id IN (SELECT id FROM qa_sessions WHERE user_id = ?)", userID)
	if sessionID != "" {
		query = query.Where("session_id = ?", sessionID)
	}

	var total int64
	if err := query.Model(&models.QaHistory{}).Count(&total).Error; err != nil {
		h.Logger.Error("failed to count qa history", zap.Error(err))
	}

	var histories []models.QaHistory
	if err := query.Order("created_at DESC").
		Offset((page - 1) * pageSize).Limit(pageSize).Find(&histories).Error; err != nil {
		h.Logger.Error("failed to get qa history", zap.Error(err))
		c.JSON(http.StatusInternalServerError, Error(50001, "查询失败"))
		return
	}

	items := make([]gin.H, 0, len(histories))
	for _, h := range histories {
		items = append(items, gin.H{
			"id":              h.ID,
			"session_id":      h.SessionID,
			"question":        h.Question,
			"question_type":   h.QuestionType,
			"answer":          h.Answer,
			"processing_time": h.ProcessingTime,
			"confidence":      h.Confidence,
			"created_at":      h.CreatedAt,
		})
	}

	c.JSON(http.StatusOK, Success(gin.H{
		"items": items,
		"pagination": gin.H{
			"page":        page,
			"page_size":   pageSize,
			"total":       total,
			"total_pages": (int(total) + pageSize - 1) / pageSize,
		},
	}))
}

// GetSessions 获取会话列表
func (h *QaHandler) GetSessions(c *gin.Context) {
	userID, _ := c.Get("user_id")

	var sessions []models.QaSession
	if err := h.DB.Where("user_id = ?", userID).Order("started_at DESC").Find(&sessions).Error; err != nil {
		h.Logger.Error("failed to get qa sessions", zap.Error(err))
		c.JSON(http.StatusInternalServerError, Error(50001, "查询失败"))
		return
	}

	items := make([]gin.H, 0, len(sessions))
	for _, s := range sessions {
		// 统计消息数量
		var messageCount int64
		h.DB.Model(&models.QaHistory{}).Where("session_id = ?", s.ID).Count(&messageCount)

		items = append(items, gin.H{
			"id":            s.ID,
			"started_at":    s.StartedAt,
			"ended_at":      s.EndedAt,
			"status":        s.Status,
			"message_count": messageCount,
		})
	}

	c.JSON(http.StatusOK, Success(gin.H{
		"items": items,
	}))
}

// EndSession 结束会话
func (h *QaHandler) EndSession(c *gin.Context) {
	sessionID := c.Param("session_id")
	userID, _ := c.Get("user_id")

	now := time.Now()
	if err := h.DB.Model(&models.QaSession{}).
		Where("id = ? AND user_id = ?", sessionID, userID).
		Updates(map[string]interface{}{
			"status":   "ended",
			"ended_at": now,
		}).Error; err != nil {
		h.Logger.Error("failed to end session", zap.Error(err))
		c.JSON(http.StatusInternalServerError, Error(50001, "操作失败"))
		return
	}

	c.JSON(http.StatusOK, Success(gin.H{
		"id":       sessionID,
		"status":   "ended",
		"ended_at": now,
	}))
}

// classifyQuestion 问题分类（简化规则引擎）
func classifyQuestion(question string) string {
	// 物品位置
	if containsAny(question, []string{"在哪", "放在哪", "在哪儿", "哪个位置", "找"}) {
		return "item_location"
	}
	// 时间查询
	if containsAny(question, []string{"什么时候", "几点", "什么时间", "上周", "昨天", "前天"}) {
		return "time_query"
	}
	// 频率统计
	if containsAny(question, []string{"几次", "多少次", "频率", "规律", "经常"}) {
		return "frequency_stats"
	}
	// 对比分析
	if containsAny(question, []string{"比", "对比", "比较", "差距", "变化"}) {
		return "comparison_analysis"
	}
	return "complex_decompose"
}

// searchAndGenerateAnswer 检索并生成回答
func (h *QaHandler) searchAndGenerateAnswer(userID string, question string, questionType string) ([]models.SourceRecord, string) {
	var sourceRecords []models.SourceRecord
	var answer string

	switch questionType {
	case "item_location":
		// 检索物品位置记录
		var items []models.ItemRecord
		if err := h.DB.Where("user_id = ? AND is_active = ?", userID, true).
			Order("updated_at DESC").Limit(5).Find(&items).Error; err == nil {
			for _, item := range items {
				sourceRecords = append(sourceRecords, models.SourceRecord{
					ID:             item.ID,
					Timestamp:      item.RecordedAt,
					Content:        item.ItemName + "：" + item.Location,
					RecordType:     "item",
					RelevanceScore: 0.95,
					SourceName:     strPtr("物品位置"),
				})
			}
		}
		if len(items) > 0 {
			answer = "根据您的记录，" + items[0].ItemName + "放在" + items[0].Location + "（" + items[0].RecordedAt.Format("1月2日") + "记录）。"
		} else {
			answer = "抱歉，未找到相关物品位置记录。"
		}

	case "time_query":
		// 检索时间线记录
		var records []models.TimelineRecord
		if err := h.DB.Where("user_id = ?", userID).
			Order("timestamp DESC").Limit(10).Find(&records).Error; err == nil {
			for _, record := range records {
				sourceRecords = append(sourceRecords, models.SourceRecord{
					ID:             record.ID,
					Timestamp:      record.Timestamp,
					Content:        record.Content,
					RecordType:     "timeline",
					RelevanceScore: 0.85,
					BehaviorTag:    record.BehaviorTag,
				})
			}
		}
		if len(records) > 0 {
			answer = "您最近的记录包括：" + records[0].Content + "（" + records[0].Timestamp.Format("1月2日 15:04") + "）。"
		} else {
			answer = "抱歉，未找到相关时间记录。"
		}

	case "frequency_stats":
		// 统计行为频率
		now := time.Now()
		startDate := now.AddDate(0, 0, -7)
		var records []models.TimelineRecord
		if err := h.DB.Where("user_id = ? AND timestamp >= ?", userID, startDate).Find(&records).Error; err == nil {
			freq := make(map[string]int)
			for _, r := range records {
				if r.BehaviorTag != nil {
					freq[*r.BehaviorTag]++
				}
			}
			for tag, count := range freq {
				sourceRecords = append(sourceRecords, models.SourceRecord{
					ID:             uuid.New().String(),
					Timestamp:      now,
					Content:        tag + "：" + fmt.Sprintf("%d", count) + "次",
					RecordType:     "timeline",
					RelevanceScore: 0.9,
					BehaviorTag:    &tag,
				})
			}
			answer = "最近7天，您共记录了" + fmt.Sprintf("%d", len(records)) + "条行为。"
		} else {
			answer = "抱歉，无法获取频率统计。"
		}

	default:
		answer = "这是一个复杂问题，我已记录您的问题，将尽快为您分析。"
	}

	return sourceRecords, answer
}

// calculateConfidence 计算置信度
func calculateConfidence(records []models.SourceRecord) float64 {
	if len(records) == 0 {
		return 0.5
	}
	var totalScore float64
	for _, r := range records {
		totalScore += r.RelevanceScore
	}
	avg := totalScore / float64(len(records))
	if avg > 0.95 {
		return 0.96
	}
	return avg + 0.1
}

func containsAny(text string, keywords []string) bool {
	for _, kw := range keywords {
		if len(kw) > 0 && len(text) >= len(kw) {
			// 简单实现
			for i := 0; i <= len(text)-len(kw); i++ {
				if text[i:i+len(kw)] == kw {
					return true
				}
			}
		}
	}
	return false
}

func strPtr(s string) *string {
	return &s
}

func parsePage(s string) int {
	var result int
	_, err := fmt.Sscanf(s, "%d", &result)
	if err != nil || result < 1 {
		return 1
	}
	return result
}

func parsePageSize(s string) int {
	var result int
	_, err := fmt.Sscanf(s, "%d", &result)
	if err != nil || result < 1 {
		return 20
	}
	if result > 100 {
		return 100
	}
	return result
}

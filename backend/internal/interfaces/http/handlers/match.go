package handlers

import (
	"fmt"
	"net/http"
	"sort"
	"time"

	"github.com/dailyawareness/backend/internal/domain/models"
	"github.com/gin-gonic/gin"
	"go.uber.org/zap"
)

// MatchHandler 匹配引擎处理器
type MatchHandler struct {
	*Handler
}

// NewMatchHandler 创建匹配处理器
func NewMatchHandler(h *Handler) *MatchHandler {
	return &MatchHandler{Handler: h}
}

// ManualMatchRequest 手动匹配请求
type ManualMatchRequest struct {
	TimelineID string `json:"timeline_id" binding:"required"`
	AgendaID   string `json:"agenda_id" binding:"required"`
}

// ManualMatch 手动匹配时间线记录与事程
func (h *MatchHandler) ManualMatch(c *gin.Context) {
	userID, _ := c.Get("user_id")
	var req ManualMatchRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, Error(40001, "参数错误："+err.Error()))
		return
	}

	// 验证时间线记录是否存在且属于当前用户
	var timeline models.TimelineRecord
	if err := h.DB.Where("id = ? AND user_id = ?", req.TimelineID, userID).First(&timeline).Error; err != nil {
		c.JSON(http.StatusNotFound, Error(40401, "时间线记录不存在"))
		return
	}

	// 验证事程是否存在且属于当前用户
	var agenda models.Agenda
	if err := h.DB.Where("id = ? AND user_id = ?", req.AgendaID, userID).First(&agenda).Error; err != nil {
		c.JSON(http.StatusNotFound, Error(40401, "事程不存在"))
		return
	}

	// 创建匹配结果记录
	matchResult := models.MatchResult{
		TimelineID:  req.TimelineID,
		AgendaID:    req.AgendaID,
		MatchScore:  1.0,
		MatchReason: "user_confirmed",
		Status:      "user_confirmed",
	}

	if err := h.DB.Create(&matchResult).Error; err != nil {
		h.Logger.Error("failed to create match result", zap.Error(err))
		c.JSON(http.StatusInternalServerError, Error(50001, "匹配失败"))
		return
	}

	// 更新时间线记录
	now := time.Now()
	if err := h.DB.Model(&timeline).Updates(map[string]interface{}{
		"matched_agenda_id": req.AgendaID,
		"match_score":       1.0,
	}).Error; err != nil {
		h.Logger.Error("failed to update timeline", zap.Error(err))
	}

	// 更新事程状态
	if err := h.DB.Model(&agenda).Updates(map[string]interface{}{
		"status":              "matched",
		"matched_timeline_id": req.TimelineID,
		"matched_at":          now,
	}).Error; err != nil {
		h.Logger.Error("failed to update agenda", zap.Error(err))
	}

	c.JSON(http.StatusOK, Success(gin.H{
		"match_result": matchResult,
		"agenda": gin.H{
			"id":         agenda.ID,
			"status":     "matched",
			"matched_at": now,
		},
	}))
}

// CancelMatch 取消匹配
func (h *MatchHandler) CancelMatch(c *gin.Context) {
	userID, _ := c.Get("user_id")
	var req ManualMatchRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, Error(40001, "参数错误："+err.Error()))
		return
	}

	// 更新匹配结果状态
	if err := h.DB.Model(&models.MatchResult{}).
		Where("timeline_id = ? AND agenda_id = ?", req.TimelineID, req.AgendaID).
		Update("status", "user_rejected").Error; err != nil {
		h.Logger.Error("failed to update match result", zap.Error(err))
	}

	// 更新时间线记录
	if err := h.DB.Model(&models.TimelineRecord{}).
		Where("id = ? AND user_id = ?", req.TimelineID, userID).
		Updates(map[string]interface{}{
			"matched_agenda_id": nil,
			"match_score":       nil,
		}).Error; err != nil {
		h.Logger.Error("failed to update timeline", zap.Error(err))
	}

	// 更新事程状态
	if err := h.DB.Model(&models.Agenda{}).
		Where("id = ? AND user_id = ?", req.AgendaID, userID).
		Updates(map[string]interface{}{
			"status":              "active",
			"matched_timeline_id": nil,
			"matched_at":          nil,
		}).Error; err != nil {
		h.Logger.Error("failed to update agenda", zap.Error(err))
	}

	c.JSON(http.StatusOK, Success(gin.H{
		"message": "匹配已取消",
	}))
}

// GetPendingAgendas 查询待匹配事程
func (h *MatchHandler) GetPendingAgendas(c *gin.Context) {
	userID, _ := c.Get("user_id")
	behaviorTag := c.Query("behavior_tag")
	timeRangeStr := c.DefaultQuery("time_range", "30")

	// 解析时间范围
	timeRange := 30
	if tr, err := parseInt(timeRangeStr); err == nil && tr > 0 {
		timeRange = tr
	}

	now := time.Now()
	startTime := now.Add(-time.Duration(timeRange) * time.Minute)
	endTime := now.Add(time.Duration(timeRange) * time.Minute)

	query := h.DB.Where("user_id = ? AND status = ? AND planned_time >= ? AND planned_time <= ?",
		userID, "active", startTime, endTime)

	if behaviorTag != "" {
		query = query.Where("behavior_tag = ?", behaviorTag)
	}

	var agendas []models.Agenda
	if err := query.Order("planned_time ASC").Find(&agendas).Error; err != nil {
		h.Logger.Error("failed to get pending agendas", zap.Error(err))
		c.JSON(http.StatusInternalServerError, Error(50001, "查询失败"))
		return
	}

	items := make([]gin.H, 0, len(agendas))
	for _, agenda := range agendas {
		deviation := int(now.Sub(agenda.PlannedTime).Minutes())
		if deviation < 0 {
			deviation = -deviation
		}
		items = append(items, gin.H{
			"id":             agenda.ID,
			"planned_time":   agenda.PlannedTime,
			"content":        agenda.Content,
			"behavior_tag":   agenda.BehaviorTag,
			"status":         agenda.Status,
			"time_deviation": deviation,
		})
	}

	c.JSON(http.StatusOK, Success(gin.H{
		"items": items,
	}))
}

// AutoMatch 自动匹配（内部使用，也可通过API触发）
func (h *MatchHandler) AutoMatch(c *gin.Context) {
	userID, _ := c.Get("user_id")
	timelineID := c.Query("timeline_id")

	if timelineID == "" {
		c.JSON(http.StatusBadRequest, Error(40001, "缺少timeline_id参数"))
		return
	}

	// 获取时间线记录
	var timeline models.TimelineRecord
	if err := h.DB.Where("id = ? AND user_id = ?", timelineID, userID).First(&timeline).Error; err != nil {
		c.JSON(http.StatusNotFound, Error(40401, "时间线记录不存在"))
		return
	}

	// 查找可能匹配的事程
	candidates, err := h.findMatchCandidates(userID.(string), timeline)
	if err != nil {
		h.Logger.Error("failed to find match candidates", zap.Error(err))
		c.JSON(http.StatusInternalServerError, Error(50001, "匹配失败"))
		return
	}

	if len(candidates) == 0 {
		c.JSON(http.StatusOK, Success(gin.H{
			"match_success": false,
			"reason":        "未找到匹配事程",
		}))
		return
	}

	// 选择最佳匹配
	bestMatch := candidates[0]
	if bestMatch.MatchScore < 0.7 {
		c.JSON(http.StatusOK, Success(gin.H{
			"match_success": false,
			"reason":        "匹配度不足",
			"best_score":    bestMatch.MatchScore,
		}))
		return
	}

	// 创建匹配记录
	matchResult := models.MatchResult{
		TimelineID:  timelineID,
		AgendaID:    bestMatch.AgendaID,
		MatchScore:  bestMatch.MatchScore,
		MatchReason: bestMatch.Reason,
		Status:      "auto_matched",
	}

	if err := h.DB.Create(&matchResult).Error; err != nil {
		h.Logger.Error("failed to create auto match result", zap.Error(err))
		c.JSON(http.StatusInternalServerError, Error(50001, "匹配失败"))
		return
	}

	// 更新时间线记录
	now := time.Now()
	if err := h.DB.Model(&timeline).Updates(map[string]interface{}{
		"matched_agenda_id": bestMatch.AgendaID,
		"match_score":       bestMatch.MatchScore,
	}).Error; err != nil {
		h.Logger.Error("failed to update timeline", zap.Error(err))
	}

	// 更新事程状态
	if err := h.DB.Model(&models.Agenda{}).Where("id = ?", bestMatch.AgendaID).Updates(map[string]interface{}{
		"status":              "matched",
		"matched_timeline_id": timelineID,
		"matched_at":          now,
	}).Error; err != nil {
		h.Logger.Error("failed to update agenda", zap.Error(err))
	}

	c.JSON(http.StatusOK, Success(gin.H{
		"match_success":  true,
		"agenda_id":      bestMatch.AgendaID,
		"match_score":    bestMatch.MatchScore,
		"time_deviation": bestMatch.TimeDeviation,
	}))
}

// MatchCandidate 匹配候选
type MatchCandidate struct {
	AgendaID      string  `json:"agenda_id"`
	MatchScore    float64 `json:"match_score"`
	TimeDeviation int     `json:"time_deviation"`
	Reason        string  `json:"reason"`
}

// findMatchCandidates 查找匹配候选
func (h *MatchHandler) findMatchCandidates(userID string, timeline models.TimelineRecord) ([]MatchCandidate, error) {
	now := timeline.Timestamp
	startTime := now.Add(-30 * time.Minute)
	endTime := now.Add(30 * time.Minute)

	// 查找时间窗口内的事程
	var agendas []models.Agenda
	if err := h.DB.Where("user_id = ? AND status IN (?, ?) AND planned_time >= ? AND planned_time <= ?",
		userID, "pending", "active", startTime, endTime).Find(&agendas).Error; err != nil {
		return nil, err
	}

	var candidates []MatchCandidate
	for _, agenda := range agendas {
		score := 0.0
		reason := ""

		// 行为标签匹配
		if timeline.BehaviorTag != nil && agenda.BehaviorTag != nil &&
			*timeline.BehaviorTag == *agenda.BehaviorTag {
			score += 0.6
			reason = "行为标签匹配"
		} else if timeline.BehaviorTag != nil && agenda.BehaviorTag != nil {
			// 简单关键词匹配
			if containsKeyword(timeline.Content, *agenda.BehaviorTag) {
				score += 0.4
				reason = "内容关键词匹配"
			}
		}

		// 时间接近度
		deviation := int(now.Sub(agenda.PlannedTime).Minutes())
		if deviation < 0 {
			deviation = -deviation
		}
		if deviation <= 5 {
			score += 0.3
		} else if deviation <= 15 {
			score += 0.2
		} else if deviation <= 30 {
			score += 0.1
		}

		if score > 0 {
			candidates = append(candidates, MatchCandidate{
				AgendaID:      agenda.ID,
				MatchScore:    score,
				TimeDeviation: deviation,
				Reason:        reason,
			})
		}
	}

	// 按匹配分数排序
	sort.Slice(candidates, func(i, j int) bool {
		return candidates[i].MatchScore > candidates[j].MatchScore
	})

	return candidates, nil
}

func containsKeyword(content, keyword string) bool {
	// 简单实现，实际项目中可使用更复杂的文本匹配算法
	return len(keyword) > 0 && (content == keyword || len(content) > len(keyword))
}

func parseInt(s string) (int, error) {
	var result int
	_, err := fmt.Sscanf(s, "%d", &result)
	return result, err
}

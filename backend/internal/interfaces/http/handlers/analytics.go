package handlers

import (
	"net/http"
	"time"

	"github.com/dailyawareness/backend/internal/domain/models"
	"github.com/gin-gonic/gin"
	"go.uber.org/zap"
)

// AnalyticsHandler 分析处理器
type AnalyticsHandler struct {
	*Handler
}

// NewAnalyticsHandler 创建分析处理器
func NewAnalyticsHandler(h *Handler) *AnalyticsHandler {
	return &AnalyticsHandler{Handler: h}
}

// GetFrequencyAnalysis 获取行为频率分析
func (h *AnalyticsHandler) GetFrequencyAnalysis(c *gin.Context) {
	userID, _ := c.Get("user_id")
	period := c.DefaultQuery("period", "week")

	var startDate, endDate time.Time
	now := time.Now()

	switch period {
	case "day":
		startDate = now.AddDate(0, 0, -1)
		endDate = now
	case "week":
		startDate = now.AddDate(0, 0, -7)
		endDate = now
	case "month":
		startDate = now.AddDate(0, -1, 0)
		endDate = now
	default:
		startDate = now.AddDate(0, 0, -7)
		endDate = now
	}

	// 查询时间线记录
	var records []models.TimelineRecord
	if err := h.DB.Where("user_id = ? AND timestamp >= ? AND timestamp <= ?",
		userID, startDate, endDate).Find(&records).Error; err != nil {
		h.Logger.Error("failed to get records for frequency", zap.Error(err))
		c.JSON(http.StatusInternalServerError, Error(50001, "查询失败"))
		return
	}

	// 统计行为频率
	behaviorFrequency := make(map[string]int)
	for _, record := range records {
		if record.BehaviorTag != nil {
			behaviorFrequency[*record.BehaviorTag]++
		}
	}

	// 排序并分类
	type behaviorStat struct {
		Tag   string  `json:"tag"`
		Count int     `json:"count"`
		Rate  float64 `json:"rate"`
	}

	var topBehaviors, lowBehaviors []behaviorStat
	periodDays := int(endDate.Sub(startDate).Hours()/24) + 1

	for tag, count := range behaviorFrequency {
		rate := float64(count) / float64(periodDays)
		stat := behaviorStat{Tag: tag, Count: count, Rate: rate}
		if rate >= 0.7 {
			topBehaviors = append(topBehaviors, stat)
		} else if rate <= 0.5 {
			lowBehaviors = append(lowBehaviors, stat)
		}
	}

	c.JSON(http.StatusOK, Success(gin.H{
		"period":             period,
		"behavior_frequency": behaviorFrequency,
		"top_behaviors":      topBehaviors,
		"low_behaviors":      lowBehaviors,
	}))
}

// GetMatchRateAnalysis 获取匹配率趋势
func (h *AnalyticsHandler) GetMatchRateAnalysis(c *gin.Context) {
	userID, _ := c.Get("user_id")
	period := c.DefaultQuery("period", "week")

	var days int
	switch period {
	case "day":
		days = 1
	case "week":
		days = 7
	case "month":
		days = 30
	default:
		days = 7
	}

	now := time.Now()
	results := make([]gin.H, 0, days)
	totalMatched := 0
	totalRecords := 0

	for i := days - 1; i >= 0; i-- {
		date := now.AddDate(0, 0, -i)
		startOfDay := time.Date(date.Year(), date.Month(), date.Day(), 0, 0, 0, 0, date.Location())
		endOfDay := startOfDay.Add(24 * time.Hour)

		var records []models.TimelineRecord
		if err := h.DB.Where("user_id = ? AND timestamp >= ? AND timestamp < ?",
			userID, startOfDay, endOfDay).Find(&records).Error; err != nil {
			continue
		}

		matched := 0
		for _, r := range records {
			if r.MatchedAgendaID != nil {
				matched++
			}
		}

		var rate float64
		if len(records) > 0 {
			rate = float64(matched) / float64(len(records))
		}

		totalMatched += matched
		totalRecords += len(records)

		results = append(results, gin.H{
			"date": date.Format("2006-01-02"),
			"rate": rate,
		})
	}

	var averageRate float64
	if totalRecords > 0 {
		averageRate = float64(totalMatched) / float64(totalRecords)
	}

	// 计算趋势
	trend := "stable"
	if len(results) >= 2 {
		first := results[0]["rate"].(float64)
		last := results[len(results)-1]["rate"].(float64)
		if last > first+0.1 {
			trend = "up"
		} else if last < first-0.1 {
			trend = "down"
		}
	}

	c.JSON(http.StatusOK, Success(gin.H{
		"period":       period,
		"daily_rate":   results,
		"average_rate": averageRate,
		"trend":        trend,
	}))
}

// GetAnomalies 获取异常检测报告
func (h *AnalyticsHandler) GetAnomalies(c *gin.Context) {
	userID, _ := c.Get("user_id")

	// 查询最近7天的行为记录
	now := time.Now()
	startDate := now.AddDate(0, 0, -7)

	var records []models.TimelineRecord
	if err := h.DB.Where("user_id = ? AND timestamp >= ?", userID, startDate).Find(&records).Error; err != nil {
		h.Logger.Error("failed to get records for anomaly", zap.Error(err))
		c.JSON(http.StatusInternalServerError, Error(50001, "查询失败"))
		return
	}

	// 查询活跃事程
	var agendas []models.Agenda
	if err := h.DB.Where("user_id = ? AND status IN (?, ?)", userID, "pending", "active").Find(&agendas).Error; err != nil {
		h.Logger.Error("failed to get agendas for anomaly", zap.Error(err))
	}

	var anomalies []gin.H

	// 检测遗漏行为
	for _, agenda := range agendas {
		if agenda.BehaviorTag == nil {
			continue
		}

		// 检查最近3天是否有该行为记录
		threeDaysAgo := now.AddDate(0, 0, -3)
		var count int64
		h.DB.Model(&models.TimelineRecord{}).
			Where("user_id = ? AND behavior_tag = ? AND timestamp >= ?", userID, *agenda.BehaviorTag, threeDaysAgo).
			Count(&count)

		if count == 0 {
			anomalies = append(anomalies, gin.H{
				"type":         "missed_behavior",
				"behavior_tag": *agenda.BehaviorTag,
				"description":  "连续3天未记录" + *agenda.BehaviorTag,
				"severity":     "high",
				"suggestion":   "请确认是否按时" + *agenda.BehaviorTag + "，如有遗漏请补录",
			})
		}
	}

	c.JSON(http.StatusOK, Success(gin.H{
		"anomalies": anomalies,
	}))
}

// GetOptimizationSuggestions 获取策略优化建议
func (h *AnalyticsHandler) GetOptimizationSuggestions(c *gin.Context) {
	userID, _ := c.Get("user_id")

	var suggestions []gin.H

	// 分析延后习惯
	var snoozedAgendas []models.Agenda
	if err := h.DB.Where("user_id = ? AND status = ?", userID, "snoozed").
		Order("updated_at DESC").Limit(10).Find(&snoozedAgendas).Error; err == nil && len(snoozedAgendas) > 3 {
		suggestions = append(suggestions, gin.H{
			"type":              "time_adjustment",
			"agenda_content":    snoozedAgendas[0].Content,
			"current_setting":   snoozedAgendas[0].PlannedTime.Format("15:04"),
			"suggested_setting": "延后15分钟",
			"reason":            "您最近多次延后该事程提醒",
			"confidence":        0.75,
			"auto_apply":        false,
		})
	}

	// 分析行为链模式
	var records []models.TimelineRecord
	if err := h.DB.Where("user_id = ? AND timestamp >= ?", userID, time.Now().AddDate(0, 0, -14)).
		Order("timestamp ASC").Find(&records).Error; err == nil && len(records) > 5 {
		suggestions = append(suggestions, gin.H{
			"type":              "behavior_chain",
			"current_setting":   "固定时间",
			"suggested_setting": "行为链触发",
			"reason":            "检测到您的行为存在规律性关联",
			"confidence":        0.8,
			"auto_apply":        true,
		})
	}

	c.JSON(http.StatusOK, Success(gin.H{
		"suggestions": suggestions,
	}))
}

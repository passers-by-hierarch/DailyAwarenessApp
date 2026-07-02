package handlers

import (
	"net/http"
	"time"

	"github.com/dailyawareness/backend/internal/domain/models"
	"github.com/gin-gonic/gin"
	"go.uber.org/zap"
)

// ReminderHandler 提醒处理器
type ReminderHandler struct {
	*Handler
}

// NewReminderHandler 创建提醒处理器
func NewReminderHandler(h *Handler) *ReminderHandler {
	return &ReminderHandler{Handler: h}
}

// GetDefaultRule 获取全局默认提醒规则
func (h *ReminderHandler) GetDefaultRule(c *gin.Context) {
	userID, _ := c.Get("user_id")

	var rule models.ReminderRule
	if err := h.DB.Where("user_id = ? AND is_default = ?", userID, true).First(&rule).Error; err != nil {
		// 返回默认规则
		c.JSON(http.StatusOK, Success(gin.H{
			"level":               "standard",
			"enable_notification": true,
			"enable_sound":        true,
			"enable_vibration":    true,
			"enable_popup":        false,
			"remind_offset":       5,
			"repeat_interval":     10,
			"max_reminders":       3,
			"allow_snooze":        true,
			"allow_skip":          true,
		}))
		return
	}

	c.JSON(http.StatusOK, Success(rule))
}

// UpdateDefaultRule 更新全局默认提醒规则
func (h *ReminderHandler) UpdateDefaultRule(c *gin.Context) {
	_ , _ = c.Get("user_id")
	var req UpdateRuleRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, Error(40001, "参数错误："+err.Error()))
		return
	}

	// TODO: 实现默认规则更新逻辑
	c.JSON(http.StatusOK, Success(gin.H{
		"message": "默认规则更新成功",
		"rule":    req,
	}))
}

// GetAgendaRule 获取事程提醒规则
func (h *ReminderHandler) GetAgendaRule(c *gin.Context) {
	agendaID := c.Param("id")
	userID, _ := c.Get("user_id")

	// 验证事程归属
	var agenda models.Agenda
	if err := h.DB.Where("id = ? AND user_id = ?", agendaID, userID).First(&agenda).Error; err != nil {
		c.JSON(http.StatusNotFound, Error(40401, "事程不存在"))
		return
	}

	var rule models.ReminderRule
	if err := h.DB.Where("agenda_id = ?", agendaID).First(&rule).Error; err != nil {
		// 返回默认规则
		c.JSON(http.StatusOK, Success(gin.H{
			"agenda_id":           agendaID,
			"level":               agenda.RemindLevel,
			"enable_notification": true,
			"enable_sound":        true,
			"enable_vibration":    true,
			"enable_popup":        agenda.RemindLevel == "forced",
			"remind_offset":       agenda.RemindOffset,
			"repeat_interval":     10,
			"max_reminders":       3,
			"allow_snooze":        true,
			"allow_skip":          agenda.RemindLevel != "forced",
		}))
		return
	}

	c.JSON(http.StatusOK, Success(rule))
}

// UpdateAgendaRule 更新事程提醒规则
func (h *ReminderHandler) UpdateAgendaRule(c *gin.Context) {
	agendaID := c.Param("id")
	userID, _ := c.Get("user_id")

	// 验证事程归属
	var agenda models.Agenda
	if err := h.DB.Where("id = ? AND user_id = ?", agendaID, userID).First(&agenda).Error; err != nil {
		c.JSON(http.StatusNotFound, Error(40401, "事程不存在"))
		return
	}

	var req UpdateRuleRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, Error(40001, "参数错误："+err.Error()))
		return
	}

	// TODO: 实现事程规则更新逻辑
	c.JSON(http.StatusOK, Success(gin.H{
		"message": "提醒规则更新成功",
		"rule":    req,
	}))
}

// GetEscalatingStrategies 获取升级策略列表
func (h *ReminderHandler) GetEscalatingStrategies(c *gin.Context) {
	userID, _ := c.Get("user_id")

	var strategies []models.EscalatingStrategy
	if err := h.DB.Where("user_id = ? OR is_default = ?", userID, true).Find(&strategies).Error; err != nil {
		h.Logger.Error("failed to get strategies", zap.Error(err))
		c.JSON(http.StatusInternalServerError, Error(50001, "查询失败"))
		return
	}

	c.JSON(http.StatusOK, Success(gin.H{
		"items": strategies,
	}))
}

// CreateEscalatingStrategy 创建自定义升级策略
func (h *ReminderHandler) CreateEscalatingStrategy(c *gin.Context) {
	userID, _ := c.Get("user_id")
	var req CreateStrategyRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, Error(40001, "参数错误："+err.Error()))
		return
	}

	strategy := models.EscalatingStrategy{
		UserID:       userID.(string),
		Name:         req.Name,
		StagesConfig: req.StagesConfig,
	}

	if err := h.DB.Create(&strategy).Error; err != nil {
		h.Logger.Error("failed to create strategy", zap.Error(err))
		c.JSON(http.StatusInternalServerError, Error(50001, "创建失败"))
		return
	}

	c.JSON(http.StatusCreated, Success(strategy))
}

// UpdateRuleRequest 更新规则请求
type UpdateRuleRequest struct {
	Level              string `json:"level"`
	EnableNotification bool   `json:"enable_notification"`
	EnableSound        bool   `json:"enable_sound"`
	EnableVibration    bool   `json:"enable_vibration"`
	EnablePopup        bool   `json:"enable_popup"`
	RemindOffset       int    `json:"remind_offset"`
	RepeatInterval     int    `json:"repeat_interval"`
	MaxReminders       int    `json:"max_reminders"`
	AllowSnooze        bool   `json:"allow_snooze"`
	AllowSkip          bool   `json:"allow_skip"`
}

// CreateStrategyRequest 创建策略请求
type CreateStrategyRequest struct {
	Name         string `json:"name" binding:"required"`
	StagesConfig string `json:"stages_config" binding:"required"`
}

// TriggerReminder 手动触发提醒（测试用）
func (h *ReminderHandler) TriggerReminder(c *gin.Context) {
	agendaID := c.Param("id")
	userID, _ := c.Get("user_id")

	var agenda models.Agenda
	if err := h.DB.Where("id = ? AND user_id = ?", agendaID, userID).First(&agenda).Error; err != nil {
		c.JSON(http.StatusNotFound, Error(40401, "事程不存在"))
		return
	}

	// 记录提醒历史
	history := models.ReminderHistory{
		UserID:      userID.(string),
		AgendaID:    agendaID,
		RemindStage: "manual_trigger",
		RemindTime:  time.Now(),
		PlannedTime: agenda.PlannedTime,
		MethodsUsed: []string{"notification", "sound", "vibration"},
		Result:      "success",
	}

	if err := h.DB.Create(&history).Error; err != nil {
		h.Logger.Error("failed to create reminder history", zap.Error(err))
	}

	c.JSON(http.StatusOK, Success(gin.H{
		"message":     "提醒已触发",
		"agenda_id":   agendaID,
		"content":     agenda.Content,
		"remind_time": time.Now(),
	}))
}

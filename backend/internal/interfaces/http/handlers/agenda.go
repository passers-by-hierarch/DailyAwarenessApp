package handlers

import (
	"fmt"
	"net/http"
	"time"

	"github.com/dailyawareness/backend/internal/domain/models"
	"github.com/dailyawareness/backend/internal/services/nlp"
	"github.com/gin-gonic/gin"
	"go.uber.org/zap"
)

// AgendaHandler 事程处理器
type AgendaHandler struct {
	*Handler
}

// NewAgendaHandler 创建事程处理器
func NewAgendaHandler(h *Handler) *AgendaHandler {
	return &AgendaHandler{Handler: h}
}

// CreateAgendaRequest 创建事程请求
type CreateAgendaRequest struct {
	PlannedTime   time.Time `json:"planned_time" binding:"required"`
	Content       string    `json:"content" binding:"required"`
	BehaviorTag   *string   `json:"behavior_tag"`
	RemindOffset  int       `json:"remind_offset"`
	RemindLevel   string    `json:"remind_level"`
	IsRecurring   bool      `json:"is_recurring"`
	RecurringRule *string   `json:"recurring_rule"`
}

// CreateAgenda 创建事程
func (h *AgendaHandler) CreateAgenda(c *gin.Context) {
	userID, _ := c.Get("user_id")
	var req CreateAgendaRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, Error(40001, "参数错误："+err.Error()))
		return
	}

	agenda := models.Agenda{
		UserID:        userID.(string),
		PlannedTime:   req.PlannedTime,
		Content:       req.Content,
		BehaviorTag:   req.BehaviorTag,
		RemindOffset:  req.RemindOffset,
		RemindLevel:   req.RemindLevel,
		IsRecurring:   req.IsRecurring,
		RecurringRule: req.RecurringRule,
		Status:        "pending",
		Source:        "manual",
	}

	if agenda.RemindLevel == "" {
		agenda.RemindLevel = "standard"
	}
	if agenda.RemindOffset == 0 {
		agenda.RemindOffset = 5
	}

	if err := h.DB.Create(&agenda).Error; err != nil {
		h.Logger.Error("failed to create agenda", zap.Error(err))
		c.JSON(http.StatusInternalServerError, Error(50001, "创建失败"))
		return
	}

	c.JSON(http.StatusOK, Success(agenda))
}

// GetTodayAgendas 获取今日事程
func (h *AgendaHandler) GetTodayAgendas(c *gin.Context) {
	userID, _ := c.Get("user_id")
	status := c.Query("status")

	now := time.Now()
	startOfDay := time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, now.Location())
	endOfDay := startOfDay.Add(24 * time.Hour)

	query := h.DB.Where("user_id = ? AND planned_time >= ? AND planned_time < ?", userID, startOfDay, endOfDay)
	if status != "" {
		query = query.Where("status = ?", status)
	}

	var agendas []models.Agenda
	if err := query.Order("planned_time ASC").Find(&agendas).Error; err != nil {
		h.Logger.Error("failed to get today agendas", zap.Error(err))
		c.JSON(http.StatusInternalServerError, Error(50001, "查询失败"))
		return
	}

	c.JSON(http.StatusOK, Success(gin.H{
		"items": agendas,
		"date":  now.Format("2006-01-02"),
	}))
}

// GetAgendaDetail 获取事程详情
func (h *AgendaHandler) GetAgendaDetail(c *gin.Context) {
	agendaID := c.Param("id")
	userID, _ := c.Get("user_id")

	var agenda models.Agenda
	if err := h.DB.Where("id = ? AND user_id = ?", agendaID, userID).First(&agenda).Error; err != nil {
		c.JSON(http.StatusNotFound, Error(40401, "事程不存在"))
		return
	}

	c.JSON(http.StatusOK, Success(agenda))
}

// UpdateAgenda 更新事程
func (h *AgendaHandler) UpdateAgenda(c *gin.Context) {
	agendaID := c.Param("id")
	userID, _ := c.Get("user_id")
	var req CreateAgendaRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, Error(40001, "参数错误："+err.Error()))
		return
	}

	updates := map[string]interface{}{
		"planned_time":   req.PlannedTime,
		"content":        req.Content,
		"behavior_tag":   req.BehaviorTag,
		"remind_offset":  req.RemindOffset,
		"remind_level":   req.RemindLevel,
		"is_recurring":   req.IsRecurring,
		"recurring_rule": req.RecurringRule,
	}

	if err := h.DB.Model(&models.Agenda{}).Where("id = ? AND user_id = ?", agendaID, userID).Updates(updates).Error; err != nil {
		h.Logger.Error("failed to update agenda", zap.Error(err))
		c.JSON(http.StatusInternalServerError, Error(50001, "更新失败"))
		return
	}

	c.JSON(http.StatusOK, Success(gin.H{"message": "更新成功"}))
}

// ConfirmAgenda 确认事程完成
func (h *AgendaHandler) ConfirmAgenda(c *gin.Context) {
	agendaID := c.Param("id")
	userID, _ := c.Get("user_id")

	if err := h.DB.Model(&models.Agenda{}).Where("id = ? AND user_id = ?", agendaID, userID).
		Update("status", "completed").Error; err != nil {
		h.Logger.Error("failed to confirm agenda", zap.Error(err))
		c.JSON(http.StatusInternalServerError, Error(50001, "确认失败"))
		return
	}

	c.JSON(http.StatusOK, Success(gin.H{"message": "事程已确认完成"}))
}

// SnoozeAgenda 延后事程
func (h *AgendaHandler) SnoozeAgenda(c *gin.Context) {
	agendaID := c.Param("id")
	userID, _ := c.Get("user_id")

	type SnoozeRequest struct {
		Minutes int `json:"minutes" binding:"required,min=1"`
	}
	var req SnoozeRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, Error(40001, "参数错误："+err.Error()))
		return
	}

	var agenda models.Agenda
	if err := h.DB.Where("id = ? AND user_id = ?", agendaID, userID).First(&agenda).Error; err != nil {
		c.JSON(http.StatusNotFound, Error(40401, "事程不存在"))
		return
	}

	newTime := agenda.PlannedTime.Add(time.Duration(req.Minutes) * time.Minute)
	if err := h.DB.Model(&agenda).Update("planned_time", newTime).Error; err != nil {
		h.Logger.Error("failed to snooze agenda", zap.Error(err))
		c.JSON(http.StatusInternalServerError, Error(50001, "延后失败"))
		return
	}

	c.JSON(http.StatusOK, Success(gin.H{
		"message":      "事程已延后",
		"new_time":     newTime,
		"snooze_count": 1,
	}))
}

// SkipAgenda 跳过事程
func (h *AgendaHandler) SkipAgenda(c *gin.Context) {
	agendaID := c.Param("id")
	userID, _ := c.Get("user_id")

	if err := h.DB.Model(&models.Agenda{}).Where("id = ? AND user_id = ?", agendaID, userID).
		Update("status", "skipped").Error; err != nil {
		h.Logger.Error("failed to skip agenda", zap.Error(err))
		c.JSON(http.StatusInternalServerError, Error(50001, "跳过失败"))
		return
	}

	c.JSON(http.StatusOK, Success(gin.H{"message": "事程已跳过"}))
}

// DeleteAgenda 删除事程
func (h *AgendaHandler) DeleteAgenda(c *gin.Context) {
	agendaID := c.Param("id")
	userID, _ := c.Get("user_id")

	if err := h.DB.Where("id = ? AND user_id = ?", agendaID, userID).Delete(&models.Agenda{}).Error; err != nil {
		h.Logger.Error("failed to delete agenda", zap.Error(err))
		c.JSON(http.StatusInternalServerError, Error(50001, "删除失败"))
		return
	}

	c.JSON(http.StatusOK, Success(gin.H{"message": "事程已删除"}))
}

// VoiceCreateAgenda 语音创建事程
func (h *AgendaHandler) VoiceCreateAgenda(c *gin.Context) {
	userID, _ := c.Get("user_id")

	file, err := c.FormFile("voice_file")
	if err != nil {
		c.JSON(http.StatusBadRequest, Error(40001, "请上传语音文件"))
		return
	}

	uploadDir := "./uploads/voice"
	if err := ensureDir(uploadDir); err != nil {
		h.Logger.Error("failed to create upload dir", zap.Error(err))
		c.JSON(http.StatusInternalServerError, Error(50001, "文件保存失败"))
		return
	}

	fileName := fmt.Sprintf("%s_agenda_%d.wav", userID.(string), time.Now().UnixNano())
	filePath := fmt.Sprintf("%s/%s", uploadDir, fileName)
	if err := c.SaveUploadedFile(file, filePath); err != nil {
		h.Logger.Error("failed to save voice file", zap.Error(err))
		c.JSON(http.StatusInternalServerError, Error(50001, "文件保存失败"))
		return
	}

	mockText := extractMockTextFromFilename(file.Filename)
	asrText := mockText
	if asrText == "" {
		asrText = "提醒我做事"
	}

	nlpResult := nlp.Parse(asrText)

	plannedTime := time.Now().Add(1 * time.Hour)
	if nlpResult.Time != nil {
		plannedTime = *nlpResult.Time
	}

	voiceFileURL := "/uploads/voice/" + fileName
	agenda := models.Agenda{
		UserID:      userID.(string),
		PlannedTime: plannedTime,
		Content:     asrText,
		BehaviorTag: nlpResult.BehaviorTag,
		Source:      "voice",
		Status:      "pending",
	}
	_ = voiceFileURL

	if err := h.DB.Create(&agenda).Error; err != nil {
		h.Logger.Error("failed to create agenda", zap.Error(err))
		c.JSON(http.StatusInternalServerError, Error(50001, "创建事程失败"))
		return
	}

	c.JSON(http.StatusOK, Success(gin.H{
		"agenda":    agenda,
		"nlp_result": nlpResult,
	}))
}

// GetBehaviorTags 获取行为标签列表
func GetBehaviorTags(c *gin.Context) {
	tags := nlp.GetBehaviorTagList()
	c.JSON(http.StatusOK, Success(gin.H{"items": tags}))
}
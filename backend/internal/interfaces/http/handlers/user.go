package handlers

import (
	"net/http"

	"github.com/dailyawareness/backend/internal/domain/models"
	"github.com/gin-gonic/gin"
	"go.uber.org/zap"
)

// UserHandler 用户处理器
type UserHandler struct {
	*Handler
}

// NewUserHandler 创建用户处理器
func NewUserHandler(h *Handler) *UserHandler {
	return &UserHandler{Handler: h}
}

// UpdateProfileRequest 更新资料请求
type UpdateProfileRequest struct {
	Nickname string `json:"nickname"`
	AvatarURL string `json:"avatar_url"`
}

// UpdateSettingsRequest 更新设置请求
type UpdateSettingsRequest struct {
	DefaultReminderLevel string `json:"default_reminder_level"`
	DefaultRemindOffset  int    `json:"default_remind_offset"`
	QuietHoursStart      string `json:"quiet_hours_start"`
	QuietHoursEnd        string `json:"quiet_hours_end"`
}

// GetProfile 获取用户资料
func (h *UserHandler) GetProfile(c *gin.Context) {
	userID, _ := c.Get("user_id")

	var user models.User
	if err := h.DB.First(&user, "id = ?", userID).Error; err != nil {
		c.JSON(http.StatusNotFound, Error(40401, "用户不存在"))
		return
	}

	c.JSON(http.StatusOK, Success(gin.H{
		"id":                     user.ID,
		"phone":                  user.Phone,
		"nickname":               user.Nickname,
		"avatar_url":             user.AvatarURL,
		"default_reminder_level": user.DefaultReminderLevel,
		"default_remind_offset":  user.DefaultRemindOffset,
		"quiet_hours_start":      user.QuietHoursStart,
		"quiet_hours_end":        user.QuietHoursEnd,
		"created_at":             user.CreatedAt,
	}))
}

// UpdateProfile 更新用户资料
func (h *UserHandler) UpdateProfile(c *gin.Context) {
	userID, _ := c.Get("user_id")
	var req UpdateProfileRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, Error(40001, "参数错误："+err.Error()))
		return
	}

	updates := map[string]interface{}{}
	if req.Nickname != "" {
		updates["nickname"] = req.Nickname
	}
	if req.AvatarURL != "" {
		updates["avatar_url"] = req.AvatarURL
	}

	if err := h.DB.Model(&models.User{}).Where("id = ?", userID).Updates(updates).Error; err != nil {
		h.Logger.Error("failed to update profile", zap.Error(err))
		c.JSON(http.StatusInternalServerError, Error(50001, "更新失败"))
		return
	}

	c.JSON(http.StatusOK, Success(gin.H{"message": "更新成功"}))
}

// GetSettings 获取用户设置
func (h *UserHandler) GetSettings(c *gin.Context) {
	userID, _ := c.Get("user_id")

	var user models.User
	if err := h.DB.First(&user, "id = ?", userID).Error; err != nil {
		c.JSON(http.StatusNotFound, Error(40401, "用户不存在"))
		return
	}

	c.JSON(http.StatusOK, Success(gin.H{
		"default_reminder_level": user.DefaultReminderLevel,
		"default_remind_offset":  user.DefaultRemindOffset,
		"quiet_hours_start":      user.QuietHoursStart,
		"quiet_hours_end":        user.QuietHoursEnd,
	}))
}

// UpdateSettings 更新用户设置
func (h *UserHandler) UpdateSettings(c *gin.Context) {
	userID, _ := c.Get("user_id")
	var req UpdateSettingsRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, Error(40001, "参数错误："+err.Error()))
		return
	}

	updates := map[string]interface{}{}
	if req.DefaultReminderLevel != "" {
		updates["default_reminder_level"] = req.DefaultReminderLevel
	}
	if req.DefaultRemindOffset > 0 {
		updates["default_remind_offset"] = req.DefaultRemindOffset
	}
	if req.QuietHoursStart != "" {
		updates["quiet_hours_start"] = req.QuietHoursStart
	}
	if req.QuietHoursEnd != "" {
		updates["quiet_hours_end"] = req.QuietHoursEnd
	}

	if err := h.DB.Model(&models.User{}).Where("id = ?", userID).Updates(updates).Error; err != nil {
		h.Logger.Error("failed to update settings", zap.Error(err))
		c.JSON(http.StatusInternalServerError, Error(50001, "更新失败"))
		return
	}

	c.JSON(http.StatusOK, Success(gin.H{"message": "设置更新成功"}))
}
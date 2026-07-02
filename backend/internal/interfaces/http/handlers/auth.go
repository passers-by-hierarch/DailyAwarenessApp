package handlers

import (
	"net/http"

	"github.com/dailyawareness/backend/internal/domain/models"
	"github.com/dailyawareness/backend/internal/interfaces/http/middleware"
	"github.com/gin-gonic/gin"
	"go.uber.org/zap"
	"golang.org/x/crypto/bcrypt"
)

// AuthHandler 认证处理器
type AuthHandler struct {
	*Handler
}

// NewAuthHandler 创建认证处理器
func NewAuthHandler(h *Handler) *AuthHandler {
	return &AuthHandler{Handler: h}
}

// RegisterRequest 注册请求
type RegisterRequest struct {
	Phone    string `json:"phone" binding:"required,len=11"`
	Password string `json:"password" binding:"required,min=6"`
	Code     string `json:"code" binding:"required,len=6"`
}

// LoginRequest 登录请求
type LoginRequest struct {
	Phone    string `json:"phone" binding:"required,len=11"`
	Password string `json:"password" binding:"required"`
}

// SendCodeRequest 发送验证码请求
type SendCodeRequest struct {
	Phone string `json:"phone" binding:"required,len=11"`
}

// RefreshRequest 刷新令牌请求
type RefreshRequest struct {
	RefreshToken string `json:"refresh_token" binding:"required"`
}

// TokenResult 令牌结果
type TokenResult struct {
	AccessToken  string `json:"access_token"`
	RefreshToken string `json:"refresh_token"`
	ExpiresIn    int    `json:"expires_in"`
}

// Register 用户注册
func (h *AuthHandler) Register(c *gin.Context) {
	var req RegisterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, Error(40001, "参数错误："+err.Error()))
		return
	}

	// TODO: 验证验证码

	// 检查用户是否已存在
	var existingUser models.User
	if err := h.DB.Where("phone = ?", req.Phone).First(&existingUser).Error; err == nil {
		c.JSON(http.StatusConflict, Error(40901, "手机号已注册"))
		return
	}

	// 密码哈希
	hash, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		h.Logger.Error("failed to hash password", zap.Error(err))
		c.JSON(http.StatusInternalServerError, Error(50001, "内部错误"))
		return
	}

	// 创建用户
	user := models.User{
		Phone:        req.Phone,
		PasswordHash: string(hash),
	}

	if err := h.DB.Create(&user).Error; err != nil {
		h.Logger.Error("failed to create user", zap.Error(err))
		c.JSON(http.StatusInternalServerError, Error(50001, "注册失败"))
		return
	}

	// 生成令牌
	token, err := middleware.GenerateToken(user.ID, h.Config)
	if err != nil {
		h.Logger.Error("failed to generate token", zap.Error(err))
		c.JSON(http.StatusInternalServerError, Error(50001, "令牌生成失败"))
		return
	}

	c.JSON(http.StatusOK, Success(gin.H{
		"user_id": user.ID,
		"token":   token,
	}))
}

// Login 用户登录
func (h *AuthHandler) Login(c *gin.Context) {
	var req LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, Error(40001, "参数错误："+err.Error()))
		return
	}

	// 查找用户
	var user models.User
	if err := h.DB.Where("phone = ?", req.Phone).First(&user).Error; err != nil {
		c.JSON(http.StatusUnauthorized, Error(40101, "手机号或密码错误"))
		return
	}

	// 验证密码
	if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(req.Password)); err != nil {
		c.JSON(http.StatusUnauthorized, Error(40101, "手机号或密码错误"))
		return
	}

	// 生成令牌
	token, err := middleware.GenerateToken(user.ID, h.Config)
	if err != nil {
		h.Logger.Error("failed to generate token", zap.Error(err))
		c.JSON(http.StatusInternalServerError, Error(50001, "令牌生成失败"))
		return
	}

	c.JSON(http.StatusOK, Success(TokenResult{
		AccessToken:  token,
		RefreshToken: "", // TODO: 实现refresh token
		ExpiresIn:    h.Config.JWT.ExpiresIn * 3600,
	}))
}

// SendCode 发送验证码
func (h *AuthHandler) SendCode(c *gin.Context) {
	var req SendCodeRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, Error(40001, "参数错误："+err.Error()))
		return
	}

	// TODO: 集成短信服务发送验证码
	// 当前返回模拟验证码
	c.JSON(http.StatusOK, Success(gin.H{
		"message": "验证码已发送",
		"code":    "123456", // 仅开发环境返回
	}))
}

// RefreshToken 刷新令牌
func (h *AuthHandler) RefreshToken(c *gin.Context) {
	var req RefreshRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, Error(40001, "参数错误："+err.Error()))
		return
	}

	// TODO: 实现refresh token逻辑
	c.JSON(http.StatusOK, Success(TokenResult{
		AccessToken:  "",
		RefreshToken: "",
		ExpiresIn:    h.Config.JWT.ExpiresIn * 3600,
	}))
}
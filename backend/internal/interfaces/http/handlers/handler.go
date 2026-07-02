package handlers

import (
	"time"

	"github.com/dailyawareness/backend/internal/config"
	"github.com/dailyawareness/backend/internal/infrastructure/persistence/redis"
	"go.uber.org/zap"
	"gorm.io/gorm"
)

// Handler 统一处理器
type Handler struct {
	DB               *gorm.DB
	Redis            *redis.Client
	Logger           *zap.Logger
	Config           *config.Config
	AuthHandler      *AuthHandler
	UserHandler      *UserHandler
	TimelineHandler  *TimelineHandler
	AgendaHandler    *AgendaHandler
	MatchHandler     *MatchHandler
	ReminderHandler  *ReminderHandler
	AnalyticsHandler *AnalyticsHandler
	QaHandler        *QaHandler
}

// NewHandler 创建处理器
func NewHandler(db *gorm.DB, redis *redis.Client, logger *zap.Logger, cfg *config.Config) *Handler {
	h := &Handler{
		DB:     db,
		Redis:  redis,
		Logger: logger,
		Config: cfg,
	}

	h.AuthHandler = NewAuthHandler(h)
	h.UserHandler = NewUserHandler(h)
	h.TimelineHandler = NewTimelineHandler(h)
	h.AgendaHandler = NewAgendaHandler(h)
	h.MatchHandler = NewMatchHandler(h)
	h.ReminderHandler = NewReminderHandler(h)
	h.AnalyticsHandler = NewAnalyticsHandler(h)
	h.QaHandler = NewQaHandler(h)

	return h
}

// Response 统一响应
type Response struct {
	Code      int         `json:"code"`
	Message   string      `json:"message"`
	Data      interface{} `json:"data,omitempty"`
	Timestamp int64       `json:"timestamp"`
}

// Success 成功响应
func Success(data interface{}) Response {
	return Response{
		Code:      200,
		Message:   "success",
		Data:      data,
		Timestamp: timeNow(),
	}
}

// Error 错误响应
func Error(code int, message string) Response {
	return Response{
		Code:      code,
		Message:   message,
		Timestamp: timeNow(),
	}
}

func timeNow() int64 {
	return time.Now().Unix()
}

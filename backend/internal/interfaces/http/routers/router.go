package routers

import (
	"github.com/dailyawareness/backend/internal/config"
	"github.com/dailyawareness/backend/internal/interfaces/http/handlers"
	"github.com/dailyawareness/backend/internal/interfaces/http/middleware"
	"github.com/gin-gonic/gin"
)

// RegisterRoutes 注册所有路由
func RegisterRoutes(r *gin.Engine, h *handlers.Handler, cfg *config.Config) {
	// 健康检查
	r.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{"status": "ok"})
	})

	// API v1
	api := r.Group("/api/v1")
	{
		// 认证（无需登录）
		auth := api.Group("/auth")
		{
			auth.POST("/register", h.AuthHandler.Register)
			auth.POST("/login", h.AuthHandler.Login)
			auth.POST("/send-code", h.AuthHandler.SendCode)
			auth.POST("/refresh", h.AuthHandler.RefreshToken)
		}

		// 需要认证的路由
		authorized := api.Group("/")
		authorized.Use(middleware.JWTAuth(cfg))
		{
			// 用户
			users := authorized.Group("/users")
			{
				users.GET("/profile", h.UserHandler.GetProfile)
				users.PUT("/profile", h.UserHandler.UpdateProfile)
				users.GET("/settings", h.UserHandler.GetSettings)
				users.PUT("/settings", h.UserHandler.UpdateSettings)
			}

			// 时间线
			timeline := authorized.Group("/timeline")
			{
				timeline.POST("", h.TimelineHandler.CreateTimeline)
				timeline.POST("/voice", h.TimelineHandler.UploadVoiceTimeline)
				timeline.GET("/today", h.TimelineHandler.GetTodayTimeline)
				timeline.GET("/history", h.TimelineHandler.GetHistoryTimeline)
				timeline.PUT("/:id", h.TimelineHandler.UpdateTimeline)
				timeline.DELETE("/:id", h.TimelineHandler.DeleteTimeline)
			}

			// 事程
			agendas := authorized.Group("/agendas")
			{
				agendas.POST("", h.AgendaHandler.CreateAgenda)
				agendas.POST("/voice", h.AgendaHandler.VoiceCreateAgenda)
				agendas.GET("/today", h.AgendaHandler.GetTodayAgendas)
				agendas.GET("/:id", h.AgendaHandler.GetAgendaDetail)
				agendas.PUT("/:id", h.AgendaHandler.UpdateAgenda)
				agendas.POST("/:id/confirm", h.AgendaHandler.ConfirmAgenda)
				agendas.POST("/:id/snooze", h.AgendaHandler.SnoozeAgenda)
				agendas.POST("/:id/skip", h.AgendaHandler.SkipAgenda)
				agendas.DELETE("/:id", h.AgendaHandler.DeleteAgenda)
			}

			// 行为标签
			authorized.GET("/behavior-tags", handlers.GetBehaviorTags)

			// 匹配引擎
			match := authorized.Group("/match")
			{
				match.POST("/manual", h.MatchHandler.ManualMatch)
				match.POST("/cancel", h.MatchHandler.CancelMatch)
				match.GET("/pending", h.MatchHandler.GetPendingAgendas)
				match.GET("/auto", h.MatchHandler.AutoMatch)
			}

			// 提醒规则
			reminderRules := authorized.Group("/reminder-rules")
			{
				reminderRules.GET("/default", h.ReminderHandler.GetDefaultRule)
				reminderRules.PUT("/default", h.ReminderHandler.UpdateDefaultRule)
			}

			// 事程提醒规则
			authorized.GET("/agendas/:id/reminder-rule", h.ReminderHandler.GetAgendaRule)
			authorized.PUT("/agendas/:id/reminder-rule", h.ReminderHandler.UpdateAgendaRule)
			authorized.POST("/agendas/:id/trigger-reminder", h.ReminderHandler.TriggerReminder)

			// 升级策略
			escalating := authorized.Group("/escalating-strategies")
			{
				escalating.GET("", h.ReminderHandler.GetEscalatingStrategies)
				escalating.POST("", h.ReminderHandler.CreateEscalatingStrategy)
			}

			// 分析
			analytics := authorized.Group("/analytics")
			{
				analytics.GET("/frequency", h.AnalyticsHandler.GetFrequencyAnalysis)
				analytics.GET("/match-rate", h.AnalyticsHandler.GetMatchRateAnalysis)
				analytics.GET("/anomalies", h.AnalyticsHandler.GetAnomalies)
				analytics.GET("/optimization-suggestions", h.AnalyticsHandler.GetOptimizationSuggestions)
			}

			// 问答（P2阶段）
			qa := authorized.Group("/qa")
			{
				qa.POST("/ask", h.QaHandler.AskQuestion)
				qa.GET("/history", h.QaHandler.GetHistory)
				qa.GET("/sessions", h.QaHandler.GetSessions)
				qa.POST("/sessions/:session_id/end", h.QaHandler.EndSession)
			}
		}
	}
}

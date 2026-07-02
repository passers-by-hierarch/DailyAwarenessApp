package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/dailyawareness/backend/internal/config"
	"github.com/dailyawareness/backend/internal/infrastructure/persistence/postgres"
	"github.com/dailyawareness/backend/internal/infrastructure/persistence/redis"
	"github.com/dailyawareness/backend/internal/interfaces/http/handlers"
	"github.com/dailyawareness/backend/internal/interfaces/http/middleware"
	"github.com/dailyawareness/backend/internal/interfaces/http/routers"
	"github.com/gin-gonic/gin"
	"go.uber.org/zap"
)

func main() {
	// 加载配置
	cfg, err := config.Load()
	if err != nil {
		log.Fatalf("failed to load config: %v", err)
	}

	// 初始化日志
	logger := initLogger(cfg.LogLevel)
	defer logger.Sync()

	// 初始化数据库
	db, err := postgres.NewConnection(cfg.Database)
	if err != nil {
		logger.Fatal("failed to connect database", zap.Error(err))
	}

	// 自动迁移
	if err := postgres.AutoMigrate(db); err != nil {
		logger.Fatal("failed to migrate database", zap.Error(err))
	}

	// 初始化Redis（可选）
	var redisClient *redis.Client
	redisClient, err = redis.NewClient(cfg.Redis)
	if err != nil {
		logger.Warn("failed to connect redis, some features may be limited", zap.Error(err))
		redisClient = nil
	} else {
		defer redisClient.Close()
	}

	// 设置Gin模式
	if cfg.Environment == "production" {
		gin.SetMode(gin.ReleaseMode)
	}

	// 创建Gin引擎
	r := gin.New()
	r.Use(gin.Recovery())
	r.Use(middleware.Logger(logger))
	r.Use(middleware.CORS())

	// 初始化handler
	h := handlers.NewHandler(db, redisClient, logger, cfg)

	// 注册路由
	routers.RegisterRoutes(r, h, cfg)

	// 创建HTTP服务器
	srv := &http.Server{
		Addr:    ":" + cfg.Port,
		Handler: r,
	}

	// 启动服务器（非阻塞）
	go func() {
		logger.Info("server starting", zap.String("port", cfg.Port))
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			logger.Fatal("server failed to start", zap.Error(err))
		}
	}()

	// 等待中断信号
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	logger.Info("server shutting down...")

	// 优雅关闭
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := srv.Shutdown(ctx); err != nil {
		logger.Fatal("server forced to shutdown", zap.Error(err))
	}

	logger.Info("server exited")
}

func initLogger(level string) *zap.Logger {
	cfg := zap.NewProductionConfig()
	switch level {
	case "debug":
		cfg.Level = zap.NewAtomicLevelAt(zap.DebugLevel)
	case "info":
		cfg.Level = zap.NewAtomicLevelAt(zap.InfoLevel)
	case "warn":
		cfg.Level = zap.NewAtomicLevelAt(zap.WarnLevel)
	case "error":
		cfg.Level = zap.NewAtomicLevelAt(zap.ErrorLevel)
	}
	logger, _ := cfg.Build()
	return logger
}

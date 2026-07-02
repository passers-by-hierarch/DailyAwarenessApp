package postgres

import (
	"fmt"

	"github.com/dailyawareness/backend/internal/config"
	"github.com/dailyawareness/backend/internal/domain/models"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

// NewConnection 创建数据库连接
func NewConnection(cfg config.DatabaseConfig) (*gorm.DB, error) {
	db, err := gorm.Open(postgres.Open(cfg.DSN()), &gorm.Config{
		Logger: logger.Default.LogMode(logger.Info),
	})
	if err != nil {
		return nil, fmt.Errorf("failed to connect to database: %w", err)
	}

	return db, nil
}

// AutoMigrate 自动迁移数据库表
func AutoMigrate(db *gorm.DB) error {
	return db.AutoMigrate(
		&models.User{},
		&models.FamilyBinding{},
		&models.TimelineRecord{},
		&models.Agenda{},
		&models.ReminderRule{},
		&models.EscalatingStrategy{},
		&models.BehaviorTag{},
		&models.MatchResult{},
		&models.AnalyticsReport{},
		&models.ReminderHistory{},
		&models.ItemRecord{},
		&models.KnowledgeEntry{},
		&models.QaSession{},
		&models.QaHistory{},
	)
}
package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// MatchResult 匹配结果记录
type MatchResult struct {
	ID           string    `json:"id" gorm:"type:uuid;primary_key;default:gen_random_uuid()"`
	TimelineID   string    `json:"timeline_id" gorm:"type:uuid;not null;index"`
	AgendaID     string    `json:"agenda_id" gorm:"type:uuid;not null;index"`
	MatchScore   float64   `json:"match_score" gorm:"not null"`
	MatchReason  string    `json:"match_reason" gorm:"type:text"`
	Status       string    `json:"status" gorm:"type:varchar(20);default:'auto_matched'"` // auto_matched/user_confirmed/user_rejected
	CreatedAt    time.Time `json:"created_at" gorm:"autoCreateTime"`

	// 关联
	TimelineRecord TimelineRecord `json:"timeline_record,omitempty" gorm:"foreignKey:TimelineID"`
	Agenda         Agenda         `json:"agenda,omitempty" gorm:"foreignKey:AgendaID"`
}

// TableName 表名
func (MatchResult) TableName() string {
	return "match_results"
}

// BeforeCreate 创建前钩子
func (m *MatchResult) BeforeCreate(tx *gorm.DB) error {
	if m.ID == "" {
		m.ID = uuid.New().String()
	}
	return nil
}

// BehaviorTag 行为标签库
type BehaviorTag struct {
	ID              string    `json:"id" gorm:"type:uuid;primary_key;default:gen_random_uuid()"`
	TagName         string    `json:"tag_name" gorm:"type:varchar(50);not null;uniqueIndex"`
	Category        string    `json:"category" gorm:"type:varchar(50);not null;index"` // health/work/life/entertainment
	DefaultTimeRange *string  `json:"default_time_range" gorm:"type:varchar(20)"`
	Keywords        []string  `json:"keywords" gorm:"-"`
	KeywordsStr     string    `json:"-" gorm:"column:keywords;type:varchar(500)"`
	CreatedAt       time.Time `json:"created_at" gorm:"autoCreateTime"`
}

// TableName 表名
func (BehaviorTag) TableName() string {
	return "behavior_tags"
}

// BeforeCreate 创建前钩子
func (b *BehaviorTag) BeforeCreate(tx *gorm.DB) error {
	if b.ID == "" {
		b.ID = uuid.New().String()
	}
	return nil
}

// AnalyticsReport 分析报告
type AnalyticsReport struct {
	ID        string    `json:"id" gorm:"type:uuid;primary_key;default:gen_random_uuid()"`
	UserID    string    `json:"user_id" gorm:"type:uuid;not null;index"`
	Period    string    `json:"period" gorm:"type:varchar(20);not null;index"` // daily/weekly/monthly
	StartDate time.Time `json:"start_date" gorm:"not null"`
	EndDate   time.Time `json:"end_date" gorm:"not null"`
	Insights  string    `json:"insights" gorm:"type:jsonb"`
	CreatedAt time.Time `json:"created_at" gorm:"autoCreateTime"`

	// 关联
	User User `json:"user,omitempty" gorm:"foreignKey:UserID"`
}

// TableName 表名
func (AnalyticsReport) TableName() string {
	return "analytics_reports"
}

// BeforeCreate 创建前钩子
func (a *AnalyticsReport) BeforeCreate(tx *gorm.DB) error {
	if a.ID == "" {
		a.ID = uuid.New().String()
	}
	return nil
}
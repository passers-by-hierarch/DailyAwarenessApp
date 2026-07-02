package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// ReminderRule 提醒规则配置
type ReminderRule struct {
	ID           string    `json:"id" gorm:"type:uuid;primary_key;default:gen_random_uuid()"`
	AgendaID     string    `json:"agenda_id" gorm:"type:uuid;not null;index"`
	Level        string    `json:"level" gorm:"type:varchar(20);not null"` // gentle/standard/strong
	Methods      []string  `json:"methods" gorm:"-"` // notification/sound/vibration/popup/voice
	MethodsStr   string    `json:"-" gorm:"column:methods;type:varchar(100)"`
	Stages       []string  `json:"stages" gorm:"-"` // pre_remind/first_remind/second_remind/final_remind
	StagesStr    string    `json:"-" gorm:"column:stages;type:varchar(100)"`
	IntervalSec  int       `json:"interval_sec" gorm:"default:300"` // 提醒间隔秒数
	MaxReminders int       `json:"max_reminders" gorm:"default:3"`
	AllowSnooze  bool      `json:"allow_snooze" gorm:"default:true"`
	AllowSkip    bool      `json:"allow_skip" gorm:"default:true"`
	CreatedAt    time.Time `json:"created_at" gorm:"autoCreateTime"`
	UpdatedAt    time.Time `json:"updated_at" gorm:"autoUpdateTime"`

	// 关联
	Agenda Agenda `json:"agenda,omitempty" gorm:"foreignKey:AgendaID"`
}

// TableName 表名
func (ReminderRule) TableName() string {
	return "reminder_rules"
}

// BeforeCreate 创建前钩子
func (r *ReminderRule) BeforeCreate(tx *gorm.DB) error {
	if r.ID == "" {
		r.ID = uuid.New().String()
	}
	return nil
}

// EscalatingStrategy 强提醒升级策略
type EscalatingStrategy struct {
	ID           string    `json:"id" gorm:"type:uuid;primary_key;default:gen_random_uuid()"`
	UserID       string    `json:"user_id" gorm:"type:uuid;not null;index"`
	Name         string    `json:"name" gorm:"type:varchar(50);not null"`
	StagesConfig string    `json:"stages_config" gorm:"type:jsonb;not null"`
	IsDefault    bool      `json:"is_default" gorm:"default:false"`
	CreatedAt    time.Time `json:"created_at" gorm:"autoCreateTime"`
	UpdatedAt    time.Time `json:"updated_at" gorm:"autoUpdateTime"`
}

// TableName 表名
func (EscalatingStrategy) TableName() string {
	return "escalating_strategies"
}

// BeforeCreate 创建前钩子
func (e *EscalatingStrategy) BeforeCreate(tx *gorm.DB) error {
	if e.ID == "" {
		e.ID = uuid.New().String()
	}
	return nil
}

// ReminderHistory 提醒历史记录
type ReminderHistory struct {
	ID                string    `json:"id" gorm:"type:uuid;primary_key;default:gen_random_uuid()"`
	UserID            string    `json:"user_id" gorm:"type:uuid;not null;index"`
	AgendaID          string    `json:"agenda_id" gorm:"type:uuid;not null;index"`
	RemindStage       string    `json:"remind_stage" gorm:"type:varchar(50);not null"` // pre_remind/first_remind/second_remind等
	RemindTime        time.Time `json:"remind_time" gorm:"not null"`
	PlannedTime       time.Time `json:"planned_time" gorm:"not null"`
	MethodsUsed       []string  `json:"methods_used" gorm:"-"`
	MethodsUsedStr    string    `json:"-" gorm:"column:methods_used;type:varchar(100)"`
	UserResponse      *string   `json:"user_response" gorm:"type:varchar(20)"` // confirmed/snoozed/skipped/ignored
	ResponseTime      *time.Time `json:"response_time"`
	ResponseDelaySec  *int       `json:"response_delay_seconds"`
	Result            string     `json:"result" gorm:"type:varchar(20);not null"` // success/timeout/failed
	CreatedAt         time.Time  `json:"created_at" gorm:"autoCreateTime"`

	// 关联
	User   User   `json:"user,omitempty" gorm:"foreignKey:UserID"`
	Agenda Agenda `json:"agenda,omitempty" gorm:"foreignKey:AgendaID"`
}

// TableName 表名
func (ReminderHistory) TableName() string {
	return "reminder_history"
}

// BeforeCreate 创建前钩子
func (r *ReminderHistory) BeforeCreate(tx *gorm.DB) error {
	if r.ID == "" {
		r.ID = uuid.New().String()
	}
	return nil
}
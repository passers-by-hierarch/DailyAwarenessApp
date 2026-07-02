package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// TimelineRecord 时间线记录
type TimelineRecord struct {
	ID              string     `json:"id" gorm:"type:uuid;primary_key;default:gen_random_uuid()"`
	UserID          string     `json:"user_id" gorm:"type:uuid;not null;index"`
	Timestamp       time.Time  `json:"timestamp" gorm:"not null;index"`
	Content         string     `json:"content" gorm:"type:text;not null"`
	BehaviorTag     *string    `json:"behavior_tag" gorm:"type:varchar(50);index"`
	VoiceFileURL    *string    `json:"voice_file_url" gorm:"type:varchar(500)"`
	VoiceDuration   *int       `json:"voice_duration"`
	MatchedAgendaID *string    `json:"matched_agenda_id" gorm:"type:uuid;index"`
	MatchScore      *float64   `json:"match_score"`
	Source          string     `json:"source" gorm:"type:varchar(20);default:'voice'"` // voice/manual
	CreatedAt       time.Time  `json:"created_at" gorm:"autoCreateTime"`
	UpdatedAt       time.Time  `json:"updated_at" gorm:"autoUpdateTime"`
	DeletedAt       gorm.DeletedAt `json:"-" gorm:"index"`

	// 关联
	User    User    `json:"user,omitempty" gorm:"foreignKey:UserID"`
	Agenda  *Agenda `json:"agenda,omitempty" gorm:"foreignKey:MatchedAgendaID"`
}

// TableName 表名
func (TimelineRecord) TableName() string {
	return "timeline_records"
}

// BeforeCreate 创建前钩子
func (t *TimelineRecord) BeforeCreate(tx *gorm.DB) error {
	if t.ID == "" {
		t.ID = uuid.New().String()
	}
	return nil
}

// Agenda 计划事程
type Agenda struct {
	ID               string     `json:"id" gorm:"type:uuid;primary_key;default:gen_random_uuid()"`
	UserID           string     `json:"user_id" gorm:"type:uuid;not null;index"`
	PlannedTime      time.Time  `json:"planned_time" gorm:"not null;index"`
	Content          string     `json:"content" gorm:"type:text;not null"`
	BehaviorTag      *string    `json:"behavior_tag" gorm:"type:varchar(50);index"`
	AgendaType       string     `json:"agenda_type" gorm:"type:varchar(20);default:'fixed'"` // fixed/floating/inferred
	Status           string     `json:"status" gorm:"type:varchar(20);default:'pending';index"` // pending/completed/skipped/snoozed
	MatchedTimelineID *string   `json:"matched_timeline_id" gorm:"type:uuid;index"`
	MatchedAt        *time.Time `json:"matched_at"`
	RemindOffset     int        `json:"remind_offset" gorm:"default:5"`
	RemindLevel      string     `json:"remind_level" gorm:"type:varchar(20);default:'standard'"` // gentle/standard/strong
	IsRecurring      bool       `json:"is_recurring" gorm:"default:false"`
	RecurringRule    *string    `json:"recurring_rule" gorm:"type:text"`
	Source           string     `json:"source" gorm:"type:varchar(20);default:'manual'"` // manual/auto_extracted
	CreatedAt        time.Time  `json:"created_at" gorm:"autoCreateTime"`
	UpdatedAt        time.Time  `json:"updated_at" gorm:"autoUpdateTime"`
	DeletedAt        gorm.DeletedAt `json:"-" gorm:"index"`

	// 关联
	User            User             `json:"user,omitempty" gorm:"foreignKey:UserID"`
	ReminderRules   []ReminderRule   `json:"reminder_rules,omitempty" gorm:"foreignKey:AgendaID"`
	MatchResults    []MatchResult    `json:"match_results,omitempty" gorm:"foreignKey:AgendaID"`
}

// TableName 表名
func (Agenda) TableName() string {
	return "agendas"
}

// BeforeCreate 创建前钩子
func (a *Agenda) BeforeCreate(tx *gorm.DB) error {
	if a.ID == "" {
		a.ID = uuid.New().String()
	}
	return nil
}
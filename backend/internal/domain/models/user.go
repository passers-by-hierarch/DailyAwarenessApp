package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// User 用户模型
type User struct {
	ID                   string         `json:"id" gorm:"type:uuid;primary_key;default:gen_random_uuid()"`
	Phone                string         `json:"phone" gorm:"type:varchar(20);uniqueIndex;not null"`
	Nickname             *string        `json:"nickname" gorm:"type:varchar(50)"`
	AvatarURL            *string        `json:"avatar_url" gorm:"type:varchar(500)"`
	PasswordHash         string         `json:"-" gorm:"type:varchar(255);not null"`
	DefaultReminderLevel string         `json:"default_reminder_level" gorm:"type:varchar(20);default:'standard'"`
	DefaultRemindOffset  int            `json:"default_remind_offset" gorm:"default:5"`
	QuietHoursStart      string         `json:"quiet_hours_start" gorm:"type:varchar(5);default:'22:00'"`
	QuietHoursEnd        string         `json:"quiet_hours_end" gorm:"type:varchar(5);default:'08:00'"`
	CreatedAt            time.Time      `json:"created_at" gorm:"autoCreateTime"`
	UpdatedAt            time.Time      `json:"updated_at" gorm:"autoUpdateTime"`
	DeletedAt            gorm.DeletedAt `json:"-" gorm:"index"`

	// 关联
	Agendas         []Agenda         `json:"agendas,omitempty" gorm:"foreignKey:UserID"`
	TimelineRecords []TimelineRecord `json:"timeline_records,omitempty" gorm:"foreignKey:UserID"`
}

// TableName 表名
func (User) TableName() string {
	return "users"
}

// BeforeCreate 创建前钩子
func (u *User) BeforeCreate(tx *gorm.DB) error {
	if u.ID == "" {
		u.ID = uuid.New().String()
	}
	return nil
}

// FamilyBinding 家属绑定关系
type FamilyBinding struct {
	ID              string    `json:"id" gorm:"type:uuid;primary_key;default:gen_random_uuid()"`
	UserID          string    `json:"user_id" gorm:"type:uuid;not null;index"`
	FamilyUserID    string    `json:"family_user_id" gorm:"type:uuid;not null;index"`
	PermissionLevel string    `json:"permission_level" gorm:"type:varchar(20);default:'view'"` // view/manage/admin
	Status          string    `json:"status" gorm:"type:varchar(20);default:'pending'"`       // pending/accepted/rejected
	CreatedAt       time.Time `json:"created_at" gorm:"autoCreateTime"`
	UpdatedAt       time.Time `json:"updated_at" gorm:"autoUpdateTime"`

	// 关联
	User       User `json:"user,omitempty" gorm:"foreignKey:UserID"`
	FamilyUser User `json:"family_user,omitempty" gorm:"foreignKey:FamilyUserID"`
}

// TableName 表名
func (FamilyBinding) TableName() string {
	return "family_bindings"
}

// BeforeCreate 创建前钩子
func (fb *FamilyBinding) BeforeCreate(tx *gorm.DB) error {
	if fb.ID == "" {
		fb.ID = uuid.New().String()
	}
	return nil
}
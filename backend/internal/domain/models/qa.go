package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// ItemRecord 物品位置记录
type ItemRecord struct {
	ID                  string    `json:"id" gorm:"type:uuid;primary_key;default:gen_random_uuid()"`
	UserID              string    `json:"user_id" gorm:"type:uuid;not null;index"`
	ItemName            string    `json:"item_name" gorm:"type:varchar(100);not null;index"`
	Location            string    `json:"location" gorm:"type:text;not null"`
	LocationKeywords    []string  `json:"location_keywords" gorm:"-"`
	LocationKeywordsStr string    `json:"-" gorm:"column:location_keywords;type:varchar(200)"`
	RecordedAt          time.Time `json:"recorded_at" gorm:"not null"`
	UpdatedAt           time.Time `json:"updated_at" gorm:"not null"`
	SourceTimelineID    *string   `json:"source_timeline_id" gorm:"type:uuid"`
	EmbeddingID         *string   `json:"embedding_id" gorm:"type:varchar(100)"`
	IsActive            bool      `json:"is_active" gorm:"default:true;index"`
	CreatedAt           time.Time `json:"created_at" gorm:"autoCreateTime"`

	// 关联
	User User `json:"user,omitempty" gorm:"foreignKey:UserID"`
}

// TableName 表名
func (ItemRecord) TableName() string {
	return "item_records"
}

// BeforeCreate 创建前钩子
func (i *ItemRecord) BeforeCreate(tx *gorm.DB) error {
	if i.ID == "" {
		i.ID = uuid.New().String()
	}
	return nil
}

// KnowledgeEntry 知识条目
type KnowledgeEntry struct {
	ID               string     `json:"id" gorm:"type:uuid;primary_key;default:gen_random_uuid()"`
	UserID           string     `json:"user_id" gorm:"type:uuid;not null;index"`
	Category         string     `json:"category" gorm:"type:varchar(50);not null;index"` // document/health/cycle
	Title            string     `json:"title" gorm:"type:varchar(200);not null"`
	Content          *string    `json:"content" gorm:"type:text"`
	Metadata         string     `json:"-" gorm:"type:jsonb"`
	EffectiveDate    *time.Time `json:"effective_date"`
	ExpireDate       *time.Time `json:"expire_date;index"`
	RemindDaysBefore int        `json:"remind_days_before" gorm:"default:30"`
	Source           string     `json:"source" gorm:"type:varchar(20);default:'manual'"` // manual/extracted_from_timeline
	SourceTimelineID *string    `json:"source_timeline_id" gorm:"type:uuid"`
	Status           string     `json:"status" gorm:"type:varchar(20);default:'active'"` // active/expired/reminded
	CreatedAt        time.Time  `json:"created_at" gorm:"autoCreateTime"`
	UpdatedAt        time.Time  `json:"updated_at" gorm:"autoUpdateTime"`

	// 关联
	User User `json:"user,omitempty" gorm:"foreignKey:UserID"`
}

// TableName 表名
func (KnowledgeEntry) TableName() string {
	return "knowledge_entries"
}

// BeforeCreate 创建前钩子
func (k *KnowledgeEntry) BeforeCreate(tx *gorm.DB) error {
	if k.ID == "" {
		k.ID = uuid.New().String()
	}
	return nil
}

// QaSession 问答会话
type QaSession struct {
	ID        string     `json:"id" gorm:"type:uuid;primary_key;default:gen_random_uuid()"`
	UserID    string     `json:"user_id" gorm:"type:uuid;not null;index"`
	StartedAt time.Time  `json:"started_at" gorm:"not null"`
	EndedAt   *time.Time `json:"ended_at"`
	Status    string     `json:"status" gorm:"type:varchar(20);default:'active'"` // active/ended
	Context   string     `json:"-" gorm:"type:jsonb"`
	CreatedAt time.Time  `json:"created_at" gorm:"autoCreateTime"`

	// 关联
	User      User        `json:"user,omitempty" gorm:"foreignKey:UserID"`
	Histories []QaHistory `json:"histories,omitempty" gorm:"foreignKey:SessionID"`
}

// TableName 表名
func (QaSession) TableName() string {
	return "qa_sessions"
}

// BeforeCreate 创建前钩子
func (q *QaSession) BeforeCreate(tx *gorm.DB) error {
	if q.ID == "" {
		q.ID = uuid.New().String()
	}
	return nil
}

// QaHistory 问答历史记录
type QaHistory struct {
	ID             string    `json:"id" gorm:"type:uuid;primary_key;default:gen_random_uuid()"`
	SessionID      string    `json:"session_id" gorm:"type:uuid;not null;index"`
	Question       string    `json:"question" gorm:"type:text;not null"`
	QuestionType   *string   `json:"question_type" gorm:"type:varchar(50)"`
	Answer         string    `json:"answer" gorm:"type:text;not null"`
	AnswerSource   string    `json:"-" gorm:"type:jsonb"`
	ProcessingTime *int      `json:"processing_time"`
	Confidence     *float64  `json:"confidence"`
	CreatedAt      time.Time `json:"created_at" gorm:"autoCreateTime"`

	// 关联
	Session QaSession `json:"session,omitempty" gorm:"foreignKey:SessionID"`
}

// TableName 表名
func (QaHistory) TableName() string {
	return "qa_history"
}

// BeforeCreate 创建前钩子
func (q *QaHistory) BeforeCreate(tx *gorm.DB) error {
	if q.ID == "" {
		q.ID = uuid.New().String()
	}
	return nil
}

// SourceRecord 检索来源记录（用于API响应）
type SourceRecord struct {
	ID             string    `json:"id"`
	Timestamp      time.Time `json:"timestamp"`
	Content        string    `json:"content"`
	RecordType     string    `json:"record_type"` // timeline/item/knowledge/agenda
	RelevanceScore float64   `json:"relevance_score"`
	BehaviorTag    *string   `json:"behavior_tag,omitempty"`
	SourceName     *string   `json:"source_name,omitempty"`
	Metadata       *string   `json:"metadata,omitempty"`
}

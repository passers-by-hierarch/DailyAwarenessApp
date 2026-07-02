package handlers

import (
	"encoding/binary"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/dailyawareness/backend/internal/domain/models"
	"github.com/dailyawareness/backend/internal/services/nlp"
	"github.com/gin-gonic/gin"
	"go.uber.org/zap"
)

// TimelineHandler 时间线处理器
type TimelineHandler struct {
	*Handler
}

// NewTimelineHandler 创建时间线处理器
func NewTimelineHandler(h *Handler) *TimelineHandler {
	return &TimelineHandler{Handler: h}
}

// CreateTimelineRequest 创建时间线记录请求
type CreateTimelineRequest struct {
	Timestamp    time.Time `json:"timestamp" binding:"required"`
	Content      string    `json:"content" binding:"required"`
	BehaviorTag  *string   `json:"behavior_tag"`
	VoiceFileURL *string   `json:"voice_file_url"`
	VoiceDuration *int     `json:"voice_duration"`
}

// CreateTimeline 创建时间线记录
func (h *TimelineHandler) CreateTimeline(c *gin.Context) {
	userID, _ := c.Get("user_id")
	var req CreateTimelineRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, Error(40001, "参数错误："+err.Error()))
		return
	}

	record := models.TimelineRecord{
		UserID:        userID.(string),
		Timestamp:     req.Timestamp,
		Content:       req.Content,
		BehaviorTag:   req.BehaviorTag,
		VoiceFileURL:  req.VoiceFileURL,
		VoiceDuration: req.VoiceDuration,
		Source:        "manual",
	}

	if err := h.DB.Create(&record).Error; err != nil {
		h.Logger.Error("failed to create timeline record", zap.Error(err))
		c.JSON(http.StatusInternalServerError, Error(50001, "创建失败"))
		return
	}

	c.JSON(http.StatusOK, Success(record))
}

// GetTodayTimeline 获取今日时间线
func (h *TimelineHandler) GetTodayTimeline(c *gin.Context) {
	userID, _ := c.Get("user_id")
	now := time.Now()
	startOfDay := time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, now.Location())
	endOfDay := startOfDay.Add(24 * time.Hour)

	var records []models.TimelineRecord
	if err := h.DB.Where("user_id = ? AND timestamp >= ? AND timestamp < ?", userID, startOfDay, endOfDay).
		Order("timestamp DESC").Find(&records).Error; err != nil {
		h.Logger.Error("failed to get today timeline", zap.Error(err))
		c.JSON(http.StatusInternalServerError, Error(50001, "查询失败"))
		return
	}

	c.JSON(http.StatusOK, Success(gin.H{
		"items": records,
		"date":  now.Format("2006-01-02"),
	}))
}

// GetHistoryTimeline 获取历史时间线
func (h *TimelineHandler) GetHistoryTimeline(c *gin.Context) {
	userID, _ := c.Get("user_id")
	startDate := c.Query("start_date")
	endDate := c.Query("end_date")
	behaviorTag := c.Query("behavior_tag")

	query := h.DB.Where("user_id = ?", userID)

	if startDate != "" {
		if t, err := time.Parse("2006-01-02", startDate); err == nil {
			query = query.Where("timestamp >= ?", t)
		}
	}
	if endDate != "" {
		if t, err := time.Parse("2006-01-02", endDate); err == nil {
			query = query.Where("timestamp < ?", t.Add(24*time.Hour))
		}
	}
	if behaviorTag != "" {
		query = query.Where("behavior_tag = ?", behaviorTag)
	}

	var records []models.TimelineRecord
	if err := query.Order("timestamp DESC").Find(&records).Error; err != nil {
		h.Logger.Error("failed to get history timeline", zap.Error(err))
		c.JSON(http.StatusInternalServerError, Error(50001, "查询失败"))
		return
	}

	c.JSON(http.StatusOK, Success(gin.H{"items": records}))
}

// UpdateTimelineRequest 更新时间线记录请求
type UpdateTimelineRequest struct {
	Content         *string `json:"content"`
	BehaviorTag     *string `json:"behavior_tag"`
	MatchedAgendaID *string `json:"matched_agenda_id"`
}

// UpdateTimeline 更新时间线记录
func (h *TimelineHandler) UpdateTimeline(c *gin.Context) {
	recordID := c.Param("id")
	userID, _ := c.Get("user_id")

	var record models.TimelineRecord
	if err := h.DB.Where("id = ? AND user_id = ?", recordID, userID).First(&record).Error; err != nil {
		c.JSON(http.StatusNotFound, Error(40401, "记录不存在"))
		return
	}

	var req UpdateTimelineRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, Error(40001, "参数错误："+err.Error()))
		return
	}

	updates := map[string]interface{}{}
	if req.Content != nil {
		updates["content"] = *req.Content
	}
	if req.BehaviorTag != nil {
		updates["behavior_tag"] = *req.BehaviorTag
	}
	if req.MatchedAgendaID != nil {
		updates["matched_agenda_id"] = *req.MatchedAgendaID
	}

	if err := h.DB.Model(&record).Updates(updates).Error; err != nil {
		h.Logger.Error("failed to update timeline record", zap.Error(err))
		c.JSON(http.StatusInternalServerError, Error(50001, "更新失败"))
		return
	}

	var updatedRecord models.TimelineRecord
	h.DB.Where("id = ?", recordID).First(&updatedRecord)

	c.JSON(http.StatusOK, Success(updatedRecord))
}

// DeleteTimeline 删除时间线记录
func (h *TimelineHandler) DeleteTimeline(c *gin.Context) {
	recordID := c.Param("id")
	userID, _ := c.Get("user_id")

	result := h.DB.Where("id = ? AND user_id = ?", recordID, userID).Delete(&models.TimelineRecord{})
	if result.Error != nil {
		h.Logger.Error("failed to delete timeline record", zap.Error(result.Error))
		c.JSON(http.StatusInternalServerError, Error(50001, "删除失败"))
		return
	}
	if result.RowsAffected == 0 {
		c.JSON(http.StatusNotFound, Error(40401, "记录不存在"))
		return
	}

	c.JSON(http.StatusOK, Success(gin.H{"message": "删除成功"}))
}

// UploadVoiceTimeline 上传语音时间线记录
func (h *TimelineHandler) UploadVoiceTimeline(c *gin.Context) {
	userID, _ := c.Get("user_id")

	// 获取表单文件
	file, err := c.FormFile("voice_file")
	if err != nil {
		c.JSON(http.StatusBadRequest, Error(40001, "请上传语音文件"))
		return
	}

	timestampStr := c.PostForm("timestamp")
	var timestamp time.Time
	if timestampStr != "" {
		if t, err := time.Parse(time.RFC3339, timestampStr); err == nil {
			timestamp = t
		}
	}
	if timestamp.IsZero() {
		timestamp = time.Now()
	}

	// 保存文件到本地（实际项目中应上传到OSS）
	uploadDir := "./uploads/voice"
	if err := ensureDir(uploadDir); err != nil {
		h.Logger.Error("failed to create upload dir", zap.Error(err))
		c.JSON(http.StatusInternalServerError, Error(50001, "文件保存失败"))
		return
	}

	fileName := fmt.Sprintf("%s_%d.wav", userID.(string), time.Now().UnixNano())
	filePath := fmt.Sprintf("%s/%s", uploadDir, fileName)
	if err := c.SaveUploadedFile(file, filePath); err != nil {
		h.Logger.Error("failed to save voice file", zap.Error(err))
		c.JSON(http.StatusInternalServerError, Error(50001, "文件保存失败"))
		return
	}

	voiceDuration := 0
	if dur, err := getWavDuration(filePath); err == nil {
		voiceDuration = dur
	}

	// 模拟ASR识别（实际项目中应调用讯飞/阿里云ASR API）
	// 这里使用本地规则引擎做简单的关键词提取
	mockText := extractMockTextFromFilename(file.Filename)
	asrText := mockText
	if asrText == "" {
		asrText = "语音记录"
	}

	// NLP解析
	nlpResult := nlp.Parse(asrText)
	behaviorTag := nlpResult.BehaviorTag

	// 创建时间线记录
	voiceFileURL := "/uploads/voice/" + fileName
	duration := voiceDuration
	record := models.TimelineRecord{
		UserID:        userID.(string),
		Timestamp:     timestamp,
		Content:       asrText,
		BehaviorTag:   behaviorTag,
		VoiceFileURL:  &voiceFileURL,
		VoiceDuration: &duration,
		Source:        "voice",
	}

	if err := h.DB.Create(&record).Error; err != nil {
		h.Logger.Error("failed to create timeline record", zap.Error(err))
		c.JSON(http.StatusInternalServerError, Error(50001, "创建失败"))
		return
	}

	// 自动匹配事程
	matchResult, _ := h.autoMatchRecord(record)

	response := gin.H{
		"record": record,
	}
	if matchResult != nil {
		response["match_result"] = matchResult
	}

	c.JSON(http.StatusOK, Success(response))
}

func (h *TimelineHandler) autoMatchRecord(record models.TimelineRecord) (*gin.H, error) {
	if record.BehaviorTag == nil {
		return nil, nil
	}

	now := record.Timestamp
	startTime := now.Add(-30 * time.Minute)
	endTime := now.Add(30 * time.Minute)

	var agendas []models.Agenda
	if err := h.DB.Where("user_id = ? AND status IN (?, ?) AND planned_time >= ? AND planned_time <= ?",
		record.UserID, "pending", "active", startTime, endTime).Find(&agendas).Error; err != nil {
		return nil, err
	}

	if len(agendas) == 0 {
		return nil, nil
	}

	var bestMatch *models.Agenda
	bestScore := 0.0

	for _, agenda := range agendas {
		score := 0.0
		if agenda.BehaviorTag != nil && *agenda.BehaviorTag == *record.BehaviorTag {
			score += 0.6
		} else if agenda.BehaviorTag != nil && strings.Contains(record.Content, *agenda.BehaviorTag) {
			score += 0.4
		}

		deviation := int(now.Sub(agenda.PlannedTime).Minutes())
		if deviation < 0 {
			deviation = -deviation
		}
		if deviation <= 5 {
			score += 0.3
		} else if deviation <= 15 {
			score += 0.2
		} else if deviation <= 30 {
			score += 0.1
		}

		if score > bestScore && score >= 0.5 {
			bestScore = score
			bestMatch = &agenda
		}
	}

	if bestMatch == nil {
		return nil, nil
	}

	nowTime := time.Now()
	h.DB.Model(&record).Updates(map[string]interface{}{
		"matched_agenda_id": bestMatch.ID,
		"match_score":       bestScore,
	})
	h.DB.Model(bestMatch).Updates(map[string]interface{}{
		"status":               "matched",
		"matched_timeline_id":  record.ID,
		"matched_at":           nowTime,
	})

	return &gin.H{
		"agenda_id":      bestMatch.ID,
		"agenda_content": bestMatch.Content,
		"match_success":  true,
		"match_score":    bestScore,
	}, nil
}

func ensureDir(dir string) error {
	if _, err := os.Stat(dir); os.IsNotExist(err) {
		return os.MkdirAll(dir, 0755)
	}
	return nil
}

func getWavDuration(filePath string) (int, error) {
	file, err := os.Open(filePath)
	if err != nil {
		return 0, err
	}
	defer file.Close()

	var chunkID [4]byte
	var chunkSize uint32
	var format [4]byte
	var subchunk1ID [4]byte
	var subchunk1Size uint32
	var audioFormat uint16
	var numChannels uint16
	var sampleRate uint32
	var byteRate uint32
	var blockAlign uint16
	var bitsPerSample uint16

	_ = binary.Read(file, binary.LittleEndian, &chunkID)
	_ = binary.Read(file, binary.LittleEndian, &chunkSize)
	_ = binary.Read(file, binary.LittleEndian, &format)
	_ = binary.Read(file, binary.LittleEndian, &subchunk1ID)
	_ = binary.Read(file, binary.LittleEndian, &subchunk1Size)
	_ = binary.Read(file, binary.LittleEndian, &audioFormat)
	_ = binary.Read(file, binary.LittleEndian, &numChannels)
	_ = binary.Read(file, binary.LittleEndian, &sampleRate)
	_ = binary.Read(file, binary.LittleEndian, &byteRate)
	_ = binary.Read(file, binary.LittleEndian, &blockAlign)
	_ = binary.Read(file, binary.LittleEndian, &bitsPerSample)

	var subchunk2ID [4]byte
	var subchunk2Size uint32
	_, _ = io.CopyN(io.Discard, file, int64(subchunk1Size)-16)
	_ = binary.Read(file, binary.LittleEndian, &subchunk2ID)
	_ = binary.Read(file, binary.LittleEndian, &subchunk2Size)

	if sampleRate > 0 && numChannels > 0 && bitsPerSample > 0 {
		duration := float64(subchunk2Size) / (float64(sampleRate) * float64(numChannels) * float64(bitsPerSample) / 8)
		return int(duration), nil
	}

	return 0, fmt.Errorf("cannot calculate duration")
}

func extractMockTextFromFilename(filename string) string {
	name := strings.TrimSuffix(filename, filepath.Ext(filename))
	name = strings.ReplaceAll(name, "_", " ")
	name = strings.ReplaceAll(name, "-", " ")
	return name
}
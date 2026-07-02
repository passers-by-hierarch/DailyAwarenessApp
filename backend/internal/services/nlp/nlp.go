package nlp

import (
	"regexp"
	"strings"
	"time"
)

type ParseResult struct {
	Intent      string
	Content     string
	BehaviorTag *string
	Time        *time.Time
	Keywords    []string
}

var behaviorTagKeywords = map[string][]string{
	"eating":        {"吃", "饭", "早餐", "午餐", "晚餐", "早饭", "午饭", "晚饭", "吃东西", "用餐", "美食"},
	"sleeping":      {"睡", "觉", "睡觉", "起床", "午休", "午睡", "晚安", "入睡", "睡着"},
	"exercising":    {"运动", "锻炼", "跑步", "健身", "散步", "打球", "游泳", "瑜伽", "走路", "晨练"},
	"medication":    {"吃药", "服药", "药", "用药", "吃了药", "服了药"},
	"reading":       {"看书", "读书", "阅读", "学习", "看报纸", "杂志"},
	"watching_tv":   {"看电视", "看剧", "追剧", "看电影", "电视"},
	"housework":     {"家务", "打扫", "做饭", "洗碗", "洗衣", "拖地", "收拾"},
	"social":        {"聊天", "打电话", "见面", "聚会", "拜访", "朋友", "家人"},
	"hygiene":       {"洗澡", "刷牙", "洗脸", "洗头", "梳妆", "洗漱"},
	"shopping":      {"购物", "买东西", "逛街", "超市", "买菜"},
	"outdoor":       {"出门", "外出", "散步", "遛弯", "公园", "出门转转"},
	"rest":          {"休息", "歇会", "放松", "躺", "坐", "静养"},
}

var intentPatterns = map[string][]string{
	"create_timeline": {"我刚", "刚刚", "刚才", "已经", "吃完", "做完", "完成", "刚"},
	"create_agenda":   {"明天", "下午", "晚上", "待会儿", "等会", "计划", "安排", "打算", "准备", "要去", "记得提醒"},
	"query":           {"今天", "昨天", "有什么", "查询", "看看", "统计"},
}

func Parse(text string) ParseResult {
	result := ParseResult{
		Content:  text,
		Intent:   "create_timeline",
		Keywords: extractKeywords(text),
	}

	tag := matchBehaviorTag(text)
	if tag != "" {
		result.BehaviorTag = &tag
	}

	parsedTime := parseTimeExpression(text)
	if parsedTime != nil {
		result.Time = parsedTime
	}

	intent := detectIntent(text)
	result.Intent = intent

	if intent == "create_agenda" && result.Time == nil {
		now := time.Now()
		defaultTime := now.Add(1 * time.Hour)
		result.Time = &defaultTime
	}

	return result
}

func extractKeywords(text string) []string {
	keywords := []string{}
	for tag, words := range behaviorTagKeywords {
		for _, word := range words {
			if strings.Contains(text, word) {
				keywords = append(keywords, word)
				break
			}
		}
		_ = tag
	}

	timeWords := []string{"早上", "上午", "中午", "下午", "晚上", "凌晨", "今天", "明天", "后天"}
	for _, word := range timeWords {
		if strings.Contains(text, word) {
			keywords = append(keywords, word)
		}
	}

	return keywords
}

func matchBehaviorTag(text string) string {
	highestTag := ""
	highestCount := 0

	for tag, keywords := range behaviorTagKeywords {
		count := 0
		for _, keyword := range keywords {
			if strings.Contains(text, keyword) {
				count++
			}
		}
		if count > highestCount {
			highestCount = count
			highestTag = tag
		}
	}

	if highestCount > 0 {
		return highestTag
	}
	return ""
}

func detectIntent(text string) string {
	agendaKeywords := []string{"明天", "下午", "晚上", "待会儿", "等会", "计划", "安排", "打算", "准备", "提醒", "记得"}
	agendaCount := 0
	for _, kw := range agendaKeywords {
		if strings.Contains(text, kw) {
			agendaCount++
		}
	}

	timelineKeywords := []string{"刚", "刚刚", "已经", "吃完", "做完", "完成", "了"}
	timelineCount := 0
	for _, kw := range timelineKeywords {
		if strings.Contains(text, kw) {
			timelineCount++
		}
	}

	queryKeywords := []string{"有什么", "查询", "看看", "统计", "今天做了", "昨天"}
	queryCount := 0
	for _, kw := range queryKeywords {
		if strings.Contains(text, kw) {
			queryCount++
		}
	}

	if queryCount > agendaCount && queryCount > timelineCount {
		return "query"
	}
	if agendaCount > timelineCount {
		return "create_agenda"
	}
	return "create_timeline"
}

func parseTimeExpression(text string) *time.Time {
	now := time.Now()
	var result time.Time

	timeRegex := regexp.MustCompile(`(\d{1,2})\s*[点时:](\d{2})?`)
	matches := timeRegex.FindStringSubmatch(text)
	if matches == nil {
		if strings.Contains(text, "早上") || strings.Contains(text, "上午") {
			result = time.Date(now.Year(), now.Month(), now.Day(), 8, 0, 0, 0, now.Location())
		} else if strings.Contains(text, "中午") {
			result = time.Date(now.Year(), now.Month(), now.Day(), 12, 0, 0, 0, now.Location())
		} else if strings.Contains(text, "下午") {
			result = time.Date(now.Year(), now.Month(), now.Day(), 15, 0, 0, 0, now.Location())
		} else if strings.Contains(text, "晚上") {
			result = time.Date(now.Year(), now.Month(), now.Day(), 20, 0, 0, 0, now.Location())
		} else if strings.Contains(text, "凌晨") {
			result = time.Date(now.Year(), now.Month(), now.Day(), 2, 0, 0, 0, now.Location())
		} else {
			return nil
		}
	} else {
		hour := parseHour(matches[1])
		minute := 0
		if len(matches) > 2 && matches[2] != "" {
			minute = parseInt(matches[2])
		}
		result = time.Date(now.Year(), now.Month(), now.Day(), hour, minute, 0, 0, now.Location())

		if strings.Contains(text, "下午") || strings.Contains(text, "晚上") {
			if hour < 12 {
				result = time.Date(now.Year(), now.Month(), now.Day(), hour+12, minute, 0, 0, now.Location())
			}
		}
	}

	if strings.Contains(text, "明天") {
		result = result.AddDate(0, 0, 1)
	} else if strings.Contains(text, "后天") {
		result = result.AddDate(0, 0, 2)
	} else if strings.Contains(text, "昨天") {
		result = result.AddDate(0, 0, -1)
	}

	if strings.Contains(text, "待会儿") || strings.Contains(text, "等会") {
		result = now.Add(30 * time.Minute)
	}

	return &result
}

func parseHour(s string) int {
	result := 0
	for _, c := range s {
		result = result*10 + int(c-'0')
	}
	return result
}

func parseInt(s string) int {
	result := 0
	for _, c := range s {
		result = result*10 + int(c-'0')
	}
	return result
}

func GetBehaviorTagList() []map[string]interface{} {
	tags := []map[string]interface{}{}
	for tag, keywords := range behaviorTagKeywords {
		label := getTagLabel(tag)
		tags = append(tags, map[string]interface{}{
			"key":      tag,
			"label":    label,
			"keywords": keywords,
		})
	}
	return tags
}

func getTagLabel(tag string) string {
	labels := map[string]string{
		"eating":      "用餐",
		"sleeping":    "睡眠",
		"exercising":  "运动",
		"medication":  "服药",
		"reading":     "阅读",
		"watching_tv": "看电视",
		"housework":   "家务",
		"social":      "社交",
		"hygiene":     "洗漱",
		"shopping":    "购物",
		"outdoor":     "外出",
		"rest":        "休息",
	}
	if label, ok := labels[tag]; ok {
		return label
	}
	return tag
}

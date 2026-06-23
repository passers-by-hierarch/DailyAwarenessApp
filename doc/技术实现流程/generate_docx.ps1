$outputPath = "D:\360MoveData\Users\13575\Desktop\tareopen\daily-awareness-app\docs\tech_design_doc.docx"
$tempDir = "D:\360MoveData\Users\13575\Desktop\tareopen\daily-awareness-app\docs\temp_docx"

if (Test-Path $tempDir) {
    Remove-Item -Recurse -Force $tempDir
}
New-Item -ItemType Directory -Force -Path $tempDir
New-Item -ItemType Directory -Force -Path "$tempDir\_rels"
New-Item -ItemType Directory -Force -Path "$tempDir\word"
New-Item -ItemType Directory -Force -Path "$tempDir\word\_rels"

$contentTypesXml = @"
<?xml version="1.0" encoding="UTF-8"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
    <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
    <Default Extension="xml" ContentType="application/xml"/>
    <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
</Types>
"@
[System.IO.File]::WriteAllText("$tempDir\[Content_Types].xml", $contentTypesXml, [System.Text.Encoding]::UTF8)

$relsXml = @"
<?xml version="1.0" encoding="UTF-8"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
    <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>
"@
[System.IO.File]::WriteAllText("$tempDir\_rels\.rels", $relsXml, [System.Text.Encoding]::UTF8)

$docRelsXml = @"
<?xml version="1.0" encoding="UTF-8"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"/>
"@
[System.IO.File]::WriteAllText("$tempDir\word\_rels\document.xml.rels", $docRelsXml, [System.Text.Encoding]::UTF8)

$docContent = @"
<?xml version="1.0" encoding="UTF-8"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
    <w:body>
        <w:p>
            <w:r>
                <w:t>Personal Assistant App - Technical Design Document</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>Version: 1.0</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>Date: June 23, 2026</w:t>
            </w:r>
        </w:p>
        <w:p/>
        <w:p>
            <w:r>
                <w:t>Document Table of Contents:</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>01 - Project Overview & Technical Architecture</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>02 - Core Data Models & Database Design</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>03 - API Interface Design</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>04 - Functional Module Detailed Design</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>05 - Speech Recognition & NLP Integration</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>06 - Flutter Client Architecture</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>07 - MVP Development Plan & Milestones</w:t>
            </w:r>
        </w:p>
        <w:p/>
        <w:p>
            <w:r>
                <w:t>===============================================================</w:t>
            </w:r>
        </w:p>
        <w:p/>
        <w:p>
            <w:r>
                <w:t>01 - Project Overview & Technical Architecture</w:t>
            </w:r>
        </w:p>
        <w:p/>
        <w:p>
            <w:r>
                <w:t>1. Project Background & Objectives</w:t>
            </w:r>
        </w:p>
        <w:p/>
        <w:p>
            <w:r>
                <w:t>Product Positioning: Personal Assistant (Daily Awareness App) is a voice recording and reminder assistant for people who need regular behavior management.</w:t>
            </w:r>
        </w:p>
        <w:p/>
        <w:p>
            <w:r>
                <w:t>Core Scenarios:</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>- Medication reminders for elderly/chronic disease patients</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>- Healthy habit formation for office workers (drinking water, exercise, rest)</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>- Daily task management (pick up package, organize room, appointments)</w:t>
            </w:r>
        </w:p>
        <w:p/>
        <w:p>
            <w:r>
                <w:t>Differentiated Advantages:</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>1. Voice-driven - Lower recording threshold, suitable for users not good at text input</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>2. Intelligent matching - Auto-associate behavior records with planned agendas</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>3. Gentle reminders - Multi-level reminder intensity, avoid one-size-fits-all</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>4. Behavior insights - Personalized suggestions based on data analysis</w:t>
            </w:r>
        </w:p>
        <w:p/>
        <w:p>
            <w:r>
                <w:t>2. Overall Technical Architecture</w:t>
            </w:r>
        </w:p>
        <w:p/>
        <w:p>
            <w:r>
                <w:t>System Layered Architecture:</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>Layer 1: Presentation Layer</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  - Flutter Client (iOS/Android)</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  - Family App (Optional)</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  - Admin Dashboard (Web)</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>Layer 2: Gateway Layer</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  - API Gateway, WebSocket Gateway, Push Gateway</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>Layer 3: Business Service Layer</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  - User Service, Timeline Service, Agenda Service</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  - Match Engine, Reminder Service, Analytics Service</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  - AI Orchestrator, Sync Service</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>Layer 4: AI Capability Layer</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  - ASR Service (iFlytek/Aliyun)</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  - NLP Service (iFlytek/Aliyun)</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>Layer 5: Data Storage Layer</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  - PostgreSQL (Primary DB), Redis (Cache), OSS (Object Storage)</w:t>
            </w:r>
        </w:p>
        <w:p/>
        <w:p>
            <w:r>
                <w:t>3. Technology Selection Details</w:t>
            </w:r>
        </w:p>
        <w:p/>
        <w:p>
            <w:r>
                <w:t>Client Technology Stack:</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  Cross-platform: Flutter 3.16+</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  State Management: Riverpod 2.4+</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  Local DB: SQLite (sqflite) 2.3+</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  Local Cache: Hive 2.2+</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  Network: Dio + Retrofit</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  Voice: flutter_sound 9.x</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  Notifications: flutter_local_notifications 16.x</w:t>
            </w:r>
        </w:p>
        <w:p/>
        <w:p>
            <w:r>
                <w:t>Server Technology Stack:</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  Language: Go 1.21+</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  Framework: Gin 1.9+</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  ORM: GORM 1.25+</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  Database: PostgreSQL 15+</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  Cache: Redis 7.x</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  Message Queue: RabbitMQ 3.12+</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  Object Storage: Aliyun OSS</w:t>
            </w:r>
        </w:p>
        <w:p/>
        <w:p>
            <w:r>
                <w:t>AI Services:</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  Primary: iFlytek Speech Recognition & NLP</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  Fallback: Aliyun Speech & NLP</w:t>
            </w:r>
        </w:p>
        <w:p/>
        <w:p>
            <w:r>
                <w:t>===============================================================</w:t>
            </w:r>
        </w:p>
        <w:p/>
        <w:p>
            <w:r>
                <w:t>02 - Core Data Models & Database Design</w:t>
            </w:r>
        </w:p>
        <w:p/>
        <w:p>
            <w:r>
                <w:t>Core Entities:</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  User - User Account</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  FamilyBinding - Family Relationship</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  TimelineRecord - Timeline Record</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  Agenda - Planned Agenda</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  ReminderRule - Reminder Rule</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  BehaviorTag - Behavior Tag</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  EscalatingStrategy - Escalating Strategy</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  MatchResult - Match Result</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  AnalyticsReport - Analytics Report</w:t>
            </w:r>
        </w:p>
        <w:p/>
        <w:p>
            <w:r>
                <w:t>Database: PostgreSQL</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  users table: id, phone, nickname, avatar_url, settings, created_at, updated_at</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  timeline_records: id, user_id, timestamp, content, behavior_tag, voice_file_url,</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>    matched_agenda_id, match_score, source, created_at, updated_at</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  agendas: id, user_id, planned_time, content, behavior_tag, agenda_type, status,</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>    remind_offset, remind_level, is_recurring, recurring_rule, created_at, updated_at</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  reminder_rules: id, user_id, agenda_id, level, enable_notification, enable_sound,</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>    enable_vibration, remind_offset, repeat_interval, max_reminders, allow_snooze</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  behavior_tags: id, tag_name, category, match_keywords, default_time_range</w:t>
            </w:r>
        </w:p>
        <w:p/>
        <w:p>
            <w:r>
                <w:t>Data Sync Strategy: Offline-First</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  - Local SQLite as primary data source</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  - Sync queue for pending data</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  - WebSocket for real-time cloud updates</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  - Conflict resolution: Cloud priority</w:t>
            </w:r>
        </w:p>
        <w:p/>
        <w:p>
            <w:r>
                <w:t>===============================================================</w:t>
            </w:r>
        </w:p>
        <w:p/>
        <w:p>
            <w:r>
                <w:t>03 - API Interface Design</w:t>
            </w:r>
        </w:p>
        <w:p/>
        <w:p>
            <w:r>
                <w:t>API Design Standards:</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  - RESTful style with version /api/v1/...</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  - Unified response: {code, message, data, timestamp}</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  - JWT Token authentication</w:t>
            </w:r>
        </w:p>
        <w:p/>
        <w:p>
            <w:r>
                <w:t>Core Interfaces:</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>Authentication:</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  POST /api/v1/auth/register - User Registration</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  POST /api/v1/auth/login - User Login</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  POST /api/v1/auth/refresh - Token Refresh</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>Timeline:</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  POST /api/v1/timeline/voice - Create Voice Record</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  POST /api/v1/timeline - Create Text Record</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  GET /api/v1/timeline/today - Get Today Timeline</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>Agenda:</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  POST /api/v1/agendas - Create Agenda</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  GET /api/v1/agendas/today - Get Today Agendas</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  POST /api/v1/agendas/{id}/confirm - Confirm Agenda</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  POST /api/v1/agendas/{id}/snooze - Snooze Reminder</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>Reminder Rules:</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  GET /api/v1/reminder-rules/default - Get Default Rules</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>Match Engine:</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  POST /api/v1/match/manual - Manual Match</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>Analytics:</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  GET /api/v1/analytics/frequency - Behavior Frequency</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  GET /api/v1/analytics/match-rate - Match Rate Trend</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  GET /api/v1/analytics/anomalies - Anomaly Detection</w:t>
            </w:r>
        </w:p>
        <w:p/>
        <w:p>
            <w:r>
                <w:t>===============================================================</w:t>
            </w:r>
        </w:p>
        <w:p/>
        <w:p>
            <w:r>
                <w:t>04 - Functional Module Detailed Design</w:t>
            </w:r>
        </w:p>
        <w:p/>
        <w:p>
            <w:r>
                <w:t>1. Voice Input Module</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  - Recording with flutter_sound</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  - Real-time waveform animation</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  - Upload to Aliyun OSS</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  - iFlytek ASR conversion</w:t>
            </w:r>
        </w:p>
        <w:p/>
        <w:p>
            <w:r>
                <w:t>2. NLP Parsing Module</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  - Keyword extraction</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  - Time expression parsing</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  - Intent recognition (record/plan/query)</w:t>
            </w:r>
        </w:p>
        <w:p/>
        <w:p>
            <w:r>
                <w:t>3. Match Engine Module</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  - Keyword matching with similarity algorithm</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  - Time window validation (+/- 30 minutes)</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  - Auto match trigger</w:t>
            </w:r>
        </w:p>
        <w:p/>
        <w:p>
            <w:r>
                <w:t>4. Reminder Notification Module</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  - 4 levels: gentle/standard/important/forced</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  - Escalating strategy: pre-remind -> first -> second -> family notify</w:t>
            </w:r>
        </w:p>
        <w:p/>
        <w:p>
            <w:r>
                <w:t>5. Behavior Analytics Module</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  - Frequency analysis, anomaly detection, trend prediction</w:t>
            </w:r>
        </w:p>
        <w:p/>
        <w:p>
            <w:r>
                <w:t>===============================================================</w:t>
            </w:r>
        </w:p>
        <w:p/>
        <w:p>
            <w:r>
                <w:t>05 - Speech Recognition & NLP Integration</w:t>
            </w:r>
        </w:p>
        <w:p/>
        <w:p>
            <w:r>
                <w:t>AI Service Selection:</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  Primary: iFlytek Open Platform</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>    - Best dialect support (23 dialects)</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>    - High accuracy (>98%)</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  Fallback: Aliyun Speech</w:t>
            </w:r>
        </w:p>
        <w:p/>
        <w:p>
            <w:r>
                <w:t>Cost Estimation (1000 active users):</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  ASR: ~495 RMB/month</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  NLP: ~300 RMB/month</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  TTS: ~60 RMB/month</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  Total: ~855 RMB/month</w:t>
            </w:r>
        </w:p>
        <w:p/>
        <w:p>
            <w:r>
                <w:t>===============================================================</w:t>
            </w:r>
        </w:p>
        <w:p/>
        <w:p>
            <w:r>
                <w:t>06 - Flutter Client Architecture</w:t>
            </w:r>
        </w:p>
        <w:p/>
        <w:p>
            <w:r>
                <w:t>Project Structure:</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  lib/core/ - Core infrastructure</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  lib/features/ - Feature modules (auth, timeline, agenda, voice, reminder, analytics, settings)</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  lib/shared/ - Shared components</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  lib/services/ - Background services</w:t>
            </w:r>
        </w:p>
        <w:p/>
        <w:p>
            <w:r>
                <w:t>Theme & Style:</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  Primary Color: #4A7C6F (Green)</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  Accent Color: #D4A574 (Warm)</w:t>
            </w:r>
        </w:p>
        <w:p/>
        <w:p>
            <w:r>
                <w:t>Pages:</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  - Home: Voice button, today stats, timeline, pending agendas</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  - Timeline: Full record list, history search</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  - Agenda: Agenda list, create/edit agenda</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  - Analytics: Frequency analysis, match rate trend, anomaly detection</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  - Settings: User config, reminder rules, family binding</w:t>
            </w:r>
        </w:p>
        <w:p/>
        <w:p>
            <w:r>
                <w:t>===============================================================</w:t>
            </w:r>
        </w:p>
        <w:p/>
        <w:p>
            <w:r>
                <w:t>07 - MVP Development Plan & Milestones</w:t>
            </w:r>
        </w:p>
        <w:p/>
        <w:p>
            <w:r>
                <w:t>Development Phases:</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  Phase 1 (Weeks 1-2): Infrastructure Setup</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  Phase 2 (Weeks 3-6): Core Features Development</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  Phase 3 (Weeks 7-9): Reminder System Development</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  Phase 4 (Weeks 10-12): Intelligent Features</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  Phase 5 (Weeks 13-14): Testing & Optimization</w:t>
            </w:r>
        </w:p>
        <w:p/>
        <w:p>
            <w:r>
                <w:t>Resource Requirements:</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  Team: 1 Backend + 1 Frontend + 1 QA + 0.5 PM = 3.5 people</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  Cost: ~1655 RMB/month (AI services + cloud + database)</w:t>
            </w:r>
        </w:p>
        <w:p/>
        <w:p>
            <w:r>
                <w:t>Success Criteria:</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  Speech recognition accuracy >= 95%</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  Agenda match accuracy >= 85%</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  Reminder punctuality >= 95%</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>  Offline functionality >= 90%</w:t>
            </w:r>
        </w:p>
        <w:p/>
        <w:p>
            <w:r>
                <w:t>===============================================================</w:t>
            </w:r>
        </w:p>
        <w:p/>
        <w:p>
            <w:r>
                <w:t>Summary</w:t>
            </w:r>
        </w:p>
        <w:p/>
        <w:p>
            <w:r>
                <w:t>This technical design document provides a complete implementation plan for the Personal Assistant App.</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>MVP development is expected to take 14 weeks with core features including voice input, timeline recording, agenda management, match engine, reminder system, and intelligent processing.</w:t>
            </w:r>
        </w:p>
        <w:p/>
        <w:p>
            <w:r>
                <w:t>Next Steps:</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>1. Assemble development team</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>2. Apply for iFlytek API keys</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>3. Apply for Aliyun OSS storage</w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:r>
                <w:t>4. Start Phase 1 development</w:t>
            </w:r>
        </w:p>
        <w:p/>
        <w:sectPr>
            <w:pgSz w:w="11906" w:h="16838"/>
            <w:pgMar w:top="1417" w:right="1417" w:bottom="1417" w:left="1417"/>
        </w:sectPr>
    </w:body>
</w:document>
"@
[System.IO.File]::WriteAllText("$tempDir\word\document.xml", $docContent, [System.Text.Encoding]::UTF8)

Add-Type -AssemblyName System.IO.Compression.FileSystem
if (Test-Path $outputPath) {
    Remove-Item -Force $outputPath
}
[System.IO.Compression.ZipFile]::CreateFromDirectory($tempDir, $outputPath)

Remove-Item -Recurse -Force $tempDir

Write-Host "Word document generated successfully at: $outputPath"
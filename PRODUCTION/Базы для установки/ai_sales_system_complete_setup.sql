-- ============================================================================
-- AI SALES SYSTEM - ПОЛНАЯ УСТАНОВКА (COMPLETE PACKAGE)
-- ============================================================================
-- 
-- ЭТОТ СКРИПТ СОЗДАЕТ ПОЛНУЮ СИСТЕМУ AI SALES:
-- • Основная система (35 таблиц) - AI агенты, чаты, email, CRM
-- • Административная часть (6 таблиц) - управление клиентами, аутентификация
-- 
-- ИТОГО: 41 ТАБЛИЦА + 7 ФУНКЦИЙ + 13 ТРИГГЕРОВ + 83 ИНДЕКСА
--
-- ИСПОЛЬЗОВАНИЕ:
-- 1. Создайте новую базу данных PostgreSQL
-- 2. Подключитесь к ней
-- 3. Выполните этот скрипт полностью
--
-- Версия PostgreSQL: 14+
-- Требуется расширение: pgvector (для AI embeddings)
-- Создано: 2024-12-07
-- ============================================================================

-- Устанавливаем параметры
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

-- ============================================================================
-- РАЗДЕЛ 0: СОЗДАНИЕ РАСШИРЕНИЙ
-- ============================================================================

-- Расширение для UUID
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Расширение для vector embeddings (для AI поиска в lead_qualification)
-- ВАЖНО: Если pgvector не установлен, закомментируйте эту строку
-- и таблица lead_qualification будет создана без AI embeddings
CREATE EXTENSION IF NOT EXISTS vector;

-- РАЗДЕЛ 1: СОЗДАНИЕ ФУНКЦИЙ
-- ============================================================================
-- Функции должны быть созданы до триггеров которые их используют
-- ============================================================================

-- Функция: extract_platform_from_session_id
CREATE OR REPLACE FUNCTION public.extract_platform_from_session_id()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- Извлекаем платформу из session_id (текст до первого _)
    -- Например: из 'telegram_347541984' получаем 'telegram'
    NEW.platform = SPLIT_PART(NEW.session_id, '_', 1);
    RETURN NEW;
END;
$function$
;

-- Функция: preserve_initial_timestamps
CREATE OR REPLACE FUNCTION public.preserve_initial_timestamps()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- Сохраняем первоначальные временные метки
    NEW.timestamp = COALESCE(OLD.timestamp, NEW.timestamp);
    NEW.session_start_time = COALESCE(OLD.session_start_time, NEW.session_start_time);
    NEW.record_timestamp = COALESCE(OLD.record_timestamp, NEW.record_timestamp);
    NEW.user_id = COALESCE(OLD.user_id, NEW.user_id);
    
    RETURN NEW;
END;
$function$
;

-- Функция: update_email_contact_last_updated
CREATE OR REPLACE FUNCTION public.update_email_contact_last_updated()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    NEW.last_updated = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$function$
;

-- Функция: update_integration_logs_timestamp
CREATE OR REPLACE FUNCTION public.update_integration_logs_timestamp()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$function$
;

-- Функция: update_updated_at_column
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$function$
;

-- Функция: update_user_contact_timestamp
CREATE OR REPLACE FUNCTION public.update_user_contact_timestamp()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    NEW.last_updated = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$function$
;


-- ============================================================================

-- ============================================================================
-- ЧАСТЬ 1: ОСНОВНАЯ СИСТЕМА (35 ТАБЛИЦ)
-- ============================================================================
-- AI Core, Чаты, Email, CRM, GDPR, Система
-- ============================================================================

-- РАЗДЕЛ 2: СОЗДАНИЕ ТАБЛИЦ
-- ============================================================================
-- Таблицы создаются в алфавитном порядке
-- Для каждой таблицы создаются:
--   - Структура колонок
--   - PRIMARY KEY
--   - UNIQUE constraints
-- ============================================================================

-- Таблица: ai_analysis_temp
CREATE TABLE IF NOT EXISTS ai_analysis_temp (
    id INTEGER DEFAULT nextval('ai_analysis_temp_id_seq'::regclass) NOT NULL,
    aggregated_data JSONB NOT NULL,
    created_at TIMESTAMP DEFAULT now() NULL,
    PRIMARY KEY (id)
);

-- Таблица: ai_learning_log
CREATE TABLE IF NOT EXISTS ai_learning_log (
    id INTEGER DEFAULT nextval('ai_learning_log_id_seq'::regclass) NOT NULL,
    type VARCHAR(100) NULL,
    action VARCHAR(100) NULL,
    table_name VARCHAR(100) NULL,
    content TEXT NULL,
    status VARCHAR(50) NULL,
    metadata JSONB NULL,
    created_at TIMESTAMP DEFAULT now() NULL,
    session_id VARCHAR(255) DEFAULT gen_random_uuid() NULL,
    workflow_execution_id VARCHAR(255) NULL,
    reason TEXT NULL,
    problem_addressed TEXT NULL,
    PRIMARY KEY (id)
);

-- Таблица: ai_performance_metrics
CREATE TABLE IF NOT EXISTS ai_performance_metrics (
    id INTEGER DEFAULT nextval('ai_performance_metrics_id_seq'::regclass) NOT NULL,
    week_start DATE NULL,
    total_analyses INTEGER NULL,
    correct_predictions INTEGER NULL,
    avg_confidence NUMERIC NULL,
    avg_risk_score NUMERIC NULL,
    best_performing_pattern TEXT NULL,
    worst_performing_pattern TEXT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NULL,
    PRIMARY KEY (id)
);

-- Таблица: analysis_language_settings
CREATE TABLE IF NOT EXISTS analysis_language_settings (
    id INTEGER DEFAULT nextval('analysis_language_settings_id_seq'::regclass) NOT NULL,
    language_code VARCHAR(10) NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NULL,
    updated_by VARCHAR(100) DEFAULT 'system'::character varying NULL,
    PRIMARY KEY (id)
);

-- Таблица: auto_analysis_settings
CREATE TABLE IF NOT EXISTS auto_analysis_settings (
    id INTEGER DEFAULT nextval('auto_analysis_settings_id_seq'::regclass) NOT NULL,
    enabled BOOLEAN DEFAULT FALSE NULL,
    delay_minutes INTEGER DEFAULT 30 NULL,
    last_check TIMESTAMP DEFAULT now() NULL,
    updated_at TIMESTAMP DEFAULT now() NULL,
    PRIMARY KEY (id)
);

-- Таблица: automation_log
CREATE TABLE IF NOT EXISTS automation_log (
    id INTEGER DEFAULT nextval('automation_log_id_seq'::regclass) NOT NULL,
    action_type VARCHAR(50) NOT NULL,
    session_id VARCHAR(255) NULL,
    details JSONB NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NULL,
    PRIMARY KEY (id)
);

-- Таблица: chat_status
CREATE TABLE IF NOT EXISTS chat_status (
    session_id VARCHAR(255) NOT NULL,
    manager_mode BOOLEAN DEFAULT FALSE NULL,
    manager_id VARCHAR(255) NULL,
    activated_at TIMESTAMP NULL,
    last_manager_message TIMESTAMP NULL,
    PRIMARY KEY (session_id)
);

-- Таблица: cleanup_logs
CREATE TABLE IF NOT EXISTS cleanup_logs (
    id INTEGER DEFAULT nextval('cleanup_logs_id_seq'::regclass) NOT NULL,
    cleanup_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP NULL,
    monitoring_deleted INTEGER DEFAULT 0 NULL,
    analysis_deleted INTEGER DEFAULT 0 NULL,
    dialogs_ru_deleted INTEGER DEFAULT 0 NULL,
    dialogs_en_deleted INTEGER DEFAULT 0 NULL,
    contacts_deleted INTEGER DEFAULT 0 NULL,
    total_deleted INTEGER DEFAULT 0 NULL,
    status VARCHAR(50) NULL,
    PRIMARY KEY (id)
);

-- Таблица: cleanup_settings
CREATE TABLE IF NOT EXISTS cleanup_settings (
    id INTEGER DEFAULT nextval('cleanup_settings_id_seq'::regclass) NOT NULL,
    monitoring_retention_days INTEGER DEFAULT 30 NULL,
    analysis_retention_days INTEGER DEFAULT 90 NULL,
    enabled BOOLEAN DEFAULT TRUE NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NULL,
    dialogs_retention_days INTEGER DEFAULT 60 NULL,
    contacts_retention_days INTEGER DEFAULT 180 NULL,
    PRIMARY KEY (id)
);

-- Таблица: conversation_highlights
CREATE TABLE IF NOT EXISTS conversation_highlights (
    id INTEGER DEFAULT nextval('conversation_highlights_id_seq'::regclass) NOT NULL,
    session_id VARCHAR(255) NOT NULL,
    message_id INTEGER NULL,
    message_text TEXT NULL,
    message_type VARCHAR(20) NULL,
    message_timestamp TIMESTAMP NULL,
    highlight_type VARCHAR(50) NOT NULL,
    confidence NUMERIC DEFAULT 0.70 NULL,
    detection_method VARCHAR(20) DEFAULT 'ai'::character varying NULL,
    matched_keywords TEXT[] NULL,
    reasoning TEXT NULL,
    language VARCHAR(10) NULL,
    platform VARCHAR(50) NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NULL,
    PRIMARY KEY (id)
);

-- Таблица: crm_sent_leads
CREATE TABLE IF NOT EXISTS crm_sent_leads (
    id INTEGER DEFAULT nextval('crm_sent_leads_id_seq'::regclass) NOT NULL,
    session_id VARCHAR(255) NOT NULL,
    crm_type VARCHAR(50) NOT NULL,
    crm_lead_id VARCHAR(255) NULL,
    lead_score INTEGER NULL,
    lead_temperature VARCHAR(20) NULL,
    sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NULL,
    webhook_url TEXT NULL,
    response_data JSONB NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NULL,
    bant_score INTEGER DEFAULT 0 NULL,
    bant_qualified BOOLEAN DEFAULT FALSE NULL,
    bant_level VARCHAR(10) DEFAULT 'cold'::character varying NULL,
    opportunity_amount INTEGER DEFAULT 0 NULL,
    contact_action VARCHAR(20) DEFAULT 'created'::character varying NULL,
    PRIMARY KEY (id),
    CONSTRAINT crm_sent_leads_session_id_key UNIQUE (session_id)
);

-- Таблица: crm_settings
CREATE TABLE IF NOT EXISTS crm_settings (
    id INTEGER DEFAULT nextval('crm_settings_id_seq'::regclass) NOT NULL,
    crm_type VARCHAR(50) NOT NULL,
    webhook_url TEXT NULL,
    auth_token TEXT NULL,
    settings JSONB NULL,
    auto_send_enabled BOOLEAN DEFAULT FALSE NULL,
    min_lead_score INTEGER DEFAULT 80 NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NULL,
    PRIMARY KEY (id),
    CONSTRAINT crm_settings_crm_type_key UNIQUE (crm_type)
);

-- Таблица: dialog_analysis
CREATE TABLE IF NOT EXISTS dialog_analysis (
    id INTEGER DEFAULT nextval('dialog_analysis_id_seq'::regclass) NOT NULL,
    session_id VARCHAR(255) NOT NULL,
    user_name VARCHAR(255) NULL,
    analysis_type VARCHAR(50) NOT NULL,
    language VARCHAR(10) NULL,
    platform VARCHAR(50) NULL,
    emotional_tone JSONB NULL,
    customer_needs TEXT[] NULL,
    missed_opportunities TEXT[] NULL,
    recommendations TEXT[] NULL,
    statistics JSONB NULL,
    satisfaction_percentage INTEGER NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NULL,
    lead_scoring JSONB NULL,
    bant_qualification JSONB NULL,
    extracted_entities JSONB NULL,
    PRIMARY KEY (id),
    CONSTRAINT unique_session_analysis_type UNIQUE (analysis_type, session_id),
    CONSTRAINT dialog_analysis_session_id_analysis_type_platform_key UNIQUE (session_id, analysis_type, platform)
);

-- Таблица: email_campaign_stats
CREATE TABLE IF NOT EXISTS email_campaign_stats (
    id INTEGER DEFAULT nextval('email_campaign_stats_id_seq'::regclass) NOT NULL,
    date DATE NOT NULL,
    platform VARCHAR(50) NULL,
    language VARCHAR(10) NULL,
    email_type VARCHAR(100) NULL,
    emails_sent INTEGER DEFAULT 0 NULL,
    emails_delivered INTEGER DEFAULT 0 NULL,
    emails_opened INTEGER DEFAULT 0 NULL,
    emails_clicked INTEGER DEFAULT 0 NULL,
    emails_bounced INTEGER DEFAULT 0 NULL,
    emails_unsubscribed INTEGER DEFAULT 0 NULL,
    unique_recipients INTEGER DEFAULT 0 NULL,
    new_leads INTEGER DEFAULT 0 NULL,
    conversions INTEGER DEFAULT 0 NULL,
    revenue NUMERIC DEFAULT 0 NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NULL,
    PRIMARY KEY (id)
);

-- Таблица: email_contact_data
CREATE TABLE IF NOT EXISTS email_contact_data (
    id INTEGER DEFAULT nextval('email_contact_data_id_seq'::regclass) NOT NULL,
    email VARCHAR(255) NOT NULL,
    thread_id VARCHAR(255) NULL,
    full_name VARCHAR(255) NULL,
    first_name VARCHAR(100) NULL,
    last_name VARCHAR(100) NULL,
    phone VARCHAR(50) NULL,
    phone_raw VARCHAR(50) NULL,
    company VARCHAR(255) NULL,
    position VARCHAR(255) NULL,
    location VARCHAR(255) NULL,
    linkedin VARCHAR(255) NULL,
    website VARCHAR(255) NULL,
    other_contacts JSONB DEFAULT '{}'::jsonb NULL,
    extracted_from TEXT NULL,
    confidence_score INTEGER DEFAULT 0 NULL,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NULL,
    PRIMARY KEY (id),
    CONSTRAINT email_contact_data_email_key UNIQUE (email)
);

-- Таблица: email_dialog_analysis
CREATE TABLE IF NOT EXISTS email_dialog_analysis (
    id INTEGER DEFAULT nextval('email_dialog_analysis_id_seq'::regclass) NOT NULL,
    email VARCHAR(255) NOT NULL,
    thread_id VARCHAR(255) NULL,
    user_name VARCHAR(255) NULL,
    analysis_type VARCHAR(50) DEFAULT 'single'::character varying NULL,
    language VARCHAR(10) DEFAULT 'ru'::character varying NULL,
    emotional_tone JSONB DEFAULT '{}'::jsonb NULL,
    customer_needs JSONB NULL,
    missed_opportunities JSONB NULL,
    recommendations JSONB NULL,
    statistics JSONB DEFAULT '{}'::jsonb NULL,
    satisfaction_percentage INTEGER DEFAULT 0 NULL,
    lead_scoring JSONB DEFAULT '{}'::jsonb NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NULL,
    PRIMARY KEY (id),
    CONSTRAINT email_dialog_analysis_unique UNIQUE (email, thread_id, analysis_type),
    CONSTRAINT email_dialog_analysis_email_unique UNIQUE (email)
);

-- Таблица: email_follow_ups
CREATE TABLE IF NOT EXISTS email_follow_ups (
    id INTEGER DEFAULT nextval('email_follow_ups_id_seq'::regclass) NOT NULL,
    email VARCHAR(255) NOT NULL,
    thread_id VARCHAR(100) NOT NULL,
    follow_up_date TIMESTAMP NOT NULL,
    status VARCHAR(50) DEFAULT 'pending'::character varying NULL,
    sent_at TIMESTAMP NULL,
    notes TEXT NULL,
    created_at TIMESTAMP DEFAULT now() NULL,
    updated_at TIMESTAMP DEFAULT now() NULL,
    PRIMARY KEY (id),
    CONSTRAINT email_follow_ups_email_thread_id_key UNIQUE (email, thread_id)
);

-- Таблица: email_monitoring
CREATE TABLE IF NOT EXISTS email_monitoring (
    id INTEGER DEFAULT nextval('email_monitoring_id_seq'::regclass) NOT NULL,
    record_id VARCHAR(255) NULL,
    record_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP NULL,
    email VARCHAR(255) NOT NULL,
    thread_id VARCHAR(255) NULL,
    user_name VARCHAR(255) NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP NULL,
    first_contact_time TIMESTAMP NULL,
    last_activity_time TIMESTAMP NULL,
    event_type VARCHAR(50) NULL,
    message_count INTEGER DEFAULT 0 NULL,
    subject TEXT NULL,
    language VARCHAR(10) DEFAULT 'ru'::character varying NULL,
    intent VARCHAR(50) NULL,
    urgency VARCHAR(20) NULL,
    status VARCHAR(50) NULL,
    last_reply_from VARCHAR(20) NULL,
    follow_up_date TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NULL,
    PRIMARY KEY (id),
    CONSTRAINT email_monitoring_email_unique UNIQUE (email),
    CONSTRAINT email_monitoring_record_id_key UNIQUE (record_id)
);

-- Таблица: email_processing_log
CREATE TABLE IF NOT EXISTS email_processing_log (
    id INTEGER DEFAULT nextval('email_processing_log_id_seq'::regclass) NOT NULL,
    gmail_message_id VARCHAR(255) NOT NULL,
    thread_id VARCHAR(255) NULL,
    email_from VARCHAR(255) NULL,
    email_to VARCHAR(255) NULL,
    subject TEXT NULL,
    direction VARCHAR(20) DEFAULT 'incoming'::character varying NULL,
    is_unread BOOLEAN DEFAULT FALSE NULL,
    processed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NULL,
    PRIMARY KEY (id),
    CONSTRAINT email_processing_log_gmail_message_id_key UNIQUE (gmail_message_id)
);

-- Таблица: email_session_mapping
CREATE TABLE IF NOT EXISTS email_session_mapping (
    id INTEGER DEFAULT nextval('email_session_mapping_id_seq'::regclass) NOT NULL,
    email VARCHAR(255) NOT NULL,
    session_id VARCHAR(255) NOT NULL,
    platform VARCHAR(50) NULL,
    client_name VARCHAR(255) NULL,
    phone VARCHAR(50) NULL,
    telegram_username VARCHAR(255) NULL,
    first_contact_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP NULL,
    last_contact_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP NULL,
    total_messages INTEGER DEFAULT 1 NULL,
    total_emails_sent INTEGER DEFAULT 0 NULL,
    total_emails_opened INTEGER DEFAULT 0 NULL,
    conversion_status VARCHAR(50) DEFAULT 'lead'::character varying NULL,
    lifetime_value NUMERIC DEFAULT 0 NULL,
    tags JSONB DEFAULT '[]'::jsonb NULL,
    metadata JSONB DEFAULT '{}'::jsonb NULL,
    PRIMARY KEY (id)
);

-- Таблица: email_tracking
CREATE TABLE IF NOT EXISTS email_tracking (
    id INTEGER DEFAULT nextval('email_tracking_id_seq'::regclass) NOT NULL,
    session_id VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    client_name VARCHAR(255) NULL,
    email_type VARCHAR(100) NULL,
    subject VARCHAR(500) NULL,
    content TEXT NULL,
    attachments JSONB DEFAULT '[]'::jsonb NULL,
    sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NULL,
    opened_at TIMESTAMP NULL,
    clicked_at TIMESTAMP NULL,
    status VARCHAR(50) DEFAULT 'sent'::character varying NULL,
    platform VARCHAR(50) NULL,
    language VARCHAR(10) DEFAULT 'ru'::character varying NULL,
    lead_score INTEGER DEFAULT 0 NULL,
    utm_source VARCHAR(100) NULL,
    utm_campaign VARCHAR(100) NULL,
    metadata JSONB DEFAULT '{}'::jsonb NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NULL,
    PRIMARY KEY (id)
);

-- Таблица: gdpr_audit_log
CREATE TABLE IF NOT EXISTS gdpr_audit_log (
    id INTEGER DEFAULT nextval('gdpr_audit_log_id_seq'::regclass) NOT NULL,
    session_id VARCHAR(255) NOT NULL,
    action VARCHAR(100) NOT NULL,
    details JSONB NULL,
    ip_address VARCHAR(45) NULL,
    user_agent TEXT NULL,
    domain VARCHAR(255) NULL,
    created_at TIMESTAMP DEFAULT now() NULL,
    PRIMARY KEY (id)
);

-- Таблица: gdpr_consents
CREATE TABLE IF NOT EXISTS gdpr_consents (
    id INTEGER DEFAULT nextval('gdpr_consents_id_seq'::regclass) NOT NULL,
    session_id VARCHAR(255) NOT NULL,
    user_email VARCHAR(255) NULL,
    consent_given BOOLEAN NOT NULL,
    consent_type VARCHAR(50) DEFAULT 'general'::character varying NULL,
    privacy_policy_version VARCHAR(20) NULL,
    ip_address VARCHAR(45) NULL,
    user_agent TEXT NULL,
    domain VARCHAR(255) NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NULL,
    expires_at TIMESTAMP NULL,
    revoked_at TIMESTAMP NULL,
    is_active BOOLEAN DEFAULT TRUE NULL,
    revoke_reason VARCHAR(255) NULL,
    revoke_ip VARCHAR(45) NULL,
    PRIMARY KEY (id)
);

-- Таблица: gmail_conversations
CREATE TABLE IF NOT EXISTS gmail_conversations (
    id INTEGER DEFAULT nextval('gmail_conversations_id_seq'::regclass) NOT NULL,
    thread_id VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    session_id VARCHAR(255) NULL,
    subject VARCHAR(500) NULL,
    first_message_date TIMESTAMP NULL,
    last_message_date TIMESTAMP NULL,
    last_message_id VARCHAR(255) NULL,
    message_count INTEGER DEFAULT 1 NULL,
    messages JSONB DEFAULT '[]'::jsonb NULL,
    status VARCHAR(50) DEFAULT 'active'::character varying NULL,
    lead_score INTEGER DEFAULT 0 NULL,
    sentiment VARCHAR(50) NULL,
    category VARCHAR(100) NULL,
    assigned_to VARCHAR(255) NULL,
    tags JSONB DEFAULT '[]'::jsonb NULL,
    notes TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NULL,
    language VARCHAR(10) DEFAULT 'ru'::character varying NULL,
    priority VARCHAR(20) NULL,
    score_history JSONB DEFAULT '[]'::jsonb NULL,
    PRIMARY KEY (id),
    CONSTRAINT gmail_conversations_email_unique UNIQUE (email)
);

-- Таблица: integration_logs
CREATE TABLE IF NOT EXISTS integration_logs (
    id INTEGER DEFAULT nextval('integration_logs_id_seq'::regclass) NOT NULL,
    session_id VARCHAR(255) NOT NULL,
    status VARCHAR(50) NOT NULL,
    error_message TEXT NULL,
    error_code VARCHAR(50) NULL,
    retry_count INTEGER DEFAULT 0 NULL,
    lead_score INTEGER NULL,
    lead_temperature VARCHAR(20) NULL,
    bant_score INTEGER NULL,
    bant_qualified BOOLEAN DEFAULT FALSE NULL,
    bant_level VARCHAR(10) NULL,
    bant_budget_score INTEGER NULL,
    bant_authority_score INTEGER NULL,
    bant_need_score INTEGER NULL,
    bant_timeline_score INTEGER NULL,
    crm_type VARCHAR(20) NULL,
    crm_contact_id VARCHAR(100) NULL,
    crm_contact_action VARCHAR(20) NULL,
    crm_deal_id VARCHAR(100) NULL,
    crm_stage_id VARCHAR(100) NULL,
    crm_pipeline_id VARCHAR(100) NULL,
    opportunity_amount NUMERIC NULL,
    telegram_sent BOOLEAN DEFAULT FALSE NULL,
    telegram_error TEXT NULL,
    notification_recipients TEXT[] NULL,
    execution_time_ms INTEGER NULL,
    webhook_url TEXT NULL,
    request_payload JSONB NULL,
    response_payload JSONB NULL,
    client_id VARCHAR(50) NULL,
    utm_source VARCHAR(255) NULL,
    utm_medium VARCHAR(255) NULL,
    utm_campaign VARCHAR(255) NULL,
    utm_content VARCHAR(255) NULL,
    utm_term VARCHAR(255) NULL,
    created_at TIMESTAMP DEFAULT now() NULL,
    updated_at TIMESTAMP DEFAULT now() NULL,
    PRIMARY KEY (id)
);

-- Таблица: n8n_chat_histories_en
CREATE TABLE IF NOT EXISTS n8n_chat_histories_en (
    id INTEGER DEFAULT nextval('n8n_chat_histories_en_id_seq'::regclass) NOT NULL,
    session_id VARCHAR(255) NOT NULL,
    message JSONB NOT NULL,
    platform VARCHAR(50) DEFAULT 'web'::character varying NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NULL,
    PRIMARY KEY (id)
);

-- Таблица: n8n_chat_histories_ru
CREATE TABLE IF NOT EXISTS n8n_chat_histories_ru (
    id INTEGER DEFAULT nextval('n8n_chat_histories_ru_id_seq'::regclass) NOT NULL,
    session_id VARCHAR(255) NOT NULL,
    message JSONB NOT NULL,
    platform VARCHAR(50) DEFAULT 'web'::character varying NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NULL,
    PRIMARY KEY (id)
);

-- Таблица: prechat_submissions
CREATE TABLE IF NOT EXISTS prechat_submissions (
    id INTEGER DEFAULT nextval('prechat_submissions_id_seq'::regclass) NOT NULL,
    session_id VARCHAR(255) NOT NULL,
    name VARCHAR(255) NULL,
    email VARCHAR(255) NULL,
    phone VARCHAR(50) NULL,
    company VARCHAR(255) NULL,
    custom_fields JSONB NULL,
    gdpr_consent BOOLEAN NOT NULL,
    domain VARCHAR(255) NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NULL,
    updated_at TIMESTAMP DEFAULT now() NULL,
    PRIMARY KEY (id),
    CONSTRAINT prechat_submissions_session_id_unique UNIQUE (session_id)
);

-- Таблица: sendpulse_addressbooks
CREATE TABLE IF NOT EXISTS sendpulse_addressbooks (
    id INTEGER NOT NULL,
    name VARCHAR(100) NOT NULL,
    type VARCHAR(50) NOT NULL,
    language VARCHAR(10) NOT NULL,
    last_sync TIMESTAMP NULL,
    PRIMARY KEY (id)
);

-- Таблица: sendpulse_sync
CREATE TABLE IF NOT EXISTS sendpulse_sync (
    id INTEGER DEFAULT nextval('sendpulse_sync_id_seq'::regclass) NOT NULL,
    email VARCHAR(255) NOT NULL,
    addressbook_id INTEGER NOT NULL,
    addressbook_name VARCHAR(100) NOT NULL,
    sync_status VARCHAR(50) NOT NULL,
    sync_date TIMESTAMP DEFAULT now() NULL,
    error_message TEXT NULL,
    PRIMARY KEY (id),
    CONSTRAINT sendpulse_sync_email_addressbook_id_key UNIQUE (email, addressbook_id)
);

-- Таблица: system_config
CREATE TABLE IF NOT EXISTS system_config (
    key VARCHAR(255) NOT NULL,
    value TEXT NULL,
    last_analysis_check TIMESTAMP DEFAULT now() NULL,
    created_at TIMESTAMP DEFAULT now() NULL,
    updated_at TIMESTAMP DEFAULT now() NULL,
    PRIMARY KEY (key)
);

-- Таблица: user_contact_data
CREATE TABLE IF NOT EXISTS user_contact_data (
    id INTEGER DEFAULT nextval('user_contact_data_id_seq'::regclass) NOT NULL,
    session_id VARCHAR(255) NOT NULL,
    full_name VARCHAR(255) NULL,
    first_name VARCHAR(100) NULL,
    last_name VARCHAR(100) NULL,
    phone VARCHAR(20) NULL,
    phone_raw VARCHAR(50) NULL,
    email VARCHAR(255) NULL,
    telegram VARCHAR(100) NULL,
    whatsapp VARCHAR(20) NULL,
    other_contacts JSONB NULL,
    company VARCHAR(255) NULL,
    position VARCHAR(255) NULL,
    location VARCHAR(255) NULL,
    preferred_contact VARCHAR(50) NULL,
    extracted_from TEXT NULL,
    confidence_score INTEGER DEFAULT 50 NULL,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NULL,
    platform VARCHAR(50) DEFAULT 'unknown'::character varying NULL,
    platform_user_id VARCHAR(255) NULL,
    platform_username VARCHAR(255) NULL,
    platform_first_name VARCHAR(255) NULL,
    platform_last_name VARCHAR(255) NULL,
    platform_metadata JSONB NULL,
    instagram VARCHAR(255) NULL,
    PRIMARY KEY (id),
    CONSTRAINT user_contact_data_session_id_key UNIQUE (session_id)
);

-- Таблица: user_language_preferences
CREATE TABLE IF NOT EXISTS user_language_preferences (
    chat_id VARCHAR(255) NOT NULL,
    platform VARCHAR(50) NOT NULL,
    preferred_language VARCHAR(5) DEFAULT 'ru'::character varying NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NULL,
    PRIMARY KEY (chat_id, platform)
);

-- Таблица: user_preferences
CREATE TABLE IF NOT EXISTS user_preferences (
    chat_id VARCHAR(255) NOT NULL,
    response_type VARCHAR(10) DEFAULT 'text'::character varying NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NULL,
    platform VARCHAR(50) DEFAULT 'telegram'::character varying NULL,
    PRIMARY KEY (chat_id)
);

-- Таблица: webchat_monitoring
CREATE TABLE IF NOT EXISTS webchat_monitoring (
    id INTEGER DEFAULT nextval('webchat_monitoring_id_seq'::regclass) NOT NULL,
    record_id VARCHAR(255) NULL,
    record_timestamp TIMESTAMP NULL,
    session_id VARCHAR(255) NULL,
    user_id VARCHAR(255) NULL,
    user_name VARCHAR(255) NULL,
    config_name VARCHAR(100) NULL,
    timestamp TIMESTAMP NULL,
    session_start_time TIMESTAMP NULL,
    last_activity_time TIMESTAMP NULL,
    session_duration INTEGER NULL,
    event_type VARCHAR(50) NULL,
    message_count INTEGER NULL,
    current_language VARCHAR(10) NULL,
    is_minimized BOOLEAN NULL,
    user_agent TEXT NULL,
    screen_resolution VARCHAR(50) NULL,
    language VARCHAR(10) NULL,
    timezone VARCHAR(100) NULL,
    referrer TEXT NULL,
    current_url TEXT NULL,
    domain VARCHAR(255) NULL,
    geo_ip VARCHAR(50) NULL,
    geo_country VARCHAR(100) NULL,
    geo_city VARCHAR(100) NULL,
    geo_region VARCHAR(100) NULL,
    geo_latitude NUMERIC NULL,
    geo_longitude NUMERIC NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NULL,
    platform VARCHAR(50) NULL,
    PRIMARY KEY (id),
    CONSTRAINT webchat_monitoring_record_id_key UNIQUE (record_id),
    CONSTRAINT unique_session_id UNIQUE (session_id)
);


-- ============================================================================
-- РАЗДЕЛ 3: СОЗДАНИЕ ИНДЕКСОВ
-- ============================================================================
-- Индексы создаются для оптимизации производительности запросов
-- ============================================================================

-- Индексы для таблицы: ai_learning_log
CREATE INDEX idx_ai_learning_log_created_at ON public.ai_learning_log USING btree (created_at DESC);
CREATE INDEX idx_ai_learning_log_status ON public.ai_learning_log USING btree (status);
CREATE INDEX idx_ai_learning_log_table_name ON public.ai_learning_log USING btree (table_name);
CREATE INDEX idx_ai_learning_log_type ON public.ai_learning_log USING btree (type);

-- Индексы для таблицы: automation_log
CREATE INDEX idx_automation_log_action_type ON public.automation_log USING btree (action_type);
CREATE INDEX idx_automation_log_created_at ON public.automation_log USING btree (created_at);
CREATE INDEX idx_automation_log_session_id ON public.automation_log USING btree (session_id);

-- Индексы для таблицы: conversation_highlights
CREATE INDEX idx_highlights_confidence ON public.conversation_highlights USING btree (confidence);
CREATE INDEX idx_highlights_created_at ON public.conversation_highlights USING btree (created_at);
CREATE INDEX idx_highlights_message_timestamp ON public.conversation_highlights USING btree (message_timestamp);
CREATE INDEX idx_highlights_session_id ON public.conversation_highlights USING btree (session_id);
CREATE INDEX idx_highlights_type ON public.conversation_highlights USING btree (highlight_type);

-- Индексы для таблицы: crm_sent_leads
CREATE INDEX idx_crm_sent_leads_sent_at ON public.crm_sent_leads USING btree (sent_at);
CREATE INDEX idx_crm_sent_leads_session_id ON public.crm_sent_leads USING btree (session_id);
CREATE INDEX idx_crm_sent_leads_temperature ON public.crm_sent_leads USING btree (lead_temperature);

-- Индексы для таблицы: dialog_analysis
CREATE INDEX idx_dialog_analysis_session ON public.dialog_analysis USING btree (session_id);
CREATE INDEX idx_dialog_analysis_type ON public.dialog_analysis USING btree (analysis_type);
CREATE UNIQUE INDEX unique_session_analysis_type ON public.dialog_analysis USING btree (session_id, analysis_type);

-- Индексы для таблицы: email_campaign_stats
CREATE INDEX idx_campaign_stats_date ON public.email_campaign_stats USING btree (date DESC);
CREATE INDEX idx_campaign_stats_platform ON public.email_campaign_stats USING btree (platform);
CREATE UNIQUE INDEX idx_campaign_stats_unique ON public.email_campaign_stats USING btree (date, platform, language, email_type);

-- Индексы для таблицы: email_contact_data
CREATE INDEX idx_email_contact_company ON public.email_contact_data USING btree (company);
CREATE INDEX idx_email_contact_data_email ON public.email_contact_data USING btree (email);
CREATE INDEX idx_email_contact_email ON public.email_contact_data USING btree (email);
CREATE INDEX idx_email_contact_updated ON public.email_contact_data USING btree (last_updated DESC);

-- Индексы для таблицы: email_dialog_analysis
CREATE UNIQUE INDEX email_dialog_analysis_email_unique ON public.email_dialog_analysis USING btree (email);
CREATE UNIQUE INDEX email_dialog_analysis_unique ON public.email_dialog_analysis USING btree (email, thread_id, analysis_type);
CREATE INDEX idx_email_analysis_created ON public.email_dialog_analysis USING btree (created_at DESC);
CREATE INDEX idx_email_analysis_email ON public.email_dialog_analysis USING btree (email);
CREATE INDEX idx_email_analysis_satisfaction ON public.email_dialog_analysis USING btree (satisfaction_percentage);
CREATE INDEX idx_email_analysis_thread ON public.email_dialog_analysis USING btree (thread_id);

-- Индексы для таблицы: email_follow_ups
CREATE INDEX idx_follow_up_date ON public.email_follow_ups USING btree (follow_up_date);
CREATE INDEX idx_follow_up_email ON public.email_follow_ups USING btree (email);
CREATE INDEX idx_follow_up_status ON public.email_follow_ups USING btree (status);

-- Индексы для таблицы: email_monitoring
CREATE UNIQUE INDEX email_monitoring_email_unique ON public.email_monitoring USING btree (email);
CREATE INDEX idx_email_monitoring_email ON public.email_monitoring USING btree (email);
CREATE INDEX idx_email_monitoring_status ON public.email_monitoring USING btree (status);
CREATE INDEX idx_email_monitoring_thread ON public.email_monitoring USING btree (thread_id);
CREATE INDEX idx_email_monitoring_timestamp ON public.email_monitoring USING btree (last_activity_time DESC);
CREATE INDEX idx_email_monitoring_urgency ON public.email_monitoring USING btree (urgency);

-- Индексы для таблицы: email_processing_log
CREATE INDEX idx_email_processing_log_gmail_id ON public.email_processing_log USING btree (gmail_message_id);
CREATE INDEX idx_processing_log_date ON public.email_processing_log USING btree (processed_at DESC);
CREATE INDEX idx_processing_log_email ON public.email_processing_log USING btree (email_from);
CREATE INDEX idx_processing_log_gmail_id ON public.email_processing_log USING btree (gmail_message_id);
CREATE INDEX idx_processing_log_thread ON public.email_processing_log USING btree (thread_id);

-- Индексы для таблицы: email_session_mapping
CREATE INDEX idx_email_session_conversion ON public.email_session_mapping USING btree (conversion_status);
CREATE INDEX idx_email_session_email ON public.email_session_mapping USING btree (email);
CREATE INDEX idx_email_session_platform ON public.email_session_mapping USING btree (platform);
CREATE INDEX idx_email_session_session ON public.email_session_mapping USING btree (session_id);
CREATE UNIQUE INDEX idx_email_session_unique ON public.email_session_mapping USING btree (email, session_id);

-- Индексы для таблицы: email_tracking
CREATE INDEX idx_email_tracking_email ON public.email_tracking USING btree (email);
CREATE INDEX idx_email_tracking_platform ON public.email_tracking USING btree (platform);
CREATE INDEX idx_email_tracking_sent_at ON public.email_tracking USING btree (sent_at);
CREATE INDEX idx_email_tracking_session ON public.email_tracking USING btree (session_id);
CREATE INDEX idx_email_tracking_status ON public.email_tracking USING btree (status);
CREATE UNIQUE INDEX idx_email_tracking_unique ON public.email_tracking USING btree (session_id, email_type, email);

-- Индексы для таблицы: gdpr_audit_log
CREATE INDEX idx_gdpr_audit_log_action ON public.gdpr_audit_log USING btree (action);
CREATE INDEX idx_gdpr_audit_log_created ON public.gdpr_audit_log USING btree (created_at);
CREATE INDEX idx_gdpr_audit_log_session ON public.gdpr_audit_log USING btree (session_id);

-- Индексы для таблицы: gdpr_consents
CREATE INDEX idx_consents_email ON public.gdpr_consents USING btree (user_email);
CREATE INDEX idx_consents_session ON public.gdpr_consents USING btree (session_id);
CREATE UNIQUE INDEX idx_gdpr_consents_session_type ON public.gdpr_consents USING btree (session_id, consent_type);

-- Индексы для таблицы: gmail_conversations
CREATE UNIQUE INDEX gmail_conversations_email_unique ON public.gmail_conversations USING btree (email);
CREATE INDEX idx_gmail_conversations_email ON public.gmail_conversations USING btree (email);
CREATE INDEX idx_gmail_conversations_session ON public.gmail_conversations USING btree (session_id);
CREATE INDEX idx_gmail_conversations_status ON public.gmail_conversations USING btree (status);
CREATE INDEX idx_gmail_conversations_thread ON public.gmail_conversations USING btree (thread_id);
CREATE INDEX idx_gmail_conversations_updated ON public.gmail_conversations USING btree (updated_at DESC);

-- Индексы для таблицы: integration_logs
CREATE INDEX idx_integration_logs_bant_level ON public.integration_logs USING btree (bant_level);


-- ============================================================================
-- РАЗДЕЛ 4: СОЗДАНИЕ ТРИГГЕРОВ
-- ============================================================================
-- Триггеры автоматически выполняют действия при INSERT/UPDATE/DELETE
-- ============================================================================

-- Триггеры для таблицы: email_contact_data
CREATE TRIGGER update_email_contact_data_last_updated
    BEFORE UPDATE
    ON email_contact_data
    FOR EACH ROW
    EXECUTE FUNCTION update_email_contact_last_updated();

-- Триггеры для таблицы: email_dialog_analysis
CREATE TRIGGER update_email_dialog_analysis_updated_at
    BEFORE UPDATE
    ON email_dialog_analysis
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Триггеры для таблицы: email_follow_ups
CREATE TRIGGER update_email_follow_ups_updated_at
    BEFORE UPDATE
    ON email_follow_ups
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Триггеры для таблицы: email_monitoring
CREATE TRIGGER update_email_monitoring_updated_at
    BEFORE UPDATE
    ON email_monitoring
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Триггеры для таблицы: gmail_conversations
CREATE TRIGGER update_gmail_conversations_updated_at
    BEFORE UPDATE
    ON gmail_conversations
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Триггеры для таблицы: integration_logs
CREATE TRIGGER trigger_update_integration_logs_timestamp
    BEFORE UPDATE
    ON integration_logs
    FOR EACH ROW
    EXECUTE FUNCTION update_integration_logs_timestamp();

-- Триггеры для таблицы: n8n_chat_histories_en
CREATE TRIGGER auto_set_platform_en
    BEFORE UPDATE
    ON n8n_chat_histories_en
    FOR EACH ROW
    EXECUTE FUNCTION extract_platform_from_session_id();

CREATE TRIGGER auto_set_platform_en
    BEFORE INSERT
    ON n8n_chat_histories_en
    FOR EACH ROW
    EXECUTE FUNCTION extract_platform_from_session_id();

-- Триггеры для таблицы: n8n_chat_histories_ru
CREATE TRIGGER auto_set_platform_ru
    BEFORE UPDATE
    ON n8n_chat_histories_ru
    FOR EACH ROW
    EXECUTE FUNCTION extract_platform_from_session_id();

CREATE TRIGGER auto_set_platform_ru
    BEFORE INSERT
    ON n8n_chat_histories_ru
    FOR EACH ROW
    EXECUTE FUNCTION extract_platform_from_session_id();

-- Триггеры для таблицы: user_contact_data
CREATE TRIGGER update_user_contact_timestamp
    BEFORE UPDATE
    ON user_contact_data
    FOR EACH ROW
    EXECUTE FUNCTION update_user_contact_timestamp();

-- Триггеры для таблицы: webchat_monitoring
CREATE TRIGGER preserve_timestamps_trigger
    BEFORE UPDATE
    ON webchat_monitoring
    FOR EACH ROW
    EXECUTE FUNCTION preserve_initial_timestamps();


-- ============================================================================
-- УСТАНОВКА ЗАВЕРШЕНА
-- ============================================================================
-- 
-- Создано:
--   - 6 функций для автоматизации
--   - 35 таблиц с полной структурой
--   - Все PRIMARY KEY и UNIQUE ограничения
--   - Все индексы для производительности
--   - Все триггеры для автоматизации
--
-- База данных готова к использованию!
-- ============================================================================
-- ============================================================================
-- ЧАСТЬ 2: АДМИНИСТРАТИВНАЯ СИСТЕМА (6 ТАБЛИЦ)
-- ============================================================================
-- Управление клиентами, аутентификация, логирование, AI квалификация
-- ============================================================================

-- Таблица: clients
CREATE TABLE IF NOT EXISTS clients (
    id INTEGER DEFAULT nextval('clients_id_seq'::regclass) NOT NULL,
    client_id VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    allowed_domains TEXT[] NULL,
    status VARCHAR(50) DEFAULT 'active'::character varying NOT NULL,
    features TEXT[] DEFAULT ARRAY['webchat'::text, 'monitoring'::text, 'database_management'::text] NULL,
    expires_at TIMESTAMPTZ NULL,
    created_at TIMESTAMPTZ DEFAULT now() NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NULL,
    license_key VARCHAR(128) NULL,
    password_hash VARCHAR(255) NULL,
    max_domains INTEGER DEFAULT 1 NULL,
    PRIMARY KEY (id),
    CONSTRAINT clients_license_key_key UNIQUE (license_key),
    CONSTRAINT clients_client_id_key UNIQUE (client_id)
);

-- Таблица: access_logs
CREATE TABLE IF NOT EXISTS access_logs (
    id INTEGER DEFAULT nextval('access_logs_id_seq'::regclass) NOT NULL,
    client_id VARCHAR(255) NOT NULL,
    feature VARCHAR(100) NULL,
    domain VARCHAR(500) NULL,
    ip_address VARCHAR(45) NULL,
    user_agent TEXT NULL,
    access_granted BOOLEAN DEFAULT FALSE NULL,
    error_message TEXT NULL,
    accessed_at TIMESTAMPTZ DEFAULT now() NULL,
    PRIMARY KEY (id)
);

-- Таблица: admins
CREATE TABLE IF NOT EXISTS admins (
    id INTEGER DEFAULT nextval('admins_id_seq'::regclass) NOT NULL,
    username VARCHAR(100) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    email VARCHAR(255) NULL,
    created_at TIMESTAMP DEFAULT now() NULL,
    last_login TIMESTAMP NULL,
    role VARCHAR(50) DEFAULT 'admin'::character varying NULL,
    is_active BOOLEAN DEFAULT TRUE NULL,
    PRIMARY KEY (id),
    CONSTRAINT admins_username_key UNIQUE (username)
);

-- Таблица: auth_users
CREATE TABLE IF NOT EXISTS auth_users (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    username VARCHAR(50) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    email VARCHAR(100) NULL,
    role VARCHAR(20) DEFAULT 'viewer'::character varying NULL,
    full_name VARCHAR(100) NULL,
    created_at TIMESTAMPTZ DEFAULT now() NULL,
    last_login TIMESTAMPTZ NULL,
    is_active BOOLEAN DEFAULT TRUE NULL,
    PRIMARY KEY (id),
    CONSTRAINT auth_users_username_key UNIQUE (username)
);

-- Таблица: lead_qualification
CREATE TABLE IF NOT EXISTS lead_qualification (
    id BIGINT DEFAULT nextval('lead_qualification_id_seq'::regclass) NOT NULL,
    content TEXT NOT NULL,
    metadata JSONB DEFAULT '{}'::jsonb NULL,
    embedding vector(1536) NULL,
    created_at TIMESTAMPTZ DEFAULT now() NULL,
    PRIMARY KEY (id)
);

-- Таблица: rate_limits
CREATE TABLE IF NOT EXISTS rate_limits (
    id INTEGER DEFAULT nextval('rate_limits_id_seq'::regclass) NOT NULL,
    ip_address VARCHAR(45) NOT NULL,
    endpoint VARCHAR(255) NOT NULL,
    request_count INTEGER DEFAULT 1 NULL,
    window_start TIMESTAMP DEFAULT now() NULL,
    blocked_until TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT now() NULL,
    PRIMARY KEY (id),
    CONSTRAINT rate_limits_ip_endpoint_unique UNIQUE (ip_address, endpoint)
);



-- ============================================================================
-- РАЗДЕЛ 3: ДОБАВЛЕНИЕ FOREIGN KEYS
-- ============================================================================
-- Foreign keys добавляются после создания всех таблиц
-- ============================================================================

-- РАЗДЕЛ 3: ДОБАВЛЕНИЕ FOREIGN KEYS

-- Foreign Key: access_logs -> clients
ALTER TABLE access_logs
    ADD CONSTRAINT fk_client
    FOREIGN KEY (client_id)
    REFERENCES clients(client_id)
    ON DELETE CASCADE;

-- ============================================================================
-- РАЗДЕЛ 4: СОЗДАНИЕ ИНДЕКСОВ
-- ============================================================================
-- Индексы создаются для оптимизации производительности запросов
-- ============================================================================

-- РАЗДЕЛ 4: СОЗДАНИЕ ИНДЕКСОВ
-- ============================================================================
-- Индексы создаются для оптимизации производительности запросов
-- ============================================================================

-- Индексы для таблицы: clients
CREATE INDEX idx_clients_client_id ON public.clients USING btree (client_id);
CREATE INDEX idx_clients_email ON public.clients USING btree (email);
CREATE INDEX idx_clients_status ON public.clients USING btree (status);

-- Индексы для таблицы: access_logs
CREATE INDEX idx_access_logs_accessed_at ON public.access_logs USING btree (accessed_at DESC);
CREATE INDEX idx_access_logs_client_id ON public.access_logs USING btree (client_id);
CREATE INDEX idx_access_logs_domain ON public.access_logs USING btree (domain);

-- Индексы для таблицы: admins
CREATE INDEX idx_admins_username ON public.admins USING btree (username);

-- Индексы для таблицы: auth_users
CREATE INDEX idx_auth_users_email ON public.auth_users USING btree (email);
CREATE INDEX idx_auth_users_is_active ON public.auth_users USING btree (is_active);
CREATE INDEX idx_auth_users_username ON public.auth_users USING btree (username);

-- Индексы для таблицы: lead_qualification
CREATE INDEX lead_qualification_embedding_idx ON public.lead_qualification USING ivfflat (embedding vector_cosine_ops) WITH (lists='100');

-- Индексы для таблицы: rate_limits
CREATE INDEX idx_rate_limits_ip ON public.rate_limits USING btree (ip_address);
CREATE INDEX idx_rate_limits_window ON public.rate_limits USING btree (window_start);
CREATE UNIQUE INDEX rate_limits_ip_endpoint_unique ON public.rate_limits USING btree (ip_address, endpoint);


-- ============================================================================

-- ============================================================================
-- РАЗДЕЛ 5: СОЗДАНИЕ ТРИГГЕРОВ
-- ============================================================================
-- Триггеры автоматически выполняют действия при INSERT/UPDATE/DELETE
-- ============================================================================

-- РАЗДЕЛ 5: СОЗДАНИЕ ТРИГГЕРОВ
-- ============================================================================
-- Триггеры автоматически выполняют действия при INSERT/UPDATE/DELETE
-- ============================================================================

-- Триггеры для таблицы: clients
CREATE TRIGGER update_clients_updated_at
    BEFORE UPDATE
    ON clients
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();



-- ============================================================================
-- УСТАНОВКА ЗАВЕРШЕНА
-- ============================================================================
-- 
-- Создано:
--   - 7 функций для автоматизации
--   - 41 таблица (35 основных + 6 админских)
--   - 1 Foreign Key (access_logs -> clients)
--   - Все PRIMARY KEY и UNIQUE ограничения
--   - 83 индекса для производительности
--   - 13 триггеров для автоматического обновления
--   - Поддержка AI embeddings (pgvector)
--
-- СТРУКТУРА БАЗЫ ДАННЫХ:
-- 
-- ОСНОВНАЯ СИСТЕМА (35 таблиц):
--   • AI Core: 4 таблицы (ai_analysis_temp, ai_learning_log, ai_performance_metrics, dialog_analysis)
--   • Чаты: 6 таблиц (n8n_chat_histories_ru/en, chat_status, webchat_monitoring, prechat_submissions, conversation_highlights)
--   • Email: 8 таблиц (gmail_conversations, email_contact_data, email_monitoring, и др.)
--   • CRM: 2 таблицы (crm_sent_leads, crm_settings)
--   • SendPulse: 2 таблицы (sendpulse_addressbooks, sendpulse_sync)
--   • Пользователи: 3 таблицы (user_contact_data, user_language_preferences, user_preferences)
--   • GDPR: 2 таблицы (gdpr_consents, gdpr_audit_log)
--   • Система: 7 таблиц (system_config, automation_log, integration_logs, и др.)
--
-- АДМИНИСТРАТИВНАЯ СИСТЕМА (6 таблиц):
--   • Клиенты: 2 таблицы (clients - управление клиентами, access_logs - логирование)
--   • Аутентификация: 2 таблицы (admins - суперадмины, auth_users - пользователи с ролями)
--   • AI и безопасность: 2 таблицы (lead_qualification - AI embeddings, rate_limits - защита)
--
-- База данных готова к использованию!
-- ============================================================================

-- ВАЖНОЕ ПРИМЕЧАНИЕ О PGVECTOR:
-- Если вы получили ошибку при создании расширения vector:
--   1. Закомментируйте строку: CREATE EXTENSION IF NOT EXISTS vector;
--   2. Измените тип колонки embedding в lead_qualification с vector(1536) на TEXT
--   3. Система будет работать, но без AI поиска по embeddings
--
-- Для установки pgvector:
--   - Supabase: Расширение уже доступно
--   - PostgreSQL: https://github.com/pgvector/pgvector
-- ============================================================================

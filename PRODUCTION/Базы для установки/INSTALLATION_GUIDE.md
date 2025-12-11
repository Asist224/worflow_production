# 🚀 AI SALES SYSTEM COMPLETE - Полное руководство по установке

## 📋 Содержание
1. [О системе](#о-системе)
2. [Требования](#требования)
3. [Быстрый старт](#быстрый-старт)
4. [Подробная инструкция](#подробная-инструкция)
5. [Работа с pgvector](#работа-с-pgvector)
6. [Проверка установки](#проверка-установки)
7. [Устранение проблем](#устранение-проблем)
8. [Примеры использования](#примеры-использования)

---

## 🎯 О системе

Это **ПОЛНЫЙ ПАКЕТ** AI Sales System, который объединяет:

### Основная система (35 таблиц):
- 🤖 **AI Core** - Самообучающаяся система анализа
- 💬 **Чаты** - Мультиплатформенная коммуникация
- 📧 **Email** - Автоматизация email маркетинга
- 🔗 **CRM** - Интеграция с популярными CRM
- 🌍 **Мультиязычность** - 11 языков
- 🔒 **GDPR** - Полное соответствие

### Административная система (6 таблиц):
- 👥 **Управление клиентами** - Мультиклиентская архитектура
- 🔐 **Аутентификация** - Двухуровневая система
- 📊 **Логирование** - Полный аудит действий
- 🤖 **AI квалификация** - Семантический поиск лидов
- 🛡️ **Rate Limiting** - Защита от злоупотреблений

**ИТОГО:** 41 таблица, 7 функций, 13 триггеров, 83 индекса

---

## ✅ Требования

### Обязательные:
- **PostgreSQL** версии 14 или выше
- **Права администратора** на создание баз данных
- **Расширение uuid-ossp** (обычно уже установлено)

### Опциональные:
- **pgvector** - для AI семантического поиска в lead_qualification
  - Supabase: ✅ Уже доступно
  - Локальный PostgreSQL: Требует установки
  - Без pgvector: Система работает, но без AI поиска

---

## 🚀 Быстрый старт

### Вариант 1: Supabase (рекомендуется)

1. Откройте **Supabase Dashboard** → **SQL Editor**
2. Скопируйте содержимое `ai_sales_system_complete_setup.sql`
3. Вставьте в редактор
4. Нажмите **Run** (Ctrl+Enter)
5. Подождите 30-60 секунд
6. Готово! ✅

### Вариант 2: PostgreSQL (командная строка)

```bash
# 1. Создайте базу данных
createdb ai_sales_complete

# 2. Выполните установку
psql -d ai_sales_complete -f ai_sales_system_complete_setup.sql

# 3. Проверьте установку
psql -d ai_sales_complete -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_type = 'BASE TABLE';"
```

**Ожидаемый результат:** 41

---

## 📖 Подробная инструкция

### Шаг 1: Подготовка

#### Создание базы данных

Вы можете выбрать **любое имя**:

```sql
-- Примеры:
CREATE DATABASE ai_sales_complete;
CREATE DATABASE my_company_ai;
CREATE DATABASE client_sales_system;
```

#### Подключение к базе данных

**Через psql:**
```bash
psql -U postgres -d ai_sales_complete
```

**Через Supabase:**
- Dashboard → **SQL Editor**

**Через pgAdmin:**
- Правый клик на базе → **Query Tool**

**Через DBeaver:**
- SQL Editor → Новый скрипт

### Шаг 2: Выполнение установочного скрипта

#### Способ A: Из файла

```bash
psql -U postgres -d ai_sales_complete -f ai_sales_system_complete_setup.sql
```

#### Способ B: Copy/Paste

1. Откройте `ai_sales_system_complete_setup.sql`
2. Скопируйте **всё** содержимое (Ctrl+A, Ctrl+C)
3. Вставьте в SQL редактор (Ctrl+V)
4. Выполните (Ctrl+Enter или кнопка Execute)

#### Что происходит при установке:

```
[1/6] Создание расширений (uuid-ossp, pgvector)... ✅
[2/6] Создание 7 функций... ✅
[3/6] Создание 41 таблицы... ✅
[4/6] Добавление Foreign Keys... ✅
[5/6] Создание 83 индексов... ✅
[6/6] Создание 13 триггеров... ✅

✅ Установка завершена за 30-60 секунд!
```

### Шаг 3: Проверка установки

```sql
-- Проверка 1: Количество таблиц (должно быть 41)
SELECT COUNT(*) as table_count
FROM information_schema.tables 
WHERE table_schema = 'public' AND table_type = 'BASE TABLE';

-- Проверка 2: Список таблиц
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
ORDER BY table_name;

-- Проверка 3: Количество функций (должно быть 7)
SELECT COUNT(*) as function_count
FROM information_schema.routines 
WHERE routine_schema = 'public';

-- Проверка 4: Количество триггеров (должно быть 13)
SELECT COUNT(*) as trigger_count
FROM information_schema.triggers 
WHERE trigger_schema = 'public';

-- Проверка 5: pgvector установлен?
SELECT extname, extversion 
FROM pg_extension 
WHERE extname = 'vector';
```

---

## 🤖 Работа с pgvector

### Что такое pgvector?

**pgvector** - это расширение PostgreSQL для работы с векторными embeddings. Используется в таблице `lead_qualification` для AI семантического поиска похожих лидов.

### Проверка наличия pgvector

```sql
SELECT * FROM pg_extension WHERE extname = 'vector';
```

### Если pgvector установлен ✅

Всё работает из коробки! Таблица `lead_qualification` поддерживает:
- Хранение AI embeddings (vector 1536 размерности)
- Быстрый семантический поиск
- Поиск похожих лидов по смыслу

### Если pgvector НЕ установлен ⚠️

#### Вариант А: Установить pgvector (рекомендуется)

**Supabase:**
- pgvector уже доступен, не требует установки

**Локальный PostgreSQL:**
```bash
# Ubuntu/Debian
sudo apt install postgresql-14-pgvector

# macOS
brew install pgvector

# Из исходников
git clone https://github.com/pgvector/pgvector.git
cd pgvector
make
sudo make install
```

После установки выполните:
```sql
CREATE EXTENSION vector;
```

#### Вариант Б: Работать без pgvector

1. Откройте файл `ai_sales_system_complete_setup.sql`
2. Найдите строку:
   ```sql
   CREATE EXTENSION IF NOT EXISTS vector;
   ```
3. Закомментируйте её:
   ```sql
   -- CREATE EXTENSION IF NOT EXISTS vector;
   ```
4. Найдите в таблице `lead_qualification`:
   ```sql
   embedding vector(1536) NULL
   ```
5. Замените на:
   ```sql
   embedding TEXT NULL
   ```
6. Сохраните и выполните скрипт

**Что изменится:**
- ❌ Не будет AI семантического поиска
- ❌ Не будет IVFFLAT индекса
- ✅ Остальная функциональность работает полностью

---

## 🔍 Проверка установки

### Быстрая проверка

```sql
-- 1. Таблицы (41)
SELECT COUNT(*) FROM information_schema.tables 
WHERE table_schema = 'public' AND table_type = 'BASE TABLE';

-- 2. Функции (7)
SELECT COUNT(*) FROM information_schema.routines 
WHERE routine_schema = 'public';

-- 3. Триггеры (13)
SELECT COUNT(*) FROM information_schema.triggers 
WHERE trigger_schema = 'public';

-- 4. Индексы (83+)
SELECT COUNT(*) FROM pg_indexes 
WHERE schemaname = 'public';
```

### Детальная проверка

```sql
-- Проверка Foreign Key (1)
SELECT
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table,
    ccu.column_name AS foreign_column
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
    ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage ccu 
    ON tc.constraint_name = ccu.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_schema = 'public';

-- Проверка триггеров по таблицам
SELECT event_object_table, trigger_name, action_timing, event_manipulation
FROM information_schema.triggers
WHERE trigger_schema = 'public'
ORDER BY event_object_table;
```

---

## 📊 Что создаётся

### 📂 Основная система (35 таблиц)

**AI Core (4):**
- ai_analysis_temp
- ai_learning_log
- ai_performance_metrics
- dialog_analysis

**Чаты (6):**
- n8n_chat_histories_ru
- n8n_chat_histories_en
- chat_status
- webchat_monitoring
- prechat_submissions
- conversation_highlights

**Email (8):**
- gmail_conversations
- email_contact_data
- email_monitoring
- email_dialog_analysis
- email_follow_ups
- email_campaign_stats
- email_tracking
- email_session_mapping

**CRM (2):**
- crm_sent_leads
- crm_settings

**SendPulse (2):**
- sendpulse_addressbooks
- sendpulse_sync

**Пользователи (3):**
- user_contact_data
- user_language_preferences
- user_preferences

**GDPR (2):**
- gdpr_consents
- gdpr_audit_log

**Система (7):**
- system_config
- automation_log
- integration_logs
- cleanup_logs
- cleanup_settings
- analysis_language_settings
- auto_analysis_settings

### 🔐 Административная система (6 таблиц)

**Клиенты (2):**
- clients - управление клиентами
- access_logs - логи доступа

**Аутентификация (2):**
- admins - суперадминистраторы
- auth_users - пользователи с ролями

**AI и безопасность (2):**
- lead_qualification - AI embeddings
- rate_limits - защита API

### ⚙️ Функции (7)

1. `extract_platform_from_session_id()` - Извлекает платформу из session_id
2. `preserve_initial_timestamps()` - Сохраняет начальные timestamps
3. `update_email_contact_last_updated()` - Обновляет email контакты
4. `update_integration_logs_timestamp()` - Обновляет логи интеграций
5. `update_updated_at_column()` - Универсальное обновление updated_at
6. `update_user_contact_timestamp()` - Обновляет user контакты
7. (Дубликат update_updated_at_column удалён при объединении)

### 🔄 Триггеры (13)

- Автообновление timestamps: 8 триггеров
- Извлечение platform: 2 триггера
- Сохранение initial timestamps: 2 триггера
- Обновление clients: 1 триггер

---

## ⚠️ Устранение проблем

### Проблема: "ERROR: extension vector does not exist"

**Причина:** pgvector не установлен

**Решение:**
1. Закомментируйте `CREATE EXTENSION IF NOT EXISTS vector;`
2. Измените тип `embedding` с `vector(1536)` на `TEXT`
3. Выполните скрипт заново

### Проблема: "ERROR: relation already exists"

**Причина:** Таблицы уже существуют

**Решение:** Используйте скрипт cleanup

```sql
-- ОСТОРОЖНО! Удалит ВСЕ таблицы!
DROP SCHEMA public CASCADE;
CREATE SCHEMA public;
```

### Проблема: "ERROR: permission denied"

**Причина:** Недостаточно прав

**Решение:**
```sql
GRANT ALL PRIVILEGES ON DATABASE your_database TO your_user;
```

### Проблема: Долгое выполнение (>2 минут)

**Причина:** Медленный сервер или большая нагрузка

**Решение:** Это нормально для первой установки. Подождите до 5 минут.

---

## 💡 Примеры использования

### 1. Создание клиента

```sql
INSERT INTO clients (
    client_id, 
    name, 
    email, 
    allowed_domains,
    features,
    expires_at,
    license_key
) VALUES (
    'acme_corp',
    'Acme Corporation',
    'admin@acme.com',
    ARRAY['acme.com', 'www.acme.com'],
    ARRAY['webchat', 'monitoring', 'database_management'],
    NOW() + INTERVAL '1 year',
    encode(gen_random_bytes(32), 'hex')
);
```

### 2. Сохранение сообщения чата

```sql
INSERT INTO n8n_chat_histories_ru (
    session_id,
    role,
    message,
    platform,
    created_at
) VALUES (
    'telegram_123456789',
    'user',
    'Здравствуйте! Хочу узнать о вашем продукте',
    'telegram',
    NOW()
);
```

### 3. Создание администратора

```sql
INSERT INTO admins (
    username,
    password_hash,
    email,
    role
) VALUES (
    'admin',
    crypt('secure_password', gen_salt('bf')),
    'admin@yourcompany.com',
    'superadmin'
);
```

### 4. Логирование доступа

```sql
INSERT INTO access_logs (
    client_id,
    feature,
    domain,
    ip_address,
    user_agent,
    access_granted
) VALUES (
    'acme_corp',
    'webchat',
    'acme.com',
    '192.168.1.100',
    'Mozilla/5.0...',
    true
);
```

### 5. AI поиск похожих лидов

```sql
-- Найти 5 самых похожих лидов
SELECT 
    id, 
    content,
    1 - (embedding <=> '[0.1,0.2,...]'::vector) as similarity
FROM lead_qualification
WHERE embedding IS NOT NULL
ORDER BY embedding <=> '[0.1,0.2,...]'::vector
LIMIT 5;
```

---

## ✅ Чеклист успешной установки

- [ ] База данных создана
- [ ] Скрипт выполнен без ошибок
- [ ] Создано 41 таблица
- [ ] Создано 7 функций
- [ ] Создано 13 триггеров
- [ ] Создано 83+ индекса
- [ ] Создан 1 Foreign Key
- [ ] pgvector работает (или отключен если не нужен)
- [ ] Все проверочные запросы возвращают правильные результаты

---

## 🎉 Готово!

База данных установлена и готова к использованию!

**Следующие шаги:**
1. Подключите n8n workflows к базе данных
2. Создайте первого клиента
3. Настройте интеграции (Telegram, Email, CRM)
4. Начните принимать запросы от пользователей

---

**Версия:** 1.0 Complete  
**Дата:** 2024-12-07  
**PostgreSQL:** 14+

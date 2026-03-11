-- Adaptive Intelligence Engine — Event Store
-- Separate SQLite database from Memory Engine
-- File: intelligence.db (created at runtime in plugin data directory)

CREATE TABLE IF NOT EXISTS events (
    id          TEXT PRIMARY KEY,        -- uuid v4
    timestamp   TEXT NOT NULL,           -- ISO 8601
    session_id  TEXT NOT NULL,           -- links events within one session
    plugin      TEXT NOT NULL,           -- e.g., "inbox-zero"
    command     TEXT NOT NULL,           -- e.g., "inbox-triage"
    event_type  TEXT NOT NULL CHECK(event_type IN ('pre_command', 'post_command', 'mcp_call', 'decision_point', 'error')),
    payload     TEXT NOT NULL,           -- JSON blob, schema varies by event_type
    outcome     TEXT CHECK(outcome IN ('success', 'failure', 'degraded') OR outcome IS NULL),
    duration_ms INTEGER                  -- wall clock time (post-events only)
);

CREATE INDEX IF NOT EXISTS idx_events_plugin ON events(plugin, command);
CREATE INDEX IF NOT EXISTS idx_events_type ON events(event_type);
CREATE INDEX IF NOT EXISTS idx_events_outcome ON events(outcome);
CREATE INDEX IF NOT EXISTS idx_events_session ON events(session_id);

-- Patterns table (used by Learning module, created here for schema completeness)
CREATE TABLE IF NOT EXISTS patterns (
    id              TEXT PRIMARY KEY,
    pattern_type    TEXT NOT NULL CHECK(pattern_type IN ('taste', 'workflow', 'autonomy')),
    plugin          TEXT,                -- null = cross-plugin
    command         TEXT,                -- null = all commands in plugin
    description     TEXT NOT NULL,       -- human-readable
    instruction     TEXT NOT NULL,       -- injected text
    confidence      REAL NOT NULL DEFAULT 0.0,
    observations    INTEGER DEFAULT 0,
    confirmations   INTEGER DEFAULT 0,
    rejections      INTEGER DEFAULT 0,
    status          TEXT DEFAULT 'candidate' CHECK(status IN ('candidate', 'active', 'approved', 'rejected')),
    created_at      TEXT NOT NULL,
    updated_at      TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_patterns_plugin ON patterns(plugin, command);
CREATE INDEX IF NOT EXISTS idx_patterns_status ON patterns(status);
CREATE INDEX IF NOT EXISTS idx_patterns_type ON patterns(pattern_type);

-- Healing patterns table (used by Self-Healing module)
CREATE TABLE IF NOT EXISTS healing_patterns (
    id              TEXT PRIMARY KEY,
    error_signature TEXT NOT NULL,       -- normalized: "notion_api:404:database_not_found"
    category        TEXT NOT NULL CHECK(category IN ('transient', 'recoverable', 'degradable', 'fatal')),
    fix_action      TEXT,                -- what to do
    fallback_action TEXT,                -- degraded path if fix fails
    success_count   INTEGER DEFAULT 0,
    failure_count   INTEGER DEFAULT 0,
    last_seen       TEXT,
    plugin          TEXT,               -- null = cross-plugin pattern
    created_at      TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_healing_sig ON healing_patterns(error_signature);
CREATE INDEX IF NOT EXISTS idx_healing_plugin ON healing_patterns(plugin);

-- Configuration table
CREATE TABLE IF NOT EXISTS config (
    key   TEXT PRIMARY KEY,
    value TEXT NOT NULL
);

-- Default configuration values
INSERT OR IGNORE INTO config (key, value) VALUES
    ('learning.enabled', 'true'),
    ('learning.taste.threshold', '0.5'),
    ('learning.workflow.suggest_threshold', '0.5'),
    ('learning.workflow.trigger_threshold', '0.8'),
    ('learning.autonomy.max_level', 'notify'),
    ('healing.enabled', 'true'),
    ('healing.max_retries', '3'),
    ('healing.fallback.enabled', 'true'),
    ('hooks.retention_days', '30'),
    ('hooks.decision_points', 'true');

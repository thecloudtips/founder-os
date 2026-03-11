-- Founder OS Memory Engine: SQLite schema for cross-plugin shared memory store
-- Journal mode WAL for concurrent read performance; normal sync is safe with WAL
PRAGMA journal_mode = WAL;
PRAGMA synchronous = NORMAL;
PRAGMA foreign_keys = ON;

-- Core memory entries
CREATE TABLE IF NOT EXISTS memories (
  id TEXT PRIMARY KEY,
  key TEXT NOT NULL UNIQUE,          -- human-readable identifier
  category TEXT NOT NULL             -- preference | pattern | fact | contact | workflow
    CHECK (category IN ('preference', 'pattern', 'fact', 'contact', 'workflow')),
  content TEXT NOT NULL,             -- the actual memory content
  source_plugin TEXT,                -- which plugin created this (P01, P21, user, etc.)
  confidence INTEGER DEFAULT 0       -- 0-100, rises with repeated confirmation
    CHECK (confidence >= 0 AND confidence <= 100),
  status TEXT DEFAULT 'candidate'    -- candidate | confirmed | applied | dismissed
    CHECK (status IN ('candidate', 'confirmed', 'applied', 'dismissed')),
  company_id TEXT,                   -- optional: related company page_id
  tags TEXT,                         -- JSON array of tags for filtering
  embedding TEXT,                    -- vector embedding for semantic search
  times_used INTEGER DEFAULT 0,
  times_confirmed INTEGER DEFAULT 0,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  last_used_at INTEGER,
  expires_at INTEGER,                -- optional TTL for temporal patterns
  notion_page_id TEXT,               -- Notion page ID for bidirectional sync
  last_synced_at INTEGER,            -- last successful sync timestamp
  deleted_at INTEGER                 -- soft-delete timestamp for sync
);

-- Pattern observations (raw data before becoming memories)
CREATE TABLE IF NOT EXISTS observations (
  id TEXT PRIMARY KEY,
  plugin TEXT NOT NULL,
  action TEXT NOT NULL,              -- what the user did
  context TEXT,                      -- surrounding context (JSON)
  observed_at INTEGER NOT NULL
);

-- Adaptation log (what the system changed and when)
CREATE TABLE IF NOT EXISTS adaptations (
  id TEXT PRIMARY KEY,
  memory_id TEXT REFERENCES memories(id),
  plugin TEXT NOT NULL,
  description TEXT NOT NULL,         -- "Now auto-archiving newsletters from tech-daily.com"
  applied_at INTEGER NOT NULL,
  reverted_at INTEGER                -- null if still active
);

-- Indexes for common query patterns
-- Frequently filtered by category (e.g., all preferences, all workflow patterns)
CREATE INDEX IF NOT EXISTS idx_memories_category ON memories(category);

-- Filtered by lifecycle status (e.g., all confirmed memories ready to inject)
CREATE INDEX IF NOT EXISTS idx_memories_status ON memories(status);

-- Client-scoped memory lookups (most common CRM-linked queries)
CREATE INDEX IF NOT EXISTS idx_memories_company_id ON memories(company_id)
  WHERE company_id IS NOT NULL;

-- Category + status compound index for the most common filter combination
CREATE INDEX IF NOT EXISTS idx_memories_category_status ON memories(category, status);

-- TTL expiry sweeps (periodic cleanup job)
CREATE INDEX IF NOT EXISTS idx_memories_expires_at ON memories(expires_at)
  WHERE expires_at IS NOT NULL;

-- Recently used memories (LRU eviction and recency ranking)
CREATE INDEX IF NOT EXISTS idx_memories_last_used_at ON memories(last_used_at)
  WHERE last_used_at IS NOT NULL;

-- Source plugin lookups (e.g., "show all memories P01 has written")
CREATE INDEX IF NOT EXISTS idx_memories_source_plugin ON memories(source_plugin)
  WHERE source_plugin IS NOT NULL;

-- Observations grouped by plugin for pattern aggregation
CREATE INDEX IF NOT EXISTS idx_observations_plugin ON observations(plugin);

-- Observations ordered by time for sliding-window pattern detection
CREATE INDEX IF NOT EXISTS idx_observations_plugin_time ON observations(plugin, observed_at);

-- Adaptations linked back to their originating memory
CREATE INDEX IF NOT EXISTS idx_adaptations_memory_id ON adaptations(memory_id)
  WHERE memory_id IS NOT NULL;

-- Active adaptations (reverted_at IS NULL = still in effect)
CREATE INDEX IF NOT EXISTS idx_adaptations_active ON adaptations(plugin, reverted_at)
  WHERE reverted_at IS NULL;

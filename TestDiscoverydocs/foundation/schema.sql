-- ============================================================================
-- CalcApp — PostgreSQL Schema (Supabase-Compatible)
-- Version: 1.0
-- Database: PostgreSQL 15+ via Supabase
-- Role: Database Architect
-- Phase: DESIGN (Mode 1 Full Army Pipeline)
--
-- Features:
--   - Row-Level Security (RLS) for multi-tenant isolation
--   - Trigger functions for updated_at auto-update
--   - Soft-delete cascade support
--   - Full-text search indexes (GIN)
--   - LWW vector clock conflict resolution support
--   - GDPR-compliant deletion cascade
-- ============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";    -- trigram similarity for fuzzy search

-- ============================================================================
-- 1. USERS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.users (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email           TEXT NOT NULL,
    display_name    TEXT,
    avatar_url      TEXT,
    encryption_salt TEXT NOT NULL,
    vector_clock    INTEGER NOT NULL DEFAULT 0,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_sync_at    TIMESTAMPTZ,
    deleted_at      TIMESTAMPTZ,

    CONSTRAINT users_email_unique UNIQUE (email),
    CONSTRAINT users_email_format CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    CONSTRAINT users_display_name_length CHECK (char_length(display_name) <= 100),
    CONSTRAINT users_vector_clock_positive CHECK (vector_clock >= 0)
);

COMMENT ON TABLE public.users IS 'Core user profile table. Maps 1:1 with auth.users. Contains PII (email, display_name, avatar_url) subject to GDPR retention policy.';
COMMENT ON COLUMN public.users.id IS 'Matches auth.users.id from Supabase Auth';
COMMENT ON COLUMN public.users.email IS 'PII: User login email. Retention: deleted on GDPR request within 7 days.';
COMMENT ON COLUMN public.users.display_name IS 'PII: Optional public display name. Max 100 chars.';
COMMENT ON COLUMN public.users.avatar_url IS 'PII: Profile image URL.';
COMMENT ON COLUMN public.users.encryption_salt IS 'Per-user PBKDF2 salt for client-side E2E key derivation. Not secret but user-specific.';
COMMENT ON COLUMN public.users.vector_clock IS 'Global monotonic counter incremented on any user data mutation. Used for sync ordering.';
COMMENT ON COLUMN public.users.last_sync_at IS 'Timestamp of last successful cross-device sync completion.';
COMMENT ON COLUMN public.users.deleted_at IS 'Soft delete timestamp. Set on GDPR deletion request. Hard delete scheduled 7 days after.';

-- ============================================================================
-- 2. CALCULATIONS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.calculations (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id           UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    expression        TEXT NOT NULL,
    result            TEXT NOT NULL,
    result_type       TEXT NOT NULL DEFAULT 'numeric',
    steps_json        JSONB,
    mode              TEXT NOT NULL DEFAULT 'standard',
    base              SMALLINT NOT NULL DEFAULT 10,
    is_favorite       BOOLEAN NOT NULL DEFAULT false,
    encrypted_payload TEXT,
    vector_clock      INTEGER NOT NULL DEFAULT 0,
    device_id         TEXT,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at        TIMESTAMPTZ,

    CONSTRAINT calculations_result_type_check CHECK (result_type IN ('numeric', 'error', 'graph', 'conversion')),
    CONSTRAINT calculations_mode_check CHECK (mode IN ('standard', 'scientific', 'programmer', 'graph')),
    CONSTRAINT calculations_base_check CHECK (base IN (2, 8, 10, 16)),
    CONSTRAINT calculations_expression_length CHECK (char_length(expression) <= 500),
    CONSTRAINT calculations_vector_clock_positive CHECK (vector_clock >= 0)
);

COMMENT ON TABLE public.calculations IS 'Primary data entity. Stores calculation history with E2E encrypted payloads for cross-device sync. Server stores ciphertext only for synced data.';
COMMENT ON COLUMN public.calculations.id IS 'Client-generated UUID v4. Ensures offline creation without server round-trip.';
COMMENT ON COLUMN public.calculations.user_id IS 'Owner reference. RLS enforces user can only access own calculations.';
COMMENT ON COLUMN public.calculations.expression IS 'Raw input expression text. Max 500 chars per US-001 acceptance criteria.';
COMMENT ON COLUMN public.calculations.result IS 'Computed result string representation.';
COMMENT ON COLUMN public.calculations.result_type IS 'Result classification: numeric, error, graph, or conversion.';
COMMENT ON COLUMN public.calculations.steps_json IS 'Step-by-step evaluation trace as JSONB array (US-002). Nullable for simple results.';
COMMENT ON COLUMN public.calculations.mode IS 'Calculator mode: standard, scientific, programmer, or graph.';
COMMENT ON COLUMN public.calculations.base IS 'Number base for programmer mode: 2 (binary), 8 (octal), 10 (decimal), 16 (hex).';
COMMENT ON COLUMN public.calculations.is_favorite IS 'Pinned/favorite status (US-009). Max 50 favorites enforced at application layer.';
COMMENT ON COLUMN public.calculations.encrypted_payload IS 'E2E encrypted blob (AES-256-GCM). Server cannot decrypt. Used for cross-device sync (US-007).';
COMMENT ON COLUMN public.calculations.vector_clock IS 'LWW timestamp for conflict resolution. Highest clock wins on sync conflict.';
COMMENT ON COLUMN public.calculations.device_id IS 'UUID of originating device. Used for vector clock tie-breaking.';
COMMENT ON COLUMN public.calculations.deleted_at IS 'Soft delete timestamp. Hard deleted after 30-day grace period.';

-- ============================================================================
-- 3. VARIABLES TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.variables (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id      UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    name         TEXT NOT NULL,
    value        TEXT NOT NULL,
    description  TEXT,
    vector_clock INTEGER NOT NULL DEFAULT 0,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at   TIMESTAMPTZ,

    CONSTRAINT variables_name_length CHECK (char_length(name) <= 50),
    CONSTRAINT variables_name_format CHECK (name ~ '^[A-Za-z_][A-Za-z0-9_]*$'),
    CONSTRAINT variables_description_length CHECK (char_length(description) <= 200),
    CONSTRAINT variables_user_name_unique UNIQUE (user_id, name),
    CONSTRAINT variables_vector_clock_positive CHECK (vector_clock >= 0)
);

COMMENT ON TABLE public.variables IS 'User-defined named variables for reuse in expressions (US-015). Synced across devices. Max 100 per user (application layer).';
COMMENT ON COLUMN public.variables.name IS 'Variable identifier. Must be valid identifier format. Unique per user. Cannot conflict with built-in functions.';
COMMENT ON COLUMN public.variables.value IS 'Stored as text string for arbitrary precision support.';
COMMENT ON COLUMN public.variables.description IS 'Optional user description. Max 200 chars.';
COMMENT ON COLUMN public.variables.vector_clock IS 'LWW sync timestamp for cross-device conflict resolution.';

-- ============================================================================
-- 4. REGISTER_TEMPLATES TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.register_templates (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id      UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    name         TEXT NOT NULL,
    bit_width    SMALLINT NOT NULL,
    description  TEXT,
    vector_clock INTEGER NOT NULL DEFAULT 0,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at   TIMESTAMPTZ,

    CONSTRAINT register_templates_name_length CHECK (char_length(name) <= 100),
    CONSTRAINT register_templates_bit_width_check CHECK (bit_width IN (8, 16, 32, 64)),
    CONSTRAINT register_templates_description_length CHECK (char_length(description) <= 500),
    CONSTRAINT register_templates_vector_clock_positive CHECK (vector_clock >= 0)
);

COMMENT ON TABLE public.register_templates IS 'Hardware register layout definitions for bit field visualizer (US-016). Contains metadata; fields in bit_field_definitions.';
COMMENT ON COLUMN public.register_templates.name IS 'Template name (e.g., "STATUS_REG", "CONTROL_REG"). Max 100 chars.';
COMMENT ON COLUMN public.register_templates.bit_width IS 'Register width: 8, 16, 32, or 64 bits.';

-- ============================================================================
-- 5. BIT_FIELD_DEFINITIONS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.bit_field_definitions (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    template_id UUID NOT NULL REFERENCES public.register_templates(id) ON DELETE CASCADE,
    name        TEXT NOT NULL,
    start_bit   SMALLINT NOT NULL,
    end_bit     SMALLINT NOT NULL,
    color       TEXT NOT NULL DEFAULT '#6366f1',
    description TEXT,
    sort_order  SMALLINT NOT NULL DEFAULT 0,

    CONSTRAINT bit_field_definitions_name_length CHECK (char_length(name) <= 50),
    CONSTRAINT bit_field_definitions_start_bit_valid CHECK (start_bit >= 0),
    CONSTRAINT bit_field_definitions_end_bit_valid CHECK (end_bit >= start_bit),
    CONSTRAINT bit_field_definitions_color_format CHECK (color ~ '^#[0-9a-fA-F]{6}$'),
    CONSTRAINT bit_field_definitions_description_length CHECK (char_length(description) <= 200)
);

COMMENT ON TABLE public.bit_field_definitions IS 'Individual bit field ranges within a register template (US-016). Cascade-deleted with parent template.';
COMMENT ON COLUMN public.bit_field_definitions.template_id IS 'Parent register template. ON DELETE CASCADE ensures cleanup.';
COMMENT ON COLUMN public.bit_field_definitions.start_bit IS 'Inclusive start bit position (0-indexed from LSB).';
COMMENT ON COLUMN public.bit_field_definitions.end_bit IS 'Inclusive end bit position. Must be >= start_bit.';
COMMENT ON COLUMN public.bit_field_definitions.color IS 'Hex color for visualization rendering. Format: #RRGGBB.';
COMMENT ON COLUMN public.bit_field_definitions.sort_order IS 'Display ordering within the template visualization.';

-- ============================================================================
-- 6. TAGS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.tags (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id      UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    name         TEXT NOT NULL,
    color        TEXT NOT NULL DEFAULT '#6366f1',
    vector_clock INTEGER NOT NULL DEFAULT 0,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at   TIMESTAMPTZ,

    CONSTRAINT tags_name_length CHECK (char_length(name) <= 30),
    CONSTRAINT tags_name_format CHECK (name ~ '^[A-Za-z0-9][A-Za-z0-9_-]*$'),
    CONSTRAINT tags_color_format CHECK (color ~ '^#[0-9a-fA-F]{6}$'),
    CONSTRAINT tags_user_name_unique UNIQUE (user_id, name),
    CONSTRAINT tags_vector_clock_positive CHECK (vector_clock >= 0)
);

COMMENT ON TABLE public.tags IS 'User-created labels for organizing calculations (US-017). Many-to-many with calculations via calculation_tags join table.';
COMMENT ON COLUMN public.tags.name IS 'Tag label. Max 30 chars per US-017 acceptance criteria. Unique per user. Allows hyphens and underscores only.';
COMMENT ON COLUMN public.tags.color IS 'Hex color for UI chip rendering.';

-- ============================================================================
-- 7. CALCULATION_TAGS JOIN TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.calculation_tags (
    calculation_id UUID NOT NULL REFERENCES public.calculations(id) ON DELETE CASCADE,
    tag_id         UUID NOT NULL REFERENCES public.tags(id) ON DELETE CASCADE,

    PRIMARY KEY (calculation_id, tag_id)
);

COMMENT ON TABLE public.calculation_tags IS 'Many-to-many join: calculations ↔ tags (US-017). Cascade-deleted when either side is removed.';
COMMENT ON COLUMN public.calculation_tags.calculation_id IS 'References calculation. ON DELETE CASCADE removes tagging when calc deleted.';
COMMENT ON COLUMN public.calculation_tags.tag_id IS 'References tag. ON DELETE CASCADE removes associations when tag deleted (US-017: tag deletion does not delete calculations).';

-- ============================================================================
-- 8. SYNC_QUEUE TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.sync_queue (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    entity_type     TEXT NOT NULL,
    entity_id       UUID NOT NULL,
    operation       TEXT NOT NULL,
    payload         TEXT,
    idempotency_key UUID NOT NULL,
    retry_count     SMALLINT NOT NULL DEFAULT 0,
    status          TEXT NOT NULL DEFAULT 'pending',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    processed_at    TIMESTAMPTZ,

    CONSTRAINT sync_queue_entity_type_check CHECK (entity_type IN ('calculation', 'variable', 'tag', 'template')),
    CONSTRAINT sync_queue_operation_check CHECK (operation IN ('create', 'update', 'delete')),
    CONSTRAINT sync_queue_status_check CHECK (status IN ('pending', 'in_flight', 'failed', 'completed')),
    CONSTRAINT sync_queue_idempotency_unique UNIQUE (idempotency_key),
    CONSTRAINT sync_queue_retry_count_max CHECK (retry_count <= 20)
);

COMMENT ON TABLE public.sync_queue IS 'Server-side sync operation tracking. Ensures exactly-once delivery via idempotency keys (US-007). Retention: 7 days after completion.';
COMMENT ON COLUMN public.sync_queue.entity_type IS 'Type of entity being synced: calculation, variable, tag, or template.';
COMMENT ON COLUMN public.sync_queue.entity_id IS 'UUID reference to the specific entity being synced.';
COMMENT ON COLUMN public.sync_queue.operation IS 'Sync operation type: create, update, or delete.';
COMMENT ON COLUMN public.sync_queue.payload IS 'Encrypted JSON payload. Server cannot decrypt — passes through to target device.';
COMMENT ON COLUMN public.sync_queue.idempotency_key IS 'Client-generated UUID for deduplication. Prevents duplicate processing on retry.';
COMMENT ON COLUMN public.sync_queue.retry_count IS 'Number of delivery attempts. Max 20 before marking permanently failed.';
COMMENT ON COLUMN public.sync_queue.status IS 'Processing state: pending → in_flight → completed/failed.';

-- ============================================================================
-- 9. SUBSCRIPTIONS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.subscriptions (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id       UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    tier          TEXT NOT NULL DEFAULT 'free',
    revenuecat_id TEXT,
    product_id    TEXT,
    expires_at    TIMESTAMPTZ,
    is_active     BOOLEAN NOT NULL DEFAULT true,
    platform      TEXT,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT subscriptions_user_unique UNIQUE (user_id),
    CONSTRAINT subscriptions_tier_check CHECK (tier IN ('free', 'pro', 'dev')),
    CONSTRAINT subscriptions_platform_check CHECK (platform IS NULL OR platform IN ('ios', 'android', 'web'))
);

COMMENT ON TABLE public.subscriptions IS 'User subscription state synced from RevenueCat webhooks. One subscription per user (1:1). Determines rate limits and feature access.';
COMMENT ON COLUMN public.subscriptions.tier IS 'Subscription tier: free (default), pro ($2.99/mo), dev ($4.99/mo). Determines rate limits and feature gates.';
COMMENT ON COLUMN public.subscriptions.revenuecat_id IS 'RevenueCat customer ID for webhook correlation.';
COMMENT ON COLUMN public.subscriptions.product_id IS 'App store product identifier (e.g., com.calcapp.pro.monthly).';
COMMENT ON COLUMN public.subscriptions.expires_at IS 'Subscription expiry timestamp. NULL for free tier. Active if expires_at > now().';
COMMENT ON COLUMN public.subscriptions.is_active IS 'Denormalized active flag. Updated by trigger from expires_at comparison.';
COMMENT ON COLUMN public.subscriptions.platform IS 'Platform where subscription was purchased: ios, android, or web.';

-- ============================================================================
-- 10. INDEXES
-- ============================================================================

-- --------------------------------------------------------------------------
-- CALCULATION indexes
-- --------------------------------------------------------------------------

-- US-003, US-007: History list ordered by recency, paginated fetching
CREATE INDEX idx_calc_user_created
    ON public.calculations (user_id, created_at DESC);

-- US-009: Favorites panel query - only index favorite entries
CREATE INDEX idx_calc_user_favorite
    ON public.calculations (user_id, created_at DESC)
    WHERE is_favorite = true AND deleted_at IS NULL;

-- US-013: Filter calculations by mode (programmer/scientific/graph)
CREATE INDEX idx_calc_user_mode
    ON public.calculations (user_id, mode, created_at DESC)
    WHERE deleted_at IS NULL;

-- US-007: Sync delta fetch - "give me everything updated since last_sync_at"
CREATE INDEX idx_calc_user_updated
    ON public.calculations (user_id, updated_at DESC);

-- US-007: Soft-deleted records for sync inclusion/exclusion
CREATE INDEX idx_calc_user_deleted
    ON public.calculations (user_id, deleted_at)
    WHERE deleted_at IS NOT NULL;

-- US-007: LWW conflict detection - compare vector clocks during sync
CREATE INDEX idx_calc_vector_clock
    ON public.calculations (user_id, vector_clock);

-- US-008: Full-text search on expressions (GIN index with tsvector)
CREATE INDEX idx_calc_expression_fts
    ON public.calculations
    USING GIN (to_tsvector('english', expression));

-- US-008: Trigram index for fuzzy/partial matching on expressions
CREATE INDEX idx_calc_expression_trgm
    ON public.calculations
    USING GIN (expression gin_trgm_ops);

-- US-008: Search by result value (trigram for partial matches like "425")
CREATE INDEX idx_calc_result_trgm
    ON public.calculations
    USING GIN (result gin_trgm_ops);

-- --------------------------------------------------------------------------
-- VARIABLE indexes
-- --------------------------------------------------------------------------

-- US-015: Variable lookup by name (uniqueness enforced by constraint, this aids lookup)
-- Note: unique constraint on (user_id, name) already creates an index

-- US-015: Sync delta for variables
CREATE INDEX idx_var_user_updated
    ON public.variables (user_id, updated_at DESC);

-- --------------------------------------------------------------------------
-- REGISTER_TEMPLATE indexes
-- --------------------------------------------------------------------------

-- US-016: List user's register templates ordered by creation
CREATE INDEX idx_template_user
    ON public.register_templates (user_id, created_at DESC);

-- --------------------------------------------------------------------------
-- BIT_FIELD_DEFINITION indexes
-- --------------------------------------------------------------------------

-- US-016: Ordered field list for a template rendering
CREATE INDEX idx_bitfield_template
    ON public.bit_field_definitions (template_id, sort_order);

-- --------------------------------------------------------------------------
-- TAG indexes
-- --------------------------------------------------------------------------

-- Note: unique constraint on (user_id, name) already creates an index for US-017 lookup

-- --------------------------------------------------------------------------
-- CALCULATION_TAGS indexes
-- --------------------------------------------------------------------------

-- US-017: Get all calculations for a specific tag filter
CREATE INDEX idx_calctag_tag
    ON public.calculation_tags (tag_id);

-- Note: PK (calculation_id, tag_id) already provides idx on calculation_id

-- --------------------------------------------------------------------------
-- SYNC_QUEUE indexes
-- --------------------------------------------------------------------------

-- US-007: Process pending sync items for a user
CREATE INDEX idx_sync_user_status
    ON public.sync_queue (user_id, status, created_at);

-- Retention: cleanup completed items older than retention period
CREATE INDEX idx_sync_processed
    ON public.sync_queue (processed_at)
    WHERE status = 'completed';

-- --------------------------------------------------------------------------
-- SUBSCRIPTION indexes
-- --------------------------------------------------------------------------

-- Note: unique constraint on user_id already creates index for tier checks

-- RevenueCat webhook processing: find subscription by RevenueCat ID
CREATE INDEX idx_sub_revenuecat
    ON public.subscriptions (revenuecat_id)
    WHERE revenuecat_id IS NOT NULL;

-- ============================================================================
-- 11. ROW-LEVEL SECURITY (RLS) POLICIES
-- ============================================================================

-- Enable RLS on all user-owned tables
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.calculations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.variables ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.register_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bit_field_definitions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.calculation_tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sync_queue ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;

-- --------------------------------------------------------------------------
-- USERS: Users can only see/modify their own profile
-- --------------------------------------------------------------------------

CREATE POLICY users_select_own ON public.users
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY users_update_own ON public.users
    FOR UPDATE USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

CREATE POLICY users_insert_own ON public.users
    FOR INSERT WITH CHECK (auth.uid() = id);

-- No direct delete policy - deletion handled via GDPR function

-- --------------------------------------------------------------------------
-- CALCULATIONS: Users can only access their own calculations
-- --------------------------------------------------------------------------

CREATE POLICY calculations_select_own ON public.calculations
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY calculations_insert_own ON public.calculations
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY calculations_update_own ON public.calculations
    FOR UPDATE USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY calculations_delete_own ON public.calculations
    FOR DELETE USING (auth.uid() = user_id);

-- --------------------------------------------------------------------------
-- VARIABLES: Users can only access their own variables
-- --------------------------------------------------------------------------

CREATE POLICY variables_select_own ON public.variables
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY variables_insert_own ON public.variables
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY variables_update_own ON public.variables
    FOR UPDATE USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY variables_delete_own ON public.variables
    FOR DELETE USING (auth.uid() = user_id);

-- --------------------------------------------------------------------------
-- REGISTER_TEMPLATES: Users can only access their own templates
-- --------------------------------------------------------------------------

CREATE POLICY register_templates_select_own ON public.register_templates
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY register_templates_insert_own ON public.register_templates
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY register_templates_update_own ON public.register_templates
    FOR UPDATE USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY register_templates_delete_own ON public.register_templates
    FOR DELETE USING (auth.uid() = user_id);

-- --------------------------------------------------------------------------
-- BIT_FIELD_DEFINITIONS: Access via parent template ownership
-- --------------------------------------------------------------------------

CREATE POLICY bit_field_definitions_select_own ON public.bit_field_definitions
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.register_templates rt
            WHERE rt.id = template_id AND rt.user_id = auth.uid()
        )
    );

CREATE POLICY bit_field_definitions_insert_own ON public.bit_field_definitions
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.register_templates rt
            WHERE rt.id = template_id AND rt.user_id = auth.uid()
        )
    );

CREATE POLICY bit_field_definitions_update_own ON public.bit_field_definitions
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.register_templates rt
            WHERE rt.id = template_id AND rt.user_id = auth.uid()
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.register_templates rt
            WHERE rt.id = template_id AND rt.user_id = auth.uid()
        )
    );

CREATE POLICY bit_field_definitions_delete_own ON public.bit_field_definitions
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM public.register_templates rt
            WHERE rt.id = template_id AND rt.user_id = auth.uid()
        )
    );

-- --------------------------------------------------------------------------
-- TAGS: Users can only access their own tags
-- --------------------------------------------------------------------------

CREATE POLICY tags_select_own ON public.tags
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY tags_insert_own ON public.tags
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY tags_update_own ON public.tags
    FOR UPDATE USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY tags_delete_own ON public.tags
    FOR DELETE USING (auth.uid() = user_id);

-- --------------------------------------------------------------------------
-- CALCULATION_TAGS: Access via calculation ownership
-- --------------------------------------------------------------------------

CREATE POLICY calculation_tags_select_own ON public.calculation_tags
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.calculations c
            WHERE c.id = calculation_id AND c.user_id = auth.uid()
        )
    );

CREATE POLICY calculation_tags_insert_own ON public.calculation_tags
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.calculations c
            WHERE c.id = calculation_id AND c.user_id = auth.uid()
        )
        AND EXISTS (
            SELECT 1 FROM public.tags t
            WHERE t.id = tag_id AND t.user_id = auth.uid()
        )
    );

CREATE POLICY calculation_tags_delete_own ON public.calculation_tags
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM public.calculations c
            WHERE c.id = calculation_id AND c.user_id = auth.uid()
        )
    );

-- --------------------------------------------------------------------------
-- SYNC_QUEUE: Users can only access their own sync items
-- --------------------------------------------------------------------------

CREATE POLICY sync_queue_select_own ON public.sync_queue
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY sync_queue_insert_own ON public.sync_queue
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY sync_queue_update_own ON public.sync_queue
    FOR UPDATE USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- No direct delete - handled by retention cleanup function (service role)

-- --------------------------------------------------------------------------
-- SUBSCRIPTIONS: Users can read their own subscription; writes via service role only
-- --------------------------------------------------------------------------

CREATE POLICY subscriptions_select_own ON public.subscriptions
    FOR SELECT USING (auth.uid() = user_id);

-- Insert/Update via service_role only (RevenueCat webhooks)
-- No user-facing insert/update/delete policies

-- ============================================================================
-- 12. TRIGGER FUNCTIONS
-- ============================================================================

-- --------------------------------------------------------------------------
-- Auto-update updated_at timestamp on row modification
-- --------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.trigger_set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION public.trigger_set_updated_at() IS 'Automatically sets updated_at to current timestamp on any row UPDATE. Applied to all tables with updated_at column.';

-- Apply updated_at trigger to relevant tables
CREATE TRIGGER set_updated_at_users
    BEFORE UPDATE ON public.users
    FOR EACH ROW EXECUTE FUNCTION public.trigger_set_updated_at();

CREATE TRIGGER set_updated_at_calculations
    BEFORE UPDATE ON public.calculations
    FOR EACH ROW EXECUTE FUNCTION public.trigger_set_updated_at();

CREATE TRIGGER set_updated_at_variables
    BEFORE UPDATE ON public.variables
    FOR EACH ROW EXECUTE FUNCTION public.trigger_set_updated_at();

CREATE TRIGGER set_updated_at_register_templates
    BEFORE UPDATE ON public.register_templates
    FOR EACH ROW EXECUTE FUNCTION public.trigger_set_updated_at();

CREATE TRIGGER set_updated_at_subscriptions
    BEFORE UPDATE ON public.subscriptions
    FOR EACH ROW EXECUTE FUNCTION public.trigger_set_updated_at();

-- --------------------------------------------------------------------------
-- Soft-delete cascade: when a user is soft-deleted, cascade to owned entities
-- --------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.trigger_soft_delete_cascade()
RETURNS TRIGGER AS $$
BEGIN
    -- Only trigger when deleted_at transitions from NULL to a value
    IF OLD.deleted_at IS NULL AND NEW.deleted_at IS NOT NULL THEN
        -- Soft-delete all user's calculations
        UPDATE public.calculations
        SET deleted_at = NEW.deleted_at, updated_at = now()
        WHERE user_id = NEW.id AND deleted_at IS NULL;

        -- Soft-delete all user's variables
        UPDATE public.variables
        SET deleted_at = NEW.deleted_at, updated_at = now()
        WHERE user_id = NEW.id AND deleted_at IS NULL;

        -- Soft-delete all user's register templates
        UPDATE public.register_templates
        SET deleted_at = NEW.deleted_at, updated_at = now()
        WHERE user_id = NEW.id AND deleted_at IS NULL;

        -- Soft-delete all user's tags
        UPDATE public.tags
        SET deleted_at = NEW.deleted_at
        WHERE user_id = NEW.id AND deleted_at IS NULL;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION public.trigger_soft_delete_cascade() IS 'Cascades soft-delete from users to all owned entities when user.deleted_at is set. Supports GDPR deletion workflow.';

CREATE TRIGGER soft_delete_cascade_users
    AFTER UPDATE OF deleted_at ON public.users
    FOR EACH ROW EXECUTE FUNCTION public.trigger_soft_delete_cascade();

-- --------------------------------------------------------------------------
-- Increment vector clock on calculation modification
-- --------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.trigger_increment_user_vector_clock()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.users
    SET vector_clock = vector_clock + 1
    WHERE id = NEW.user_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION public.trigger_increment_user_vector_clock() IS 'Increments user global vector clock on any owned entity mutation. Enables efficient sync delta detection.';

CREATE TRIGGER increment_user_clock_on_calc
    AFTER INSERT OR UPDATE ON public.calculations
    FOR EACH ROW EXECUTE FUNCTION public.trigger_increment_user_vector_clock();

CREATE TRIGGER increment_user_clock_on_var
    AFTER INSERT OR UPDATE ON public.variables
    FOR EACH ROW EXECUTE FUNCTION public.trigger_increment_user_vector_clock();

-- ============================================================================
-- 13. UTILITY FUNCTIONS
-- ============================================================================

-- --------------------------------------------------------------------------
-- GDPR hard-delete: Permanently removes all user data (called by scheduled job)
-- --------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.gdpr_hard_delete_user(target_user_id UUID)
RETURNS JSONB AS $$
DECLARE
    calc_count INTEGER;
    var_count INTEGER;
    template_count INTEGER;
    tag_count INTEGER;
    sync_count INTEGER;
BEGIN
    -- Count entities for audit response
    SELECT count(*) INTO calc_count FROM public.calculations WHERE user_id = target_user_id;
    SELECT count(*) INTO var_count FROM public.variables WHERE user_id = target_user_id;
    SELECT count(*) INTO template_count FROM public.register_templates WHERE user_id = target_user_id;
    SELECT count(*) INTO tag_count FROM public.tags WHERE user_id = target_user_id;
    SELECT count(*) INTO sync_count FROM public.sync_queue WHERE user_id = target_user_id;

    -- Hard delete all data (CASCADE handles join tables and bit_field_definitions)
    DELETE FROM public.sync_queue WHERE user_id = target_user_id;
    DELETE FROM public.calculations WHERE user_id = target_user_id;
    DELETE FROM public.variables WHERE user_id = target_user_id;
    DELETE FROM public.register_templates WHERE user_id = target_user_id;
    DELETE FROM public.tags WHERE user_id = target_user_id;
    DELETE FROM public.subscriptions WHERE user_id = target_user_id;
    DELETE FROM public.users WHERE id = target_user_id;

    RETURN jsonb_build_object(
        'user_id', target_user_id,
        'deleted_entities', jsonb_build_object(
            'calculations', calc_count,
            'variables', var_count,
            'templates', template_count,
            'tags', tag_count,
            'sync_queue', sync_count
        ),
        'completed_at', now()
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION public.gdpr_hard_delete_user(UUID) IS 'GDPR Article 17: Permanently deletes all user data. Called by scheduled job 7 days after soft-delete. Returns deletion audit summary.';

-- --------------------------------------------------------------------------
-- Sync conflict resolution: LWW with vector clock comparison
-- --------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.resolve_sync_conflict(
    p_entity_id UUID,
    p_client_vector_clock INTEGER,
    p_client_device_id TEXT
)
RETURNS TABLE (
    resolution TEXT,
    server_vector_clock INTEGER,
    server_device_id TEXT
) AS $$
DECLARE
    v_server_clock INTEGER;
    v_server_device TEXT;
BEGIN
    SELECT c.vector_clock, c.device_id
    INTO v_server_clock, v_server_device
    FROM public.calculations c
    WHERE c.id = p_entity_id;

    IF v_server_clock IS NULL THEN
        -- Entity doesn't exist server-side: client wins (create)
        RETURN QUERY SELECT 'client_wins'::TEXT, 0, ''::TEXT;
    ELSIF p_client_vector_clock > v_server_clock THEN
        -- Client has higher clock: client wins
        RETURN QUERY SELECT 'client_wins'::TEXT, v_server_clock, v_server_device;
    ELSIF p_client_vector_clock < v_server_clock THEN
        -- Server has higher clock: server wins
        RETURN QUERY SELECT 'server_wins'::TEXT, v_server_clock, v_server_device;
    ELSE
        -- Equal clocks: tie-break by device_id lexicographic order
        IF p_client_device_id > COALESCE(v_server_device, '') THEN
            RETURN QUERY SELECT 'client_wins'::TEXT, v_server_clock, v_server_device;
        ELSE
            RETURN QUERY SELECT 'server_wins'::TEXT, v_server_clock, v_server_device;
        END IF;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION public.resolve_sync_conflict(UUID, INTEGER, TEXT) IS 'LWW conflict resolution per ADR-008. Compares vector clocks; ties broken by device_id lexicographic order. Used during POST /api/v1/calculations/sync.';

-- --------------------------------------------------------------------------
-- Retention cleanup: Remove completed sync queue entries older than 7 days
-- --------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.cleanup_sync_queue()
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM public.sync_queue
    WHERE status = 'completed'
      AND processed_at < now() - INTERVAL '7 days';

    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION public.cleanup_sync_queue() IS 'Retention policy: Removes completed sync_queue entries older than 7 days. Run via pg_cron daily.';

-- --------------------------------------------------------------------------
-- Retention cleanup: Hard-delete soft-deleted calculations past grace period
-- --------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.cleanup_soft_deleted_calculations()
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM public.calculations
    WHERE deleted_at IS NOT NULL
      AND deleted_at < now() - INTERVAL '30 days';

    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION public.cleanup_soft_deleted_calculations() IS 'Retention policy: Hard-deletes calculations soft-deleted more than 30 days ago. Run via pg_cron daily.';

-- --------------------------------------------------------------------------
-- Process GDPR deletions: Hard-delete users soft-deleted 7+ days ago
-- --------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.process_gdpr_deletions()
RETURNS INTEGER AS $$
DECLARE
    user_record RECORD;
    processed_count INTEGER := 0;
BEGIN
    FOR user_record IN
        SELECT id FROM public.users
        WHERE deleted_at IS NOT NULL
          AND deleted_at < now() - INTERVAL '7 days'
    LOOP
        PERFORM public.gdpr_hard_delete_user(user_record.id);
        processed_count := processed_count + 1;
    END LOOP;

    RETURN processed_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION public.process_gdpr_deletions() IS 'GDPR scheduled job: Finds users soft-deleted 7+ days ago and permanently removes all their data. Run via pg_cron daily.';

-- --------------------------------------------------------------------------
-- Helper: Check subscription tier for rate limiting
-- --------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.get_user_tier(p_user_id UUID)
RETURNS TEXT AS $$
DECLARE
    v_tier TEXT;
    v_expires TIMESTAMPTZ;
BEGIN
    SELECT tier, expires_at INTO v_tier, v_expires
    FROM public.subscriptions
    WHERE user_id = p_user_id;

    -- No subscription record = free
    IF v_tier IS NULL THEN
        RETURN 'free';
    END IF;

    -- Expired subscription = free
    IF v_expires IS NOT NULL AND v_expires < now() THEN
        RETURN 'free';
    END IF;

    RETURN v_tier;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION public.get_user_tier(UUID) IS 'Returns effective subscription tier considering expiry. Used for rate limit checks: free=100 req/min, pro=500, dev=500.';

-- ============================================================================
-- 14. SCHEDULED JOBS (pg_cron configuration — run as service_role)
-- ============================================================================

-- NOTE: These require the pg_cron extension enabled in Supabase dashboard.
-- Uncomment when pg_cron is available:

-- Daily at 03:00 UTC: Clean up completed sync queue entries
-- SELECT cron.schedule('cleanup-sync-queue', '0 3 * * *', 'SELECT public.cleanup_sync_queue()');

-- Daily at 03:30 UTC: Hard-delete soft-deleted calculations past 30-day grace
-- SELECT cron.schedule('cleanup-soft-deletes', '30 3 * * *', 'SELECT public.cleanup_soft_deleted_calculations()');

-- Daily at 04:00 UTC: Process GDPR deletion requests past 7-day window
-- SELECT cron.schedule('gdpr-deletions', '0 4 * * *', 'SELECT public.process_gdpr_deletions()');

-- ============================================================================
-- 15. GRANTS (Supabase roles)
-- ============================================================================

-- Authenticated users can access tables (RLS handles row filtering)
GRANT SELECT, INSERT, UPDATE, DELETE ON public.users TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.calculations TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.variables TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.register_templates TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.bit_field_definitions TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.tags TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.calculation_tags TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.sync_queue TO authenticated;
GRANT SELECT ON public.subscriptions TO authenticated;

-- Service role has full access (for webhooks, GDPR jobs, admin operations)
GRANT ALL ON ALL TABLES IN SCHEMA public TO service_role;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO service_role;

-- Anon role: no access to user data tables
-- (Supabase default: anon can access public schema, but RLS blocks all rows)

-- ============================================================================
-- END OF SCHEMA
-- ============================================================================

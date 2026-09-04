-- ==============================================================================
-- TITANNOVA FIT - SISTEMA DE PLANOS E ASSINATURAS (SUPABASE MIGRATION)
-- Versão: 3.1.0
-- Planos: Grátis (free), Bronze (bronze), Prata (silver), Gold (gold)
-- Arquitetura Segura: RLS Estrito + Funções SECURITY DEFINER + Preservação Total
-- ==============================================================================

-- 1. TABELA DE PLANOS (public.plans)
CREATE TABLE IF NOT EXISTS public.plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    monthly_price NUMERIC(10,2) NOT NULL DEFAULT 0.00,
    annual_price NUMERIC(10,2) NOT NULL DEFAULT 0.00,
    active BOOLEAN NOT NULL DEFAULT true,
    display_order INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2. TABELA DE RECURSOS E LIMITES POR PLANO (public.plan_features)
CREATE TABLE IF NOT EXISTS public.plan_features (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    plan_id UUID NOT NULL REFERENCES public.plans(id) ON DELETE CASCADE,
    feature_code TEXT NOT NULL,
    enabled BOOLEAN NOT NULL DEFAULT true,
    limit_value INTEGER NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_plan_feature UNIQUE (plan_id, feature_code)
);

-- 3. TABELA DE ASSINATURAS DOS USUÁRIOS (public.subscriptions)
CREATE TABLE IF NOT EXISTS public.subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    plan_id UUID NOT NULL REFERENCES public.plans(id),
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'trialing', 'past_due', 'canceled', 'expired')),
    billing_cycle TEXT NOT NULL DEFAULT 'free' CHECK (billing_cycle IN ('monthly', 'annual', 'free')),
    provider TEXT NOT NULL DEFAULT 'manual' CHECK (provider IN ('manual', 'mercadopago', 'stripe', 'app_store', 'play_store')),
    provider_subscription_id TEXT NULL,
    started_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    current_period_start TIMESTAMPTZ NOT NULL DEFAULT now(),
    current_period_end TIMESTAMPTZ NULL,
    canceled_at TIMESTAMPTZ NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Índice parcial para garantir estritamente no máximo 1 assinatura ativa por usuário
CREATE UNIQUE INDEX IF NOT EXISTS idx_subscriptions_user_active 
ON public.subscriptions(user_id) 
WHERE status IN ('active', 'trialing');

-- Índices adicionais para performance de consultas
CREATE INDEX IF NOT EXISTS idx_subscriptions_user_id ON public.subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_plan_id ON public.subscriptions(plan_id);
CREATE INDEX IF NOT EXISTS idx_plan_features_plan_id ON public.plan_features(plan_id);

-- ==============================================================================
-- 4. INSERÇÃO E ATUALIZAÇÃO DOS 4 PLANOS (IDEMPOTENTE)
-- ==============================================================================

INSERT INTO public.plans (code, name, monthly_price, annual_price, active, display_order)
VALUES
    ('free', 'Grátis', 0.00, 0.00, true, 1),
    ('bronze', 'Bronze', 7.90, 69.90, true, 2),
    ('silver', 'Prata', 14.90, 129.90, true, 3),
    ('gold', 'Gold', 24.90, 219.90, true, 4)
ON CONFLICT (code) DO UPDATE SET
    name = EXCLUDED.name,
    monthly_price = EXCLUDED.monthly_price,
    annual_price = EXCLUDED.annual_price,
    active = EXCLUDED.active,
    display_order = EXCLUDED.display_order;

-- ==============================================================================
-- 5. CONFIGURAÇÃO DE RECURSOS (PLAN_FEATURES) PARA CADA PLANO
-- ==============================================================================

DO $$
DECLARE
    v_free_id UUID;
    v_bronze_id UUID;
    v_silver_id UUID;
    v_gold_id UUID;
BEGIN
    SELECT id INTO v_free_id FROM public.plans WHERE code = 'free';
    SELECT id INTO v_bronze_id FROM public.plans WHERE code = 'bronze';
    SELECT id INTO v_silver_id FROM public.plans WHERE code = 'silver';
    SELECT id INTO v_gold_id FROM public.plans WHERE code = 'gold';

    -- Limpar recursos existentes para recadastramento idempotente
    DELETE FROM public.plan_features WHERE plan_id IN (v_free_id, v_bronze_id, v_silver_id, v_gold_id);

    -- ----------------------------------------------------
    -- PLANO GRÁTIS (free)
    -- ----------------------------------------------------
    INSERT INTO public.plan_features (plan_id, feature_code, enabled, limit_value) VALUES
        (v_free_id, 'workout_limit', true, 3),            -- Até 3 fichas de treino
        (v_free_id, 'history_days', true, 30),            -- Histórico de 30 dias
        (v_free_id, 'exercise_library', true, NULL),       -- Biblioteca de exercícios
        (v_free_id, 'gif_demonstrations', true, NULL),     -- GIFs demonstrativos
        (v_free_id, 'sets_and_reps', true, NULL),          -- Séries, cargas e repetições
        (v_free_id, 'rest_timer', true, NULL),             -- Cronômetro
        (v_free_id, 'multi_device_sync', true, NULL),      -- Sincronização entre aparelhos
        (v_free_id, 'beginner_templates', true, NULL),     -- Fichas para iniciantes
        (v_free_id, 'offline_mode', true, NULL),           -- Offline básico
        (v_free_id, 'unlimited_history', false, NULL),
        (v_free_id, 'custom_exercises', false, NULL),
        (v_free_id, 'data_export', false, NULL),
        (v_free_id, 'remove_ads', false, NULL),            -- Com anúncios
        (v_free_id, 'workout_assistant', false, NULL),
        (v_free_id, 'advanced_assistant', false, NULL),
        (v_free_id, 'advanced_charts', false, NULL),
        (v_free_id, 'personal_records', false, NULL),
        (v_free_id, 'advanced_sets', false, NULL),
        (v_free_id, 'progress_photos', false, NULL),
        (v_free_id, 'monthly_report', false, NULL),
        (v_free_id, 'full_reports', false, NULL),
        (v_free_id, 'workout_sharing', false, NULL),
        (v_free_id, 'teacher_student_mode', false, NULL),
        (v_free_id, 'smartwatch_integration', false, NULL),
        (v_free_id, 'priority_support', false, NULL);

    -- ----------------------------------------------------
    -- PLANO BRONZE (bronze)
    -- ----------------------------------------------------
    INSERT INTO public.plan_features (plan_id, feature_code, enabled, limit_value) VALUES
        (v_bronze_id, 'workout_limit', true, NULL),       -- Fichas ilimitadas
        (v_bronze_id, 'history_days', true, NULL),        -- Histórico completo
        (v_bronze_id, 'unlimited_history', true, NULL),
        (v_bronze_id, 'exercise_library', true, NULL),
        (v_bronze_id, 'gif_demonstrations', true, NULL),
        (v_bronze_id, 'sets_and_reps', true, NULL),
        (v_bronze_id, 'rest_timer', true, NULL),
        (v_bronze_id, 'multi_device_sync', true, NULL),
        (v_bronze_id, 'custom_exercises', true, NULL),     -- Exercícios personalizados
        (v_bronze_id, 'beginner_templates', true, NULL),   -- Treinos prontos para iniciantes
        (v_bronze_id, 'data_export', true, NULL),          -- Exportação de dados
        (v_bronze_id, 'offline_mode', true, NULL),         -- Offline completo
        (v_bronze_id, 'remove_ads', true, NULL),           -- Sem anúncios
        (v_bronze_id, 'workout_assistant', false, NULL),
        (v_bronze_id, 'advanced_assistant', false, NULL),
        (v_bronze_id, 'advanced_charts', false, NULL),
        (v_bronze_id, 'personal_records', false, NULL),
        (v_bronze_id, 'advanced_sets', false, NULL),
        (v_bronze_id, 'progress_photos', false, NULL),
        (v_bronze_id, 'monthly_report', false, NULL),
        (v_bronze_id, 'full_reports', false, NULL),
        (v_bronze_id, 'workout_sharing', false, NULL),
        (v_bronze_id, 'teacher_student_mode', false, NULL),
        (v_bronze_id, 'smartwatch_integration', false, NULL),
        (v_bronze_id, 'priority_support', false, NULL);

    -- ----------------------------------------------------
    -- PLANO PRATA (silver) - "Mais Escolhido"
    -- ----------------------------------------------------
    INSERT INTO public.plan_features (plan_id, feature_code, enabled, limit_value) VALUES
        (v_silver_id, 'workout_limit', true, NULL),
        (v_silver_id, 'history_days', true, NULL),
        (v_silver_id, 'unlimited_history', true, NULL),
        (v_silver_id, 'exercise_library', true, NULL),
        (v_silver_id, 'gif_demonstrations', true, NULL),
        (v_silver_id, 'sets_and_reps', true, NULL),
        (v_silver_id, 'rest_timer', true, NULL),
        (v_silver_id, 'multi_device_sync', true, NULL),
        (v_silver_id, 'custom_exercises', true, NULL),
        (v_silver_id, 'beginner_templates', true, NULL),
        (v_silver_id, 'all_level_templates', true, NULL),  -- Treinos para todos os níveis
        (v_silver_id, 'data_export', true, NULL),
        (v_silver_id, 'offline_mode', true, NULL),
        (v_silver_id, 'remove_ads', true, NULL),
        (v_silver_id, 'workout_assistant', true, NULL),    -- Assistente de montagem
        (v_silver_id, 'advanced_charts', true, NULL),      -- Gráficos avançados
        (v_silver_id, 'personal_records', true, NULL),     -- Recordes pessoais (PRs)
        (v_silver_id, 'workout_comparison', true, NULL),   -- Comparação de treinos
        (v_silver_id, 'advanced_sets', true, NULL),        -- Superséries e drop sets
        (v_silver_id, 'progress_photos', true, NULL),      -- Medidas e fotos privadas
        (v_silver_id, 'monthly_report', true, NULL),       -- Relatório mensal
        (v_silver_id, 'advanced_assistant', false, NULL),
        (v_silver_id, 'full_reports', false, NULL),
        (v_silver_id, 'workout_sharing', false, NULL),
        (v_silver_id, 'teacher_student_mode', false, NULL),
        (v_silver_id, 'smartwatch_integration', false, NULL),
        (v_silver_id, 'priority_support', false, NULL);

    -- ----------------------------------------------------
    -- PLANO GOLD (gold)
    -- ----------------------------------------------------
    INSERT INTO public.plan_features (plan_id, feature_code, enabled, limit_value) VALUES
        (v_gold_id, 'workout_limit', true, NULL),
        (v_gold_id, 'history_days', true, NULL),
        (v_gold_id, 'unlimited_history', true, NULL),
        (v_gold_id, 'exercise_library', true, NULL),
        (v_gold_id, 'gif_demonstrations', true, NULL),
        (v_gold_id, 'sets_and_reps', true, NULL),
        (v_gold_id, 'rest_timer', true, NULL),
        (v_gold_id, 'multi_device_sync', true, NULL),
        (v_gold_id, 'custom_exercises', true, NULL),
        (v_gold_id, 'beginner_templates', true, NULL),
        (v_gold_id, 'all_level_templates', true, NULL),
        (v_gold_id, 'data_export', true, NULL),
        (v_gold_id, 'offline_mode', true, NULL),
        (v_gold_id, 'remove_ads', true, NULL),
        (v_gold_id, 'workout_assistant', true, NULL),
        (v_gold_id, 'advanced_charts', true, NULL),
        (v_gold_id, 'personal_records', true, NULL),
        (v_gold_id, 'workout_comparison', true, NULL),
        (v_gold_id, 'advanced_sets', true, NULL),
        (v_gold_id, 'progress_photos', true, NULL),
        (v_gold_id, 'monthly_report', true, NULL),
        (v_gold_id, 'advanced_assistant', true, NULL),     -- Assistente avançado
        (v_gold_id, 'full_reports', true, NULL),           -- Relatórios completos
        (v_gold_id, 'workout_sharing', true, NULL),        -- Compartilhamento de fichas
        (v_gold_id, 'priority_support', true, NULL),       -- Suporte prioritário
        (v_gold_id, 'teacher_student_mode', false, NULL),  -- Em breve (não exibir como ativo)
        (v_gold_id, 'smartwatch_integration', false, NULL);-- Em breve (não exibir como ativo)
END $$;

-- ==============================================================================
-- 6. SEGURANÇA E ROW LEVEL SECURITY (RLS)
-- ==============================================================================

ALTER TABLE public.plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.plan_features ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;

-- 6.1. Policies para public.plans
DROP POLICY IF EXISTS "Permitir leitura pública de planos ativos" ON public.plans;
CREATE POLICY "Permitir leitura pública de planos ativos" 
ON public.plans FOR SELECT 
USING (active = true);

DROP POLICY IF EXISTS "Bloquear escrita pública de planos" ON public.plans;
CREATE POLICY "Bloquear escrita pública de planos" 
ON public.plans FOR ALL 
USING (false)
WITH CHECK (false);

-- 6.2. Policies para public.plan_features
DROP POLICY IF EXISTS "Permitir leitura pública de recursos dos planos" ON public.plan_features;
CREATE POLICY "Permitir leitura pública de recursos dos planos" 
ON public.plan_features FOR SELECT 
USING (true);

DROP POLICY IF EXISTS "Bloquear escrita pública de recursos" ON public.plan_features;
CREATE POLICY "Bloquear escrita pública de recursos" 
ON public.plan_features FOR ALL 
USING (false)
WITH CHECK (false);

-- 6.3. Policies para public.subscriptions
DROP POLICY IF EXISTS "Usuário consulta apenas sua própria assinatura ou admin" ON public.subscriptions;
CREATE POLICY "Usuário consulta apenas sua própria assinatura ou admin" 
ON public.subscriptions FOR SELECT 
USING (
    auth.uid() = user_id 
    OR EXISTS (SELECT 1 FROM public.admin_users au WHERE au.user_id = auth.uid())
);

-- Usuários NUNCA podem inserir, editar ou deletar assinaturas diretamente do frontend
DROP POLICY IF EXISTS "Bloquear inserção direta de assinaturas pelo cliente" ON public.subscriptions;
CREATE POLICY "Bloquear inserção direta de assinaturas pelo cliente" 
ON public.subscriptions FOR INSERT 
WITH CHECK (false);

DROP POLICY IF EXISTS "Bloquear alteração direta de assinaturas pelo cliente" ON public.subscriptions;
CREATE POLICY "Bloquear alteração direta de assinaturas pelo cliente" 
ON public.subscriptions FOR UPDATE 
USING (false)
WITH CHECK (false);

DROP POLICY IF EXISTS "Bloquear exclusão direta de assinaturas pelo cliente" ON public.subscriptions;
CREATE POLICY "Bloquear exclusão direta de assinaturas pelo cliente" 
ON public.subscriptions FOR DELETE 
USING (false);

-- ==============================================================================
-- 7. FUNÇÕES SEGURAS (SECURITY DEFINER)
-- ==============================================================================

-- 7.1. Retornar dados completos e verificados da assinatura do usuário atual
CREATE OR REPLACE FUNCTION public.get_my_subscription()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    v_user_id UUID;
    v_sub RECORD;
    v_features JSONB;
    v_limits JSONB;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('error', 'Usuário não autenticado');
    END IF;

    -- Localizar assinatura ativa ou trialing do usuário
    SELECT 
        s.id AS subscription_id,
        s.status,
        s.billing_cycle,
        s.provider,
        s.current_period_start,
        s.current_period_end,
        p.id AS plan_id,
        p.code AS plan_code,
        p.name AS plan_name,
        p.monthly_price,
        p.annual_price
    INTO v_sub
    FROM public.subscriptions s
    JOIN public.plans p ON p.id = s.plan_id
    WHERE s.user_id = v_user_id
      AND s.status IN ('active', 'trialing')
    ORDER BY s.created_at DESC
    LIMIT 1;

    -- Se não encontrar assinatura ativa, busca o plano Grátis como padrão
    IF v_sub IS NULL THEN
        SELECT 
            NULL::UUID AS subscription_id,
            'active' AS status,
            'free' AS billing_cycle,
            'manual' AS provider,
            now() AS current_period_start,
            NULL::TIMESTAMPTZ AS current_period_end,
            p.id AS plan_id,
            p.code AS plan_code,
            p.name AS plan_name,
            p.monthly_price,
            p.annual_price
        INTO v_sub
        FROM public.plans p
        WHERE p.code = 'free'
        LIMIT 1;
    END IF;

    -- Carregar mapa de features habilitadas
    SELECT jsonb_object_agg(feature_code, enabled)
    INTO v_features
    FROM public.plan_features
    WHERE plan_id = v_sub.plan_id;

    -- Carregar mapa de limites
    SELECT jsonb_object_agg(feature_code, limit_value)
    INTO v_limits
    FROM public.plan_features
    WHERE plan_id = v_sub.plan_id AND limit_value IS NOT NULL;

    RETURN jsonb_build_object(
        'subscription_id', v_sub.subscription_id,
        'plan_code', v_sub.plan_code,
        'plan_name', v_sub.plan_name,
        'status', v_sub.status,
        'billing_cycle', v_sub.billing_cycle,
        'provider', v_sub.provider,
        'current_period_start', v_sub.current_period_start,
        'current_period_end', v_sub.current_period_end,
        'features', COALESCE(v_features, '{}'::JSONB),
        'limits', COALESCE(v_limits, '{}'::JSONB)
    );
END;
$$;

-- 7.2. Validar se o usuário pode criar uma nova ficha de treino
CREATE OR REPLACE FUNCTION public.can_create_workout(p_user_id UUID DEFAULT auth.uid())
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    v_limit INTEGER;
    v_current_count INTEGER;
    v_plan_code TEXT;
BEGIN
    IF p_user_id IS NULL THEN
        RETURN jsonb_build_object('allowed', false, 'message', 'Usuário não identificado.');
    END IF;

    -- Obter código do plano e limite de treinos
    SELECT p.code, pf.limit_value
    INTO v_plan_code, v_limit
    FROM public.subscriptions s
    JOIN public.plans p ON p.id = s.plan_id
    LEFT JOIN public.plan_features pf ON pf.plan_id = p.id AND pf.feature_code = 'workout_limit'
    WHERE s.user_id = p_user_id
      AND s.status IN ('active', 'trialing')
    ORDER BY s.created_at DESC
    LIMIT 1;

    -- Se não encontrar assinatura, assume plano Grátis (limite 3)
    IF v_plan_code IS NULL THEN
        v_plan_code := 'free';
        v_limit := 3;
    END IF;

    -- Se o limite for NULL, o plano é ilimitado (Bronze, Prata, Gold)
    IF v_limit IS NULL THEN
        RETURN jsonb_build_object(
            'allowed', true,
            'plan_code', v_plan_code,
            'current_count', NULL,
            'limit', NULL,
            'message', 'Fichas ilimitadas liberadas no seu plano.'
        );
    END IF;

    -- Contar treinos pertencentes ao usuário na tabela treinos
    SELECT COUNT(*)
    INTO v_current_count
    FROM public.treinos
    WHERE user_id = p_user_id OR usuario_id = p_user_id;

    IF v_current_count < v_limit THEN
        RETURN jsonb_build_object(
            'allowed', true,
            'plan_code', v_plan_code,
            'current_count', v_current_count,
            'limit', v_limit,
            'message', format('Você possui %s de %s fichas utilizadas.', v_current_count, v_limit)
        );
    ELSE
        RETURN jsonb_build_object(
            'allowed', false,
            'plan_code', v_plan_code,
            'current_count', v_current_count,
            'limit', v_limit,
            'message', format('Seu plano %s permite até %s fichas. Faça upgrade para criar fichas ilimitadas.', 
                              CASE WHEN v_plan_code = 'free' THEN 'Grátis' ELSE v_plan_code END, v_limit)
        );
    END IF;
END;
$$;

-- 7.3. Verificar se o usuário possui permissão para um recurso específico
CREATE OR REPLACE FUNCTION public.can_use_feature(p_user_id UUID, p_feature_code TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    v_enabled BOOLEAN;
BEGIN
    IF p_user_id IS NULL OR p_feature_code IS NULL THEN
        RETURN false;
    END IF;

    SELECT pf.enabled
    INTO v_enabled
    FROM public.subscriptions s
    JOIN public.plan_features pf ON pf.plan_id = s.plan_id
    WHERE s.user_id = p_user_id
      AND s.status IN ('active', 'trialing')
      AND pf.feature_code = p_feature_code
    ORDER BY s.created_at DESC
    LIMIT 1;

    -- Se não encontrar assinatura ativa, consulta os recursos do plano Grátis
    IF v_enabled IS NULL THEN
        SELECT pf.enabled
        INTO v_enabled
        FROM public.plans p
        JOIN public.plan_features pf ON pf.plan_id = p.id
        WHERE p.code = 'free'
          AND pf.feature_code = p_feature_code
        LIMIT 1;
    END IF;

    RETURN COALESCE(v_enabled, false);
END;
$$;

-- 7.4. Obter valor limite numérico de um recurso
CREATE OR REPLACE FUNCTION public.get_feature_limit(p_user_id UUID, p_feature_code TEXT)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    v_limit INTEGER;
BEGIN
    SELECT pf.limit_value
    INTO v_limit
    FROM public.subscriptions s
    JOIN public.plan_features pf ON pf.plan_id = s.plan_id
    WHERE s.user_id = p_user_id
      AND s.status IN ('active', 'trialing')
      AND pf.feature_code = p_feature_code
    ORDER BY s.created_at DESC
    LIMIT 1;

    IF v_limit IS NULL THEN
        SELECT pf.limit_value
        INTO v_limit
        FROM public.plans p
        JOIN public.plan_features pf ON pf.plan_id = p.id
        WHERE p.code = 'free'
          AND pf.feature_code = p_feature_code
        LIMIT 1;
    END IF;

    RETURN v_limit;
END;
$$;

-- ==============================================================================
-- 8. TRIGGER DE CRIAÇÃO AUTOMÁTICA DE ASSINATURA GRATUITA (NOVAS CONTAS)
-- ==============================================================================

CREATE OR REPLACE FUNCTION public.handle_new_user_subscription()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    v_free_plan_id UUID;
BEGIN
    -- Localizar ID do plano Grátis
    SELECT id INTO v_free_plan_id FROM public.plans WHERE code = 'free' LIMIT 1;

    IF v_free_plan_id IS NOT NULL THEN
        -- Criar assinatura gratuita inicial caso não exista
        INSERT INTO public.subscriptions (
            user_id,
            plan_id,
            status,
            billing_cycle,
            provider,
            started_at,
            current_period_start
        )
        VALUES (
            NEW.id,
            v_free_plan_id,
            'active',
            'free',
            'manual',
            now(),
            now()
        )
        ON CONFLICT DO NOTHING;
    END IF;

    RETURN NEW;
END;
$$;

-- Vincular trigger à tabela auth.users se ela existir
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'auth' AND tablename = 'users') THEN
        DROP TRIGGER IF EXISTS trg_on_auth_user_created_subscription ON auth.users;
        CREATE TRIGGER trg_on_auth_user_created_subscription
        AFTER INSERT ON auth.users
        FOR EACH ROW
        EXECUTE FUNCTION public.handle_new_user_subscription();
    END IF;
END $$;

-- ==============================================================================
-- 9. MIGRAÇÃO SEGURA PARA CONTAS EXISTENTES (BACKFILL SEM DUPLICAÇÕES)
-- ==============================================================================

DO $$
DECLARE
    v_free_plan_id UUID;
    v_migrated_count INTEGER := 0;
BEGIN
    SELECT id INTO v_free_plan_id FROM public.plans WHERE code = 'free' LIMIT 1;

    IF v_free_plan_id IS NOT NULL THEN
        -- Associar plano Grátis a usuários em auth.users sem assinatura ativa
        INSERT INTO public.subscriptions (user_id, plan_id, status, billing_cycle, provider, started_at, current_period_start)
        SELECT 
            u.id, 
            v_free_plan_id, 
            'active', 
            'free', 
            'manual', 
            COALESCE(u.created_at, now()), 
            now()
        FROM auth.users u
        WHERE NOT EXISTS (
            SELECT 1 
            FROM public.subscriptions s 
            WHERE s.user_id = u.id AND s.status IN ('active', 'trialing')
        )
        ON CONFLICT DO NOTHING;

        GET DIAGNOSTICS v_migrated_count = ROW_COUNT;
        RAISE NOTICE 'Migração de assinaturas concluída. Usuários vinculados ao plano Grátis: %', v_migrated_count;
    END IF;
END $$;

-- Conceder permissões de execução para usuários autenticados e anônimos nas funções públicas
GRANT EXECUTE ON FUNCTION public.get_my_subscription() TO authenticated;
GRANT EXECUTE ON FUNCTION public.can_create_workout(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.can_use_feature(UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_feature_limit(UUID, TEXT) TO authenticated;

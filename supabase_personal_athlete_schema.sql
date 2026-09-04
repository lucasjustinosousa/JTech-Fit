-- ==============================================================================
-- TITANNOVA FIT - MODO ATLETA E MODO PERSONAL TRAINER (SUPABASE MIGRATION)
-- Versão: 3.3.0
-- Tipos de Usuário: Atleta ('athlete'), Personal ('trainer'), Admin ('admin')
-- Independência de Planos: free, bronze, silver, gold
-- ==============================================================================

-- 1. EXTENSÃO DA TABELA DE PERFIS (public.profiles)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL DEFAULT 'Atleta TitanNova',
    email TEXT NOT NULL DEFAULT '',
    avatar_url TEXT,
    account_type TEXT NOT NULL DEFAULT 'athlete' CHECK (account_type IN ('athlete', 'trainer', 'admin')),
    phone TEXT,
    birth_date DATE,
    goal TEXT,
    experience_level TEXT,
    active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Garantir que colunas adicionais existam se a tabela já tiver sido criada anteriormente
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='profiles' AND column_name='name') THEN
        ALTER TABLE public.profiles ADD COLUMN name TEXT NOT NULL DEFAULT 'Atleta TitanNova';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='profiles' AND column_name='account_type') THEN
        ALTER TABLE public.profiles ADD COLUMN account_type TEXT NOT NULL DEFAULT 'athlete' CHECK (account_type IN ('athlete', 'trainer', 'admin'));
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='profiles' AND column_name='phone') THEN
        ALTER TABLE public.profiles ADD COLUMN phone TEXT;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='profiles' AND column_name='birth_date') THEN
        ALTER TABLE public.profiles ADD COLUMN birth_date DATE;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='profiles' AND column_name='goal') THEN
        ALTER TABLE public.profiles ADD COLUMN goal TEXT;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='profiles' AND column_name='experience_level') THEN
        ALTER TABLE public.profiles ADD COLUMN experience_level TEXT;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='profiles' AND column_name='active') THEN
        ALTER TABLE public.profiles ADD COLUMN active BOOLEAN NOT NULL DEFAULT true;
    END IF;
END $$;

-- 2. TABELA DE PERFIL DE PERSONAL TRAINER (public.trainer_profiles)
CREATE TABLE IF NOT EXISTS public.trainer_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    professional_name TEXT NOT NULL,
    biography TEXT,
    cref_number TEXT,
    cref_state TEXT,
    verification_status TEXT NOT NULL DEFAULT 'not_submitted' CHECK (verification_status IN ('not_submitted', 'pending', 'approved', 'rejected')),
    specialties TEXT[] DEFAULT '{}',
    city TEXT,
    state TEXT,
    maximum_students INTEGER DEFAULT 2,
    admin_verification_notes TEXT,
    verified_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_trainer_profile_user UNIQUE (user_id)
);

-- 3. TABELA DE VÍNCULO PERSONAL TRAINER & ATLETA (public.trainer_athletes)
CREATE TABLE IF NOT EXISTS public.trainer_athletes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trainer_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    athlete_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'invited' CHECK (status IN ('invited', 'active', 'rejected', 'removed', 'blocked')),
    invited_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    accepted_at TIMESTAMPTZ,
    removed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_trainer_athlete UNIQUE (trainer_id, athlete_id)
);

-- 4. TABELA DE CONVITES DO PERSONAL (public.trainer_invites)
CREATE TABLE IF NOT EXISTS public.trainer_invites (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trainer_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    athlete_email TEXT,
    token_hash TEXT NOT NULL UNIQUE,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'expired', 'canceled')),
    expires_at TIMESTAMPTZ NOT NULL,
    maximum_uses INTEGER NOT NULL DEFAULT 1,
    used_count INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 5. TABELA DE ATRIBUIÇÃO DE TREINOS (public.workout_assignments)
CREATE TABLE IF NOT EXISTS public.workout_assignments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trainer_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    athlete_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    workout_id TEXT NOT NULL,
    workout_data JSONB NOT NULL,
    status TEXT NOT NULL DEFAULT 'sent' CHECK (status IN ('draft', 'sent', 'accepted', 'active', 'completed', 'canceled')),
    starts_at TIMESTAMPTZ,
    ends_at TIMESTAMPTZ,
    trainer_notes TEXT,
    athlete_notes TEXT,
    assigned_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    accepted_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 6. TABELA DE COMENTÁRIOS ESTRUTURADOS DE TREINO (public.workout_assignment_comments)
CREATE TABLE IF NOT EXISTS public.workout_assignment_comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    assignment_id UUID NOT NULL REFERENCES public.workout_assignments(id) ON DELETE CASCADE,
    author_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    comment TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 7. TABELA DE LOGS DE AUDITORIA (public.audit_logs)
CREATE TABLE IF NOT EXISTS public.audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    actor_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    action TEXT NOT NULL,
    resource_type TEXT NOT NULL,
    resource_id TEXT,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Índices de performance
CREATE INDEX IF NOT EXISTS idx_trainer_athletes_trainer ON public.trainer_athletes(trainer_id);
CREATE INDEX IF NOT EXISTS idx_trainer_athletes_athlete ON public.trainer_athletes(athlete_id);
CREATE INDEX IF NOT EXISTS idx_trainer_athletes_status ON public.trainer_athletes(status);
CREATE INDEX IF NOT EXISTS idx_trainer_invites_hash ON public.trainer_invites(token_hash);
CREATE INDEX IF NOT EXISTS idx_workout_assignments_athlete ON public.workout_assignments(athlete_id);
CREATE INDEX IF NOT EXISTS idx_workout_assignments_trainer ON public.workout_assignments(trainer_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_actor ON public.audit_logs(actor_user_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_action ON public.audit_logs(action);

-- ==============================================================================
-- 8. SEGURANÇA E ROW LEVEL SECURITY (RLS)
-- ==============================================================================

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trainer_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trainer_athletes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trainer_invites ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workout_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workout_assignment_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

-- 8.1. Policies para public.profiles
DROP POLICY IF EXISTS "Usuário consulta seu próprio perfil ou perfis vinculados" ON public.profiles;
CREATE POLICY "Usuário consulta seu próprio perfil ou perfis vinculados" 
ON public.profiles FOR SELECT 
USING (
    auth.uid() = id 
    OR EXISTS (
        SELECT 1 FROM public.trainer_athletes ta 
        WHERE (ta.trainer_id = auth.uid() AND ta.athlete_id = public.profiles.id AND ta.status = 'active')
           OR (ta.athlete_id = auth.uid() AND ta.trainer_id = public.profiles.id AND ta.status = 'active')
    )
    OR EXISTS (SELECT 1 FROM public.admin_users au WHERE au.user_id = auth.uid())
);

DROP POLICY IF EXISTS "Usuário edita seu próprio perfil" ON public.profiles;
CREATE POLICY "Usuário edita seu próprio perfil" 
ON public.profiles FOR UPDATE 
USING (auth.uid() = id)
WITH CHECK (
    auth.uid() = id 
    -- Não permitir que o próprio usuário se transforme em admin diretamente
    AND (account_type <> 'admin' OR EXISTS (SELECT 1 FROM public.admin_users au WHERE au.user_id = auth.uid()))
);

DROP POLICY IF EXISTS "Usuário insere seu próprio perfil" ON public.profiles;
CREATE POLICY "Usuário insere seu próprio perfil" 
ON public.profiles FOR INSERT 
WITH CHECK (
    auth.uid() = id 
    AND (account_type <> 'admin' OR EXISTS (SELECT 1 FROM public.admin_users au WHERE au.user_id = auth.uid()))
);

-- 8.2. Policies para public.trainer_profiles
DROP POLICY IF EXISTS "Leitura de perfis de personal" ON public.trainer_profiles;
CREATE POLICY "Leitura de perfis de personal" 
ON public.trainer_profiles FOR SELECT 
USING (
    auth.uid() = user_id 
    OR verification_status = 'approved'
    OR EXISTS (
        SELECT 1 FROM public.trainer_athletes ta 
        WHERE ta.athlete_id = auth.uid() AND ta.trainer_id = public.trainer_profiles.user_id
    )
    OR EXISTS (SELECT 1 FROM public.admin_users au WHERE au.user_id = auth.uid())
);

DROP POLICY IF EXISTS "Personal edita seu próprio perfil profissional" ON public.trainer_profiles;
CREATE POLICY "Personal edita seu próprio perfil profissional" 
ON public.trainer_profiles FOR UPDATE 
USING (auth.uid() = user_id)
WITH CHECK (
    auth.uid() = user_id
    -- verification_status só pode ser alterado por administradores
);

DROP POLICY IF EXISTS "Personal insere seu perfil profissional" ON public.trainer_profiles;
CREATE POLICY "Personal insere seu perfil profissional" 
ON public.trainer_profiles FOR INSERT 
WITH CHECK (auth.uid() = user_id);

-- 8.3. Policies para public.trainer_athletes
DROP POLICY IF EXISTS "Personal e Atleta visualizam seus próprios vínculos" ON public.trainer_athletes;
CREATE POLICY "Personal e Atleta visualizam seus próprios vínculos" 
ON public.trainer_athletes FOR SELECT 
USING (
    auth.uid() = trainer_id 
    OR auth.uid() = athlete_id 
    OR EXISTS (SELECT 1 FROM public.admin_users au WHERE au.user_id = auth.uid())
);

-- Bloquear escrita direta sem passar pelas funções de negócio
DROP POLICY IF EXISTS "Bloquear insert direto em trainer_athletes" ON public.trainer_athletes;
CREATE POLICY "Bloquear insert direto em trainer_athletes" 
ON public.trainer_athletes FOR INSERT WITH CHECK (false);

DROP POLICY IF EXISTS "Bloquear update direto em trainer_athletes" ON public.trainer_athletes;
CREATE POLICY "Bloquear update direto em trainer_athletes" 
ON public.trainer_athletes FOR UPDATE USING (false);

-- 8.4. Policies para public.trainer_invites
DROP POLICY IF EXISTS "Personal visualiza seus próprios convites" ON public.trainer_invites;
CREATE POLICY "Personal visualiza seus próprios convites" 
ON public.trainer_invites FOR SELECT 
USING (
    auth.uid() = trainer_id 
    OR EXISTS (SELECT 1 FROM public.admin_users au WHERE au.user_id = auth.uid())
);

-- 8.5. Policies para public.workout_assignments
DROP POLICY IF EXISTS "Personal e Atleta consultam atribuições de treino" ON public.workout_assignments;
CREATE POLICY "Personal e Atleta consultam atribuições de treino" 
ON public.workout_assignments FOR SELECT 
USING (
    auth.uid() = trainer_id 
    OR auth.uid() = athlete_id 
    OR EXISTS (SELECT 1 FROM public.admin_users au WHERE au.user_id = auth.uid())
);

-- 8.6. Policies para public.workout_assignment_comments
DROP POLICY IF EXISTS "Participantes consultam comentários" ON public.workout_assignment_comments;
CREATE POLICY "Participantes consultam comentários" 
ON public.workout_assignment_comments FOR SELECT 
USING (
    EXISTS (
        SELECT 1 FROM public.workout_assignments wa 
        WHERE wa.id = assignment_id AND (wa.trainer_id = auth.uid() OR wa.athlete_id = auth.uid())
    )
    OR EXISTS (SELECT 1 FROM public.admin_users au WHERE au.user_id = auth.uid())
);

DROP POLICY IF EXISTS "Participantes inserem comentários" ON public.workout_assignment_comments;
CREATE POLICY "Participantes inserem comentários" 
ON public.workout_assignment_comments FOR INSERT 
WITH CHECK (
    auth.uid() = author_id 
    AND EXISTS (
        SELECT 1 FROM public.workout_assignments wa 
        WHERE wa.id = assignment_id AND (wa.trainer_id = auth.uid() OR wa.athlete_id = auth.uid())
    )
);

-- ==============================================================================
-- 9. FUNÇÕES SEGURAS (SECURITY DEFINER)
-- ==============================================================================

-- 9.1. Limite de alunos conforme o plano ativo do personal
CREATE OR REPLACE FUNCTION public.get_trainer_student_limit(p_trainer_id UUID)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    v_plan_id TEXT;
BEGIN
    SELECT s.plan_id INTO v_plan_id
    FROM public.subscriptions s
    WHERE s.user_id = p_trainer_id AND s.status IN ('active', 'trialing')
    LIMIT 1;

    v_plan_id := COALESCE(v_plan_id, 'free');

    IF v_plan_id = 'gold' THEN
        RETURN 100;
    ELSIF v_plan_id = 'silver' THEN
        RETURN 30;
    ELSIF v_plan_id = 'bronze' THEN
        RETURN 10;
    ELSE
        RETURN 2; -- Grátis: até 2 alunos ativos
    END IF;
END;
$$;

-- 9.2. Verificar se o personal pode acessar dados do atleta
CREATE OR REPLACE FUNCTION public.can_trainer_access_athlete(p_trainer_id UUID, p_athlete_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.trainer_athletes 
        WHERE trainer_id = p_trainer_id 
          AND athlete_id = p_athlete_id 
          AND status = 'active'
    );
END;
$$;

-- 9.3. Criar Convite Seguro do Personal
CREATE OR REPLACE FUNCTION public.create_trainer_invite(
    p_athlete_email TEXT DEFAULT NULL,
    p_expires_days INT DEFAULT 7
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    v_trainer_id UUID;
    v_student_limit INT;
    v_active_students INT;
    v_raw_token TEXT;
    v_token_hash TEXT;
    v_expires_at TIMESTAMPTZ;
    v_invite_id UUID;
BEGIN
    v_trainer_id := auth.uid();
    IF v_trainer_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Não autenticado');
    END IF;

    -- Validar limite de alunos do personal
    v_student_limit := public.get_trainer_student_limit(v_trainer_id);
    SELECT COUNT(*) INTO v_active_students 
    FROM public.trainer_athletes 
    WHERE trainer_id = v_trainer_id AND status = 'active';

    IF v_active_students >= v_student_limit THEN
        RETURN jsonb_build_object(
            'success', false, 
            'error', format('Limite de alunos atingido (%s/%s). Faça upgrade de plano para adicionar mais alunos.', v_active_students, v_student_limit)
        );
    END IF;

    -- Gerar token aleatório seguro (32 caracteres hexadecimais)
    v_raw_token := encode(gen_random_bytes(16), 'hex');
    v_token_hash := encode(digest(v_raw_token, 'sha256'), 'hex');
    v_expires_at := now() + (COALESCE(p_expires_days, 7) || ' days')::interval;

    INSERT INTO public.trainer_invites (
        trainer_id,
        athlete_email,
        token_hash,
        status,
        expires_at
    )
    VALUES (
        v_trainer_id,
        NULLIF(TRIM(p_athlete_email), ''),
        v_token_hash,
        'pending',
        v_expires_at
    )
    RETURNING id INTO v_invite_id;

    -- Registrar log de auditoria
    INSERT INTO public.audit_logs (actor_user_id, action, resource_type, resource_id, metadata)
    VALUES (v_trainer_id, 'CREATE_INVITE', 'trainer_invite', v_invite_id::text, jsonb_build_object('expires_at', v_expires_at));

    RETURN jsonb_build_object(
        'success', true,
        'invite_token', v_raw_token,
        'expires_at', v_expires_at
    );
END;
$$;

-- 9.4. Consultar Detalhes do Convite (Sem vazar dados sensíveis)
CREATE OR REPLACE FUNCTION public.get_invite_details(p_token TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    v_token_hash TEXT;
    v_inv RECORD;
    v_trainer_profile RECORD;
BEGIN
    IF p_token IS NULL OR TRIM(p_token) = '' THEN
        RETURN jsonb_build_object('valid', false, 'error', 'Convite inválido');
    END IF;

    v_token_hash := encode(digest(p_token, 'sha256'), 'hex');

    SELECT * INTO v_inv 
    FROM public.trainer_invites 
    WHERE token_hash = v_token_hash;

    IF v_inv IS NULL THEN
        RETURN jsonb_build_object('valid', false, 'error', 'Convite não encontrado');
    END IF;

    IF v_inv.status <> 'pending' OR v_inv.expires_at < now() OR v_inv.used_count >= v_inv.maximum_uses THEN
        RETURN jsonb_build_object('valid', false, 'error', 'Este convite já foi utilizado ou expirou');
    END IF;

    -- Buscar informações profissionais do personal
    SELECT tp.professional_name, tp.verification_status, tp.city, tp.state, p.avatar_url
    INTO v_trainer_profile
    FROM public.trainer_profiles tp
    LEFT JOIN public.profiles p ON p.id = tp.user_id
    WHERE tp.user_id = v_inv.trainer_id;

    RETURN jsonb_build_object(
        'valid', true,
        'trainer_id', v_inv.trainer_id,
        'professional_name', COALESCE(v_trainer_profile.professional_name, 'Personal Trainer'),
        'verification_status', COALESCE(v_trainer_profile.verification_status, 'not_submitted'),
        'city', v_trainer_profile.city,
        'state', v_trainer_profile.state,
        'avatar_url', v_trainer_profile.avatar_url,
        'expires_at', v_inv.expires_at
    );
END;
$$;

-- 9.5. Aceitar Convite do Personal
CREATE OR REPLACE FUNCTION public.accept_trainer_invite(p_token TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    v_athlete_id UUID;
    v_token_hash TEXT;
    v_inv RECORD;
    v_rel_id UUID;
BEGIN
    v_athlete_id := auth.uid();
    IF v_athlete_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Faça login para aceitar o convite');
    END IF;

    v_token_hash := encode(digest(p_token, 'sha256'), 'hex');

    SELECT * INTO v_inv 
    FROM public.trainer_invites 
    WHERE token_hash = v_token_hash 
      AND status = 'pending' 
      AND expires_at >= now()
      AND used_count < maximum_uses;

    IF v_inv IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Convite inválido ou expirado');
    END IF;

    IF v_inv.trainer_id = v_athlete_id THEN
        RETURN jsonb_build_object('success', false, 'error', 'Você não pode ser aluno de si mesmo');
    END IF;

    -- Criar ou reativar vínculo
    INSERT INTO public.trainer_athletes (trainer_id, athlete_id, status, accepted_at, updated_at)
    VALUES (v_inv.trainer_id, v_athlete_id, 'active', now(), now())
    ON CONFLICT (trainer_id, athlete_id) DO UPDATE SET
        status = 'active',
        accepted_at = now(),
        removed_at = NULL,
        updated_at = now()
    RETURNING id INTO v_rel_id;

    -- Marcar convite como utilizado
    UPDATE public.trainer_invites
    SET used_count = used_count + 1,
        status = 'accepted'
    WHERE id = v_inv.id;

    -- Registrar auditoria
    INSERT INTO public.audit_logs (actor_user_id, action, resource_type, resource_id, metadata)
    VALUES (v_athlete_id, 'ACCEPT_INVITE', 'trainer_athletes', v_rel_id::text, jsonb_build_object('trainer_id', v_inv.trainer_id));

    RETURN jsonb_build_object(
        'success', true,
        'relationship_id', v_rel_id,
        'message', 'Vínculo estabelecido com sucesso! Seu personal já pode acompanhar seus treinos.'
    );
END;
$$;

-- 9.6. Recusar Convite do Personal
CREATE OR REPLACE FUNCTION public.reject_trainer_invite(p_token TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    v_token_hash TEXT;
BEGIN
    v_token_hash := encode(digest(p_token, 'sha256'), 'hex');

    UPDATE public.trainer_invites
    SET status = 'canceled'
    WHERE token_hash = v_token_hash AND status = 'pending';

    RETURN jsonb_build_object('success', true);
END;
$$;

-- 9.7. Atribuir Treino a um Aluno
CREATE OR REPLACE FUNCTION public.assign_workout_to_athlete(
    p_athlete_id UUID,
    p_workout_id TEXT,
    p_workout_data JSONB,
    p_trainer_notes TEXT DEFAULT NULL,
    p_starts_at TIMESTAMPTZ DEFAULT now(),
    p_ends_at TIMESTAMPTZ DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    v_trainer_id UUID;
    v_assignment_id UUID;
BEGIN
    v_trainer_id := auth.uid();
    IF v_trainer_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Não autenticado');
    END IF;

    -- Validar vínculo ativo
    IF NOT EXISTS (
        SELECT 1 FROM public.trainer_athletes 
        WHERE trainer_id = v_trainer_id AND athlete_id = p_athlete_id AND status = 'active'
    ) THEN
        RETURN jsonb_build_object('success', false, 'error', 'Você não possui vínculo ativo com este aluno');
    END IF;

    INSERT INTO public.workout_assignments (
        trainer_id,
        athlete_id,
        workout_id,
        workout_data,
        status,
        starts_at,
        ends_at,
        trainer_notes,
        assigned_at
    )
    VALUES (
        v_trainer_id,
        p_athlete_id,
        p_workout_id,
        p_workout_data,
        'sent',
        COALESCE(p_starts_at, now()),
        p_ends_at,
        p_trainer_notes,
        now()
    )
    RETURNING id INTO v_assignment_id;

    -- Auditoria
    INSERT INTO public.audit_logs (actor_user_id, action, resource_type, resource_id, metadata)
    VALUES (v_trainer_id, 'ASSIGN_WORKOUT', 'workout_assignment', v_assignment_id::text, jsonb_build_object('athlete_id', p_athlete_id, 'workout_id', p_workout_id));

    RETURN jsonb_build_object(
        'success', true,
        'assignment_id', v_assignment_id
    );
END;
$$;

-- 9.8. Encerrar Vínculo entre Personal e Aluno (Preservando treinos e históricos)
CREATE OR REPLACE FUNCTION public.remove_trainer_athlete_relationship(p_target_user_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    v_user_id UUID;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Não autenticado');
    END IF;

    UPDATE public.trainer_athletes
    SET status = 'removed',
        removed_at = now(),
        updated_at = now()
    WHERE (trainer_id = v_user_id AND athlete_id = p_target_user_id)
       OR (athlete_id = v_user_id AND trainer_id = p_target_user_id);

    -- Auditoria
    INSERT INTO public.audit_logs (actor_user_id, action, resource_type, resource_id, metadata)
    VALUES (v_user_id, 'REMOVE_RELATIONSHIP', 'trainer_athletes', p_target_user_id::text, jsonb_build_object('other_user', p_target_user_id));

    RETURN jsonb_build_object('success', true, 'message', 'Vínculo encerrado com sucesso. Os treinos e históricos continuam preservados na conta.');
END;
$$;

-- 9.9. Verificação Administrativa de CREF (Apenas Admins)
CREATE OR REPLACE FUNCTION public.admin_verify_cref(
    p_trainer_id UUID,
    p_new_status TEXT,
    p_notes TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    v_admin_id UUID;
BEGIN
    v_admin_id := auth.uid();
    IF v_admin_id IS NULL OR NOT EXISTS (SELECT 1 FROM public.admin_users WHERE user_id = v_admin_id) THEN
        RETURN jsonb_build_object('success', false, 'error', 'Apenas administradores podem verificar cadastros profissionais');
    END IF;

    IF p_new_status NOT IN ('approved', 'rejected', 'pending') THEN
        RETURN jsonb_build_object('success', false, 'error', 'Status inválido');
    END IF;

    UPDATE public.trainer_profiles
    SET verification_status = p_new_status,
        admin_verification_notes = p_notes,
        verified_at = CASE WHEN p_new_status = 'approved' THEN now() ELSE NULL END,
        updated_at = now()
    WHERE user_id = p_trainer_id;

    -- Auditoria
    INSERT INTO public.audit_logs (actor_user_id, action, resource_type, resource_id, metadata)
    VALUES (v_admin_id, 'VERIFY_CREF', 'trainer_profile', p_trainer_id::text, jsonb_build_object('new_status', p_new_status, 'notes', p_notes));

    RETURN jsonb_build_object('success', true, 'status', p_new_status);
END;
$$;

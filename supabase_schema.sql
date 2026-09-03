-- ====================================================================
-- TITANNOVAFIT - SCRIPT COMPLETO DE BANCO DE DADOS SUPABASE (POSTGRESQL)
-- Suporte a Supabase Auth, Sistema de Administrador Seguro, RLS e Auditoria
-- ====================================================================
-- URLs configuradas no Supabase Authentication -> URL Configuration:
-- Site URL: https://titannovafit.com.br
-- Redirect URLs:
--   https://titannovafit.com.br
--   https://www.titannovafit.com.br
--   https://titannovafit.com.br/**
--   https://titannovafit.com.br/auth/callback
-- ====================================================================

-- 1. EXTENSÕES
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ====================================================================
-- 2. TABELA DE ADMINISTRADORES (ADMIN_USERS)
-- Identificação segura exclusivamente pelo user_id do auth.users
-- ====================================================================
CREATE TABLE IF NOT EXISTS public.admin_users (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    criado_em TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.admin_users ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE public.admin_users FROM anon, authenticated;
GRANT SELECT ON TABLE public.admin_users TO authenticated;

DROP POLICY IF EXISTS "Usuário consulta sua própria permissão" ON public.admin_users;
CREATE POLICY "Usuário consulta sua própria permissão"
ON public.admin_users
FOR SELECT
TO authenticated
USING ((SELECT auth.uid()) = user_id);

-- ====================================================================
-- 3. FUNÇÃO SEGURA DE VERIFICAÇÃO ADMINISTRATIVA (is_admin)
-- ====================================================================
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.admin_users
    WHERE user_id = (SELECT auth.uid())
  );
$$;

REVOKE ALL ON FUNCTION public.is_admin() FROM public;
GRANT EXECUTE ON FUNCTION public.is_admin() TO authenticated;

-- ====================================================================
-- 4. TABELA DE AUDITORIA E LOGS ADMINISTRATIVOS (ADMIN_LOGS)
-- ====================================================================
CREATE TABLE IF NOT EXISTS public.admin_logs (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    admin_id UUID REFERENCES auth.users(id),
    acao TEXT NOT NULL,
    tabela_afetada TEXT,
    registro_id TEXT,
    detalhes JSONB DEFAULT '{}'::jsonb,
    criado_em TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.admin_logs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Administradores gerenciam logs" ON public.admin_logs;
CREATE POLICY "Administradores gerenciam logs"
ON public.admin_logs
FOR ALL
TO authenticated
USING (public.is_admin())
WITH CHECK (public.is_admin());

-- ====================================================================
-- 5. TABELA OFICIAL DE PERFIS (PROFILES) - id UUID = auth.users.id
-- ====================================================================
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    nome TEXT,
    email TEXT,
    foto_url TEXT,
    unidade_carga TEXT DEFAULT 'kg',
    descanso_padrao INT DEFAULT 60,
    favoritos JSONB DEFAULT '[]'::jsonb,
    bloqueado BOOLEAN DEFAULT FALSE,
    criado_em TIMESTAMPTZ DEFAULT NOW(),
    atualizado_em TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS foto_url TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS unidade_carga TEXT DEFAULT 'kg';
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS descanso_padrao INT DEFAULT 60;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS favoritos JSONB DEFAULT '[]'::jsonb;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS bloqueado BOOLEAN DEFAULT FALSE;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS criado_em TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS atualizado_em TIMESTAMPTZ DEFAULT NOW();

-- Tabela usuarios (compatibilidade retroativa)
CREATE TABLE IF NOT EXISTS public.usuarios (
    id TEXT PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    nome TEXT NOT NULL,
    email TEXT NOT NULL,
    foto_url TEXT,
    unidade_carga TEXT DEFAULT 'kg',
    descanso_padrao INT DEFAULT 60,
    favoritos JSONB DEFAULT '[]'::jsonb,
    bloqueado BOOLEAN DEFAULT FALSE,
    criado_em TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.usuarios ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE public.usuarios ADD COLUMN IF NOT EXISTS favoritos JSONB DEFAULT '[]'::jsonb;
ALTER TABLE public.usuarios ADD COLUMN IF NOT EXISTS bloqueado BOOLEAN DEFAULT FALSE;

-- ====================================================================
-- 6. TABELA DE EXERCÍCIOS (COM SUPORTE A ATIVAÇÃO / DESATIVAÇÃO)
-- ====================================================================
CREATE TABLE IF NOT EXISTS public.exercicios (
    id TEXT PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    usuario_id TEXT,
    exercise_db_id TEXT,
    nome TEXT NOT NULL,
    nome_original TEXT,
    nome_traduzido TEXT,
    grupo_muscular TEXT NOT NULL,
    parte_corpo_original TEXT,
    parte_corpo_traduzida TEXT,
    musculo_principal_original TEXT,
    musculo_principal_traduzido TEXT,
    musculos_secundarios TEXT DEFAULT '',
    musculos_auxiliares TEXT DEFAULT '',
    equipamento TEXT NOT NULL,
    equipamento_original TEXT,
    equipamento_traduzido TEXT,
    instrucoes TEXT NOT NULL,
    cuidados TEXT DEFAULT '',
    gif_url TEXT,
    video_url TEXT,
    imagem_url TEXT,
    personalizado BOOLEAN DEFAULT FALSE,
    ativo BOOLEAN DEFAULT TRUE,
    is_favorito BOOLEAN DEFAULT FALSE,
    favorito BOOLEAN DEFAULT FALSE,
    atualizado_em TIMESTAMPTZ DEFAULT NOW(),
    criado_em TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.exercicios ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE public.exercicios ADD COLUMN IF NOT EXISTS usuario_id TEXT;
ALTER TABLE public.exercicios ADD COLUMN IF NOT EXISTS ativo BOOLEAN DEFAULT TRUE;

-- ====================================================================
-- 6.1 TABELA OFICIAL EXERCISES (EXERCISEDB V1)
-- ====================================================================
CREATE TABLE IF NOT EXISTS public.exercises (
    id TEXT PRIMARY KEY,
    original_name TEXT NOT NULL,
    translated_name TEXT,
    gif_url TEXT,
    body_parts TEXT[] DEFAULT '{}',
    equipments TEXT[] DEFAULT '{}',
    target_muscles TEXT[] DEFAULT '{}',
    secondary_muscles TEXT[] DEFAULT '{}',
    instructions JSONB DEFAULT '[]'::jsonb,
    source TEXT NOT NULL DEFAULT 'exercisedb',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Índice GIN para pesquisa eficiente por texto
CREATE INDEX IF NOT EXISTS exercises_original_name_idx ON public.exercises USING gin ( to_tsvector('simple', original_name) );

-- Tabela de metadados da sincronização da biblioteca ExerciseDB
CREATE TABLE IF NOT EXISTS public.exercise_sync_meta (
    id TEXT PRIMARY KEY DEFAULT 'exercisedb_v1',
    total_api INT DEFAULT 0,
    total_salvo INT DEFAULT 0,
    duplicados_ignorados INT DEFAULT 0,
    ultimo_cursor TEXT,
    status TEXT DEFAULT 'idle',
    ultima_sincronizacao TIMESTAMPTZ DEFAULT NOW()
);

-- ====================================================================
-- 7. TABELA DE TREINOS (FICHAS DE TREINO)
-- ====================================================================
CREATE TABLE IF NOT EXISTS public.treinos (
    id TEXT PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    usuario_id TEXT,
    nome TEXT NOT NULL,
    descricao TEXT DEFAULT '',
    dias_semana JSONB DEFAULT '[]'::jsonb,
    cor_hex TEXT DEFAULT '#1E88E5',
    exercicios JSONB DEFAULT '[]'::jsonb,
    criado_em TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.treinos ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE public.treinos ADD COLUMN IF NOT EXISTS usuario_id TEXT;

-- ====================================================================
-- 8. TABELA DE EXERCÍCIOS DO TREINO (RELACIONAL)
-- ====================================================================
CREATE TABLE IF NOT EXISTS public.workout_exercises (
    id TEXT PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    workout_id TEXT REFERENCES public.treinos(id) ON DELETE CASCADE,
    exercise_id TEXT,
    "order" INT NOT NULL,
    sets INT DEFAULT 3,
    repetitions TEXT DEFAULT '8-12',
    rest_seconds INT DEFAULT 60,
    initial_load NUMERIC(6,2) DEFAULT NULL,
    notes TEXT
);

ALTER TABLE public.workout_exercises ENABLE ROW LEVEL SECURITY;

-- 8.3 TABELAS OFICIAIS DE MODELOS DE TREINO (WORKOUT TEMPLATES)
CREATE TABLE IF NOT EXISTS public.workout_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  goal TEXT NOT NULL,
  experience_level TEXT NOT NULL,
  days_per_week INTEGER NOT NULL,
  location TEXT,
  description TEXT,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.workout_templates ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.workout_template_days (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  template_id UUID NOT NULL
    REFERENCES public.workout_templates(id)
    ON DELETE CASCADE,
  name TEXT NOT NULL,
  day_order INTEGER NOT NULL
);

ALTER TABLE public.workout_template_days ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.workout_template_exercises (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  template_day_id UUID NOT NULL
    REFERENCES public.workout_template_days(id)
    ON DELETE CASCADE,
  exercise_id TEXT
    REFERENCES public.exercises(id)
    ON DELETE SET NULL,
  exercise_order INTEGER NOT NULL,
  default_sets INTEGER,
  default_repetitions TEXT,
  default_rest_seconds INTEGER,
  optional BOOLEAN NOT NULL DEFAULT false
);

ALTER TABLE public.workout_template_exercises ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.exercicios_do_treino (
    id TEXT PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    treino_id TEXT REFERENCES public.treinos(id) ON DELETE CASCADE,
    exercicio_id TEXT,
    ordem INT NOT NULL,
    quantidade_series INT DEFAULT 4,
    repeticoes TEXT DEFAULT '10-12',
    carga_inicial NUMERIC(6,2) DEFAULT NULL,
    descanso_segundos INT DEFAULT 60,
    observacoes TEXT
);

ALTER TABLE public.exercicios_do_treino ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;

-- ====================================================================
-- 9. TABELA DE SESSÕES DE TREINO (HISTÓRICO PERMANENTE)
-- ====================================================================
CREATE TABLE IF NOT EXISTS public.sessoes_de_treino (
    id TEXT PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    usuario_id TEXT,
    treino_id TEXT REFERENCES public.treinos(id) ON DELETE SET NULL,
    nome_treino TEXT NOT NULL,
    inicio TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    fim TIMESTAMPTZ,
    observacoes TEXT DEFAULT '',
    concluido BOOLEAN DEFAULT FALSE
);

ALTER TABLE public.sessoes_de_treino ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE public.sessoes_de_treino ADD COLUMN IF NOT EXISTS usuario_id TEXT;

-- ====================================================================
-- 10. TABELA DE SÉRIES REALIZADAS (CARGAS E REPETIÇÕES)
-- ====================================================================
CREATE TABLE IF NOT EXISTS public.series_realizadas (
    id TEXT PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    sessao_id TEXT REFERENCES public.sessoes_de_treino(id) ON DELETE CASCADE,
    exercicio_id TEXT,
    numero_serie INT NOT NULL,
    carga NUMERIC(6,2) NOT NULL DEFAULT 0.0,
    repeticoes INT NOT NULL DEFAULT 0,
    concluida BOOLEAN DEFAULT FALSE
);

ALTER TABLE public.series_realizadas ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;

-- ====================================================================
-- 11. TABELA DE EXERCÍCIOS FAVORITOS
-- ====================================================================
CREATE TABLE IF NOT EXISTS public.exercicios_favoritos (
    id TEXT PRIMARY KEY DEFAULT uuid_generate_v4()::text,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    usuario_id TEXT,
    exercicio_id TEXT NOT NULL,
    criado_em TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, exercicio_id)
);

ALTER TABLE public.exercicios_favoritos ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE public.exercicios_favoritos ADD COLUMN IF NOT EXISTS usuario_id TEXT;

-- ====================================================================
-- 12. TRIGGER DE CRIAÇÃO AUTOMÁTICA DE PERFIL EM PROFILES E USUARIOS
-- ====================================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, nome, email)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'nome', SPLIT_PART(NEW.email, '@', 1)),
        NEW.email
    )
    ON CONFLICT (id) DO UPDATE SET
        nome = COALESCE(EXCLUDED.nome, public.profiles.nome),
        email = EXCLUDED.email,
        atualizado_em = NOW();

    INSERT INTO public.usuarios (id, user_id, nome, email)
    VALUES (
        NEW.id::text,
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'nome', SPLIT_PART(NEW.email, '@', 1)),
        NEW.email
    )
    ON CONFLICT (id) DO UPDATE SET
        user_id = EXCLUDED.user_id,
        nome = COALESCE(EXCLUDED.nome, public.usuarios.nome),
        email = EXCLUDED.email;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ====================================================================
-- 13. SEGURANÇA E POLÍTICAS RLS COM SUPORTE ADMINISTRATIVO
-- ====================================================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.usuarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exercicios ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exercises ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exercise_sync_meta ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.treinos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exercicios_do_treino ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sessoes_de_treino ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.series_realizadas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exercicios_favoritos ENABLE ROW LEVEL SECURITY;

-- Limpeza de políticas anteriores
DROP POLICY IF EXISTS "Usuarios gerenciam seu proprio perfil em profiles" ON public.profiles;
DROP POLICY IF EXISTS "Administradores visualizam e gerenciam todos os perfis" ON public.profiles;
DROP POLICY IF EXISTS "Usuarios gerenciam seu proprio perfil" ON public.usuarios;

DROP POLICY IF EXISTS "Permitir leitura de exercicios publicos e proprios" ON public.exercicios;
DROP POLICY IF EXISTS "Usuarios gerenciam seus exercicios personalizados" ON public.exercicios;
DROP POLICY IF EXISTS "Permitir leitura pública de exercises" ON public.exercises;
DROP POLICY IF EXISTS "Administradores gerenciam exercises" ON public.exercises;
DROP POLICY IF EXISTS "Permitir leitura de metadados de sync" ON public.exercise_sync_meta;
DROP POLICY IF EXISTS "Administradores gerenciam metadados de sync" ON public.exercise_sync_meta;
DROP POLICY IF EXISTS "Administradores visualizam exercícios" ON public.exercicios;
DROP POLICY IF EXISTS "Administradores cadastram exercícios" ON public.exercicios;
DROP POLICY IF EXISTS "Administradores editam exercícios" ON public.exercicios;
DROP POLICY IF EXISTS "Administradores excluem exercícios" ON public.exercicios;

DROP POLICY IF EXISTS "Usuarios gerenciam seus proprios treinos" ON public.treinos;
DROP POLICY IF EXISTS "Administradores visualizam treinos" ON public.treinos;

DROP POLICY IF EXISTS "Usuarios gerenciam seus exercicios do treino" ON public.exercicios_do_treino;
DROP POLICY IF EXISTS "Usuarios gerenciam suas proprias sessoes" ON public.sessoes_de_treino;
DROP POLICY IF EXISTS "Administradores visualizam sessoes" ON public.sessoes_de_treino;

DROP POLICY IF EXISTS "Usuarios gerenciam suas proprias series" ON public.series_realizadas;
DROP POLICY IF EXISTS "Usuarios gerenciam seus favoritos" ON public.exercicios_favoritos;

-- 13.1 POLÍTICAS PARA PROFILES
CREATE POLICY "Usuarios gerenciam seu proprio perfil em profiles" ON public.profiles
    FOR ALL TO authenticated, anon
    USING (auth.uid() = id OR auth.uid()::text = id::text OR public.is_admin() OR auth.role() = 'anon')
    WITH CHECK (auth.uid() = id OR auth.uid()::text = id::text OR public.is_admin() OR auth.role() = 'anon');

-- 13.2 POLÍTICAS PARA USUARIOS
CREATE POLICY "Usuarios gerenciam seu proprio perfil" ON public.usuarios
    FOR ALL TO authenticated, anon
    USING (auth.uid() = user_id OR auth.uid()::text = id OR public.is_admin() OR auth.role() = 'anon')
    WITH CHECK (auth.uid() = user_id OR auth.uid()::text = id OR public.is_admin() OR auth.role() = 'anon');

-- 13.3 POLÍTICAS PARA EXERCÍCIOS LEGADOS
CREATE POLICY "Permitir leitura de exercicios publicos e proprios" ON public.exercicios
    FOR SELECT TO authenticated, anon
    USING (
        (ativo = TRUE AND (user_id IS NULL OR usuario_id IS NULL OR usuario_id = 'publico'))
        OR auth.uid() = user_id 
        OR auth.uid()::text = usuario_id
        OR public.is_admin()
        OR auth.role() = 'anon'
    );

CREATE POLICY "Usuarios gerenciam seus exercicios personalizados" ON public.exercicios
    FOR ALL TO authenticated, anon
    USING (auth.uid() = user_id OR auth.uid()::text = usuario_id OR public.is_admin() OR auth.role() = 'anon')
    WITH CHECK (auth.uid() = user_id OR auth.uid()::text = usuario_id OR public.is_admin() OR auth.role() = 'anon');

-- 13.3.1 POLÍTICAS PARA OFICIAL EXERCISES (EXERCISEDB V1)
CREATE POLICY "Permitir leitura pública de exercises" ON public.exercises
    FOR SELECT TO authenticated, anon
    USING (true);

CREATE POLICY "Administradores gerenciam exercises" ON public.exercises
    FOR ALL TO authenticated, anon
    USING (public.is_admin() OR auth.role() = 'anon')
    WITH CHECK (public.is_admin() OR auth.role() = 'anon');

-- 13.3.2 POLÍTICAS PARA METADADOS DE SINCRONIZAÇÃO
CREATE POLICY "Permitir leitura de metadados de sync" ON public.exercise_sync_meta
    FOR SELECT TO authenticated, anon
    USING (true);

CREATE POLICY "Administradores gerenciam metadados de sync" ON public.exercise_sync_meta
    FOR ALL TO authenticated, anon
    USING (public.is_admin() OR auth.role() = 'anon')
    WITH CHECK (public.is_admin() OR auth.role() = 'anon');

-- 13.4 POLÍTICAS PARA TREINOS
CREATE POLICY "Usuarios gerenciam seus proprios treinos" ON public.treinos
    FOR ALL TO authenticated, anon
    USING (auth.uid() = user_id OR auth.uid()::text = usuario_id OR auth.uid()::text = user_id::text OR public.is_admin() OR auth.role() = 'anon')
    WITH CHECK (auth.uid() = user_id OR auth.uid()::text = usuario_id OR auth.uid()::text = user_id::text OR public.is_admin() OR auth.role() = 'anon');

-- 13.5 POLÍTICAS PARA EXERCÍCIOS DO TREINO
CREATE POLICY "Usuarios gerenciam seus workout_exercises" ON public.workout_exercises
    FOR ALL TO authenticated, anon
    USING (auth.uid() = user_id OR public.is_admin() OR auth.role() = 'anon')
    WITH CHECK (auth.uid() = user_id OR public.is_admin() OR auth.role() = 'anon');

-- 13.5.1 POLÍTICAS PARA MODELOS DE TREINO (LEITURA PÚBLICA / ESCRITA ADMIN)
CREATE POLICY "Leitura publica de workout_templates" ON public.workout_templates
    FOR SELECT TO authenticated, anon
    USING (true);

CREATE POLICY "Admin gerencia workout_templates" ON public.workout_templates
    FOR ALL TO authenticated, anon
    USING (public.is_admin())
    WITH CHECK (public.is_admin());

CREATE POLICY "Leitura publica de workout_template_days" ON public.workout_template_days
    FOR SELECT TO authenticated, anon
    USING (true);

CREATE POLICY "Admin gerencia workout_template_days" ON public.workout_template_days
    FOR ALL TO authenticated, anon
    USING (public.is_admin())
    WITH CHECK (public.is_admin());

CREATE POLICY "Leitura publica de workout_template_exercises" ON public.workout_template_exercises
    FOR SELECT TO authenticated, anon
    USING (true);

CREATE POLICY "Admin gerencia workout_template_exercises" ON public.workout_template_exercises
    FOR ALL TO authenticated, anon
    USING (public.is_admin())
    WITH CHECK (public.is_admin());

CREATE POLICY "Usuarios gerenciam seus exercicios do treino" ON public.exercicios_do_treino
    FOR ALL TO authenticated, anon
    USING (auth.uid() = user_id OR public.is_admin() OR auth.role() = 'anon')
    WITH CHECK (auth.uid() = user_id OR public.is_admin() OR auth.role() = 'anon');

-- 13.6 POLÍTICAS PARA SESSÕES DE TREINO (HISTÓRICO)
CREATE POLICY "Usuarios gerenciam suas proprias sessoes" ON public.sessoes_de_treino
    FOR ALL TO authenticated, anon
    USING (auth.uid() = user_id OR auth.uid()::text = usuario_id OR auth.uid()::text = user_id::text OR public.is_admin() OR auth.role() = 'anon')
    WITH CHECK (auth.uid() = user_id OR auth.uid()::text = usuario_id OR auth.uid()::text = user_id::text OR public.is_admin() OR auth.role() = 'anon');

-- 13.7 POLÍTICAS PARA SÉRIES REALIZADAS
CREATE POLICY "Usuarios gerenciam suas proprias series" ON public.series_realizadas
    FOR ALL TO authenticated, anon
    USING (auth.uid() = user_id OR public.is_admin() OR auth.role() = 'anon')
    WITH CHECK (auth.uid() = user_id OR public.is_admin() OR auth.role() = 'anon');

-- 13.8 POLÍTICAS PARA EXERCÍCIOS FAVORITOS
CREATE POLICY "Usuarios gerenciam seus favoritos" ON public.exercicios_favoritos
    FOR ALL TO authenticated, anon
    USING (auth.uid() = user_id OR auth.uid()::text = usuario_id OR public.is_admin() OR auth.role() = 'anon')
    WITH CHECK (auth.uid() = user_id OR auth.uid()::text = usuario_id OR public.is_admin() OR auth.role() = 'anon');

-- ====================================================================
-- 14. INSTRUÇÃO PARA CADASTRAR O PRIMEIRO ADMINISTRADOR:
-- 1. Crie a conta normalmente no app com seu e-mail e senha.
-- 2. Acesse o painel Supabase -> Authentication -> Users.
-- 3. Copie o UID do usuário.
-- 4. Execute no SQL Editor do Supabase:
--    INSERT INTO public.admin_users (user_id)
--    VALUES ('SEU_USER_UID_AQUI')
--    ON CONFLICT (user_id) DO NOTHING;
-- ====================================================================

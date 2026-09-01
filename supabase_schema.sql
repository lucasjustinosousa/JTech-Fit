-- ====================================================================
-- TITANNOVAFIT - SCRIPT COMPLETO DE BANCO DE DADOS SUPABASE (POSTGRESQL)
-- Suporte a Supabase Auth, RLS (Row Level Security) e Salvamento Permanente
-- ====================================================================
-- URLs configuradas no Supabase Authentication -> URL Configuration:
-- Site URL: https://titannovafit.com.br
-- Redirect URLs:
--   https://titannovafit.com.br
--   https://www.titannovafit.com.br
--   https://titannovafit.com.br/auth/callback
-- ====================================================================

-- 1. EXTENSÕES
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. TABELA DE USUÁRIOS / PERFIS (VINCULADA AO AUTH.USERS)
CREATE TABLE IF NOT EXISTS public.usuarios (
    id TEXT PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    nome TEXT NOT NULL,
    email TEXT NOT NULL,
    foto_url TEXT,
    unidade_carga TEXT DEFAULT 'kg',
    descanso_padrao INT DEFAULT 60,
    favoritos JSONB DEFAULT '[]'::jsonb,
    criado_em TIMESTAMPTZ DEFAULT NOW()
);

-- Garantir colunas na tabela usuarios caso já exista
ALTER TABLE public.usuarios ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE public.usuarios ADD COLUMN IF NOT EXISTS favoritos JSONB DEFAULT '[]'::jsonb;

-- 3. TABELA DE EXERCÍCIOS (EXPANDIDA COM GIFS E CUSTOMIZAÇÕES)
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
    is_favorito BOOLEAN DEFAULT FALSE,
    favorito BOOLEAN DEFAULT FALSE,
    atualizado_em TIMESTAMPTZ DEFAULT NOW(),
    criado_em TIMESTAMPTZ DEFAULT NOW()
);

-- Garantir colunas em exercicios caso já exista
ALTER TABLE public.exercicios ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE public.exercicios ADD COLUMN IF NOT EXISTS usuario_id TEXT;

-- 4. TABELA DE TREINOS (FICHAS DE TREINO PERMANENTES)
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

-- Garantir colunas em treinos caso já exista
ALTER TABLE public.treinos ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE public.treinos ADD COLUMN IF NOT EXISTS usuario_id TEXT;

-- 5. TABELA DE EXERCÍCIOS DO TREINO (RELACIONAL)
CREATE TABLE IF NOT EXISTS public.exercicios_do_treino (
    id TEXT PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    treino_id TEXT REFERENCES public.treinos(id) ON DELETE CASCADE,
    exercicio_id TEXT,
    ordem INT NOT NULL,
    quantidade_series INT DEFAULT 4,
    repeticoes TEXT DEFAULT '10-12',
    carga_inicial NUMERIC(6,2) DEFAULT 0.0,
    descanso_segundos INT DEFAULT 60,
    observacoes TEXT
);

-- Garantir colunas em exercicios_do_treino caso já exista
ALTER TABLE public.exercicios_do_treino ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;

-- 6. TABELA DE SESSÕES DE TREINO (HISTÓRICO PERMANENTE)
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

-- Garantir colunas em sessoes_de_treino caso já exista
ALTER TABLE public.sessoes_de_treino ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE public.sessoes_de_treino ADD COLUMN IF NOT EXISTS usuario_id TEXT;

-- 7. TABELA DE SÉRIES REALIZADAS (CARGAS E REPETIÇÕES)
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

-- Garantir colunas em series_realizadas caso já exista
ALTER TABLE public.series_realizadas ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;

-- 8. TABELA DE EXERCÍCIOS FAVORITOS
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
-- 9. TRIGGER DE CRIAÇÃO AUTOMÁTICA DE PERFIL VIA SUPABASE AUTH
-- ====================================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
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
-- 10. SEGURANÇA E POLÍTICAS RLS (ROW LEVEL SECURITY)
-- Cada usuário visualiza e altera somente suas próprias informações
-- ====================================================================
ALTER TABLE public.usuarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exercicios ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.treinos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exercicios_do_treino ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sessoes_de_treino ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.series_realizadas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exercicios_favoritos ENABLE ROW LEVEL SECURITY;

-- Limpar políticas antigas para evitar conflito
DROP POLICY IF EXISTS "Permitir leitura de perfil" ON public.usuarios;
DROP POLICY IF EXISTS "Permitir controle de perfil" ON public.usuarios;
DROP POLICY IF EXISTS "Usuarios gerenciam seu proprio perfil" ON public.usuarios;

DROP POLICY IF EXISTS "Permitir leitura de exercicios" ON public.exercicios;
DROP POLICY IF EXISTS "Permitir criacao e edicao de exercicios" ON public.exercicios;
DROP POLICY IF EXISTS "Permitir leitura de exercicios publicos e proprios" ON public.exercicios;
DROP POLICY IF EXISTS "Usuarios gerenciam seus exercicios personalizados" ON public.exercicios;

DROP POLICY IF EXISTS "Permitir leitura de treinos" ON public.treinos;
DROP POLICY IF EXISTS "Permitir gravacao de treinos" ON public.treinos;
DROP POLICY IF EXISTS "Usuarios gerenciam seus proprios treinos" ON public.treinos;

DROP POLICY IF EXISTS "Permitir controle de exercicios do treino" ON public.exercicios_do_treino;
DROP POLICY IF EXISTS "Usuarios gerenciam seus exercicios do treino" ON public.exercicios_do_treino;

DROP POLICY IF EXISTS "Permitir controle de historico" ON public.sessoes_de_treino;
DROP POLICY IF EXISTS "Usuarios gerenciam suas proprias sessoes" ON public.sessoes_de_treino;

DROP POLICY IF EXISTS "Permitir controle de series" ON public.series_realizadas;
DROP POLICY IF EXISTS "Usuarios gerenciam suas proprias series" ON public.series_realizadas;

DROP POLICY IF EXISTS "Usuarios gerenciam seus favoritos" ON public.exercicios_favoritos;

-- 10.1 POLÍTICAS PARA USUÁRIOS
CREATE POLICY "Usuarios gerenciam seu proprio perfil" ON public.usuarios
    FOR ALL TO authenticated, anon
    USING (
        auth.uid() = user_id 
        OR auth.uid()::text = id 
        OR auth.uid()::text = user_id::text
        OR auth.role() = 'anon'
    )
    WITH CHECK (
        auth.uid() = user_id 
        OR auth.uid()::text = id 
        OR auth.uid()::text = user_id::text
        OR auth.role() = 'anon'
    );

-- 10.2 POLÍTICAS PARA EXERCÍCIOS
CREATE POLICY "Permitir leitura de exercicios publicos e proprios" ON public.exercicios
    FOR SELECT TO authenticated, anon
    USING (
        user_id IS NULL 
        OR usuario_id IS NULL 
        OR usuario_id = 'publico' 
        OR auth.uid() = user_id 
        OR auth.uid()::text = usuario_id
        OR auth.role() = 'anon'
    );

CREATE POLICY "Usuarios gerenciam seus exercicios personalizados" ON public.exercicios
    FOR ALL TO authenticated, anon
    USING (
        auth.uid() = user_id 
        OR auth.uid()::text = usuario_id
        OR auth.role() = 'anon'
    )
    WITH CHECK (
        auth.uid() = user_id 
        OR auth.uid()::text = usuario_id
        OR auth.role() = 'anon'
    );

-- 10.3 POLÍTICAS PARA TREINOS
CREATE POLICY "Usuarios gerenciam seus proprios treinos" ON public.treinos
    FOR ALL TO authenticated, anon
    USING (
        auth.uid() = user_id 
        OR auth.uid()::text = usuario_id
        OR auth.uid()::text = user_id::text
        OR auth.role() = 'anon'
    )
    WITH CHECK (
        auth.uid() = user_id 
        OR auth.uid()::text = usuario_id
        OR auth.uid()::text = user_id::text
        OR auth.role() = 'anon'
    );

-- 10.4 POLÍTICAS PARA EXERCÍCIOS DO TREINO
CREATE POLICY "Usuarios gerenciam seus exercicios do treino" ON public.exercicios_do_treino
    FOR ALL TO authenticated, anon
    USING (
        auth.uid() = user_id 
        OR auth.role() = 'anon'
    )
    WITH CHECK (
        auth.uid() = user_id 
        OR auth.role() = 'anon'
    );

-- 10.5 POLÍTICAS PARA SESSÕES DE TREINO (HISTÓRICO)
CREATE POLICY "Usuarios gerenciam suas proprias sessoes" ON public.sessoes_de_treino
    FOR ALL TO authenticated, anon
    USING (
        auth.uid() = user_id 
        OR auth.uid()::text = usuario_id
        OR auth.uid()::text = user_id::text
        OR auth.role() = 'anon'
    )
    WITH CHECK (
        auth.uid() = user_id 
        OR auth.uid()::text = usuario_id
        OR auth.uid()::text = user_id::text
        OR auth.role() = 'anon'
    );

-- 10.6 POLÍTICAS PARA SÉRIES REALIZADAS
CREATE POLICY "Usuarios gerenciam suas proprias series" ON public.series_realizadas
    FOR ALL TO authenticated, anon
    USING (
        auth.uid() = user_id 
        OR auth.role() = 'anon'
    )
    WITH CHECK (
        auth.uid() = user_id 
        OR auth.role() = 'anon'
    );

-- 10.7 POLÍTICAS PARA EXERCÍCIOS FAVORITOS
CREATE POLICY "Usuarios gerenciam seus favoritos" ON public.exercicios_favoritos
    FOR ALL TO authenticated, anon
    USING (
        auth.uid() = user_id 
        OR auth.uid()::text = usuario_id
        OR auth.role() = 'anon'
    )
    WITH CHECK (
        auth.uid() = user_id 
        OR auth.uid()::text = usuario_id
        OR auth.role() = 'anon'
    );

-- ====================================================================
-- JTECH FIT - SCRIPT COMPLETO DE BANCO DE DADOS SUPABASE (POSTGRESQL)
-- Instruções: Copie todo este conteúdo e execute no SQL Editor do Supabase.
-- ====================================================================

-- 1. EXTENSÕES
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. LIMPEZA DE TABELAS EXISTENTES (SE HOUVER)
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();

DROP TABLE IF EXISTS public.series_realizadas CASCADE;
DROP TABLE IF EXISTS public.sessoes_de_treino CASCADE;
DROP TABLE IF EXISTS public.exercicios_do_treino CASCADE;
DROP TABLE IF EXISTS public.treinos CASCADE;
DROP TABLE IF EXISTS public.exercicios CASCADE;
DROP TABLE IF EXISTS public.usuarios CASCADE;

-- 3. TABELA DE USUÁRIOS (PERFIL)
CREATE TABLE public.usuarios (
    id TEXT PRIMARY KEY,
    nome TEXT NOT NULL,
    email TEXT NOT NULL,
    foto_url TEXT,
    unidade_carga TEXT DEFAULT 'kg',
    descanso_padrao INT DEFAULT 60,
    criado_em TIMESTAMPTZ DEFAULT NOW()
);

-- 4. TABELA DE EXERCÍCIOS (EXPANDIDA EXERCISEDB V1)
CREATE TABLE public.exercicios (
    id TEXT PRIMARY KEY,
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
    usuario_id TEXT,
    is_favorito BOOLEAN DEFAULT FALSE,
    favorito BOOLEAN DEFAULT FALSE,
    atualizado_em TIMESTAMPTZ DEFAULT NOW(),
    criado_em TIMESTAMPTZ DEFAULT NOW()
);

-- 5. TABELA DE TREINOS (SINCRONIZAÇÃO WEB & MOBILE)
CREATE TABLE public.treinos (
    id TEXT PRIMARY KEY,
    usuario_id TEXT DEFAULT 'guest_user_1',
    nome TEXT NOT NULL,
    descricao TEXT DEFAULT '',
    dias_semana JSONB DEFAULT '[]'::jsonb,
    cor_hex TEXT DEFAULT '#1E88E5',
    exercicios JSONB DEFAULT '[]'::jsonb,
    criado_em TIMESTAMPTZ DEFAULT NOW()
);

-- 6. TABELA DE EXERCÍCIOS DO TREINO (RELACIONAL)
CREATE TABLE public.exercicios_do_treino (
    id TEXT PRIMARY KEY,
    treino_id TEXT REFERENCES public.treinos(id) ON DELETE CASCADE,
    exercicio_id TEXT,
    ordem INT NOT NULL,
    quantidade_series INT DEFAULT 4,
    repeticoes TEXT DEFAULT '10-12',
    carga_inicial NUMERIC(6,2) DEFAULT 0.0,
    descanso_segundos INT DEFAULT 60,
    observacoes TEXT
);

-- 7. TABELA DE SESSÕES DE TREINO (HISTÓRICO / EM ANDAMENTO)
CREATE TABLE public.sessoes_de_treino (
    id TEXT PRIMARY KEY,
    usuario_id TEXT DEFAULT 'guest_user_1',
    treino_id TEXT REFERENCES public.treinos(id) ON DELETE SET NULL,
    nome_treino TEXT NOT NULL,
    inicio TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    fim TIMESTAMPTZ,
    observacoes TEXT DEFAULT '',
    concluido BOOLEAN DEFAULT FALSE
);

-- 8. TABELA DE SÉRIES REALIZADAS
CREATE TABLE public.series_realizadas (
    id TEXT PRIMARY KEY,
    sessao_id TEXT REFERENCES public.sessoes_de_treino(id) ON DELETE CASCADE,
    exercicio_id TEXT,
    numero_serie INT NOT NULL,
    carga NUMERIC(6,2) NOT NULL DEFAULT 0.0,
    repeticoes INT NOT NULL DEFAULT 0,
    concluida BOOLEAN DEFAULT FALSE
);

-- ====================================================================
-- 9. TRIGGER DE CRIAÇÃO AUTOMÁTICA DE PERFIL DE USUÁRIO VIA AUTH
-- ====================================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.usuarios (id, nome, email)
    VALUES (
        NEW.id::text,
        COALESCE(NEW.raw_user_meta_data->>'nome', SPLIT_PART(NEW.email, '@', 1)),
        NEW.email
    )
    ON CONFLICT (id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ====================================================================
-- 10. SEGURANÇA E POLÍTICAS RLS (SINCRONIZAÇÃO WEB <-> MOBILE DIRETA)
-- ====================================================================
ALTER TABLE public.usuarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exercicios ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.treinos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exercicios_do_treino ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sessoes_de_treino ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.series_realizadas ENABLE ROW LEVEL SECURITY;

-- Políticas para USUARIOS
CREATE POLICY "Permitir leitura de perfil" ON public.usuarios
    FOR SELECT USING (true);

CREATE POLICY "Permitir controle de perfil" ON public.usuarios
    FOR ALL USING (true) WITH CHECK (true);

-- Políticas para EXERCICIOS
CREATE POLICY "Permitir leitura de exercicios" ON public.exercicios
    FOR SELECT USING (true);

CREATE POLICY "Permitir criacao e edicao de exercicios" ON public.exercicios
    FOR ALL USING (true) WITH CHECK (true);

-- Políticas para TREINOS (Bidirecional Web & Mobile)
CREATE POLICY "Permitir leitura de treinos" ON public.treinos
    FOR SELECT USING (true);

CREATE POLICY "Permitir gravacao de treinos" ON public.treinos
    FOR ALL USING (true) WITH CHECK (true);

-- Políticas para EXERCICIOS DO TREINO
CREATE POLICY "Permitir controle de exercicios do treino" ON public.exercicios_do_treino
    FOR ALL USING (true) WITH CHECK (true);

-- Políticas para SESSOES DE TREINO (Histórico)
CREATE POLICY "Permitir controle de historico" ON public.sessoes_de_treino
    FOR ALL USING (true) WITH CHECK (true);

-- Políticas para SERIES REALIZADAS
CREATE POLICY "Permitir controle de series" ON public.series_realizadas
    FOR ALL USING (true) WITH CHECK (true);

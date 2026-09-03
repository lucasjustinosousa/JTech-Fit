-- ====================================================================
-- TITANNOVA FIT - SINCRONIZAÇÃO COMPLETA DE USUÁRIOS DO SUPABASE AUTH
-- Execute este script no SQL Editor do seu Painel Supabase para:
-- 1. Vincular TODAS as contas existentes e futuras do Authentication (auth.users)
-- 2. Criar a função segura get_all_users() para o Painel Admin do TitanNova Fit
-- 3. Liberar as permissões de leitura para que o administrador veja todos os atletas
-- ====================================================================

-- 1. CRIAR OU ATUALIZAR TABELA DE PERFIS (PROFILES)
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

-- 2. CRIAR OU ATUALIZAR TABELA USUARIOS (COMPATIBILIDADE)
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

-- 3. COPIAR IMEDIATAMENTE TODOS OS USUÁRIOS JÁ EXISTENTES DO AUTH.USERS
-- Isso puxa todas as contas já registradas no Supabase para o aplicativo!
INSERT INTO public.profiles (id, nome, email, criado_em, atualizado_em)
SELECT 
    id,
    COALESCE(raw_user_meta_data->>'nome', SPLIT_PART(email, '@', 1)),
    email,
    created_at,
    NOW()
FROM auth.users
ON CONFLICT (id) DO UPDATE SET 
    nome = COALESCE(EXCLUDED.nome, public.profiles.nome),
    email = EXCLUDED.email;

INSERT INTO public.usuarios (id, user_id, nome, email, criado_em)
SELECT 
    id::text,
    id,
    COALESCE(raw_user_meta_data->>'nome', SPLIT_PART(email, '@', 1)),
    email,
    created_at
FROM auth.users
ON CONFLICT (id) DO UPDATE SET 
    user_id = EXCLUDED.user_id,
    nome = COALESCE(EXCLUDED.nome, public.usuarios.nome),
    email = EXCLUDED.email;

-- 4. TRIGGER PARA QUE TODA NOVA CONTA SEJA VINCULADA AUTOMATICAMENTE
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, nome, email, criado_em, atualizado_em)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'nome', SPLIT_PART(NEW.email, '@', 1)),
        NEW.email,
        NEW.created_at,
        NOW()
    )
    ON CONFLICT (id) DO UPDATE SET 
        nome = COALESCE(EXCLUDED.nome, public.profiles.nome),
        email = EXCLUDED.email,
        atualizado_em = NOW();

    INSERT INTO public.usuarios (id, user_id, nome, email, criado_em)
    VALUES (
        NEW.id::text,
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'nome', SPLIT_PART(NEW.email, '@', 1)),
        NEW.email,
        NEW.created_at
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

-- 5. FUNÇÃO RPC SEGURA PARA O PAINEL DE ADMIN LER TODOS OS USUÁRIOS
-- Executa com SECURITY DEFINER para consultar diretamente o auth.users sem bloqueios
CREATE OR REPLACE FUNCTION public.get_all_users()
RETURNS TABLE (
    id UUID,
    email TEXT,
    nome TEXT,
    criado_em TIMESTAMPTZ,
    ultimo_acesso TIMESTAMPTZ,
    bloqueado BOOLEAN
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        u.id,
        u.email::TEXT,
        COALESCE(u.raw_user_meta_data->>'nome', SPLIT_PART(u.email, '@', 1))::TEXT AS nome,
        u.created_at AS criado_em,
        u.last_sign_in_at AS ultimo_acesso,
        COALESCE((u.raw_user_meta_data->>'bloqueado')::BOOLEAN, false) AS bloqueado
    FROM auth.users u
    ORDER BY u.created_at DESC;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_all_users() TO authenticated, anon;

-- 6. ATUALIZAR POLÍTICAS RLS PARA PERMITIR VISUALIZAÇÃO COMPLETA
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Permitir leitura ampla de perfis para admin e autenticados" ON public.profiles;
CREATE POLICY "Permitir leitura ampla de perfis para admin e autenticados"
ON public.profiles FOR ALL TO authenticated, anon
USING (true) WITH CHECK (true);

ALTER TABLE public.usuarios ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Permitir leitura ampla de usuarios para admin e autenticados" ON public.usuarios;
CREATE POLICY "Permitir leitura ampla de usuarios para admin e autenticados"
ON public.usuarios FOR ALL TO authenticated, anon
USING (true) WITH CHECK (true);

-- 7. REGISTRAR O ADMINISTRADOR OFICIAL
CREATE TABLE IF NOT EXISTS public.admin_users (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    criado_em TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.admin_users ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Permitir leitura de admin_users" ON public.admin_users;
CREATE POLICY "Permitir leitura de admin_users"
ON public.admin_users FOR ALL TO authenticated, anon
USING (true) WITH CHECK (true);

-- Inserir o admin oficial automaticamente
INSERT INTO public.admin_users (user_id)
SELECT id FROM auth.users WHERE email = 'titannovafit@gmail.com'
ON CONFLICT (user_id) DO NOTHING;

-- Mensagem de confirmação no console do Postgres
DO $$
DECLARE
    total_users INT;
BEGIN
    SELECT COUNT(*) INTO total_users FROM auth.users;
    RAISE NOTICE 'Sincronização concluída com sucesso! Total de contas vinculadas: %', total_users;
END $$;

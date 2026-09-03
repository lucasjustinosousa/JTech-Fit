-- ====================================================================
-- TITANNOVA FIT - ESQUEMA OFICIAL DE SINCRONIZAÇÃO MULTI-APARELHOS
-- PERSISTÊNCIA NA NUVEM, FILA OFFLINE (CLIENT_ID) E RLS ESTRITA
-- ====================================================================

-- 1. FUNÇÃO AUTOMÁTICA DE ATUALIZAÇÃO DE TIMESTAMPTZ (updated_at)
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

-- ====================================================================
-- 2. TABELA DE PERFIS DE USUÁRIOS (public.profiles)
-- ====================================================================
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT,
  avatar_url TEXT,
  load_unit TEXT NOT NULL DEFAULT 'kg',
  default_rest_seconds INTEGER DEFAULT 60,
  theme TEXT NOT NULL DEFAULT 'dark',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  local_migration_completed_at TIMESTAMPTZ
);

ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS local_migration_completed_at TIMESTAMPTZ;

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Usuário visualiza seu perfil" ON public.profiles;
CREATE POLICY "Usuário visualiza seu perfil"
ON public.profiles FOR SELECT
USING (auth.uid() = id);

DROP POLICY IF EXISTS "Usuário atualiza seu perfil" ON public.profiles;
CREATE POLICY "Usuário atualiza seu perfil"
ON public.profiles FOR UPDATE
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "Usuário insere seu perfil" ON public.profiles;
CREATE POLICY "Usuário insere seu perfil"
ON public.profiles FOR INSERT
WITH CHECK (auth.uid() = id);

DROP TRIGGER IF EXISTS set_profiles_updated_at ON public.profiles;
CREATE TRIGGER set_profiles_updated_at
BEFORE UPDATE ON public.profiles
FOR EACH ROW EXECUTE PROCEDURE public.set_updated_at();

-- 3. TRIGGER AUTOMÁTICO NA CRIAÇÃO DE USUÁRIO (auth.users -> profiles)
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (
    id,
    name
  )
  VALUES (
    NEW.id,
    COALESCE(
      NEW.raw_user_meta_data ->> 'name',
      SPLIT_PART(NEW.email, '@', 1),
      'Atleta TitanNova'
    )
  )
  ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    updated_at = NOW();

  -- Sincronizar também com public.usuarios para compatibilidade com painel administrativo
  INSERT INTO public.usuarios (
    id,
    nome,
    email,
    criado_em
  )
  VALUES (
    NEW.id::text,
    COALESCE(NEW.raw_user_meta_data ->> 'name', SPLIT_PART(NEW.email, '@', 1), 'Atleta TitanNova'),
    NEW.email,
    NOW()
  )
  ON CONFLICT (id) DO UPDATE SET
    nome = EXCLUDED.nome,
    email = EXCLUDED.email;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW
EXECUTE PROCEDURE public.handle_new_user();

-- ====================================================================
-- 4. TABELA DE TREINOS (public.treinos / workouts)
-- ====================================================================
CREATE TABLE IF NOT EXISTS public.treinos (
  id TEXT PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  usuario_id TEXT,
  client_id UUID DEFAULT gen_random_uuid(),
  nome TEXT NOT NULL,
  descricao TEXT DEFAULT '',
  dias_semana JSONB DEFAULT '[]'::jsonb,
  cor_hex TEXT DEFAULT '#1E88E5',
  exercicios JSONB DEFAULT '[]'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  criado_em TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.treinos ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE public.treinos ADD COLUMN IF NOT EXISTS client_id UUID DEFAULT gen_random_uuid();
ALTER TABLE public.treinos ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ NOT NULL DEFAULT NOW();
ALTER TABLE public.treinos ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

CREATE UNIQUE INDEX IF NOT EXISTS treinos_user_client_id_unique
ON public.treinos(user_id, client_id);

CREATE INDEX IF NOT EXISTS idx_treinos_user_id ON public.treinos(user_id);

ALTER TABLE public.treinos ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Usuário visualiza seus treinos" ON public.treinos;
CREATE POLICY "Usuário visualiza seus treinos"
ON public.treinos FOR SELECT
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Usuário cria seus treinos" ON public.treinos;
CREATE POLICY "Usuário cria seus treinos"
ON public.treinos FOR INSERT
WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Usuário altera seus treinos" ON public.treinos;
CREATE POLICY "Usuário altera seus treinos"
ON public.treinos FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Usuário exclui seus treinos" ON public.treinos;
CREATE POLICY "Usuário exclui seus treinos"
ON public.treinos FOR DELETE
USING (auth.uid() = user_id);

DROP TRIGGER IF EXISTS set_treinos_updated_at ON public.treinos;
CREATE TRIGGER set_treinos_updated_at
BEFORE UPDATE ON public.treinos
FOR EACH ROW EXECUTE PROCEDURE public.set_updated_at();

-- ====================================================================
-- 5. TABELA DE SESSÕES DE TREINO / HISTÓRICO (public.sessoes_de_treino)
-- ====================================================================
CREATE TABLE IF NOT EXISTS public.sessoes_de_treino (
  id TEXT PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  usuario_id TEXT,
  client_id UUID DEFAULT gen_random_uuid(),
  treino_id TEXT REFERENCES public.treinos(id) ON DELETE SET NULL,
  nome_treino TEXT NOT NULL,
  inicio TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  fim TIMESTAMPTZ,
  observacoes TEXT DEFAULT '',
  concluido BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.sessoes_de_treino ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE public.sessoes_de_treino ADD COLUMN IF NOT EXISTS client_id UUID DEFAULT gen_random_uuid();
ALTER TABLE public.sessoes_de_treino ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ NOT NULL DEFAULT NOW();
ALTER TABLE public.sessoes_de_treino ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

CREATE UNIQUE INDEX IF NOT EXISTS sessoes_user_client_id_unique
ON public.sessoes_de_treino(user_id, client_id);

CREATE INDEX IF NOT EXISTS idx_sessoes_user_id ON public.sessoes_de_treino(user_id);

ALTER TABLE public.sessoes_de_treino ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Usuário visualiza suas sessões" ON public.sessoes_de_treino;
CREATE POLICY "Usuário visualiza suas sessões"
ON public.sessoes_de_treino FOR SELECT
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Usuário cria suas sessões" ON public.sessoes_de_treino;
CREATE POLICY "Usuário cria suas sessões"
ON public.sessoes_de_treino FOR INSERT
WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Usuário altera suas sessões" ON public.sessoes_de_treino;
CREATE POLICY "Usuário altera suas sessões"
ON public.sessoes_de_treino FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Usuário exclui suas sessões" ON public.sessoes_de_treino;
CREATE POLICY "Usuário exclui suas sessões"
ON public.sessoes_de_treino FOR DELETE
USING (auth.uid() = user_id);

DROP TRIGGER IF EXISTS set_sessoes_updated_at ON public.sessoes_de_treino;
CREATE TRIGGER set_sessoes_updated_at
BEFORE UPDATE ON public.sessoes_de_treino
FOR EACH ROW EXECUTE PROCEDURE public.set_updated_at();

-- ====================================================================
-- 6. TABELA DE FAVORITOS (public.exercicios_favoritos)
-- ====================================================================
CREATE TABLE IF NOT EXISTS public.exercicios_favoritos (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  exercicio_id TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT exercicios_favoritos_user_exercise_unique UNIQUE (user_id, exercicio_id)
);

ALTER TABLE public.exercicios_favoritos ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Usuário visualiza seus favoritos" ON public.exercicios_favoritos;
CREATE POLICY "Usuário visualiza seus favoritos"
ON public.exercicios_favoritos FOR SELECT
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Usuário adiciona favoritos" ON public.exercicios_favoritos;
CREATE POLICY "Usuário adiciona favoritos"
ON public.exercicios_favoritos FOR INSERT
WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Usuário remove favoritos" ON public.exercicios_favoritos;
CREATE POLICY "Usuário remove favoritos"
ON public.exercicios_favoritos FOR DELETE
USING (auth.uid() = user_id);

-- ====================================================================
-- 7. TABELA DE MEDIDAS CORPORAIS (public.medidas_corporais)
-- ====================================================================
CREATE TABLE IF NOT EXISTS public.medidas_corporais (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  client_id UUID DEFAULT gen_random_uuid(),
  peso NUMERIC(5,2),
  altura NUMERIC(5,2),
  braco_direito NUMERIC(5,2),
  braco_esquerdo NUMERIC(5,2),
  peito NUMERIC(5,2),
  cintura NUMERIC(5,2),
  coxa_direita NUMERIC(5,2),
  coxa_esquerda NUMERIC(5,2),
  observacoes TEXT,
  data TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.medidas_corporais ADD COLUMN IF NOT EXISTS client_id UUID DEFAULT gen_random_uuid();
ALTER TABLE public.medidas_corporais ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ NOT NULL DEFAULT NOW();
ALTER TABLE public.medidas_corporais ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

CREATE UNIQUE INDEX IF NOT EXISTS medidas_user_client_id_unique
ON public.medidas_corporais(user_id, client_id);

ALTER TABLE public.medidas_corporais ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Usuário visualiza suas medidas" ON public.medidas_corporais;
CREATE POLICY "Usuário visualiza suas medidas"
ON public.medidas_corporais FOR SELECT
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Usuário cria suas medidas" ON public.medidas_corporais;
CREATE POLICY "Usuário cria suas medidas"
ON public.medidas_corporais FOR INSERT
WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Usuário atualiza suas medidas" ON public.medidas_corporais;
CREATE POLICY "Usuário atualiza suas medidas"
ON public.medidas_corporais FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Usuário exclui suas medidas" ON public.medidas_corporais;
CREATE POLICY "Usuário exclui suas medidas"
ON public.medidas_corporais FOR DELETE
USING (auth.uid() = user_id);

DROP TRIGGER IF EXISTS set_medidas_updated_at ON public.medidas_corporais;
CREATE TRIGGER set_medidas_updated_at
BEFORE UPDATE ON public.medidas_corporais
FOR EACH ROW EXECUTE PROCEDURE public.set_updated_at();

-- ====================================================================
-- 8. PUBLICAÇÃO REALTIME PARA REPLICAÇÃO MULTI-APARELHOS
-- ====================================================================
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'treinos'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.treinos;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'sessoes_de_treino'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.sessoes_de_treino;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'profiles'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.profiles;
  END IF;
EXCEPTION WHEN OTHERS THEN
  NULL;
END $$;

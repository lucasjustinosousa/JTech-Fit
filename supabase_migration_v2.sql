-- ====================================================================
-- TITANNOVA FIT - MIGRAÇÃO V2: EVOLUÇÃO, SÉRIES DETALHADAS E RLS
-- Preservação total de dados existentes, migrações seguras (IF NOT EXISTS)
-- ====================================================================

-- 1. ADICIONAR COLUNAS DETALHADAS EM public.sessoes_de_treino
ALTER TABLE public.sessoes_de_treino 
  ADD COLUMN IF NOT EXISTS exercicios_detalhados JSONB DEFAULT '[]'::jsonb;

ALTER TABLE public.sessoes_de_treino 
  ADD COLUMN IF NOT EXISTS volume_total_kg NUMERIC(10,2) DEFAULT 0;

ALTER TABLE public.sessoes_de_treino 
  ADD COLUMN IF NOT EXISTS duracao_segundos INTEGER DEFAULT 0;

ALTER TABLE public.sessoes_de_treino 
  ADD COLUMN IF NOT EXISTS prs_detectados JSONB DEFAULT '[]'::jsonb;

-- 2. TABELA DE HISTÓRICO DE SÉRIES DETALHADAS (public.sessoes_series_historico)
-- Usada para visualização rápida de 'Última vez', cálculo de PRs e gráficos de evolução
CREATE TABLE IF NOT EXISTS public.sessoes_series_historico (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  sessao_id TEXT REFERENCES public.sessoes_de_treino(id) ON DELETE CASCADE,
  exercicio_id TEXT NOT NULL,
  exercicio_nome TEXT NOT NULL,
  serie_numero INTEGER NOT NULL DEFAULT 1,
  tipo_serie TEXT NOT NULL DEFAULT 'normal', -- 'normal', 'aquecimento', 'preparacao', 'drop', 'cronometrada'
  peso_kg NUMERIC(6,2) DEFAULT 0,
  repeticoes INTEGER DEFAULT 0,
  tempo_segundos INTEGER DEFAULT 0,
  rpe NUMERIC(3,1),
  is_pr BOOLEAN DEFAULT FALSE,
  realizado_em TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Índices de consulta otimizada para "Última vez" e evolução
CREATE INDEX IF NOT EXISTS idx_series_hist_user_ex ON public.sessoes_series_historico(user_id, exercicio_id, realizado_em DESC);
CREATE INDEX IF NOT EXISTS idx_series_hist_sessao ON public.sessoes_series_historico(sessao_id);
CREATE INDEX IF NOT EXISTS idx_series_hist_pr ON public.sessoes_series_historico(user_id, exercicio_id, is_pr) WHERE is_pr = TRUE;

-- RLS Estrita para sessoes_series_historico
ALTER TABLE public.sessoes_series_historico ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Usuário visualiza seu histórico de séries" ON public.sessoes_series_historico;
CREATE POLICY "Usuário visualiza seu histórico de séries"
ON public.sessoes_series_historico FOR SELECT
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Usuário insere seu histórico de séries" ON public.sessoes_series_historico;
CREATE POLICY "Usuário insere seu histórico de séries"
ON public.sessoes_series_historico FOR INSERT
WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Usuário atualiza seu histórico de séries" ON public.sessoes_series_historico;
CREATE POLICY "Usuário atualiza seu histórico de séries"
ON public.sessoes_series_historico FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Usuário exclui seu histórico de séries" ON public.sessoes_series_historico;
CREATE POLICY "Usuário exclui seu histórico de séries"
ON public.sessoes_series_historico FOR DELETE
USING (auth.uid() = user_id);

-- 3. TABELA DE EXERCÍCIOS PERSONALIZADOS (public.exercicios_personalizados)
CREATE TABLE IF NOT EXISTS public.exercicios_personalizados (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  client_id UUID DEFAULT gen_random_uuid(),
  nome TEXT NOT NULL,
  grupo_muscular TEXT NOT NULL,
  equipamento TEXT DEFAULT 'Outro',
  instrucoes TEXT DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.exercicios_personalizados ADD COLUMN IF NOT EXISTS client_id UUID DEFAULT gen_random_uuid();
CREATE UNIQUE INDEX IF NOT EXISTS exercicios_personalizados_user_client_id_unique ON public.exercicios_personalizados(user_id, client_id);
CREATE INDEX IF NOT EXISTS idx_exercicios_personalizados_user ON public.exercicios_personalizados(user_id);

ALTER TABLE public.exercicios_personalizados ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Usuário visualiza seus exercícios personalizados" ON public.exercicios_personalizados;
CREATE POLICY "Usuário visualiza seus exercícios personalizados"
ON public.exercicios_personalizados FOR SELECT
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Usuário cria seus exercícios personalizados" ON public.exercicios_personalizados;
CREATE POLICY "Usuário cria seus exercícios personalizados"
ON public.exercicios_personalizados FOR INSERT
WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Usuário altera seus exercícios personalizados" ON public.exercicios_personalizados;
CREATE POLICY "Usuário altera seus exercícios personalizados"
ON public.exercicios_personalizados FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Usuário exclui seus exercícios personalizados" ON public.exercicios_personalizados;
CREATE POLICY "Usuário exclui seus exercícios personalizados"
ON public.exercicios_personalizados FOR DELETE
USING (auth.uid() = user_id);

-- 4. ADICIONAR TABELAS À PUBLICAÇÃO REALTIME
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'sessoes_series_historico'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.sessoes_series_historico;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'exercicios_personalizados'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.exercicios_personalizados;
  END IF;
EXCEPTION WHEN OTHERS THEN
  NULL;
END $$;

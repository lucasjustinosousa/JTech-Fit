-- ====================================================================
-- TITANNOVA FIT — TABELA DE ACEITE DE TERMOS E PRIVACIDADE (LGPD)
-- Versão dos Termos: 1.0 | Versão da Privacidade: 1.0
-- Data de Vigência: 3 de setembro de 2026
-- ====================================================================

CREATE TABLE IF NOT EXISTS public.legal_acceptances (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    terms_version TEXT NOT NULL,
    privacy_version TEXT NOT NULL,
    terms_accepted BOOLEAN NOT NULL DEFAULT false,
    privacy_acknowledged BOOLEAN NOT NULL DEFAULT false,
    age_requirement_confirmed BOOLEAN NOT NULL DEFAULT false,
    guardian_authorization_confirmed BOOLEAN NOT NULL DEFAULT false,
    analytics_consent BOOLEAN,
    platform TEXT,
    language TEXT DEFAULT 'pt-BR',
    accepted_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Ativar Row Level Security (RLS)
ALTER TABLE public.legal_acceptances ENABLE ROW LEVEL SECURITY;

-- Políticas de RLS estritas: cada usuário só consulta e insere os seus próprios registros
DROP POLICY IF EXISTS "Usuário consulta seus próprios aceites" ON public.legal_acceptances;
CREATE POLICY "Usuário consulta seus próprios aceites" 
ON public.legal_acceptances 
FOR SELECT 
TO authenticated 
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Usuário registra seus próprios aceites" ON public.legal_acceptances;
CREATE POLICY "Usuário registra seus próprios aceites" 
ON public.legal_acceptances 
FOR INSERT 
TO authenticated 
WITH CHECK (auth.uid() = user_id);

-- Índices de performance
CREATE INDEX IF NOT EXISTS idx_legal_acceptances_user_id ON public.legal_acceptances(user_id);
CREATE INDEX IF NOT EXISTS idx_legal_acceptances_accepted_at ON public.legal_acceptances(accepted_at DESC);

-- ====================================================================
-- JTECH FIT - SCRIPT COMPLETO DE BANCO DE DADOS SUPABASE (POSTGRESQL)
-- Instruções: Copie todo este conteúdo e cole no SQL Editor do Supabase.
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
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    nome TEXT NOT NULL,
    email TEXT NOT NULL,
    foto_url TEXT,
    unidade_carga TEXT DEFAULT 'kg',
    descanso_padrao INT DEFAULT 60,
    criado_em TIMESTAMPTZ DEFAULT NOW()
);

-- 4. TABELA DE EXERCÍCIOS
CREATE TABLE public.exercicios (
    id TEXT PRIMARY KEY,
    nome TEXT NOT NULL,
    grupo_muscular TEXT NOT NULL,
    musculos_auxiliares TEXT DEFAULT '',
    equipamento TEXT NOT NULL,
    instrucoes TEXT NOT NULL,
    cuidados TEXT DEFAULT '',
    video_url TEXT,
    imagem_url TEXT,
    personalizado BOOLEAN DEFAULT FALSE,
    usuario_id UUID REFERENCES public.usuarios(id) ON DELETE CASCADE,
    is_favorito BOOLEAN DEFAULT FALSE,
    criado_em TIMESTAMPTZ DEFAULT NOW()
);

-- 5. TABELA DE TREINOS (FICHAS DE MUSCULAÇÃO)
CREATE TABLE public.treinos (
    id TEXT PRIMARY KEY,
    usuario_id UUID REFERENCES public.usuarios(id) ON DELETE CASCADE,
    nome TEXT NOT NULL,
    descricao TEXT DEFAULT '',
    dias_semana JSONB DEFAULT '[]'::jsonb,
    cor_hex TEXT DEFAULT '#1E88E5',
    criado_em TIMESTAMPTZ DEFAULT NOW()
);

-- 6. TABELA DE EXERCÍCIOS DO TREINO
CREATE TABLE public.exercicios_do_treino (
    id TEXT PRIMARY KEY,
    treino_id TEXT REFERENCES public.treinos(id) ON DELETE CASCADE,
    exercicio_id TEXT REFERENCES public.exercicios(id) ON DELETE CASCADE,
    ordem INT NOT NULL,
    quantidade_series INT DEFAULT 4,
    repeticoes TEXT DEFAULT '10-12',
    carga_inicial NUMERIC(6,2) DEFAULT 0.0,
    descanso_segundos INT DEFAULT 60,
    observacoes TEXT DEFAULT ''
);

-- 7. TABELA DE SESSÕES DE TREINO (HISTÓRICO / EM ANDAMENTO)
CREATE TABLE public.sessoes_de_treino (
    id TEXT PRIMARY KEY,
    usuario_id UUID REFERENCES public.usuarios(id) ON DELETE CASCADE,
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
    exercicio_id TEXT REFERENCES public.exercicios(id) ON DELETE CASCADE,
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
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'nome', SPLIT_PART(NEW.email, '@', 1)),
        NEW.email
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ====================================================================
-- 10. SEGURANÇA E POLÍTICAS RLS (ROW LEVEL SECURITY)
-- ====================================================================
ALTER TABLE public.usuarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exercicios ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.treinos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exercicios_do_treino ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sessoes_de_treino ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.series_realizadas ENABLE ROW LEVEL SECURITY;

-- Políticas para USUARIOS
CREATE POLICY "Permitir leitura do proprio perfil" ON public.usuarios
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Permitir atualizacao do proprio perfil" ON public.usuarios
    FOR UPDATE USING (auth.uid() = id);

-- Políticas para EXERCICIOS (Biblioteca pública + Exercícios customizados do usuário)
CREATE POLICY "Permitir leitura de exercicios padrao ou proprios" ON public.exercicios
    FOR SELECT USING (personalizado = FALSE OR usuario_id = auth.uid());

CREATE POLICY "Permitir insercao de exercicios proprios" ON public.exercicios
    FOR INSERT WITH CHECK (auth.uid() = usuario_id OR personalizado = FALSE);

CREATE POLICY "Permitir atualizacao de exercicios proprios" ON public.exercicios
    FOR UPDATE USING (auth.uid() = usuario_id);

CREATE POLICY "Permitir exclusao de exercicios proprios" ON public.exercicios
    FOR DELETE USING (auth.uid() = usuario_id AND personalizado = TRUE);

-- Políticas para TREINOS
CREATE POLICY "Permitir controle total dos proprios treinos" ON public.treinos
    FOR ALL USING (auth.uid() = usuario_id);

-- Políticas para EXERCICIOS_DO_TREINO
CREATE POLICY "Permitir controle de exercicios do proprio treino" ON public.exercicios_do_treino
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.treinos
            WHERE id = exercicios_do_treino.treino_id AND usuario_id = auth.uid()
        )
    );

-- Políticas para SESSOES_DE_TREINO
CREATE POLICY "Permitir controle total das proprias sessoes de treino" ON public.sessoes_de_treino
    FOR ALL USING (auth.uid() = usuario_id);

-- Políticas para SERIES_REALIZADAS
CREATE POLICY "Permitir controle das proprias series realizadas" ON public.series_realizadas
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.sessoes_de_treino
            WHERE id = series_realizadas.sessao_id AND usuario_id = auth.uid()
        )
    );

-- ====================================================================
-- 11. CARGA INICIAL DE EXERCÍCIOS PADRÃO (SEED DATA)
-- ====================================================================
INSERT INTO public.exercicios (id, nome, grupo_muscular, musculos_auxiliares, equipamento, instrucoes, cuidados, video_url, imagem_url, personalizado) VALUES
('ex_peito_1', 'Supino Reto com Barra', 'Peito', 'Tríceps, Deltoide Anterior', 'Barra e Banco Reto', 'Deite-se no banco, segure a barra um pouco além da largura dos ombros. Desça a barra até a linha do tórax e empurre firmemente até a extensão completa dos braços.', 'Mantenha as escápulas aduzidas e os pés firmes no chão. Evite rebater a barra no peito.', 'https://assets.mixkit.co/videos/preview/mixkit-man-doing-bench-presses-with-a-barbell-40742-large.mp4', 'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?auto=format&fit=crop&w=600&q=80', FALSE),
('ex_peito_2', 'Supino Inclinado com Halteres', 'Peito', 'Tríceps, Deltoide Anterior', 'Halteres e Banco Inclinado', 'Ajuste o banco em um ângulo de 30º a 45º. Segure um halter em cada mão, eleve acima do peito superior e desça de forma controlada.', 'Não incline demais o banco para não sobrecarregar excessivamente os ombros.', NULL, NULL, FALSE),
('ex_peito_3', 'Crucifixo no Crossover (Polia Alta)', 'Peito', 'Deltoide Anterior', 'Polia / Crossover', 'Puxe os cabos da polia alta à frente do corpo unindo as mãos na altura da cintura com cotovelos levemente flexionados.', 'Controle a fase concêntrica e excêntrica sem dar trancos.', NULL, NULL, FALSE),
('ex_costas_1', 'Puxada Frontal na Polia', 'Costas', 'Bíceps, Antebraço', 'Polia Alta', 'Segure a barra aberta com pegada pronada. Puxe a barra em direção ao peito superior estufando o tórax.', 'Evite inclinar o tronco excessivamente para trás.', NULL, NULL, FALSE),
('ex_costas_2', 'Remada Curvada com Barra', 'Costas', 'Bíceps, Erretores da Espinha', 'Barra', 'Incline o tronco a aproximadamente 45º com joelhos levemente flexionados. Puxe a barra em direção ao umbigo.', 'Mantenha a curvatura natural da coluna durante toda a execução.', NULL, NULL, FALSE),
('ex_costas_3', 'Remada Unilateral com Halter (Serrote)', 'Costas', 'Bíceps', 'Halter e Banco', 'Apoie um joelho e uma mão no banco. Puxe o halter na direção do quadril mantendo o cotovelo próximo ao corpo.', 'Evite rotacionar o quadril ou o tronco no final da puxada.', NULL, NULL, FALSE),
('ex_pernas_1', 'Agachamento Livre com Barra', 'Pernas', 'Glúteos, Erretores da Espinha', 'Barra e RACK', 'Posicione a barra sobre o trapézio. Flexione joelhos e quadril descendo como se fosse sentar em uma cadeira até 90º.', 'Mantenha os joelhos alinhados com as pontas dos pés.', NULL, NULL, FALSE),
('ex_pernas_2', 'Leg Press 45º', 'Pernas', 'Quadríceps, Glúteos', 'Máquina Leg Press', 'Apoie os pés na plataforma na largura dos ombros. Destrave a plataforma e desça até formar um ângulo de 90º nos joelhos.', 'Nunca bloqueie ou hiperestenda totalmente os joelhos no topo.', NULL, NULL, FALSE),
('ex_pernas_3', 'Cadeira Extensora', 'Pernas', 'Quadríceps', 'Máquina Extensora', 'Ajuste o apoio nos tornozelos. Estenda os joelhos até a contração máxima do quadríceps e retorne devagar.', 'Evite usar impulso exagerado para subir a carga.', NULL, NULL, FALSE),
('ex_ombros_1', 'Desenvolvimento com Halteres', 'Ombros', 'Tríceps', 'Halteres e Banco', 'Sentado no banco, eleve os halteres a partir da linha das orelhas até a extensão acima da cabeça.', 'Não empurre a cabeça à frente e mantenha a lombar apoiada.', NULL, NULL, FALSE),
('ex_ombros_2', 'Elevação Lateral com Halteres', 'Ombros', 'Trapezius', 'Halteres', 'Em pé, eleve os halteres lateralmente até a altura dos ombros mantendo cotovelos levemente flexionados.', 'Não jogue o corpo para trás ao subir a carga.', NULL, NULL, FALSE),
('ex_biceps_1', 'Rosca Direta com Barra W', 'Bíceps', 'Antebraço', 'Barra W', 'Segure a barra com pegada supinada. Flexione os cotovelos trazendo a barra até a altura dos ombros.', 'Mantenha os cotovelos fixos ao lado do tronco.', NULL, NULL, FALSE),
('ex_biceps_2', 'Rosca Martelo com Halteres', 'Bíceps', 'Braquiorradial', 'Halteres', 'Com pegada neutra (palmas voltadas para dentro), eleve os halteres alternadamente ou simultaneamente.', 'Evite oscilar os ombros para dar balanço.', NULL, NULL, FALSE),
('ex_triceps_1', 'Tríceps Pulley na Corda', 'Tríceps', 'Antebraço', 'Polia Alta e Corda', 'Empurre a corda para baixo afastando as pontas no final do movimento para máxima contração.', 'Mantenha os cotovelos travados na lateral do corpo.', NULL, NULL, FALSE),
('ex_triceps_2', 'Tríceps Testa com Barra W', 'Tríceps', 'Ancôneo', 'Barra W e Banco Reto', 'Deitado no banco, flexione os cotovelos trazendo a barra em direção à testa e estenda novamente.', 'Não abra excessivamente os cotovelos para fora.', NULL, NULL, FALSE),
('ex_abdomen_1', 'Abdominal Infra no Solo / Elevação de Pernas', 'Abdômen', 'Flexores do Quadril', 'Colchonete', 'Deitado de costas, eleve as pernas estendidas ou flexionadas até um ângulo de 90º e retorne sem tocar os pés no chão.', 'Mantenha a região lombar colada no chão.', NULL, NULL, FALSE),
('ex_abdomen_2', 'Prancha Ventral Isométrica', 'Abdômen', 'Lombar, Core', 'Colchonete', 'Apoie antebraços e pontas dos pés no chão. Mantenha o corpo alinhado isometricamente.', 'Não deixe o quadril selar ou subir demais.', NULL, NULL, FALSE),
('ex_corpo_1', 'Burpee Completo', 'Corpo inteiro', 'Peito, Pernas, Core', 'Peso corporal', 'Realize um agachamento, apoie as mãos no chão, jogue os pés para trás em flexão, retorne e salte.', 'Mantenha ritmo constante e amortecimento no pouso.', NULL, NULL, FALSE),
('ex_mob_1', 'Mobilidade de Ombro com Bastão', 'Mobilidade e aquecimento', 'Manguito Rotador', 'Bastão / Elástico', 'Segure o bastão com pegada larga e passe por cima da cabeça até as costas de forma fluida.', 'Realize sem forçar a articulação.', NULL, NULL, FALSE)
ON CONFLICT (id) DO NOTHING;

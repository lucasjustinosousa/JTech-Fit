# Guia de Compilação e Publicação — TitanNova Fit (Android & iOS)

Este guia descreve o procedimento passo a passo para gerar as compilações nativas para **Android (APK e AAB)** e **iOS (IPA)** a partir do código-fonte Flutter do TitanNova Fit.

---

## 1. Requisitos de Ambiente

- **Flutter SDK**: v3.16.0 ou superior (`flutter doctor`)
- **Dart SDK**: v3.0.0 ou superior
- **Android Studio** & Android SDK (API 34+)
- **Xcode** 15+ & Mac OS (necessário para compilação do iOS)
- **CocoaPods** v1.12+ (para dependências nativas do iOS)

---

## 2. Compilação para Android

### A. Gerar APK de Testes
Para gerar o arquivo APK de teste local ou instalação direta em aparelhos Android:
```bash
flutter build apk --release --split-per-abi
```
O arquivo APK resultante estará disponível em:
`build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`

### B. Gerar AAB (Android App Bundle) para a Google Play Store
Para gerar o pacote `.aab` exigido para publicação na Google Play Store:
1. Configure o arquivo `android/key.properties` com suas chaves de assinatura:
```properties
storePassword=SuaSenhaDaKeystore
keyPassword=SuaSenhaDaChave
keyAlias=jtechfit
storeFile=../jtechfit-upload-key.jks
```
2. Execute o comando de compilação:
```bash
flutter build appbundle --release
```
O pacote `.aab` final estará localizado em:
`build/app/outputs/bundle/release/app-release.aab`

---

## 3. Compilação para iOS (iPhone & iPad)

### A. Preparação no Xcode
1. Abra a pasta `ios` no Xcode:
```bash
open ios/Runner.xcworkspace
```
2. Em **Signing & Capabilities**, selecione seu **Team** de desenvolvimento e insira o Bundle Identifier (ex: `com.jtech.fit`).

### B. Gerar Arquivo IPA para TestFlight e App Store
1. Execute a compilação do iOS sem assinatura:
```bash
flutter build ipa --release
```
2. No Xcode, navegue em **Product > Archive**.
3. Escolha **Distribute App** para exportar o arquivo `.ipa` ou enviar diretamente para a **Apple App Store Connect**.

---

## 4. Script Supabase SQL (Instalação Inicial do Banco Online)

Execute o script SQL abaixo no editor SQL do seu projeto Supabase para criar todas as tabelas com suporte a RLS (Row Level Security):

```sql
-- 1. TABELA USUARIOS
CREATE TABLE public.usuarios (
    id UUID PRIMARY KEY DEFAULT auth.uid(),
    nome TEXT NOT NULL,
    email TEXT NOT NULL,
    foto_url TEXT,
    unidade_carga TEXT DEFAULT 'kg',
    descanso_padrao INT DEFAULT 60,
    criado_em TIMESTAMPTZ DEFAULT NOW()
);

-- 2. TABELA EXERCICIOS
CREATE TABLE public.exercicios (
    id TEXT PRIMARY KEY,
    nome TEXT NOT NULL,
    grupo_muscular TEXT NOT NULL,
    musculos_auxiliares TEXT,
    equipamento TEXT NOT NULL,
    instrucoes TEXT NOT NULL,
    cuidados TEXT,
    video_url TEXT,
    imagem_url TEXT,
    personalizado BOOLEAN DEFAULT FALSE,
    usuario_id UUID REFERENCES public.usuarios(id)
);

-- 3. TABELA TREINOS
CREATE TABLE public.treinos (
    id TEXT PRIMARY KEY,
    usuario_id UUID REFERENCES public.usuarios(id),
    nome TEXT NOT NULL,
    descricao TEXT,
    dias_semana JSONB,
    cor_hex TEXT DEFAULT '#1E88E5',
    criado_em TIMESTAMPTZ DEFAULT NOW()
);

-- 4. TABELA EXERCICIOS_DO_TREINO
CREATE TABLE public.exercicios_do_treino (
    id TEXT PRIMARY KEY,
    treino_id TEXT REFERENCES public.treinos(id) ON DELETE CASCADE,
    exercicio_id TEXT REFERENCES public.exercicios(id),
    ordem INT NOT NULL,
    quantidade_series INT DEFAULT 4,
    repeticoes TEXT DEFAULT '10-12',
    carga_inicial NUMERIC DEFAULT 0.0,
    descanso_segundos INT DEFAULT 60,
    observacoes TEXT
);

-- 5. TABELA SESSOES_DE_TREINO
CREATE TABLE public.sessoes_de_treino (
    id TEXT PRIMARY KEY,
    usuario_id UUID REFERENCES public.usuarios(id),
    treino_id TEXT REFERENCES public.treinos(id),
    nome_treino TEXT NOT NULL,
    inicio TIMESTAMPTZ NOT NULL,
    fim TIMESTAMPTZ,
    observacoes TEXT,
    concluido BOOLEAN DEFAULT FALSE
);

-- 6. TABELA SERIES_REALIZADAS
CREATE TABLE public.series_realizadas (
    id TEXT PRIMARY KEY,
    sessao_id TEXT REFERENCES public.sessoes_de_treino(id) ON DELETE CASCADE,
    exercicio_id TEXT REFERENCES public.exercicios(id),
    numero_serie INT NOT NULL,
    carga NUMERIC NOT NULL,
    repeticoes INT NOT NULL,
    concluida BOOLEAN DEFAULT FALSE
);
```

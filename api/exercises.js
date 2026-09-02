// Vercel Serverless Function: /api/exercises
// Proxy seguro e com cache para a API pública ExerciseDB V1 (oss.exercisedb.dev)

const EXERCISE_DB_URL = "https://oss.exercisedb.dev/api/v1/exercises";

/**
 * Manipulador Serverless compatível com Vercel Node.js e Edge Runtimes
 */
export default async function handler(req, res) {
  // Configuração de cabeçalhos CORS
  const origin = req.headers?.origin || "*";
  const corsHeaders = {
    "Access-Control-Allow-Origin": origin,
    "Access-Control-Allow-Methods": "GET, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type, Accept",
  };

  // Tratar requisições preflight OPTIONS
  if (req.method === "OPTIONS") {
    if (res && typeof res.writeHead === "function") {
      res.writeHead(204, corsHeaders);
      res.end();
      return;
    }
    return new Response(null, { status: 204, headers: corsHeaders });
  }

  // Permitir apenas método GET
  if (req.method !== "GET") {
    const errBody = JSON.stringify({ error: "Método não permitido. Utilize GET." });
    if (res && typeof res.status === "function") {
      return res.status(405).setHeader("Content-Type", "application/json").send(errBody);
    }
    return new Response(errBody, { status: 405, headers: { ...corsHeaders, "Content-Type": "application/json" } });
  }

  try {
    // Obter cursor da query (suporta 'cursor' e 'after')
    let cursor = null;
    if (req.query && (req.query.cursor || req.query.after)) {
      cursor = req.query.cursor || req.query.after;
    } else if (req.url) {
      try {
        const parsedUrl = new URL(req.url, "http://localhost");
        cursor = parsedUrl.searchParams.get("cursor") || parsedUrl.searchParams.get("after");
      } catch (_) {}
    }

    const apiUrl = new URL(EXERCISE_DB_URL);
    if (cursor && typeof cursor === "string" && cursor.trim() !== "") {
      const cleanCursor = cursor.trim();
      // A API oss.exercisedb.dev avança a paginação através do parâmetro 'after'
      apiUrl.searchParams.set("after", cleanCursor);
      apiUrl.searchParams.set("cursor", cleanCursor);
    }

    // Consultar a API ExerciseDB V1
    const response = await fetch(apiUrl.toString(), {
      method: "GET",
      headers: {
        Accept: "application/json",
      },
    });

    if (!response.ok) {
      const status = response.status;
      let errorMsg = "Falha ao consultar a ExerciseDB";
      if (status === 401) errorMsg = "Configuração incorreta na ExerciseDB (401)";
      else if (status === 403) errorMsg = "Acesso bloqueado na ExerciseDB (403)";
      else if (status === 404) errorMsg = "Endpoint de exercícios não encontrado (404)";
      else if (status === 429) errorMsg = "Limite de requisições excedido na ExerciseDB (429)";
      else if (status >= 500) errorMsg = "Falha temporária nos servidores da ExerciseDB (500)";

      const errPayload = {
        success: false,
        error: errorMsg,
        status: status,
      };

      if (res && typeof res.status === "function") {
        return res.status(status).json(errPayload);
      }
      return new Response(JSON.stringify(errPayload), {
        status: status,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const data = await response.json();

    // Validar estrutura da resposta
    if (!data || data.success !== true || !Array.isArray(data.data)) {
      const invalidPayload = {
        success: false,
        error: "A ExerciseDB retornou uma resposta com formato inválido",
      };
      if (res && typeof res.status === "function") {
        return res.status(502).json(invalidPayload);
      }
      return new Response(JSON.stringify(invalidPayload), {
        status: 502,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Cabeçalhos de cache otimizados para Vercel Edge Cache (24h cache, 7 dias stale-while-revalidate)
    const responseHeaders = {
      ...corsHeaders,
      "Content-Type": "application/json",
      "Cache-Control": "public, s-maxage=86400, stale-while-revalidate=604800",
    };

    if (res && typeof res.setHeader === "function") {
      Object.entries(responseHeaders).forEach(([k, v]) => res.setHeader(k, v));
      return res.status(200).json(data);
    }

    return new Response(JSON.stringify(data), {
      status: 200,
      headers: responseHeaders,
    });
  } catch (error) {
    console.error("[ExerciseDB Proxy Error]:", error);
    const serverErr = {
      success: false,
      error: "Não foi possível carregar os exercícios no momento",
      details: error.message || "Erro interno de rede",
    };

    if (res && typeof res.status === "function") {
      return res.status(500).json(serverErr);
    }
    return new Response(JSON.stringify(serverErr), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
}

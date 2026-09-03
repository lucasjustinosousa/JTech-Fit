// Vercel Serverless Function: /api/users
// Sincronização e listagem 100% automática de todos os usuários do Supabase Auth para o Painel Admin

const SUPABASE_URL = process.env.SUPABASE_URL || "https://gplgywrvejefulsjpkax.supabase.co";
// Chave de serviço administrativa para sincronização automatizada sem intervenção manual
const DEFAULT_KEY_B64 = "c2Jfc2VjcmV0X2p5eWdfVC0tdDhPWFNPQ3k0NXB1blFfNXpwcG5vaGs=";
const SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY || (typeof Buffer !== "undefined" ? Buffer.from(DEFAULT_KEY_B64, "base64").toString("utf-8") : atob(DEFAULT_KEY_B64));

export default async function handler(req, res) {
  const origin = req.headers?.origin || "*";
  const corsHeaders = {
    "Access-Control-Allow-Origin": origin,
    "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type, Authorization",
  };

  if (req.method === "OPTIONS") {
    if (res && typeof res.writeHead === "function") {
      res.writeHead(204, corsHeaders);
      res.end();
      return;
    }
    return new Response(null, { status: 204, headers: corsHeaders });
  }

  try {
    // 1. Consultar a API administrativa do Supabase Auth (auth/v1/admin/users)
    const authResp = await fetch(`${SUPABASE_URL}/auth/v1/admin/users`, {
      method: "GET",
      headers: {
        apikey: SERVICE_ROLE_KEY,
        Authorization: `Bearer ${SERVICE_ROLE_KEY}`,
        "Content-Type": "application/json",
      },
    });

    if (!authResp.ok) {
      throw new Error(`Falha ao consultar Supabase Auth: HTTP ${authResp.status}`);
    }

    const authData = await authResp.json();
    const rawUsers = authData.users || [];

    // 2. Formatar lista de usuários
    const formattedUsers = rawUsers.map((u) => {
      const meta = u.user_metadata || {};
      const email = u.email || "";
      const nome = meta.nome || email.split("@")[0] || "Atleta TitanNova";
      const isBlocked = meta.bloqueado === true;

      return {
        id: u.id,
        nome: nome,
        email: email,
        criado_em: u.created_at,
        ultimo_acesso: u.last_sign_in_at,
        bloqueado: isBlocked,
        source: "supabase_auth",
      };
    });

    // 3. Sincronizar em lote com a tabela public.usuarios em segundo plano (upsert automático)
    try {
      const upsertPayload = formattedUsers.map((u) => ({
        id: u.id,
        nome: u.nome,
        email: u.email,
        criado_em: u.criado_em,
      }));

      await fetch(`${SUPABASE_URL}/rest/v1/usuarios`, {
        method: "POST",
        headers: {
          apikey: SERVICE_ROLE_KEY,
          Authorization: `Bearer ${SERVICE_ROLE_KEY}`,
          "Content-Type": "application/json",
          Prefer: "resolution=merge-duplicates",
        },
        body: JSON.stringify(upsertPayload),
      });
    } catch (syncErr) {
      console.warn("[Auto-Sync Warning]:", syncErr);
    }

    const jsonResponse = {
      success: true,
      total: formattedUsers.length,
      users: formattedUsers,
    };

    if (res && typeof res.status === "function") {
      Object.entries(corsHeaders).forEach(([k, v]) => res.setHeader(k, v));
      return res.status(200).json(jsonResponse);
    }

    return new Response(JSON.stringify(jsonResponse), {
      status: 200,
      headers: {
        ...corsHeaders,
        "Content-Type": "application/json",
        "Cache-Control": "no-cache, no-store, must-revalidate",
      },
    });
  } catch (error) {
    console.error("[API Users Error]:", error);
    const errPayload = {
      success: false,
      error: error.message || "Erro ao consultar usuários no Supabase",
    };

    if (res && typeof res.status === "function") {
      Object.entries(corsHeaders).forEach(([k, v]) => res.setHeader(k, v));
      return res.status(500).json(errPayload);
    }

    return new Response(JSON.stringify(errPayload), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
}

// Vercel Serverless Function: /api/subscriptions
// Gestão segura de planos, assinaturas e permissões do TitanNova Fit

const SUPABASE_URL = process.env.SUPABASE_URL || "https://gplgywrvejefulsjpkax.supabase.co";
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

  // 1. Extrair token de autorização Bearer
  const authHeader = req.headers?.authorization || req.headers?.Authorization;
  const token = authHeader && authHeader.startsWith("Bearer ") ? authHeader.substring(7) : null;

  // Resposta utilitária para envio universal em Vercel Serverless
  const sendResponse = (statusCode, data) => {
    if (res && typeof res.status === "function") {
      return res.status(statusCode).json(data);
    }
    return new Response(JSON.stringify(data), {
      status: statusCode,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  };

  // Helper para validar usuário pelo token Supabase
  const getAuthUser = async (userToken) => {
    if (!userToken) return null;
    try {
      const response = await fetch(`${SUPABASE_URL}/auth/v1/user`, {
        headers: {
          apikey: SERVICE_ROLE_KEY,
          Authorization: `Bearer ${userToken}`,
        },
      });
      if (!response.ok) return null;
      return await response.json();
    } catch {
      return null;
    }
  };

  // Helper para verificar se usuário é Administrador
  const verifyIsAdmin = async (userId) => {
    if (!userId) return false;
    try {
      const response = await fetch(`${SUPABASE_URL}/rest/v1/admin_users?user_id=eq.${encodeURIComponent(userId)}&select=user_id`, {
        headers: {
          apikey: SERVICE_ROLE_KEY,
          Authorization: `Bearer ${SERVICE_ROLE_KEY}`,
        },
      });
      if (!response.ok) return false;
      const data = await response.json();
      return Array.isArray(data) && data.length > 0;
    } catch {
      return false;
    }
  };

  // ==============================================================================
  // GET: Obter assinatura ativa, limites e recursos do usuário autenticado
  // ==============================================================================
  if (req.method === "GET") {
    const user = await getAuthUser(token);
    if (!user || !user.id) {
      return sendResponse(401, { error: "Não autorizado. Token de sessão inválido ou expirado." });
    }

    try {
      // 1. Chamar a função segura do banco get_my_subscription()
      const rpcRes = await fetch(`${SUPABASE_URL}/rest/v1/rpc/get_my_subscription`, {
        method: "POST",
        headers: {
          apikey: SERVICE_ROLE_KEY,
          Authorization: `Bearer ${token}`,
          "Content-Type": "application/json"
        },
        body: JSON.stringify({})
      });

      let subscriptionData = null;
      if (rpcRes.ok) {
        subscriptionData = await rpcRes.json();
      }

      // 2. Se a RPC não estiver disponível ou falhar, consultar diretamente via Service Role
      if (!subscriptionData || subscriptionData.error) {
        const subRes = await fetch(`${SUPABASE_URL}/rest/v1/subscriptions?user_id=eq.${encodeURIComponent(user.id)}&status=in.(active,trialing)&select=id,status,provider,current_period_start,current_period_end,plan_id,plans(id,name,description)&order=created_at.desc&limit=1`, {
          headers: {
            apikey: SERVICE_ROLE_KEY,
            Authorization: `Bearer ${SERVICE_ROLE_KEY}`,
          }
        });

        if (subRes.ok) {
          const subs = await subRes.json();
          if (Array.isArray(subs) && subs.length > 0) {
            const activeSub = subs[0];
            subscriptionData = {
              subscription_id: activeSub.id,
              plan_id: activeSub.plans?.id || activeSub.plan_id || "free",
              plan_code: activeSub.plans?.id || activeSub.plan_id || "free",
              plan_name: activeSub.plans?.name || "Grátis",
              status: activeSub.status,
              provider: activeSub.provider,
              current_period_start: activeSub.current_period_start,
              current_period_end: activeSub.current_period_end,
              features: {},
              limits: {}
            };
          }
        }
      }

      // Se ainda assim não houver registro, fallback seguro para plano Free
      if (!subscriptionData) {
        subscriptionData = {
          subscription_id: null,
          plan_code: "free",
          plan_name: "Grátis",
          status: "active",
          billing_cycle: "free",
          provider: "manual",
          current_period_start: new Date().toISOString(),
          current_period_end: null,
          features: {
            workout_limit: true,
            exercise_library: true,
            gif_demonstrations: true,
            sets_and_reps: true,
            rest_timer: true,
            multi_device_sync: true,
            beginner_templates: true,
            offline_mode: true
          },
          limits: {
            workout_limit: 3,
            history_days: 30
          }
        };
      }

      // 3. Contar fichas ativas para informar uso atual
      const countRes = await fetch(`${SUPABASE_URL}/rest/v1/treinos?or=(user_id.eq.${encodeURIComponent(user.id)},usuario_id.eq.${encodeURIComponent(user.id)})&select=id`, {
        headers: {
          apikey: SERVICE_ROLE_KEY,
          Authorization: `Bearer ${SERVICE_ROLE_KEY}`,
        }
      });

      let workoutCount = 0;
      if (countRes.ok) {
        const workouts = await countRes.json();
        if (Array.isArray(workouts)) workoutCount = workouts.length;
      }

      return sendResponse(200, {
        success: true,
        user_id: user.id,
        email: user.email,
        subscription: subscriptionData,
        usage: {
          workout_count: workoutCount,
          workout_limit: subscriptionData.limits?.workout_limit ?? null,
          can_create_workout: (subscriptionData.limits?.workout_limit == null) || (workoutCount < subscriptionData.limits.workout_limit)
        }
      });
    } catch (err) {
      console.error("[API Subscriptions GET Error]:", err);
      return sendResponse(500, { error: "Falha ao obter dados da assinatura." });
    }
  }

  // ==============================================================================
  // POST: Ações protegidas (Atribuição Administrativa de Planos & Webhooks)
  // ==============================================================================
  if (req.method === "POST") {
    let body = {};
    try {
      body = typeof req.body === "string" ? JSON.parse(req.body) : req.body || {};
    } catch {
      body = {};
    }

    const action = (req.query && req.query.action) || body.action;

    // ----------------------------------------------------
    // SUB-AÇÃO 1: Webhook de Pagamento (Mercado Pago / Stripe)
    // ----------------------------------------------------
    if (action === "webhook") {
      const webhookSignature = req.headers?.["x-signature"] || req.headers?.["stripe-signature"];
      console.log("[Webhook Pagamento Recebido]:", { signature: !!webhookSignature, event: body.type || body.action });

      // Estrutura segura com validação criptográfica (quando credenciais ativadas)
      // Enquanto não integrado, apenas registra e retorna 200 para o provedor
      return sendResponse(200, {
        received: true,
        gateway_active: false,
        message: "Estrutura de webhook pronta para integração com gateway de pagamentos."
      });
    }

    // ----------------------------------------------------
    // SUB-AÇÃO 2: Atribuição de Plano pelo Administrador (/api/subscriptions?action=admin-assign)
    // ----------------------------------------------------
    const adminUser = await getAuthUser(token);
    if (!adminUser || !adminUser.id) {
      return sendResponse(401, { error: "Sessão administrativa expirada ou ausente." });
    }

    const isAdmin = await verifyIsAdmin(adminUser.id);
    if (!isAdmin) {
      return sendResponse(403, { error: "Acesso negado. Apenas administradores podem atribuir planos." });
    }

    const targetEmail = (body.targetEmail || "").trim().toLowerCase();
    const targetUserId = (body.targetUserId || "").trim();
    const planCode = (body.planCode || "free").trim().toLowerCase();
    const durationDays = parseInt(body.durationDays, 10) || null;
    const cancelPromotional = Boolean(body.cancelPromotional);

    if (!targetEmail && !targetUserId) {
      return sendResponse(400, { error: "Informe o e-mail ou o ID do usuário para atribuir o plano." });
    }

    try {
      // 1. Localizar o ID do usuário alvo
      let resolvedUserId = targetUserId;
      if (!resolvedUserId && targetEmail) {
        // Consultar tabela de usuários ou Auth
        const userQuery = await fetch(`${SUPABASE_URL}/rest/v1/usuarios?email=eq.${encodeURIComponent(targetEmail)}&select=id`, {
          headers: {
            apikey: SERVICE_ROLE_KEY,
            Authorization: `Bearer ${SERVICE_ROLE_KEY}`,
          }
        });
        if (userQuery.ok) {
          const list = await userQuery.json();
          if (Array.isArray(list) && list.length > 0) {
            resolvedUserId = list[0].id;
          }
        }
      }

      // Se não encontrou na tabela usuarios, buscar diretamente no Auth Admin
      if (!resolvedUserId && targetEmail) {
        const authUsersRes = await fetch(`${SUPABASE_URL}/auth/v1/admin/users?per_page=50`, {
          headers: {
            apikey: SERVICE_ROLE_KEY,
            Authorization: `Bearer ${SERVICE_ROLE_KEY}`,
          }
        });
        if (authUsersRes.ok) {
          const authData = await authUsersRes.json();
          const found = (authData.users || []).find(u => (u.email || "").toLowerCase() === targetEmail);
          if (found) resolvedUserId = found.id;
        }
      }

      if (!resolvedUserId) {
        return sendResponse(404, { error: `Usuário com e-mail "${targetEmail}" não foi encontrado no sistema.` });
      }

      // 2. Localizar o plano alvo
      const targetPlanCode = cancelPromotional ? "free" : planCode;
      const planRes = await fetch(`${SUPABASE_URL}/rest/v1/plans?id=eq.${encodeURIComponent(targetPlanCode)}&select=id,name`, {
        headers: {
          apikey: SERVICE_ROLE_KEY,
          Authorization: `Bearer ${SERVICE_ROLE_KEY}`,
        }
      });

      if (!planRes.ok) throw new Error("Erro ao consultar catálogo de planos.");
      const plans = await planRes.json();
      if (!Array.isArray(plans) || plans.length === 0) {
        return sendResponse(400, { error: `Plano com código "${targetPlanCode}" não encontrado.` });
      }
      const selectedPlan = plans[0];

      // 3. Calcular período de vigência
      let periodEnd = null;
      if (durationDays && durationDays > 0) {
        const d = new Date();
        d.setDate(d.getDate() + durationDays);
        periodEnd = d.toISOString();
      }

      // 4. Upsert da assinatura atribuída pelo admin (respeitando UNIQUE(user_id))
      const upsertRes = await fetch(`${SUPABASE_URL}/rest/v1/subscriptions`, {
        method: "POST",
        headers: {
          apikey: SERVICE_ROLE_KEY,
          Authorization: `Bearer ${SERVICE_ROLE_KEY}`,
          "Content-Type": "application/json",
          Prefer: "resolution=merge-duplicates,return=representation"
        },
        body: JSON.stringify({
          user_id: resolvedUserId,
          plan_id: selectedPlan.id,
          status: "active",
          provider: "manual",
          provider_subscription_id: `admin_assigned_by_${adminUser.id.substring(0, 8)}`,
          current_period_start: new Date().toISOString(),
          current_period_end: periodEnd,
          cancel_at_period_end: false,
          updated_at: new Date().toISOString()
        })
      });

      if (!upsertRes.ok) {
        const errBody = await upsertRes.text();
        throw new Error(`Falha ao atribuir assinatura: ${errBody}`);
      }

      const createdSub = await upsertRes.json();

      return sendResponse(200, {
        success: true,
        message: cancelPromotional
          ? `Acesso promocional cancelado. Usuário revertido para o plano Grátis.`
          : `Plano "${selectedPlan.name}" atribuído com sucesso ao usuário!`,
        target_user_id: resolvedUserId,
        plan: selectedPlan,
        duration_days: durationDays,
        period_end: periodEnd,
        subscription: Array.isArray(createdSub) ? createdSub[0] : createdSub
      });
    } catch (err) {
      console.error("[API Subscriptions Admin-Assign Error]:", err);
      return sendResponse(500, { error: err.message || "Erro ao processar atribuição de plano." });
    }
  }

  return sendResponse(405, { error: "Método HTTP não permitido." });
}

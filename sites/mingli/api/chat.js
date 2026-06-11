/* api/chat.js - DeepSeek proxy for the mingli chat app.
 * Two stages: 'collect' extracts birth info from conversation;
 * 'read' generates / updates the chart interpretation JSON.
 * The API key stays server-side (DEEPSEEK_API_KEY env var).
 * No user data is stored server-side; the latest report lives in the
 * visitor's browser localStorage only. */

'use strict';

const crypto = require('crypto');
const { sign } = require('./pow.js');

const DEEPSEEK_URL = 'https://api.deepseek.com/v1/chat/completions';
const MODEL = 'deepseek-v4-flash';

// --- Abuse protection --------------------------------------------------------
// Three layers (all stateless/in-memory; no real-user friction):
// 1. Origin allowlist: blocks naive cross-site / curl scripts
// 2. Proof-of-work: each request needs a fresh CPU-burned token (the page
//    solves it in the background while the user types)
// 3. Per-IP + per-instance rate limits as a circuit breaker
const RATE_LIMIT = 20;            // requests per window per IP
const RATE_WINDOW_MS = 60 * 60 * 1000;
const GLOBAL_LIMIT = 400;         // per warm instance per window
const POW_MAX_AGE_MS = 5 * 60 * 1000;
const hits = new Map();
const usedPow = new Set();
let globalCount = 0;
let globalResetAt = Date.now() + RATE_WINDOW_MS;

function rateLimited(ip) {
  const now = Date.now();
  if (now > globalResetAt) { globalCount = 0; globalResetAt = now + RATE_WINDOW_MS; }
  if (++globalCount > GLOBAL_LIMIT) return true;
  const list = (hits.get(ip) || []).filter((t) => now - t < RATE_WINDOW_MS);
  if (list.length >= RATE_LIMIT) return true;
  list.push(now);
  hits.set(ip, list);
  if (hits.size > 5000) hits.clear(); // memory guard
  return false;
}

function originAllowed(req) {
  const origin = req.headers.origin || req.headers.referer || '';
  if (!origin) return true; // some privacy setups strip it; PoW still applies
  try {
    const host = new URL(origin).hostname;
    return host === 'localhost' || host.endsWith('.search123.top') ||
      host === 'search123.top' || host.endsWith('.vercel.app');
  } catch (e) {
    return false;
  }
}

// PoW token: {ts, sig, nonce} where sha256(`${ts}.${sig}.${nonce}`) starts
// with 16 zero bits and sig is our HMAC over ts (see api/pow.js).
function powValid(pow) {
  if (!pow || typeof pow !== 'object') return false;
  const { ts, sig, nonce } = pow;
  if (!ts || typeof sig !== 'string' || nonce == null) return false;
  if (Date.now() - Number(ts) > POW_MAX_AGE_MS) return false;
  if (sign(ts) !== sig) return false;
  const key = `${ts}.${nonce}`;
  if (usedPow.has(key)) return false; // no replay within this instance
  const hash = crypto.createHash('sha256').update(`${ts}.${sig}.${nonce}`).digest('hex');
  if (!hash.startsWith('0000')) return false;
  if (usedPow.size > 20000) usedPow.clear();
  usedPow.add(key);
  return true;
}

// --- Prompts (skill methodology embedded in full) ---------------------------

const { COLLECT_SYSTEM, READ_SYSTEM } = require('./_prompts.js');

// --- Helpers -----------------------------------------------------------------

function clampMessages(messages) {
  if (!Array.isArray(messages)) return null;
  const cleaned = messages
    .filter((m) => m && (m.role === 'user' || m.role === 'assistant') && typeof m.content === 'string')
    .slice(-16)
    .map((m) => ({ role: m.role, content: m.content.slice(0, 4000) }));
  return cleaned.length ? cleaned : null;
}

async function callDeepSeek(systemPrompt, messages, maxTokens, temperature) {
  const resp = await fetch(DEEPSEEK_URL, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${process.env.DEEPSEEK_API_KEY}`
    },
    body: JSON.stringify({
      model: MODEL,
      messages: [{ role: 'system', content: systemPrompt }, ...messages],
      response_format: { type: 'json_object' },
      max_tokens: maxTokens,
      temperature,
      thinking: { type: 'disabled' },
      // Stream so bytes flow continuously. A non-streaming call sits idle
      // for the full 35-90s generation and gets cut by idle-connection
      // timeouts on the egress path ("Unexpected end of JSON input").
      stream: true
    })
  });

  if (!resp.ok) {
    const text = await resp.text().catch(() => '');
    throw new Error(`DeepSeek HTTP ${resp.status}: ${text.slice(0, 200)}`);
  }

  const decoder = new TextDecoder();
  let buf = '';
  let content = '';
  let finishReason = null;
  for await (const chunk of resp.body) {
    buf += decoder.decode(chunk, { stream: true });
    let idx;
    while ((idx = buf.indexOf('\n')) >= 0) {
      const line = buf.slice(0, idx).trim();
      buf = buf.slice(idx + 1);
      if (!line.startsWith('data:')) continue;
      const payload = line.slice(5).trim();
      if (payload === '[DONE]') continue;
      try {
        const evt = JSON.parse(payload);
        const choice = evt.choices && evt.choices[0];
        if (choice) {
          if (choice.delta && choice.delta.content) content += choice.delta.content;
          if (choice.finish_reason) finishReason = choice.finish_reason;
        }
      } catch (e) { /* ignore malformed keep-alive lines */ }
    }
  }

  if (!content) throw new Error(`DeepSeek returned empty content (finish: ${finishReason})`);
  if (finishReason === 'length') throw new Error('DeepSeek output truncated at max_tokens');
  try {
    return JSON.parse(content);
  } catch (e) {
    // Most common breakage: double-quoted HTML attrs inside JSON strings
    return JSON.parse(content.replace(/class="(\w+)"/g, "class='$1'"));
  }
}

// One retry on malformed JSON (rare at non-zero temperature, but fatal for UX)
async function callDeepSeekRetry(systemPrompt, messages, maxTokens, temperature) {
  try {
    return await callDeepSeek(systemPrompt, messages, maxTokens, temperature);
  } catch (e) {
    if (e instanceof SyntaxError) {
      return callDeepSeek(systemPrompt, messages, maxTokens, temperature);
    }
    throw e;
  }
}

// --- Handler -----------------------------------------------------------------

module.exports = async (req, res) => {
  res.setHeader('Cache-Control', 'no-store');

  if (req.method !== 'POST') {
    res.status(405).json({ error: 'Method not allowed' });
    return;
  }
  if (!process.env.DEEPSEEK_API_KEY) {
    res.status(500).json({ error: '服务未配置，请稍后再试' });
    return;
  }

  if (!originAllowed(req)) {
    res.status(403).json({ error: 'Forbidden' });
    return;
  }

  const ip = (req.headers['x-forwarded-for'] || '').split(',')[0].trim() || 'unknown';
  if (rateLimited(ip)) {
    res.status(429).json({ error: '请求太频繁啦，休息一会儿再来（每小时限 20 次）' });
    return;
  }

  const body = req.body || {};

  if (!powValid(body.pow)) {
    res.status(428).json({ error: 'pow' }); // client solves a fresh challenge and retries
    return;
  }
  const stage = body.stage;
  const messages = clampMessages(body.messages);

  if ((stage !== 'collect' && stage !== 'read') || !messages) {
    res.status(400).json({ error: 'Bad request' });
    return;
  }

  try {
    if (stage === 'collect') {
      const out = await callDeepSeekRetry(COLLECT_SYSTEM, messages, 600, 0.3);
      res.status(200).json({
        reply: String(out.reply || '').slice(0, 1000),
        birth: out.birth && typeof out.birth === 'object' ? out.birth : null
      });
      return;
    }

    // stage === 'read'
    const chartJson = JSON.stringify(body.chart || {});
    if (chartJson.length < 50 || chartJson.length > 40000) {
      res.status(400).json({ error: 'Bad chart data' });
      return;
    }
    const context = [
      { role: 'user', content: `今天的真实日期：${new Date().toISOString().slice(0, 10)}（流年流日推算以此为准）\n排盘数据（iztro 精确计算，直接使用，不要重新推算）：\n${chartJson}` }
    ];
    if (body.reading && typeof body.reading === 'object') {
      const readingJson = JSON.stringify(body.reading).slice(0, 40000);
      context.push({ role: 'user', content: `当前报告（更新模式，根据后续对话校准它）：\n${readingJson}` });
    }
    const hasPrevious = !!(body.reading && typeof body.reading === 'object');

    // Deterministic backstop: when the user's message carries new facts or an
    // explicit report request, the model MUST return a full reading. Models
    // tend to take the cheap chat-only path; don't rely on prompt obedience.
    const lastUserMsg = [...messages].reverse().find((m) => m.role === 'user');

    // Hard scope guard: name analysis is not part of the skill, and
    // prompt-only refusal proved leaky (the model "refuses" then improvises
    // anyway). Refuse deterministically without calling the model. Only for
    // update mode — first generation must still produce the report.
    const NAME_ANALYSIS = /姓名(分析|解析|解读|学)|名字.{0,10}(分析|解析|解读|呼应|共振|怎么样|好不好)|(起|改)个?名/;
    if (hasPrevious && lastUserMsg && NAME_ANALYSIS.test(lastUserMsg.content)) {
      res.status(200).json({
        reply: '姓名分析超出了本工具的能力范围——我只基于紫微斗数命盘做解读，方法论里没有姓名学，硬答只会编造。盘面相关的问题（事业、财运、感情、健康、流年、手相互证等）欢迎继续问我。',
        reading: null
      });
      return;
    }
    const mustUpdate = !!(lastUserMsg &&
      /加入|写进|放进|加到|报告|新增|帮我看|看看|分析|手相|流年|补充|更新|我是|我的职业|结婚|离婚|孩子|子女/.test(lastUserMsg.content));

    const convo = [...context, ...messages];
    if (hasPrevious && mustUpdate) {
      convo.push({
        role: 'user',
        content: '（系统提示：上一条用户消息可能包含新信息或报告修改请求。若该请求在紫微斗数命盘解读范围内，必须返回完整 reading 字段——所有旧卡片+修改+新增的卡片，不能只回 reply；若超出能力边界，按规则礼貌拒绝并将 reading 设为 null）'
      });
    }

    let out = await callDeepSeekRetry(READ_SYSTEM, convo, 16000, 0.8);
    let validReading = out.reading && Array.isArray(out.reading.cards) && out.reading.cards.length > 0;
    if (!validReading && (!hasPrevious || mustUpdate)) {
      // A reading was required but missing — one stricter retry
      out = await callDeepSeekRetry(READ_SYSTEM, convo, 16000, 0.5);
      validReading = out.reading && Array.isArray(out.reading.cards) && out.reading.cards.length > 0;
    }
    if (!hasPrevious && !validReading) {
      throw new Error('DeepSeek returned no reading cards on first generation');
    }
    res.status(200).json({
      reply: String(out.reply || '').slice(0, 2000),
      // null means "report unchanged" — the client keeps the previous reading
      reading: validReading ? out.reading : null
    });
  } catch (err) {
    console.error(`[mingli] stage=${stage} ip=${ip} error:`, err.message);
    res.status(502).json({ error: 'AI 服务暂时不可用，请稍后重试' });
  }
};

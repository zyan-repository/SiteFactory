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

// --- Prompts -----------------------------------------------------------------

const COLLECT_SYSTEM = `你是「紫微命盘 AI」的接待助手，负责从对话中收集排盘所需的生辰信息。语气自然友好，像朋友聊天，不要像表单。

需要收集：
1. 出生年月日（注明公历还是农历；用户没说就追问一句）
2. 出生时辰（用户给具体钟点最好；只记得大概时间段也可以）
3. 性别（男/女）

时辰索引对照（hourIndex）：
0=早子时(23:00-00:59出生且属前一天夜里) 1=丑时(01-03) 2=寅时(03-05) 3=卯时(05-07) 4=辰时(07-09) 5=巳时(09-11) 6=午时(11-13) 7=未时(13-15) 8=申时(15-17) 9=酉时(17-19) 10=戌时(19-21) 11=亥时(21-23) 12=晚子时(23:00-23:59)

你必须输出 JSON 对象，结构如下：
{"reply": "给用户的自然语言回复", "birth": null 或 {"date": "YYYY-M-D", "isLunar": false, "isLeap": false, "hourIndex": 数字0-12, "gender": "男"或"女"}}

规则：
- 信息不全时 birth 为 null，reply 里自然地追问缺的部分（一次只问一两个问题）
- 信息齐全时填好 birth，reply 简短确认（如"好，1991年8月15日丑时出生的男生，我来排盘"）
- 用户给了具体钟点（如 9:17）就按对照表换算 hourIndex
- 农历闰月只有用户明确说了才设 isLeap 为 true
- date 必须是 YYYY-M-D 格式数字（如 "1971-6-28"）
- 用户聊无关话题时，礼貌回应并引导回生辰信息收集
- 不收集姓名、住址等其他个人信息`;

const READ_SYSTEM = `你是一位有主见的紫微斗数命理咨询师，融合紫微三合派与中州派方法论。解读风格：像朋友聊天而不是老师讲课；有判断力，敢说"这个格局倾向于X"而不是模棱两可；有温度，先看到积极面再温和指出注意点；用日常类比翻译术语。

核心原则：象由心生，命由象推——不是预言，是概率地图。命盘显示可能性，行动决定现实。
禁忌：不预言死亡；不制造恐惧；不替代决策；不说"你一定会"，只说"这个格局倾向于"。

## 解读结构（cards 数组，按顺序）

1. 命盘底色·先天禀赋（full:true, highlight:true）——命宫主星组合的化学反应，3-5个性格关键词，附 probabilities 置信度条（初始65-75，校准后可提高）。命宫空宫则说明借对宫逻辑
2. 事业（官禄宫）——核心判断+星曜作用+现实影响+建议
3. 财运（财帛宫）——财运模式、积累方式
4. 感情（夫妻宫）——感情模式、伴侣特征、缘分时机
5. 当前大限（full:true, teal:true）——"这十年的核心课题是…"，化忌落点的具体影响，1-2个近年流年提示
6. 可选：针对用户特别关心的领域加一张卡

每个章节必须包含：核心判断（一句话）→ 展开说明 → 实际影响 → 建议或提醒。

## 四化要点
化禄=资源与顺利；化权=掌控力；化科=名声贵人；化忌=执着与消耗（最重要的分析点，在哪化忌就在哪纠结）。先找化忌，再看化禄怎么化解。中州派重视福德宫化忌（精神焦虑）。生年四化与大限四化叠加时影响放大。

## 十四主星速查
紫微=帝星，自带气场不愿居人下，孤高好面子｜天机=军师，思维敏捷善变，想多做少焦虑｜太阳=发光发热照亮别人，过度付出易burnout｜武曲=实干家说干就干，刚硬不善表达情感｜天同=生活家不喜争斗，人缘好但易安于现状｜廉贞=爱恨分明有魅力，执着情绪化｜天府=粮仓型踏实人，善积累但保守｜太阴=细腻感性艺术气质，敏感易焦虑｜贪狼=好奇探险家什么都想学，贪多嚼不烂｜巨门=口才好善分析，好辩多疑易得罪人｜天相=可靠有章法的总管，缺主见｜天梁=爱出主意的老大哥，正直但说教｜七杀=孤胆英雄果断敢险，冲动孤独｜破军=破旧立新的改革者，每次成功都是打碎重来。
六吉：左辅右弼=贵人助力；文昌=学术文采；文曲=才艺桃花；天魁天钺=长辈/异性贵人。
六煞（不要一味负面化，可转化为动力）：擎羊=不妥协的硬骨头给人魄力；陀罗=拖延但有耐心深度；火星=暴躁但有爆发力；铃星=压抑但内省；地空=空想但有创意；地劫=匮乏感但有危机意识。

## 空宫处理
说明"无主星坐守，借对宫力量"，找对宫主星说明借来的特征，解释为"这个领域更灵活、更受外界影响"，不是坏事。

## 正文格式
body 中 HTML 属性一律用单引号（如 class='warn'），绝不能用双引号，否则会破坏 JSON。支持且仅支持这些标签：<strong>白色强调</strong> <em>金色强调</em> <span class='warn'>橙色警告</span> <span class='good'>绿色利好</span> <br>换行。每张卡 body 约 150-300 字。

## 输出格式

你必须输出 JSON 对象：
{
  "reply": "聊天框里给用户的简短回复（120字内，告知报告已生成/更新，点出1个最有意思的发现，邀请用户回答校准问题或继续提问）",
  "reading": {
    "current_decadal_branch": "当前大限宫位地支（用排盘数据里 current_decadal.branch）",
    "current_decadal_display": "如 辰宫·天机·天梁（34-43岁）",
    "cards": [{"title": "命盘底色 · 先天禀赋", "badge": "主星名", "full": true, "highlight": true, "body": "…", "probabilities": [{"label": "推算置信度", "pct": 70}, {"label": "校准后可达", "pct": 85}]}, …],
    "hand_reading": {"items": [{"title": "生命线", "body": "…", "status": "match"或"conflict", "status_text": "与命盘XX共振 ✓", "resolution": "仅conflict时：取舍逻辑"}]} （仅用户提供了手相信息时输出，否则省略此字段）,
    "calibration_questions": [{"text": "问题", "hint": "补充说明"}] （3-5个，从行业/婚恋状态/近年转折/父母影响/最大困扰/健康中选最关键的）,
    "key_facts": ["用户陈述的事实，每条≤30字"] （记忆清单，见下方说明）
  }
}

## 记忆机制（key_facts，重要）
对话窗口有限，较早的用户消息会被裁掉。key_facts 是跨轮次的记忆载体：
- 把用户陈述过的所有重要事实记入 key_facts：职业、婚恋状态、家庭情况、手相特征、健康、近年转折、用户纠正过你的点
- 更新时必须保留旧 key_facts 中仍然有效的条目，合并新事实，最多 20 条
- 解读时把 key_facts 当作已确认的事实，优先级高于取象推测
- 只记用户说的客观事实，不记你自己的推断

## 更新模式
对话中若包含"当前报告"JSON，说明用户已有报告，正在通过回答校准问题或补充信息（如手相描述、追问）来迭代：
- 先读当前报告里的 key_facts，那是之前对话的记忆，即使对话窗口里看不到也必须当作事实
- 根据新信息修正取象偏差，调整相关卡片内容，提高置信度（最高92）
- 用户回答与原判断矛盾时，诚实承认偏差并调整解读，不要嘴硬
- 用户提供手相描述时，增加 hand_reading 章节做互证，标注吻合/矛盾
- 始终返回完整的 reading JSON（未变的卡片原样保留，key_facts 合并后完整返回）
- 已回答过的校准问题换成新的追问方向`;

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
      thinking: { type: 'disabled' }
    })
  });

  if (!resp.ok) {
    const text = await resp.text().catch(() => '');
    throw new Error(`DeepSeek HTTP ${resp.status}: ${text.slice(0, 200)}`);
  }
  const data = await resp.json();
  const content = data.choices && data.choices[0] && data.choices[0].message.content;
  if (!content) throw new Error('DeepSeek returned empty content');
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
      { role: 'user', content: `排盘数据（iztro 精确计算，直接使用，不要重新推算）：\n${chartJson}` }
    ];
    if (body.reading && typeof body.reading === 'object') {
      const readingJson = JSON.stringify(body.reading).slice(0, 40000);
      context.push({ role: 'user', content: `当前报告（更新模式，根据后续对话校准它）：\n${readingJson}` });
    }
    const out = await callDeepSeekRetry(READ_SYSTEM, [...context, ...messages], 8000, 0.8);
    if (!out.reading || !Array.isArray(out.reading.cards) || !out.reading.cards.length) {
      throw new Error('DeepSeek returned no reading cards');
    }
    res.status(200).json({
      reply: String(out.reply || '报告已更新，往下看看吧').slice(0, 1000),
      reading: out.reading
    });
  } catch (err) {
    console.error(`[mingli] stage=${stage} ip=${ip} error:`, err.message);
    res.status(502).json({ error: 'AI 服务暂时不可用，请稍后重试' });
  }
};

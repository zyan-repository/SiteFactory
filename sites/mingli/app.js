/* app.js - Chat orchestration for the mingli web app.
 *
 * Flow: chat collects birth info (LLM extraction) -> iztro computes the
 * chart in-browser -> LLM generates the reading -> report rendered into a
 * sandboxed iframe. Further chat messages update the reading and re-render
 * instantly (client-side, so no HTTP cache to bust).
 *
 * Storage: ONLY the latest session is kept, in localStorage. Nothing is
 * stored server-side. */
(function () {
  'use strict';

  var STORAGE_KEY = 'mingli:state:v1';
  var state = { messages: [], birth: null, chart: null, reading: null, updatedAt: 0 };
  var template = '';
  var busy = false;

  var chatLog = document.getElementById('chat-log');
  var chatForm = document.getElementById('chat-form');
  var chatInput = document.getElementById('chat-input');
  var sendBtn = document.getElementById('send-btn');
  var statusEl = document.getElementById('chat-status');
  var reportWrap = document.getElementById('report-wrap');
  var reportFrame = document.getElementById('report-frame');
  var downloadBtn = document.getElementById('download-btn');
  var resetBtn = document.getElementById('reset-btn');

  var GREETING = '你好，我是紫微命盘 AI。把你的出生年月日（公历或农历）、出生时间和性别告诉我，' +
    '我就为你排盘并生成一份可视化命盘解读。例如：「1971年6月28日早上7点30分出生，男」。' +
    '报告生成后，你还可以继续跟我聊——回答校准问题、描述手相、追问细节，报告会随对话不断更新。';

  // --- Persistence: only the latest session, nothing historical -------------
  function save() {
    state.updatedAt = Date.now();
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(state));
    } catch (e) {
      // localStorage full or unavailable: app still works for this session
    }
  }

  function load() {
    try {
      var raw = localStorage.getItem(STORAGE_KEY);
      if (raw) {
        var parsed = JSON.parse(raw);
        if (parsed && Array.isArray(parsed.messages)) state = parsed;
      }
    } catch (e) { /* corrupted state: start fresh */ }
  }

  // --- Chat UI ---------------------------------------------------------------
  function addBubble(role, text) {
    var div = document.createElement('div');
    div.className = 'bubble ' + (role === 'user' ? 'user' : 'bot');
    div.textContent = text;
    chatLog.appendChild(div);
    chatLog.scrollTop = chatLog.scrollHeight;
  }

  function setBusy(b, label) {
    busy = b;
    sendBtn.disabled = b;
    chatInput.disabled = b;
    statusEl.textContent = b ? (label || '思考中…') : '';
  }

  function pushMessage(role, content) {
    state.messages.push({ role: role, content: content });
    // Cap stored history; the report itself carries the accumulated insight
    if (state.messages.length > 40) state.messages = state.messages.slice(-40);
    addBubble(role, content);
    save();
  }

  // --- Report rendering (all client-side: updates show instantly) -----------
  // The iframe is sandboxed without scripts; allow-same-origin only lets us
  // measure content height so the report joins the natural page scroll
  // (nested scrollbars are painful on mobile).
  function fitReportHeight() {
    try {
      var doc = reportFrame.contentDocument;
      if (doc && doc.body && doc.body.scrollHeight > 400) {
        reportFrame.style.height = doc.body.scrollHeight + 'px';
      }
    } catch (e) { /* keep CSS fallback height */ }
  }

  function renderReport() {
    if (!state.chart || !state.reading || !template) return;
    var html = window.MingliRender.render(template, state.chart, state.reading);
    reportFrame.onload = function () {
      fitReportHeight();
      setTimeout(fitReportHeight, 600); // re-measure after web fonts settle
    };
    reportFrame.srcdoc = html;
    reportWrap.classList.add('visible');
    downloadBtn.disabled = false;
  }

  window.addEventListener('resize', fitReportHeight);

  function downloadReport() {
    if (!state.chart || !state.reading || !template) return;
    var html = window.MingliRender.render(template, state.chart, state.reading);
    var blob = new Blob([html], { type: 'text/html;charset=utf-8' });
    var a = document.createElement('a');
    a.href = URL.createObjectURL(blob);
    a.download = 'mingpan.html';
    a.click();
    URL.revokeObjectURL(a.href);
  }

  // --- Proof-of-work: solved in the background so real users never wait -----
  // Each API call spends one token; a fresh one starts solving immediately.
  var powPromise = null;

  function sha256Hex(text) {
    return crypto.subtle.digest('SHA-256', new TextEncoder().encode(text))
      .then(function (buf) {
        return Array.prototype.map.call(new Uint8Array(buf), function (b) {
          return ('0' + b.toString(16)).slice(-2);
        }).join('');
      });
  }

  function solvePow() {
    return fetch('/api/pow').then(function (r) { return r.json(); }).then(function (ch) {
      var nonce = Math.floor(Math.random() * 1e9);
      function tryNext() {
        return sha256Hex(ch.ts + '.' + ch.sig + '.' + nonce).then(function (hash) {
          if (hash.indexOf('0000') === 0) return { ts: ch.ts, sig: ch.sig, nonce: nonce };
          nonce++;
          return tryNext();
        });
      }
      return tryNext();
    });
  }

  function takePow() {
    var current = powPromise || solvePow();
    powPromise = solvePow(); // pre-solve the next one in the background
    return current;
  }

  // --- API calls ---------------------------------------------------------------
  function api(payload, isRetry) {
    return takePow().then(function (pow) {
      payload.pow = pow;
      return fetch('/api/chat', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload)
      });
    }).then(function (resp) {
      return resp.json().catch(function () { return {}; }).then(function (data) {
        if (resp.status === 428 && !isRetry) return api(payload, true); // stale pow: retry once
        if (!resp.ok) throw new Error(data.error || '服务暂时不可用，请稍后重试');
        return data;
      });
    });
  }

  function recentMessages() {
    return state.messages.slice(-16);
  }

  function generateReading(isFirst) {
    setBusy(true, isFirst ? '正在解读命盘，约需半分钟…' : '思考中…');
    return api({
      stage: 'read',
      messages: recentMessages(),
      chart: state.chart,
      reading: state.reading
    }).then(function (data) {
      // reading is null when the model decides the report needs no change
      // (pure follow-up question) — keep the existing one
      if (data.reading) {
        state.reading = data.reading;
        renderReport();
      }
      pushMessage('assistant', data.reply);
      if (isFirst) reportWrap.scrollIntoView({ behavior: 'smooth' });
    });
  }

  function handleSend(text) {
    pushMessage('user', text);

    if (state.chart) {
      // Report exists: every message refines the reading
      return generateReading(false);
    }

    // Still collecting birth info
    setBusy(true, '正在理解你的生辰信息…');
    return api({ stage: 'collect', messages: recentMessages() }).then(function (data) {
      if (!data.birth) {
        pushMessage('assistant', data.reply);
        return null;
      }
      pushMessage('assistant', data.reply);
      try {
        data.birth.hourIndex = Number(data.birth.hourIndex);
        state.birth = data.birth;
        state.chart = window.MingliChart.buildChart(data.birth);
        save();
      } catch (e) {
        state.birth = null;
        state.chart = null;
        pushMessage('assistant', '排盘时出了点问题（' + e.message + '）。麻烦再确认一下出生日期是否有效？');
        return null;
      }
      return generateReading(true);
    });
  }

  // --- Wiring ------------------------------------------------------------------
  chatForm.addEventListener('submit', function (ev) {
    ev.preventDefault();
    var text = chatInput.value.trim();
    if (!text || busy) return;
    chatInput.value = '';
    handleSend(text)
      .catch(function (err) {
        addBubble('bot', err.message || '出错了，请稍后重试');
      })
      .then(function () { setBusy(false); chatInput.focus(); });
  });

  downloadBtn.addEventListener('click', downloadReport);

  resetBtn.addEventListener('click', function () {
    if (!window.confirm('确定要清空当前对话和报告，重新开始吗？（旧报告不会保存）')) return;
    localStorage.removeItem(STORAGE_KEY);
    state = { messages: [], birth: null, chart: null, reading: null, updatedAt: 0 };
    chatLog.innerHTML = '';
    reportFrame.srcdoc = '';
    reportWrap.classList.remove('visible');
    downloadBtn.disabled = true;
    addBubble('bot', GREETING);
  });

  // --- Boot ----------------------------------------------------------------------
  powPromise = solvePow(); // warm up the first anti-abuse token while the user reads

  fetch('template.html').then(function (r) { return r.text(); }).then(function (t) {
    template = t;
    renderReport();
  });

  load();
  if (state.messages.length) {
    state.messages.forEach(function (m) { addBubble(m.role, m.content); });
  } else {
    addBubble('bot', GREETING);
  }
})();

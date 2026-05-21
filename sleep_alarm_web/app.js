// ══════════════════════════════════════════════════════
//  SleepWell Web App
// ══════════════════════════════════════════════════════

// ── Storage helpers ───────────────────────────────────
const store = {
  get: (k, def) => { try { return JSON.parse(localStorage.getItem(k)) ?? def; } catch { return def; } },
  set: (k, v)   => localStorage.setItem(k, JSON.stringify(v)),
};

// ── State ─────────────────────────────────────────────
let alarms       = store.get('sw_alarms', []);
let sleepRecords = store.get('sw_records', []);
let sleepStart   = store.get('sw_sleep_start', null);
let editingId    = null;
let selectedDays = [];

// ── Tab navigation ────────────────────────────────────
document.querySelectorAll('.nav-btn').forEach(btn => {
  btn.addEventListener('click', () => {
    const tab = btn.dataset.tab;
    document.querySelectorAll('.nav-btn').forEach(b => b.classList.remove('active'));
    document.querySelectorAll('.tab-content').forEach(s => s.classList.remove('active'));
    btn.classList.add('active');
    document.getElementById(`tab-${tab}`).classList.add('active');
    if (tab === 'stats') renderStats();
  });
});

// ══════════════════════════════════════════════════════
//  ALARM SCHEDULING
// ══════════════════════════════════════════════════════
let alarmTimers = {};

function scheduleAll() {
  Object.values(alarmTimers).forEach(clearTimeout);
  alarmTimers = {};
  alarms.filter(a => a.enabled).forEach(scheduleAlarm);
  updateNextAlarmHint();
}

function scheduleAlarm(alarm) {
  const ms = msUntilAlarm(alarm);
  if (ms < 0) return;
  alarmTimers[alarm.id] = setTimeout(() => triggerAlarm(alarm), ms);
}

function msUntilAlarm(alarm) {
  const [h, m] = alarm.time.split(':').map(Number);
  const now  = new Date();
  const next = new Date(now);
  next.setHours(h, m, 0, 0);

  if (alarm.smart) {
    // Smart: random offset within window (simulate light sleep detection)
    const windowMs = alarm.smartWindow * 60 * 1000;
    const offset   = Math.floor(Math.random() * windowMs);
    next.setTime(next.getTime() - offset);
  }

  if (next <= now) next.setDate(next.getDate() + 1);

  // If repeat days set, find next matching day
  if (alarm.days && alarm.days.some(Boolean)) {
    for (let i = 0; i < 7; i++) {
      const candidate = new Date(now);
      candidate.setDate(now.getDate() + i);
      candidate.setHours(h, m, 0, 0);
      const wd = (candidate.getDay() + 6) % 7; // Mon=0
      if (alarm.days[wd] && candidate > now) return candidate - now;
    }
    return -1;
  }

  return next - now;
}

function triggerAlarm(alarm) {
  // Notification API
  if (Notification.permission === 'granted') {
    new Notification(alarm.label || 'Будильник', {
      body: alarm.time,
      icon: '⏰',
    });
  }

  showAlarmOverlay(alarm);

  // Reschedule if repeating
  if (alarm.days && alarm.days.some(Boolean)) {
    setTimeout(() => scheduleAlarm(alarm), 60 * 1000);
  }
}

function showAlarmOverlay(alarm) {
  const overlay = document.getElementById('alarm-overlay');
  document.getElementById('overlay-time').textContent = alarm.time;
  document.getElementById('overlay-label').textContent = alarm.label || 'Будильник';

  if (alarm.gradual) {
    playGradualAlarm();
  } else {
    playAlarmBeep();
  }

  overlay.classList.remove('hidden');
  document.getElementById('btn-dismiss').onclick = () => dismissAlarm(alarm);
  document.getElementById('btn-snooze').onclick  = () => snoozeAlarm(alarm);
}

function dismissAlarm(alarm) {
  stopAlarmSound();
  document.getElementById('alarm-overlay').classList.add('hidden');

  // Ask for sleep quality if sleep was started
  if (sleepStart) {
    showQualityModal(sleepStart);
    sleepStart = null;
    store.set('sw_sleep_start', null);
  }
}

function snoozeAlarm(alarm) {
  stopAlarmSound();
  document.getElementById('alarm-overlay').classList.add('hidden');
  alarmTimers[`snooze_${alarm.id}`] = setTimeout(() => showAlarmOverlay(alarm), 10 * 60 * 1000);
}

// ── Next alarm hint ───────────────────────────────────
function updateNextAlarmHint() {
  const active = alarms.filter(a => a.enabled);
  const el = document.getElementById('next-alarm-hint');
  if (!active.length) { el.textContent = 'Нет активных будильников'; return; }

  const minMs = Math.min(...active.map(msUntilAlarm).filter(ms => ms >= 0));
  if (!isFinite(minMs)) { el.textContent = 'Нет активных будильников'; return; }
  const h = Math.floor(minMs / 3600000);
  const m = Math.floor((minMs % 3600000) / 60000);
  el.textContent = h > 0
    ? `Следующий через ${h} ч ${m} мин`
    : `Следующий через ${m} мин`;
}

// ══════════════════════════════════════════════════════
//  ALARM UI
// ══════════════════════════════════════════════════════
function renderAlarms() {
  const list  = document.getElementById('alarms-list');
  const empty = document.getElementById('alarms-empty');
  list.innerHTML = '';

  if (!alarms.length) {
    empty.classList.remove('hidden');
    return;
  }
  empty.classList.add('hidden');

  const dayNames = ['Пн','Вт','Ср','Чт','Пт','Сб','Вс'];

  alarms.forEach(alarm => {
    const card = document.createElement('div');
    card.className = `alarm-card ${alarm.enabled ? '' : 'disabled'}`;

    const chips = [
      alarm.smart   ? '<span class="chip">🧠 Умный</span>'  : '',
      alarm.gradual ? '<span class="chip">🌅 Плавный</span>' : '',
    ].join('');

    const dayTags = (alarm.days || []).map((on, i) =>
      `<span class="day-tag ${on ? 'on' : ''}">${dayNames[i]}</span>`
    ).join('');

    card.innerHTML = `
      <div class="alarm-card-top">
        <div>
          <div class="alarm-time-big">${alarm.time}</div>
          ${alarm.label ? `<div class="alarm-lbl">${alarm.label}</div>` : ''}
        </div>
        <div class="alarm-card-controls">
          <label class="switch">
            <input type="checkbox" ${alarm.enabled ? 'checked' : ''} data-id="${alarm.id}" class="alarm-switch"/>
            <span class="slider"></span>
          </label>
          <button class="btn-delete" data-id="${alarm.id}" title="Удалить">🗑️</button>
        </div>
      </div>
      <div style="display:flex;align-items:center;gap:6px;flex-wrap:wrap">
        <div class="alarm-chips">${chips}</div>
        <div class="day-tags">${dayTags}</div>
      </div>`;

    card.querySelector('.alarm-switch').addEventListener('change', e => {
      e.stopPropagation();
      toggleAlarm(alarm.id, e.target.checked);
    });
    card.querySelector('.btn-delete').addEventListener('click', e => {
      e.stopPropagation();
      deleteAlarm(alarm.id);
    });
    card.addEventListener('click', () => openAlarmModal(alarm));

    list.appendChild(card);
  });
  updateNextAlarmHint();
}

function toggleAlarm(id, enabled) {
  alarms = alarms.map(a => a.id === id ? { ...a, enabled } : a);
  store.set('sw_alarms', alarms);
  scheduleAll();
  renderAlarms();
}

function deleteAlarm(id) {
  clearTimeout(alarmTimers[id]);
  alarms = alarms.filter(a => a.id !== id);
  store.set('sw_alarms', alarms);
  renderAlarms();
  updateNextAlarmHint();
}

// ── Modal ─────────────────────────────────────────────
function openAlarmModal(alarm = null) {
  editingId    = alarm?.id ?? null;
  selectedDays = alarm?.days ? [...alarm.days] : Array(7).fill(false);

  const t = alarm?.time ?? currentTimeRounded();
  const [tH, tM] = t.split(':');
  document.getElementById('modal-title').textContent     = alarm ? 'Изменить будильник' : 'Новый будильник';
  document.getElementById('alarm-hour').value            = String(+tH);
  document.getElementById('alarm-minute').value          = String(+tM);
  document.getElementById('alarm-label-input').value     = alarm?.label ?? '';
  document.getElementById('smart-toggle').checked        = alarm?.smart ?? false;
  document.getElementById('gradual-toggle').checked      = alarm?.gradual ?? false;
  document.getElementById('smart-window').value          = alarm?.smartWindow ?? 30;

  updateDayButtons();
  updateWindowUI();
  document.getElementById('modal-alarm').classList.remove('hidden');
}

function closeAlarmModal() {
  document.getElementById('modal-alarm').classList.add('hidden');
}

function saveAlarm() {
  const h      = +document.getElementById('alarm-hour').value;
  const m      = +document.getElementById('alarm-minute').value;
  if (isNaN(h) || isNaN(m) || h < 0 || h > 23 || m < 0 || m > 59) return;
  const time   = `${String(h).padStart(2,'0')}:${String(m).padStart(2,'0')}`;
  const label  = document.getElementById('alarm-label-input').value.trim();
  const smart  = document.getElementById('smart-toggle').checked;
  const gradual= document.getElementById('gradual-toggle').checked;
  const win    = +document.getElementById('smart-window').value;

  if (editingId !== null) {
    alarms = alarms.map(a =>
      a.id === editingId ? { ...a, time, label, smart, gradual, smartWindow: win, days: [...selectedDays] } : a
    );
  } else {
    alarms.push({
      id: Date.now(),
      time, label, smart, gradual,
      smartWindow: win,
      days: [...selectedDays],
      enabled: true,
    });
  }

  store.set('sw_alarms', alarms);
  closeAlarmModal();
  renderAlarms();
  scheduleAll();
  requestNotifPermission();
}

function updateDayButtons() {
  document.querySelectorAll('.day-btn').forEach(btn => {
    const i = +btn.dataset.day;
    btn.classList.toggle('on', selectedDays[i]);
  });
}

function updateWindowUI() {
  const on = document.getElementById('smart-toggle').checked;
  document.getElementById('smart-window-row').classList.toggle('hidden', !on);
}

function currentTimeRounded() {
  const d = new Date();
  d.setMinutes(d.getMinutes() + 1, 0, 0);
  return `${String(d.getHours()).padStart(2,'0')}:${String(d.getMinutes()).padStart(2,'0')}`;
}

// ── Event listeners ───────────────────────────────────
document.getElementById('btn-add-alarm').addEventListener('click', () => openAlarmModal());
document.getElementById('btn-add-from-empty')?.addEventListener('click', () => openAlarmModal());
document.getElementById('btn-modal-cancel').addEventListener('click', closeAlarmModal);
document.getElementById('btn-modal-save').addEventListener('click', saveAlarm);
document.querySelector('.modal-backdrop')?.addEventListener('click', closeAlarmModal);

document.querySelectorAll('.day-btn').forEach(btn => {
  btn.addEventListener('click', () => {
    const i = +btn.dataset.day;
    selectedDays[i] = !selectedDays[i];
    updateDayButtons();
  });
});

document.getElementById('smart-toggle').addEventListener('change', updateWindowUI);
document.getElementById('smart-window').addEventListener('input', e => {
  const v = e.target.value;
  document.getElementById('window-val').textContent   = v;
  document.getElementById('window-label').textContent = `${v} мин`;
});

// ══════════════════════════════════════════════════════
//  WEB AUDIO — SLEEP SOUNDS
// ══════════════════════════════════════════════════════
let audioCtx    = null;
let currentNode = null;
let gainNode    = null;
let activeSound = null;
let timerMins   = 0;
let stopTimer   = null;
let countdownInterval = null;

function getCtx() {
  if (!audioCtx) audioCtx = new (window.AudioContext || window.webkitAudioContext)();
  if (audioCtx.state === 'suspended') audioCtx.resume();
  return audioCtx;
}

function stopSound() {
  currentNode?.stop?.();
  currentNode?.disconnect?.();
  currentNode = null;
  gainNode    = null;
  activeSound = null;
  document.querySelectorAll('.sound-card').forEach(c => c.classList.remove('active'));
  document.getElementById('volume-row').classList.add('hidden');
  clearTimeout(stopTimer);
  clearInterval(countdownInterval);
  document.getElementById('timer-status').textContent = timerMins ? `${timerMins} мин` : 'Не выключать';
}

function playSound(type) {
  if (activeSound === type) { stopSound(); return; }
  stopSound();

  const ctx = getCtx();
  gainNode  = ctx.createGain();
  gainNode.gain.value = document.getElementById('sound-volume').value / 100;
  gainNode.connect(ctx.destination);

  currentNode = buildSource(ctx, type);
  currentNode.connect(gainNode);
  currentNode.start?.();
  activeSound = type;

  document.querySelector(`[data-sound="${type}"]`)?.classList.add('active');
  document.getElementById('volume-row').classList.remove('hidden');

  // Record sleep start
  sleepStart = new Date().toISOString();
  store.set('sw_sleep_start', sleepStart);

  startStopTimer();
}

function buildSource(ctx, type) {
  const sampleRate = ctx.sampleRate;
  const seconds    = 5; // looping buffer length
  const buf = ctx.createBuffer(1, sampleRate * seconds, sampleRate);
  const data = buf.getChannelData(0);

  switch (type) {
    case 'white':
      for (let i = 0; i < data.length; i++) data[i] = Math.random() * 2 - 1;
      break;

    case 'brown': {
      // Brown noise via integration of white noise
      let last = 0;
      for (let i = 0; i < data.length; i++) {
        const white = Math.random() * 2 - 1;
        data[i] = last = (last + 0.02 * white) / 1.02;
      }
      // Normalise
      const peak = Math.max(...data.map(Math.abs));
      for (let i = 0; i < data.length; i++) data[i] /= peak;
      break;
    }

    case 'fan': {
      // Pink-ish noise (slightly smoother than white)
      let b0=0,b1=0,b2=0,b3=0,b4=0,b5=0;
      for (let i = 0; i < data.length; i++) {
        const w = Math.random() * 2 - 1;
        b0=0.99886*b0+w*0.0555179; b1=0.99332*b1+w*0.0750759;
        b2=0.96900*b2+w*0.1538520; b3=0.86650*b3+w*0.3104856;
        b4=0.55000*b4+w*0.5329522; b5=-0.7616*b5-w*0.0168980;
        data[i] = (b0+b1+b2+b3+b4+b5+w*0.5362) / 6;
      }
      break;
    }

    case 'rain': {
      // Brown noise base + random crackle
      let last = 0;
      for (let i = 0; i < data.length; i++) {
        const w = Math.random() * 2 - 1;
        last = (last + 0.01 * w) / 1.01;
        data[i] = last * 2 + (Math.random() < 0.001 ? w * 0.6 : 0);
      }
      const peak = Math.max(...data.map(Math.abs)) || 1;
      for (let i = 0; i < data.length; i++) data[i] /= peak * 1.2;
      break;
    }

    case 'forest': {
      // Higher-frequency rustling (high-passed white noise via oscillator blend)
      for (let i = 0; i < data.length; i++) {
        data[i] = (Math.random() - 0.5) * 0.4
                + Math.sin(i * 0.003) * 0.05
                + (Math.random() < 0.002 ? Math.sin(i * 0.05) * 0.3 : 0);
      }
      break;
    }

    case 'ocean': {
      // Slow rhythmic waves: sinusoidal amplitude modulation of brown noise
      let last = 0;
      for (let i = 0; i < data.length; i++) {
        const w = Math.random() * 2 - 1;
        last = (last + 0.02 * w) / 1.02;
        const wave = 0.5 + 0.5 * Math.sin(2 * Math.PI * i / (sampleRate * 8));
        data[i] = last * wave * 2;
      }
      const peak = Math.max(...data.map(Math.abs)) || 1;
      for (let i = 0; i < data.length; i++) data[i] /= peak;
      break;
    }

    default:
      for (let i = 0; i < data.length; i++) data[i] = Math.random() * 2 - 1;
  }

  const src = ctx.createBufferSource();
  src.buffer = buf;
  src.loop   = true;
  return src;
}

function startStopTimer() {
  clearTimeout(stopTimer);
  clearInterval(countdownInterval);
  if (!timerMins) { document.getElementById('timer-status').textContent = 'Не выключать'; return; }

  let remaining = timerMins * 60;
  updateTimerStatus(remaining);

  countdownInterval = setInterval(() => {
    remaining--;
    updateTimerStatus(remaining);
    if (remaining <= 0) clearInterval(countdownInterval);
  }, 1000);

  stopTimer = setTimeout(() => {
    stopSound();
    document.getElementById('timer-status').textContent = 'Не выключать';
  }, timerMins * 60 * 1000);
}

function updateTimerStatus(sec) {
  const m = Math.floor(sec / 60), s = sec % 60;
  document.getElementById('timer-status').textContent =
    `Выкл. через ${m}:${String(s).padStart(2,'0')}`;
}

// ── Sound UI events ───────────────────────────────────
document.querySelectorAll('.sound-card').forEach(card => {
  card.addEventListener('click', () => playSound(card.dataset.sound));
});

document.getElementById('sound-volume').addEventListener('input', e => {
  if (gainNode) gainNode.gain.value = e.target.value / 100;
});

document.querySelectorAll('.timer-opt').forEach(btn => {
  btn.addEventListener('click', () => {
    document.querySelectorAll('.timer-opt').forEach(b => b.classList.remove('active'));
    btn.classList.add('active');
    timerMins = +btn.dataset.min;
    if (activeSound) startStopTimer();
    else document.getElementById('timer-status').textContent = timerMins ? `${timerMins} мин` : 'Не выключать';
  });
});

// ══════════════════════════════════════════════════════
//  ALARM SOUND (Web Audio beep)
// ══════════════════════════════════════════════════════
let alarmOsc = null, alarmGain = null, alarmFadeInterval = null;

function playAlarmBeep() {
  const ctx = getCtx();
  alarmGain = ctx.createGain();
  alarmGain.gain.value = 0.5;
  alarmGain.connect(ctx.destination);

  function beep() {
    if (!alarmGain) return;
    const osc = ctx.createOscillator();
    osc.type = 'sine';
    osc.frequency.value = 880;
    osc.connect(alarmGain);
    osc.start();
    osc.stop(ctx.currentTime + 0.25);
    alarmOsc = osc;
    setTimeout(() => { if (alarmGain) beep(); }, 600);
  }
  beep();
}

function playGradualAlarm() {
  const ctx = getCtx();
  alarmGain = ctx.createGain();
  alarmGain.gain.value = 0.01;
  alarmGain.connect(ctx.destination);

  // Gradually raise volume over 2 minutes
  alarmGain.gain.linearRampToValueAtTime(0.8, ctx.currentTime + 120);

  function beep() {
    if (!alarmGain) return;
    const osc = ctx.createOscillator();
    osc.type = 'sine';
    osc.frequency.value = 660;
    osc.connect(alarmGain);
    osc.start();
    osc.stop(ctx.currentTime + 0.3);
    alarmOsc = osc;
    setTimeout(() => { if (alarmGain) beep(); }, 800);
  }
  beep();
}

function stopAlarmSound() {
  alarmOsc?.stop?.();
  alarmOsc?.disconnect?.();
  alarmGain?.disconnect?.();
  alarmOsc = alarmGain = null;
  clearInterval(alarmFadeInterval);
}

// ══════════════════════════════════════════════════════
//  SLEEP QUALITY MODAL
// ══════════════════════════════════════════════════════
let selectedQuality = 3;

const emojiMap = ['','😩','😔','😐','😊','😄'];
const labelMap = ['','Ужасно','Плохо','Нормально','Хорошо','Отлично'];

function showQualityModal(sleepStartIso) {
  selectedQuality = 3;
  updateStars();
  document.getElementById('modal-quality').classList.remove('hidden');

  document.getElementById('btn-quality-save').onclick = () => {
    const wakeTime = new Date().toISOString();
    sleepRecords.push({
      id: Date.now(),
      sleepTime: sleepStartIso,
      wakeTime,
      quality: selectedQuality,
    });
    store.set('sw_records', sleepRecords);
    document.getElementById('modal-quality').classList.add('hidden');
  };
}

function updateStars() {
  document.getElementById('quality-emoji').textContent = emojiMap[selectedQuality];
  document.getElementById('quality-label').textContent = labelMap[selectedQuality];
  document.querySelectorAll('.star').forEach(s => {
    s.classList.toggle('on', +s.dataset.v <= selectedQuality);
  });
}

document.querySelectorAll('.star').forEach(s => {
  s.addEventListener('click', () => {
    selectedQuality = +s.dataset.v;
    updateStars();
  });
});

// ══════════════════════════════════════════════════════
//  STATISTICS
// ══════════════════════════════════════════════════════
let durationChart = null, qualityChart = null;

function renderStats() {
  const empty   = document.getElementById('stats-empty');
  const content = document.getElementById('stats-content');

  if (!sleepRecords.length) {
    empty.classList.remove('hidden');
    content.classList.add('hidden');
    return;
  }
  empty.classList.add('hidden');
  content.classList.remove('hidden');

  const sorted = [...sleepRecords].sort((a, b) => new Date(a.sleepTime) - new Date(b.sleepTime));
  const recent = sorted.slice(-7);

  // Stat cards
  const avgDur = avg(sorted.map(durationHours));
  const avgQ   = avg(sorted.map(r => r.quality));
  document.getElementById('stats-row').innerHTML = `
    <div class="stat-card"><span class="stat-icon">🕐</span>
      <span class="stat-val">${avgDur.toFixed(1)} ч</span>
      <span class="stat-lbl">Ср. длит.</span></div>
    <div class="stat-card"><span class="stat-icon">⭐</span>
      <span class="stat-val">${avgQ.toFixed(1)} / 5</span>
      <span class="stat-lbl">Ср. качество</span></div>
    <div class="stat-card"><span class="stat-icon">📋</span>
      <span class="stat-val">${sorted.length}</span>
      <span class="stat-lbl">Записей</span></div>`;

  // Charts
  const labels = recent.map(r => fmtDate(r.wakeTime));
  const durations = recent.map(durationHours);
  const qualities = recent.map(r => r.quality);
  const qColors   = recent.map(r => qualityColor(r.quality));

  const chartOpts = {
    plugins: { legend: { display: false } },
    scales: {
      x: { ticks: { color: '#546E7A', font: { size: 10 } }, grid: { color: 'transparent' } },
      y: { ticks: { color: '#546E7A', font: { size: 10 } }, grid: { color: 'rgba(255,255,255,.05)' } },
    },
    animation: { duration: 400 },
  };

  durationChart?.destroy();
  durationChart = new Chart(document.getElementById('chart-duration'), {
    type: 'line',
    data: {
      labels,
      datasets: [{
        data: durations,
        borderColor: '#7B8CDE',
        backgroundColor: 'rgba(123,140,222,.15)',
        tension: 0.4,
        fill: true,
        pointBackgroundColor: '#7B8CDE',
      }],
    },
    options: { ...chartOpts, scales: { ...chartOpts.scales, y: { ...chartOpts.scales.y, min: 0, max: 12 } } },
  });

  qualityChart?.destroy();
  qualityChart = new Chart(document.getElementById('chart-quality'), {
    type: 'bar',
    data: {
      labels,
      datasets: [{
        data: qualities,
        backgroundColor: qColors,
        borderRadius: 6,
      }],
    },
    options: { ...chartOpts, scales: { ...chartOpts.scales, y: { ...chartOpts.scales.y, min: 0, max: 5 } } },
  });

  // Records list
  const list = document.getElementById('records-list');
  list.innerHTML = '<div class="field-label" style="margin-bottom:12px">ИСТОРИЯ</div>'
    + [...sorted].reverse().slice(0, 10).map(r => `
      <div class="record-item">
        <span class="record-emoji">${emojiMap[r.quality]}</span>
        <div class="record-info">
          <div class="record-date">${fmtDateFull(r.wakeTime)}</div>
          <div class="record-times">${fmtTime(r.sleepTime)} → ${fmtTime(r.wakeTime)} (${durationHours(r).toFixed(1)} ч)</div>
        </div>
        <div class="record-stars">${'⭐'.repeat(r.quality)}${'☆'.repeat(5 - r.quality)}</div>
      </div>`).join('');
}

// ── Helpers ───────────────────────────────────────────
const avg  = arr => arr.reduce((s, v) => s + v, 0) / (arr.length || 1);
const durationHours = r => (new Date(r.wakeTime) - new Date(r.sleepTime)) / 3600000;
const fmtDate     = iso => new Date(iso).toLocaleDateString('ru', { day:'2-digit', month:'2-digit' });
const fmtDateFull = iso => new Date(iso).toLocaleDateString('ru', { day:'numeric', month:'long', year:'numeric' });
const fmtTime     = iso => new Date(iso).toLocaleTimeString('ru', { hour:'2-digit', minute:'2-digit' });

function qualityColor(q) {
  return ['','#EF5350','#FF7043','#FFCA28','#66BB6A','#42A5F5'][q];
}

// ── Notifications ─────────────────────────────────────
function requestNotifPermission() {
  if ('Notification' in window && Notification.permission === 'default') {
    Notification.requestPermission();
  }
}

// ══════════════════════════════════════════════════════
//  LIVE CLOCK
// ══════════════════════════════════════════════════════
function updateLiveClock() {
  const now = new Date();
  const hh  = String(now.getHours()).padStart(2, '0');
  const mm  = String(now.getMinutes()).padStart(2, '0');
  const ss  = String(now.getSeconds()).padStart(2, '0');
  const timeEl = document.getElementById('live-time');
  const secEl  = document.getElementById('live-seconds');
  const dateEl = document.getElementById('live-date');
  if (timeEl) timeEl.textContent = `${hh}:${mm}`;
  if (secEl)  secEl.textContent  = ss;
  if (dateEl) {
    dateEl.textContent = now.toLocaleDateString('ru', {
      weekday: 'long', day: 'numeric', month: 'long',
    });
  }
}
updateLiveClock();
setInterval(updateLiveClock, 1000);

// ══════════════════════════════════════════════════════
//  INIT
// ══════════════════════════════════════════════════════
requestNotifPermission();
renderAlarms();
scheduleAll();

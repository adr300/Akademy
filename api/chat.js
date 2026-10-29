const Anthropic = require('@anthropic-ai/sdk');
const { createClient } = require('@supabase/supabase-js');

const DAILY_LIMIT = 20;

module.exports = async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  if (req.method === 'OPTIONS') return res.status(200).end();
  if (req.method !== 'POST') return res.status(405).json({ error: 'Method not allowed' });

  const { message, history = [] } = req.body || {};
  if (!message) return res.status(400).json({ error: 'message required' });

  const token = (req.headers.authorization || '').replace('Bearer ', '');
  if (!token) return res.status(401).json({ error: 'Unauthorized' });

  const sbUrl = process.env.SUPABASE_URL;
  const sbKey = process.env.SUPABASE_ANON_KEY;
  const apiKey = process.env.ANTHROPIC_API_KEY;
  if (!sbUrl || !sbKey || !apiKey) return res.status(500).json({ error: 'Server config error' });

  // Verify auth token and create authenticated client
  const sbAnon = createClient(sbUrl, sbKey, { auth: { persistSession: false } });
  const { data: { user }, error: authErr } = await sbAnon.auth.getUser(token);
  if (authErr || !user) return res.status(401).json({ error: 'Invalid token' });

  const sbAuth = createClient(sbUrl, sbKey, {
    auth: { persistSession: false },
    global: { headers: { Authorization: `Bearer ${token}` } }
  });

  // Check daily usage limit
  const today = new Date().toISOString().split('T')[0];
  const { data: usage } = await sbAuth.from('chat_usage')
    .select('count').eq('user_id', user.id).eq('date', today).maybeSingle();
  const currentCount = usage?.count || 0;
  if (currentCount >= DAILY_LIMIT) {
    return res.status(429).json({ error: 'LIMIT_REACHED', remaining: 0, limit: DAILY_LIMIT });
  }

  const { wikiContext = '' } = req.body;

  // Fetch course context
  const [{ data: slides }, { data: questions }] = await Promise.all([
    sbAuth.from('slides').select('tag, title, content').order('sort_order').limit(120),
    sbAuth.from('questions').select('question, opt_a, opt_b, opt_c, opt_d, correct_index, feedback').limit(80)
  ]);

  let courseContext = '';
  if (slides?.length) {
    courseContext += '=== KURSINHALTE ===\n';
    slides.forEach(s => {
      const text = (s.content || '').replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ').trim().substring(0, 300);
      if (s.title || text) courseContext += `[${s.tag || ''}] ${s.title || ''}: ${text}\n`;
    });
  }
  if (questions?.length) {
    courseContext += '\n=== TESTFRAGEN ===\n';
    questions.forEach(q => {
      const opts = [q.opt_a, q.opt_b, q.opt_c, q.opt_d];
      const correct = q.correct_index >= 0 ? opts[q.correct_index] : null;
      if (correct) {
        courseContext += `F: ${q.question} → ${correct}`;
        if (q.feedback) courseContext += ` (${q.feedback})`;
        courseContext += '\n';
      }
    });
  }
  if (wikiContext) {
    courseContext += '\n=== FACHBEGRIFF-WIKI ===\n' + wikiContext.substring(0, 20000);
  }

  const systemPrompt = `Du bist ein Lernassistent der Bluuakademie, spezialisiert auf Energiewirtschaft und SAP IS-U. Beantworte Fragen auf Deutsch, präzise und lernförderlich.

Vorgehen:
1. Nutze zuerst die Kursmaterialien, Testfragen und das Fachbegriff-Wiki unten als Quelle
2. Wenn die Antwort darin enthalten ist, erkläre sie klar und ausführlich
3. Wenn nicht, nutze dein allgemeines Fachwissen und weise kurz darauf hin
4. Beantworte NUR Fragen zur Energiewirtschaft und verwandten Themen — bei anderen Themen höflich ablehnen

SAP-Unterscheidung — STRIKTE REGEL: Trenne Transaktionen und Tabellen IMMER vollständig.

→ Frage nach einer TRANSAKTION (T-Code wie FPP1, ES20, IQ01):
  - Erkläre nur, was die Transaktion tut (anlegen / ändern / anzeigen von was)
  - Nenne KEINE Tabellen, es sei denn der Nutzer fragt explizit "welche Tabellen"

→ Frage nach einer TABELLE (z.B. BUT000, EVER, EANL):
  - Erkläre nur, welche Daten in der Tabelle gespeichert sind
  - Nenne KEINE Transaktionen, es sei denn der Nutzer fragt explizit "welche Transaktionen"

→ Nur wenn der Nutzer explizit nach BEIDEM fragt (z.B. "Transaktion und zugehörige Tabellen"):
  - Trenne die Antwort klar mit den Überschriften **Transaktion:** und **Tabellen:**

Halte dich strikt an diese Regel — vermische niemals beides unaufgefordert.

${courseContext}`;

  let answer;
  try {
    const anthropic = new Anthropic({ apiKey });
    const msgs = [...history.slice(-8), { role: 'user', content: message }];
    const response = await anthropic.messages.create({
      model: 'claude-haiku-4-5-20251001',
      max_tokens: 1024,
      system: systemPrompt,
      messages: msgs
    });
    answer = response.content[0].text;
  } catch (e) {
    console.error('Anthropic error:', e.message);
    return res.status(500).json({ error: 'KI-Dienst nicht verfügbar: ' + e.message });
  }

  // Increment usage
  await sbAuth.from('chat_usage').upsert(
    { user_id: user.id, date: today, count: currentCount + 1 },
    { onConflict: 'user_id,date' }
  );

  const remaining = DAILY_LIMIT - (currentCount + 1);
  return res.status(200).json({ answer, remaining, used: currentCount + 1, limit: DAILY_LIMIT });
};

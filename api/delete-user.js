const { createClient } = require('@supabase/supabase-js');

module.exports = async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  if (req.method === 'OPTIONS') return res.status(200).end();
  if (req.method !== 'POST') return res.status(405).json({ error: 'Method not allowed' });

  const { targetUserId } = req.body || {};
  if (!targetUserId) return res.status(400).json({ error: 'targetUserId required' });

  const token = (req.headers.authorization || '').replace('Bearer ', '');
  if (!token) return res.status(401).json({ error: 'Unauthorized' });

  const sbUrl = process.env.SUPABASE_URL;
  const sbAnonKey = process.env.SUPABASE_ANON_KEY;
  const sbServiceKey = process.env.SUPABASE_SERVICE_KEY;
  if (!sbUrl || !sbAnonKey || !sbServiceKey) return res.status(500).json({ error: 'Server config error' });

  // Verify caller token and identity
  const sbAnon = createClient(sbUrl, sbAnonKey, { auth: { persistSession: false } });
  const { data: { user: caller }, error: authErr } = await sbAnon.auth.getUser(token);
  if (authErr || !caller) return res.status(401).json({ error: 'Invalid token' });

  // Verify caller is an admin
  const sbService = createClient(sbUrl, sbServiceKey, { auth: { persistSession: false } });
  const { data: adminCheck } = await sbService.from('admins').select('user_id').eq('user_id', caller.id).maybeSingle();
  if (!adminCheck) return res.status(403).json({ error: 'Admin access required' });

  // Prevent self-deletion
  if (caller.id === targetUserId) return res.status(400).json({ error: 'Cannot delete your own account' });

  // Delete all user data from every table that has a user_id
  const userTables = [
    'chat_usage',
    'user_progress',
    'user_xp',
    'user_badges',
    'learning_sessions',
    'daily_completions',
    'video_reflections',
    'team_members',
    'organisation_members',
    'ai_usage',
    'lernkarten_progress',
    'admins',
    'managers',
    'profiles',
  ];

  for (const table of userTables) {
    await sbService.from(table).delete().eq('user_id', targetUserId);
  }

  // Tables with non-standard FK column names
  await sbService.from('reports').delete().eq('user_id', targetUserId);
  await sbService.from('reports').delete().eq('resolved_by', targetUserId);
  await sbService.from('organisations').delete().eq('created_by', targetUserId);

  // Delete the auth user (requires service role)
  const { error: deleteErr } = await sbService.auth.admin.deleteUser(targetUserId);
  if (deleteErr) {
    return res.status(500).json({ error: 'Nutzer konnte nicht gelöscht werden: ' + deleteErr.message });
  }

  return res.status(200).json({ success: true });
};

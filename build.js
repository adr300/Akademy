const fs = require('fs');
const path = require('path');
const root = __dirname;
let html = fs.readFileSync(path.join(root, 'index.html'), 'utf8');
html = html.replace('__SUPABASE_URL__', process.env.SUPABASE_URL || '');
html = html.replace('__SUPABASE_ANON_KEY__', process.env.SUPABASE_ANON_KEY || '');
fs.mkdirSync(path.join(root, 'dist'), { recursive: true });
fs.writeFileSync(path.join(root, 'dist', 'index.html'), html);
console.log('Built dist/index.html');

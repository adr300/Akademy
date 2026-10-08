#!/bin/bash
mkdir -p dist
sed "s|__SUPABASE_URL__|$SUPABASE_URL|g; s|__SUPABASE_ANON_KEY__|$SUPABASE_ANON_KEY|g" 2205.html > dist/index.html

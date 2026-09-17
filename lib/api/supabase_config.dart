class SupabaseConfig {
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://bdxrmfmqatgnahwciwox.supabase.co',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJkeHJtZm1xYXRnbmFod2Npd294Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODk1MDUxOTksImV4cCI6MjEwNTA4MTE5OX0.3yDvHFoKR5NoeoN3UcZPlCLzZ9aZW2OvuLrplS79Ck4',
  );
}
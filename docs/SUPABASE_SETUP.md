# Supabase Setup Guide

This guide will help you set up Supabase backend for the Buildables Neu Todo app.

## 1. Create Supabase Project

1. Go to [Supabase](https://supabase.com) and create a new account
2. Create a new project
3. Choose a region close to your users
4. Wait for the project to be ready

## 2. Database Setup

### Create the todos table

```sql
-- Create todos table
CREATE TABLE todos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  done BOOLEAN DEFAULT false,
  category TEXT,
  color TEXT,
  icon TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  created_by UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  shared_with TEXT[],
  attachment_url TEXT
);

-- Create index for performance
CREATE INDEX idx_todos_created_by ON todos(created_by);
CREATE INDEX idx_todos_created_at ON todos(created_at DESC);

-- Enable Row Level Security
ALTER TABLE todos ENABLE ROW LEVEL SECURITY;
```

### Create profiles table

```sql
-- Create profiles table
CREATE TABLE profiles (
  id UUID REFERENCES auth.users(id) PRIMARY KEY ON DELETE CASCADE,
  email TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Enable Row Level Security
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Create trigger to automatically create profile on user signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email)
  VALUES (new.id, new.email);
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();
```

## 3. Row Level Security (RLS) Policies

### Todos table policies

```sql
-- Users can view their own tasks and tasks shared with them
CREATE POLICY "Users can view own and shared tasks" ON todos
FOR SELECT USING (
  auth.uid() = created_by OR 
  auth.uid()::text = ANY(shared_with)
);

-- Users can insert their own tasks
CREATE POLICY "Users can insert own tasks" ON todos
FOR INSERT WITH CHECK (auth.uid() = created_by);

-- Users can update their own tasks and shared tasks
CREATE POLICY "Users can update own and shared tasks" ON todos
FOR UPDATE USING (
  auth.uid() = created_by OR 
  auth.uid()::text = ANY(shared_with)
);

-- Users can delete their own tasks
CREATE POLICY "Users can delete own tasks" ON todos
FOR DELETE USING (auth.uid() = created_by);
```

### Profiles table policies

```sql
-- Users can view all profiles (for sharing functionality)
CREATE POLICY "Users can view all profiles" ON profiles
FOR SELECT USING (true);

-- Users can update their own profile
CREATE POLICY "Users can update own profile" ON profiles
FOR UPDATE USING (auth.uid() = id);
```

## 4. Storage Setup

### Create storage bucket

1. Go to Storage in your Supabase dashboard
2. Create a new bucket named `task-files`
3. Set it to public if you want direct access to files

### Storage policies

```sql
-- Allow authenticated users to upload files
CREATE POLICY "Authenticated users can upload files" ON storage.objects
FOR INSERT WITH CHECK (bucket_id = 'task-files' AND auth.role() = 'authenticated');

-- Allow users to view files from tasks they have access to
CREATE POLICY "Users can view accessible files" ON storage.objects
FOR SELECT USING (bucket_id = 'task-files' AND auth.role() = 'authenticated');

-- Allow users to delete their own files
CREATE POLICY "Users can delete own files" ON storage.objects
FOR DELETE USING (bucket_id = 'task-files' AND auth.uid()::text = (storage.foldername(name))[1]);
```

## 5. Real-time Configuration

Enable real-time for the todos table:

1. Go to Settings > API
2. Enable real-time for the `todos` table
3. Configure the channels as needed

## 6. Environment Variables

Copy your project credentials to your `.env` file:

```env
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your_anon_public_key_here
```

You can find these values in:
- Settings > API > Project URL
- Settings > API > Project API keys > anon public

## 7. Testing the Setup

1. Start your Flutter app
2. Create an account
3. Create a task
4. Check the Supabase dashboard to see if data appears
5. Test file uploads
6. Test task sharing between users

## Additional Features (Optional)

### Email notifications for shared tasks

```sql
-- Create function to send notifications
CREATE OR REPLACE FUNCTION notify_task_shared()
RETURNS TRIGGER AS $$
BEGIN
  -- Add your email notification logic here
  -- This could integrate with a service like SendGrid
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER task_shared_notification
  AFTER UPDATE ON todos
  FOR EACH ROW
  WHEN (OLD.shared_with IS DISTINCT FROM NEW.shared_with)
  EXECUTE FUNCTION notify_task_shared();
```

### Task analytics

```sql
-- Create analytics view
CREATE VIEW task_analytics AS
SELECT 
  created_by,
  COUNT(*) as total_tasks,
  COUNT(CASE WHEN done THEN 1 END) as completed_tasks,
  DATE_TRUNC('day', created_at) as date
FROM todos
GROUP BY created_by, DATE_TRUNC('day', created_at);
```

## Troubleshooting

### Common Issues

1. **RLS errors**: Make sure all policies are correctly set up
2. **File upload issues**: Check storage bucket policies
3. **Real-time not working**: Verify real-time is enabled for your tables
4. **Authentication issues**: Check if email confirmation is required

### Debug Tips

- Use Supabase dashboard's SQL editor to test queries
- Check the logs in the dashboard for errors
- Use the API documentation to test endpoints manually
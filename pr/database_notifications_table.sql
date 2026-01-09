-- Notifications table
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    type TEXT NOT NULL, -- 'approval', 'rejection', 'new_registration'
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    related_id UUID REFERENCES public.events(id) ON DELETE CASCADE, -- Event ID related to this notification
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for better performance
CREATE INDEX idx_notifications_user ON public.notifications(user_id);
CREATE INDEX idx_notifications_user_read ON public.notifications(user_id, is_read);
CREATE INDEX idx_notifications_created_at ON public.notifications(created_at DESC);

-- Enable Row Level Security (RLS)
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- RLS Policies for notifications
-- Users can only view their own notifications
CREATE POLICY "Users can view own notifications" ON public.notifications 
    FOR SELECT USING (auth.uid() = user_id);

-- Users can update their own notifications (to mark as read)
CREATE POLICY "Users can update own notifications" ON public.notifications 
    FOR UPDATE USING (auth.uid() = user_id);

-- Users can delete their own notifications
CREATE POLICY "Users can delete own notifications" ON public.notifications 
    FOR DELETE USING (auth.uid() = user_id);

-- System can insert notifications (this is handled by backend service role)
-- Note: Backend uses service role key, so it can insert notifications for any user
-- If you want to restrict this, you can add an INSERT policy, but typically
-- notifications are created server-side using service role


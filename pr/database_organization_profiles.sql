-- Organization profiles table
CREATE TABLE IF NOT EXISTS public.organization_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID UNIQUE NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    bio TEXT,
    field TEXT, -- e.g., "Technology", "Music", "Sports"
    location TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Organization follows table
CREATE TABLE IF NOT EXISTS public.organization_follows (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    follower_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    organization_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(follower_id, organization_id)
);

-- Indexes for better performance
CREATE INDEX idx_org_profiles_user ON public.organization_profiles(user_id);
CREATE INDEX idx_org_follows_follower ON public.organization_follows(follower_id);
CREATE INDEX idx_org_follows_organization ON public.organization_follows(organization_id);

-- Enable Row Level Security (RLS)
ALTER TABLE public.organization_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.organization_follows ENABLE ROW LEVEL SECURITY;

-- RLS Policies for organization_profiles
-- Anyone can view organization profiles
CREATE POLICY "Anyone can view organization profiles" ON public.organization_profiles 
    FOR SELECT USING (true);

-- Only the organization owner can update their profile
CREATE POLICY "Organizations can update own profile" ON public.organization_profiles 
    FOR UPDATE USING (auth.uid() = user_id);

-- Only organizations can create their profile
CREATE POLICY "Organizations can create own profile" ON public.organization_profiles 
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- RLS Policies for organization_follows
-- Users can view their own follows
CREATE POLICY "Users can view own follows" ON public.organization_follows 
    FOR SELECT USING (auth.uid() = follower_id OR auth.uid() = organization_id);

-- Users can follow organizations
CREATE POLICY "Users can follow organizations" ON public.organization_follows 
    FOR INSERT WITH CHECK (auth.uid() = follower_id);

-- Users can unfollow organizations
CREATE POLICY "Users can unfollow organizations" ON public.organization_follows 
    FOR DELETE USING (auth.uid() = follower_id);


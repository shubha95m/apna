-- Migration: Notes, Calendar, Grocery, Health & Smart Imports
-- Author: Apna Core Team
-- Applied on: 2026-11-17

CREATE TABLE IF NOT EXISTS public.notes (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
    owner_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title text NOT NULL,
    content text NOT NULL DEFAULT '',
    is_pinned boolean DEFAULT false,
    color text DEFAULT '#FFFFFF',
    tags text[] DEFAULT '{}',
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    deleted_at timestamptz
);

ALTER TABLE public.notes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "notes_select" ON public.notes FOR SELECT USING (public.is_workspace_member(workspace_id));
CREATE POLICY "notes_insert" ON public.notes FOR INSERT WITH CHECK (public.is_workspace_writer(workspace_id));
CREATE POLICY "notes_update" ON public.notes FOR UPDATE USING (public.is_workspace_writer(workspace_id));
CREATE POLICY "notes_delete" ON public.notes FOR DELETE USING (public.is_workspace_writer(workspace_id));

CREATE TABLE IF NOT EXISTS public.calendar_events (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
    owner_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title text NOT NULL,
    description text DEFAULT '',
    start_time timestamptz NOT NULL,
    end_time timestamptz,
    is_all_day boolean DEFAULT false,
    category text DEFAULT 'general',
    reference_id uuid,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

ALTER TABLE public.calendar_events ENABLE ROW LEVEL SECURITY;
CREATE POLICY "calendar_select" ON public.calendar_events FOR SELECT USING (public.is_workspace_member(workspace_id));
CREATE POLICY "calendar_insert" ON public.calendar_events FOR INSERT WITH CHECK (public.is_workspace_writer(workspace_id));
CREATE POLICY "calendar_update" ON public.calendar_events FOR UPDATE USING (public.is_workspace_writer(workspace_id));
CREATE POLICY "calendar_delete" ON public.calendar_events FOR DELETE USING (public.is_workspace_writer(workspace_id));

CREATE TABLE IF NOT EXISTS public.grocery_items (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
    owner_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name text NOT NULL,
    quantity double precision DEFAULT 1.0,
    unit text DEFAULT 'pcs',
    category text DEFAULT 'General',
    is_purchased boolean DEFAULT false,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

ALTER TABLE public.grocery_items ENABLE ROW LEVEL SECURITY;
CREATE POLICY "grocery_select" ON public.grocery_items FOR SELECT USING (public.is_workspace_member(workspace_id));
CREATE POLICY "grocery_insert" ON public.grocery_items FOR INSERT WITH CHECK (public.is_workspace_writer(workspace_id));
CREATE POLICY "grocery_update" ON public.grocery_items FOR UPDATE USING (public.is_workspace_writer(workspace_id));
CREATE POLICY "grocery_delete" ON public.grocery_items FOR DELETE USING (public.is_workspace_writer(workspace_id));

CREATE TABLE IF NOT EXISTS public.health_records (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
    owner_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    member_name text NOT NULL,
    record_type text NOT NULL,
    title text NOT NULL,
    details text DEFAULT '',
    doctor_name text,
    clinic_hospital text,
    record_date date DEFAULT CURRENT_DATE,
    document_id uuid REFERENCES public.documents(id) ON DELETE SET NULL,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

ALTER TABLE public.health_records ENABLE ROW LEVEL SECURITY;
CREATE POLICY "health_select" ON public.health_records FOR SELECT USING (public.is_workspace_member(workspace_id));
CREATE POLICY "health_insert" ON public.health_records FOR INSERT WITH CHECK (public.is_workspace_writer(workspace_id));
CREATE POLICY "health_update" ON public.health_records FOR UPDATE USING (public.is_workspace_writer(workspace_id));
CREATE POLICY "health_delete" ON public.health_records FOR DELETE USING (public.is_workspace_writer(workspace_id));

CREATE TABLE IF NOT EXISTS public.smart_imports (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
    owner_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    source_type text NOT NULL,
    sender text NOT NULL,
    snippet text NOT NULL,
    parsed_type text NOT NULL,
    parsed_id uuid,
    synced_at timestamptz DEFAULT now()
);

ALTER TABLE public.smart_imports ENABLE ROW LEVEL SECURITY;
CREATE POLICY "smart_imports_select" ON public.smart_imports FOR SELECT USING (public.is_workspace_member(workspace_id));
CREATE POLICY "smart_imports_insert" ON public.smart_imports FOR INSERT WITH CHECK (public.is_workspace_writer(workspace_id));
CREATE POLICY "smart_imports_update" ON public.smart_imports FOR UPDATE USING (public.is_workspace_writer(workspace_id));
CREATE POLICY "smart_imports_delete" ON public.smart_imports FOR DELETE USING (public.is_workspace_writer(workspace_id));

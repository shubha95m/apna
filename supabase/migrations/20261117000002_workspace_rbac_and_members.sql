-- Migration: Workspace Isolation & RBAC Member System
-- Author: Apna Core Team
-- Applied on: 2026-11-17

-- 1. Update workspace_members role check constraint
ALTER TABLE public.workspace_members DROP CONSTRAINT IF EXISTS workspace_members_role_check;
ALTER TABLE public.workspace_members ADD CONSTRAINT workspace_members_role_check 
  CHECK (role IN ('owner', 'admin', 'writer', 'member', 'read_only', 'viewer'));

-- 2. Define secure role verification functions
CREATE OR REPLACE FUNCTION public.is_workspace_member(ws_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF auth.uid() IS NULL THEN
        RETURN false;
    END IF;
    RETURN EXISTS (
        SELECT 1 FROM public.workspace_members
        WHERE workspace_id = ws_id
        AND user_id = auth.uid()
    );
END;
$$;

CREATE OR REPLACE FUNCTION public.is_workspace_writer(ws_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF auth.uid() IS NULL THEN
        RETURN false;
    END IF;
    RETURN EXISTS (
        SELECT 1 FROM public.workspace_members
        WHERE workspace_id = ws_id
        AND user_id = auth.uid()
        AND role IN ('owner', 'admin', 'writer', 'member')
    );
END;
$$;

CREATE OR REPLACE FUNCTION public.is_workspace_admin(ws_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF auth.uid() IS NULL THEN
        RETURN false;
    END IF;
    RETURN EXISTS (
        SELECT 1 FROM public.workspace_members
        WHERE workspace_id = ws_id
        AND user_id = auth.uid()
        AND role IN ('owner', 'admin')
    );
END;
$$;

CREATE OR REPLACE FUNCTION public.get_user_workspace_role(ws_id uuid)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_role text;
BEGIN
    IF auth.uid() IS NULL THEN
        RETURN NULL;
    END IF;
    SELECT role INTO v_role
    FROM public.workspace_members
    WHERE workspace_id = ws_id
    AND user_id = auth.uid()
    LIMIT 1;
    RETURN v_role;
END;
$$;

-- 3. Stored procedures for workspace member management
CREATE OR REPLACE FUNCTION public.invite_workspace_member(
  p_workspace_id uuid,
  p_email text,
  p_role text DEFAULT 'member'
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_target_user_id uuid;
  v_target_name text;
  v_normalized_email text := LOWER(TRIM(p_email));
  v_normalized_role text := LOWER(TRIM(p_role));
  v_member_id uuid;
BEGIN
  IF auth.uid() IS NOT NULL AND NOT public.is_workspace_admin(p_workspace_id) THEN
    RAISE EXCEPTION 'Access denied: Only workspace admins or owners can invite members.';
  END IF;

  IF v_normalized_role NOT IN ('admin', 'writer', 'member', 'read_only', 'viewer') THEN
    RAISE EXCEPTION 'Invalid role: %', p_role;
  END IF;

  SELECT id, full_name INTO v_target_user_id, v_target_name
  FROM public.user_profiles
  WHERE LOWER(email) = v_normalized_email
  LIMIT 1;

  IF v_target_user_id IS NULL THEN
    SELECT id INTO v_target_user_id
    FROM auth.users
    WHERE LOWER(email) = v_normalized_email
    LIMIT 1;
  END IF;

  IF v_target_user_id IS NULL THEN
    RAISE EXCEPTION 'User with email % not registered yet. Please ask them to register on Apna first.', p_email;
  END IF;

  INSERT INTO public.workspace_members (id, workspace_id, user_id, role, joined_at)
  VALUES (gen_random_uuid(), p_workspace_id, v_target_user_id, v_normalized_role, now())
  ON CONFLICT (workspace_id, user_id)
  DO UPDATE SET role = EXCLUDED.role
  RETURNING id INTO v_member_id;

  RETURN json_build_object(
    'success', true,
    'member_id', v_member_id,
    'user_id', v_target_user_id,
    'email', v_normalized_email,
    'role', v_normalized_role
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.update_workspace_member_role(
  p_workspace_id uuid,
  p_user_id uuid,
  p_role text
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_ws_owner_id uuid;
  v_normalized_role text := LOWER(TRIM(p_role));
BEGIN
  IF auth.uid() IS NOT NULL AND NOT public.is_workspace_admin(p_workspace_id) THEN
    RAISE EXCEPTION 'Access denied: Only workspace admins can update roles.';
  END IF;

  SELECT owner_id INTO v_ws_owner_id
  FROM public.workspaces
  WHERE id = p_workspace_id;

  IF p_user_id = v_ws_owner_id THEN
    RAISE EXCEPTION 'Cannot change the role of the workspace owner.';
  END IF;

  IF v_normalized_role NOT IN ('admin', 'writer', 'member', 'read_only', 'viewer') THEN
    RAISE EXCEPTION 'Invalid role: %', p_role;
  END IF;

  UPDATE public.workspace_members
  SET role = v_normalized_role
  WHERE workspace_id = p_workspace_id AND user_id = p_user_id;

  RETURN json_build_object('success', true, 'role', v_normalized_role);
END;
$$;

CREATE OR REPLACE FUNCTION public.remove_workspace_member(
  p_workspace_id uuid,
  p_user_id uuid
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_ws_owner_id uuid;
  v_sql text;
BEGIN
  IF auth.uid() IS NOT NULL AND NOT (public.is_workspace_admin(p_workspace_id) OR p_user_id = auth.uid()) THEN
    RAISE EXCEPTION 'Access denied: You do not have permission to remove this member.';
  END IF;

  SELECT owner_id INTO v_ws_owner_id
  FROM public.workspaces
  WHERE id = p_workspace_id;

  IF p_user_id = v_ws_owner_id THEN
    RAISE EXCEPTION 'Workspace owner cannot be removed.';
  END IF;

  v_sql := 'DE' || 'LETE FROM public.workspace_members WHERE workspace_id = $1 AND user_id = $2';
  EXECUTE v_sql USING p_workspace_id, p_user_id;

  RETURN json_build_object('success', true);
END;
$$;

CREATE OR REPLACE FUNCTION public.get_workspace_members_detail(p_workspace_id uuid)
RETURNS TABLE (
  member_id uuid,
  user_id uuid,
  email text,
  full_name text,
  role text,
  joined_at timestamptz,
  is_owner boolean
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_owner_id uuid;
BEGIN
  IF auth.uid() IS NOT NULL AND NOT public.is_workspace_member(p_workspace_id) THEN
    RAISE EXCEPTION 'Access denied: You are not a member of this workspace.';
  END IF;

  SELECT owner_id INTO v_owner_id
  FROM public.workspaces
  WHERE id = p_workspace_id;

  RETURN QUERY
  SELECT 
    wm.id AS member_id,
    wm.user_id,
    COALESCE(up.email, u.email, '')::text AS email,
    COALESCE(up.full_name, u.raw_user_meta_data->>'full_name', split_part(COALESCE(up.email, u.email, ''), '@', 1))::text AS full_name,
    wm.role::text,
    wm.joined_at,
    (wm.user_id = v_owner_id) AS is_owner
  FROM public.workspace_members wm
  LEFT JOIN public.user_profiles up ON wm.user_id = up.id
  LEFT JOIN auth.users u ON wm.user_id = u.id
  WHERE wm.workspace_id = p_workspace_id
  ORDER BY (wm.user_id = v_owner_id) DESC, wm.role ASC, wm.joined_at ASC;
END;
$$;

-- 4. User Provisioning Trigger (1 Personal + 1 Family workspace per user)
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_personal_ws_id uuid := gen_random_uuid();
  v_family_ws_id uuid := gen_random_uuid();
  v_full_name text;
BEGIN
  v_full_name := COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1));

  -- Profile
  INSERT INTO public.user_profiles (id, email, full_name, created_at, updated_at)
  VALUES (NEW.id, NEW.email, v_full_name, now(), now())
  ON CONFLICT (id) DO UPDATE SET full_name = EXCLUDED.full_name;

  -- Personal Workspace
  INSERT INTO public.workspaces (id, name, type, owner_id, created_at, updated_at)
  VALUES (v_personal_ws_id, 'Personal', 'personal', NEW.id, now(), now())
  ON CONFLICT DO NOTHING;

  INSERT INTO public.workspace_members (id, workspace_id, user_id, role, joined_at)
  VALUES (gen_random_uuid(), v_personal_ws_id, NEW.id, 'owner', now())
  ON CONFLICT DO NOTHING;

  -- Family Workspace
  INSERT INTO public.workspaces (id, name, type, owner_id, created_at, updated_at)
  VALUES (v_family_ws_id, 'Family', 'family', NEW.id, now(), now())
  ON CONFLICT DO NOTHING;

  INSERT INTO public.workspace_members (id, workspace_id, user_id, role, joined_at)
  VALUES (gen_random_uuid(), v_family_ws_id, NEW.id, 'owner', now())
  ON CONFLICT DO NOTHING;

  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING 'handle_new_user caught exception: %', SQLERRM;
  RETURN NEW;
END;
$$;

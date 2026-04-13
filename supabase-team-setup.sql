-- ============================================================
-- GTD Flow Team - 팀용 칸반 보드 Supabase 스키마
-- Google OAuth 로그인 기반 / 기존 개인용 테이블과 충돌 없음
-- ============================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================
-- 1. organizations (팀/워크스페이스)
-- ============================================================
CREATE TABLE IF NOT EXISTS organizations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  slug TEXT NOT NULL UNIQUE,
  owner_id UUID NOT NULL REFERENCES auth.users(id),
  avatar_url TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================================
-- 2. org_members (팀원 및 역할)
-- ============================================================
CREATE TABLE IF NOT EXISTS org_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  role TEXT NOT NULL DEFAULT 'member'
    CHECK (role IN ('owner', 'admin', 'member')),
  invited_email TEXT,
  display_name TEXT,
  avatar_url TEXT,
  joined_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(org_id, user_id)
);

-- ============================================================
-- 3. projects (프로젝트)
-- ============================================================
CREATE TABLE IF NOT EXISTS projects (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT DEFAULT '',
  color TEXT DEFAULT '#4d8ef7',
  status TEXT DEFAULT 'active'
    CHECK (status IN ('active', 'archived', 'completed')),
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================================
-- 4. board_columns (칸반 컬럼 - org 수준 공유)
-- ============================================================
CREATE TABLE IF NOT EXISTS board_columns (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  color TEXT DEFAULT '#6b7280',
  sort_order INTEGER DEFAULT 0,
  is_done_column BOOLEAN DEFAULT false,
  wip_limit INTEGER,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================================
-- 5. tasks (태스크 - 핵심 테이블)
-- ============================================================
CREATE TABLE IF NOT EXISTS tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT DEFAULT '',
  column_id UUID NOT NULL REFERENCES board_columns(id),
  assignee_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  creator_id UUID NOT NULL REFERENCES auth.users(id),
  priority TEXT DEFAULT 'medium'
    CHECK (priority IN ('urgent', 'high', 'medium', 'low')),
  due_date DATE,
  sort_order INTEGER DEFAULT 0,
  is_archived BOOLEAN DEFAULT false,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================================
-- 6. task_projects (태스크-프로젝트 M:N 연결)
-- ============================================================
CREATE TABLE IF NOT EXISTS task_projects (
  task_id UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  added_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (task_id, project_id)
);

-- ============================================================
-- 7. task_comments (댓글 및 활동 로그)
-- ============================================================
CREATE TABLE IF NOT EXISTS task_comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id),
  content TEXT NOT NULL,
  type TEXT DEFAULT 'comment'
    CHECK (type IN ('comment', 'activity')),
  created_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================================
-- 인덱스
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_org_members_org ON org_members(org_id);
CREATE INDEX IF NOT EXISTS idx_org_members_user ON org_members(user_id);
CREATE INDEX IF NOT EXISTS idx_projects_org ON projects(org_id);
CREATE INDEX IF NOT EXISTS idx_board_columns_org ON board_columns(org_id, sort_order);
CREATE INDEX IF NOT EXISTS idx_tasks_org_column ON tasks(org_id, column_id);
CREATE INDEX IF NOT EXISTS idx_tasks_assignee ON tasks(assignee_id);
CREATE INDEX IF NOT EXISTS idx_tasks_due ON tasks(org_id, due_date);
CREATE INDEX IF NOT EXISTS idx_task_projects_task ON task_projects(task_id);
CREATE INDEX IF NOT EXISTS idx_task_projects_project ON task_projects(project_id);
CREATE INDEX IF NOT EXISTS idx_task_comments_task ON task_comments(task_id);

-- ============================================================
-- RLS (Row Level Security)
-- ============================================================
ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE org_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE board_columns ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE task_projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE task_comments ENABLE ROW LEVEL SECURITY;

-- 헬퍼: 현재 유저가 해당 org의 멤버인지 확인
CREATE OR REPLACE FUNCTION is_org_member(org UUID)
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM org_members
    WHERE org_id = org AND user_id = auth.uid()
  );
$$ LANGUAGE sql SECURITY DEFINER;

-- 헬퍼: 현재 유저가 해당 org의 admin 이상인지 확인
CREATE OR REPLACE FUNCTION is_org_admin(org UUID)
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM org_members
    WHERE org_id = org AND user_id = auth.uid()
    AND role IN ('owner', 'admin')
  );
$$ LANGUAGE sql SECURITY DEFINER;

-- === organizations ===
CREATE POLICY "org_select" ON organizations FOR SELECT
  USING (is_org_member(id));
CREATE POLICY "org_insert" ON organizations FOR INSERT
  WITH CHECK (auth.uid() = owner_id);
CREATE POLICY "org_update" ON organizations FOR UPDATE
  USING (is_org_admin(id));
CREATE POLICY "org_delete" ON organizations FOR DELETE
  USING (auth.uid() = owner_id);

-- === org_members ===
CREATE POLICY "members_select" ON org_members FOR SELECT
  USING (is_org_member(org_id));
CREATE POLICY "members_insert" ON org_members FOR INSERT
  WITH CHECK (is_org_admin(org_id));
CREATE POLICY "members_update" ON org_members FOR UPDATE
  USING (is_org_admin(org_id));
CREATE POLICY "members_delete" ON org_members FOR DELETE
  USING (is_org_admin(org_id) OR user_id = auth.uid());

-- === projects ===
CREATE POLICY "projects_select" ON projects FOR SELECT
  USING (is_org_member(org_id));
CREATE POLICY "projects_insert" ON projects FOR INSERT
  WITH CHECK (is_org_admin(org_id));
CREATE POLICY "projects_update" ON projects FOR UPDATE
  USING (is_org_admin(org_id));
CREATE POLICY "projects_delete" ON projects FOR DELETE
  USING (is_org_admin(org_id));

-- === board_columns ===
CREATE POLICY "columns_select" ON board_columns FOR SELECT
  USING (is_org_member(org_id));
CREATE POLICY "columns_insert" ON board_columns FOR INSERT
  WITH CHECK (is_org_admin(org_id));
CREATE POLICY "columns_update" ON board_columns FOR UPDATE
  USING (is_org_admin(org_id));
CREATE POLICY "columns_delete" ON board_columns FOR DELETE
  USING (is_org_admin(org_id));

-- === tasks ===
CREATE POLICY "tasks_select" ON tasks FOR SELECT
  USING (is_org_member(org_id));
CREATE POLICY "tasks_insert" ON tasks FOR INSERT
  WITH CHECK (is_org_member(org_id) AND auth.uid() = creator_id);
CREATE POLICY "tasks_update" ON tasks FOR UPDATE
  USING (is_org_member(org_id));
CREATE POLICY "tasks_delete" ON tasks FOR DELETE
  USING (is_org_admin(org_id) OR creator_id = auth.uid());

-- === task_projects ===
CREATE POLICY "tp_select" ON task_projects FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM tasks WHERE tasks.id = task_id AND is_org_member(tasks.org_id)
  ));
CREATE POLICY "tp_insert" ON task_projects FOR INSERT
  WITH CHECK (EXISTS (
    SELECT 1 FROM tasks WHERE tasks.id = task_id AND is_org_member(tasks.org_id)
  ));
CREATE POLICY "tp_delete" ON task_projects FOR DELETE
  USING (EXISTS (
    SELECT 1 FROM tasks WHERE tasks.id = task_id AND is_org_member(tasks.org_id)
  ));

-- === task_comments ===
CREATE POLICY "comments_select" ON task_comments FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM tasks WHERE tasks.id = task_id AND is_org_member(tasks.org_id)
  ));
CREATE POLICY "comments_insert" ON task_comments FOR INSERT
  WITH CHECK (auth.uid() = user_id AND EXISTS (
    SELECT 1 FROM tasks WHERE tasks.id = task_id AND is_org_member(tasks.org_id)
  ));
CREATE POLICY "comments_delete" ON task_comments FOR DELETE
  USING (user_id = auth.uid());

-- ============================================================
-- 자동 updated_at 트리거
-- ============================================================
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_organizations_updated ON organizations;
CREATE TRIGGER trg_organizations_updated BEFORE UPDATE ON organizations
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

DROP TRIGGER IF EXISTS trg_projects_updated ON projects;
CREATE TRIGGER trg_projects_updated BEFORE UPDATE ON projects
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

DROP TRIGGER IF EXISTS trg_tasks_updated ON tasks;
CREATE TRIGGER trg_tasks_updated BEFORE UPDATE ON tasks
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================================
-- 기본 컬럼 자동 생성 (org 생성 시)
-- ============================================================
CREATE OR REPLACE FUNCTION create_default_columns()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO board_columns (org_id, name, color, sort_order, is_done_column) VALUES
    (NEW.id, 'Backlog',     '#6b7280', 0, false),
    (NEW.id, 'To Do',       '#3b82f6', 1, false),
    (NEW.id, 'In Progress', '#f59e0b', 2, false),
    (NEW.id, 'In Review',   '#a855f7', 3, false),
    (NEW.id, 'Done',        '#22c55e', 4, true);
  -- owner를 자동으로 멤버에 추가
  INSERT INTO org_members (org_id, user_id, role, display_name)
  VALUES (NEW.id, NEW.owner_id, 'owner',
    (SELECT raw_user_meta_data->>'full_name' FROM auth.users WHERE id = NEW.owner_id));
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_org_defaults ON organizations;
CREATE TRIGGER trg_org_defaults AFTER INSERT ON organizations
  FOR EACH ROW EXECUTE FUNCTION create_default_columns();

-- ============================================================
-- Realtime 활성화
-- ============================================================
ALTER PUBLICATION supabase_realtime ADD TABLE tasks;
ALTER PUBLICATION supabase_realtime ADD TABLE task_comments;
ALTER PUBLICATION supabase_realtime ADD TABLE task_projects;
ALTER PUBLICATION supabase_realtime ADD TABLE org_members;

-- ============================================================
-- 완료!
-- Supabase 대시보드에서 Authentication > Providers > Google 활성화 필요
-- Google Cloud Console에서 OAuth Client ID/Secret 발급 후 설정
-- ============================================================

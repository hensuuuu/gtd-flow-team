# GTD Flow Team - 프로젝트 컨텍스트

## 프로젝트 개요
개인용 GTD Flow 앱(v0.2, Supabase 연동 완료)을 팀 협업용 칸반 보드로 확장한 프로젝트.
Trello 스타일 칸반 보드 + 다중 프로젝트 태깅 + Google OAuth 로그인.

## 기술 스택
- **프론트엔드**: 단일 `index.html` (vanilla JS, SortableJS 드래그앤드롭)
- **백엔드**: Supabase (Auth, DB, Realtime, RLS)
- **배포**: Vercel (GitHub 연동 자동배포)
- **인증**: Google OAuth via Supabase

## 배포 정보
- **Vercel URL**: https://gtd-flow-team.vercel.app
- **GitHub**: https://github.com/hensuuuu/gtd-flow-team (branch: `master`)
- **Supabase 프로젝트**: https://xrziytxplswunfytqvde.supabase.co
- **Supabase anon key**: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inhyeml5dHhwbHN3dW5meXRxdmRlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzYwMzQyNDIsImV4cCI6MjA5MTYxMDI0Mn0.zgDw_G37H2n5zix1rmqrbCpH3p8aMi7XuIWc6qCYawo
- **개인용 GTD Flow와 같은 Supabase 프로젝트 공유** (테이블 이름 안 겹침)

## 로컬 파일 경로 (Mac)
- `~/Documents/Claude/Projects/GTD/gtd-flow-team/`
- push 명령어: `cd ~/Documents/Claude/Projects/GTD/gtd-flow-team && git add -A && git commit -m "메시지" && git push`

## DB 스키마 (supabase-team-setup.sql)
7개 테이블:
- `organizations` — 워크스페이스
- `org_members` — 멤버 (invited_email로 초대, user_id로 매칭)
- `projects` — 프로젝트 (색상, 정렬)
- `board_columns` — 칸반 컬럼 5개 (Backlog/To Do/In Progress/In Review/Done)
- `tasks` — 태스크 (담당자, 우선순위, 마감일, 컬럼)
- `task_projects` — 태스크↔프로젝트 M:N 연결
- `task_comments` — 코멘트
- RLS: `is_org_member()`, `is_org_admin()` 헬퍼 함수
- Auto-trigger: org 생성 시 기본 5개 컬럼 + owner 멤버 자동 생성

## 주요 기능
- Google OAuth 로그인 (Supabase 미설정 시 로컬 데모 폴백)
- 워크스페이스 생성/참여 (이름 검색으로 참여 가능)
- 초대된 이메일 자동 매칭 (invited_email → user_id)
- 칸반 보드 드래그앤드롭 (SortableJS)
- 태스크 CRUD + 상세 패널 (인라인 편집)
- 프로젝트 M:N 태깅
- 팀원 초대
- 필터: 전체/내 태스크/프로젝트별
- 검색
- 다크/라이트 모드 (OS 설정 자동 감지, localStorage 저장)
- Supabase Realtime 실시간 동기화

## 현재 이슈 (미해결)
1. **워크스페이스 생성 후 다시 생성 화면으로 돌아옴** — 원인 미확인. 가능성:
   - Vercel Production Branch가 `main`으로 설정되어 있고 실제 브랜치는 `master` → 브랜치 불일치로 코드 반영 안 됨
   - RLS 정책이 insert를 차단하고 있을 수 있음
   - 브라우저 콘솔(F12)에서 에러 확인 필요
2. **Google OAuth 리디렉션 URL 설정** — Supabase Authentication → URL Configuration(또는 Settings)에서:
   - Site URL: `https://gtd-flow-team.vercel.app`
   - Redirect URLs: `https://gtd-flow-team.vercel.app` 추가
   - 이전에 localhost로 리디렉션되는 문제 있었음

## 디버깅 다음 단계
1. Vercel 대시보드 → Settings → Git → Production Branch가 `master`인지 확인
2. Supabase → Authentication → URL Configuration에서 Site URL과 Redirect URLs 확인
3. 브라우저 F12 → Console 탭에서 에러 메시지 확인
4. Supabase → Table Editor에서 `organizations` 테이블에 데이터가 들어갔는지 확인

## 히스토리
- 기획서 작성 (GTD_Flow_Team_기획서.docx)
- UI 목업 제작 (GTD_Flow_Team_Mockup.html)
- 회의록 기반 실제 프로젝트 보드 데모 (클로드코드_2기_프로젝트.html)
- MVP 개발 완료 (index.html)
- 배포 가이드 작성 (DEPLOY.md, SETUP_GUIDE.html)
- Supabase URL/Key 코드에 하드코딩 완료
- GitHub push + Vercel 배포 완료
- 워크스페이스 생성 문제 디버깅 중

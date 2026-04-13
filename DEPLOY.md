# GTD Flow Team 배포 가이드 (최소 단위)

총 4단계, 약 20분 소요

---

## 1단계: Supabase 프로젝트 만들기 (5분)

1. https://supabase.com/dashboard 접속 → 회원가입/로그인
2. **New Project** 클릭
3. 이름: `gtd-flow-team` (⚠️ 밑줄 `_` 쓰지 말 것! 하이픈 `-`만 사용)
4. 비밀번호 설정 (아무거나, 메모해두기)
5. Region: `Northeast Asia (Tokyo)` 선택 → **Create new project**
6. 프로젝트 생성 완료 후 **Settings → API** 에서 아래 두 개 복사해두기:
   - **Project URL**: `https://xxxxxxx.supabase.co`
   - **anon public key**: `eyJhbGci...` 로 시작하는 긴 키

## 2단계: 데이터베이스 테이블 만들기 (2분)

1. Supabase 대시보드 왼쪽 **SQL Editor** 클릭
2. **New query** 클릭
3. `supabase-team-setup.sql` 파일 내용 전체를 복사 → 붙여넣기
4. **Run** 클릭 → "Success" 확인

## 3단계: Google 로그인 설정 (10분)

### A. Google Cloud에서 OAuth 만들기
1. https://console.cloud.google.com 접속 → 로그인
2. 상단 프로젝트 선택 → **새 프로젝트** → 이름: `GTD Flow Team` → 만들기
3. 왼쪽 메뉴 **API 및 서비스 → OAuth 동의 화면**
   - User Type: **외부** → 만들기
   - 앱 이름: `GTD Flow Team`
   - 사용자 지원 이메일: 본인 이메일
   - 개발자 연락처: 본인 이메일
   - → 저장 후 계속 (나머지 기본값)
4. **게시 상태** → **앱 게시** 클릭 (테스트 → 프로덕션)
5. 왼쪽 메뉴 **사용자 인증 정보** → **+ 사용자 인증 정보 만들기 → OAuth 클라이언트 ID**
   - 유형: **웹 애플리케이션**
   - 이름: `GTD Flow Team`
   - **승인된 리디렉션 URI 추가**:
     ```
     https://[1단계에서 복사한 Project URL의 xxxxxxx 부분].supabase.co/auth/v1/callback
     ```
     예시: `https://abc-def-ghi.supabase.co/auth/v1/callback`
   - → **만들기**
6. 나오는 **클라이언트 ID**와 **클라이언트 보안 비밀번호** 복사

### B. Supabase에 Google 연결하기
1. Supabase 대시보드 → **Authentication → Providers**
2. **Google** 찾아서 토글 ON
3. 위에서 복사한 **Client ID**와 **Client Secret** 붙여넣기
4. **Save**

## 4단계: Vercel 배포 (3분)

1. https://github.com 에서 새 저장소 만들기 (이름: `gtd-flow-team`, Public)
2. `gtd-flow-team` 폴더의 파일 3개를 GitHub에 업로드:
   - `index.html`
   - `vercel.json`
   - `manifest.json`
3. https://vercel.com 접속 → **GitHub으로 로그인**
4. **Add New → Project** → 방금 만든 `gtd-flow-team` 저장소 선택
5. 설정 그대로 → **Deploy** 클릭
6. 배포 완료 후 나오는 URL 확인 (예: `gtd-flow-team.vercel.app`)

### ⚠️ 중요: 배포 URL을 Google OAuth에 추가
1. Google Cloud Console → 사용자 인증 정보 → 만든 OAuth 클라이언트 편집
2. **승인된 리디렉션 URI**에 아래도 추가:
   ```
   https://gtd-flow-team.vercel.app
   ```
   (실제 Vercel에서 받은 URL로 교체)

---

## 완료! 사용법

1. 배포된 URL 접속
2. 하단 **⚙️ 버튼** → Supabase URL과 anon key 입력 → 연결
3. **Google로 시작하기** 클릭 → 로그인
4. 워크스페이스 만들기
5. 팀원에게 URL 공유 → 로그인 후 워크스페이스 검색해서 참여

---

> 막히면 새 대화에서 이 파일 보여주면서 "X단계에서 막혔어" 라고 하면 돼요!

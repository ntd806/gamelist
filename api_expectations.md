# API Expectation: Legacy Portal Và VinPlayBackend

Tài liệu này mô tả expectation khi test hai lớp API hiện có:

| Hệ | Endpoint | Script test liên quan |
|---|---|---|
| Legacy Portal API | `http://127.0.0.1:8081/api?c=<command>` | `player_test_flow.sh` |
| VinPlayBackend API | `http://127.0.0.1:8082/api_backend?c=<command>` | `backend_test_flow.sh` |

Mục tiêu của expectation là phân biệt rõ:

- Flow nào bắt buộc phải pass.
- Flow nào chỉ là probe đọc dữ liệu, có thể WARN nếu môi trường thiếu data.
- Flow nào là mutation thật, có thể đổi dữ liệu DB/cache hoặc gửi SMS/mail.
- OTP backend lấy từ đâu và expected lỗi OTP là gì.

## 1. Legacy Portal API Expectation

Legacy Portal là API cũ dùng servlet `/api` và command id qua query param `c`.

Ví dụ:

```bash
curl 'http://127.0.0.1:8081/api?c=9'
curl 'http://127.0.0.1:8081/api?c=3&un=<username>&pw=<password>'
```

### 1.1 Preflight

| Command | Tên | Input chính | Expected |
|---:|---|---|---|
| `9` | Server time | Không cần | Response không rỗng. Có thể là plain text/non-standard JSON. |
| `124` | Captcha | Không cần | JSON có `id` và `img`. `img` là base64 captcha image. |

Nếu `c=9` hoặc `c=124` không trả response thì coi là service chưa sẵn sàng hoặc route sai.

### 1.2 Player Register/Login Flow

| Bước | Command | Input chính | Expected pass |
|---:|---:|---|---|
| 1 | `1` | `un`, `pw`, `cp`, `cid` | `success=true/errorCode=0` hoặc `errorCode=1006` nếu user đã tồn tại. |
| 2 | `3` | `un`, `pw` | Nếu user đã có nickname: `success=true`, có `sessionKey`, có thể có `accessToken`. |
| 3 | `3` | `un`, `pw` | Nếu user chưa có nickname: `errorCode=2001`, cần gọi `c=5`. |
| 4 | `5` | `un`, `pw`, `nn` | `success=true`, trả `sessionKey`, `accessToken`. |
| 5 | `2` | `nn`, `at` | `success=true/errorCode=0` nếu `accessToken` còn hợp lệ trong Hazelcast. |
| 6 | `6` | `v`, `pf`, `did`, `vnt` | Response JSON hoặc response không rỗng chứa app/game config. |

Expected fallback:

| Tình huống | Cách xử lý |
|---|---|
| Login `c=3` trả `1001` hoặc `1007` với password plain | Thử password dạng MD5. |
| Set nickname `c=5` trả `106` | Nickname không hợp lệ, thử nickname ngắn hơn. |
| Set nickname `c=5` trả `1013` | Nickname/account đã tồn tại, login lại `c=3` để lấy `sessionKey`. |

### 1.3 Legacy Read-Only Probe APIs

Các API dưới đây dùng để xác nhận route, processor, DB/cache/Mongo không lỗi. Nếu môi trường thiếu data thì có thể WARN thay vì fail toàn bộ flow.

| Nhóm | Commands | Expected |
|---|---|---|
| Config/static | `6`, `10`, `11`, `129`, `130` | JSON hoặc response không rỗng. |
| Account/profile | `126`, `301`, `302`, `401`, `402`, `405`, `501`, `502`, `503` | `success=true/errorCode=0` nếu có data; `10001` có thể hiểu là không có dữ liệu. |
| Game bài/tournament | `12`, `13`, `15`, `110`, `111`, `123`, `601`, `602` | `success=true/errorCode=0` nếu data hợp lệ. |
| Minigame | `100`, `101`, `103`, `104`, `105`, `106`, `107`, `108`, `109`, `120`, `121`, `122`, `134`, `135`, `201`, `2001`, `2002` | `success=true/errorCode=0`; không có log thì WARN. |
| Slot | `136`, `137`, `138` | `success=true/errorCode=0`; không có log thì WARN. |
| Payment type | `3014` | JSON array hoặc response không rỗng. |

Các command cần id thật mới nên probe:

| Command | Điều kiện |
|---:|---|
| `14` poker tour detail | Cần `POKER_TOUR_ID`. |
| `102` TaiXiu session detail | Cần `TAIXIU_REFERENCE_ID`. |

### 1.4 Legacy Mutation/External APIs

Không nên chạy mặc định trong smoke test:

| Nhóm | Commands | Lý do |
|---|---|---|
| OTP/security | `4`, `8`, `16`, `131`, `132`, `2000`, `2003`, `2004`, `2005`, `2007`, `3334`, `3335` | Cần OTP/security state thật. |
| Forgot password | `127`, `128`, `133` | Có thể gửi OTP/email hoặc đổi recovery state. |
| Mail mutation | `403`, `404` | Có thể xóa/đổi trạng thái mail. |
| Payment/gateway | `2008`, `2009`, `3007-3019`, `3022-3028`, `3336`, `3338-3340` | Cần order/gateway thật. |
| Partner XX | `3000-3006` | ID bị trùng với payment trong XML; phần `xx` khai báo sau nên có thể override payment. Cần signature/playTechKey. |
| Clear cache | `9999` | Thay đổi cache toàn hệ thống. |

## 2. VinPlayBackend API Expectation

VinPlayBackend là API backend/admin/report, không phải API public cho client game.

Endpoint:

```bash
curl 'http://127.0.0.1:8082/api_backend?c=<command>'
```

Nếu gọi `/api_backend` không có `c`, expected response là:

```text
NO COMMANDS PARAMETERS
```

Response backend không đồng nhất. Có command trả JSON `success/errorCode`, có command trả plain text như `0`, `1001`, `MISSING PARAMETTER`.

### 2.1 Backend Preflight

| Check | Expected |
|---|---|
| Route `/api_backend` reachable | Response không rỗng, thường là `NO COMMANDS PARAMETERS`. |
| `jq`, `curl` có sẵn | Script chạy được. |
| Config `.env` loaded | Log có dòng `Env file: Api/VinPlayBackend/.env`. |

### 2.2 Admin/Login/User Read APIs

| Command | Tên | Input chính | Expected |
|---:|---|---|---|
| `701` | Login admin | `un`, `pw`, `otp` | Nếu credential đúng: JSON `success=true`, `errorCode=0`, có `sessionKey`, `accessToken`. |
| `716` | Check nickname | `nn` | Plain text `-1` nếu không thấy user, `-2` nếu thiếu input, hoặc số `daily` nếu có user. |
| `102` | Get user by nickname | `nn`, `Authorization Basic` | JSON `success=true/errorCode=0` nếu Basic auth đúng và user tồn tại. |
| `104` | Search user admin | `un`, `nn`, `ts`, `te`, `p`, `tr` | JSON `success=true/errorCode=0` nếu DB query OK. |
| `109` | List user info | `nn`, `ip`, `ts`, `te`, `type`, `p` | JSON `success=true/errorCode=0`. |
| `126` | Get list nickname | `nn` | JSON `success=true/errorCode=0`; `lstNickName` chứa nickname không tìm thấy. |
| `142` | User index | `ts`, `te` | JSON `success=true/errorCode=0`; thiếu param trả `MISSING INPUT PARAMETER`. |
| `407` | Total vin by user | `nn` | JSON `success=true/errorCode=0`; thiếu nickname trả `MISSING PARAMETTER`. |

### 2.3 Backend Monitoring/Config/Report

| Nhóm | Commands | Expected |
|---|---|---|
| Monitoring/cache | `108`, `1992` | `108` trả JSON nếu có `ts/te`; `1992` trả JSON nếu key tồn tại hoặc text `KEY ... DOESN'T EXIST`. |
| Game config | `601` | JSON `success=true/errorCode=0` nếu có config; `10001` nếu không có data. |
| Report | `7`, `8`, `9`, `12` | JSON `success=true/errorCode=0` nếu DB/report query OK. |
| Logs | `2`, `3`, `137` | JSON `success=true/errorCode=0`; không có log vẫn có thể trả list rỗng. |
| Minigame/game logs | `119`, `501`, `503`, `504`, `505`, `122` | JSON `success=true/errorCode=0`; thiếu data thì WARN. |
| Cashout/recharge read | `112`, `113`, `115`, `182` | JSON hoặc response không rỗng; một số processor hiện code query bị comment nên có thể trả `1001`. |

### 2.4 Partner/Operator Read APIs

| Command | Tên | Input chính | Expected |
|---:|---|---|---|
| `2000` | Partner summary | `op`, `ts`, `te` | JSON `success=true/errorCode=0`. |
| `2001` | Partner users | `op`, `un`, `ts`, `te`, `p` | JSON `success=true/errorCode=0`. |
| `2002` | Partner user summary | `op`, `nn`, `ts`, `te` | JSON `success=true/errorCode=0`. |
| `2003` | Gameplay history | `op`, `nn`, `ts`, `te`, `p` | JSON `success=true/errorCode=0`. |
| `2004` | Transfer history | `op`, `nn`, `type`, `status`, `ts`, `te`, `p` | JSON `success=true/errorCode=0`. |
| `2005` | Get operator | `op` | JSON `success=true/errorCode=0`, có `operator` nếu tồn tại. |
| `2006` | List operators | Không cần | JSON `success=true/errorCode=0`, có danh sách operator active. |
| `2008` | Get operator DB config | `operator_id` | JSON `success=true/errorCode=0`, có `operatorDatabaseConfig` nếu tồn tại. |

### 2.5 Backend Mutation APIs

Các flow này được tích hợp vào `backend_test_flow.sh` và chỉ nên chạy khi đã chuẩn bị môi trường test.

Trong `.env`:

```env
ENABLE_BACKEND_MUTATIONS=1
TARGET_NICKNAME=nickname_test
BACKEND_OTP=otp_admin
SMS_MOBILE=sdt_test
```

| Command | Mutation | Expected pass | Expected lỗi thường gặp |
|---:|---|---|---|
| `14` | Reset password | Plain text `0`. | `1001` input/OTP sai, `1008` OTP invalid, `1021` OTP expired/locked, `1035` user không tồn tại. |
| `100` | Update money user | JSON `success=true/errorCode=0`. | `1008` OTP invalid, `1021` OTP expired/locked, `1001` input invalid. |
| `718` | Send SMS | Plain text `0`. | `2` mobile không hợp lệ, `1` exception/gateway lỗi. |
| `401` | Send mail | JSON `success=true/errorCode=0`. | `10002` nickname không tồn tại, `10001` gửi thất bại, `MISSING PARAMETTER`. |
| `2010` | Create partner/operator | JSON `success=true`, có `operatorId`, `apiKey`, `secretKey`, `mysqlDatabase`, `mongoDatabase`. | `success=false` với `message` nếu duplicate hoặc DB error. |
| `2007` | Update operator | JSON `success=true/errorCode=0`. | `1002` thiếu id, `1003` update fail, `1004` parse number fail, `1005` exception. |
| `2009` | Update operator DB config | JSON `success=true/errorCode=0`. | `1002` thiếu id/operatorId, `1003` update fail, `1004` parse number fail, `1005` exception. |

### 2.6 BACKEND_OTP Lấy Từ Đâu

`BACKEND_OTP` trong `.env` chỉ là giá trị script gửi lên backend. Backend không tự đọc OTP từ `.env`.

Backend validate OTP theo logic:

| Trường hợp | Nguồn OTP thật |
|---|---|
| `game_common` phần `otp.otp_default` có giá trị | Dùng chính `OTP_DEFAULT`. Khi đó `BACKEND_OTP` phải bằng giá trị này. |
| `otp_default` rỗng | Dùng Google Authenticator/TOTP theo secret của super admin. Secret nằm trong bảng `vinplay.user_appotp`, cột `nick_name`, `secret`. |

Danh sách super admin lấy từ:

```text
game_common -> billing -> super_admin
```

Code liên quan:

- `BackendUtils.checkOTPSuperAdmin(...)`
- `OtpServiceImpl.checkOtp(...)`
- `GameCommon.getValueStr("SUPER_ADMIN")`
- `GameCommon.getValueStr("OTP_DEFAULT")`
- `VinPlayUtils.getUserSecretKey(nickname)`

### 2.7 Backend High-Risk Commands Không Nên Chạy Mặc Định

| Nhóm | Commands | Lý do |
|---|---|---|
| Cache write/remove | `702-715` | Có thể đổi money/cache/security online. |
| Agent money | `706`, `711`, `713`, `714`, `724` | Có thể chuyển tiền, refund, unfreeze. |
| Giftcode | `116`, `117`, `128-136`, `301-311` | Có thể tạo, update, block hoặc expose giftcode. |
| Payment provider mutation | `124`, `141`, `500`, `514`, `515` | Cần provider/order state thật. |
| Bot/admin chat/marketing | `6`, `1993`, `1994`, `1995`, `723` | Có side effect vận hành. |
| Security disable/update | `22`, `717` | Cần OTP/security context thật. |

## 3. Quy Ước PASS/WARN/FAIL

| Kết quả | Ý nghĩa |
|---|---|
| PASS | Route chạy đúng và response đạt expectation. |
| WARN | Route có response nhưng không đạt success, thường do thiếu data, OTP sai, token sai, external dependency chưa sẵn sàng. |
| FAIL | Preflight hoặc flow bắt buộc lỗi, ví dụ service không reachable, captcha không decode được, login không thể lấy session. |

## 4. Điều Kiện Môi Trường Trước Khi Test

| Hạng mục | Legacy Portal | VinPlayBackend |
|---|---|---|
| Service port | `8081` | `8082` |
| MySQL | Cần `vinplay`, `vinplay_minigame`, `vinplay_gamebai`, `vinplay_admin` tùy flow | Cần đủ pool `mysqlpoolname`, `mysqlpool_minigame`, `mysqlpool_admin`, `mysqlpool_gamebai` |
| MongoDB | Cần cho history/log một số API | Cần cho log/report một số API |
| Hazelcast | Cần cho login/session/token/cache | Cần cho login/cache/report |
| RabbitMQ | Không bắt buộc cho read-only smoke | Có thể cần cho một số OTP/SMS/payment flow |

Nếu service chưa mở port, expectation là test dừng ngay ở preflight với lỗi connection refused.

## 5. File Tham Chiếu Chính

| Nội dung | File |
|---|---|
| Legacy command map | `/Users/anthonynguyen/Downloads/ProjectsS8/winall_svn/s8-backend/Api/VinPlayPortal/config/api_portal.xml` |
| Legacy test script | `/Users/anthonynguyen/Downloads/ProjectsS8/winall_svn/s8-backend/player_test_flow.sh` |
| Backend command map | `/Users/anthonynguyen/Downloads/ProjectsS8/winall_svn/s8-backend/Api/VinPlayBackend/app/config/api_backend.xml` |
| Backend test script | `/Users/anthonynguyen/Downloads/ProjectsS8/winall_svn/s8-backend/backend_test_flow.sh` |
| Backend env | `/Users/anthonynguyen/Downloads/ProjectsS8/winall_svn/s8-backend/Api/VinPlayBackend/.env` |
| OTP note | `/Users/anthonynguyen/Desktop/command/gamelist/otp.md` |

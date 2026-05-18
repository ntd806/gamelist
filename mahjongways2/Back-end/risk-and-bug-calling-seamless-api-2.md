Nếu hiện tại server ổn định với **100 người chơi đồng thời**, mà tăng lên **10,000 lần**, tức khoảng:

```text
100 × 10,000 = 1,000,000 người chơi đồng thời
```

thì rủi ro không còn nằm ở “code game có chạy được không”, mà chuyển thành bài toán:

```text
concurrency
network I/O
Seamless API bottleneck
database write pressure
idempotency
queue/retry
state consistency
```

Dưới đây là các rủi ro theo mức độ nghiêm trọng giảm dần.

---

# P0 — Rủi ro thảm họa, có thể làm sập hệ thống hoặc lệch tiền

## 1. Seamless API bị quá tải trước game server

Với flow mới:

```text
1 BASE SPIN = ít nhất 1 DEBIT
nếu thắng = thêm 1 CREDIT
nếu không thắng = có thể thêm SETTLE
```

Nếu 1,000,000 user cùng chơi, Seamless API có thể phải chịu:

```text
1,000,000 DEBIT gần như cùng lúc
+
rất nhiều CREDIT / SETTLE sau đó
```

Rủi ro:

```text
Seamless timeout
DEBIT/CREDIT response chậm
trạng thái UNKNOWN tăng mạnh
retry storm
double debit / double credit nếu idempotency sai
```

Kết luận:

```text
Seamless API thường sẽ là bottleneck lớn nhất.
```

---

## 2. Retry storm làm hệ thống chết nhanh hơn

Khi Seamless timeout, backend retry. Nếu 1 triệu người cùng retry:

```text
request gốc đã nhiều
+
request retry còn nhiều hơn
```

Ví dụ:

```text
1,000,000 DEBIT
timeout 20%
= 200,000 retry
nếu retry thêm 3 lần
= 600,000 request phụ
```

Hệ quả:

```text
Seamless càng nghẽn
backend thread/socket càng bị giữ
queue phình to
latency tăng dây chuyền
```

Cách chặn:

```text
retry có backoff
circuit breaker
rate limit theo operator
queue tách DEBIT/CREDIT
không retry vô hạn
```

---

## 3. Double debit / double credit tăng xác suất cực mạnh

Ở tải thấp, bug idempotency có thể hiếm gặp. Ở tải cực cao, timeout/retry xảy ra liên tục.

Nếu retry dùng key sai:

```text
DEBIT timeout
retry bằng key mới
→ trừ tiền 2 lần
```

Nếu CREDIT dùng key sai:

```text
CREDIT timeout
retry bằng key mới
→ cộng thưởng 2 lần
```

Ở 100 user, có thể chưa thấy. Ở 1,000,000 user, lỗi này sẽ lộ ngay.

Bắt buộc có:

```text
debitIdempotencyKey cố định theo spinId
creditIdempotencyKey cố định theo spinId
unique constraint ở DB
state machine rõ ràng
```

---

## 4. Database nghẽn vì write quá nhiều

Mỗi spin có thể ghi:

```text
spin_history
transaction_mapping
seamless_log
pot/fund ledger
cascadeSteps
freeSpin state
jackpot history nếu có
```

Nếu mỗi user quay 1 spin / 5 giây:

```text
1,000,000 / 5 = 200,000 spins/second
```

Mỗi spin ghi 5–10 records:

```text
~1,000,000 đến 2,000,000 writes/second
```

Rủi ro:

```text
DB lock
index quá tải
connection pool full
disk I/O full
replication lag
history save fail
```

Cách chặn:

```text
write batching
event queue
append-only ledger
partition table theo ngày/game/room
archive history
tách DB game state và DB analytics
```

---

## 5. Race condition theo user

Nếu user gửi nhiều PLAY song song:

```text
PLAY A
PLAY B
PLAY C
```

Ở tải lớn, nếu không lock theo user:

```text
3 DEBIT cùng lúc
freeSpin remaining sai
balance response lộn thứ tự
spin result trả về sai thứ tự
```

Bắt buộc:

```text
1 user chỉ có 1 active spin tại một thời điểm
lock theo userId + gameCode
hoặc queue per user
```

---

# P1 — Rủi ro nghiêm trọng với game server

## 6. Thread pool / event loop bị block vì gọi Seamless sync

Nếu backend gọi Seamless API kiểu blocking:

```text
request vào
thread chờ Seamless response
```

Khi Seamless chậm:

```text
thread bị giữ
connection pool đầy
request mới không xử lý được
server treo dù CPU chưa full
```

Cách chặn:

```text
non-blocking HTTP client
timeout ngắn
bulkhead riêng cho Seamless
queue async settlement
không dùng chung thread pool cho game logic và external API
```

---

## 7. Connection pool cạn

Các pool dễ cạn:

```text
HTTP connection pool tới Seamless
DB connection pool
Redis connection pool
WebSocket connection
thread pool
```

Triệu chứng:

```text
latency tăng
timeout hàng loạt
server báo 5xx
auto play bị force stop hàng loạt
```

Cách chặn:

```text
pool sizing theo load test
backpressure
rate limit
circuit breaker
metrics realtime
```

---

## 8. Memory tăng do cascadeSteps quá nặng

Mahjong Ways 2 có cascade. Một result có thể chứa:

```text
reelsBefore
wins
removedPositions
goldenTransforms
reelsAfterDrop
nhiều cascadeSteps
```

Nếu response quá lớn và nhiều user cùng lúc:

```text
memory tăng mạnh
GC pressure
network bandwidth tăng
WebSocket buffer đầy
```

Cách chặn:

```text
giới hạn max cascade step
compress response nếu cần
không trả field thừa
stream thấp nhất có thể
lưu full audit DB, response chỉ đủ render
```

---

## 9. WebSocket broadcast gây nghẽn

Các event như:

```text
UPDATE_POT
BIG_WIN
FORCE_STOP_AUTO
```

nếu broadcast rộng quá:

```text
1 jackpot event gửi tới 1,000,000 clients
```

Rủi ro:

```text
network egress rất lớn
socket buffer đầy
server lag
client nhận chậm
```

Cách chặn:

```text
broadcast theo room
throttle UPDATE_POT
coalesce pot update
không broadcast mọi spin
BIG_WIN dùng queue riêng
```

---

# P2 — Rủi ro về money flow và consistency

## 10. Pot/fund ledger không chịu được concurrent update

Nếu mỗi DEBIT success đều:

```text
pot += moneyToPot
fund += moneyToFund
```

và nhiều spin cùng update một room:

```text
lost update
lock contention
deadlock
```

Cách chặn:

```text
append ledger event thay vì update trực tiếp liên tục
aggregate pot/fund theo batch
atomic increment
partition theo room
```

---

## 11. CREDIT thành công nhưng save history thất bại

Ở tải lớn, DB fail là chuyện có thể xảy ra.

Bug nguy hiểm:

```text
Seamless đã cộng tiền
DB không lưu spin result
```

Hậu quả:

```text
khó đối soát
user khiếu nại không có lịch sử
jackpot/fund lệch audit
```

Cách chặn:

```text
outbox pattern
transaction mapping tối thiểu phải save trước
recovery job từ seamless transaction log
idempotent replay
```

---

## 12. Timeout khiến trạng thái UNKNOWN quá nhiều

Khi Seamless chậm:

```text
DEBIT_UNKNOWN
CREDIT_UNKNOWN
SETTLE_UNKNOWN
```

Nếu không có job reconcile:

```text
spin treo
user không biết thắng/thua
balance không rõ
support quá tải
```

Cần có:

```text
transaction status query
reconciliation job
manual ops dashboard
pending timeout policy
```

---

# P3 — Rủi ro vận hành / monitoring

## 13. Không có metrics đủ sâu

Ở 100 user, chỉ nhìn CPU/RAM có vẻ đủ. Ở 1 triệu user, cần metrics theo từng lớp:

```text
QPS PLAY
DEBIT success/fail/timeout
CREDIT success/fail/timeout
avg/p95/p99 latency
pending spin count
retry count
queue depth
DB write latency
WebSocket buffer size
pot/fund lag
```

Không có metrics thì khi lỗi sẽ không biết nghẽn ở đâu.

---

## 14. Log quá nhiều làm nghẽn hệ thống

Nếu mỗi spin log full JSON:

```text
request
response
cascadeSteps
seamless raw payload
```

Ở tải lớn, log có thể giết server trước cả game logic.

Cách chặn:

```text
structured log
sampling
chỉ full log cho lỗi
tách audit log khỏi app log
async log pipeline
```

---

## 15. Auto play nhân tải lên rất nhanh

Auto play làm user không cần bấm liên tục. Nếu 1 triệu user bật auto:

```text
traffic đều và liên tục
không có khoảng nghỉ tự nhiên
```

Cần có:

```text
auto play rate limit
min interval per spin
server-side throttle
force stop khi hệ thống degraded
```

---

# Bảng tổng hợp rủi ro

| Mức | Rủi ro                     | Hậu quả                                     |
| --- | -------------------------- | ------------------------------------------- |
| P0  | Seamless quá tải           | Không debit/credit được, toàn hệ thống treo |
| P0  | Double debit/credit        | Mất tiền thật                               |
| P0  | Retry storm                | Tự khuếch đại lỗi, sập nhanh hơn            |
| P0  | DB write quá tải           | Không lưu được transaction/history          |
| P0  | Race condition theo user   | Trừ tiền/sai spin/sai free spin             |
| P1  | Blocking call tới Seamless | Thread pool chết                            |
| P1  | Connection pool cạn        | Timeout hàng loạt                           |
| P1  | Response cascade quá nặng  | Memory/GC/network nghẽn                     |
| P1  | Broadcast quá rộng         | WebSocket lag/sập                           |
| P2  | Pot/fund concurrent update | Lệch quỹ                                    |
| P2  | Credit xong save fail      | Khó đối soát                                |
| P2  | UNKNOWN state nhiều        | Spin treo, user khiếu nại                   |
| P3  | Thiếu metrics              | Không biết lỗi ở đâu                        |
| P3  | Log quá nhiều              | Disk/log pipeline nghẽn                     |
| P3  | Auto play quá mạnh         | Tải tăng đều không kiểm soát                |

---

# Kiến trúc nên có nếu muốn scale lớn

```text
Frontend
↓
Gateway / WebSocket layer
↓
Game API layer
↓
Per-user spin lock / queue
↓
Seamless adapter
    - rate limit
    - timeout
    - retry
    - circuit breaker
↓
Game logic engine
↓
Settlement state machine
↓
Event queue / outbox
↓
DB ledger / history / pot / fund
↓
Reconciliation jobs
```

---

# Rule sống còn khi scale Seamless API

```text
1. Không random trước DEBIT success.
2. Không retry DEBIT/CREDIT bằng key mới.
3. Không cho 1 user có nhiều spin active cùng lúc.
4. Không commit jackpot reset trước CREDIT success.
5. Không dùng balance cache làm source of truth.
6. Không để retry storm xảy ra khi Seamless chậm.
7. Không ghi DB đồng bộ quá nặng trong request path.
8. Không broadcast update pot mỗi spin cho toàn bộ user.
```

Nói ngắn gọn:

```text
Ở 100 user, bug có thể chưa lộ.
Ở 1,000,000 user, mọi bug về idempotency, timeout, retry, lock và DB write sẽ lộ ngay.
```

Với Seamless API, **rủi ro lớn nhất không phải random game**, mà là:

```text
DEBIT / CREDIT / RETRY / IDEMPOTENCY / STATE MACHINE
```

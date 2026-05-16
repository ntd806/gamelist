```text
[Nhóm rủi ro] → [Số thứ tự] → [Mức độ] → [Vấn đề] → [Cách xử lý] → [Backend / Frontend / QA cần làm]
```

Tài liệu này tổng hợp từ bản checklist trước của bạn về các flow: nạp tiền, rút tiền, bet/debit, win/credit, rollback, bonus/jackpot, callback, đối soát và admin adjustment. 

---

# TÀI LIỆU RÀ SOÁT RỦI RO GIAO DỊCH TIỀN VỚI SQL

## 0. Mục tiêu tài liệu

Tài liệu này dùng để rà soát các rủi ro khi xử lý giao dịch tiền trong hệ thống:

```text
Nạp tiền
Rút tiền
Đặt cược / trừ tiền
Trả thưởng / cộng tiền
Rollback / hoàn tiền
Bonus / jackpot
Callback payment / game provider
Đối soát
Admin adjustment
Worker / queue / retry
Frontend retry / timeout
```

Nguyên tắc cốt lõi:

> Hệ thống tiền không chỉ cần chạy đúng khi mọi thứ bình thường. Nó phải không mất tiền, không cộng trùng tiền, không trừ sai tiền, và vẫn truy vết được khi callback trễ, request retry, provider lỗi, user spam, worker chết, hoặc admin can thiệp.

---

# 1. Nhóm CRITICAL — Có thể mất tiền ngay / cộng tiền ảo / trừ sai tiền

---

## 1. Backend tin dữ liệu tiền từ frontend

**Mức độ:** CRITICAL
**Team chính:** Backend
**Team liên quan:** Frontend, QA

### Vấn đề

Frontend có thể bị sửa request. Nếu backend tin các field tiền từ frontend, user có thể tự cộng tiền hoặc sửa kết quả game.

Không được tin frontend gửi:

```text
balance
after_balance
win_amount
bonus_amount
jackpot_amount
multiplier
odds
result
is_win
```

Ví dụ nguy hiểm:

```json
{
  "user_id": 1001,
  "amount": 100000,
  "win_amount": 5000000,
  "is_win": true
}
```

### Cách xử lý

Frontend chỉ gửi hành động:

```json
{
  "game_id": "mahjong_ways_1",
  "round_id": "round_abc_001",
  "bet_amount": 100000,
  "action": "SPIN"
}
```

Backend phải tự xử lý:

```text
kiểm tra số dư
trừ tiền
random kết quả
tính thắng/thua
tính bonus
tính jackpot
cộng ví
ghi ledger
```

### Backend cần làm

```text
Không nhận balance/win_amount/result từ frontend làm nguồn quyết định.
Tự tính toàn bộ kết quả tiền.
Validate toàn bộ amount/action từ request.
```

### Frontend cần làm

```text
Chỉ gửi action và thông tin cần thiết.
Không tự tính win/loss/payout.
Chỉ render kết quả backend trả về.
```

### QA cần test

```text
Sửa request win_amount lớn bất thường.
Sửa is_win = true.
Sửa multiplier.
Sửa balance/after_balance.
Kỳ vọng: backend bỏ qua toàn bộ field không đáng tin.
```

---

## 2. Không dùng atomic update khi trừ tiền

**Mức độ:** CRITICAL
**Team chính:** Backend
**Team liên quan:** QA

### Vấn đề

Flow sai:

```text
SELECT balance
IF balance >= amount
UPDATE balance
```

Nếu nhiều request chạy cùng lúc, user có thể tiêu cùng một khoản tiền nhiều lần.

### Cách xử lý

Dùng atomic update:

```sql
UPDATE wallets
SET available_balance = available_balance - :amount
WHERE user_id = :user_id
  AND available_balance >= :amount;
```

Sau đó kiểm tra:

```text
affected_rows = 1 -> trừ thành công
affected_rows = 0 -> không đủ tiền hoặc request khác đã xử lý trước
```

### Backend cần làm

```text
Không check tiền bằng SELECT rồi xử lý ở application.
Dùng atomic UPDATE hoặc SELECT FOR UPDATE trong transaction.
```

### QA cần test

```text
Gửi 100 request bet cùng lúc.
Gửi 100 request withdraw cùng lúc.
Kỳ vọng: không âm tiền, không double spending.
```

---

## 3. Không dùng DB transaction cho wallet + ledger + business status

**Mức độ:** CRITICAL
**Team chính:** Backend
**Team liên quan:** QA

### Vấn đề

Một giao dịch tiền thường gồm nhiều bước:

```text
trừ ví
cộng ví
ghi transaction
ghi round result
ghi callback
ghi bonus
```

Nếu một bước thành công, bước sau lỗi, tiền sẽ lệch.

Ví dụ:

```text
Đã trừ tiền user nhưng chưa ghi ledger.
Đã lưu game thắng nhưng chưa cộng ví.
Đã ghi SUCCESS nhưng wallet chưa đổi.
```

### Cách xử lý

Các bước liên quan tiền phải nằm trong cùng DB transaction:

```sql
BEGIN;

UPDATE wallets
SET available_balance = available_balance - :amount
WHERE user_id = :user_id
  AND available_balance >= :amount;

INSERT INTO wallet_transactions (...);

UPDATE game_rounds
SET status = 'BET_PLACED'
WHERE id = :round_id;

COMMIT;
```

Nếu lỗi:

```sql
ROLLBACK;
```

### Backend cần làm

```text
Wallet update, ledger insert, status update phải commit cùng nhau.
Không set SUCCESS trước khi wallet update hoàn tất.
```

### QA cần test

```text
Giả lập lỗi sau khi update wallet.
Giả lập lỗi sau khi insert ledger.
Giả lập lỗi trước COMMIT.
Kỳ vọng: rollback toàn bộ.
```

---

## 4. Không có idempotency key

**Mức độ:** CRITICAL
**Team chính:** Backend
**Team liên quan:** Frontend, QA

### Vấn đề

Client timeout, user bấm lại, provider callback lại, worker retry lại.

Nếu không có idempotency, một giao dịch có thể bị xử lý nhiều lần:

```text
Nạp tiền cộng 2 lần
Rút tiền trừ 2 lần
Bet bị trừ 2 lần
Bonus cộng 2 lần
Callback success xử lý 3 lần
```

### Cách xử lý

Frontend tạo UUID v4:

```javascript
const idempotencyKey = crypto.randomUUID();
```

Backend lưu unique:

```sql
CREATE UNIQUE INDEX uniq_user_idempotency
ON wallet_transactions(user_id, idempotency_key);
```

Với game cần thêm business key:

```sql
CREATE UNIQUE INDEX uniq_game_action
ON wallet_transactions(user_id, game_id, round_id, action_type);
```

### Backend cần làm

```text
Nhận và lưu idempotency_key.
Retry cùng key phải trả kết quả cũ.
Cùng key nhưng payload khác phải trả 409 Conflict.
```

### Frontend cần làm

```text
Tạo UUID cho mỗi action mới.
Retry cùng action phải dùng lại UUID cũ.
Không tạo UUID mới khi request timeout.
```

### QA cần test

```text
Retry cùng idempotency_key, cùng payload.
Retry cùng idempotency_key, khác payload.
Gửi callback success 3 lần.
Kỳ vọng: chỉ xử lý tiền 1 lần.
```

---

## 5. Không có request_hash

**Mức độ:** CRITICAL
**Team chính:** Backend
**Team liên quan:** QA

### Vấn đề

Cùng idempotency key nhưng payload bị thay đổi.

Ví dụ lần 1:

```json
{
  "idempotency_key": "abc",
  "amount": 100000
}
```

Lần 2:

```json
{
  "idempotency_key": "abc",
  "amount": 900000
}
```

Nếu backend chỉ check key mà không check payload, rất nguy hiểm.

### Cách xử lý

Lưu `request_hash`:

```text
hash(user_id + action_type + amount + round_id + currency)
```

Nếu cùng idempotency key nhưng hash khác:

```text
409 Conflict - Idempotency key reused with different payload
```

### Backend cần làm

```text
Tính request_hash từ payload quan trọng.
Lưu request_hash với idempotency_key.
So sánh hash khi retry.
```

### QA cần test

```text
Gửi cùng key nhưng đổi amount.
Gửi cùng key nhưng đổi round_id.
Gửi cùng key nhưng đổi action_type.
Kỳ vọng: 409 Conflict.
```

---

## 6. Không verify callback signature

**Mức độ:** CRITICAL
**Team chính:** Backend
**Team liên quan:** QA, DevOps

### Vấn đề

Nếu callback endpoint public mà không verify chữ ký, người ngoài có thể gọi API giả:

```http
POST /deposit/callback
{
  "user_id": 1001,
  "amount": 10000000,
  "status": "SUCCESS"
}
```

Kết quả: tự cộng tiền vào ví.

### Cách xử lý

Callback phải verify:

```text
HMAC signature
raw body
timestamp
nonce
provider secret
IP whitelist nếu có
provider_reference_id
```

Không verify bằng object đã parse rồi stringify lại nếu provider yêu cầu ký trên raw body.

### Backend cần làm

```text
Verify signature trước khi xử lý tiền.
Lưu raw callback.
Reject callback sai signature.
```

### QA cần test

```text
Callback không có signature.
Callback sai signature.
Callback bị sửa amount.
Callback replay lại.
Kỳ vọng: không thay đổi ví.
```

---

## 7. Dùng FLOAT / DOUBLE cho tiền

**Mức độ:** CRITICAL
**Team chính:** Backend / Database
**Team liên quan:** QA

### Vấn đề

`FLOAT` và `DOUBLE` có sai số.

Ví dụ:

```text
0.1 + 0.2 = 0.30000000000000004
```

Với tiền, sai số nhỏ cũng gây lệch ledger.

### Cách xử lý

Dùng:

```sql
BIGINT
```

Lưu theo đơn vị nhỏ nhất.

Ví dụ:

```text
100.000 VND -> 100000
10.25 USD -> 1025 cents
```

Hoặc nếu bắt buộc:

```sql
DECIMAL(18,2)
```

### Backend cần làm

```text
Tất cả amount/balance/fee/jackpot/turnover dùng BIGINT hoặc DECIMAL.
Không dùng FLOAT/DOUBLE.
```

### QA cần test

```text
Test cộng/trừ nhiều giao dịch nhỏ.
Test phí phần trăm.
Test jackpot/bonus có số lẻ.
Kỳ vọng: ledger không lệch.
```

---

## 8. Không validate amount chặt

**Mức độ:** CRITICAL
**Team chính:** Backend
**Team liên quan:** Frontend, QA

### Vấn đề

Nếu user gửi:

```text
amount = -100000
amount = 0
amount = NaN
amount = null
amount quá lớn
```

Có thể gây cộng tiền ngược.

Ví dụ:

```sql
balance = balance - (-100000)
```

thành cộng tiền.

### Cách xử lý

Validate:

```text
amount > 0
amount là integer
amount <= max_allowed
amount >= min_allowed
currency hợp lệ
scale hợp lệ
```

### Backend cần làm

```text
Reject amount âm, 0, null, NaN, decimal sai scale.
Check min/max theo từng action.
```

### Frontend cần làm

```text
Validate UX trước khi gửi.
Không cho nhập amount sai format.
```

### QA cần test

```text
amount âm.
amount = 0.
amount null.
amount cực lớn.
amount decimal sai.
Kỳ vọng: backend reject.
```

---

## 9. Lấy user_id từ request body thay vì auth context

**Mức độ:** CRITICAL
**Team chính:** Backend
**Team liên quan:** QA

### Vấn đề

User có thể sửa request:

```json
{
  "user_id": 9999,
  "amount": 100000
}
```

Nếu backend tin `user_id` từ body, user có thể tác động vào ví người khác.

### Cách xử lý

Backend lấy user từ:

```text
authenticated_user_id
token/session
server-side auth context
```

Không lấy từ body cho action của chính user.

### Backend cần làm

```text
Ignore user_id từ body với API user tự thao tác.
Chỉ admin API mới được truyền target_user_id và phải có permission.
```

### QA cần test

```text
Login user A, gửi user_id của user B.
Kỳ vọng: backend vẫn xử lý theo user A hoặc reject.
```

---

## 10. Chỉ lưu balance, không có ledger

**Mức độ:** CRITICAL
**Team chính:** Backend / Database
**Team liên quan:** QA, Operation

### Vấn đề

Nếu chỉ có:

```text
wallet.balance = 500000
```

Sẽ không biết vì sao balance thành 500000.

Không thể audit:

```text
user mất tiền ở đâu
callback nào cộng tiền
round nào trừ tiền
admin nào chỉnh tiền
rollback nào xảy ra
```

### Cách xử lý

Cần bảng ledger:

```text
wallet_transactions
```

Gồm:

```text
id
user_id
type
direction
amount
before_balance
after_balance
reference_type
reference_id
status
idempotency_key
created_at
```

### Backend cần làm

```text
Mọi thay đổi ví phải có wallet_transaction.
Không update balance nếu không ghi ledger.
```

### QA cần test

```text
Mọi deposit/withdraw/bet/win/rollback đều sinh ledger.
So balance hiện tại với replay ledger.
```

---

## 11. Cho phép sửa/xóa transaction history

**Mức độ:** CRITICAL
**Team chính:** Backend / Database
**Team liên quan:** Operation, QA

### Vấn đề

Nếu transaction history bị sửa/xóa, không còn khả năng đối soát.

Sai:

```sql
DELETE FROM wallet_transactions WHERE id = :id;
UPDATE wallet_transactions SET amount = :new_amount;
```

### Cách xử lý

Không sửa lịch sử. Nếu sai, tạo transaction đảo:

```text
BET -100.000
ROLLBACK +100.000
```

Hoặc:

```text
ADJUSTMENT_CREDIT
ADJUSTMENT_DEBIT
REVERSAL
```

### Backend cần làm

```text
Không expose API update/delete ledger.
Dùng reversal/adjustment để sửa sai.
```

### QA cần test

```text
Kiểm tra không có endpoint sửa/xóa ledger.
Kiểm tra rollback tạo transaction mới.
```

---

## 12. Admin sửa balance trực tiếp

**Mức độ:** CRITICAL
**Team chính:** Backend / Admin Tool
**Team liên quan:** Operation, QA

### Vấn đề

Admin chạy:

```sql
UPDATE wallets SET balance = balance + 1000000
```

Không có lý do, không có audit, không có ledger.

### Cách xử lý

Admin adjustment phải tạo transaction:

```text
ADJUSTMENT_CREDIT
ADJUSTMENT_DEBIT
```

Cần lưu:

```text
requested_by
approved_by
reason
evidence
before_balance
after_balance
created_at
```

### Backend cần làm

```text
Admin tool không update balance trực tiếp.
Mọi adjustment đi qua service tạo ledger.
```

### QA cần test

```text
Admin cộng tiền.
Admin trừ tiền.
Adjustment lớn cần approval.
Ledger và audit log phải đầy đủ.
```

---

# 2. Nhóm CRITICAL — Rút tiền / tiền thật rời hệ thống

---

## 13. Không tách available_balance và locked_balance

**Mức độ:** CRITICAL
**Team chính:** Backend
**Team liên quan:** Frontend, QA

### Vấn đề

User vừa tạo lệnh rút, vừa tiếp tục dùng tiền để chơi.

Ví dụ:

```text
available_balance = 1.000.000
User rút 1.000.000
Trong lúc pending, user bet tiếp 1.000.000
```

Nếu không lock tiền, hệ thống bị double spending.

### Cách xử lý

Wallet nên có:

```text
available_balance
locked_balance
real_balance
bonus_balance
```

Khi tạo lệnh rút:

```text
available_balance - amount
locked_balance + amount
```

Khi rút thành công:

```text
locked_balance - amount
```

Khi rút thất bại:

```text
locked_balance - amount
available_balance + amount
```

### Backend cần làm

```text
Withdraw request phải lock tiền trước.
Không gửi provider nếu lock tiền thất bại.
```

### Frontend cần làm

```text
Hiển thị available balance và locked/pending withdraw.
Không hiển thị nhầm locked money là tiền có thể chơi/rút.
```

### QA cần test

```text
Tạo withdraw rồi bet cùng lúc.
Tạo nhiều withdraw cùng lúc.
Kỳ vọng: không double spend.
```

---

## 14. Release tiền rút quá sớm khi provider timeout

**Mức độ:** CRITICAL
**Team chính:** Backend
**Team liên quan:** Operation, QA

### Vấn đề

Timeout không có nghĩa là thất bại.

Flow nguy hiểm:

```text
1. Gửi rút sang provider
2. Provider timeout
3. Hệ thống đánh FAILED và trả tiền lại user
4. Sau đó provider callback SUCCESS
5. Tiền đã chuyển ra ngoài, user cũng đã được trả lại tiền trong ví
```

### Cách xử lý

Khi timeout, dùng trạng thái:

```text
UNKNOWN
NEED_REQUERY
MANUAL_REVIEW
```

Không release tiền ngay.

Flow an toàn:

```text
PROCESSING timeout
-> UNKNOWN
-> re-query provider
-> SUCCESS: trừ locked
-> FAILED thật sự: release locked
-> vẫn không rõ: manual review
```

### Backend cần làm

```text
Timeout không được map thẳng thành FAILED.
Phải có job re-query provider.
```

### QA cần test

```text
Provider timeout.
Sau timeout gửi callback SUCCESS.
Kỳ vọng: không release tiền trước khi rõ kết quả.
```

---

## 15. Late success callback sau khi đã failed/released

**Mức độ:** CRITICAL
**Team chính:** Backend
**Team liên quan:** Operation, QA

### Vấn đề

Rút tiền đã bị đánh failed và release tiền. Sau đó provider lại báo success.

Nếu xử lý tự động, hệ thống có thể mất tiền.

### Cách xử lý

Nếu request đã:

```text
FAILED
REJECTED
CANCELLED
EXPIRED
```

mà nhận callback `SUCCESS`, không tự động trừ ví.

Chuyển sang:

```text
LATE_SUCCESS_CALLBACK
MANUAL_REVIEW
```

### Backend cần làm

```text
Callback handler phải check current status.
Không xử lý callback mù.
```

### QA cần test

```text
Withdraw failed/released.
Sau đó callback success.
Kỳ vọng: vào manual review, không auto trừ ví.
```

---

## 16. Fallback provider khi attempt cũ đang UNKNOWN

**Mức độ:** CRITICAL
**Team chính:** Backend / Payment
**Team liên quan:** Operation, QA

### Vấn đề

Provider A timeout. Hệ thống tự động gửi provider B.

Sau đó:

```text
A success
B success
```

User nhận 2 lần.

### Cách xử lý

Nếu provider A timeout:

```text
UNKNOWN
NEED_REQUERY
```

Không fallback tự động nếu chưa xác minh A chắc chắn fail.

### Backend cần làm

```text
Lưu provider_attempts.
Không gửi provider mới nếu attempt trước chưa final.
```

### QA cần test

```text
Provider A timeout.
System fallback provider B.
Sau đó A success.
Kỳ vọng: không double payout.
```

---

## 17. Cho user cancel khi withdraw đã PROCESSING

**Mức độ:** HIGH
**Team chính:** Backend / Frontend
**Team liên quan:** QA

### Vấn đề

Nếu user cancel khi tiền đã gửi sang provider/bank:

```text
user cancel -> hệ thống release tiền
provider vẫn chuyển khoản thành công
```

### Cách xử lý

Chỉ cho cancel khi:

```text
CREATED
PENDING_REVIEW
```

Không cho cancel khi:

```text
APPROVED
PROCESSING
SUCCESS
```

### Backend cần làm

```text
Cancel API phải check state.
```

### Frontend cần làm

```text
Ẩn nút cancel khi request đã processing.
```

### QA cần test

```text
Cancel withdraw ở PENDING.
Cancel withdraw ở PROCESSING.
Kỳ vọng: PROCESSING không cho cancel.
```

---

## 18. Không kiểm tra withdrawable balance

**Mức độ:** HIGH
**Team chính:** Backend
**Team liên quan:** Frontend, QA

### Vấn đề

Không phải toàn bộ balance đều được rút.

Balance có thể gồm:

```text
tiền thật
bonus
locked money
tiền chưa đủ turnover
tiền đang dispute
```

Nếu chỉ check `balance`, user có thể rút cả bonus hoặc tiền chưa đủ điều kiện.

### Cách xử lý

Tính:

```text
withdrawable_balance
= real_balance
- locked_balance
- non_withdrawable_bonus
- pending_dispute_amount
```

### Backend cần làm

```text
Withdraw check withdrawable_balance, không check total balance.
```

### Frontend cần làm

```text
Hiển thị withdrawable balance riêng.
```

### QA cần test

```text
Rút khi có bonus chưa đủ turnover.
Rút khi có locked balance.
Rút khi có pending dispute.
Kỳ vọng: chỉ rút phần withdrawable.
```

---

# 3. Nhóm CRITICAL/HIGH — Nạp tiền

---

## 19. Cộng tiền dựa trên frontend báo đã thanh toán

**Mức độ:** CRITICAL
**Team chính:** Backend
**Team liên quan:** Frontend, QA

### Vấn đề

User upload ảnh bill hoặc frontend báo `PAID`, backend cộng ví ngay.

Đây là lỗi cực nguy hiểm.

### Cách xử lý

Chỉ cộng ví khi có nguồn đáng tin:

```text
payment provider callback đã verify
bank statement đã match
admin verification có audit
```

Ảnh biên lai chỉ là bằng chứng hỗ trợ, không phải trigger cộng tiền.

### Backend cần làm

```text
Không có API frontend nào được tự set deposit SUCCESS.
```

### Frontend cần làm

```text
Upload proof chỉ chuyển trạng thái PENDING_VERIFICATION.
Không hiển thị là đã cộng tiền.
```

### QA cần test

```text
Upload bill giả.
Frontend gửi status PAID.
Kỳ vọng: không cộng ví.
```

---

## 20. Callback nạp tiền bị xử lý nhiều lần

**Mức độ:** CRITICAL
**Team chính:** Backend
**Team liên quan:** QA

### Vấn đề

Provider có thể gửi callback nhiều lần:

```text
SUCCESS
SUCCESS
SUCCESS
```

Nếu không chống trùng, user được cộng tiền nhiều lần.

### Cách xử lý

Unique provider reference:

```sql
CREATE UNIQUE INDEX uniq_provider_deposit_ref
ON deposit_requests(provider, provider_reference_id);
```

Update theo state:

```sql
UPDATE deposit_requests
SET status = 'SUCCESS'
WHERE id = :id
  AND status = 'PENDING';
```

Chỉ khi `affected_rows = 1` mới cộng ví.

### Backend cần làm

```text
Callback handler phải idempotent.
provider_reference_id phải unique.
```

### QA cần test

```text
Gửi cùng callback success 3 lần.
Kỳ vọng: ví chỉ cộng 1 lần.
```

---

## 21. Amount mismatch khi nạp tiền

**Mức độ:** HIGH
**Team chính:** Backend
**Team liên quan:** Operation, QA

### Vấn đề

User tạo lệnh nạp 1.000.000 nhưng chuyển:

```text
999.000
1.010.000
10.000.000
```

Nếu backend tự động cộng bừa, ledger có thể lệch.

### Cách xử lý

So sánh:

```text
deposit_request.amount
callback.amount
currency
provider_ref
```

Nếu lệch:

```text
UNDERPAID
OVERPAID
AMOUNT_MISMATCH
MANUAL_REVIEW
```

### Backend cần làm

```text
Không auto SUCCESS nếu amount/currency mismatch.
```

### QA cần test

```text
Nạp thiếu.
Nạp dư.
Nạp sai currency.
Kỳ vọng: manual review hoặc rule rõ.
```

---

## 22. Callback success nhưng không match được deposit request

**Mức độ:** HIGH
**Team chính:** Backend
**Team liên quan:** Operation, QA

### Vấn đề

User chuyển khoản sai nội dung, sai mã nạp, hoặc callback về trước khi hệ thống lưu request.

Nếu bỏ qua callback, user đã nạp tiền nhưng không được cộng.

### Cách xử lý

Lưu raw callback vào bảng riêng:

```text
deposit_callbacks
payment_callbacks
```

Nếu không match được:

```text
UNMATCHED
MANUAL_REVIEW
```

### Backend cần làm

```text
Mọi callback đều lưu raw trước.
Unmatched callback không được bỏ qua.
```

### QA cần test

```text
Callback không có deposit_code.
Callback có provider_ref lạ.
Kỳ vọng: lưu unmatched, không mất dữ liệu.
```

---

## 23. Deposit expired nhưng tiền về sau

**Mức độ:** HIGH
**Team chính:** Backend
**Team liên quan:** Operation, QA

### Vấn đề

User tạo lệnh nạp, lệnh hết hạn, sau đó tiền mới về.

Nếu hệ thống bỏ qua, user mất tiền. Nếu tự cộng bừa, dễ sai đối soát.

### Cách xử lý

Trạng thái:

```text
LATE_PAYMENT
MANUAL_REVIEW
```

Kiểm tra lại:

```text
amount
deposit_code
sender account
provider reference
payment time
```

### Backend cần làm

```text
Expired request vẫn có thể nhận callback.
Không drop callback vì request expired.
```

### QA cần test

```text
Deposit expired.
Sau đó callback success.
Kỳ vọng: late payment/manual review.
```

---

## 24. Chargeback / refund / reversal sau khi đã cộng ví

**Mức độ:** HIGH
**Team chính:** Backend / Operation
**Team liên quan:** QA

### Vấn đề

User nạp tiền thành công, được cộng ví, sau đó payment bị chargeback hoặc refund.

Có thể lúc đó user đã:

```text
chơi hết tiền
rút tiền
chuyển tiền
```

### Cách xử lý

Cần trạng thái:

```text
CHARGEBACK
REFUND
REVERSED
DISPUTED
```

Ledger:

```text
DEPOSIT_SUCCESS +1.000.000
DEPOSIT_CHARGEBACK -1.000.000
```

Nếu user không đủ tiền:

```text
freeze account
negative balance nếu policy cho phép
manual review
khóa withdraw
```

### Backend cần làm

```text
Không xóa deposit cũ.
Tạo reversal transaction.
```

### QA cần test

```text
Deposit success.
User bet/rút.
Sau đó chargeback.
Kỳ vọng: có policy xử lý rõ.
```

---

# 4. Nhóm CRITICAL — Game / Betting / Round Settlement

---

## 25. Client tự tạo round_id mà backend không kiểm soát

**Mức độ:** CRITICAL
**Team chính:** Backend
**Team liên quan:** Frontend, QA

### Vấn đề

Nếu frontend tự tạo round_id, user có thể spam round giả.

### Cách xử lý

Backend tạo round:

```text
/create-round
-> backend tạo round_id
-> status = CREATED
-> frontend chỉ dùng round_id đã được cấp
```

### Backend cần làm

```text
Round_id phải được tạo hoặc verify bởi backend/game server.
```

### Frontend cần làm

```text
Không tự phát minh round_id cho giao dịch tiền.
```

### QA cần test

```text
Gửi round_id giả.
Gửi round_id của user khác.
Kỳ vọng: reject.
```

---

## 26. Không có state machine cho game round

**Mức độ:** CRITICAL
**Team chính:** Backend
**Team liên quan:** QA

### Vấn đề

Không có state rõ thì cùng một round có thể bị xử lý sai thứ tự.

Ví dụ:

```text
WIN trước BET
ROLLBACK sau WIN
SETTLE 2 lần
BET sau CANCEL
```

### Cách xử lý

State machine mẫu:

```text
CREATED
-> BET_PLACED
-> SETTLED

CREATED
-> CANCELLED

BET_PLACED
-> ROLLBACK
```

Không cho nhảy trạng thái ngoài rule.

### Backend cần làm

```text
Mỗi action phải check current state.
Update state bằng WHERE status = trạng_thái_hợp_lệ.
```

### QA cần test

```text
WIN trước BET.
SETTLE 2 lần.
ROLLBACK sau SETTLED.
Kỳ vọng: reject action sai state.
```

---

## 27. Settle game không atomic với wallet

**Mức độ:** CRITICAL
**Team chính:** Backend
**Team liên quan:** QA

### Vấn đề

Game báo user thắng nhưng ví chưa được cộng, hoặc ví đã cộng nhưng round chưa settle.

### Cách xử lý

Nếu cùng DB, dùng transaction:

```sql
BEGIN;

UPDATE game_rounds
SET status = 'SETTLED',
    win_amount = :win_amount
WHERE round_id = :round_id
  AND status = 'BET_PLACED';

UPDATE wallets
SET available_balance = available_balance + :win_amount
WHERE user_id = :user_id;

INSERT INTO wallet_transactions (...);

COMMIT;
```

Nếu khác service/database, cần:

```text
outbox pattern
event log
compensation transaction
reconciliation
```

### Backend cần làm

```text
Game result, wallet update, ledger phải nhất quán.
```

### QA cần test

```text
Lỗi sau khi update round.
Lỗi sau khi cộng ví.
Kỳ vọng: không lệch round và wallet.
```

---

## 28. Random/result tính ở frontend

**Mức độ:** CRITICAL
**Team chính:** Backend
**Team liên quan:** Frontend, QA

### Vấn đề

Nếu kết quả game tính ở client, user có thể sửa memory, response, JS hoặc request để thắng.

### Cách xử lý

Backend/game server phải xử lý:

```text
RNG
symbol result
ways/line calculation
payout
bonus
jackpot
wallet update
```

Frontend chỉ render:

```text
reels
animation
result display
```

### Backend cần làm

```text
RNG và payout table nằm server-side.
```

### Frontend cần làm

```text
Không tự tính thắng/thua.
Không gửi result để backend tin.
```

### QA cần test

```text
Sửa response/result ở client.
Sửa symbol result.
Kỳ vọng: backend không tin client.
```

---

# 5. Nhóm HIGH — Bonus / Jackpot / Promotion

---

## 29. Không tách real_balance và bonus_balance

**Mức độ:** HIGH
**Team chính:** Backend
**Team liên quan:** Frontend, QA

### Vấn đề

Nếu cộng tiền thật và bonus vào cùng một cột `balance`, sẽ khó kiểm soát:

```text
bonus có được rút không?
win từ bonus tính thế nào?
turnover đã đủ chưa?
rollback về ví nào?
```

### Cách xử lý

Tách ví:

```text
real_balance
bonus_balance
locked_balance
withdrawable_balance
```

Ledger riêng:

```text
DEPOSIT_SUCCESS + real_balance
DEPOSIT_BONUS + bonus_balance
BET_DEBIT_REAL
BET_DEBIT_BONUS
WIN_CREDIT_REAL
WIN_CREDIT_BONUS
```

### Backend cần làm

```text
Phân biệt nguồn tiền trong mọi transaction.
```

### Frontend cần làm

```text
Hiển thị tiền thật, bonus, withdrawable rõ ràng.
```

### QA cần test

```text
Nạp có bonus.
Bet bằng bonus.
Rút khi chưa đủ turnover.
Rollback bet split real/bonus.
```

---

## 30. Bonus bị cộng nhiều lần do callback trùng

**Mức độ:** HIGH
**Team chính:** Backend
**Team liên quan:** QA

### Vấn đề

Deposit callback bị gửi nhiều lần. Deposit có thể chỉ cộng 1 lần nhưng bonus lại bị cộng nhiều lần nếu bonus không idempotent.

### Cách xử lý

Bonus transaction cũng cần unique:

```text
deposit_request_id + bonus_campaign_id
```

Ví dụ:

```sql
CREATE UNIQUE INDEX uniq_deposit_bonus
ON bonus_transactions(deposit_request_id, campaign_id);
```

### Backend cần làm

```text
Bonus cũng phải có idempotency và ledger.
```

### QA cần test

```text
Gửi callback deposit success nhiều lần.
Kỳ vọng: bonus chỉ cộng 1 lần.
```

---

## 31. Không kiểm tra turnover trước khi rút

**Mức độ:** HIGH
**Team chính:** Backend
**Team liên quan:** Frontend, QA

### Vấn đề

User nhận bonus nhưng chưa đủ điều kiện cược vòng, vẫn rút được tiền.

### Cách xử lý

Cần lưu:

```text
turnover_required
turnover_completed
bonus_status
withdrawable_amount
```

Khi rút tiền:

```text
Nếu turnover chưa đủ -> không cho rút phần bị khóa
```

### Backend cần làm

```text
Withdraw phải check bonus/turnover trước khi approve.
```

### QA cần test

```text
Bonus chưa đủ turnover.
User rút toàn bộ balance.
Kỳ vọng: reject hoặc chỉ cho rút phần hợp lệ.
```

---

## 32. Jackpot không có nguồn tiền và ledger riêng

**Mức độ:** MEDIUM - HIGH
**Team chính:** Backend
**Team liên quan:** Operation, QA

### Vấn đề

Jackpot cộng tiền cho user nhưng không rõ tiền đến từ đâu:

```text
system fund
jackpot pool
operator wallet
promotion budget
```

Nếu không có pool/ledger, đối soát sẽ lệch.

### Cách xử lý

Jackpot nên có:

```text
jackpot_pool
jackpot_contribution
jackpot_payout
jackpot_round_id
```

Ledger:

```text
JACKPOT_CONTRIBUTION + pool
JACKPOT_PAYOUT - pool, + user real_balance
```

### Backend cần làm

```text
Jackpot payout phải idempotent.
Jackpot pool phải đối soát được.
```

### QA cần test

```text
Hit jackpot.
Retry jackpot payout.
Rollback round có jackpot.
Kỳ vọng: không payout trùng, pool khớp.
```

---

# 6. Nhóm HIGH — Callback / Provider / External System

---

## 33. Không lưu raw callback

**Mức độ:** HIGH
**Team chính:** Backend
**Team liên quan:** Operation, QA

### Vấn đề

Khi có tranh chấp, không biết provider đã gửi gì.

### Cách xử lý

Lưu:

```text
provider
provider_reference_id
raw_payload
raw_headers
signature_valid
received_at
process_status
error_message
```

### Backend cần làm

```text
Lưu raw callback trước khi xử lý business logic.
```

### QA cần test

```text
Callback success.
Callback fail.
Callback sai signature.
Kỳ vọng: đều có raw log.
```

---

## 34. Callback về sai thứ tự

**Mức độ:** HIGH
**Team chính:** Backend
**Team liên quan:** QA

### Vấn đề

Provider có thể gửi:

```text
PENDING
SUCCESS
FAILED
SUCCESS
```

Nếu không có state machine, hệ thống có thể rollback sai.

### Cách xử lý

Nếu đã `SUCCESS`, callback `FAILED` về sau không được tự động trừ tiền.

Chuyển sang:

```text
CONFLICT_EVENT
MANUAL_REVIEW
```

### Backend cần làm

```text
Callback phải check state hiện tại.
Event cũ không được ghi đè state mới.
```

### QA cần test

```text
SUCCESS trước, FAILED sau.
FAILED trước, SUCCESS sau.
Kỳ vọng: xử lý theo state machine.
```

---

## 35. Không chống replay request

**Mức độ:** HIGH
**Team chính:** Backend
**Team liên quan:** DevOps, QA

### Vấn đề

Request hợp lệ bị gửi lại nhiều lần.

### Cách xử lý

Với API nội bộ/provider:

```text
HMAC signature
timestamp
nonce
body hash
idempotency key
```

Nonce đã dùng thì không cho dùng lại.

### Backend cần làm

```text
Lưu nonce đã dùng.
Reject timestamp quá cũ.
```

### QA cần test

```text
Replay cùng request.
Replay request sau nhiều phút.
Kỳ vọng: reject.
```

---

## 36. Dùng chung API key cho nhiều service

**Mức độ:** HIGH
**Team chính:** Backend / DevOps
**Team liên quan:** QA

### Vấn đề

Nếu mọi service dùng chung key, khi lộ key sẽ gọi được tất cả endpoint tiền.

### Cách xử lý

Tách quyền:

```text
game-service: chỉ settle game
payment-service: chỉ deposit/withdraw callback
admin-service: adjustment cần approval
```

### Backend / DevOps cần làm

```text
Tách API key theo service.
Scope permission theo endpoint/action.
Rotate key định kỳ.
```

### QA cần test

```text
Game key gọi withdraw callback.
Payment key gọi admin adjustment.
Kỳ vọng: bị reject.
```

---

# 7. Nhóm HIGH — Worker / Queue / Event

---

## 37. Nhiều worker xử lý cùng một job tiền

**Mức độ:** CRITICAL / HIGH
**Team chính:** Backend
**Team liên quan:** QA, DevOps

### Vấn đề

Hai worker cùng pick một job:

```text
worker A xử lý transaction X
worker B cũng xử lý transaction X
```

Rủi ro: cộng/trừ tiền trùng.

### Cách xử lý

Dùng claim job atomic:

```sql
UPDATE jobs
SET status = 'PROCESSING',
    locked_by = :worker_id,
    locked_at = NOW()
WHERE id = :job_id
  AND status = 'PENDING';
```

Chỉ worker nào update được `affected_rows = 1` mới xử lý.

### Backend cần làm

```text
Job tiền phải claim atomic.
Worker xử lý phải idempotent.
```

### QA cần test

```text
Hai worker cùng pick một job.
Kỳ vọng: chỉ một worker xử lý.
```

---

## 38. Worker chết giữa PROCESSING

**Mức độ:** HIGH
**Team chính:** Backend / DevOps
**Team liên quan:** QA

### Vấn đề

Worker lấy job:

```text
status = PROCESSING
```

Sau đó server crash.

Rủi ro: job kẹt mãi.

### Cách xử lý

Cần lease timeout:

```text
PROCESSING quá X phút
-> kiểm tra lại trạng thái thật
-> retry nếu an toàn
-> manual review nếu không chắc
```

Bảng job nên có:

```text
locked_by
locked_at
retry_count
last_error
next_retry_at
```

### Backend cần làm

```text
Có pending scanner.
Có retry policy.
Có manual review cho job không chắc.
```

### QA cần test

```text
Kill worker giữa job.
Kỳ vọng: job được recover hoặc manual review.
```

---

## 39. Publish event trước khi DB commit

**Mức độ:** HIGH
**Team chính:** Backend
**Team liên quan:** QA

### Vấn đề

Code publish event trước khi commit DB:

```text
publish DepositSuccess
DB rollback
consumer đã cộng bonus
```

### Cách xử lý

Dùng outbox pattern:

```text
ghi outbox_event cùng DB transaction
worker đọc outbox sau commit rồi publish
```

### Backend cần làm

```text
Không publish event tiền trước commit.
Consumer cũng phải idempotent.
```

### QA cần test

```text
Publish event rồi DB rollback.
Kỳ vọng: consumer không xử lý event không có transaction thật.
```

---

## 40. Settlement batch bị chạy lại

**Mức độ:** HIGH
**Team chính:** Backend
**Team liên quan:** QA, Operation

### Vấn đề

Job cuối ngày chạy payout/commission/cashback. Job lỗi giữa chừng và chạy lại.

Rủi ro: cộng cashback/commission nhiều lần.

### Cách xử lý

Batch item phải có unique key:

```text
settlement_date + user_id + settlement_type
```

Ví dụ:

```sql
CREATE UNIQUE INDEX uniq_daily_cashback
ON settlement_transactions(business_date, user_id, settlement_type);
```

### Backend cần làm

```text
Batch phải resumable.
Mỗi item có trạng thái riêng.
```

### QA cần test

```text
Batch chạy được 70%, sau đó lỗi.
Chạy lại batch.
Kỳ vọng: không cộng trùng 70% đã xử lý.
```

---

# 8. Nhóm HIGH — Admin / Manual Operation

---

## 41. Không có maker-checker cho adjustment lớn

**Mức độ:** HIGH
**Team chính:** Backend / Admin Tool
**Team liên quan:** Operation, QA

### Vấn đề

Một admin tự tạo và tự duyệt cộng/trừ tiền.

### Cách xử lý

Với adjustment vượt ngưỡng:

```text
người tạo yêu cầu
người duyệt khác
lý do bắt buộc
audit log
```

### Backend cần làm

```text
Adjustment lớn phải có approval flow.
```

### QA cần test

```text
Admin tự tạo tự duyệt adjustment lớn.
Kỳ vọng: không cho.
```

---

## 42. Không log admin action

**Mức độ:** HIGH
**Team chính:** Backend / Admin Tool
**Team liên quan:** Operation, QA

### Vấn đề

Không biết ai đã duyệt rút tiền, ai reject, ai adjustment.

### Cách xử lý

Admin log:

```text
admin_id
action
target_user_id
target_transaction_id
old_value
new_value
reason
ip
created_at
```

### Backend cần làm

```text
Mọi thao tác admin liên quan tiền phải có audit log.
```

### QA cần test

```text
Approve withdraw.
Reject withdraw.
Manual adjustment.
Kỳ vọng: audit đầy đủ.
```

---

## 43. Race condition giữa manual review và callback

**Mức độ:** CRITICAL
**Team chính:** Backend / Admin Tool
**Team liên quan:** Operation, QA

### Vấn đề

Admin đang xử lý thủ công một withdraw/deposit. Cùng lúc provider callback về.

Ví dụ:

```text
admin đánh FAILED và release tiền
callback SUCCESS về cùng lúc
```

Rủi ro:

```text
double release
double debit
trạng thái mâu thuẫn
```

### Cách xử lý

Manual action và callback đều phải update bằng state condition:

```sql
UPDATE withdraw_requests
SET status = 'FAILED'
WHERE id = :id
  AND status IN ('PENDING_REVIEW', 'PROCESSING', 'UNKNOWN');
```

Nếu `affected_rows = 0`, nghĩa là trạng thái đã bị bên khác xử lý.

### Backend cần làm

```text
Admin action cũng phải idempotent và state-safe.
```

### QA cần test

```text
Admin reject cùng lúc callback success.
Admin approve cùng lúc callback failed.
Kỳ vọng: chỉ một state transition hợp lệ.
```

---

# 9. Nhóm HIGH — Fraud / Risk / KYC

---

## 44. Không verify bank account khi rút

**Mức độ:** HIGH
**Team chính:** Backend / Operation
**Team liên quan:** Frontend, QA

### Vấn đề

User rút về tài khoản không xác minh, tài khoản của người khác, hoặc blacklist.

### Cách xử lý

Bank account cần:

```text
verified_status
account_holder_name
bank_name
account_number_masked
created_at
last_used_at
risk_status
```

Rule:

```text
chỉ rút về account đã verified
tên account match KYC
account mới thêm có thể hold 24h
blacklist thì reject
```

### Backend cần làm

```text
Withdraw API chỉ nhận verified bank account.
Lưu snapshot bank khi tạo withdraw.
```

### QA cần test

```text
Rút về bank chưa verify.
Sửa bank sau khi tạo withdraw.
Kỳ vọng: reject hoặc dùng snapshot cũ.
```

---

## 45. Không có fraud rules cho rút tiền

**Mức độ:** HIGH
**Team chính:** Backend / Risk
**Team liên quan:** Operation, QA

### Vấn đề

Các hành vi rủi ro:

```text
vừa nạp đã rút ngay
rút toàn bộ sau khi thắng lớn
nhiều account rút về cùng bank
đổi bank liên tục
nhiều user cùng IP/device
rút sát max limit nhiều lần
chưa đủ turnover nhưng muốn rút
```

### Cách xử lý

Đưa vào:

```text
MANUAL_REVIEW
WITHDRAW_HOLD
RISK_CHECK
```

### Backend cần làm

```text
Có risk rule trước khi approve withdraw.
```

### QA cần test

```text
User vừa nạp vừa rút.
Nhiều user cùng bank.
User rút sát limit nhiều lần.
Kỳ vọng: manual review/hold.
```

---

## 46. Negative balance không có policy

**Mức độ:** HIGH
**Team chính:** Backend / Product / Operation
**Team liên quan:** QA

### Vấn đề

Chargeback hoặc reversal khiến user balance âm.

Cần policy:

```text
có cho âm không?
âm thì khóa chơi không?
âm thì deposit mới bù trước không?
âm có cho rút không?
```

### Cách xử lý

Nếu cho negative balance:

```text
debt_balance
restricted_status
```

Nếu không cho âm:

```text
freeze account
manual collection/review
```

### Backend cần làm

```text
Có rule xử lý chargeback khi user không đủ balance.
```

### QA cần test

```text
Deposit success.
User rút/chơi hết tiền.
Chargeback về.
Kỳ vọng: xử lý theo policy.
```

---

# 10. Nhóm HIGH/MEDIUM — Validation / Limit / Currency / Fee

---

## 47. Integer overflow

**Mức độ:** HIGH
**Team chính:** Backend / Database
**Team liên quan:** QA

### Vấn đề

Dùng `INT` có thể vượt giới hạn khi hệ thống có turnover lớn.

### Cách xử lý

Dùng `BIGINT` cho:

```text
amount
balance
turnover
jackpot_pool
daily_total
monthly_total
```

### QA cần test

```text
Amount lớn.
Turnover lớn.
Jackpot pool lớn.
Kỳ vọng: không overflow.
```

---

## 48. Không có constraint số dư không âm

**Mức độ:** HIGH
**Team chính:** Backend / Database
**Team liên quan:** QA

### Vấn đề

Bug application có thể khiến balance âm.

### Cách xử lý

Nếu policy không cho âm:

```sql
ALTER TABLE wallets
ADD CONSTRAINT chk_available_non_negative
CHECK (available_balance >= 0);

ALTER TABLE wallets
ADD CONSTRAINT chk_locked_non_negative
CHECK (locked_balance >= 0);
```

### QA cần test

```text
Cố update balance âm.
Kỳ vọng: DB reject.
```

---

## 49. Không giới hạn min/max deposit/withdraw/bet

**Mức độ:** MEDIUM - HIGH
**Team chính:** Backend / Product
**Team liên quan:** Frontend, QA

### Vấn đề

User spam lệnh nhỏ, lệnh lớn bất thường, hoặc vượt ngưỡng risk.

### Cách xử lý

Rule cần có:

```text
min_deposit
max_deposit_per_request
min_withdraw
max_withdraw_per_request
max_bet_per_round
daily_deposit_limit
daily_withdraw_limit
monthly_limit
max_pending_withdraw_count
```

### QA cần test

```text
Deposit dưới min.
Withdraw trên max.
Bet vượt max.
Nhiều pending withdraw.
Kỳ vọng: reject hoặc manual review.
```

---

## 50. Cross-currency / sai currency

**Mức độ:** HIGH nếu multi-currency
**Team chính:** Backend
**Team liên quan:** QA

### Vấn đề

User nạp/rút bằng nhiều loại tiền:

```text
VND
THB
USD
USDT
```

Nếu không kiểm soát currency, dễ cộng sai.

### Cách xử lý

Mọi transaction phải có:

```text
currency
amount
exchange_rate nếu convert
source_currency
target_currency
converted_amount
rate_timestamp
```

### QA cần test

```text
Nạp USD vào ví VND.
Rút THB từ ví VND.
Kỳ vọng: conversion rõ hoặc reject.
```

---

## 51. Rounding sai khi tính phí / bonus / jackpot

**Mức độ:** MEDIUM - HIGH
**Team chính:** Backend / Product
**Team liên quan:** QA

### Vấn đề

Phí 1.5%, bonus 12.5%, chia jackpot, chia commission.

Nếu rounding không thống nhất, ledger lệch.

### Cách xử lý

Định nghĩa:

```text
round down
round up
round half even
round half up
min fee
max fee
```

Lưu:

```text
raw_amount
calculated_fee
rounded_fee
rounding_diff
```

### QA cần test

```text
Tính phí số lẻ.
Tính bonus số lẻ.
Chia jackpot nhiều user.
Kỳ vọng: rounding đúng policy.
```

---

# 11. Nhóm HIGH/MEDIUM — Reporting / Reconciliation / Time

---

## 52. Không có reconciliation

**Mức độ:** HIGH
**Team chính:** Backend / Data / Operation
**Team liên quan:** QA

### Vấn đề

Hệ thống có thể lệch tiền âm thầm nhiều ngày.

### Cách xử lý

Đối soát định kỳ:

```text
opening_balance
+ deposits
+ wins
+ adjustments_credit
- bets
- withdrawals
- adjustments_debit
= closing_balance
```

Đối soát theo từng nguồn:

```text
real_balance
bonus_balance
locked_balance
jackpot_pool
provider balance
```

### Backend / Operation cần làm

```text
Có reconciliation job.
Có báo cáo lệch.
Có alert khi lệch.
```

### QA cần test

```text
Ledger replay có khớp wallet không.
Provider success có khớp deposit success không.
Withdraw success có khớp provider payout không.
```

---

## 53. Không có before_balance / after_balance

**Mức độ:** MEDIUM - HIGH
**Team chính:** Backend
**Team liên quan:** QA, Support

### Vấn đề

Khi user khiếu nại, rất khó giải thích balance thay đổi ra sao.

### Cách xử lý

Mỗi transaction nên ghi:

```text
before_available_balance
after_available_balance
before_locked_balance
after_locked_balance
before_bonus_balance
after_bonus_balance
```

### QA cần test

```text
Mỗi transaction có before/after balance đúng.
Replay transaction theo thời gian.
```

---

## 54. Timezone làm sai daily limit / expiry / report

**Mức độ:** MEDIUM - HIGH
**Team chính:** Backend / Data
**Team liên quan:** QA

### Vấn đề

Server dùng UTC nhưng business dùng giờ Việt Nam. Daily limit, expiry, report có thể sai ngày.

### Cách xử lý

Lưu DB bằng UTC, nhưng business day theo timezone xác định:

```text
Asia/Ho_Chi_Minh
```

Cần lưu:

```text
created_at
paid_at
settled_at
processed_at
business_date
```

### QA cần test

```text
Giao dịch lúc 23:59:59.
Giao dịch lúc 00:00:01.
Daily limit qua ngày.
Kỳ vọng: tính đúng business_date.
```

---

## 55. Pending transaction bị treo

**Mức độ:** HIGH
**Team chính:** Backend / DevOps
**Team liên quan:** Operation, QA

### Vấn đề

Transaction kẹt ở:

```text
PENDING
PROCESSING
UNKNOWN
```

Tiền bị treo hoặc trạng thái không rõ.

### Cách xử lý

Có scheduled job:

```text
scan pending
re-query provider
expire deposit
manual review withdraw unknown
alert nếu quá SLA
```

### QA cần test

```text
Deposit pending quá hạn.
Withdraw unknown quá SLA.
Worker chết giữa processing.
Kỳ vọng: scanner xử lý.
```

---

# 12. Nhóm MEDIUM/HIGH — Frontend / UX Safety

---

## 56. Frontend cho user bấm lại vì không biết request đang pending

**Mức độ:** MEDIUM - HIGH
**Team chính:** Frontend
**Team liên quan:** Backend, QA

### Vấn đề

User bấm nạp/rút/bet nhiều lần vì UI không phản hồi.

### Cách xử lý

Frontend nên:

```text
disable button theo request
hiển thị pending state
giữ idempotency key cho retry
không tạo key mới khi retry cùng action
```

Backend vẫn phải bảo vệ.

### QA cần test

```text
Double click nút bet.
Refresh page khi request pending.
Timeout rồi user bấm lại.
Kỳ vọng: không tạo transaction trùng.
```

---

## 57. Không có endpoint query transaction status

**Mức độ:** MEDIUM - HIGH
**Team chính:** Backend
**Team liên quan:** Frontend, QA

### Vấn đề

Frontend timeout, không biết giao dịch thành công hay chưa. Nếu không có endpoint kiểm tra, frontend dễ retry sai.

### Cách xử lý

Có API:

```text
GET /transactions/{idempotency_key}
GET /deposit-requests/{id}
GET /withdraw-requests/{id}
GET /game-rounds/{round_id}
```

### Frontend cần làm

```text
Sau timeout, query trạng thái thay vì tạo request mới.
```

### QA cần test

```text
Request timeout sau commit.
Frontend query status.
Kỳ vọng: trả đúng transaction cũ.
```

---

## 58. API retry response không nhất quán

**Mức độ:** MEDIUM
**Team chính:** Backend
**Team liên quan:** Frontend, QA

### Vấn đề

Cùng một giao dịch retry lúc thì trả:

```text
200 SUCCESS
400 duplicate
500 error
```

Frontend không biết xử lý.

### Cách xử lý

Idempotent response nên nhất quán:

```text
SUCCESS cũ -> 200 + transaction result
PENDING cũ -> 202 + pending status
FAILED cũ -> 4xx/200 tùy policy nhưng có transaction status rõ
payload khác -> 409
```

### QA cần test

```text
Retry success transaction.
Retry pending transaction.
Retry failed transaction.
Retry same key different payload.
```

---

# 13. Nhóm HIGH — DevOps / Infrastructure / Deployment

---

## 59. Không có backup / point-in-time recovery

**Mức độ:** HIGH
**Team chính:** DevOps / Database
**Team liên quan:** Backend, QA

### Vấn đề

Mất ledger là mất khả năng chứng minh tiền.

### Cách xử lý

Cần:

```text
backup định kỳ
point-in-time recovery
replica
test restore thật
```

### DevOps cần làm

```text
Backup tự động.
Test restore định kỳ.
PITR cho database tiền.
```

### QA cần test

```text
Restore backup trên môi trường test.
Kiểm tra ledger/wallet sau restore.
```

---

## 60. Migration dữ liệu tiền không có plan

**Mức độ:** CRITICAL
**Team chính:** Backend / DevOps / Database
**Team liên quan:** QA, Operation

### Vấn đề

Migration đổi schema balance, chuyển từ:

```text
balance
```

sang:

```text
real_balance
bonus_balance
locked_balance
```

Rủi ro:

```text
mất tiền
double balance
sai locked amount
ledger không khớp
```

### Cách xử lý

Migration cần:

```text
backup trước migration
dry run
checksum trước/sau
reconciliation sau migration
rollback plan
maintenance window
```

### QA cần test

```text
Dry run migration.
So tổng balance trước/sau.
Replay ledger sau migration.
Rollback migration.
```

---

## 61. Không có disaster mode / kill switch

**Mức độ:** HIGH
**Team chính:** Backend / DevOps / Operation
**Team liên quan:** QA

### Vấn đề

Provider lỗi, DB lag, reconciliation lệch, fraud spike. Hệ thống vẫn cho giao dịch tiền chạy bình thường.

### Cách xử lý

Cần kill switch:

```text
disable withdraw
disable deposit
disable specific provider
disable bonus payout
disable game settlement
manual review all high-risk transactions
```

### QA cần test

```text
Tắt withdraw.
Tắt deposit provider A.
Tắt bonus payout.
Kỳ vọng: hệ thống chặn đúng module, không sập toàn hệ thống.
```

---

# 14. Checklist theo team

---

## 14.1 Backend checklist

```text
1. Không tin dữ liệu tiền từ frontend.
2. Tự tính win/loss/payout/bonus/jackpot.
3. Dùng BIGINT/DECIMAL cho tiền.
4. Validate amount chặt.
5. Atomic update khi debit.
6. DB transaction cho wallet + ledger + status.
7. Idempotency key.
8. Request hash.
9. Unique business key cho game/deposit/withdraw/callback.
10. Ledger immutable.
11. Tách real/bonus/locked/withdrawable.
12. State machine cho deposit/withdraw/game round.
13. Verify callback signature.
14. Lưu raw callback.
15. Callback handler idempotent.
16. Withdraw lock available -> locked.
17. Timeout -> UNKNOWN, không auto failed.
18. Late callback -> manual review.
19. Worker claim atomic.
20. Outbox pattern nếu dùng event.
```

---

## 14.2 Frontend checklist

```text
1. Không tự tính tiền thắng/thua.
2. Không gửi balance/after_balance/win_amount làm nguồn quyết định.
3. Tạo UUID idempotency key cho action mới.
4. Retry cùng action phải dùng lại key cũ.
5. Không tạo key mới khi timeout.
6. Hiển thị pending state.
7. Disable button để giảm spam click.
8. Sau timeout, query transaction status.
9. Hiển thị available/locked/bonus/withdrawable rõ.
10. Không hiển thị upload bill là đã nạp thành công.
```

---

## 14.3 QA checklist

```text
1. Test 100 bet request cùng lúc.
2. Test 100 withdraw request cùng lúc.
3. Test 100 deposit callback trùng.
4. Test retry cùng idempotency key.
5. Test same key different payload.
6. Test provider timeout rồi late success.
7. Test callback failed sau success.
8. Test admin action cùng lúc callback.
9. Test worker chết giữa processing.
10. Test batch settlement chạy lại.
11. Test bonus cộng trùng.
12. Test rollback nhiều lần.
13. Test rollback trả đúng ví real/bonus.
14. Test amount âm/null/NaN.
15. Test frontend sửa win_amount/result.
16. Test user_id trong body bị sửa.
17. Test deposit expired rồi tiền về.
18. Test withdraw khi bonus chưa đủ turnover.
19. Test migration balance.
20. Test reconciliation ledger với wallet.
```

---

# 15. State machine khuyến nghị

---

## 15.1 Deposit states

```text
CREATED
PENDING_PAYMENT
PROCESSING
SUCCESS
FAILED
EXPIRED
CANCELLED
AMOUNT_MISMATCH
UNDERPAID
OVERPAID
UNMATCHED
LATE_PAYMENT
CHARGEBACK
REFUNDED
MANUAL_REVIEW
```

---

## 15.2 Withdraw states

```text
CREATED
PENDING_REVIEW
APPROVED
PROCESSING
SUCCESS
FAILED
REJECTED
CANCELLED
UNKNOWN
NEED_REQUERY
LATE_SUCCESS_CALLBACK
MANUAL_REVIEW
WAITING_PROVIDER_FUNDS
WAITING_BANK_WINDOW
```

---

## 15.3 Game round states

```text
CREATED
BET_PLACED
SPINNING
SETTLED
CANCELLED
ROLLBACK
FAILED
PAYOUT_HOLD
FRAUD_REVIEW
MANUAL_REVIEW
```

---

# 16. Phase triển khai ưu tiên

---

## 16.1 Phase 0 — Bắt buộc trước khi chạy tiền thật

```text
1. Backend không tin tiền/result từ frontend.
2. BIGINT/DECIMAL cho money.
3. Atomic debit.
4. DB transaction cho wallet + ledger + business status.
5. Ledger immutable.
6. Idempotency key.
7. Request hash.
8. Unique business key.
9. Verify callback signature.
10. Tách real/bonus/locked/withdrawable balance.
11. Withdraw lock tiền trước.
12. Deposit chỉ cộng sau payment verified.
13. Game result/payout tính ở backend.
14. State machine cho deposit/withdraw/game round.
15. Không admin update balance trực tiếp.
16. User_id lấy từ auth context.
17. Không dùng replica/cache làm source of truth.
18. Không fallback payout khi provider attempt UNKNOWN.
19. Backup/PITR tối thiểu.
20. Kill switch cơ bản.
```

---

## 16.2 Phase 1 — Cần có trước khi scale user

```text
1. Raw callback storage.
2. Reconciliation hằng ngày.
3. Alert balance âm / pending lâu / provider lỗi / duplicate callback.
4. Worker atomic claim.
5. Outbox pattern nếu dùng event.
6. Consumer idempotency.
7. Admin audit log.
8. Maker-checker cho adjustment/rút tiền lớn.
9. Bank account verification.
10. Bonus turnover check.
11. Jackpot pool ledger.
12. Chargeback/reversal policy.
13. Provider status mapping.
14. Manual review queue.
15. Fraud rules cơ bản.
16. Risk hold cho nguồn tiền rủi ro.
17. Deadlock retry.
18. Rate limit endpoint tiền.
19. Migration checklist.
20. Provider channel status.
```

---

## 16.3 Phase 2 — Cần có để vận hành ổn định

```text
1. Business_date / effective_at / paid_at / settled_at.
2. Reporting không ảnh hưởng production.
3. Provider settlement reconciliation.
4. Rolling limit 24h/30d.
5. Multi-account risk detection.
6. Bank sender tracking.
7. SLA cho manual review.
8. Error code taxonomy.
9. Correlation_id / trace_id.
10. Counter reconciliation.
11. Archive ledger có kiểm soát.
12. RBAC cho dữ liệu tiền.
13. Export audit log.
14. UI hiển thị available/locked/bonus/withdrawable.
15. Query transaction status API.
16. Frontend pending state.
17. Holiday / bank cutoff.
18. Rule/config versioning.
19. Test data flag.
20. Ledger integrity check nếu cần.
```

---

# 17. Top 20 lỗi nghiêm trọng nhất cần rà đầu tiên

```text
1. Backend tin dữ liệu tiền/result từ frontend.
2. Không dùng atomic update khi trừ tiền.
3. Không dùng DB transaction cho wallet + ledger.
4. Không có idempotency key.
5. Không có request_hash.
6. Không có unique business key cho game/action.
7. Không verify callback signature.
8. Callback success xử lý nhiều lần.
9. Deposit cộng tiền dựa trên frontend/proof.
10. Withdraw không lock available -> locked.
11. Provider timeout bị coi là failed và release tiền.
12. Late success callback sau khi đã release withdraw.
13. Fallback provider khi attempt trước UNKNOWN.
14. Game result/payout tính ở frontend.
15. Game settle không atomic với wallet.
16. Ledger bị sửa/xóa.
17. Chỉ lưu balance, không có ledger.
18. Admin update balance trực tiếp.
19. Dùng FLOAT/DOUBLE cho tiền.
20. Lấy user_id từ request body.
```

---

# 18. Kết luận

Thứ tự nghiêm trọng nhất cần nhớ:

```text
1. Không tin frontend về tiền.
2. Atomic update + DB transaction.
3. Idempotency + request_hash + unique business key.
4. Ledger bất biến.
5. Verify callback.
6. Tách available / locked / real / bonus.
7. State machine cho deposit / withdraw / game round.
8. Timeout không phải failed.
9. Callback trễ / callback trùng phải xử lý an toàn.
10. Reconciliation + audit + alert.
```

Câu chốt cho toàn bộ hệ thống:

> Với giao dịch tiền, đừng chỉ thiết kế để request thành công. Hãy thiết kế để khi request bị gửi lại, callback về trễ, provider timeout, user spam, worker chết, admin chỉnh tay, hoặc hệ thống lỗi giữa chừng, tiền vẫn không bị mất, không bị cộng trùng, không bị trừ sai, và luôn truy vết được bằng ledger.

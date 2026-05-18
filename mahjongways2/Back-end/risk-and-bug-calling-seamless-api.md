Dưới đây là phần **risk & bug khi gọi Seamless API**, sắp xếp theo **mức độ nghiêm trọng giảm dần**. Mình phân tích theo flow mới:

```text
JOIN → BALANCE
PLAY → BET/DEBIT
DEBIT SUCCESS → random/game logic
SETTLEMENT → WIN/CREDIT hoặc SETTLE
COMMIT → save history / pot / fund / jackpot
RESULT → trả balance cuối cho frontend
```

Tài liệu cũ yêu cầu flow slot phải có: tính cược, chia fee/pot/fund, random theo weight, tính ways/cascade/multiplier/free spin, check jackpot, safety check fund, trả thưởng và ghi transaction/history. Khi chuyển sang Seamless API, các bước trừ/cộng balance phải đi qua API ngoài, nhưng các rule về pot/fund/safety vẫn phải giữ. 

---

# P0 — Rủi ro thảm họa, có thể mất tiền thật

## 1. Double debit — trừ tiền cược 2 lần

### Bug

Frontend gửi `PLAY` một lần, nhưng do timeout/retry/network lag, backend gọi `BET/DEBIT` nhiều lần với **idempotencyKey khác nhau**.

```text
PLAY
↓
DEBIT key A thành công
↓
timeout
↓
retry DEBIT key B
↓
trừ thêm lần nữa
```

### Hậu quả

User bị trừ tiền 2 lần cho 1 spin.

### Cách chặn

Mỗi spin phải có:

```text
spinId
roundId
debitIdempotencyKey
```

Một `spinId` chỉ được có **một debit key cố định**. Retry phải dùng lại key cũ.

### Rule bắt buộc

```text
Không generate key mới khi retry DEBIT.
Không cho tạo spin mới nếu request cũ đang DEBIT_PENDING / DEBIT_SUCCESS.
```

---

## 2. Double credit — cộng thưởng 2 lần

### Bug

`WIN/CREDIT` thành công ở Seamless, nhưng backend không nhận được response vì timeout. Backend retry bằng key mới.

```text
CREDIT key A thực tế đã thành công
↓
backend timeout
↓
retry CREDIT key B
↓
user được cộng thưởng lần 2
```

### Hậu quả

Mất tiền thật, đặc biệt nguy hiểm với jackpot/big win.

### Cách chặn

Retry `WIN/CREDIT` phải dùng cùng:

```text
creditIdempotencyKey
spinId
roundId
amount
```

Backend phải lưu trạng thái:

```text
CREDIT_PENDING
CREDIT_SUCCESS
```

Nếu đã `CREDIT_SUCCESS`, tuyệt đối không gọi lại credit.

---

## 3. Random result trước khi DEBIT success

### Bug

Backend random board và tính win trước khi Seamless xác nhận trừ tiền thành công.

```text
PLAY
↓
random result
↓
tính totalWin
↓
DEBIT failed
```

### Hậu quả

Có thể lộ outcome, exploit retry, hoặc tạo result thắng nhưng user chưa bị trừ cược.

### Cách chặn

Flow đúng:

```text
PLAY
↓
BET/DEBIT success
↓
mới random reels
↓
mới tính ways/cascade/win
```

Nếu `DEBIT_FAILED`:

```text
không random
không update pot/fund
không tạo spin result
```

---

## 4. CREDIT failed nhưng vẫn trả result “thắng thành công”

### Bug

Backend tính được `totalWin > 0`, gọi `WIN/CREDIT` bị lỗi, nhưng vẫn trả frontend:

```json
{
  "totalWin": 5000000,
  "balance": "đã cộng"
}
```

trong khi Seamless chưa cộng tiền.

### Hậu quả

Frontend hiển thị user đã thắng, nhưng ví thật chưa có tiền. Khiếu nại rất khó xử lý.

### Cách chặn

Nếu `CREDIT_FAILED`:

```text
không được coi spin là COMPLETED
status = CREDIT_PENDING
retry WIN/CREDIT cùng idempotencyKey
```

Response nếu buộc trả sớm phải có:

```json
{
  "payoutStatus": "PENDING"
}
```

Tốt nhất: chỉ trả `RESULT` hoàn tất khi credit thành công, hoặc có cơ chế pending rõ ràng.

---

## 5. Reset jackpot trước khi CREDIT thành công

### Bug

Jackpot nổ, backend reset `pot = initPotValue` trước khi Seamless `WIN/CREDIT` thành công.

```text
jackpotPrize = pot
↓
reset pot
↓
CREDIT failed
```

### Hậu quả

User chưa nhận tiền, nhưng hũ đã reset. Sai ledger, sai jackpot state, có thể mất khả năng truy vết.

### Cách chặn

Chỉ commit:

```text
pot reset
jackpot_history
fund deduction
```

sau khi:

```text
CREDIT_SUCCESS
```

Tài liệu jackpot yêu cầu jackpotPrize có thể bằng `pot` hoặc `2 × pot`, sau nổ thì pot reset về `initPotValue`, nhưng reset này phải nằm sau bước settlement thành công khi dùng Seamless. 

---

## 6. Không rollback khi DEBIT success nhưng game internal error

### Bug

DEBIT đã thành công, sau đó game lỗi khi random/cascade/save result.

```text
DEBIT success
↓
game exception
↓
return ERROR
↓
không rollback
```

### Hậu quả

User bị trừ tiền nhưng không có spin result.

### Cách chặn

Nếu lỗi xảy ra **sau debit nhưng trước result final**, phải:

```text
call ROLLBACK / CANCEL_BET
```

Nếu rollback thất bại:

```text
status = ROLLBACK_PENDING
retry background job
không cho spinId này chạy lại như spin mới
```

---

# P1 — Rủi ro nghiêm trọng, dễ lệch ví/quỹ/lịch sử

## 7. Dùng balance lúc JOIN để quyết định cho quay

### Bug

User join game lúc có 1,000,000, sau đó số dư thay đổi ở hệ thống khác. Backend vẫn dùng balance cũ để cho quay.

### Hậu quả

Cho phép quay khi ví thật không đủ tiền, hoặc báo sai lỗi.

### Cách chặn

`BALANCE` lúc `SUBSCRIBE` chỉ để hiển thị. Khi `PLAY`, quyết định cuối phải là `BET/DEBIT`.

```text
BALANCE = display
DEBIT = xác nhận tiền thật
```

---

## 8. Response balance lấy từ local cache thay vì Seamless

### Bug

Backend tự tính:

```text
balance = oldBalance - bet + win
```

rồi trả frontend.

### Hậu quả

Số dư frontend lệch với ví thật operator.

### Cách chặn

Balance trong `RESULT` phải lấy từ:

```text
DEBIT response nếu totalWin = 0
CREDIT response nếu totalWin > 0
SETTLE response nếu provider yêu cầu settle
```

Không dùng local wallet balance làm source of truth.

---

## 9. Commit pot/fund ngay sau DEBIT success, nhưng CREDIT/SETTLE fail

### Bug

Sau DEBIT success, backend cộng pot/fund và commit ngay. Sau đó result hoặc credit fail.

### Hậu quả

Pot/fund đã tăng nhưng spin chưa hoàn tất. Có thể lệch economy.

### Cách chặn

Tách ledger thành 2 bước:

```text
PENDING economy ledger sau DEBIT_SUCCESS
COMMITTED economy ledger sau settlement success
```

Hoặc có compensating transaction nếu settlement fail.

Tài liệu cũ yêu cầu sau mỗi lượt cược phải chia fee/pot/fund và cập nhật pot/fund, nhưng với Seamless flow nên commit sau khi round settlement chắc chắn để tránh lệch trạng thái. 

---

## 10. Safety check fund sai hoặc bỏ qua

### Bug

Backend tính `totalWin`, gọi CREDIT luôn, không check:

```text
fund - fundCost >= 0
```

### Hậu quả

Game trả vượt quỹ, jackpot/cascade/free spin làm âm fund.

### Cách chặn

Trước `WIN/CREDIT`, phải tính:

```text
totalPrizes = regularPrize + jackpotPrize
fundCost = totalPrizes - soTienNoHuKhongTruQuy
fund - fundCost >= 0
```

Tài liệu jackpot nhấn mạnh phần jackpot lấy từ pot không trừ trực tiếp vào fund qua `soTienNoHuKhongTruQuy`, và bắt buộc safety check trước khi trả thưởng. 

---

## 11. Race condition khi user bấm PLAY liên tục

### Bug

User gửi nhiều `PLAY` gần như đồng thời. Backend xử lý song song:

```text
PLAY A debit success
PLAY B debit success
PLAY C debit success
```

trong khi game state/free spin/pot/fund chưa khóa.

### Hậu quả

Trừ tiền nhiều lần, sai thứ tự spin, sai free spin remaining, sai pot/fund.

### Cách chặn

Cần lock theo:

```text
userId + gameCode
```

hoặc:

```text
userId + roomId
```

Một user chỉ được có một spin active:

```text
CREATED / DEBIT_PENDING / DEBIT_SUCCESS / CREDIT_PENDING
```

---

## 12. Replay attack với cùng request

### Bug

Client hoặc attacker gửi lại request cũ:

```text
same spinId / same payload / same timestamp
```

Backend tạo spin mới.

### Hậu quả

Có thể exploit kết quả, double debit hoặc double credit.

### Cách chặn

Backend tự tạo `spinId`, `roundId`, idempotency key. Không tin `spinId` từ frontend. Mỗi request phải có nonce/session validation, và backend lưu trạng thái idempotency.

---

## 13. Timeout không rõ trạng thái từ Seamless

### Bug

Backend gọi DEBIT/CREDIT, bị timeout. Không biết API đã xử lý hay chưa.

### Hậu quả

Nếu retry sai key: double debit/credit. Nếu bỏ qua: mất tiền hoặc treo spin.

### Cách chặn

Timeout phải chuyển trạng thái:

```text
DEBIT_UNKNOWN
CREDIT_UNKNOWN
```

Sau đó gọi query transaction/status nếu Seamless hỗ trợ, hoặc retry cùng idempotencyKey.

---

# P2 — Rủi ro gameplay/economy sai nhưng chưa chắc mất tiền ngay

## 14. Free Spin vẫn gọi DEBIT

### Bug

User đang `mode = FREE_SPIN`, nhưng backend vẫn gọi `BET/DEBIT`.

### Hậu quả

Free spin không còn miễn phí, user bị trừ tiền sai.

### Cách chặn

Flow Free Spin:

```text
validate remainingFreeSpin > 0
không gọi DEBIT
dùng bet state của lượt trigger
nếu totalWin > 0 thì gọi CREDIT
```

Tài liệu Mahjong2 ghi Free Spin không deduct bet và vẫn dùng bet của lượt trigger/state hiện tại để tính payout. 

---

## 15. Không lưu bet state của lượt trigger Free Spin

### Bug

Free spin cần dùng lại betSize/betLevel/baseBet của lượt trigger, nhưng backend không lưu.

### Hậu quả

Free spin payout sai, có thể dùng nhầm bet mới hoặc room mới.

### Cách chặn

Khi trigger free spin, lưu:

```text
triggerSpinId
betSize
betLevel
baseBet
lineBet
totalBet
roomId
remainingFreeSpin
```

Không cho đổi room làm ảnh hưởng free spin đang có.

---

## 16. Retrigger Free Spin cộng sai remaining

### Bug

Đang Free Spin còn 5 lượt, ra 3 Scatter. Backend set remaining = 10 thay vì cộng thêm.

### Hậu quả

User mất lượt free spin hoặc được cộng sai.

### Cách chặn

Rule:

```text
remaining = currentRemaining - 1 + awarded
```

với `awarded = 10 + (scatterCount - 3) × 2`.

---

## 17. Golden Transform xử lý sai thứ tự với cascade

### Bug

Golden thắng vừa bị remove vừa transform, hoặc transform xong lại bị xóa khỏi board.

### Hậu quả

Frontend animation sai, payout cascade sau sai.

### Cách chặn

Phải tách:

```text
removedPositions
goldenTransforms
reelsBefore
reelsAfterDrop
```

và định nghĩa rõ Golden thắng được xử lý thế nào trong step tiếp theo. Tài liệu Mahjong2 yêu cầu Golden symbol tham gia winning ways sẽ chuyển thành WILD ở cascade tiếp theo. 

---

## 18. Payout formula lẫn giữa totalBet và lineBet

### Bug

Backend lúc thì dùng:

```text
totalBet × payRate
```

lúc thì dùng:

```text
payTableValue × lineBet
```

### Hậu quả

Payout lệch toàn bộ RTP, có thể trả quá nhiều hoặc quá ít.

### Cách chặn

Cần chốt một mode trong config:

```text
TOTAL_BET_X_PAY_RATE
PAYTABLE_VALUE_X_LINE_BET
```

Không được mix trong cùng game.

Tài liệu full-flow chỉ nêu công thức tổng quát `Win = Bet × Paytable × Ways × Multiplier`, nên paytable thật phải quyết định “Bet” ở đây là `totalBet` hay `lineBet`. 

---

## 19. Ways/cascade tính sai nhưng vẫn credit tiền

### Bug

Engine tính sai ways, multiplier hoặc cascade nhưng đã gọi CREDIT.

### Hậu quả

Sai payout tiền thật.

### Cách chặn

Trước khi gọi CREDIT cần validate result:

```text
totalWin = sum(cascadeSteps.stepWin) + jackpotPrize
ways không vượt 2000
multiplier đúng theo step
scatter/freeSpin đúng rule
```

---

## 20. Không giới hạn max exposure

### Bug

Cascade/free spin/jackpot cộng dồn tạo payout cực lớn, vượt giới hạn business.

### Hậu quả

Một spin có thể gây payout khổng lồ.

### Cách chặn

Cần config:

```text
maxPayoutPerSpin
maxMultiplierExposure
maxJackpotPayout
```

Tài liệu full-flow cũng nhắc exposure control để giới hạn payout tối đa và giữ hệ thống không bankrupt. 

---

# P3 — Rủi ro vận hành, debug, audit

## 21. Không lưu mapping transaction Seamless

### Bug

Spin history không lưu:

```text
debitTransactionId
creditTransactionId
idempotencyKey
roundId
providerResponseCode
```

### Hậu quả

Không đối soát được với operator.

### Cách chặn

Spin history phải lưu đầy đủ:

```text
spinId
roundId
debitId
creditId
debitKey
creditKey
balanceBefore nếu có
balanceAfterBet
finalBalance
payoutStatus
```

---

## 22. Trả RESULT trước khi save history

### Bug

Backend trả result cho frontend rồi mới save DB. Save thất bại.

### Hậu quả

User thấy kết quả nhưng backend không có lịch sử để audit.

### Cách chặn

Thứ tự an toàn:

```text
settlement success
↓
save spin history
↓
return RESULT
```

Nếu save history fail sau credit success, phải có recovery job ghi lại từ transaction mapping.

---

## 23. Không có trạng thái PENDING rõ ràng

### Bug

Chỉ có `SUCCESS/FAILED`, không có:

```text
DEBIT_PENDING
CREDIT_PENDING
ROLLBACK_PENDING
UNKNOWN
```

### Hậu quả

Gặp timeout là không biết retry hay dừng.

### Cách chặn

Dùng state machine rõ:

```text
CREATED
DEBIT_PENDING
DEBIT_SUCCESS
DEBIT_FAILED
RESULT_GENERATED
CREDIT_PENDING
CREDIT_SUCCESS
CREDIT_FAILED
ROLLBACK_PENDING
ROLLBACK_SUCCESS
COMPLETED
```

---

## 24. Update balance frontend sai thời điểm

### Bug

Frontend tự trừ tiền ngay khi bấm quay, rồi backend trả balance khác.

### Hậu quả

UI nhảy số dư liên tục, gây khiếu nại.

### Cách chặn

Frontend chỉ được update số dư bằng:

```text
INFO.balance
RESULT.balance
ERROR.balance nếu có
```

Không tự cộng/trừ balance theo dự đoán.

---

## 25. Log thiếu raw request/response Seamless

### Bug

Không lưu payload đã gửi/nhận từ Seamless.

### Hậu quả

Không debug được khi provider báo khác.

### Cách chặn

Log tối thiểu:

```text
endpoint
requestId
idempotencyKey
amount
currency
providerTxnId
status
latency
errorCode
```

Ẩn token/signature để không lộ bảo mật.

---

# Bảng tổng hợp mức độ nghiêm trọng

| Mức | Nhóm bug                                                                                       | Hậu quả                                         |
| --- | ---------------------------------------------------------------------------------------------- | ----------------------------------------------- |
| P0  | Double debit, double credit, random trước debit, credit fail vẫn trả result, reset jackpot sớm | Mất tiền thật / sai ví operator                 |
| P1  | Balance cache, commit pot/fund sớm, thiếu safety check, race condition, timeout unknown        | Lệch quỹ, lệch trạng thái, lỗi khó đối soát     |
| P2  | Free spin debit sai, bet state sai, golden/cascade/payout sai, exposure không giới hạn         | Sai gameplay/RTP/payout                         |
| P3  | Thiếu log, thiếu pending state, trả result trước save, frontend update balance sai             | Khó vận hành, khó audit, dễ phát sinh khiếu nại |

---

# Checklist bắt buộc trước khi code

```text
1. Có idempotencyKey riêng cho DEBIT và CREDIT.
2. Retry DEBIT/CREDIT luôn dùng lại key cũ.
3. DEBIT success mới được random.
4. DEBIT fail thì không random, không update pot/fund.
5. CREDIT success mới trả result hoàn tất.
6. CREDIT pending thì không random lại.
7. Jackpot reset chỉ sau CREDIT success.
8. Balance trong RESULT lấy từ Seamless.
9. Free Spin không gọi DEBIT.
10. Pot/fund/jackpot ledger có trạng thái PENDING/COMMITTED.
11. Safety check fund trước CREDIT.
12. Một user chỉ có một spin active.
13. Lưu đủ debitId/creditId/roundId/spinId/provider response.
```

Câu chốt cho dev backend:

```text
Seamless API là source of truth của balance.
Game backend là source of truth của game result.
Hai hệ này phải nối với nhau bằng idempotency, state machine và transaction mapping.
```

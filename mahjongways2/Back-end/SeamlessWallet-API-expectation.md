Dưới đây là **SeamlessWallet API expectation** theo flow đã chốt. Trong phạm vi game backend, chỉ có **1 endpoint chính**:

```http
POST /game/wallet
Content-Type: application/json
```

Request luôn có:

```json
{
  "session_token": "SESSION_TOKEN",
  "action": "ACTION_NAME"
}
```

Game Backend chỉ gọi `/game/wallet`; `GameWalletServlet` sẽ kiểm tra session, idempotency, gọi Partner Wallet Callback, lưu transaction và trả balance về Game Backend. 

---

# 1. Danh sách API/action cần dùng

| API / Action                  | Ai gọi       | Khi nào gọi                                      | Mục đích                                             |
| ----------------------------- | ------------ | ------------------------------------------------ | ---------------------------------------------------- |
| `/game/wallet` + `getBalance` | Game Backend | Join game / Subscribe                            | Lấy balance để hiển thị                              |
| `/game/wallet` + `bet`        | Game Backend | Trước RNG                                        | Trừ tiền cược                                        |
| `/game/wallet` + `settle`     | Game Backend | Sau RNG                                          | Kết toán thắng/thua, luôn gọi kể cả `win_amount = 0` |
| `/game/wallet` + `cancelBet`  | Game Backend | Bet thành công nhưng game lỗi trước result final | Hủy bet / hoàn tiền cược                             |
| `/game/wallet` + `jackpotWin` | Game Backend | Sau `settle` nếu có jackpot                      | Trả jackpot riêng                                    |

Không dùng các action cũ/generic sau:

```text
BALANCE
DEBIT
CREDIT
WIN
ROLLBACK
```

Tên đúng theo SeamlessWallet là:

```text
getBalance
bet
settle
cancelBet
jackpotWin
```

Các action này được chốt trong tài liệu backend SeamlessWallet. 

---

# 2. `getBalance`

## Mục đích

Lấy số dư khi user join game / subscribe.

## Request

```json
{
  "session_token": "SESSION_TOKEN",
  "action": "getBalance"
}
```

## Response success

```json
{
  "code": 0,
  "balance": 1000000,
  "currency": "VND"
}
```

## Rule

```text
Balance ở JOIN chỉ để hiển thị.
Không dùng balance này để quyết định user có được spin hay không.
Khi PLAY vẫn phải gọi bet.
```

Flow join game hiện tại là `SUBSCRIBE_MAHJONG2 → /game/wallet getBalance → INFO_MAHJONG2(balance)`. 

---

# 3. `bet`

## Mục đích

Trừ tiền cược trước khi RNG.

## Khi gọi

```text
PLAY_MAHJONG2
↓
validate request
↓
calculate lineBet / totalBet
↓
create spinId / roundId / transaction ids
↓
call /game/wallet action=bet
```

## Request

```json
{
  "session_token": "SESSION_TOKEN",
  "action": "bet",
  "transaction_id": "BET_MW2_SPIN_10001",
  "round_id": "RND_MW2_SPIN_10001",
  "amount": 450
}
```

## Response success

```json
{
  "code": 0,
  "balance": 999550,
  "transaction_id": "BET_MW2_SPIN_10001"
}
```

## Response fail ví dụ

```json
{
  "code": 1005,
  "message": "Insufficient balance"
}
```

## Rule

```text
bet code = 0 mới được RNG.
bet fail thì dừng flow.
bet fail thì không random, không update pot/fund, không tạo result thắng thua, không gọi settle.
```

Tài liệu flow mới chốt rõ: `bet` thành công mới RNG; nếu `bet` fail thì stop và return error. 

---

# 4. `settle`

## Mục đích

Kết toán round sau khi RNG xong.

## Khi gọi

Sau khi game logic tính xong:

```text
regularWin
jackpotPrize nếu có
safety check
```

Backend **luôn gọi `settle`**, kể cả khi thua.

## Request thắng thường

```json
{
  "session_token": "SESSION_TOKEN",
  "action": "settle",
  "transaction_id": "WIN_MW2_SPIN_10001",
  "bet_transaction_id": "BET_MW2_SPIN_10001",
  "round_id": "RND_MW2_SPIN_10001",
  "win_amount": 1800,
  "is_jackpot": false
}
```

## Request thua

```json
{
  "session_token": "SESSION_TOKEN",
  "action": "settle",
  "transaction_id": "WIN_MW2_SPIN_10001",
  "bet_transaction_id": "BET_MW2_SPIN_10001",
  "round_id": "RND_MW2_SPIN_10001",
  "win_amount": 0,
  "is_jackpot": false
}
```

## Response success

```json
{
  "code": 0,
  "balance": 1001350,
  "transaction_id": "WIN_MW2_SPIN_10001"
}
```

## Rule

```text
Sau RNG luôn gọi settle.
win_amount = 0 nếu thua.
Không dùng CREDIT/WIN.
Không bỏ qua settle.
Nếu settle fail/timeout: SETTLE_PENDING.
Retry settle bằng cùng transaction_id.
Không random lại.
Không tạo spin mới.
Không gọi cancelBet sau khi result đã generated.
```

Backend spec ghi `settle` là bắt buộc sau RNG và `win_amount = 0` nếu thua. 

---

# 5. `jackpotWin`

## Mục đích

Trả jackpot riêng sau `settle`.

## Khi gọi

Chỉ gọi nếu:

```text
settle success
jackpotPrize > 0
```

## Request

```json
{
  "session_token": "SESSION_TOKEN",
  "action": "jackpotWin",
  "transaction_id": "JP_MW2_SPIN_10001",
  "round_id": "RND_MW2_SPIN_10001",
  "jackpot_id": "MW2_JACKPOT_ROOM_1",
  "win_amount": 12000000,
  "jackpot_contribution": 450
}
```

## Response success

```json
{
  "code": 0,
  "balance": 13000000,
  "transaction_id": "JP_MW2_SPIN_10001"
}
```

## Rule

```text
jackpotWin chỉ gọi sau settle success.
Không gộp jackpotPrize vào settle rồi lại gọi jackpotWin.
Nếu jackpotWin fail/timeout: JACKPOT_PENDING.
Retry jackpotWin bằng cùng transaction_id.
Không reset pot trước jackpotWin success.
```

Flow jackpot chuẩn là `bet → RNG → settle regularWin → jackpotWin jackpotPrize → commit result`; không gộp jackpot vào settle để tránh double credit. 

---

# 6. `cancelBet`

## Mục đích

Hủy bet nếu `bet` đã thành công nhưng game lỗi **trước khi có result final / trước settle**.

## Request

```json
{
  "session_token": "SESSION_TOKEN",
  "action": "cancelBet",
  "transaction_id": "CANCEL_MW2_SPIN_10001",
  "bet_transaction_id": "BET_MW2_SPIN_10001",
  "round_id": "RND_MW2_SPIN_10001",
  "amount": 450
}
```

## Response success

```json
{
  "code": 0,
  "balance": 1000000,
  "transaction_id": "CANCEL_MW2_SPIN_10001"
}
```

## Rule

```text
Chỉ dùng cancelBet khi:
bet success
game lỗi trước result final / trước settle

Không dùng cancelBet khi:
RNG đã xong
result đã generated
settle đang pending
```

Nếu result đã generated mà settle fail, phải retry `settle`, không cancel. 

---

# 7. Transaction ID / Idempotency expectation

`transaction_id` là idempotency key.

Mỗi action phải có transaction riêng:

```text
BET_MW2_{spinId}
WIN_MW2_{spinId}
CANCEL_MW2_{spinId}
JP_MW2_{spinId}
```

Ví dụ:

```text
BET_MW2_SPIN_10001
WIN_MW2_SPIN_10001
CANCEL_MW2_SPIN_10001
JP_MW2_SPIN_10001
```

Rule:

```text
Retry bet dùng lại BET transaction_id.
Retry settle dùng lại WIN transaction_id.
Retry cancelBet dùng lại CANCEL transaction_id.
Retry jackpotWin dùng lại JP transaction_id.
Không tạo transaction_id mới khi retry.
```

Tài liệu flow mới chốt retry theo `transaction_id`, không dùng id mới. 

---

# 8. Full flow API expectation

```text
JOIN
↓
/game/wallet getBalance
↓
INFO_MAHJONG2


BASE PLAY
↓
/game/wallet bet
↓
if bet fail:
    return ERROR
↓
if bet success:
    RNG / game logic
    calculate regularWin / jackpotPrize
    safety check
↓
/game/wallet settle
↓
if settle fail:
    SETTLE_PENDING
    retry same transaction_id
↓
if jackpotPrize > 0:
    /game/wallet jackpotWin
↓
if jackpotWin fail:
    JACKPOT_PENDING
    retry same transaction_id
↓
if all success:
    commit result
    return RESULT_MAHJONG2


ERROR AFTER BET BEFORE RESULT
↓
/game/wallet cancelBet
```

---

# 9. Free Spin expectation

```text
Free Spin không gọi bet mới.
```

Nhưng SeamlessWallet doc hiện chưa có strategy riêng cho Free Spin settlement, nên:

```text
Free Spin settlement strategy = TBD.
Không hardcode dùng lại bet_transaction_id của trigger spin cho nhiều free spin nếu chưa test.
Không tạo zero-bet nếu /game/wallet action=bet không xác nhận amount = 0.
```

Điểm này đang được ghi rõ trong backend spec. 

---

# 10. Chốt ngắn

| Action       |          Bắt buộc? | Ghi chú                  |
| ------------ | -----------------: | ------------------------ |
| `getBalance` |                 Có | Join/subscribe           |
| `bet`        |                 Có | Base spin trước RNG      |
| `settle`     |                 Có | Sau RNG, kể cả thua      |
| `cancelBet`  |                 Có | Lỗi sau bet trước result |
| `jackpotWin` | Có nếu bật jackpot | Sau settle success       |

Câu chốt:

```text
Game Backend không xử lý tiền trực tiếp.
Game Backend chỉ gọi /game/wallet.
Balance thật lấy từ response của SeamlessWallet.
Không dùng DEBIT/CREDIT/WIN/ROLLBACK.
```

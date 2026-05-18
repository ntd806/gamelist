Dưới đây là **flow đúng chuẩn theo SeamlessWallet** để thay thế cho `new-flow.md`. Bản này đã sửa các điểm sai: **không dùng CREDIT/WIN**, **settle không optional**, **jackpot dùng `jackpotWin` sau `settle`**, và **retry dựa trên `transaction_id`**.

````md
# Mahjong Ways 2 — Backend Flow Chuẩn Theo SeamlessWallet

## 1. Nguyên tắc chính

Game backend không gọi Partner Callback trực tiếp.

Game backend chỉ gọi:

```http
POST /game/wallet
Content-Type: application/json
````

Các action dùng trong game:

| Action       | Mục đích                                                            |
| ------------ | ------------------------------------------------------------------- |
| `getBalance` | Lấy số dư khi join game / subscribe                                 |
| `bet`        | Trừ tiền cược trước khi RNG                                         |
| `settle`     | Kết toán sau RNG, luôn gọi kể cả `win_amount = 0`                   |
| `cancelBet`  | Hủy bet nếu bet thành công nhưng game lỗi trước khi có result final |
| `jackpotWin` | Trả jackpot riêng sau `settle` nếu có jackpot                       |

Không dùng các action sau trong flow này:

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

---

## 2. Flow tổng quan

```text
JOIN GAME
↓
/game/wallet getBalance
↓
INFO_MAHJONG2

BASE PLAY
↓
/game/wallet bet
↓
bet success mới RNG
↓
game logic
↓
/game/wallet settle
↓
nếu có jackpot: /game/wallet jackpotWin
↓
commit result
↓
RESULT_MAHJONG2
```

---

## 3. Join Game / Subscribe Flow

```text
┌──────────────────────────────────────────────┐
│ A. JOIN GAME / SUBSCRIBE                     │
└──────────────────────────────────────────────┘

Client
  │
  │ SUBSCRIBE_MAHJONG2
  │ session_token
  ▼
Game Backend
  │
  │ POST /game/wallet
  │ action = getBalance
  ▼
SeamlessWallet
  │
  │ Kiểm tra session_token
  │ Gọi Partner Wallet Callback
  │ Trả balance
  ▼
Game Backend
  │
  │ Return INFO_MAHJONG2
  │ balance = response.balance
  ▼
Frontend hiển thị số dư
```

Request:

```json
{
  "session_token": "SESSION_TOKEN",
  "action": "getBalance"
}
```

Response success:

```json
{
  "code": 0,
  "balance": 1000000,
  "currency": "VND"
}
```

Ghi chú:

```text
Balance ở JOIN chỉ dùng để hiển thị.
Không dùng balance này để quyết định user có được spin hay không.
PLAY phải đi qua action=bet.
```

---

## 4. Base Spin Flow

```text
┌──────────────────────────────────────────────┐
│ B. BASE SPIN                                 │
└──────────────────────────────────────────────┘

Client
  │
  │ PLAY_MAHJONG2
  │ session_token
  │ roomId
  │ betSize
  │ betLevel
  │ baseBet
  ▼
Game Backend
  │
  │ Validate request
  │ - session_token
  │ - room
  │ - betSize
  │ - betLevel
  │ - baseBet
  │ - user không có spin active khác
  ▼
Game Backend
  │
  │ Calculate:
  │ lineBet  = betSize × betLevel
  │ totalBet = lineBet × baseBet
  ▼
Game Backend
  │
  │ Create IDs:
  │ spinId
  │ roundId
  │ betTransactionId
  │ settleTransactionId
  │ cancelTransactionId
  │ jackpotTransactionId nếu cần
  ▼
Game Backend
  │
  │ POST /game/wallet
  │ action = bet
  │ amount = totalBet
  ▼
SeamlessWallet
  │
  ├── bet failed
  │     │
  │     ▼
  │  Game Backend
  │     │
  │     │ Không RNG
  │     │ Không update pot/fund
  │     │ Không tạo result thắng thua
  │     │ Không gọi settle
  │     ▼
  │  Return ERROR
  │
  └── bet success
        │
        │ response.balance = balanceAfterBet
        ▼
     Game Backend
        │
        │ Lúc này mới được RNG / game logic
        ▼
```

Request `bet`:

```json
{
  "session_token": "SESSION_TOKEN",
  "action": "bet",
  "transaction_id": "BET_MW2_SPIN_10001",
  "round_id": "RND_MW2_SPIN_10001",
  "amount": 450
}
```

Response success:

```json
{
  "code": 0,
  "balance": 999550,
  "transaction_id": "BET_MW2_SPIN_10001"
}
```

Nếu fail:

```json
{
  "code": 1005,
  "message": "Insufficient balance"
}
```

Rule bắt buộc:

```text
bet code = 0 mới được random.
bet fail thì dừng flow.
```

---

## 5. Game Logic Sau Bet Success

Mahjong Ways 2 dùng layout `4-5-5-5-4`, tổng `2000 ways`, không dùng matrix `4x5` đều. Backend phải dùng dạng `List<List<Mahjong2Cell>> reels`. 

```text
┌──────────────────────────────────────────────┐
│ C. GAME LOGIC                                │
└──────────────────────────────────────────────┘

Game Backend
  │
  │ Generate reels layout 4-5-5-5-4
  │ Random symbol by weight
  │ Apply Golden rule
  ▼
Ways Engine
  │
  │ Calculate 2000 ways
  │ Win từ trái sang phải
  │ Tối thiểu 3 reels liên tiếp
  │ WILD thay symbol thường
  │ WILD không thay SCATTER
  ▼
Cascade Engine
  │
  │ Calculate wins
  │ Collect removedPositions
  │ Collect goldenTransforms
  │ Remove symbols
  │ Drop symbols
  │ Fill new symbols
  │ Recalculate until no win
  ▼
Multiplier Engine
  │
  │ BASE:
  │ step 1 = x1
  │ step 2 = x2
  │ step 3 = x3
  │ step 4+ = x5
  │
  │ FREE_SPIN:
  │ step 1 = x2
  │ step 2 = x4
  │ step 3 = x6
  │ step 4+ = x10
  ▼
FreeSpin Engine
  │
  │ 3 SCATTER = 10 free spins
  │ mỗi SCATTER thêm = +2
  ▼
Jackpot Engine nếu bật
  │
  │ Tính jackpotPrize nếu có
  ▼
Calculate:
  regularWin
  jackpotPrize
```

Tài liệu flow slot cũng xác nhận các phần trọng yếu: random theo weight, Ways System, payout theo `Bet × Paytable × Ways × Multiplier`, cascade `Win → Remove Symbols → Drop New Symbols → Recalculate Win`, multiplier tăng theo cascade. 

---

## 6. Economy Ledger Sau Bet Success

Sau `bet success`, backend có thể tạo economy ledger ở trạng thái `PENDING`.

```text
fee = totalBet × 2%
moneyToPot = totalBet × 1%
moneyToFund = totalBet × 97%
```

Không commit final ngay.

```text
bet success
↓
create pending economy ledger
↓
RNG / game logic
↓
settle success
↓
commit pot/fund ledger
```

Lý do: nếu settle fail mà pot/fund đã commit final thì ledger sẽ lệch. `new-flow.md` cũng đã nêu rõ không nên commit pot/fund/jackpot quá sớm, chỉ nên commit sau settlement thành công. 

---

## 7. Safety Check Trước Settle

```text
regularWin = sum(cascadeSteps.stepWin)
jackpotPrize = jackpot amount nếu có

totalPrizes = regularWin + jackpotPrize
soTienNoHuKhongTruQuy = jackpotPrize nếu jackpot lấy từ pot
fundCost = totalPrizes - soTienNoHuKhongTruQuy

Require:
fund - fundCost >= 0
```

Nếu không đủ fund:

```text
deny jackpot
fallback safe result
recalculate regularWin / jackpotPrize nếu cần
```

---

## 8. Settle Flow — Bắt Buộc Sau RNG

Theo flow SeamlessWallet mới: **sau RNG luôn gọi `settle`**, kể cả khi người chơi thua.

```text
┌──────────────────────────────────────────────┐
│ D. SETTLE THƯỜNG                             │
└──────────────────────────────────────────────┘

Game Backend
  │
  │ POST /game/wallet
  │ action = settle
  │ win_amount = regularWin
  │ Nếu thua: win_amount = 0
  ▼
SeamlessWallet
  │
  ├── settle failed / timeout
  │     │
  │     ▼
  │  Game Backend
  │     │
  │     │ status = SETTLE_PENDING
  │     │ retry settle cùng transaction_id
  │     │ không random lại
  │     │ không tạo spin mới
  │     ▼
  │  Return pending/error response
  │
  └── settle success
        │
        │ response.balance = balanceAfterSettle
        ▼
     Game Backend
        │
        │ Nếu không có jackpot:
        │ finalBalance = balanceAfterSettle
        │
        │ Nếu có jackpot:
        │ gọi jackpotWin sau settle
        ▼
```

Request settle có thắng:

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

Request settle khi thua:

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

Rule bắt buộc:

```text
Không dùng CREDIT/WIN.
Không bỏ qua settle khi win_amount = 0.
Không retry bằng transaction_id mới.
Không random lại khi settle pending.
```

---

## 9. Jackpot Flow Theo SeamlessWallet

Nếu có jackpot, flow chuẩn là:

```text
bet
↓
RNG / game logic
↓
settle regularWin
↓
jackpotWin jackpotPrize
↓
commit result
```

Không gộp jackpot vào settle nếu đang bám đúng SeamlessWallet flow.

```text
┌──────────────────────────────────────────────┐
│ E. JACKPOT WIN NẾU CÓ                        │
└──────────────────────────────────────────────┘

Game Backend
  │
  │ Chỉ gọi sau settle success
  │
  │ POST /game/wallet
  │ action = jackpotWin
  │ win_amount = jackpotPrize
  ▼
SeamlessWallet
  │
  ├── jackpotWin failed / timeout
  │     │
  │     ▼
  │  Game Backend
  │     │
  │     │ status = JACKPOT_PENDING
  │     │ retry jackpotWin cùng transaction_id
  │     │ không reset pot
  │     ▼
  │  Return pending/error response
  │
  └── jackpotWin success
        │
        │ response.balance = finalBalance
        ▼
     Game Backend
        │
        │ commit result
        │ reset pot
        │ save jackpot history
        ▼
     Return RESULT_MAHJONG2
```

Request:

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

Không được:

```text
settle regularWin + jackpotPrize
rồi tiếp tục jackpotWin jackpotPrize
```

vì sẽ double credit jackpot.

---

## 10. Commit Game Result

```text
┌──────────────────────────────────────────────┐
│ F. COMMIT GAME RESULT                        │
└──────────────────────────────────────────────┘

Chỉ commit khi:

Case 1 — Không jackpot:
  SETTLE_SUCCESS

Case 2 — Có jackpot:
  SETTLE_SUCCESS
  +
  JACKPOT_SUCCESS

Sau đó:
  save spin history
  save cascadeSteps
  save freeSpin state
  save seamless transaction mapping
  commit pot/fund ledger
  reset pot nếu jackpot đã trả thành công
  mark spin COMPLETED
  return RESULT_MAHJONG2
```

Nếu pending:

```text
SETTLE_PENDING:
  không mark COMPLETED
  retry settle cùng transaction_id

JACKPOT_PENDING:
  không reset pot
  retry jackpotWin cùng transaction_id
```

---

## 11. Cancel Bet Flow

Chỉ dùng khi:

```text
bet đã thành công
nhưng game lỗi trước khi có result final / trước settle
```

```text
┌──────────────────────────────────────────────┐
│ G. CANCEL BET                                │
└──────────────────────────────────────────────┘

Game Backend
  │
  │ bet success
  │ game internal error trước result final
  ▼
Game Backend
  │
  │ POST /game/wallet
  │ action = cancelBet
  ▼
SeamlessWallet
  │
  ├── cancel success
  │     │
  │     ▼
  │  status = CANCELLED
  │  return ERROR_GAME_CANCELLED
  │
  └── cancel failed / timeout
        │
        ▼
     status = CANCEL_PENDING
     retry cancelBet cùng transaction_id
```

Request:

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

Không dùng `cancelBet` khi:

```text
RNG đã xong
result đã generated
settle đang pending
```

Trường hợp đó phải retry `settle`, không cancel.

---

## 12. Free Spin Flow

Free Spin không gọi `bet`.

Tuy nhiên, SeamlessWallet doc hiện chưa có section riêng cho Free Spin settlement. Vì vậy không hardcode strategy nếu chưa test.

```text
┌──────────────────────────────────────────────┐
│ H. FREE SPIN FLOW                            │
└──────────────────────────────────────────────┘

Client
  │
  │ PLAY_MAHJONG2
  │ state.mode = FREE_SPIN
  ▼
Game Backend
  │
  │ Validate remainingFreeSpin > 0
  │ Không gọi bet
  │ Dùng bet state đã lưu từ lượt trigger
  ▼
Game Backend
  │
  │ Generate reels
  │ Calculate ways / cascade
  │ Use FREE_SPIN multiplier
  │ Apply reel 3 Golden rule
  │ Calculate regularWin
  ▼
Settlement
  │
  │ Free Spin settlement strategy = TBD
  │ theo SeamlessWallet implementation
  ▼
Return RESULT_MAHJONG2
```

Không được tự giả định:

```text
dùng lại bet_transaction_id của trigger spin cho nhiều free spin
```

nếu chưa test hoặc chưa có doc xác nhận.

Không được tự thiết kế zero-bet nếu action `bet` không cho `amount = 0`.

---

## 13. Transaction ID / Idempotency

`transaction_id` là key idempotency.

Mỗi action có transaction riêng:

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

---

## 14. State Machine Chuẩn

```text
CREATED
↓
BET_PENDING
↓
BET_SUCCESS
↓
RESULT_GENERATED
↓
SETTLE_PENDING
↓
SETTLE_SUCCESS
↓
JACKPOT_PENDING nếu có jackpot
↓
JACKPOT_SUCCESS nếu có jackpot
↓
COMPLETED
```

Nhánh lỗi:

```text
BET_FAILED
CANCEL_PENDING
CANCELLED
SETTLE_PENDING
JACKPOT_PENDING
```

Rule:

```text
BET_FAILED:
  không random

BET_SUCCESS + lỗi trước result:
  cancelBet

RESULT_GENERATED + settle fail:
  retry settle

SETTLE_SUCCESS + jackpotWin fail:
  retry jackpotWin

COMPLETED:
  không gọi lại bet / settle / jackpotWin
```

---

## 15. RESULT_MAHJONG2

Nếu không jackpot:

```text
balance = settle.response.balance
```

Nếu có jackpot:

```text
balance = jackpotWin.response.balance
```

Response:

```json
{
  "cmd": 4001,
  "spinId": "SPIN_10001",
  "roundId": "RND_MW2_SPIN_10001",
  "roomId": 1,

  "reels": [],
  "cascadeSteps": [],

  "totalWin": 1800,
  "balance": 1001350,

  "bet": {
    "betSize": 2.5,
    "betLevel": 9,
    "baseBet": 20,
    "lineBet": 22.5,
    "totalBet": 450
  },

  "seamless": {
    "enabled": true,
    "betTransactionId": "BET_MW2_SPIN_10001",
    "settleTransactionId": "WIN_MW2_SPIN_10001",
    "jackpotTransactionId": null,
    "payoutStatus": "SUCCESS"
  },

  "freeSpin": {
    "triggered": false,
    "awarded": 0,
    "remaining": 0,
    "retriggered": false,
    "scatterCount": 0
  },

  "jackpot": {
    "enabled": true,
    "triggered": false,
    "type": null,
    "amount": 0
  },

  "state": {
    "mode": "BASE",
    "pot": 1200450,
    "bigWin": false,
    "autoPlay": false,
    "turbo": false
  }
}
```

---

## 16. Full Flow Text Cuối Cùng

```text
JOIN
↓
SUBSCRIBE_MAHJONG2
↓
/game/wallet getBalance
↓
INFO_MAHJONG2(balance)


BASE PLAY
↓
PLAY_MAHJONG2
↓
validate request
↓
calculate lineBet / totalBet
↓
create spinId / roundId / transaction ids
↓
/game/wallet bet
↓
if bet fail:
    stop
    return ERROR
↓
if bet success:
    create pending economy ledger
    run RNG / game logic
    calculate regularWin / jackpotPrize
    safety check
↓
/game/wallet settle regularWin
↓
if settle fail:
    SETTLE_PENDING
    retry same transaction_id
↓
if settle success and jackpotPrize = 0:
    commit result
    return RESULT(balance = settle.balance)
↓
if settle success and jackpotPrize > 0:
    /game/wallet jackpotWin
↓
if jackpotWin fail:
    JACKPOT_PENDING
    retry same transaction_id
↓
if jackpotWin success:
    commit result
    reset pot
    return RESULT(balance = jackpotWin.balance)


ERROR AFTER BET BEFORE RESULT
↓
bet success
↓
game error before result final
↓
/game/wallet cancelBet
↓
cancel success:
    CANCELLED
↓
cancel fail:
    CANCEL_PENDING
    retry same transaction_id


FREE SPIN
↓
PLAY in FREE_SPIN
↓
no bet
↓
use stored trigger bet state
↓
game logic
↓
settlement strategy = TBD theo SeamlessWallet implementation
```

---

## 17. Những điểm không được code sai

```text
1. Không gọi Partner Callback trực tiếp.
2. Không dùng CREDIT / WIN action.
3. Không random trước khi bet code = 0.
4. Bet fail thì không RNG, không settle.
5. Sau RNG luôn gọi settle, kể cả win_amount = 0.
6. Jackpot dùng jackpotWin sau settle.
7. Không gộp jackpot vào settle rồi lại jackpotWin.
8. Không retry bằng transaction_id mới.
9. Không cancelBet sau khi result đã generated và settle pending.
10. Không commit pot/fund final trước settlement success.
11. Không reset pot trước jackpotWin success.
12. Free Spin settlement chưa có doc riêng, không hardcode nếu chưa test.
```
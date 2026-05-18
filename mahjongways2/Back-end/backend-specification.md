Dưới đây là bản **tài liệu backend chuẩn đã rà soát lại**, chỉ dùng các thông tin đã có trong:

```text
s8gamelib/SeamlessWallet/doc/GAME_WALLET_API.md
Mahjong2_Backend_Technical_Specification.md
cong-thuc-and-luat-choi-slot-jackpot.md
full-flow-slot-jackpot-system.md
```

Mình đã sửa lại các điểm sai trước đó: **settle không optional**, **jackpot dùng `jackpotWin` sau `settle`**, **không dùng action `credit`**, **không gộp jackpot vào settle nếu bám đúng doc SeamlessWallet**.

````md
# Mahjong Ways 2 — Backend Flow Specification With SeamlessWallet

## 1. Mục tiêu tài liệu

Tài liệu này mô tả flow backend chuẩn để dev implement game **Mahjong Ways 2** tích hợp với **SeamlessWallet** hiện có trong `s8gamelib/SeamlessWallet`.

Mục tiêu:

- Game backend xử lý gameplay.
- SeamlessWallet xử lý tiền.
- Game không gọi Partner Callback trực tiếp.
- Game chỉ gọi `POST /game/wallet`.
- Không random trước khi `bet` thành công.
- Luôn gọi `settle` sau RNG, kể cả `win_amount = 0`.
- Nếu có jackpot, gọi `jackpotWin` sau `settle`.

---

## 2. Kiến trúc tổng quan

```text
Frontend / Game Client
↓
Mahjong Ways 2 Backend
↓
POST /game/wallet
↓
GameWalletServlet
↓
Partner Wallet Callback
````

Game backend không cần biết:

```text
partner callback_url
partner credentials
partner signature
```

Game backend chỉ cần:

```text
session_token
action
transaction_id
round_id
amount / win_amount
```

`GameWalletServlet` sẽ xử lý:

```text
kiểm tra session
kiểm tra idempotency
gọi Partner Wallet Callback
lưu transaction
trả balance về Game Backend
```

---

## 3. Endpoint SeamlessWallet game cần gọi

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

Không cần header xác thực riêng ở phía game. `session_token` là định danh chính.

---

## 4. Các action được dùng

| Action       | Khi dùng                                         | Ghi chú                                 |
| ------------ | ------------------------------------------------ | --------------------------------------- |
| `getBalance` | Khi join game / subscribe                        | Lấy số dư hiển thị                      |
| `bet`        | Trước khi RNG                                    | Thành công mới được random              |
| `settle`     | Sau khi RNG xong                                 | Bắt buộc gọi, `win_amount = 0` nếu thua |
| `cancelBet`  | Bet thành công nhưng game lỗi trước result final | Hoàn tiền cược                          |
| `jackpotWin` | Có jackpot                                       | Gọi sau `settle` thông thường           |

Không dùng các tên action sau nếu bám theo doc hiện tại:

```text
credit
win
debit
rollback
```

Trong doc SeamlessWallet hiện tại, tên đúng là:

```text
bet
settle
cancelBet
jackpotWin
```

---

## 5. Rule gameplay Mahjong Ways 2

Mahjong Ways 2 là game:

```text
5 reels
layout 4-5-5-5-4
2,000 ways
cascade
multiplier theo cascade
Golden Symbol
Golden → Wild transform
Free Spin
Wild thay symbol thường, không thay Scatter
```

Layout:

| Reel   | Row count |
| ------ | --------: |
| Reel 1 |         4 |
| Reel 2 |         5 |
| Reel 3 |         5 |
| Reel 4 |         5 |
| Reel 5 |         4 |

Tổng ways:

```text
4 × 5 × 5 × 5 × 4 = 2,000 ways
```

Backend dùng:

```java
List<List<Mahjong2Cell>> reels;
```

Không dùng:

```java
Cell[4][5]
```

Tài liệu Mahjong2 backend xác nhận game dùng layout `4-5-5-5-4`, tổng `2000 ways`, không dùng matrix `4x5` đều. 

---

## 6. Symbol / Item

Symbol chính thức trên reels:

```text
WILD
SCATTER
ITEM_1
ITEM_2
ITEM_3
ITEM_4
ITEM_5
ITEM_6
ITEM_7
```

Không định nghĩa chính thức trên reels nếu chưa có rule/asset xác nhận:

```text
BONUS
JP
JACKPOT
```

Jackpot nếu có là reward ở tầng system/economy, không phải symbol bắt buộc trên board.

Tài liệu Mahjong2 backend cũng ghi rõ hiện không định nghĩa chính thức `BONUS` hoặc `JACKPOT / JP` symbol trên reels. 

---

## 7. Command ID game backend

Vì project độc lập và muốn reuse flow cũ, có thể dùng block command sau:

| Command                    |     ID | Direction       |
| -------------------------- | -----: | --------------- |
| `PLAY_MAHJONG2`            | `4001` | Client ↔ Server |
| `UPDATE_POT_MAHJONG2`      | `4002` | Server → Client |
| `SUBSCRIBE_MAHJONG2`       | `4003` | Client → Server |
| `UNSUBSCRIBE_MAHJONG2`     | `4004` | Client → Server |
| `CHANGE_ROOM_MAHJONG2`     | `4005` | Client → Server |
| `AUTO_PLAY_MAHJONG2`       | `4006` | Client → Server |
| `STOP_AUTO_PLAY_MAHJONG2`  | `4007` | Client → Server |
| `FORCE_STOP_AUTO_MAHJONG2` | `4008` | Server → Client |
| `INFO_MAHJONG2`            | `4009` | Server → Client |
| `BIG_WIN_MAHJONG2`         | `4010` | Server → Client |
| `TOTAL_FREE_SPIN_MAHJONG2` | `4011` | Server → Client |
| `FREE_DAILY_MAHJONG2`      | `4012` | Optional        |
| `MINIMIZE_MAHJONG2`        | `4013` | Client → Server |
| `MINIMIZE_RESULT_MAHJONG2` | `4014` | Server → Client |

Nếu cần history:

| Command                   |     ID |
| ------------------------- | -----: |
| `HISTORY_MAHJONG2`        | `4015` |
| `HISTORY_RESULT_MAHJONG2` | `4016` |

Lưu ý:

```text
Nếu sau này merge vào SlotMachine chung, phải kiểm tra conflict trong SlotCMD.java.
```

---

## 8. Transaction ID / Idempotency

Theo doc SeamlessWallet:

```text
transaction_id phải duy nhất toàn cầu.
Trùng transaction_id = idempotency.
Mỗi action phải có transaction_id riêng.
```

Khuyến nghị đặt ID:

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

Không được retry bằng transaction id mới.

Nếu timeout hoặc lỗi mạng:

```text
retry cùng transaction_id cũ
```

Không tạo:

```text
BET_MW2_SPIN_10001_RETRY_1
WIN_MW2_SPIN_10001_RETRY_1
```

---

## 9. Full flow chuẩn

### 9.1. Join game / Subscribe

```text
Client → SUBSCRIBE_MAHJONG2(4003)
↓
Backend nhận session_token
↓
Backend gọi /game/wallet
    action = getBalance
    session_token = session_token
↓
Nếu code = 0:
    lấy balance
    trả INFO_MAHJONG2(4009)
↓
Nếu code != 0:
    trả ERROR
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
  "balance": 1000.00,
  "currency": "USD"
}
```

Ghi chú:

```text
Balance ở join chỉ để hiển thị.
Không dùng balance lúc join để quyết định user có được spin sau đó hay không.
```

---

## 10. Base Spin flow

### 10.1. Client gửi PLAY

```json
{
  "cmd": 4001,
  "sessionToken": "SESSION_TOKEN",
  "roomId": 1,
  "betSize": 2.5,
  "betLevel": 9,
  "baseBet": 20,
  "turbo": false
}
```

### 10.2. Backend validate

Backend kiểm tra:

```text
sessionToken tồn tại
roomId hợp lệ
betSize hợp lệ
betLevel hợp lệ
baseBet hợp lệ
player không có spin active khác
game không maintenance
```

### 10.3. Backend tính cược

```text
lineBet = betSize × betLevel
totalBet = lineBet × baseBet
```

Ví dụ:

```text
betSize = 2.5
betLevel = 9
baseBet = 20

lineBet = 2.5 × 9 = 22.5
totalBet = 22.5 × 20 = 450
```

---

## 11. Bet trước RNG

Backend tạo:

```text
spinId = SPIN_10001
roundId = RND_MW2_SPIN_10001
betTransactionId = BET_MW2_SPIN_10001
settleTransactionId = WIN_MW2_SPIN_10001
cancelTransactionId = CANCEL_MW2_SPIN_10001
jackpotTransactionId = JP_MW2_SPIN_10001
```

Gọi `/game/wallet`:

```json
{
  "session_token": "SESSION_TOKEN",
  "action": "bet",
  "transaction_id": "BET_MW2_SPIN_10001",
  "round_id": "RND_MW2_SPIN_10001",
  "amount": 450
}
```

Nếu response:

```json
{
  "code": 0,
  "balance": 999550,
  "transaction_id": "BET_MW2_SPIN_10001"
}
```

thì:

```text
bet success
lấy balanceAfterBet
mới được chạy RNG / game logic
```

Nếu response lỗi, ví dụ:

```json
{
  "code": 1005,
  "message": "Insufficient balance"
}
```

thì:

```text
không random
không update pot/fund
không tạo result thắng thua
không gọi settle
trả ERROR cho client
```

Theo doc SeamlessWallet, `bet` phải gọi trước RNG và chỉ chạy RNG sau khi nhận `code: 0`.

---

## 12. Game logic sau bet success

Sau khi `bet` thành công:

```text
1. Tạo economy ledger trạng thái PENDING
2. Generate reels layout 4-5-5-5-4
3. Random symbol theo weight
4. Calculate 2000 ways
5. Process cascade
6. Process multiplier
7. Process Golden → Wild
8. Process Free Spin
9. Process jackpot nội bộ nếu bật
10. Tính regularWin và jackpotPrize
```

Không commit final pot/fund/jackpot reset ở bước này.

---

## 13. Economy ledger sau bet success

Tài liệu jackpot xác nhận mỗi lượt cược chia thành:

```text
fee = totalBet × 2%
moneyToPot = totalBet × 1%
moneyToFund = totalBet × 97%
```

Sau đó về mặt logic:

```text
pot += moneyToPot
fund += moneyToFund
```

Tuy nhiên khi dùng SeamlessWallet, backend nên ghi ledger ở trạng thái:

```text
PENDING
```

Chỉ commit final sau khi `settle` thành công.

Tài liệu jackpot/economy xác nhận split 2% fee, 1% pot, 97% fund và quy trình cập nhật pot/fund. 

---

## 14. Ways / Cascade / Multiplier

### 14.1. Ways

Win condition:

```text
Symbol thắng xuất hiện từ reel trái sang phải.
Tối thiểu 3 reels liên tiếp.
Wild thay symbol thường.
Wild không thay Scatter.
```

Ways formula:

```text
ways = countReel1 × countReel2 × countReel3 × ...
```

### 14.2. Cascade

```text
Win
↓
Remove Symbols
↓
Drop New Symbols
↓
Recalculate Win
```

### 14.3. Multiplier

Base Game:

| Cascade step | Multiplier |
| -----------: | ---------: |
|            1 |         x1 |
|            2 |         x2 |
|            3 |         x3 |
|           4+ |         x5 |

Free Spin:

| Cascade step | Multiplier |
| -----------: | ---------: |
|            1 |         x2 |
|            2 |         x4 |
|            3 |         x6 |
|           4+ |        x10 |

Tài liệu full-flow xác nhận Ways System, payout theo `Bet × Paytable × Ways × Multiplier`, cascade và multiplier tăng theo cascade. 

---

## 15. Golden Symbol

Golden không phải symbol riêng.

Golden là state của symbol thường:

```json
{
  "symbol": "ITEM_1",
  "golden": true
}
```

Rule:

```text
Golden chỉ xuất hiện ở reel 2, 3, 4.
Golden không áp dụng cho WILD và SCATTER.
Golden symbol tham gia winning ways sẽ chuyển thành WILD ở cascade tiếp theo.
```

Nếu index từ 0:

```text
reel 2,3,4 = index 1,2,3
```

Trong Free Spin:

```text
symbol trên reel 3, trừ WILD và SCATTER, sẽ là Golden
```

Nếu index từ 0:

```text
reel 3 = reelIndex 2
```

---

## 16. Free Spin

Trigger:

```text
3 SCATTER = 10 free spins
mỗi SCATTER thêm = +2 free spins
```

Bảng:

| Scatter count | Free spins |
| ------------: | ---------: |
|             3 |         10 |
|             4 |         12 |
|             5 |         14 |

Công thức:

```text
freeSpinAwarded = 10 + (scatterCount - 3) × 2
```

Free Spin có thể retrigger nếu trong Free Spin tiếp tục xuất hiện đủ Scatter.

---

## 17. Safety check fund

Sau khi tính gameplay:

```text
regularWin = sum(cascadeSteps.stepWin)
jackpotPrize = jackpot amount nếu có
```

Theo doc SeamlessWallet, jackpot trả bằng `jackpotWin` riêng, vì vậy:

```text
settleWinAmount = regularWin
jackpotWinAmount = jackpotPrize
```

Safety check nội bộ:

```text
totalPrizes = regularWin + jackpotPrize
soTienNoHuKhongTruQuy = jackpotPrize nếu jackpot lấy từ pot
fundCost = totalPrizes - soTienNoHuKhongTruQuy
fund - fundCost >= 0
```

Nếu không đủ fund:

```text
deny jackpot
fallback safe result
tính lại regularWin / jackpotPrize nếu cần
```

Tài liệu jackpot xác nhận `soTienNoHuKhongTruQuy` dùng để loại phần jackpot trả từ pot khỏi phần trừ fund, và bắt buộc safety check chống âm quỹ. 

---

## 18. Settle bắt buộc sau RNG

Theo doc SeamlessWallet:

```text
Sau RNG luôn gọi settle.
win_amount = 0 nếu player thua.
```

Request settle:

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

Nếu player thua:

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

Nếu settle success:

```json
{
  "code": 0,
  "balance": 1001350,
  "transaction_id": "WIN_MW2_SPIN_10001"
}
```

Backend lấy:

```text
balanceAfterSettle = response.balance
```

Nếu settle fail / timeout:

```text
không random lại
không gọi bet lại
không tạo settle transaction_id mới
mark SETTLE_PENDING
retry settle với cùng transaction_id
```

---

## 19. Jackpot flow theo doc SeamlessWallet

Theo doc SeamlessWallet:

```text
jackpotWin dùng riêng cho jackpot progressive/fixed
gọi thêm sau settle thông thường
```

Vì vậy flow chuẩn nếu có jackpot:

```text
1. bet
2. RNG / game logic
3. settle regularWin
4. jackpotWin jackpotPrize
5. commit result
```

Không gộp jackpot vào `settle` nếu bám đúng doc hiện tại.

### 19.1. Settle regular win

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

### 19.2. Jackpot win sau settle

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

Nếu `jackpotWin` success:

```text
finalBalance = jackpotWin.response.balance
```

Nếu không có jackpot:

```text
finalBalance = settle.response.balance
```

Không được:

```text
settle win_amount = regularWin + jackpotPrize
và sau đó lại gọi jackpotWin jackpotPrize
```

vì sẽ double credit jackpot.

---

## 20. Commit result

Backend chỉ commit final sau khi:

```text
settle success
và nếu có jackpot: jackpotWin success
```

Khi đó mới:

```text
commit economy ledger
update pot/fund
reset pot nếu jackpot đã trả thành công
save spin history
save cascadeSteps
save freeSpin state
save seamless transaction mapping
mark spin COMPLETED
return RESULT_MAHJONG2
```

Nếu `settle` pending hoặc `jackpotWin` pending:

```text
không mark COMPLETED
không random lại
không tạo transaction_id mới
retry đúng action với cùng transaction_id
```

---

## 21. Cancel bet flow

Chỉ dùng khi:

```text
bet đã thành công
nhưng game lỗi trước khi có result final / trước settle
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

Nếu cancel success:

```text
status = CANCELLED
return ERROR_GAME_CANCELLED
```

Nếu cancel fail:

```text
status = CANCEL_PENDING
retry cancelBet với cùng transaction_id
```

Không dùng `cancelBet` khi:

```text
RNG đã xong và settle đang pending
```

Trường hợp đó phải retry `settle`, không cancel.

---

## 22. Free Spin với SeamlessWallet

Free Spin không gọi `bet` mới, vì đây là lượt miễn phí.

Flow:

```text
PLAY_MAHJONG2 khi mode = FREE_SPIN
↓
validate remainingFreeSpin > 0
↓
không gọi bet
↓
dùng bet state của lượt trigger:
    betSize
    betLevel
    baseBet
    lineBet
    totalBet
↓
generate reels
↓
calculate ways / cascade / multiplier FREE_SPIN
↓
calculate regularWin
↓
gọi settle nếu có round/transaction strategy hợp lệ
```

Điểm cần chốt thêm với code SeamlessWallet:

```text
Doc hiện tại không có section riêng cho Free Spin.
Vì settle cần liên kết round/bet, backend phải chọn strategy rõ ràng trước production.
```

Strategy an toàn để không đoán trong tài liệu này:

```text
Free Spin settlement strategy = TBD theo implementation SeamlessWallet hiện tại.
Không hardcode dùng lại bet_transaction_id của trigger spin cho nhiều free spin nếu chưa test.
Không tạo zero-bet nếu /game/wallet action=bet không cho amount = 0.
```

Vì doc `bet` yêu cầu:

```text
amount phải > 0
```

nên không được tự thiết kế zero-bet nếu chưa sửa SeamlessWallet.

---

## 23. State machine tối thiểu

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
SETTLE_FAILED / SETTLE_PENDING
JACKPOT_FAILED / JACKPOT_PENDING
```

Rule:

```text
BET_FAILED → không random
BET_SUCCESS + lỗi trước result → cancelBet
RESULT_GENERATED + settle fail → retry settle
SETTLE_SUCCESS + jackpotWin fail → retry jackpotWin
COMPLETED → không gọi lại bet/settle/jackpotWin
```

---

## 24. Backend class gợi ý

```text
mahjong2/
├── Mahjong2Module.java
├── Mahjong2Room.java
├── Mahjong2SpinService.java
├── Mahjong2GameEngine.java
├── Mahjong2Config.java
├── Mahjong2Symbol.java
├── Mahjong2Board.java
├── Mahjong2Cell.java
├── Mahjong2WaysEngine.java
├── Mahjong2CascadeEngine.java
├── Mahjong2GoldenTransformService.java
├── Mahjong2FreeSpinService.java
├── Mahjong2JackpotService.java
├── Mahjong2HistoryService.java
└── seamless/
    ├── SeamlessWalletGateway.java
    ├── SeamlessWalletHttpGateway.java
    ├── BalanceResult.java
    ├── BetResult.java
    ├── SettleResult.java
    ├── CancelBetResult.java
    └── JackpotWinResult.java
```

Game package chỉ gọi:

```java
SeamlessWalletGateway
```

Không gọi trực tiếp Partner Callback.

---

## 25. SeamlessWalletGateway interface

```java
public interface SeamlessWalletGateway {

    BalanceResult getBalance(String sessionToken);

    BetResult bet(
            String sessionToken,
            String transactionId,
            String roundId,
            BigDecimal amount
    );

    SettleResult settle(
            String sessionToken,
            String transactionId,
            String betTransactionId,
            String roundId,
            BigDecimal winAmount,
            boolean jackpot
    );

    CancelBetResult cancelBet(
            String sessionToken,
            String transactionId,
            String betTransactionId,
            String roundId,
            BigDecimal amount
    );

    JackpotWinResult jackpotWin(
            String sessionToken,
            String transactionId,
            String roundId,
            String jackpotId,
            BigDecimal winAmount,
            BigDecimal jackpotContribution
    );
}
```

Ghi chú tiền:

```text
Trong game logic không dùng double.
Dùng BigDecimal.
Khi gọi /game/wallet, adapter convert sang number theo format endpoint hiện có.
```

---

## 26. Result response

```json
{
  "cmd": 4001,
  "spinId": "SPIN_10001",
  "roundId": "RND_MW2_SPIN_10001",
  "roomId": 1,

  "reels": [],

  "cascadeSteps": [
    {
      "step": 1,
      "mode": "BASE",
      "multiplier": 1,
      "reelsBefore": [],
      "wins": [],
      "removedPositions": [],
      "goldenTransforms": [],
      "reelsAfterDrop": [],
      "stepWin": 0
    }
  ],

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

Balance trong result:

```text
Nếu không jackpot:
    balance = settle.response.balance

Nếu có jackpot:
    balance = jackpotWin.response.balance
```

---

## 27. Những điều không được code sai

```text
1. Không gọi Partner Callback trực tiếp.
2. Không random trước khi bet code = 0.
3. Bet fail thì không settle, không RNG.
4. Sau RNG luôn gọi settle, kể cả win_amount = 0.
5. Jackpot dùng jackpotWin sau settle.
6. Không gộp jackpot vào settle rồi lại gọi jackpotWin.
7. Không retry bằng transaction_id mới.
8. Không dùng cancelBet sau khi result đã generated và settle pending.
9. Không dùng double cho tiền trong game logic.
10. Không dùng matrix 4x5 đều.
11. Không dùng Lines/payline.
12. Không đưa BONUS / JP / JACKPOT vào reel symbol khi chưa có rule.
13. Không commit jackpot reset trước khi jackpotWin success.
14. Không mark spin COMPLETED trước settle success.
15. Free Spin settlement chưa có doc riêng, không hardcode nếu chưa test.
```

---

## 28. Full flow text cuối cùng

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
    stop, return ERROR
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
    SETTLE_PENDING, retry same transaction_id
↓
if settle success and jackpotPrize = 0:
    commit result
    return RESULT(balance = settle.balance)
↓
if settle success and jackpotPrize > 0:
    /game/wallet jackpotWin
↓
if jackpotWin fail:
    JACKPOT_PENDING, retry same transaction_id
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
cancel success: CANCELLED
cancel fail: CANCEL_PENDING
```

---

## 29. Kết luận chuẩn

```text
Mahjong Ways 2 Backend xử lý gameplay.
SeamlessWallet xử lý tiền.
Game chỉ gọi /game/wallet.
Join gọi getBalance.
Base Spin gọi bet trước RNG.
Bet thành công mới random.
Sau RNG luôn gọi settle.
Nếu có jackpot thì gọi jackpotWin sau settle.
Nếu bet thành công nhưng game lỗi trước result thì gọi cancelBet.
Retry luôn dùng lại cùng transaction_id.
```

```
```

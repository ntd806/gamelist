# Mahjong Ways 2 — Frontend Command & Response Flow

---

## 1. Mục tiêu tài liệu

Tài liệu này mô tả flow tích hợp Frontend với Backend cho game **Mahjong Ways 2**.

Backend hiện dùng **SeamlessWallet** để xử lý tiền, nên frontend cần hiểu rõ:

```text
Frontend không tự trừ tiền.
Frontend không tự cộng tiền.
Frontend chỉ update balance bằng response từ Backend.
Backend sẽ gọi /game/wallet để xử lý tiền.
```

Flow backend mới:

```text
JOIN
→ /game/wallet getBalance
→ INFO_MAHJONG2

PLAY
→ /game/wallet bet
→ bet success mới RNG
→ /game/wallet settle
→ nếu có jackpot: /game/wallet jackpotWin
→ RESULT_MAHJONG2
```

---

## 2. Cấu trúc game Mahjong Ways 2

Mahjong Ways 2 là game slot dùng **Ways System**, không dùng payline cố định.

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

---

## 3. Reel layout

| Reel   | Số row |
| ------ | -----: |
| Reel 1 |      4 |
| Reel 2 |      5 |
| Reel 3 |      5 |
| Reel 4 |      5 |
| Reel 5 |      4 |

Tổng số ways:

```text
4 × 5 × 5 × 5 × 4 = 2,000 ways
```

Frontend render theo dạng:

```text
reels[reelIndex][rowIndex]
```

Không render như matrix đều `4x5`.

---

## 4. Symbol / Item chính

Backend hiện xác nhận các symbol chính dùng trên reels:

| Symbol    | Loại    | Vai trò                                              |
| --------- | ------- | ---------------------------------------------------- |
| `WILD`    | Special | Thay thế các symbol thường, không thay thế `SCATTER` |
| `SCATTER` | Special | Kích hoạt Free Spin                                  |
| `ITEM_1`  | Normal  | Symbol thường, dùng để tính ways win                 |
| `ITEM_2`  | Normal  | Symbol thường, dùng để tính ways win                 |
| `ITEM_3`  | Normal  | Symbol thường, dùng để tính ways win                 |
| `ITEM_4`  | Normal  | Symbol thường, dùng để tính ways win                 |
| `ITEM_5`  | Normal  | Symbol thường, dùng để tính ways win                 |
| `ITEM_6`  | Normal  | Symbol thường, dùng để tính ways win                 |
| `ITEM_7`  | Normal  | Symbol thường, dùng để tính ways win                 |

---

## 5. Golden Symbol

`Golden` không phải là một symbol riêng. Đây là trạng thái đặc biệt của symbol thường.

Ví dụ:

```json
{
  "symbol": "ITEM_1",
  "golden": true
}
```

Rule:

```text
Golden Symbol chỉ áp dụng cho symbol thường.
Golden không áp dụng cho WILD và SCATTER.
Golden Symbol tham gia winning ways sẽ chuyển thành WILD ở cascade tiếp theo.
```

Frontend render bằng:

```text
symbol asset + golden overlay / golden frame / golden effect
```

Không cần asset riêng dạng `GOLDEN_ITEM`.

---

## 6. Symbol chưa xác nhận

Hiện chưa có rule chính thức cho các symbol sau trên reels:

```text
BONUS
JP
JACKPOT
```

Vì vậy frontend không tự giả định có các symbol này nếu backend không trả trong `symbols[]` hoặc `reels[]`.

---

## 7. Jackpot

Jackpot nếu có là reward ở tầng system/economy, không phải symbol bắt buộc xuất hiện trên board.

```text
Jackpot là reward system.
JP / JACKPOT không phải reel symbol mặc định.
```

Response jackpot dùng để frontend hiển thị animation jackpot:

```json
{
  "jackpot": {
    "enabled": true,
    "triggered": false,
    "type": null,
    "amount": 0
  }
}
```

Nếu jackpot nổ, backend sẽ xử lý `jackpotWin` sau `settle`, frontend chỉ render theo response.

---

# 8. Command ID convention

Dự án dùng lại command convention cũ theo block `4001–4016`.

## 8.1. Client → Server

| Command                   |     ID | Mục đích                       |
| ------------------------- | -----: | ------------------------------ |
| `PLAY_MAHJONG2`           | `4001` | Quay 1 lượt / nhận result      |
| `SUBSCRIBE_MAHJONG2`      | `4003` | Vào game / join room           |
| `UNSUBSCRIBE_MAHJONG2`    | `4004` | Thoát game                     |
| `CHANGE_ROOM_MAHJONG2`    | `4005` | Đổi room / mức cược            |
| `AUTO_PLAY_MAHJONG2`      | `4006` | Bật auto play                  |
| `STOP_AUTO_PLAY_MAHJONG2` | `4007` | Dừng auto play                 |
| `MINIMIZE_MAHJONG2`       | `4013` | Thu nhỏ game                   |
| `HISTORY_MAHJONG2`        | `4015` | Lấy lịch sử nếu backend hỗ trợ |

---

## 8.2. Server → Client

| Command                    |     ID | Mục đích                           |
| -------------------------- | -----: | ---------------------------------- |
| `RESULT_MAHJONG2`          | `4001` | Kết quả spin                       |
| `UPDATE_POT_MAHJONG2`      | `4002` | Update jackpot pot nếu bật jackpot |
| `FORCE_STOP_AUTO_MAHJONG2` | `4008` | Server bắt dừng auto               |
| `INFO_MAHJONG2`            | `4009` | Game config + room state           |
| `BIG_WIN_MAHJONG2`         | `4010` | Broadcast thắng lớn / jackpot      |
| `TOTAL_FREE_SPIN_MAHJONG2` | `4011` | Sync tổng Free Spin nếu cần        |
| `MINIMIZE_RESULT_MAHJONG2` | `4014` | Kết quả khi minimize               |
| `HISTORY_RESULT_MAHJONG2`  | `4016` | Trả lịch sử nếu backend hỗ trợ     |
| `ERROR`                    | `3999` | Lỗi chuẩn                          |

---

# 9. Session token rule

Frontend nhận `session_token` từ game launch URL.

Ví dụ:

```text
https://game-domain.com/index.html?token=SESSION_TOKEN&game=MAHJONG_WAYS_2
```

Frontend phải gửi `sessionToken` trong các request chính:

```text
SUBSCRIBE_MAHJONG2
PLAY_MAHJONG2
CHANGE_ROOM_MAHJONG2 nếu backend yêu cầu
AUTO_PLAY_MAHJONG2 nếu backend yêu cầu
```

Frontend không gọi Partner Callback và không gọi `/game/wallet` trực tiếp.

---

# 10. Full flow tổng quan

```text
LAUNCH GAME
↓
Frontend lấy sessionToken từ URL
↓
SUBSCRIBE_MAHJONG2
↓
Backend gọi /game/wallet getBalance
↓
INFO_MAHJONG2
↓
PLAY_MAHJONG2
↓
Backend gọi /game/wallet bet
↓
bet success mới RNG
↓
Backend xử lý reels / ways / cascade / freeSpin / jackpot
↓
Backend gọi /game/wallet settle
↓
Nếu có jackpot: Backend gọi /game/wallet jackpotWin
↓
RESULT_MAHJONG2
↓
Frontend render result + update balance bằng RESULT.balance
```

---

# 11. SUBSCRIBE_MAHJONG2

## Client → Server

```json
{
  "cmd": 4003,
  "sessionToken": "SESSION_TOKEN",
  "roomId": 1
}
```

Backend sẽ gọi:

```text
/game/wallet action=getBalance
```

Sau đó trả `INFO_MAHJONG2`.

---

## Server → Client: INFO_MAHJONG2

```json
{
  "cmd": 4009,

  "room": {
    "roomId": 1,
    "betSize": 2.5,
    "betLevel": 9,
    "baseBet": 20,
    "lineBet": 22.5,
    "totalBet": 450,
    "pot": 1200000
  },

  "gameConfig": {
    "gameCode": "MAHJONG_WAYS_2",
    "reelCount": 5,
    "reelRows": [4, 5, 5, 5, 4],
    "totalWays": 2000,
    "minMatchedReels": 3,
    "winDirection": "LEFT_TO_RIGHT",
    "hasCascade": true,
    "hasGoldenSymbol": true,
    "hasFreeSpin": true,
    "hasJackpot": true
  },

  "symbols": [
    {
      "code": "WILD",
      "type": "SPECIAL",
      "role": "WILD",
      "assetKey": "wild",
      "canBeGolden": false,
      "payable": false
    },
    {
      "code": "SCATTER",
      "type": "SPECIAL",
      "role": "SCATTER",
      "assetKey": "scatter",
      "canBeGolden": false,
      "payable": false
    },
    {
      "code": "ITEM_1",
      "type": "NORMAL",
      "role": "PAYABLE",
      "assetKey": "item_1",
      "canBeGolden": true,
      "payable": true
    }
  ],

  "wildRule": {
    "enabled": true,
    "substitutes": "ALL_PAYABLE_SYMBOLS",
    "excludedSymbols": ["SCATTER"]
  },

  "goldenRule": {
    "enabled": true,
    "allowedReels": [1, 2, 3],
    "excludedSymbols": ["WILD", "SCATTER"],
    "transformTo": "WILD",
    "transformCondition": "PARTICIPATED_IN_PREVIOUS_WIN"
  },

  "multipliers": {
    "BASE": {
      "1": 1,
      "2": 2,
      "3": 3,
      "4+": 5
    },
    "FREE_SPIN": {
      "1": 2,
      "2": 4,
      "3": 6,
      "4+": 10
    }
  },

  "freeSpinRule": {
    "triggerSymbol": "SCATTER",
    "minScatter": 3,
    "baseFreeSpin": 10,
    "extraSpinPerAdditionalScatter": 2,
    "retrigger": true,
    "freeSpinGoldenReel": 2
  },

  "playerState": {
    "balance": 1000000,
    "currency": "VND",
    "mode": "BASE",
    "remainingFreeSpin": 0,
    "autoPlay": false,
    "turbo": false
  }
}
```

Ghi chú:

```text
allowedReels: [1,2,3] = reel 2,3,4 nếu index từ 0.
freeSpinGoldenReel: 2 = reel 3 nếu index từ 0.
```

---

# 12. CHANGE_ROOM_MAHJONG2

## Client → Server

```json
{
  "cmd": 4005,
  "sessionToken": "SESSION_TOKEN",
  "roomId": 2
}
```

## Server → Client

Backend trả lại `INFO_MAHJONG2`.

```json
{
  "cmd": 4009,

  "room": {
    "roomId": 2,
    "betSize": 5,
    "betLevel": 9,
    "baseBet": 20,
    "lineBet": 45,
    "totalBet": 900,
    "pot": 5000000
  },

  "playerState": {
    "balance": 1000000,
    "currency": "VND",
    "mode": "BASE",
    "remainingFreeSpin": 0,
    "autoPlay": false,
    "turbo": false
  }
}
```

---

# 13. PLAY_MAHJONG2

## Client → Server

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

---

## Bet formula

```text
lineBet = betSize × betLevel
totalBet = lineBet × baseBet
```

Ví dụ:

```text
lineBet = 2.5 × 9 = 22.5
totalBet = 22.5 × 20 = 450
```

Frontend chỉ hiển thị bet. Backend là nơi tính và xác nhận tiền thật.

---

# 14. Backend play flow frontend cần biết

```text
Frontend gửi PLAY_MAHJONG2
↓
Backend gọi /game/wallet action=bet
↓
Nếu bet fail:
    Backend trả ERROR
    Frontend không chạy spin result
↓
Nếu bet success:
    Backend mới RNG
    Backend tính ways/cascade/freeSpin/jackpot
    Backend gọi /game/wallet action=settle
    Nếu có jackpot: Backend gọi /game/wallet action=jackpotWin
↓
Backend trả RESULT_MAHJONG2
↓
Frontend render result và update balance
```

Frontend không cần gọi:

```text
getBalance
bet
settle
jackpotWin
```

Frontend chỉ gọi socket command của game.

---

# 15. RESULT_MAHJONG2 — response chuẩn

## Server → Client

```json
{
  "cmd": 4001,
  "spinId": "SPIN_10001",
  "roundId": "RND_MW2_SPIN_10001",
  "roomId": 1,

  "reels": [
    [
      { "symbol": "ITEM_1", "golden": false },
      { "symbol": "ITEM_2", "golden": false },
      { "symbol": "SCATTER", "golden": false },
      { "symbol": "ITEM_3", "golden": false }
    ],
    [
      { "symbol": "ITEM_1", "golden": true },
      { "symbol": "WILD", "golden": false },
      { "symbol": "ITEM_2", "golden": false },
      { "symbol": "ITEM_4", "golden": true },
      { "symbol": "ITEM_5", "golden": false }
    ],
    [
      { "symbol": "ITEM_1", "golden": false },
      { "symbol": "ITEM_3", "golden": true },
      { "symbol": "ITEM_4", "golden": false },
      { "symbol": "ITEM_5", "golden": false },
      { "symbol": "ITEM_6", "golden": false }
    ],
    [
      { "symbol": "ITEM_1", "golden": false },
      { "symbol": "ITEM_2", "golden": true },
      { "symbol": "ITEM_3", "golden": false },
      { "symbol": "ITEM_4", "golden": false },
      { "symbol": "ITEM_5", "golden": false }
    ],
    [
      { "symbol": "ITEM_2", "golden": false },
      { "symbol": "ITEM_3", "golden": false },
      { "symbol": "ITEM_4", "golden": false },
      { "symbol": "ITEM_5", "golden": false }
    ]
  ],

  "cascadeSteps": [
    {
      "step": 1,
      "mode": "BASE",
      "multiplier": 1,

      "reelsBefore": [],

      "wins": [
        {
          "symbol": "ITEM_1",
          "matchedReels": 4,
          "ways": 8,
          "payTableValue": 10,
          "lineBet": 22.5,
          "multiplier": 1,
          "winAmount": 1800,
          "positions": [
            { "reel": 0, "row": 0 },
            { "reel": 1, "row": 0 },
            { "reel": 1, "row": 3 },
            { "reel": 2, "row": 0 },
            { "reel": 3, "row": 0 }
          ]
        }
      ],

      "removedPositions": [
        { "reel": 0, "row": 0 },
        { "reel": 1, "row": 0 },
        { "reel": 2, "row": 0 },
        { "reel": 3, "row": 0 }
      ],

      "goldenTransforms": [
        {
          "position": { "reel": 1, "row": 3 },
          "from": {
            "symbol": "ITEM_4",
            "golden": true
          },
          "to": {
            "symbol": "WILD",
            "golden": false
          }
        }
      ],

      "reelsAfterDrop": [],

      "stepWin": 1800
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
    "turbo": false,
    "autoPlay": false
  }
}
```

---

# 16. Payout rule trong response

Mỗi `win` phản ánh công thức backend:

```text
winAmount = payTableValue × lineBet × ways × multiplier
```

Trong đó:

```text
lineBet = betSize × betLevel
totalBet = lineBet × baseBet
```

Frontend không tự tính tiền thắng. Frontend chỉ render:

```text
wins[].winAmount
cascadeSteps[].stepWin
totalWin
balance
```

---

# 17. Seamless payout status

Frontend cần đọc:

```json
"seamless": {
  "enabled": true,
  "payoutStatus": "SUCCESS"
}
```

Các trạng thái có thể dùng:

| Status            | Ý nghĩa                                     | Frontend nên làm                                              |
| ----------------- | ------------------------------------------- | ------------------------------------------------------------- |
| `SUCCESS`         | Bet/settle hoàn tất                         | Render result bình thường                                     |
| `SETTLE_PENDING`  | Result đã có nhưng settle đang pending      | Hiển thị trạng thái đang xử lý / không cho spin mới           |
| `JACKPOT_PENDING` | JackpotWin đang pending                     | Hiển thị đang xử lý jackpot / không reset UI pot như hoàn tất |
| `CANCELLED`       | Bet đã được cancel do lỗi game trước result | Hiển thị lỗi, không render spin                               |
| `CANCEL_PENDING`  | Cancel đang pending                         | Hiển thị lỗi xử lý, chờ backend                               |

Trong production, backend nên hạn chế trả result thắng nếu payout chưa hoàn tất. Nhưng nếu có trả pending, frontend phải dựa vào `payoutStatus`.

---

# 18. Free Spin trigger result

## 3 Scatter

```json
{
  "cmd": 4001,
  "spinId": "SPIN_10002",
  "roundId": "RND_MW2_SPIN_10002",
  "roomId": 1,

  "reels": [],
  "cascadeSteps": [],

  "totalWin": 0,
  "balance": 999550,

  "bet": {
    "betSize": 2.5,
    "betLevel": 9,
    "baseBet": 20,
    "lineBet": 22.5,
    "totalBet": 450
  },

  "seamless": {
    "enabled": true,
    "betTransactionId": "BET_MW2_SPIN_10002",
    "settleTransactionId": "WIN_MW2_SPIN_10002",
    "jackpotTransactionId": null,
    "payoutStatus": "SUCCESS"
  },

  "freeSpin": {
    "triggered": true,
    "awarded": 10,
    "remaining": 10,
    "retriggered": false,
    "scatterCount": 3
  },

  "jackpot": {
    "enabled": true,
    "triggered": false,
    "type": null,
    "amount": 0
  },

  "state": {
    "mode": "FREE_SPIN",
    "pot": 1200450,
    "bigWin": false,
    "turbo": false,
    "autoPlay": false
  }
}
```

## 4 Scatter

```json
"freeSpin": {
  "triggered": true,
  "awarded": 12,
  "remaining": 12,
  "retriggered": false,
  "scatterCount": 4
}
```

## 5 Scatter

```json
"freeSpin": {
  "triggered": true,
  "awarded": 14,
  "remaining": 14,
  "retriggered": false,
  "scatterCount": 5
}
```

---

# 19. RESULT trong Free Spin

Frontend vẫn gửi `PLAY_MAHJONG2`.

Backend xử lý Free Spin nội bộ:

```text
Không gọi bet mới.
Dùng bet state của lượt trigger.
Settlement Free Spin do backend xử lý theo strategy nội bộ.
Frontend chỉ render RESULT.
```

Response:

```json
{
  "cmd": 4001,
  "spinId": "FREE_SPIN_10003",
  "roundId": "RND_MW2_FREE_SPIN_10003",
  "roomId": 1,

  "reels": [],

  "cascadeSteps": [
    {
      "step": 1,
      "mode": "FREE_SPIN",
      "multiplier": 2,
      "reelsBefore": [],
      "wins": [],
      "removedPositions": [],
      "goldenTransforms": [],
      "reelsAfterDrop": [],
      "stepWin": 0
    }
  ],

  "totalWin": 0,
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
    "betTransactionId": null,
    "settleTransactionId": "WIN_MW2_FREE_SPIN_10003",
    "jackpotTransactionId": null,
    "payoutStatus": "SUCCESS"
  },

  "freeSpin": {
    "triggered": false,
    "awarded": 0,
    "remaining": 9,
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
    "mode": "FREE_SPIN",
    "pot": 1200450,
    "bigWin": false,
    "turbo": false,
    "autoPlay": false
  }
}
```

Rule trong Free Spin:

```text
Frontend không gửi bet riêng.
Không deduct bet mới.
Payout dùng lineBet của lượt trigger / free spin state.
Multiplier dùng bảng FREE_SPIN: x2, x4, x6, x10.
Reel 3 có Golden rule, trừ WILD và SCATTER.
```

---

# 20. Retrigger Free Spin

Nếu đang Free Spin và tiếp tục có đủ Scatter:

```json
"freeSpin": {
  "triggered": true,
  "awarded": 10,
  "remaining": 15,
  "retriggered": true,
  "scatterCount": 3
}
```

Ý nghĩa:

```text
awarded = số spin mới được cộng thêm
remaining = tổng free spin còn lại sau khi cộng
retriggered = true vì đang trong FREE_SPIN mode
```

---

# 21. Jackpot result

Nếu jackpot nổ:

```json
{
  "cmd": 4001,
  "spinId": "SPIN_10004",
  "roundId": "RND_MW2_SPIN_10004",
  "roomId": 1,

  "reels": [],
  "cascadeSteps": [],

  "totalWin": 12000000,
  "balance": 13000000,

  "bet": {
    "betSize": 2.5,
    "betLevel": 9,
    "baseBet": 20,
    "lineBet": 22.5,
    "totalBet": 450
  },

  "seamless": {
    "enabled": true,
    "betTransactionId": "BET_MW2_SPIN_10004",
    "settleTransactionId": "WIN_MW2_SPIN_10004",
    "jackpotTransactionId": "JP_MW2_SPIN_10004",
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
    "triggered": true,
    "type": "NORMAL",
    "amount": 12000000
  },

  "state": {
    "mode": "BASE",
    "pot": 1000000,
    "bigWin": true,
    "turbo": false,
    "autoPlay": false
  }
}
```

Rule:

```text
Nếu jackpot.triggered = true:
- Frontend render jackpot animation.
- balance là balance sau jackpotWin.
- state.pot là pot sau khi backend đã xử lý reset.
```

Nếu `payoutStatus = JACKPOT_PENDING`, frontend không nên hiển thị jackpot như đã hoàn tất.

---

# 22. UPDATE_POT_MAHJONG2

Gửi khi:

```text
pot thay đổi sau spin
pot reset sau jackpot
client subscribe / change room
```

```json
{
  "cmd": 4002,
  "roomId": 1,
  "pot": 1200450
}
```

Nếu project không bật jackpot:

```text
Không cần gửi UPDATE_POT_MAHJONG2.
INFO/RESULT có thể trả jackpot.enabled = false.
```

---

# 23. BIG_WIN_MAHJONG2

```json
{
  "cmd": 4010,
  "roomId": 1,
  "nickname": "playerA",
  "amount": 5000000,
  "type": "BIG_WIN"
}
```

Nếu là jackpot:

```json
{
  "cmd": 4010,
  "roomId": 1,
  "nickname": "playerA",
  "amount": 12000000,
  "type": "JACKPOT"
}
```

---

# 24. AUTO_PLAY_MAHJONG2

## Client → Server

```json
{
  "cmd": 4006,
  "sessionToken": "SESSION_TOKEN",
  "roomId": 1,
  "betSize": 2.5,
  "betLevel": 9,
  "baseBet": 20,
  "rounds": 100,
  "turbo": true
}
```

## Server → Client

Server trả nhiều result liên tiếp:

```text
RESULT_MAHJONG2
RESULT_MAHJONG2
RESULT_MAHJONG2
...
```

Mỗi result có:

```json
"state": {
  "autoPlay": true
}
```

Nếu gặp pending settlement hoặc không đủ tiền, backend trả `FORCE_STOP_AUTO_MAHJONG2`.

---

# 25. STOP_AUTO_PLAY_MAHJONG2

## Client → Server

```json
{
  "cmd": 4007,
  "sessionToken": "SESSION_TOKEN"
}
```

## Server → Client

```json
{
  "cmd": 4008,
  "reason": "USER_STOP"
}
```

---

# 26. FORCE_STOP_AUTO_MAHJONG2

```json
{
  "cmd": 4008,
  "reason": "NOT_ENOUGH_MONEY"
}
```

Các reason:

| Reason              | Ý nghĩa                                     |
| ------------------- | ------------------------------------------- |
| `NOT_ENOUGH_MONEY`  | Không đủ tiền                               |
| `USER_STOP`         | User dừng                                   |
| `DISCONNECTED`      | Mất kết nối                                 |
| `INVALID_ROOM`      | Room không hợp lệ                           |
| `SESSION_EXPIRED`   | Session hết hạn                             |
| `FREE_SPIN_ENTERED` | Dừng auto để vào Free Spin nếu game yêu cầu |
| `SETTLE_PENDING`    | Dừng auto vì payout đang xử lý              |
| `JACKPOT_PENDING`   | Dừng auto vì jackpot payout đang xử lý      |

---

# 27. MINIMIZE_MAHJONG2

## Client → Server

```json
{
  "cmd": 4013,
  "sessionToken": "SESSION_TOKEN"
}
```

## Server → Client

```json
{
  "cmd": 4014,
  "result": {
    "spinId": "SPIN_10005",
    "totalWin": 1200,
    "balance": 1001200,
    "freeSpin": {
      "remaining": 0
    },
    "state": {
      "mode": "BASE"
    }
  }
}
```

---

# 28. HISTORY_MAHJONG2

## Client → Server

```json
{
  "cmd": 4015,
  "sessionToken": "SESSION_TOKEN",
  "fromDate": "2026-05-01",
  "toDate": "2026-05-18",
  "page": 1,
  "size": 20
}
```

## Server → Client

```json
{
  "cmd": 4016,
  "page": 1,
  "size": 20,
  "total": 100,
  "items": [
    {
      "spinId": "SPIN_10001",
      "roundId": "RND_MW2_SPIN_10001",
      "time": "2026-05-18T10:30:00",
      "roomId": 1,
      "totalBet": 450,
      "totalWin": 1800,
      "mode": "BASE",
      "isJackpot": false,
      "payoutStatus": "SUCCESS"
    }
  ]
}
```

---

# 29. UNSUBSCRIBE_MAHJONG2

## Client → Server

```json
{
  "cmd": 4004,
  "sessionToken": "SESSION_TOKEN"
}
```

## Server xử lý

```text
remove player khỏi room
stop auto nếu đang chạy
save free spin state nếu còn
```

## Server → Client

```json
{
  "cmd": 4004,
  "success": true
}
```

---

# 30. ERROR response

```json
{
  "cmd": 3999,
  "errorCode": 1001,
  "message": "NOT_ENOUGH_MONEY",
  "balance": 100000
}
```

| Error Code | Message                     |
| ---------: | --------------------------- |
|       1001 | `NOT_ENOUGH_MONEY`          |
|       1002 | `INVALID_ROOM`              |
|       1003 | `INVALID_BET`               |
|       1004 | `SESSION_EXPIRED`           |
|       1005 | `GAME_MAINTENANCE`          |
|       1006 | `INVALID_STATE`             |
|       1007 | `AUTO_PLAY_ALREADY_RUNNING` |
|       1008 | `NO_FREE_SPIN_AVAILABLE`    |
|       1009 | `SETTLE_PENDING`            |
|       1010 | `JACKPOT_PENDING`           |

---

# 31. Frontend balance rule

Frontend chỉ được update balance bằng:

```text
INFO_MAHJONG2.playerState.balance
RESULT_MAHJONG2.balance
ERROR.balance nếu backend có trả
```

Frontend không được:

```text
tự trừ balance khi bấm PLAY
tự cộng balance khi thấy totalWin
tự reset balance theo local calculation
```

Vì balance thật được xử lý qua SeamlessWallet.

---

# 32. Flow tóm tắt theo frontend

## Subscribe flow

```text
Client 4003 SUBSCRIBE(sessionToken)
↓
Backend /game/wallet getBalance
↓
Server 4009 INFO(balance, config)
↓
Server 4002 UPDATE_POT nếu jackpot.enabled = true
```

## Play flow

```text
Client 4001 PLAY(sessionToken, bet)
↓
Backend /game/wallet bet
↓
Nếu bet fail:
    Server 3999 ERROR
↓
Nếu bet success:
    Backend RNG / ways / cascade / freeSpin / jackpot
    Backend /game/wallet settle
    Nếu có jackpot: Backend /game/wallet jackpotWin
↓
Server 4001 RESULT
↓
Server 4002 UPDATE_POT nếu pot đổi
↓
Server 4010 BIG_WIN nếu đủ điều kiện
```

## Auto play flow

```text
Client 4006 AUTO_PLAY
↓
Server 4001 RESULT
↓
Server 4001 RESULT
↓
Server 4001 RESULT
↓
Client 4007 STOP
hoặc
Server 4008 FORCE_STOP
```

## Free Spin flow

```text
Server 4001 RESULT
freeSpin.triggered = true
state.mode = FREE_SPIN
↓
Client tiếp tục 4001 PLAY
↓
Backend không gọi bet mới
↓
Backend xử lý Free Spin
↓
Server 4001 RESULT mode FREE_SPIN
↓
freeSpin.remaining giảm dần
↓
Nếu retrigger: remaining cộng thêm
↓
Kết thúc: state.mode = BASE
```

---

# 33. Không tạo command riêng cho cascade/golden

Không cần:

```text
CASCADE_STEP
GOLDEN_TRANSFORM
FREE_SPIN_STATE
```

Vì các dữ liệu này đã nằm trong:

```text
RESULT_MAHJONG2.cascadeSteps[]
RESULT_MAHJONG2.cascadeSteps[].goldenTransforms[]
RESULT_MAHJONG2.freeSpin
```

Frontend tự chạy animation queue từ `RESULT`.

---

# 34. Kết luận

Bản command/response này bám theo backend mới:

```text
Frontend gửi sessionToken.
Backend gọi /game/wallet.
Base Spin: bet → RNG → settle → jackpotWin nếu có.
RESULT có roundId + seamless status.
Balance chỉ update từ INFO/RESULT/ERROR.
Không tự giả định BONUS hoặc JP symbol trên reels.
Không split cascade/golden/freeSpin thành command riêng.
```

Điểm quan trọng nhất cho frontend:

```text
Frontend chỉ render.
Backend xử lý tiền và gameplay.
Balance trong UI lấy từ response, không tự tính.
```

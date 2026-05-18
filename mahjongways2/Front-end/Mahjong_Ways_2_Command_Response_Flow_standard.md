# Mahjong Ways 2 — Command & Response Flow

---

## 1. Cấu trúc & Symbol / Item Mahjong Ways 2

### 1.1. Cấu trúc game

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

### 1.2. Reel layout

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

---

### 1.3. Symbol / Item chính

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

### 1.4. Golden Symbol

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

---

### 1.5. Symbol chưa xác nhận

Hiện chưa có rule chính thức cho các symbol sau trên reels:

```text
BONUS
JP
JACKPOT
```

Vì vậy, không đưa các symbol này vào reel symbol list nếu chưa có rule/asset/source xác nhận.

---

### 1.6. Jackpot

Jackpot nếu có sẽ được xử lý ở tầng **system/economy**, không phải symbol bắt buộc xuất hiện trên board.

Nói cách khác:

```text
Jackpot là reward system.
JP / JACKPOT không phải reel symbol mặc định.
```

Response có thể có object jackpot để báo trạng thái nổ hũ:

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


## 2. Command ID convention

Vì là project độc lập, đề xuất chia command như sau:

|       Range | Ý nghĩa                        |
| ----------: | ------------------------------ |
| `1000–1099` | Auth / connection              |
| `2000–2099` | Client → Server request        |
| `3000–3099` | Server → Client response/event |
|      `3999` | Error                          |

> ID bên dưới là đề xuất protocol. Nếu backend gateway đã có convention khác thì giữ tên command, đổi ID theo gateway.

---

## 3. Command list

### 3.1. Client → Server

| Command                   |     ID | Mục đích             |
| ------------------------- | -----: | -------------------- |
| `LOGIN`                   | `1000` | Xác thực user        |
| `SUBSCRIBE_MAHJONG2`      | `2001` | Vào game / join room |
| `UNSUBSCRIBE_MAHJONG2`    | `2002` | Thoát game           |
| `CHANGE_ROOM_MAHJONG2`    | `2003` | Đổi room / mức cược  |
| `PLAY_MAHJONG2`           | `2004` | Quay 1 lượt          |
| `AUTO_PLAY_MAHJONG2`      | `2005` | Bật auto play        |
| `STOP_AUTO_PLAY_MAHJONG2` | `2006` | Dừng auto play       |
| `MINIMIZE_MAHJONG2`       | `2007` | Thu nhỏ game         |
| `HISTORY_MAHJONG2`        | `2008` | Lấy lịch sử          |
| `PING`                    | `2098` | Giữ kết nối          |
| `LOGOUT`                  | `2099` | Đăng xuất            |

---

### 3.2. Server → Client

| Command                    |     ID | Mục đích                           |
| -------------------------- | -----: | ---------------------------------- |
| `LOGIN_RESULT`             | `3000` | Kết quả login                      |
| `INFO_MAHJONG2`            | `3001` | Game config + room state           |
| `RESULT_MAHJONG2`          | `3002` | Kết quả spin                       |
| `UPDATE_POT_MAHJONG2`      | `3003` | Update jackpot pot nếu bật jackpot |
| `BIG_WIN_MAHJONG2`         | `3004` | Broadcast thắng lớn                |
| `FORCE_STOP_AUTO_MAHJONG2` | `3005` | Server bắt dừng auto               |
| `MINIMIZE_RESULT_MAHJONG2` | `3006` | Kết quả khi minimize               |
| `HISTORY_RESULT_MAHJONG2`  | `3007` | Trả lịch sử                        |
| `PONG`                     | `3098` | Phản hồi ping                      |
| `ERROR`                    | `3999` | Lỗi chuẩn                          |

---

## 4. Full flow tổng quan

```text
LOGIN
↓
SUBSCRIBE_MAHJONG2
↓
INFO_MAHJONG2
↓
CHANGE_ROOM_MAHJONG2 nếu cần
↓
PLAY_MAHJONG2
↓
RESULT_MAHJONG2
↓
UPDATE_POT_MAHJONG2 nếu pot thay đổi
↓
BIG_WIN_MAHJONG2 nếu đủ điều kiện
↓
AUTO_PLAY_MAHJONG2 nếu bật auto
↓
STOP_AUTO_PLAY_MAHJONG2 / FORCE_STOP_AUTO_MAHJONG2
↓
MINIMIZE_MAHJONG2 nếu thu nhỏ
↓
UNSUBSCRIBE_MAHJONG2
```

---

## 5. LOGIN

### Client → Server

```json
{
  "cmd": 1000,
  "token": "USER_TOKEN"
}
```

### Server → Client

```json
{
  "cmd": 3000,
  "success": true,
  "user": {
    "userId": 1001,
    "nickname": "playerA",
    "balance": 1000000
  }
}
```

---

## 6. SUBSCRIBE_MAHJONG2

### Client → Server

```json
{
  "cmd": 2001,
  "roomId": 1
}
```

### Server → Client: INFO_MAHJONG2

```json
{
  "cmd": 3001,

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

## 7. CHANGE_ROOM_MAHJONG2

### Client → Server

```json
{
  "cmd": 2003,
  "roomId": 2
}
```

### Server → Client

```json
{
  "cmd": 3001,

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
    "mode": "BASE",
    "remainingFreeSpin": 0,
    "autoPlay": false,
    "turbo": false
  }
}
```

---

## 8. PLAY_MAHJONG2

### Client → Server

```json
{
  "cmd": 2004,
  "roomId": 1,
  "betSize": 2.5,
  "betLevel": 9,
  "baseBet": 20,
  "turbo": false
}
```

### Bet formula

```text
lineBet = betSize × betLevel
totalBet = lineBet × baseBet
```

Ví dụ:

```text
lineBet = 2.5 × 9 = 22.5
totalBet = 22.5 × 20 = 450
```

---

## 9. RESULT_MAHJONG2 — response chuẩn

### Server → Client

```json
{
  "cmd": 3002,
  "spinId": "SPIN_10001",
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

## 10. Payout rule trong response

Mỗi `win` nên phản ánh đúng công thức backend:

```text
winAmount = payTableValue × lineBet × ways × multiplier
```

Trong đó:

```text
lineBet = betSize × betLevel
totalBet = lineBet × baseBet
```

Không dùng frontend để tính lại tiền thắng. Frontend chỉ render `winAmount`.

---

## 11. Free Spin trigger result

### 3 Scatter

```json
{
  "cmd": 3002,
  "spinId": "SPIN_10002",
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

### 4 Scatter

```json
"freeSpin": {
  "triggered": true,
  "awarded": 12,
  "remaining": 12,
  "retriggered": false,
  "scatterCount": 4
}
```

### 5 Scatter

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

## 12. RESULT trong Free Spin

```json
{
  "cmd": 3002,
  "spinId": "FREE_SPIN_10003",
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
Không deduct bet.
Payout vẫn dùng lineBet của lượt trigger / free spin state.
Multiplier dùng bảng FREE_SPIN: x2, x4, x6, x10.
Reel 3 có Golden rule, trừ WILD và SCATTER.
```

---

## 13. Retrigger Free Spin

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

## 14. UPDATE_POT_MAHJONG2

Gửi khi:

```text
pot thay đổi sau spin
pot reset sau jackpot
client subscribe / change room
```

```json
{
  "cmd": 3003,
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

## 15. BIG_WIN_MAHJONG2

```json
{
  "cmd": 3004,
  "roomId": 1,
  "nickname": "playerA",
  "amount": 5000000,
  "type": "BIG_WIN"
}
```

Nếu là jackpot:

```json
{
  "cmd": 3004,
  "roomId": 1,
  "nickname": "playerA",
  "amount": 12000000,
  "type": "JACKPOT"
}
```

---

## 16. RESULT khi nổ Jackpot

Chỉ dùng nếu project bật jackpot system.

```json
{
  "cmd": 3002,
  "spinId": "SPIN_10004",
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

Lưu ý:

```text
Jackpot là system reward.
Không tự giả định có JP symbol trên reels nếu luật/asset không xác nhận.
```

---

## 17. AUTO_PLAY_MAHJONG2

### Client → Server

```json
{
  "cmd": 2005,
  "roomId": 1,
  "betSize": 2.5,
  "betLevel": 9,
  "baseBet": 20,
  "rounds": 100,
  "turbo": true
}
```

### Server → Client

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

---

## 18. STOP_AUTO_PLAY_MAHJONG2

### Client → Server

```json
{
  "cmd": 2006
}
```

### Server → Client

```json
{
  "cmd": 3005,
  "reason": "USER_STOP"
}
```

---

## 19. FORCE_STOP_AUTO_MAHJONG2

```json
{
  "cmd": 3005,
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

---

## 20. MINIMIZE_MAHJONG2

### Client → Server

```json
{
  "cmd": 2007
}
```

### Server → Client

```json
{
  "cmd": 3006,
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

## 21. HISTORY_MAHJONG2

### Client → Server

```json
{
  "cmd": 2008,
  "fromDate": "2026-05-01",
  "toDate": "2026-05-18",
  "page": 1,
  "size": 20
}
```

### Server → Client

```json
{
  "cmd": 3007,
  "page": 1,
  "size": 20,
  "total": 100,
  "items": [
    {
      "spinId": "SPIN_10001",
      "time": "2026-05-18T10:30:00",
      "roomId": 1,
      "totalBet": 450,
      "totalWin": 1800,
      "mode": "BASE",
      "isJackpot": false
    }
  ]
}
```

---

## 22. UNSUBSCRIBE_MAHJONG2

### Client → Server

```json
{
  "cmd": 2002
}
```

### Server xử lý

```text
remove player khỏi room
stop auto nếu đang chạy
save free spin state nếu còn
```

### Server → Client

```json
{
  "cmd": 2002,
  "success": true
}
```

---

## 23. ERROR response

```json
{
  "cmd": 3999,
  "errorCode": 1001,
  "message": "NOT_ENOUGH_MONEY"
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

---

## 24. Flow tóm tắt theo backend

### Subscribe flow

```text
Client 2001 SUBSCRIBE
↓
Server 3001 INFO
↓
Server 3003 UPDATE_POT nếu jackpot.enabled = true
```

### Play flow

```text
Client 2004 PLAY
↓
Backend validate balance
↓
Backend generate reels 4-5-5-5-4
↓
Backend calculate ways
↓
Backend process cascade
↓
Backend process goldenTransforms
↓
Backend process freeSpin
↓
Backend process jackpot nếu bật
↓
Server 3002 RESULT
↓
Server 3003 UPDATE_POT nếu pot đổi
↓
Server 3004 BIG_WIN nếu đủ điều kiện
```

### Auto play flow

```text
Client 2005 AUTO_PLAY
↓
Server 3002 RESULT
↓
Server 3002 RESULT
↓
Server 3002 RESULT
↓
Client 2006 STOP hoặc Server 3005 FORCE_STOP
```

### Free spin flow

```text
Server 3002 RESULT
freeSpin.triggered = true
state.mode = FREE_SPIN
↓
Client tiếp tục PLAY hoặc server tự consume tùy thiết kế
↓
Server 3002 RESULT mode FREE_SPIN
↓
freeSpin.remaining giảm dần
↓
Nếu retrigger: remaining cộng thêm
↓
Kết thúc: state.mode = BASE
```

---

## 25. Không tạo command riêng cho cascade/golden

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

## 26. Kết luận

Bản command/response này bám sát:

```text
luật chơi Mahjong Ways 2
backend xử lý toàn bộ gameplay
frontend chỉ render theo RESULT payload
```

Các điểm quan trọng nhất:

```text
INFO trả gameConfig/symbol/rule
PLAY trả RESULT đầy đủ
RESULT chứa reels + cascadeSteps + goldenTransforms + freeSpin + jackpot optional
Không split cascade/golden thành nhiều socket command
Không giả định BONUS hoặc JP symbol trên reels
```

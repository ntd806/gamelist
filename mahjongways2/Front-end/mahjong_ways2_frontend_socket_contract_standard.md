---
# Mahjong Ways 2 — Frontend Socket Contract

## 1. Kết nối WebSocket

```txt
WebSocket path: /ws
Default port: 61144
Local URL: ws://127.0.0.1:61144/ws
```

Frontend connect:

```js
const socket = new WebSocket("ws://127.0.0.1:61144/ws");
```

Sau khi `onopen`, frontend gửi command `4003` để subscribe game.

---

## 2. Flow chuẩn từ FE

```txt
1. FE connect WebSocket
2. FE gửi SUBSCRIBE_MAHJONG2 / cmd 4003
3. BE trả INFO_MAHJONG2 / cmd 4009
4. FE render room, betOptions, balance, symbols, config
5. User chọn betOptionId
6. FE gửi PLAY_MAHJONG2 / cmd 4001
7. BE trả:
   - cmd 4001 nếu spin success / pending result
   - cmd 3999 nếu lỗi
8. FE render reels + cascadeSteps
9. FE update balance nếu payoutStatus = SUCCESS
10. FE không update balance từ cmd 3999
```

---

## 3. Common request rule

### 3.1 Mọi request phải có `cmd`

Nếu thiếu `cmd`, backend trả lỗi:

```json
{
  "cmd": 3999,
  "errorCode": 1001,
  "message": "INVALID_REQUEST",
  "balance": 0,
  "payoutStatus": "FAILED"
}
```

### 3.2 Token field được backend nhận

Source `Mahjong2SocketRequestMapper` nhận 3 field:

```txt
sessionToken
session_token
token
```

Ví dụ hợp lệ:

```json
{
  "cmd": 4003,
  "sessionToken": "player-token"
}
```

Hoặc:

```json
{
  "cmd": 4003,
  "token": "player-token"
}
```

### 3.3 FE không cần gửi `userId`, `currency`

Backend lấy `userId` và `currency` từ session token.

FE chỉ gửi token.

---

## 4. Command list

|    CMD | Tên                       | FE gửi?              | Response           |
| -----: | ------------------------- | -------------------- | ------------------ |
| `4001` | `PLAY_MAHJONG2`           | Có                   | `4001` hoặc `3999` |
| `4003` | `SUBSCRIBE_MAHJONG2`      | Có                   | `4009`             |
| `4004` | `UNSUBSCRIBE_MAHJONG2`    | Có                   | `4009`             |
| `4005` | `CHANGE_ROOM_MAHJONG2`    | Có                   | `4009`             |
| `4006` | `AUTO_PLAY_MAHJONG2`      | Có nhưng unsupported | `3999`             |
| `4007` | `STOP_AUTO_PLAY_MAHJONG2` | Có                   | `4008`             |
| `4013` | `MINIMIZE_MAHJONG2`       | Có                   | `4014`             |
| `4015` | `HISTORY_MAHJONG2`        | Có                   | `4016`             |
| `3999` | `ERROR`                   | BE trả lỗi           | -                  |

Các cmd có trong `Mahjong2CommandIds` nhưng không thấy handler thực tế cho FE:

```txt
4002 UPDATE_POT_MAHJONG2
4010 BIG_WIN_MAHJONG2
4011 TOTAL_FREE_SPIN_MAHJONG2
```

---

## 5. SUBSCRIBE_MAHJONG2 — cmd `4003`

### Request FE gửi

```json
{
  "cmd": 4003,
  "sessionToken": "player-token",
  "roomId": 1
}
```

`roomId` optional. Nếu không gửi hoặc `roomId <= 0`, backend chọn default room.

---

### Response BE trả — cmd `4009`

```json
{
  "cmd": 4009,
  "rooms": [
    {
      "roomId": 1,
      "name": "Default Room",
      "enabled": true,
      "defaultBetOptionId": "R1_BS_250_BL_9",
      "minTotalBet": 0.4,
      "maxTotalBet": 500,
      "betSize": 2.5,
      "betLevel": 9,
      "baseBet": 20,
      "lineBet": 22.5,
      "totalBet": 450,
      "pot": 1200000
    }
  ],
  "room": {
    "roomId": 1,
    "name": "Default Room",
    "enabled": true,
    "defaultBetOptionId": "R1_BS_250_BL_9",
    "minTotalBet": 0.4,
    "maxTotalBet": 500,
    "betSize": 2.5,
    "betLevel": 9,
    "baseBet": 20,
    "lineBet": 22.5,
    "totalBet": 450,
    "pot": 1200000
  },
  "betOptions": [
    {
      "betOptionId": "R1_BS_002_BL_1",
      "roomId": 1,
      "betSize": 0.02,
      "betLevel": 1,
      "baseBet": 20,
      "lineBet": 0.02,
      "totalBet": 0.4,
      "displayName": "0.4 / lượt",
      "enabled": true,
      "isMin": true,
      "isMax": false
    },
    {
      "betOptionId": "R1_BS_250_BL_9",
      "roomId": 1,
      "betSize": 2.5,
      "betLevel": 9,
      "baseBet": 20,
      "lineBet": 22.5,
      "totalBet": 450,
      "displayName": "450 / lượt",
      "enabled": true,
      "isMin": false,
      "isMax": false
    },
    {
      "betOptionId": "R1_BS_250_BL_10",
      "roomId": 1,
      "betSize": 2.5,
      "betLevel": 10,
      "baseBet": 20,
      "lineBet": 25,
      "totalBet": 500,
      "displayName": "500 / lượt",
      "enabled": true,
      "isMin": false,
      "isMax": true
    }
  ],
  "gameConfig": {
    "gameCode": "MAHJONG_WAYS_2",
    "reelCount": 5,
    "reelRows": [4, 5, 5, 5, 4],
    "totalWays": 2000,
    "minMatchedReels": 3,
    "winDirection": "LEFT_TO_RIGHT",
    "hasCascade": true,
    "hasGoldenSymbol": true,
    "hasFreeSpin": false,
    "hasJackpot": false
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
    "selectedRoomId": 1,
    "selectedBetOptionId": "R1_BS_250_BL_9",
    "mode": "BASE",
    "remainingFreeSpin": 0,
    "autoPlay": false,
    "turbo": false
  }
}
```

### Giải thích field chính

| Field                             | Ý nghĩa                                     |
| --------------------------------- | ------------------------------------------- |
| `cmd`                             | `4009`, response info game                  |
| `rooms`                           | Danh sách room đang enabled                 |
| `room`                            | Room hiện tại được chọn                     |
| `betOptions`                      | Danh sách mức cược frontend được chọn       |
| `gameConfig.reelRows`             | Layout reel: `[4,5,5,5,4]`                  |
| `symbols`                         | Danh sách symbol để FE map asset            |
| `wildRule`                        | Rule WILD                                   |
| `goldenRule`                      | Rule golden symbol transform thành WILD     |
| `multipliers`                     | Multiplier theo cascade step                |
| `freeSpinRule`                    | Rule free spin, dù hiện `hasFreeSpin=false` |
| `playerState.balance`             | Số dư hiện tại                              |
| `playerState.selectedBetOptionId` | Bet mặc định nên select                     |

---

## 6. CHANGE_ROOM_MAHJONG2 — cmd `4005`

### Request

```json
{
  "cmd": 4005,
  "sessionToken": "player-token",
  "roomId": 1
}
```

### Response

Trả về cùng schema với `SUBSCRIBE_MAHJONG2`, tức `cmd = 4009`.

Nếu `roomId` không tồn tại hoặc room disabled:

```json
{
  "cmd": 3999,
  "errorCode": 1001,
  "message": "INVALID_ROOM",
  "balance": 0,
  "payoutStatus": "FAILED"
}
```

---

## 7. PLAY_MAHJONG2 — cmd `4001`

### Request FE gửi

```json
{
  "cmd": 4001,
  "clientRequestId": "spin-20260521-0001",
  "sessionToken": "player-token",
  "roomId": 1,
  "betOptionId": "R1_BS_250_BL_9",
  "turbo": false
}
```

### Field request

| Field             | Bắt buộc | Ý nghĩa                                     |
| ----------------- | -------: | ------------------------------------------- |
| `cmd`             |       Có | Luôn `4001`                                 |
| `clientRequestId` |       Có | Idempotency key, mỗi spin mới phải unique   |
| `sessionToken`    |       Có | Token user                                  |
| `roomId`          |       Có | Room đang chơi                              |
| `betOptionId`     |       Có | Mức cược lấy từ `betOptions`                |
| `turbo`           |    Không | Default `false`                             |
| `gameCode`        |    Không | Nếu không gửi backend dùng `MAHJONG_WAYS_2` |

### Các field FE không được gửi khi spin

Backend reject nếu request có một trong các field này:

```txt
betSize
betSizeMinor
betLevel
baseBet
lineBet
totalBet
betAmountMinor
```

Ví dụ sai:

```json
{
  "cmd": 4001,
  "clientRequestId": "spin-bad-001",
  "sessionToken": "player-token",
  "roomId": 1,
  "betOptionId": "R1_BS_250_BL_9",
  "totalBet": 450
}
```

Response lỗi:

```json
{
  "cmd": 3999,
  "errorCode": 1001,
  "message": "CLIENT_BET_FIELDS_NOT_ALLOWED",
  "balance": 0,
  "payoutStatus": "FAILED"
}
```

---

## 8. PLAY success response — cmd `4001`

### Sample response có cascade

```json
{
  "cmd": 4001,
  "spinId": "SPIN_abc123",
  "roundId": "RND_MW2_SPIN_abc123",
  "roomId": 1,
  "reels": [
    [
      { "symbol": "ITEM_1", "golden": false },
      { "symbol": "ITEM_4", "golden": false },
      { "symbol": "ITEM_5", "golden": false },
      { "symbol": "ITEM_6", "golden": false }
    ],
    [
      { "symbol": "ITEM_1", "golden": true },
      { "symbol": "ITEM_2", "golden": false },
      { "symbol": "ITEM_3", "golden": false },
      { "symbol": "ITEM_4", "golden": false },
      { "symbol": "ITEM_5", "golden": false }
    ],
    [
      { "symbol": "ITEM_1", "golden": false },
      { "symbol": "ITEM_7", "golden": false },
      { "symbol": "ITEM_6", "golden": false },
      { "symbol": "ITEM_5", "golden": false },
      { "symbol": "ITEM_4", "golden": false }
    ],
    [
      { "symbol": "ITEM_2", "golden": false },
      { "symbol": "ITEM_3", "golden": false },
      { "symbol": "ITEM_4", "golden": false },
      { "symbol": "ITEM_5", "golden": false },
      { "symbol": "ITEM_6", "golden": false }
    ],
    [
      { "symbol": "ITEM_7", "golden": false },
      { "symbol": "ITEM_6", "golden": false },
      { "symbol": "ITEM_5", "golden": false },
      { "symbol": "ITEM_4", "golden": false }
    ]
  ],
  "cascadeSteps": [
    {
      "step": 1,
      "mode": "BASE",
      "multiplier": 1,
      "reelsBefore": [
        [
          { "symbol": "ITEM_1", "golden": false },
          { "symbol": "ITEM_4", "golden": false },
          { "symbol": "ITEM_5", "golden": false },
          { "symbol": "ITEM_6", "golden": false }
        ],
        [
          { "symbol": "ITEM_1", "golden": true },
          { "symbol": "ITEM_2", "golden": false },
          { "symbol": "ITEM_3", "golden": false },
          { "symbol": "ITEM_4", "golden": false },
          { "symbol": "ITEM_5", "golden": false }
        ],
        [
          { "symbol": "ITEM_1", "golden": false },
          { "symbol": "ITEM_7", "golden": false },
          { "symbol": "ITEM_6", "golden": false },
          { "symbol": "ITEM_5", "golden": false },
          { "symbol": "ITEM_4", "golden": false }
        ],
        [
          { "symbol": "ITEM_2", "golden": false },
          { "symbol": "ITEM_3", "golden": false },
          { "symbol": "ITEM_4", "golden": false },
          { "symbol": "ITEM_5", "golden": false },
          { "symbol": "ITEM_6", "golden": false }
        ],
        [
          { "symbol": "ITEM_7", "golden": false },
          { "symbol": "ITEM_6", "golden": false },
          { "symbol": "ITEM_5", "golden": false },
          { "symbol": "ITEM_4", "golden": false }
        ]
      ],
      "wins": [
        {
          "symbol": "ITEM_1",
          "matchedReels": 3,
          "ways": 1,
          "payTableValue": 2,
          "lineBet": 22.5,
          "multiplier": 1,
          "winAmount": 45,
          "positions": [
            { "reel": 0, "row": 0 },
            { "reel": 1, "row": 0 },
            { "reel": 2, "row": 0 }
          ]
        }
      ],
      "removedPositions": [
        { "reel": 0, "row": 0 },
        { "reel": 2, "row": 0 }
      ],
      "goldenTransforms": [
        {
          "position": { "reel": 1, "row": 0 },
          "from": { "symbol": "ITEM_1", "golden": true },
          "to": { "symbol": "WILD", "golden": false }
        }
      ],
      "reelsAfterDrop": [
        [
          { "symbol": "ITEM_7", "golden": false },
          { "symbol": "ITEM_4", "golden": false },
          { "symbol": "ITEM_5", "golden": false },
          { "symbol": "ITEM_6", "golden": false }
        ],
        [
          { "symbol": "WILD", "golden": false },
          { "symbol": "ITEM_2", "golden": false },
          { "symbol": "ITEM_3", "golden": false },
          { "symbol": "ITEM_4", "golden": false },
          { "symbol": "ITEM_5", "golden": false }
        ],
        [
          { "symbol": "ITEM_6", "golden": false },
          { "symbol": "ITEM_7", "golden": false },
          { "symbol": "ITEM_6", "golden": false },
          { "symbol": "ITEM_5", "golden": false },
          { "symbol": "ITEM_4", "golden": false }
        ],
        [
          { "symbol": "ITEM_2", "golden": false },
          { "symbol": "ITEM_3", "golden": false },
          { "symbol": "ITEM_4", "golden": false },
          { "symbol": "ITEM_5", "golden": false },
          { "symbol": "ITEM_6", "golden": false }
        ],
        [
          { "symbol": "ITEM_7", "golden": false },
          { "symbol": "ITEM_6", "golden": false },
          { "symbol": "ITEM_5", "golden": false },
          { "symbol": "ITEM_4", "golden": false }
        ]
      ],
      "stepWin": 45
    }
  ],
  "totalWin": 45,
  "balance": 999595,
  "bet": {
    "roomId": 1,
    "betOptionId": "R1_BS_250_BL_9",
    "betSize": 2.5,
    "betLevel": 9,
    "baseBet": 20,
    "lineBet": 22.5,
    "totalBet": 450
  },
  "seamless": {
    "enabled": true,
    "betTransactionId": "BET_RND_MW2_SPIN_abc123",
    "settleTransactionId": "SETTLE_RND_MW2_SPIN_abc123",
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
    "enabled": false,
    "triggered": false,
    "amount": 0
  },
  "state": {
    "mode": "BASE",
    "pot": 0,
    "bigWin": false,
    "turbo": false,
    "autoPlay": false
  },
  "clientRequestId": "spin-20260521-0001"
}
```

---

## 9. Giải thích PLAY response

### Top-level fields

| Field             | Ý nghĩa                             |
| ----------------- | ----------------------------------- |
| `cmd`             | `4001`, kết quả spin                |
| `spinId`          | ID spin backend tạo                 |
| `roundId`         | ID round dùng cho wallet/settlement |
| `roomId`          | Room đã chơi                        |
| `reels`           | Board ban đầu sau khi spin          |
| `cascadeSteps`    | Danh sách cascade nếu có win        |
| `totalWin`        | Tổng tiền thắng                     |
| `balance`         | Balance sau settle                  |
| `bet`             | Cấu hình cược backend resolve       |
| `seamless`        | Thông tin transaction ví            |
| `freeSpin`        | Trạng thái free spin                |
| `jackpot`         | Trạng thái jackpot                  |
| `state`           | State phụ của game                  |
| `clientRequestId` | Echo lại request id của FE          |

### `reels`

Source type:

```java
List<List<Mahjong2Cell>>
```

Cell:

```json
{
  "symbol": "ITEM_1",
  "golden": false
}
```

Frontend hiểu:

```js
reels[reelIndex][rowIndex]
```

Layout hiện tại:

```txt
reel 0: 4 cells
reel 1: 5 cells
reel 2: 5 cells
reel 3: 5 cells
reel 4: 4 cells
```

### `cascadeSteps`

Mỗi step là một lần:

```txt
win → remove symbol thắng → golden transform nếu có → drop symbol mới
```

| Field              | Ý nghĩa                         |
| ------------------ | ------------------------------- |
| `step`             | Số thứ tự cascade, bắt đầu từ 1 |
| `mode`             | `BASE` hoặc `FREE_SPIN`         |
| `multiplier`       | Multiplier step đó              |
| `reelsBefore`      | Board trước khi remove          |
| `wins`             | Danh sách win ways              |
| `removedPositions` | Vị trí cell bị remove           |
| `goldenTransforms` | Cell golden được đổi thành WILD |
| `reelsAfterDrop`   | Board sau khi drop              |
| `stepWin`          | Tiền thắng của riêng step đó    |

Position đúng trong JSON:

```json
{
  "reel": 0,
  "row": 0
}
```

Không phải `reelIndex`, `rowIndex`.

### Final board

Top-level `reels` là board ban đầu.

Final board lấy như sau:

```js
const finalReels =
  response.cascadeSteps.length > 0
    ? response.cascadeSteps[response.cascadeSteps.length - 1].reelsAfterDrop
    : response.reels;
```

---

## 10. PLAY response không có win

Nếu không có win:

```json
{
  "cmd": 4001,
  "spinId": "SPIN_no_win_001",
  "roundId": "RND_MW2_SPIN_no_win_001",
  "roomId": 1,
  "reels": [
    [
      { "symbol": "ITEM_1", "golden": false },
      { "symbol": "ITEM_2", "golden": false },
      { "symbol": "ITEM_3", "golden": false },
      { "symbol": "ITEM_4", "golden": false }
    ],
    [
      { "symbol": "ITEM_5", "golden": false },
      { "symbol": "ITEM_6", "golden": false },
      { "symbol": "ITEM_7", "golden": false },
      { "symbol": "ITEM_2", "golden": false },
      { "symbol": "ITEM_3", "golden": false }
    ],
    [
      { "symbol": "ITEM_4", "golden": false },
      { "symbol": "ITEM_5", "golden": false },
      { "symbol": "ITEM_6", "golden": false },
      { "symbol": "ITEM_7", "golden": false },
      { "symbol": "ITEM_1", "golden": false }
    ],
    [
      { "symbol": "ITEM_2", "golden": false },
      { "symbol": "ITEM_3", "golden": false },
      { "symbol": "ITEM_4", "golden": false },
      { "symbol": "ITEM_5", "golden": false },
      { "symbol": "ITEM_6", "golden": false }
    ],
    [
      { "symbol": "ITEM_7", "golden": false },
      { "symbol": "ITEM_6", "golden": false },
      { "symbol": "ITEM_5", "golden": false },
      { "symbol": "ITEM_4", "golden": false }
    ]
  ],
  "cascadeSteps": [],
  "totalWin": 0,
  "balance": 999550,
  "bet": {
    "roomId": 1,
    "betOptionId": "R1_BS_250_BL_9",
    "betSize": 2.5,
    "betLevel": 9,
    "baseBet": 20,
    "lineBet": 22.5,
    "totalBet": 450
  },
  "seamless": {
    "enabled": true,
    "betTransactionId": "BET_RND_MW2_SPIN_no_win_001",
    "settleTransactionId": "SETTLE_RND_MW2_SPIN_no_win_001",
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
    "enabled": false,
    "triggered": false,
    "amount": 0
  },
  "state": {
    "mode": "BASE",
    "pot": 0,
    "bigWin": false,
    "turbo": false,
    "autoPlay": false
  },
  "clientRequestId": "spin-20260521-0002"
}
```

---

## 11. Pending / duplicate PLAY response

Nếu FE gửi lại cùng `clientRequestId`, backend xử lý idempotency.

### Duplicate đang pending bet

Response vẫn là `cmd = 4001`:

```json
{
  "cmd": 4001,
  "spinId": "SPIN_pending_001",
  "roundId": "RND_MW2_SPIN_pending_001",
  "roomId": 0,
  "cascadeSteps": [],
  "totalWin": 0,
  "seamless": {
    "enabled": true,
    "betTransactionId": "BET_RND_MW2_SPIN_pending_001",
    "settleTransactionId": "SETTLE_RND_MW2_SPIN_pending_001",
    "payoutStatus": "BET_PENDING"
  },
  "clientRequestId": "spin-20260521-0003"
}
```

Do `spring.jackson.default-property-inclusion = non_null`, các field `null` có thể không xuất hiện.

FE rule:

```txt
payoutStatus = BET_PENDING / SETTLE_PENDING / JACKPOT_PENDING / CREATED
=> không xem là spin success hoàn chỉnh
=> không update balance
=> nên lock spin hoặc hiển thị đang xử lý
```

### Duplicate đã failed

Bản mới trả `cmd = 3999`:

```json
{
  "cmd": 3999,
  "errorCode": 1009,
  "message": "FAILED",
  "balance": 0,
  "payoutStatus": "FAILED",
  "clientRequestId": "spin-20260521-0004",
  "spinId": "SPIN_failed_001",
  "roundId": "RND_MW2_SPIN_failed_001"
}
```

Hoặc:

```json
{
  "cmd": 3999,
  "errorCode": 1009,
  "message": "FAILED_NEED_REVIEW",
  "balance": 0,
  "payoutStatus": "FAILED_NEED_REVIEW",
  "clientRequestId": "spin-20260521-0005",
  "spinId": "SPIN_review_001",
  "roundId": "RND_MW2_SPIN_review_001"
}
```

---

## 12. HISTORY_MAHJONG2 — cmd `4015`

### Request

```json
{
  "cmd": 4015,
  "sessionToken": "player-token",
  "limit": 20
}
```

Rule từ source:

```txt
limit default = 20
limit min = 1
limit max = 50
page / size không được hỗ trợ
```

Nếu gửi `page` hoặc `size` sẽ lỗi.

---

### Response — cmd `4016`

```json
{
  "cmd": 4016,
  "limit": 20,
  "pagination": "limit",
  "items": [
    {
      "spinId": "SPIN_abc123",
      "roundId": "RND_MW2_SPIN_abc123",
      "betOptionId": "R1_BS_250_BL_9",
      "totalBet": 450,
      "totalWin": 45,
      "payoutStatus": "SUCCESS",
      "createdAt": "2026-05-21T10:00:00Z",
      "result": {
        "cmd": 4001,
        "spinId": "SPIN_abc123",
        "roundId": "RND_MW2_SPIN_abc123",
        "roomId": 1,
        "cascadeSteps": [],
        "totalWin": 45,
        "seamless": {
          "enabled": true,
          "payoutStatus": "SUCCESS"
        },
        "clientRequestId": "spin-20260521-0001"
      }
    }
  ]
}
```

### Giải thích field

| Field            | Ý nghĩa                                  |
| ---------------- | ---------------------------------------- |
| `cmd`            | `4016`                                   |
| `limit`          | Limit backend dùng sau khi clamp 1–50    |
| `pagination`     | Luôn `"limit"`                           |
| `items`          | Danh sách lịch sử spin                   |
| `items[].result` | Snapshot `ResultMahjong2Response` đã lưu |

---

## 13. UNSUBSCRIBE_MAHJONG2 — cmd `4004`

### Request

```json
{
  "cmd": 4004,
  "sessionToken": "player-token"
}
```

### Response

```json
{
  "cmd": 4009,
  "subscribed": false
}
```

---

## 14. MINIMIZE_MAHJONG2 — cmd `4013`

### Request

```json
{
  "cmd": 4013,
  "sessionToken": "player-token"
}
```

### Response

```json
{
  "cmd": 4014,
  "success": true
}
```

---

## 15. AUTO_PLAY_MAHJONG2 — cmd `4006`

Auto play hiện **không support** trong source.

### Request

```json
{
  "cmd": 4006,
  "sessionToken": "player-token"
}
```

### Response

```json
{
  "cmd": 3999,
  "errorCode": 1001,
  "message": "AUTO_PLAY_UNSUPPORTED",
  "balance": 0,
  "payoutStatus": "FAILED"
}
```

---

## 16. STOP_AUTO_PLAY_MAHJONG2 — cmd `4007`

### Request

```json
{
  "cmd": 4007,
  "sessionToken": "player-token"
}
```

### Response

```json
{
  "cmd": 4008,
  "reason": "USER_STOP"
}
```

---

## 17. Error response chung — cmd `3999`

Source DTO:

```java
Mahjong2ErrorResponse(
  int cmd,
  int errorCode,
  String message,
  BigDecimal balance,
  String payoutStatus,
  String clientRequestId,
  String spinId,
  String roundId
)
```

Shape:

```json
{
  "cmd": 3999,
  "errorCode": 1001,
  "message": "INVALID_REQUEST",
  "balance": 0,
  "payoutStatus": "FAILED"
}
```

Nếu lỗi có liên quan spin pending/duplicate, có thể có thêm:

```json
{
  "clientRequestId": "spin-xxx",
  "spinId": "SPIN_xxx",
  "roundId": "RND_MW2_SPIN_xxx"
}
```

---

## 18. Các lỗi FE có thể nhận

| Trường hợp                       | Response sample                 |
| -------------------------------- | ------------------------------- |
| Thiếu `cmd`                      | `INVALID_REQUEST`               |
| Command không có handler         | `UNKNOWN_COMMAND`               |
| Token sai/hết hạn                | `INVALID_SESSION_TOKEN`         |
| Thiếu `sessionToken`             | `INVALID_REQUEST`               |
| Thiếu `clientRequestId` khi spin | `INVALID_REQUEST`               |
| Thiếu `roomId` khi spin          | `INVALID_ROOM`                  |
| Room không hợp lệ                | `INVALID_ROOM`                  |
| Bet option không hợp lệ          | `INVALID_BET_OPTION`            |
| FE gửi field bet bị cấm          | `CLIENT_BET_FIELDS_NOT_ALLOWED` |
| Số dư không đủ                   | `INSUFFICIENT_BALANCE`          |
| Spin trước đang pending bet      | `BET_PENDING`                   |
| Settle đang pending              | `SETTLE_PENDING`                |
| Jackpot đang pending             | `JACKPOT_PENDING`               |
| Wallet lỗi cần review            | `FAILED_NEED_REVIEW`            |
| Internal error                   | `INTERNAL_ERROR`                |

### 18.1 Unknown command

Request:

```json
{
  "cmd": 9999,
  "sessionToken": "player-token"
}
```

Response:

```json
{
  "cmd": 3999,
  "errorCode": 1006,
  "message": "UNKNOWN_COMMAND",
  "balance": 0,
  "payoutStatus": "FAILED"
}
```

### 18.2 Invalid session token

Response:

```json
{
  "cmd": 3999,
  "errorCode": 1001,
  "message": "INVALID_SESSION_TOKEN",
  "balance": 0,
  "payoutStatus": "FAILED"
}
```

### 18.3 Invalid room

Response:

```json
{
  "cmd": 3999,
  "errorCode": 1001,
  "message": "INVALID_ROOM",
  "balance": 0,
  "payoutStatus": "FAILED"
}
```

### 18.4 Invalid bet option

Response:

```json
{
  "cmd": 3999,
  "errorCode": 1001,
  "message": "INVALID_BET_OPTION",
  "balance": 0,
  "payoutStatus": "FAILED"
}
```

### 18.5 Insufficient balance

Response:

```json
{
  "cmd": 3999,
  "errorCode": 1002,
  "message": "INSUFFICIENT_BALANCE",
  "balance": 0,
  "payoutStatus": "FAILED"
}
```

### 18.6 Bet pending

Response:

```json
{
  "cmd": 3999,
  "errorCode": 1003,
  "message": "BET_PENDING",
  "balance": 0,
  "payoutStatus": "BET_PENDING",
  "clientRequestId": "spin-20260521-0006",
  "spinId": "SPIN_pending_001",
  "roundId": "RND_MW2_SPIN_pending_001"
}
```

### 18.7 Settle pending

Response:

```json
{
  "cmd": 3999,
  "errorCode": 1004,
  "message": "SETTLE_PENDING",
  "balance": 0,
  "payoutStatus": "SETTLE_PENDING",
  "clientRequestId": "spin-20260521-0007",
  "spinId": "SPIN_settle_pending_001",
  "roundId": "RND_MW2_SPIN_settle_pending_001"
}
```

### 18.8 Failed need review

Response:

```json
{
  "cmd": 3999,
  "errorCode": 1009,
  "message": "FAILED_NEED_REVIEW",
  "balance": 0,
  "payoutStatus": "FAILED_NEED_REVIEW",
  "clientRequestId": "spin-20260521-0008",
  "spinId": "SPIN_review_001",
  "roundId": "RND_MW2_SPIN_review_001"
}
```

---

## 19. FE handling rule

```js
function handleSocketMessage(msg) {
  switch (msg.cmd) {
    case 4009:
      // subscribe / change room / unsubscribe info
      break;

    case 4001:
      // spin result or pending result
      // check msg.seamless?.payoutStatus
      break;

    case 4016:
      // history result
      break;

    case 4014:
      // minimize result
      break;

    case 4008:
      // stop auto result
      break;

    case 3999:
      // error
      // do not update balance from msg.balance
      break;
  }
}
```

Balance rule:

```txt
Chỉ update balance từ cmd=4001 khi seamless.payoutStatus = SUCCESS.
Không update balance từ cmd=3999 vì error.balance trong source luôn là 0.
```

Pending rule:

```txt
BET_PENDING
SETTLE_PENDING
JACKPOT_PENDING
CANCEL_PENDING
FAILED_NEED_REVIEW
CREATED

=> không xem là success
=> không spin tiếp bằng clientRequestId mới ngay
=> nên lock spin / hiển thị đang xử lý
```

Failed rule:

```txt
FAILED
INSUFFICIENT_BALANCE
INVALID_ROOM
INVALID_BET_OPTION
INVALID_REQUEST
INVALID_SESSION_TOKEN

=> request fail rõ ràng
=> FE có thể hiển thị lỗi
=> chỉ spin lại bằng clientRequestId mới sau khi user sửa lỗi / refresh session / nạp tiền
```

---

## 20. Minimal FE commands

```js
const CMD = {
  PLAY: 4001,
  SUBSCRIBE: 4003,
  UNSUBSCRIBE: 4004,
  CHANGE_ROOM: 4005,
  AUTO_PLAY: 4006,
  STOP_AUTO_PLAY: 4007,
  MINIMIZE: 4013,
  HISTORY: 4015
};

socket.send(JSON.stringify({
  cmd: CMD.SUBSCRIBE,
  sessionToken: token,
  roomId: 1
}));

socket.send(JSON.stringify({
  cmd: CMD.PLAY,
  clientRequestId: crypto.randomUUID(),
  sessionToken: token,
  roomId: 1,
  betOptionId: "R1_BS_250_BL_9",
  turbo: false
}));

socket.send(JSON.stringify({
  cmd: CMD.HISTORY,
  sessionToken: token,
  limit: 20
}));

socket.send(JSON.stringify({
  cmd: CMD.CHANGE_ROOM,
  sessionToken: token,
  roomId: 1
}));

socket.send(JSON.stringify({
  cmd: CMD.UNSUBSCRIBE,
  sessionToken: token
}));

socket.send(JSON.stringify({
  cmd: CMD.MINIMIZE,
  sessionToken: token
}));
```

---


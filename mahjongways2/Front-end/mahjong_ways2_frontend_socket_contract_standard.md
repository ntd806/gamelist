# Mahjong Ways 2 — Frontend Socket Contract

---

## 1. Kết nối WebSocket

Thông tin kết nối hiện tại:

```txt
WebSocket path: /ws
Default public port: 61144
Local URL: ws://127.0.0.1:61144/ws
```

Frontend connect:

```js
const socket = new WebSocket("ws://127.0.0.1:61144/ws");
```

Sau khi `onopen`, frontend gửi `cmd = 4003` để subscribe game.

```js
socket.onopen = () => {
  socket.send(JSON.stringify({
    cmd: 4003,
    sessionToken: token,
    roomId: 1
  }));
};
```

---

## 2. Flow chuẩn từ frontend

```txt
1. FE connect WebSocket.
2. FE gửi SUBSCRIBE_MAHJONG2 / cmd 4003.
3. BE trả INFO_MAHJONG2 / cmd 4009.
4. FE render rooms, room hiện tại, betOptions, symbols, gameConfig, animationConfig, balance.
5. User chọn betOptionId từ betOptions backend trả về.
6. FE gửi PLAY_MAHJONG2 / cmd 4001.
7. BE trả:
   - cmd 4001 nếu spin thành công hoặc pending result.
   - cmd 3999 nếu lỗi.
8. FE render reels, animationReels, cascadeSteps.
9. FE update balance chỉ khi cmd = 4001 và seamless.payoutStatus = SUCCESS.
10. FE không update balance từ cmd = 3999.
```

---

## 3. Common request rules

### 3.1. Mọi request phải có `cmd`

Nếu thiếu `cmd`, lỗi trả về là `3999 INVALID_REQUEST`.

Response có dạng:

```json
{
  "cmd": 3999,
  "errorCode": 1001,
  "message": "INVALID_REQUEST",
  "payoutStatus": "FAILED"
}
```

Lưu ý: field nào là `null` có thể không xuất hiện trong JSON. Ví dụ `balance` trong error response hiện thường là `null`, nên có thể bị omit.

---

### 3.2. Token field backend nhận

Backend nhận token qua 3 field:

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

Hoặc:

```json
{
  "cmd": 4003,
  "session_token": "player-token"
}
```

Nếu thiếu token hoặc token rỗng, backend trả `3999 INVALID_REQUEST`.

Nếu token có nhưng session resolver reject, backend trả `3999 INVALID_SESSION_TOKEN`.

---

### 3.3. FE không cần gửi `userId`, `currency`, `partnerCode`

Backend resolve các thông tin này từ session token:

```txt
userId
currency
partnerCode
```

Frontend chỉ cần gửi token. Khi spin, backend không lấy `userId`, `currency`, `partnerCode` từ request body làm nguồn tin cậy.

---

## 4. Command list hiện tại

| CMD | Tên | FE gửi? | Response |
|---:|---|---|---|
| `4001` | `PLAY_MAHJONG2` | Có | `4001` hoặc `3999` |
| `4002` | `UPDATE_POT_MAHJONG2` | Không | `3999 UNKNOWN_COMMAND` nếu gửi |
| `4003` | `SUBSCRIBE_MAHJONG2` | Có | `4009` |
| `4004` | `UNSUBSCRIBE_MAHJONG2` | Có | `4009` với `subscribed=false` |
| `4005` | `CHANGE_ROOM_MAHJONG2` | Có | `4009` |
| `4006` | `AUTO_PLAY_MAHJONG2` | Có nhưng unsupported | `3999 AUTO_PLAY_UNSUPPORTED` |
| `4007` | `STOP_AUTO_PLAY_MAHJONG2` | Có | `4008` |
| `4008` | `FORCE_STOP_AUTO_MAHJONG2` | Response only | `{ "cmd": 4008, "reason": "USER_STOP" }` |
| `4009` | `INFO_MAHJONG2` | Response only | Subscribe/change room response |
| `4010` | `BIG_WIN_MAHJONG2` | Không | `3999 UNKNOWN_COMMAND` nếu gửi |
| `4011` | `TOTAL_FREE_SPIN_MAHJONG2` | Không | `3999 UNKNOWN_COMMAND` nếu gửi |
| `4013` | `MINIMIZE_MAHJONG2` | Có | `4014` |
| `4014` | `MINIMIZE_RESULT_MAHJONG2` | Response only | `{ "cmd": 4014, "success": true }` |
| `4015` | `HISTORY_MAHJONG2` | Có | `4016` |
| `4016` | `HISTORY_RESULT_MAHJONG2` | Response only | History response |
| `3999` | `ERROR` | Response only | Error response |

---

## 5. SUBSCRIBE_MAHJONG2 — cmd `4003`

### 5.1. Request

```json
{
  "cmd": 4003,
  "sessionToken": "player-token",
  "roomId": 1
}
```

### Field request

| Field | Bắt buộc | Ý nghĩa |
|---|---:|---|
| `cmd` | Có | Luôn là `4003` |
| `sessionToken` / `session_token` / `token` | Có | Token player |
| `roomId` | Không | Nếu thiếu hoặc `<= 0`, backend chọn room default từ catalog |

---

### 5.2. Response — cmd `4009`

Response `4009` là response init game khi subscribe/change room thành công.

Shape hiện tại:

```json
{
  "cmd": 4009,
  "rooms": [
    {
      "roomId": 1,
      "name": "Default Room",
      "enabled": true,
      "defaultBetOptionId": "R1_BS_250_BL_9",
      "minTotalBet": 2,
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
    "minTotalBet": 2,
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
      "betOptionId": "R1_BS_010_BL_1",
      "roomId": 1,
      "betSize": 0.1,
      "betLevel": 1,
      "baseBet": 20,
      "lineBet": 0.1,
      "totalBet": 2,
      "displayName": "2 / lượt",
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
  },
  "animationConfig": {
    "enabled": true,
    "mathLayout": [4, 5, 5, 5, 4],
    "displayLayout": [6, 5, 5, 5, 6],
    "displayOnlyPositions": [
      { "col": 0, "row": 0 },
      { "col": 0, "row": 5 },
      { "col": 4, "row": 0 },
      { "col": 4, "row": 5 }
    ],
    "displayOnlyAffectsMath": false
  }
}
```

### 5.3. Giải thích field `4009`

| Field | Ý nghĩa |
|---|---|
| `cmd` | Luôn là `4009` |
| `rooms` | Danh sách room enabled |
| `room` | Room hiện tại được chọn |
| `betOptions` | Danh sách mức cược FE được chọn |
| `gameConfig.gameCode` | Mã game, hiện là `MAHJONG_WAYS_2` |
| `gameConfig.reelRows` | Layout math thật: `[4,5,5,5,4]` |
| `gameConfig.totalWays` | Tổng ways: `2000` |
| `gameConfig.minMatchedReels` | Số reel tối thiểu để có win, hiện là `3` |
| `gameConfig.winDirection` | Hướng tính win, hiện là `LEFT_TO_RIGHT` |
| `symbols` | Danh sách symbol để FE map asset |
| `wildRule` | Rule WILD |
| `goldenRule` | Rule golden symbol transform thành WILD |
| `multipliers` | Multiplier theo cascade step |
| `freeSpinRule` | Rule free spin config |
| `playerState.balance` | Số dư hiện tại lấy qua money service |
| `playerState.selectedBetOptionId` | Bet option default FE nên select |
| `animationConfig` | Config visual-only cho animation reels |

---

## 6. Animation contract hiện tại

Contract hiện tại đã có animation bằng các field sau:

```txt
4009:
- animationConfig

4001:
- animationReels
- animationMeta

cascadeSteps[]:
- animationReelsBeforeDrop
- animationReelsAfterDrop
- animationMeta
```

Contract hiện tại **không có field**:

```txt
displayReels
```

Vì vậy frontend chỉ nên dùng `animationReels`, không dùng `displayReels`.

---

### 6.1. `animationConfig` trong `4009`

`animationConfig` cho FE biết layout nào là math thật và layout nào chỉ để render:

```json
{
  "enabled": true,
  "mathLayout": [4, 5, 5, 5, 4],
  "displayLayout": [6, 5, 5, 5, 6],
  "displayOnlyPositions": [
    { "col": 0, "row": 0 },
    { "col": 0, "row": 5 },
    { "col": 4, "row": 0 },
    { "col": 4, "row": 5 }
  ],
  "displayOnlyAffectsMath": false
}
```

Ý nghĩa:

| Field | Ý nghĩa |
|---|---|
| `enabled` | Animation reels có bật không |
| `mathLayout` | Layout thật để backend tính game |
| `displayLayout` | Layout FE render animation |
| `displayOnlyPositions` | Các ô chỉ để hiển thị, không tính game |
| `displayOnlyAffectsMath` | Luôn `false` theo code hiện tại |

Mapping hiện tại:

```txt
Column 0:
- display row 0 = displayOnly top buffer
- display row 1 = math row 0
- display row 2 = math row 1
- display row 3 = math row 2
- display row 4 = math row 3
- display row 5 = displayOnly bottom buffer

Columns 1,2,3:
- display rows 0..4 = math rows 0..4

Column 4:
- display row 0 = displayOnly top buffer
- display row 1 = math row 0
- display row 2 = math row 1
- display row 3 = math row 2
- display row 4 = math row 3
- display row 5 = displayOnly bottom buffer
```

---

### 6.2. `animationReels` trong `4001`

`animationReels` là visual board FE dùng để render layout `[6,5,5,5,6]`.

Cell shape:

```json
{
  "symbol": "ITEM_1",
  "displayOnly": false
}
```

Ô buffer display-only:

```json
{
  "symbol": "ITEM_7",
  "displayOnly": true
}
```

Lưu ý quan trọng:

```txt
Animation cell chỉ có:
- symbol
- displayOnly

Animation cell không có field `golden`.
```

Nếu FE cần render golden state, dùng `reels` / `cascadeSteps.reelsBefore` / `cascadeSteps.reelsAfterDrop` là nguồn math truth có `golden`.

---

### 6.3. `animationMeta` trong `4001`

Shape hiện tại:

```json
{
  "mathLayout": [4, 5, 5, 5, 4],
  "displayLayout": [6, 5, 5, 5, 6],
  "displayOnlyPositions": [
    { "col": 0, "row": 0 },
    { "col": 0, "row": 5 },
    { "col": 4, "row": 0 },
    { "col": 4, "row": 5 }
  ]
}
```

Khác với `animationConfig`, `animationMeta` trong `4001` **không có** field `enabled` và **không có** field `displayOnlyAffectsMath`.

---

### 6.4. Cách tạo animation symbols

Quy tắc tạo `animationReels` hiện tại:

```txt
- animationReels được tạo từ reels math sau khi có result.
- Không thay đổi reels math.
- Không thay đổi cascadeSteps math.
- Không dùng gameplay RNG để tạo buffer.
- Buffer top lấy symbol của cell đầu trong math reel.
- Buffer bottom lấy symbol của cell cuối trong math reel.
```

Nghĩa là với cột 0 có 4 math cells:

```txt
math reel 0 = [A, B, C, D]
animation reel 0 = [A(displayOnly), A, B, C, D, D(displayOnly)]
```

Với cột 4 có 4 math cells:

```txt
math reel 4 = [E, F, G, H]
animation reel 4 = [E(displayOnly), E, F, G, H, H(displayOnly)]
```

---

### 6.5. Rule bắt buộc cho FE

```txt
FE dùng reels để biết kết quả thật.
FE dùng animationReels để render animation.
FE không được dùng animationReels để tự tính thắng.
FE không được đếm scatter/freeSpin/jackpot từ animationReels.
FE không được highlight removedPositions trên ô displayOnly.
```

Các logic sau chỉ được dựa vào backend response math/result:

```txt
win
ways
cascade
removedPositions
goldenTransforms
freeSpin
jackpot
totalWin
balance
```

---

## 7. CHANGE_ROOM_MAHJONG2 — cmd `4005`

### Request

```json
{
  "cmd": 4005,
  "sessionToken": "player-token",
  "roomId": 1
}
```

`CHANGE_ROOM_MAHJONG2` trả response `4009` và có cùng schema với subscribe, bao gồm `animationConfig`.

Nếu room không hợp lệ, backend trả `3999`.

---

## 8. UNSUBSCRIBE_MAHJONG2 — cmd `4004`

### Request

```json
{
  "cmd": 4004,
  "sessionToken": "player-token"
}
```

### Response

Response:

```json
{
  "cmd": 4009,
  "subscribed": false
}
```

Do response là map riêng, các field như `rooms`, `room`, `betOptions`, `gameConfig`, `animationConfig` không xuất hiện trong unsubscribe response.

---

## 9. PLAY_MAHJONG2 — cmd `4001`

### 9.1. Request FE gửi

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

### 9.2. Field request

| Field | Bắt buộc | Ý nghĩa |
|---|---:|---|
| `cmd` | Có | Luôn là `4001` |
| `clientRequestId` | Có | Idempotency key. Mỗi spin mới phải unique |
| `sessionToken` / `session_token` / `token` | Có | Token player |
| `roomId` | Có | Room đang chơi |
| `betOptionId` | Có | Lấy từ `betOptions` backend trả về ở `4009` |
| `turbo` | Không | Default `false` |
| `gameCode` | Không | Nếu không gửi, backend dùng config game code hiện tại |

### 9.3. Các field FE không được gửi khi spin

Nếu request spin có bất kỳ field nào sau đây, backend trả lỗi:

```txt
betSize
betSizeMinor
betLevel
baseBet
lineBet
totalBet
betAmountMinor
```

Ví dụ request sai:

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
  "payoutStatus": "FAILED"
}
```

### 9.4. Nếu thiếu `roomId`

`roomId` là bắt buộc trong `4001`. Nếu thiếu, lỗi trả về là `3999 INVALID_ROOM`.

Response:

```json
{
  "cmd": 3999,
  "errorCode": 1001,
  "message": "INVALID_ROOM",
  "payoutStatus": "FAILED"
}
```

### 9.5. Nếu thiếu `clientRequestId`

Nếu thiếu `clientRequestId`, lỗi trả về là `3999 INVALID_REQUEST`.

Response:

```json
{
  "cmd": 3999,
  "errorCode": 1001,
  "message": "INVALID_REQUEST",
  "payoutStatus": "FAILED"
}
```

---

## 10. PLAY success response — cmd `4001`

Response `4001` gồm result math và các field animation nếu animation reels đang bật.

`animationReels` được tạo thêm từ result math, không thay thế `reels`.

---

### 10.1. Sample response có animation reels

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
  "animationReels": [
    [
      { "symbol": "ITEM_1", "displayOnly": true },
      { "symbol": "ITEM_1", "displayOnly": false },
      { "symbol": "ITEM_4", "displayOnly": false },
      { "symbol": "ITEM_5", "displayOnly": false },
      { "symbol": "ITEM_6", "displayOnly": false },
      { "symbol": "ITEM_6", "displayOnly": true }
    ],
    [
      { "symbol": "ITEM_1", "displayOnly": false },
      { "symbol": "ITEM_2", "displayOnly": false },
      { "symbol": "ITEM_3", "displayOnly": false },
      { "symbol": "ITEM_4", "displayOnly": false },
      { "symbol": "ITEM_5", "displayOnly": false }
    ],
    [
      { "symbol": "ITEM_1", "displayOnly": false },
      { "symbol": "ITEM_7", "displayOnly": false },
      { "symbol": "ITEM_6", "displayOnly": false },
      { "symbol": "ITEM_5", "displayOnly": false },
      { "symbol": "ITEM_4", "displayOnly": false }
    ],
    [
      { "symbol": "ITEM_2", "displayOnly": false },
      { "symbol": "ITEM_3", "displayOnly": false },
      { "symbol": "ITEM_4", "displayOnly": false },
      { "symbol": "ITEM_5", "displayOnly": false },
      { "symbol": "ITEM_6", "displayOnly": false }
    ],
    [
      { "symbol": "ITEM_7", "displayOnly": true },
      { "symbol": "ITEM_7", "displayOnly": false },
      { "symbol": "ITEM_6", "displayOnly": false },
      { "symbol": "ITEM_5", "displayOnly": false },
      { "symbol": "ITEM_4", "displayOnly": false },
      { "symbol": "ITEM_4", "displayOnly": true }
    ]
  ],
  "animationMeta": {
    "mathLayout": [4, 5, 5, 5, 4],
    "displayLayout": [6, 5, 5, 5, 6],
    "displayOnlyPositions": [
      { "col": 0, "row": 0 },
      { "col": 0, "row": 5 },
      { "col": 4, "row": 0 },
      { "col": 4, "row": 5 }
    ]
  },
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
    "type": null,
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

Nếu field `jackpot.type` là `null`, field này có thể không xuất hiện trong JSON.

---

### 10.2. Giải thích top-level field `4001`

| Field | Ý nghĩa |
|---|---|
| `cmd` | Luôn là `4001` nếu spin response thành công/pending |
| `spinId` | ID spin backend tạo |
| `roundId` | ID round dùng cho wallet/settlement |
| `roomId` | Room đã chơi |
| `reels` | Board math thật ban đầu sau khi spin |
| `animationReels` | Board visual-only để FE render animation |
| `animationMeta` | Metadata mapping math/display layout |
| `cascadeSteps` | Danh sách cascade nếu có |
| `totalWin` | Tổng tiền thắng |
| `balance` | Balance sau settle nếu có |
| `bet` | Cấu hình cược backend đã resolve từ `betOptionId` |
| `seamless` | Thông tin transaction ví |
| `freeSpin` | Trạng thái free spin |
| `jackpot` | Trạng thái jackpot |
| `state` | State phụ của game |
| `clientRequestId` | Echo lại request id của FE |

---

### 10.3. `reels`


Cell shape:

```json
{
  "symbol": "ITEM_1",
  "golden": false
}
```

Layout hiện tại theo config:

```txt
reel 0: 4 cells
reel 1: 5 cells
reel 2: 5 cells
reel 3: 5 cells
reel 4: 4 cells
```

Tức là:

```txt
[4, 5, 5, 5, 4]
```

`reels` là math truth. FE không được thay `reels` bằng `animationReels` để tính game.

---

### 10.4. `animationReels`


Cell shape:

```json
{
  "symbol": "ITEM_1",
  "displayOnly": false
}
```

Layout:

```txt
[6, 5, 5, 5, 6]
```

`displayOnly=true` nghĩa là ô chỉ để render, không phải ô math.

---

### 10.5. `cascadeSteps`

Mỗi cascade step có shape:

```json
{
  "step": 1,
  "mode": "BASE",
  "multiplier": 1,
  "reelsBefore": [],
  "animationReelsBeforeDrop": [],
  "wins": [],
  "removedPositions": [],
  "goldenTransforms": [],
  "reelsAfterDrop": [],
  "animationReelsAfterDrop": [],
  "animationMeta": {},
  "stepWin": 45
}
```

| Field | Ý nghĩa |
|---|---|
| `step` | Số thứ tự cascade, bắt đầu từ 1 |
| `mode` | `BASE` hoặc `FREE_SPIN` |
| `multiplier` | Multiplier step đó |
| `reelsBefore` | Math board trước khi remove |
| `animationReelsBeforeDrop` | Visual board trước drop |
| `wins` | Danh sách win ways |
| `removedPositions` | Vị trí math cell bị remove |
| `goldenTransforms` | Cell golden được đổi thành WILD |
| `reelsAfterDrop` | Math board sau khi drop |
| `animationReelsAfterDrop` | Visual board sau drop |
| `animationMeta` | Metadata layout cho step |
| `stepWin` | Tiền thắng riêng step đó |

Position trong JSON dùng field:

```json
{
  "reel": 0,
  "row": 0
}
```

Không phải:

```txt
reelIndex
rowIndex
```

`removedPositions` luôn refer tới math layout `[4,5,5,5,4]`, không refer tới display-only rows.

---

### 10.6. Final board

Top-level `reels` là board ban đầu của spin.

Final math board lấy như sau:

```js
const finalReels =
  response.cascadeSteps && response.cascadeSteps.length > 0
    ? response.cascadeSteps[response.cascadeSteps.length - 1].reelsAfterDrop
    : response.reels;
```

Final visual board lấy như sau:

```js
const finalAnimationReels =
  response.cascadeSteps && response.cascadeSteps.length > 0
    ? response.cascadeSteps[response.cascadeSteps.length - 1].animationReelsAfterDrop
    : response.animationReels;
```

---

## 11. PLAY response không có win

Nếu không có win:

```txt
cascadeSteps = []
totalWin = 0
```

Response vẫn có thể có:

```txt
animationReels
animationMeta
```

nếu `mahjong2.animation-reels.enabled=true`.

---

## 12. Pending / duplicate PLAY response

Nếu FE gửi lại cùng `clientRequestId`, backend xử lý idempotency.

### 12.1. Pending response dạng `4001`

Một số pending/idempotency path có thể trả `cmd = 4001` với `seamless.payoutStatus` là trạng thái pending.

Ví dụ:

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

Do non-null inclusion, các field `null` có thể không xuất hiện.

FE rule:

```txt
payoutStatus = BET_PENDING / SETTLE_PENDING / JACKPOT_PENDING / CREATED / CANCEL_PENDING
=> không xem là spin success hoàn chỉnh
=> không update balance
=> nên lock spin hoặc hiển thị đang xử lý
```

---

### 12.2. Duplicate đã failed

Nếu duplicate failed được map qua error path, response có thể là `3999`.

Ví dụ:

```json
{
  "cmd": 3999,
  "errorCode": 1009,
  "message": "FAILED",
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
  "payoutStatus": "FAILED_NEED_REVIEW",
  "clientRequestId": "spin-20260521-0005",
  "spinId": "SPIN_review_001",
  "roundId": "RND_MW2_SPIN_review_001"
}
```

---

## 13. HISTORY_MAHJONG2 — cmd `4015`

### 13.1. Request

```json
{
  "cmd": 4015,
  "sessionToken": "player-token",
  "limit": 20
}
```

Rule history hiện tại:

```txt
limit default = 20
limit min = 1
limit max = 50
page / size không được hỗ trợ
```

Nếu gửi `page` hoặc `size`, backend trả `3999 INVALID_REQUEST`.

---

### 13.2. Response — cmd `4016`

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
        "animationReels": [],
        "animationMeta": {
          "mathLayout": [4, 5, 5, 5, 4],
          "displayLayout": [6, 5, 5, 5, 6],
          "displayOnlyPositions": [
            { "col": 0, "row": 0 },
            { "col": 0, "row": 5 },
            { "col": 4, "row": 0 },
            { "col": 4, "row": 5 }
          ]
        },
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

`items[].result` là snapshot kết quả spin. Nếu có full response, result có thể bao gồm `animationReels` / `animationMeta`. Nếu chỉ có summary fallback, result chỉ có summary fields và có thể không có full `reels`.

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

Auto play hiện không support.

### Request

```json
{
  "cmd": 4006,
  "sessionToken": "player-token"
}
```

### Response

Response:

```json
{
  "cmd": 3999,
  "errorCode": 1001,
  "message": "AUTO_PLAY_UNSUPPORTED",
  "payoutStatus": "FAILED"
}
```

`balance` được set `null`, nên với non-null inclusion có thể không xuất hiện.

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

Shape thường gặp:

```json
{
  "cmd": 3999,
  "errorCode": 1001,
  "message": "INVALID_REQUEST",
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

Lưu ý:

```txt
balance trong error response hiện thường là null.
Do non_null config, FE không nên kỳ vọng error.balance luôn có mặt.
FE không nên update balance từ cmd = 3999.
```

---

## 18. Các lỗi FE có thể nhận

| Trường hợp | errorCode | message | payoutStatus |
|---|---:|---|---|
| Thiếu `cmd` | `1001` | `INVALID_REQUEST` | `FAILED` |
| Command không có handler | `1006` | `UNKNOWN_COMMAND` | `FAILED` |
| Token sai/hết hạn | `1001` | `INVALID_SESSION_TOKEN` | `FAILED` |
| Thiếu `sessionToken` | `1001` | `INVALID_REQUEST` | `FAILED` |
| Thiếu `clientRequestId` khi spin | `1001` | `INVALID_REQUEST` | `FAILED` |
| Thiếu `roomId` khi spin | `1001` | `INVALID_ROOM` | `FAILED` |
| Room không hợp lệ / disabled | `1001` | `INVALID_ROOM` hoặc `ROOM_DISABLED` | `FAILED` |
| Bet option không hợp lệ | `1001` | `INVALID_BET_OPTION` | `FAILED` |
| FE gửi field bet bị cấm | `1001` | `CLIENT_BET_FIELDS_NOT_ALLOWED` | `FAILED` |
| Số dư không đủ | `1002` | `INSUFFICIENT_BALANCE` | `FAILED` |
| Active spin đang tồn tại | `1003` | `ACTIVE_SPIN_ALREADY_EXISTS` | `BET_PENDING` |
| Bet pending | `1003` | `BET_PENDING` | `BET_PENDING` |
| Settle pending | `1004` | `SETTLE_PENDING` | `SETTLE_PENDING` |
| Jackpot pending | `1005` | `JACKPOT_PENDING` | `JACKPOT_PENDING` |
| Seamless timeout / 5xx / malformed | `1009` | Theo code lỗi | `FAILED_NEED_REVIEW` |
| Internal error | `1099` | `INTERNAL_ERROR` | `FAILED_NEED_REVIEW` |

---

## 19. FE handling rule

```js
function handleSocketMessage(msg) {
  switch (msg.cmd) {
    case 4009:
      // subscribe / change room / unsubscribe info
      // if msg.animationConfig exists, use it for visual layout metadata
      break;

    case 4001:
      // spin result or pending result
      // render msg.reels as math board
      // render msg.animationReels if present for animation board
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
Chỉ update balance từ cmd = 4001 khi seamless.payoutStatus = SUCCESS.
Không update balance từ cmd = 3999.
```

Pending rule:

```txt
BET_PENDING
SETTLE_PENDING
JACKPOT_PENDING
CANCEL_PENDING
FAILED_NEED_REVIEW
CREATED

=> không xem là success hoàn chỉnh
=> không update balance
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
UNKNOWN_COMMAND

=> request fail rõ ràng
=> FE có thể hiển thị lỗi
=> chỉ spin lại bằng clientRequestId mới sau khi user sửa lỗi / refresh session / nạp tiền
```

Animation rule:

```txt
reels = math truth [4,5,5,5,4]
animationReels = visual-only [6,5,5,5,6]
animationMeta = mapping metadata

FE không được tính thắng từ animationReels.
FE không được đếm scatter/freeSpin/jackpot từ animationReels.
FE chỉ dùng animationReels để render animation.
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

## 21. Checklist FE cần nhớ

```txt
[ ] Lấy betOptionId từ 4009.betOptions, không tự tính bet.
[ ] Không gửi totalBet/betSize/betLevel/baseBet/lineBet/betAmountMinor khi spin.
[ ] Dùng 4009.symbols để map symbol code sang assetKey.
[ ] Dùng reels cho kết quả thật.
[ ] Dùng animationReels nếu có để render animation.
[ ] Không dùng animationReels để tính thắng.
[ ] Chỉ update balance từ 4001 SUCCESS.
[ ] Không update balance từ 3999.
[ ] Với pending payoutStatus, khóa spin và hiển thị đang xử lý.
[ ] Không gửi page/size cho history; chỉ gửi limit.
```


## sample response 4001 có ăn line/ways và có cascade sập xuống
---

# Response `4001` mới — FE-only animation contract

```json
{
  "cmd": 4001,
  "spinId": "SPIN_SAMPLE_001",
  "roundId": "RND_MW2_SPIN_SAMPLE_001",
  "roomId": 1,

  "animationMeta": {
    "mathLayout": [4, 5, 5, 5, 4],
    "displayLayout": [6, 5, 5, 5, 6],
    "rowOrder": "TOP_TO_BOTTOM",
    "displayOnlyPositions": [
      { "col": 0, "row": 0 },
      { "col": 0, "row": 5 },
      { "col": 4, "row": 0 },
      { "col": 4, "row": 5 }
    ]
  },

  "animationReels": [
    [
      { "cellId": "s0-c0-buffer-top", "symbol": "ITEM_5", "displayOnly": true, "golden": false, "source": "BUFFER" },
      { "cellId": "s0-c0-r1", "symbol": "ITEM_5", "displayOnly": false, "golden": false, "source": "MATH" },
      { "cellId": "s0-c0-r2", "symbol": "ITEM_2", "displayOnly": false, "golden": false, "source": "MATH" },
      { "cellId": "s0-c0-r3", "symbol": "ITEM_5", "displayOnly": false, "golden": false, "source": "MATH" },
      { "cellId": "s0-c0-r4", "symbol": "ITEM_7", "displayOnly": false, "golden": false, "source": "MATH" },
      { "cellId": "s0-c0-buffer-bottom", "symbol": "ITEM_7", "displayOnly": true, "golden": false, "source": "BUFFER" }
    ],
    [
      { "cellId": "s0-c1-r0", "symbol": "ITEM_1", "displayOnly": false, "golden": false, "source": "MATH" },
      { "cellId": "s0-c1-r1", "symbol": "ITEM_3", "displayOnly": false, "golden": false, "source": "MATH" },
      { "cellId": "s0-c1-r2", "symbol": "ITEM_6", "displayOnly": false, "golden": false, "source": "MATH" },
      { "cellId": "s0-c1-r3", "symbol": "ITEM_7", "displayOnly": false, "golden": false, "source": "MATH" },
      { "cellId": "s0-c1-r4", "symbol": "ITEM_4", "displayOnly": false, "golden": false, "source": "MATH" }
    ],
    [
      { "cellId": "s0-c2-r0", "symbol": "ITEM_2", "displayOnly": false, "golden": false, "source": "MATH" },
      { "cellId": "s0-c2-r1", "symbol": "ITEM_7", "displayOnly": false, "golden": false, "source": "MATH" },
      { "cellId": "s0-c2-r2", "symbol": "ITEM_5", "displayOnly": false, "golden": false, "source": "MATH" },
      { "cellId": "s0-c2-r3", "symbol": "ITEM_2", "displayOnly": false, "golden": false, "source": "MATH" },
      { "cellId": "s0-c2-r4", "symbol": "ITEM_4", "displayOnly": false, "golden": false, "source": "MATH" }
    ],
    [
      { "cellId": "s0-c3-r0", "symbol": "ITEM_2", "displayOnly": false, "golden": false, "source": "MATH" },
      { "cellId": "s0-c3-r1", "symbol": "ITEM_3", "displayOnly": false, "golden": false, "source": "MATH" },
      { "cellId": "s0-c3-r2", "symbol": "ITEM_3", "displayOnly": false, "golden": false, "source": "MATH" },
      { "cellId": "s0-c3-r3", "symbol": "ITEM_4", "displayOnly": false, "golden": false, "source": "MATH" },
      { "cellId": "s0-c3-r4", "symbol": "ITEM_3", "displayOnly": false, "golden": false, "source": "MATH" }
    ],
    [
      { "cellId": "s0-c4-buffer-top", "symbol": "ITEM_2", "displayOnly": true, "golden": false, "source": "BUFFER" },
      { "cellId": "s0-c4-r1", "symbol": "ITEM_2", "displayOnly": false, "golden": false, "source": "MATH" },
      { "cellId": "s0-c4-r2", "symbol": "ITEM_3", "displayOnly": false, "golden": false, "source": "MATH" },
      { "cellId": "s0-c4-r3", "symbol": "ITEM_3", "displayOnly": false, "golden": false, "source": "MATH" },
      { "cellId": "s0-c4-r4", "symbol": "ITEM_3", "displayOnly": false, "golden": false, "source": "MATH" },
      { "cellId": "s0-c4-buffer-bottom", "symbol": "ITEM_3", "displayOnly": true, "golden": false, "source": "BUFFER" }
    ]
  ],

  "cascadeSteps": [
    {
      "step": 1,
      "mode": "BASE",
      "multiplier": 3,
      "stepWin": 675,

      "animationReelsBeforeDrop": [
        [
          { "cellId": "s1-c0-buffer-top", "symbol": "ITEM_5", "displayOnly": true, "golden": false, "source": "BUFFER" },
          { "cellId": "s1-c0-r1", "symbol": "ITEM_5", "displayOnly": false, "golden": false, "source": "MATH" },
          { "cellId": "s1-c0-r2", "symbol": "ITEM_2", "displayOnly": false, "golden": false, "source": "MATH" },
          { "cellId": "s1-c0-r3", "symbol": "ITEM_5", "displayOnly": false, "golden": false, "source": "MATH" },
          { "cellId": "s1-c0-r4", "symbol": "ITEM_7", "displayOnly": false, "golden": false, "source": "MATH" },
          { "cellId": "s1-c0-buffer-bottom", "symbol": "ITEM_7", "displayOnly": true, "golden": false, "source": "BUFFER" }
        ],
        [
          { "cellId": "s1-c1-r0", "symbol": "ITEM_1", "displayOnly": false, "golden": false, "source": "MATH" },
          { "cellId": "s1-c1-r1", "symbol": "ITEM_3", "displayOnly": false, "golden": false, "source": "MATH" },
          { "cellId": "s1-c1-r2", "symbol": "ITEM_6", "displayOnly": false, "golden": false, "source": "MATH" },
          { "cellId": "s1-c1-r3", "symbol": "ITEM_7", "displayOnly": false, "golden": false, "source": "MATH" },
          { "cellId": "s1-c1-r4", "symbol": "ITEM_4", "displayOnly": false, "golden": false, "source": "MATH" }
        ],
        [
          { "cellId": "s1-c2-r0", "symbol": "ITEM_2", "displayOnly": false, "golden": false, "source": "MATH" },
          { "cellId": "s1-c2-r1", "symbol": "ITEM_7", "displayOnly": false, "golden": false, "source": "MATH" },
          { "cellId": "s1-c2-r2", "symbol": "ITEM_5", "displayOnly": false, "golden": false, "source": "MATH" },
          { "cellId": "s1-c2-r3", "symbol": "ITEM_2", "displayOnly": false, "golden": false, "source": "MATH" },
          { "cellId": "s1-c2-r4", "symbol": "ITEM_4", "displayOnly": false, "golden": false, "source": "MATH" }
        ],
        [
          { "cellId": "s1-c3-r0", "symbol": "ITEM_2", "displayOnly": false, "golden": false, "source": "MATH" },
          { "cellId": "s1-c3-r1", "symbol": "ITEM_3", "displayOnly": false, "golden": false, "source": "MATH" },
          { "cellId": "s1-c3-r2", "symbol": "ITEM_3", "displayOnly": false, "golden": false, "source": "MATH" },
          { "cellId": "s1-c3-r3", "symbol": "ITEM_4", "displayOnly": false, "golden": false, "source": "MATH" },
          { "cellId": "s1-c3-r4", "symbol": "ITEM_3", "displayOnly": false, "golden": false, "source": "MATH" }
        ],
        [
          { "cellId": "s1-c4-buffer-top", "symbol": "ITEM_2", "displayOnly": true, "golden": false, "source": "BUFFER" },
          { "cellId": "s1-c4-r1", "symbol": "ITEM_2", "displayOnly": false, "golden": false, "source": "MATH" },
          { "cellId": "s1-c4-r2", "symbol": "ITEM_3", "displayOnly": false, "golden": false, "source": "MATH" },
          { "cellId": "s1-c4-r3", "symbol": "ITEM_3", "displayOnly": false, "golden": false, "source": "MATH" },
          { "cellId": "s1-c4-r4", "symbol": "ITEM_3", "displayOnly": false, "golden": false, "source": "MATH" },
          { "cellId": "s1-c4-buffer-bottom", "symbol": "ITEM_3", "displayOnly": true, "golden": false, "source": "BUFFER" }
        ]
      ],

      "visualWins": [
        {
          "symbol": "ITEM_7",
          "matchedReels": 3,
          "ways": 1,
          "winAmount": 675,
          "positions": [
            { "col": 0, "row": 4, "cellId": "s1-c0-r4" },
            { "col": 1, "row": 3, "cellId": "s1-c1-r3" },
            { "col": 2, "row": 1, "cellId": "s1-c2-r1" }
          ]
        }
      ],

      "animationRemovedPositions": [
        { "col": 0, "row": 4, "cellId": "s1-c0-r4" },
        { "col": 1, "row": 3, "cellId": "s1-c1-r3" },
        { "col": 2, "row": 1, "cellId": "s1-c2-r1" }
      ],

      "animationDropMap": [
        {
          "cellId": "s1-c0-r1",
          "symbol": "ITEM_5",
          "golden": false,
          "from": { "col": 0, "row": 1 },
          "to": { "col": 0, "row": 2 }
        },
        {
          "cellId": "s1-c0-r2",
          "symbol": "ITEM_2",
          "golden": false,
          "from": { "col": 0, "row": 2 },
          "to": { "col": 0, "row": 3 }
        },
        {
          "cellId": "s1-c0-r3",
          "symbol": "ITEM_5",
          "golden": false,
          "from": { "col": 0, "row": 3 },
          "to": { "col": 0, "row": 4 }
        },
        {
          "cellId": "s1-c1-r0",
          "symbol": "ITEM_1",
          "golden": false,
          "from": { "col": 1, "row": 0 },
          "to": { "col": 1, "row": 1 }
        },
        {
          "cellId": "s1-c1-r1",
          "symbol": "ITEM_3",
          "golden": false,
          "from": { "col": 1, "row": 1 },
          "to": { "col": 1, "row": 2 }
        },
        {
          "cellId": "s1-c1-r2",
          "symbol": "ITEM_6",
          "golden": false,
          "from": { "col": 1, "row": 2 },
          "to": { "col": 1, "row": 3 }
        },
        {
          "cellId": "s1-c1-r4",
          "symbol": "ITEM_4",
          "golden": false,
          "from": { "col": 1, "row": 4 },
          "to": { "col": 1, "row": 4 }
        },
        {
          "cellId": "s1-c2-r0",
          "symbol": "ITEM_2",
          "golden": false,
          "from": { "col": 2, "row": 0 },
          "to": { "col": 2, "row": 1 }
        },
        {
          "cellId": "s1-c2-r2",
          "symbol": "ITEM_5",
          "golden": false,
          "from": { "col": 2, "row": 2 },
          "to": { "col": 2, "row": 2 }
        },
        {
          "cellId": "s1-c2-r3",
          "symbol": "ITEM_2",
          "golden": false,
          "from": { "col": 2, "row": 3 },
          "to": { "col": 2, "row": 3 }
        },
        {
          "cellId": "s1-c2-r4",
          "symbol": "ITEM_4",
          "golden": false,
          "from": { "col": 2, "row": 4 },
          "to": { "col": 2, "row": 4 }
        }
      ],

      "animationNewSymbols": [
        {
          "cellId": "s1-new-c0-r1",
          "symbol": "ITEM_1",
          "golden": false,
          "to": { "col": 0, "row": 1 },
          "enterFrom": { "col": 0, "row": 0 }
        },
        {
          "cellId": "s1-new-c1-r0",
          "symbol": "ITEM_5",
          "golden": false,
          "to": { "col": 1, "row": 0 },
          "enterFrom": { "col": 1, "row": -1 }
        },
        {
          "cellId": "s1-new-c2-r0",
          "symbol": "ITEM_1",
          "golden": false,
          "to": { "col": 2, "row": 0 },
          "enterFrom": { "col": 2, "row": -1 }
        }
      ],

      "visualGoldenTransforms": [],

      "animationReelsAfterDrop": [
        [
          { "cellId": "s1-after-c0-buffer-top", "symbol": "ITEM_1", "displayOnly": true, "golden": false, "source": "BUFFER" },
          { "cellId": "s1-new-c0-r1", "symbol": "ITEM_1", "displayOnly": false, "golden": false, "source": "NEW" },
          { "cellId": "s1-c0-r1", "symbol": "ITEM_5", "displayOnly": false, "golden": false, "source": "MATH" },
          { "cellId": "s1-c0-r2", "symbol": "ITEM_2", "displayOnly": false, "golden": false, "source": "MATH" },
          { "cellId": "s1-c0-r3", "symbol": "ITEM_5", "displayOnly": false, "golden": false, "source": "MATH" },
          { "cellId": "s1-after-c0-buffer-bottom", "symbol": "ITEM_5", "displayOnly": true, "golden": false, "source": "BUFFER" }
        ],
        [
          { "cellId": "s1-new-c1-r0", "symbol": "ITEM_5", "displayOnly": false, "golden": false, "source": "NEW" },
          { "cellId": "s1-c1-r0", "symbol": "ITEM_1", "displayOnly": false, "golden": false, "source": "MATH" },
          { "cellId": "s1-c1-r1", "symbol": "ITEM_3", "displayOnly": false, "golden": false, "source": "MATH" },
          { "cellId": "s1-c1-r2", "symbol": "ITEM_6", "displayOnly": false, "golden": false, "source": "MATH" },
          { "cellId": "s1-c1-r4", "symbol": "ITEM_4", "displayOnly": false, "golden": false, "source": "MATH" }
        ],
        [
          { "cellId": "s1-new-c2-r0", "symbol": "ITEM_1", "displayOnly": false, "golden": false, "source": "NEW" },
          { "cellId": "s1-c2-r0", "symbol": "ITEM_2", "displayOnly": false, "golden": false, "source": "MATH" },
          { "cellId": "s1-c2-r2", "symbol": "ITEM_5", "displayOnly": false, "golden": false, "source": "MATH" },
          { "cellId": "s1-c2-r3", "symbol": "ITEM_2", "displayOnly": false, "golden": false, "source": "MATH" },
          { "cellId": "s1-c2-r4", "symbol": "ITEM_4", "displayOnly": false, "golden": false, "source": "MATH" }
        ],
        [
          { "cellId": "s1-c3-r0", "symbol": "ITEM_2", "displayOnly": false, "golden": false, "source": "MATH" },
          { "cellId": "s1-c3-r1", "symbol": "ITEM_3", "displayOnly": false, "golden": false, "source": "MATH" },
          { "cellId": "s1-c3-r2", "symbol": "ITEM_3", "displayOnly": false, "golden": false, "source": "MATH" },
          { "cellId": "s1-c3-r3", "symbol": "ITEM_4", "displayOnly": false, "golden": false, "source": "MATH" },
          { "cellId": "s1-c3-r4", "symbol": "ITEM_3", "displayOnly": false, "golden": false, "source": "MATH" }
        ],
        [
          { "cellId": "s1-after-c4-buffer-top", "symbol": "ITEM_2", "displayOnly": true, "golden": false, "source": "BUFFER" },
          { "cellId": "s1-c4-r1", "symbol": "ITEM_2", "displayOnly": false, "golden": false, "source": "MATH" },
          { "cellId": "s1-c4-r2", "symbol": "ITEM_3", "displayOnly": false, "golden": false, "source": "MATH" },
          { "cellId": "s1-c4-r3", "symbol": "ITEM_3", "displayOnly": false, "golden": false, "source": "MATH" },
          { "cellId": "s1-c4-r4", "symbol": "ITEM_3", "displayOnly": false, "golden": false, "source": "MATH" },
          { "cellId": "s1-after-c4-buffer-bottom", "symbol": "ITEM_3", "displayOnly": true, "golden": false, "source": "BUFFER" }
        ]
      ]
    }
  ],

  "totalWin": 675,
  "balance": 1000225,

  "bet": {
    "roomId": 1,
    "betOptionId": "R1_BS_250_BL_9",
    "totalBet": 450
  },

  "seamless": {
    "enabled": true,
    "payoutStatus": "SUCCESS"
  },

  "freeSpin": {
    "triggered": false,
    "awarded": 0,
    "remaining": 0,
    "scatterCount": 0
  },

  "jackpot": {
    "enabled": false,
    "triggered": false,
    "amount": 0
  },

  "state": {
    "mode": "BASE",
    "bigWin": false,
    "turbo": false,
    "autoPlay": false
  },

  "clientRequestId": "sample-fe-only-001"
}
```

## Những field không trả cho frontend nữa

Không trả trong response FE:

```txt
reels
cascadeSteps[].reelsBefore
cascadeSteps[].reelsAfterDrop
cascadeSteps[].removedPositions
cascadeSteps[].goldenTransforms
wins.positions theo math coordinate
mathPosition nếu FE không cần debug
betSize / betLevel / baseBet / lineBet nếu UI không cần hiển thị chi tiết
betTransactionId / settleTransactionId nếu FE không cần debug giao dịch
state.pot nếu chưa hiển thị hũ
```

Các field này backend vẫn nên lưu ở:

```txt
history
debug log
game_round_results
audit/reconciliation
```

## FE sẽ diễn animation bằng field nào?

FE chỉ cần dùng:

```txt
animationReels
cascadeSteps[].animationReelsBeforeDrop
cascadeSteps[].visualWins
cascadeSteps[].animationRemovedPositions
cascadeSteps[].animationDropMap
cascadeSteps[].animationNewSymbols
cascadeSteps[].visualGoldenTransforms
cascadeSteps[].animationReelsAfterDrop
```

## Ý nghĩa flow FE

```txt
1. Render animationReels ban đầu.
2. Với mỗi cascade step:
   - render animationReelsBeforeDrop
   - highlight visualWins.positions
   - xóa animationRemovedPositions
   - cho item cũ rơi theo animationDropMap
   - cho item mới vào theo animationNewSymbols
   - chạy visualGoldenTransforms nếu có
   - snap về animationReelsAfterDrop
3. Hiển thị totalWin và balance.
```

Dưới đây là cách hiểu **từng field trong response `4001` mới theo hướng FE-only animation contract**.

## 1. Nhóm định danh response

```json
"cmd": 4001
```

Mã response của lệnh spin. `4001` nghĩa là backend trả kết quả một lượt quay.

```json
"spinId": "SPIN_SAMPLE_001"
```

ID riêng của lượt spin. FE thường không cần dùng để render, nhưng có thể dùng để log/debug.

```json
"roundId": "RND_MW2_SPIN_SAMPLE_001"
```

ID round xử lý tiền. Backend dùng cho bet/settle/history. FE có thể bỏ qua nếu không cần debug.

```json
"roomId": 1
```

Room mà người chơi đang chơi.

---

## 2. `animationMeta`

```json
"animationMeta": {
  "mathLayout": [4, 5, 5, 5, 4],
  "displayLayout": [6, 5, 5, 5, 6],
  "rowOrder": "TOP_TO_BOTTOM",
  "displayOnlyPositions": [
    { "col": 0, "row": 0 },
    { "col": 0, "row": 5 },
    { "col": 4, "row": 0 },
    { "col": 4, "row": 5 }
  ]
}
```

Đây là metadata layout.

```txt
mathLayout = layout thật backend dùng để tính game.
displayLayout = layout FE dùng để render animation.
rowOrder = thứ tự row trong từng cột.
displayOnlyPositions = các ô chỉ để hiển thị, không tính win.
```

Nghĩa là:

```txt
Math thật: 4-5-5-5-4
Visual FE render: 6-5-5-5-6
```

Cột 1 và cột 5 có thêm 2 ô đệm:

```txt
row 0 = buffer trên
row cuối = buffer dưới
```

---

## 3. `animationReels`

```json
"animationReels": [...]
```

Đây là **board visual ban đầu của spin**, trước khi xử lý cascade.

FE dùng field này để render màn hình sau khi guồng dừng.

Layout:

```txt
animationReels[0] = cột 1
animationReels[1] = cột 2
animationReels[2] = cột 3
animationReels[3] = cột 4
animationReels[4] = cột 5
```

Trong mỗi cột, row đi theo:

```txt
trên xuống dưới
```

Mỗi cell có dạng:

```json
{
  "cellId": "s0-c0-r1",
  "symbol": "ITEM_5",
  "displayOnly": false,
  "golden": false,
  "source": "SYMBOL"
}
```

Ý nghĩa:

```txt
cellId = ID duy nhất của cell để FE tracking item.
symbol = mã item cần render.
displayOnly = true nếu chỉ là ô đệm visual, không tính win.
golden = true nếu item là golden.
source = loại cell: SYMBOL / BUFFER / NEW.
```

Nên dùng `source: "SYMBOL"` thay vì `source: "MATH"` trong response FE-only để tránh FE hiểu nhầm.

---

## 4. `cascadeSteps`

```json
"cascadeSteps": [...]
```

Danh sách các lần thắng liên hoàn.

Nếu không thắng:

```json
"cascadeSteps": []
```

Nếu có thắng/sập xuống, mỗi lần sập là một step:

```txt
step 1
step 2
step 3
...
```

FE chạy animation tuần tự từng step.

---

# Bên trong mỗi `cascadeSteps[]`

## 5. `step`

```json
"step": 1
```

Số thứ tự cascade.

```txt
step 1 = lần thắng đầu tiên
step 2 = sau khi sập xuống vẫn thắng tiếp
step 3 = tiếp tục thắng tiếp
```

---

## 6. `mode`

```json
"mode": "BASE"
```

Trạng thái game ở step đó.

Có thể là:

```txt
BASE = game thường
FREE_SPIN = free spin
```

---

## 7. `multiplier`

```json
"multiplier": 3
```

Hệ số nhân tiền thắng ở step hiện tại.

Ví dụ:

```txt
BASE step 1: x1
BASE step 2: x2
BASE step 3: x3
BASE step 4 trở đi: x5
```

---

## 8. `stepWin`

```json
"stepWin": 675
```

Tổng tiền thắng của riêng cascade step này.

Nếu có nhiều win trong cùng step, `stepWin` là tổng các win đó.

---

## 9. `animationReelsBeforeDrop`

```json
"animationReelsBeforeDrop": [...]
```

Đây là **board visual trước khi remove item thắng**.

FE dùng để:

```txt
1. render board trước khi nổ
2. highlight item thắng
3. chạy hiệu ứng nổ/xóa
```

Field này thay cho `reelsBefore` trong FE contract mới.

---

## 10. `visualWins`

```json
"visualWins": [
  {
    "symbol": "ITEM_7",
    "matchedReels": 3,
    "ways": 1,
    "winAmount": 675,
    "positions": [
      { "col": 0, "row": 4, "cellId": "s1-c0-r4" },
      { "col": 1, "row": 3, "cellId": "s1-c1-r3" },
      { "col": 2, "row": 1, "cellId": "s1-c2-r1" }
    ]
  }
]
```

Đây là thông tin thắng theo **visual coordinate**.

Ý nghĩa:

```txt
symbol = item thắng
matchedReels = thắng qua bao nhiêu cột liên tiếp
ways = số ways thắng
winAmount = tiền thắng của win này
positions = vị trí FE cần highlight
```

FE dùng `visualWins.positions` để highlight item thắng.

Không cần dùng `wins.positions` math nữa.

---

## 11. `animationRemovedPositions`

```json
"animationRemovedPositions": [
  { "col": 0, "row": 4, "cellId": "s1-c0-r4" },
  { "col": 1, "row": 3, "cellId": "s1-c1-r3" },
  { "col": 2, "row": 1, "cellId": "s1-c2-r1" }
]
```

Đây là các item sẽ bị nổ/xóa theo **visual coordinate**.

FE dùng để chạy hiệu ứng:

```txt
explode / fade out / remove
```

Quan trọng:

```txt
animationRemovedPositions dùng col/row visual.
Không dùng math coordinate.
Không bao giờ remove displayOnly=true.
```

---

## 12. `animationDropMap`

```json
"animationDropMap": [
  {
    "cellId": "s1-c0-r1",
    "symbol": "ITEM_5",
    "golden": false,
    "from": { "col": 0, "row": 1 },
    "to": { "col": 0, "row": 2 }
  }
]
```

Đây là field quan trọng nhất để FE diễn hiệu ứng rơi.

Nó nói rõ:

```txt
item nào rơi từ đâu tới đâu
```

Ý nghĩa:

```txt
cellId = ID item đang rơi
symbol = item đó là gì
golden = có phải golden không
from = vị trí trước khi rơi
to = vị trí sau khi rơi
```

Ví dụ:

```txt
ITEM_5 từ cột 1 row 1 rơi xuống cột 1 row 2
```

Nhờ `cellId`, nếu có nhiều `ITEM_5` trong cùng cột, FE vẫn biết con nào là con nào.

---

## 13. `animationNewSymbols`

```json
"animationNewSymbols": [
  {
    "cellId": "s1-new-c0-r1",
    "symbol": "ITEM_1",
    "golden": false,
    "to": { "col": 0, "row": 1 },
    "enterFrom": { "col": 0, "row": 0 }
  }
]
```

Đây là danh sách item mới xuất hiện sau khi các item cũ rơi xuống.

Ý nghĩa:

```txt
cellId = ID item mới
symbol = item mới là gì
golden = item mới có golden không
to = vị trí cuối cùng item mới sẽ nằm
enterFrom = vị trí item mới bay/rơi vào từ đâu
```

FE dùng để render:

```txt
symbol mới rơi từ trên xuống
```

Không cần tự đoán item mới bằng cách so sánh before/after.

---

## 14. `visualGoldenTransforms`

```json
"visualGoldenTransforms": []
```

Nếu không có golden transform thì là mảng rỗng.

Nếu có, sẽ có dạng:

```json
"visualGoldenTransforms": [
  {
    "cellId": "s2-c2-r2",
    "from": { "col": 2, "row": 2 },
    "to": { "col": 2, "row": 2 },
    "fromSymbol": "ITEM_5",
    "toSymbol": "WILD",
    "fromGolden": true,
    "toGolden": false
  }
]
```

Ý nghĩa:

```txt
Golden symbol tham gia thắng
→ không bị xóa
→ chuyển thành WILD
```

Không phải item rơi xuống rồi “gom thành golden”.

FE dùng field này để chạy hiệu ứng:

```txt
ITEM golden → WILD
```

---

## 15. `animationReelsAfterDrop`

```json
"animationReelsAfterDrop": [...]
```

Đây là **board visual cuối cùng sau khi remove/drop/new/transform xong**.

FE dùng làm final frame.

Flow đúng:

```txt
Không so sánh before/after để đoán rơi.
Dùng animationDropMap + animationNewSymbols để animate.
Sau đó snap về animationReelsAfterDrop.
```

Nói đơn giản:

```txt
animationReelsAfterDrop = kết quả cuối
animationDropMap = đường rơi
animationNewSymbols = item mới
```

---

# Nhóm field kết quả tiền/game

## 16. `totalWin`

```json
"totalWin": 675
```

Tổng tiền thắng của toàn bộ spin.

Nếu nhiều cascade:

```txt
totalWin = stepWin step 1 + stepWin step 2 + ...
```

---

## 17. `balance`

```json
"balance": 1000225
```

Số dư sau khi backend xử lý bet/settle thành công.

FE chỉ update balance khi:

```txt
cmd = 4001
seamless.payoutStatus = SUCCESS
```

---

## 18. `bet`

```json
"bet": {
  "roomId": 1,
  "betOptionId": "R1_BS_250_BL_9",
  "totalBet": 450
}
```

Thông tin cược của spin.

FE thường chỉ cần:

```txt
totalBet = số tiền đã cược
betOptionId = option đang chọn
roomId = room đang chơi
```

Nếu UI cần hiển thị chi tiết chip/level thì có thể thêm `betSize`, `betLevel`.

---

## 19. `seamless`

```json
"seamless": {
  "enabled": true,
  "payoutStatus": "SUCCESS"
}
```

Trạng thái ví.

Ý nghĩa:

```txt
enabled = có dùng seamless wallet
payoutStatus = trạng thái xử lý tiền
```

Các trạng thái thường cần quan tâm:

```txt
SUCCESS = tiền đã xử lý xong, FE được update balance
PENDING = chưa chắc chắn, FE nên hiện trạng thái chờ
FAILED = lỗi, không update balance như success
```

---

## 20. `freeSpin`

```json
"freeSpin": {
  "triggered": false,
  "awarded": 0,
  "remaining": 0,
  "scatterCount": 0
}
```

Thông tin free spin.

Ý nghĩa:

```txt
triggered = spin này có kích hoạt free spin không
awarded = số free spin được thưởng
remaining = số free spin còn lại
scatterCount = số scatter xuất hiện
```

---

## 21. `jackpot`

```json
"jackpot": {
  "enabled": false,
  "triggered": false,
  "amount": 0
}
```

Thông tin jackpot.

Ý nghĩa:

```txt
enabled = jackpot có bật không
triggered = spin này có nổ hũ không
amount = số tiền jackpot nếu nổ
```

Hiện theo contract đã chốt:

```txt
JP không trả như symbol trong reels.
Nếu nổ jackpot thì trả qua jackpot.triggered và jackpot.amount.
```

---

## 22. `state`

```json
"state": {
  "mode": "BASE",
  "bigWin": false,
  "turbo": false,
  "autoPlay": false
}
```

Trạng thái phụ của game.

Ý nghĩa:

```txt
mode = BASE hoặc FREE_SPIN
bigWin = có phải big win không
turbo = user có bật turbo không
autoPlay = user có đang autoplay không
```

---

## 23. `clientRequestId`

```json
"clientRequestId": "sample-fe-only-001"
```

ID request FE gửi lên, backend trả lại để FE đối chiếu.

FE dùng để tránh nhầm response giữa nhiều request.

---

# Flow FE render theo response mới

```txt
1. Render animationReels ban đầu.
2. Với từng cascadeSteps:
   2.1 Render animationReelsBeforeDrop.
   2.2 Highlight visualWins.positions.
   2.3 Xóa animationRemovedPositions.
   2.4 Cho item cũ rơi theo animationDropMap.
   2.5 Cho item mới đi vào theo animationNewSymbols.
   2.6 Chạy visualGoldenTransforms nếu có.
   2.7 Snap về animationReelsAfterDrop.
3. Sau cascade cuối, hiển thị totalWin.
4. Nếu seamless.payoutStatus = SUCCESS thì update balance.
```
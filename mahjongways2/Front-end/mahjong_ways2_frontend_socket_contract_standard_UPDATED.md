# Mahjong Ways 2 — Frontend Socket Contract

> Updated for the latest animation/display-reels contract.
>
> Key rule: **do not change `gameConfig.reelRows`**. The math layout remains `[4,5,5,5,4]`. Backend only adds `animationConfig` to `4009`, and adds `animationReels` / `displayReels` to `4001` when animation reels are enabled.

---

## 1. WebSocket connection

```txt
WebSocket path: /ws
Default port: 61144
Local URL: ws://127.0.0.1:61144/ws
```

Frontend connect:

```js
const socket = new WebSocket("ws://127.0.0.1:61144/ws");
```

After `onopen`, frontend sends command `4003` to subscribe to the game.

---

## 2. Standard FE flow

```txt
1. FE connects WebSocket.
2. FE sends SUBSCRIBE_MAHJONG2 / cmd 4003.
3. BE returns INFO_MAHJONG2 / cmd 4009.
4. FE renders room, betOptions, balance, symbols, game config, and animationConfig.
5. User selects betOptionId.
6. FE sends PLAY_MAHJONG2 / cmd 4001.
7. BE returns:
   - cmd 4001 when spin result / pending result is returned
   - cmd 3999 when there is an error
8. FE renders reels + cascadeSteps.
9. If animationReels/displayReels exists, FE uses it only for visual animation.
10. FE updates balance only when cmd=4001 and seamless.payoutStatus=SUCCESS.
11. FE must not update balance from cmd=3999.
```

---

## 3. Common request rules

### 3.1 Every request must include `cmd`

If `cmd` is missing, backend returns:

```json
{
  "cmd": 3999,
  "errorCode": 1001,
  "message": "INVALID_REQUEST",
  "balance": 0,
  "payoutStatus": "FAILED"
}
```

### 3.2 Token fields accepted by backend

Backend accepts these token field names:

```txt
sessionToken
session_token
token
```

Valid examples:

```json
{
  "cmd": 4003,
  "sessionToken": "player-token"
}
```

```json
{
  "cmd": 4003,
  "token": "player-token"
}
```

### 3.3 FE does not need to send `userId` or `currency`

Backend resolves player identity and currency from the session token.

---

## 4. Command list

| CMD    | Name                      | FE sends?            | Response           |
| -----: | ------------------------- | -------------------- | ------------------ |
| `4001` | `PLAY_MAHJONG2`           | Yes                  | `4001` or `3999`   |
| `4003` | `SUBSCRIBE_MAHJONG2`      | Yes                  | `4009`             |
| `4004` | `UNSUBSCRIBE_MAHJONG2`    | Yes                  | `4009`             |
| `4005` | `CHANGE_ROOM_MAHJONG2`    | Yes                  | `4009` or `3999`   |
| `4006` | `AUTO_PLAY_MAHJONG2`      | Yes, unsupported     | `3999`             |
| `4007` | `STOP_AUTO_PLAY_MAHJONG2` | Yes                  | `4008`             |
| `4013` | `MINIMIZE_MAHJONG2`       | Yes                  | `4014`             |
| `4015` | `HISTORY_MAHJONG2`        | Yes                  | `4016`             |
| `3999` | `ERROR`                   | Backend error        | -                  |

Commands present in command constants but not part of the current FE flow:

```txt
4002 UPDATE_POT_MAHJONG2
4010 BIG_WIN_MAHJONG2
4011 TOTAL_FREE_SPIN_MAHJONG2
```

---

## 5. SUBSCRIBE_MAHJONG2 — cmd `4003`

### Request

```json
{
  "cmd": 4003,
  "sessionToken": "player-token",
  "roomId": 1
}
```

`roomId` is optional. If missing or `roomId <= 0`, backend selects the default room.

---

## 6. INFO_MAHJONG2 response — cmd `4009`

### Required response shape

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
    },
    {
      "code": "ITEM_2",
      "type": "NORMAL",
      "role": "PAYABLE",
      "assetKey": "item_2",
      "canBeGolden": true,
      "payable": true
    },
    {
      "code": "ITEM_3",
      "type": "NORMAL",
      "role": "PAYABLE",
      "assetKey": "item_3",
      "canBeGolden": true,
      "payable": true
    },
    {
      "code": "ITEM_4",
      "type": "NORMAL",
      "role": "PAYABLE",
      "assetKey": "item_4",
      "canBeGolden": true,
      "payable": true
    },
    {
      "code": "ITEM_5",
      "type": "NORMAL",
      "role": "PAYABLE",
      "assetKey": "item_5",
      "canBeGolden": true,
      "payable": true
    },
    {
      "code": "ITEM_6",
      "type": "NORMAL",
      "role": "PAYABLE",
      "assetKey": "item_6",
      "canBeGolden": true,
      "payable": true
    },
    {
      "code": "ITEM_7",
      "type": "NORMAL",
      "role": "PAYABLE",
      "assetKey": "item_7",
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

### Field explanation

| Field | Meaning |
|---|---|
| `cmd` | `4009`, game info response. |
| `rooms` | Enabled rooms. |
| `room` | Currently selected room. |
| `betOptions` | Bet options FE may select. |
| `gameConfig.reelRows` | **Math layout**. Must remain `[4,5,5,5,4]`. |
| `gameConfig.totalWays` | `2000`. Must remain consistent with `[4,5,5,5,4]`. |
| `symbols` | Symbol catalog FE uses to map `symbol` code to `assetKey`. |
| `wildRule` | WILD substitution rule. |
| `goldenRule` | Golden symbol transform rule. |
| `multipliers` | Cascade multiplier table. |
| `freeSpinRule` | Free spin rule data. Current `gameConfig.hasFreeSpin=false`. |
| `playerState.balance` | Current player balance. |
| `playerState.selectedBetOptionId` | Suggested/default selected bet option. |
| `animationConfig` | Visual-only animation layout metadata for FE. |

---

## 7. Animation/display layout contract

### 7.1 Core rule

```txt
gameConfig.reelRows = math truth = [4,5,5,5,4]
animationConfig.displayLayout = visual-only display = [6,5,5,5,6]
```

Frontend must not treat `[6,5,5,5,6]` as the game math board.

### 7.2 Position mapping

For display layout `[6,5,5,5,6]`:

```txt
Column 0:
  display row 0 = top display-only buffer
  display row 1 = math row 0
  display row 2 = math row 1
  display row 3 = math row 2
  display row 4 = math row 3
  display row 5 = bottom display-only buffer

Column 1:
  display rows 0..4 = math rows 0..4

Column 2:
  display rows 0..4 = math rows 0..4

Column 3:
  display rows 0..4 = math rows 0..4

Column 4:
  display row 0 = top display-only buffer
  display row 1 = math row 0
  display row 2 = math row 1
  display row 3 = math row 2
  display row 4 = math row 3
  display row 5 = bottom display-only buffer
```

### 7.3 Display-only safety rule

`displayOnly=true` cells:

```txt
- are only for frontend visual animation
- do not participate in ways calculation
- do not participate in payout
- do not count as scatter
- do not trigger free spin
- do not trigger jackpot
- do not affect RTP
- do not appear in removedPositions
- do not change balance or settlement
```

---

## 8. CHANGE_ROOM_MAHJONG2 — cmd `4005`

### Request

```json
{
  "cmd": 4005,
  "sessionToken": "player-token",
  "roomId": 1
}
```

### Response

Returns the same schema as `SUBSCRIBE_MAHJONG2`, meaning `cmd = 4009` and includes `animationConfig`.

If `roomId` does not exist or the room is disabled:

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

## 9. PLAY_MAHJONG2 — cmd `4001`

### Request

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

### Request fields

| Field | Required | Meaning |
|---|---:|---|
| `cmd` | Yes | Always `4001`. |
| `clientRequestId` | Yes | Idempotency key. Must be unique per new spin. |
| `sessionToken` | Yes | Player session token. |
| `roomId` | Yes | Selected room. |
| `betOptionId` | Yes | Must be selected from `betOptions`. |
| `turbo` | No | Defaults to `false`. |
| `gameCode` | No | Backend defaults to `MAHJONG_WAYS_2` if omitted. |

### Fields FE must not send when spinning

Backend rejects requests containing any of these fields:

```txt
betSize
betSizeMinor
betLevel
baseBet
lineBet
totalBet
betAmountMinor
```

Invalid example:

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

Error response:

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

## 10. PLAY success response — cmd `4001`

### 10.1 Main fields

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
  "displayReels": [
    [
      { "symbol": "ITEM_7", "golden": false, "displayOnly": true },
      { "symbol": "ITEM_1", "golden": false, "displayOnly": false },
      { "symbol": "ITEM_4", "golden": false, "displayOnly": false },
      { "symbol": "ITEM_5", "golden": false, "displayOnly": false },
      { "symbol": "ITEM_6", "golden": false, "displayOnly": false },
      { "symbol": "ITEM_2", "golden": false, "displayOnly": true }
    ],
    [
      { "symbol": "ITEM_1", "golden": true, "displayOnly": false },
      { "symbol": "ITEM_2", "golden": false, "displayOnly": false },
      { "symbol": "ITEM_3", "golden": false, "displayOnly": false },
      { "symbol": "ITEM_4", "golden": false, "displayOnly": false },
      { "symbol": "ITEM_5", "golden": false, "displayOnly": false }
    ],
    [
      { "symbol": "ITEM_1", "golden": false, "displayOnly": false },
      { "symbol": "ITEM_7", "golden": false, "displayOnly": false },
      { "symbol": "ITEM_6", "golden": false, "displayOnly": false },
      { "symbol": "ITEM_5", "golden": false, "displayOnly": false },
      { "symbol": "ITEM_4", "golden": false, "displayOnly": false }
    ],
    [
      { "symbol": "ITEM_2", "golden": false, "displayOnly": false },
      { "symbol": "ITEM_3", "golden": false, "displayOnly": false },
      { "symbol": "ITEM_4", "golden": false, "displayOnly": false },
      { "symbol": "ITEM_5", "golden": false, "displayOnly": false },
      { "symbol": "ITEM_6", "golden": false, "displayOnly": false }
    ],
    [
      { "symbol": "ITEM_3", "golden": false, "displayOnly": true },
      { "symbol": "ITEM_7", "golden": false, "displayOnly": false },
      { "symbol": "ITEM_6", "golden": false, "displayOnly": false },
      { "symbol": "ITEM_5", "golden": false, "displayOnly": false },
      { "symbol": "ITEM_4", "golden": false, "displayOnly": false },
      { "symbol": "ITEM_1", "golden": false, "displayOnly": true }
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
    ],
    "displayOnlyAffectsMath": false
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

### 10.2 Important compatibility rules

`reels` remains the math/truth board:

```txt
reel 0: 4 cells
reel 1: 5 cells
reel 2: 5 cells
reel 3: 5 cells
reel 4: 4 cells
```

`displayReels` / `animationReels`, when present, is visual-only:

```txt
reel 0: 6 cells
reel 1: 5 cells
reel 2: 5 cells
reel 3: 5 cells
reel 4: 6 cells
```

FE should render symbols using:

```txt
cell.symbol -> match symbols[].code -> use symbols[].assetKey
```

Example:

```txt
displayReels[0][1].symbol = ITEM_1
symbols[].code = ITEM_1
symbols[].assetKey = item_1
```

Then render asset `item_1`.

### 10.3 Cascade steps

Cascade math fields remain unchanged:

| Field | Meaning |
|---|---|
| `step` | Cascade step number, starting from 1. |
| `mode` | `BASE` or `FREE_SPIN`. |
| `multiplier` | Multiplier for the step. |
| `reelsBefore` | Math board before removal. |
| `wins` | Winning ways for this step. |
| `removedPositions` | Math positions removed. |
| `goldenTransforms` | Golden cells transformed to WILD. |
| `reelsAfterDrop` | Math board after drop. |
| `stepWin` | Win amount for the step. |

`removedPositions` always uses math coordinates:

```json
{ "reel": 0, "row": 0 }
```

It must satisfy:

```txt
row < gameConfig.reelRows[reel]
```

It must never reference `displayOnly` cells.

### 10.4 Final board

Top-level `reels` is the initial board.

Final math board:

```js
const finalReels =
  response.cascadeSteps.length > 0
    ? response.cascadeSteps[response.cascadeSteps.length - 1].reelsAfterDrop
    : response.reels;
```

Final display board:

```js
const finalDisplayReels =
  response.cascadeSteps.length > 0 && response.cascadeSteps.at(-1).displayReelsAfterDrop
    ? response.cascadeSteps.at(-1).displayReelsAfterDrop
    : response.displayReels || response.animationReels;
```

If `displayReelsAfterDrop` is not present, FE can derive display layout from `finalReels` using `animationConfig` mapping or render only math reels.

---

## 11. PLAY response without win

If no win, backend returns `cascadeSteps: []`.

The response may still include `displayReels` / `animationReels` if animation reels are enabled.

Important:

```txt
No win does not mean no displayReels.
displayReels is visual-only and independent from win calculation.
```

---

## 12. Pending / duplicate PLAY response

If FE sends the same `clientRequestId`, backend handles idempotency.

### Duplicate pending bet

Response can still be `cmd = 4001`:

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

Because non-null JSON inclusion may be enabled, null fields may be omitted.

FE rule:

```txt
payoutStatus = BET_PENDING / SETTLE_PENDING / JACKPOT_PENDING / CREATED
=> do not treat as completed success
=> do not update balance
=> lock spin or show processing state
```

### Duplicate failed

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

Or:

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

## 13. HISTORY_MAHJONG2 — cmd `4015`

### Request

```json
{
  "cmd": 4015,
  "sessionToken": "player-token",
  "limit": 20
}
```

Rules:

```txt
limit default = 20
limit min = 1
limit max = 50
page / size not supported
```

If FE sends `page` or `size`, backend returns an error.

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

`items[].result` is the saved `ResultMahjong2Response` snapshot. If the saved result contains `displayReels` / `animationReels`, FE may use it for display, but must still treat `reels` as the math truth.

---

## 14. UNSUBSCRIBE_MAHJONG2 — cmd `4004`

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

## 15. MINIMIZE_MAHJONG2 — cmd `4013`

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

## 16. AUTO_PLAY_MAHJONG2 — cmd `4006`

Auto play is currently unsupported.

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
  "balance": null,
  "payoutStatus": "FAILED"
}
```

`balance` can be `null` for errors that are not real wallet/balance responses.

---

## 17. STOP_AUTO_PLAY_MAHJONG2 — cmd `4007`

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

## 18. Error response — cmd `3999`

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

When error is related to a spin/round, response can include:

```json
{
  "clientRequestId": "spin-xxx",
  "spinId": "SPIN_xxx",
  "roundId": "RND_MW2_SPIN_xxx"
}
```

For errors not tied to a real wallet balance, `balance` can be `0`, `null`, or omitted depending on the backend DTO/serialization config. FE must not update balance from `cmd=3999`.

---

## 19. Common errors FE may receive

| Case | Message / status |
|---|---|
| Missing `cmd` | `INVALID_REQUEST` |
| Unknown command | `UNKNOWN_COMMAND` |
| Invalid / expired token | `INVALID_SESSION_TOKEN` |
| Missing `sessionToken` | `INVALID_REQUEST` |
| Missing `clientRequestId` for spin | `INVALID_REQUEST` |
| Missing / invalid `roomId` | `INVALID_ROOM` |
| Invalid bet option | `INVALID_BET_OPTION` |
| FE sends forbidden bet field | `CLIENT_BET_FIELDS_NOT_ALLOWED` |
| Insufficient balance | `INSUFFICIENT_BALANCE` |
| Previous spin has pending bet | `BET_PENDING` |
| Settle pending | `SETTLE_PENDING` |
| Jackpot pending | `JACKPOT_PENDING` |
| Wallet issue needs review | `FAILED_NEED_REVIEW` |
| Internal error | `INTERNAL_ERROR` |

---

## 20. FE handling rules

```js
function handleSocketMessage(msg) {
  switch (msg.cmd) {
    case 4009:
      // subscribe / change room / unsubscribe info
      // use msg.animationConfig for visual display layout
      break;

    case 4001:
      // spin result or pending result
      // use msg.reels as math/truth result
      // use msg.displayReels or msg.animationReels only for visual animation
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

### Balance rule

```txt
Only update balance from cmd=4001 when seamless.payoutStatus = SUCCESS.
Do not update balance from cmd=3999.
```

### Pending rule

```txt
BET_PENDING
SETTLE_PENDING
JACKPOT_PENDING
CANCEL_PENDING
FAILED_NEED_REVIEW
CREATED

=> not completed success
=> do not update balance
=> do not immediately spin again with a new clientRequestId
=> lock spin or show processing state
```

### Failed rule

```txt
FAILED
INSUFFICIENT_BALANCE
INVALID_ROOM
INVALID_BET_OPTION
INVALID_REQUEST
INVALID_SESSION_TOKEN

=> request clearly failed
=> FE may show error
=> only spin again with a new clientRequestId after user fixes the issue / refreshes session / adds funds
```

---

## 21. Minimal FE commands

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

## 22. Frontend summary

```txt
4009:
- Use gameConfig.reelRows as math layout: [4,5,5,5,4].
- Use animationConfig.displayLayout as visual layout: [6,5,5,5,6].
- Do not calculate wins from animationConfig.

4001:
- Use reels as game truth.
- Use displayReels / animationReels only for visual animation.
- displayOnly=true cells are visual buffers.
- removedPositions always use math coordinates.

Balance:
- Update balance only from 4001 SUCCESS.
- Never update balance from 3999.
```

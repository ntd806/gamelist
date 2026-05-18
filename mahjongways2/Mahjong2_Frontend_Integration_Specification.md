# Mahjong2 — Frontend Integration Specification

> File này được tách từ tài liệu tổng hợp Mahjong2 Backend/Frontend. Nội dung tập trung cho frontend: socket flow, command convention, init config, result payload, cascade animation, free spin và jackpot display.

---

## 1. Frontend kết luận thiết kế

Frontend không cần làm socket architecture mới.

Frontend cần:

```text
reuse socket cũ
reuse numeric command convention cũ
reuse subscribe/play/autoplay/minimize flow cũ
```

Chỉ mở rộng:

```text
RESULT payload
dynamic reels 4-5-5-5-4
cascadeSteps
removedPositions
goldenTransforms
freeSpin state
```

---

# 2. Command rule

Dự án cũ dùng numeric command.

Với Mahjong2:

```text
Command ID cụ thể = TBD
Backend sẽ cấp trong SlotCMD.java
Frontend không hardcode ID nếu chưa có
```

Flow command vẫn theo pattern cũ:

```text
SUBSCRIBE_MAHJONG2
INFO_MAHJONG2
CHANGE_ROOM_MAHJONG2
PLAY_MAHJONG2
RESULT_MAHJONG2
UPDATE_POT_MAHJONG2
BIG_WIN_MAHJONG2
AUTO_PLAY_MAHJONG2
STOP_AUTO_PLAY_MAHJONG2
FORCE_STOP_AUTO_MAHJONG2
MINIMIZE_MAHJONG2
MINIMIZE_RESULT_MAHJONG2
UNSUBSCRIBE_MAHJONG2
```

---

# 3. Init game config cho frontend

Khi frontend subscribe hoặc nhận info, backend nên trả:

```json
{
  "cmd": "TBD_INFO_MAHJONG2",
  "room": {
    "roomId": 1,
    "betSize": 2.5,
    "betLevel": 9,
    "baseBet": 20,
    "totalBet": 450,
    "pot": 1200000
  },
  "gameConfig": {
    "gameCode": "MAHJONG2",
    "reelCount": 5,
    "reelRows": [4, 5, 5, 5, 4],
    "totalWays": 2000,
    "minMatchedReels": 3,
    "winDirection": "LEFT_TO_RIGHT",
    "hasCascade": true,
    "hasGoldenSymbol": true,
    "hasFreeSpin": true
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
    "retrigger": true
  },
  "playerState": {
    "balance": 1000000,
    "mode": "BASE",
    "remainingFreeSpin": 0
  }
}
```

Frontend dùng config này để:

```text
render layout
map asset
render multiplier UI
render free spin rules
render golden overlay
```

---

# 4. Frontend không dùng matrix 4x5

Frontend phải render theo:

```text
reels[reelIndex][rowIndex]
```

Vì layout là:

```text
[4, 5, 5, 5, 4]
```

Ví dụ:

```json
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
]
```

---

# 5. PLAY request

```json
{
  "cmd": "TBD_PLAY_MAHJONG2",
  "betSize": 2.5,
  "betLevel": 9,
  "baseBet": 20,
  "turbo": false
}
```

Formula:

```text
totalBet = betSize × betLevel × baseBet
```

---

# 6. RESULT payload chuẩn

```json
{
  "cmd": "TBD_RESULT_MAHJONG2",
  "spinId": "SPIN_10001",

  "reels": [],

  "cascadeSteps": [],

  "totalWin": 4800,
  "balance": 1050000,

  "bet": {
    "betSize": 2.5,
    "betLevel": 9,
    "baseBet": 20,
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
    "triggered": false,
    "type": null,
    "amount": 0
  },

  "state": {
    "mode": "BASE",
    "pot": 1200000,
    "bigWin": false,
    "turbo": false
  }
}
```

---

# 7. Cascade step payload

```json
{
  "step": 1,
  "mode": "BASE",
  "multiplier": 1,
  "reelsBefore": [],
  "wins": [],
  "removedPositions": [],
  "goldenTransforms": [],
  "reelsAfterDrop": [],
  "stepWin": 1200
}
```

Frontend render sequence:

```text
render reelsBefore
highlight wins.positions
show multiplier
show stepWin
explode removedPositions
animate goldenTransforms
animate drop to reelsAfterDrop
next cascade step
```

---

# 8. Win object

```json
{
  "symbol": "ITEM_1",
  "matchedReels": 4,
  "ways": 8,
  "payRate": 0.2,
  "multiplier": 2,
  "winAmount": 3200,
  "positions": [
    { "reel": 0, "row": 0 },
    { "reel": 1, "row": 0 },
    { "reel": 1, "row": 3 },
    { "reel": 2, "row": 1 }
  ]
}
```

Frontend dùng `positions` để highlight symbol thắng.

---

# 9. Removed positions

```json
"removedPositions": [
  { "reel": 0, "row": 0 },
  { "reel": 1, "row": 0 },
  { "reel": 1, "row": 3 },
  { "reel": 2, "row": 1 }
]
```

Frontend dùng để:

```text
explode
remove symbol
drop animation
```

---

# 10. Golden transform

```json
"goldenTransforms": [
  {
    "position": { "reel": 2, "row": 1 },
    "from": {
      "symbol": "ITEM_3",
      "golden": true
    },
    "to": {
      "symbol": "WILD",
      "golden": false
    }
  }
]
```

Frontend animate:

```text
Golden ITEM_3 → WILD
```

---

# 11. Free Spin response

```json
"freeSpin": {
  "triggered": true,
  "awarded": 10,
  "remaining": 10,
  "retriggered": false,
  "scatterCount": 3
}
```

Nếu đang Free Spin:

```json
"state": {
  "mode": "FREE_SPIN"
}
```

Frontend hiển thị:

```text
Free Spin intro
remaining free spin
Free Spin multiplier UI
retrigger nếu có
```

---

# 12. Jackpot response

Jackpot là system reward, không nhất thiết là reel symbol.

```json
"jackpot": {
  "triggered": false,
  "type": null,
  "amount": 0
}
```

Nếu nổ:

```json
"jackpot": {
  "triggered": true,
  "type": "NORMAL",
  "amount": 5000000
}
```

Frontend không tự giả định có `JP` symbol trên reels.

---

# 13. Frontend render flow

```text
Receive RESULT_MAHJONG2
↓
Render initial reels layout 4-5-5-5-4
↓
For each cascadeStep:
    render reelsBefore
    highlight wins[].positions
    display multiplier
    display stepWin
    explode removedPositions
    animate goldenTransforms
    animate drop to reelsAfterDrop
↓
Update totalWin
↓
Update balance
↓
Update pot
↓
If freeSpin.triggered:
    show free spin intro
↓
If state.mode = FREE_SPIN:
    show remaining free spins
↓
If jackpot.triggered:
    show jackpot animation
↓
Ready next spin / autoplay next spin
```

---

# 14. Những thứ frontend không được tự giả định

Frontend không tự giả định:

```text
matrix 4x5 đều
1024 ways
BONUS symbol
JP symbol trên reels
multiplier luôn x1
một spin chỉ có một win result
free spin luôn chỉ 10 không cộng thêm
golden là item riêng
```

Frontend phải đọc từ response/config:

```text
reels
gameConfig.reelRows
cascadeSteps
removedPositions
goldenTransforms
freeSpin
state.mode
multiplier
symbols[]
```

---

---

# Bản chốt Frontend

```text
Reuse socket cũ.
Reuse numeric command cũ.
Render dynamic reels 4-5-5-5-4.
Không dùng linesWin.
Dùng cascadeSteps để chạy animation.
Dùng removedPositions để explode.
Dùng goldenTransforms để animate Golden → Wild.
Dùng freeSpin object để hiển thị state.
Không tự giả định BONUS / JP symbol.
```

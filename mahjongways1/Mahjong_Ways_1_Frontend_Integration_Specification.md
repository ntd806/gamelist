# Mahjong Ways 1 — Frontend Integration Specification

Dưới đây là bản tài liệu chuẩn cho **Mahjong Ways 1 / Đường Mạt Chược**, tách riêng **Backend** và **Frontend**. Bản này **không dùng rule của Mahjong Ways 2**.

---

# Mahjong Ways 1 — Backend & Frontend Specification

## 0. Phạm vi tài liệu

Tài liệu này áp dụng cho game:

```text
Đường Mạt Chược / Mahjong Ways 1
```

Không áp dụng cho:

```text
Đường Mạt Chược 2 / Mahjong Ways 2
```

Khác biệt lớn nhất:

| Game           |    Layout |      Ways | Free Spin gốc |
| -------------- | --------: | --------: | ------------: |
| Mahjong Ways 1 | 4-4-4-4-4 | 1024 ways | 12 free spins |
| Mahjong Ways 2 | 4-5-5-5-4 | 2000 ways | 10 free spins |

---

---

# B. Mahjong Ways 1 — Frontend Integration Specification

---

# 1. Frontend overview

Frontend cần render:

```text
5 reels
4 rows mỗi reel
1024 ways
cascade animation
golden overlay
golden → wild transform
free spin state
multiplier per cascade step
```

Không dùng layout của Mahjong Ways 2:

```text
4-5-5-5-4
2000 ways
```

---

# 2. Init game config

Khi `SUBSCRIBE` hoặc `INFO`, backend nên trả:

```json
{
  "cmd": "TBD_INFO_MAHJONG_WAYS",
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
    "gameCode": "MAHJONG_WAYS",
    "reelCount": 5,
    "reelRows": [4, 4, 4, 4, 4],
    "totalWays": 1024,
    "minMatchedReels": 3,
    "winDirection": "LEFT_TO_RIGHT",
    "hasCascade": true,
    "hasGoldenSymbol": true,
    "hasFreeSpin": true
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
    "baseFreeSpin": 12,
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

---

# 3. Symbol init

```json
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
]
```

Không tự giả định:

```text
BONUS
JP / JACKPOT symbol
```

nếu backend không trả.

---

# 4. Board response

Frontend nhận reels dạng:

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
    { "symbol": "ITEM_4", "golden": true }
  ],
  [
    { "symbol": "ITEM_1", "golden": false },
    { "symbol": "ITEM_3", "golden": true },
    { "symbol": "ITEM_4", "golden": false },
    { "symbol": "ITEM_5", "golden": false }
  ],
  [
    { "symbol": "ITEM_1", "golden": false },
    { "symbol": "ITEM_2", "golden": true },
    { "symbol": "ITEM_3", "golden": false },
    { "symbol": "ITEM_4", "golden": false }
  ],
  [
    { "symbol": "ITEM_2", "golden": false },
    { "symbol": "ITEM_3", "golden": false },
    { "symbol": "ITEM_4", "golden": false },
    { "symbol": "ITEM_5", "golden": false }
  ]
]
```

Vì Mahjong Ways 1 là board đều 4x5 nên frontend có thể render grid 4 rows × 5 reels, nhưng vẫn nên giữ format `reels[reel][row]` để thống nhất với các game ways khác.

---

# 5. Play request

```json
{
  "cmd": "TBD_PLAY_MAHJONG_WAYS",
  "betSize": 2.5,
  "betLevel": 9,
  "baseBet": 20,
  "turbo": false
}
```

Frontend có thể hiển thị:

```text
lineBet = betSize × betLevel
totalBet = lineBet × baseBet
```

---

# 6. Result response

```json
{
  "cmd": "TBD_RESULT_MAHJONG_WAYS",
  "spinId": "SPIN_10001",

  "reels": [],

  "cascadeSteps": [],

  "totalWin": 4800,
  "balance": 1050000,

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

# 7. Cascade step response

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

Frontend render:

```text
render reelsBefore
highlight wins[].positions
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
  "payTableValue": 10,
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

---

# 9. Golden transform response

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

# 10. Free Spin response

```json
"freeSpin": {
  "triggered": true,
  "awarded": 12,
  "remaining": 12,
  "retriggered": false,
  "scatterCount": 3
}
```

Nếu 4 Scatter:

```json
"freeSpin": {
  "triggered": true,
  "awarded": 14,
  "remaining": 14,
  "retriggered": false,
  "scatterCount": 4
}
```

Frontend cần hiển thị:

```text
Free Spin intro
12 free spins hoặc nhiều hơn nếu có extra Scatter
remaining free spins
retrigger nếu có
free spin multiplier x2/x4/x6/x10
```

---

# 11. Frontend render flow

```text
Receive RESULT_MAHJONG_WAYS
↓
Render reels 5x4
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

# 12. Những thứ frontend không được tự giả định

Frontend không tự giả định:

```text
Mahjong Ways 1 là 2000 ways
layout 4-5-5-5-4
Free Spin gốc là 10
Có reel 3 golden trong Free Spin
Có BONUS symbol
Có JP symbol trên reels
Golden là symbol riêng
Một spin chỉ có một win result
```

Frontend phải đọc từ config/response:

```text
gameConfig.reelRows
gameConfig.totalWays
symbols[]
cascadeSteps
goldenTransforms
freeSpin
state.mode
multipliers
```

---

---

# C. Chốt cuối

## Mahjong Ways 1 frontend
```text
Render 5x4 reels
Display 1024 ways
Use cascadeSteps
Use removedPositions
Use goldenTransforms
Use freeSpin state
Do not assume BONUS/JP symbol
Do not use Mahjong Ways 2 layout/rules
```

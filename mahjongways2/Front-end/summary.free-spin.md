## Response `cmd=4020` dùng chung cho mọi mode

Frontend chỉ cần đọc một schema duy nhất:

```json
{
  "cmd": 4020,
  "summaryType": "PLAY_SUMMARY",
  "status": "COMPLETED",

  "mode": "FREE_SPIN",
  "summaryScope": "FREE_SPIN_SESSION",

  "sessionId": "SPIN_TRIGGER_abc123",
  "triggerSpinId": "SPIN_TRIGGER_abc123",
  "spinId": "SPIN_FS_10",
  "roundId": "RND_MW2_SPIN_FS_10",
  "displaySpinId": "MW2-000140",
  "dailySpinCount": 140,

  "roomId": 1,
  "betOptionId": "R1_BS_250_BL_9",

  "bet": {
    "totalBet": 450,
    "lockedBet": 450,
    "lockedTotalBet": 450,
    "referenceBet": 450,

    "chargedAmount": 0,
    "displayBet": 0,
    "actualBet": 0,
    "paid": false
  },

  "win": {
    "totalWin": 1280,
    "profitAmount": 1280,
    "winLevel": "NONE",
    "winMultiplier": 2.844444
  },

  "freeSpin": {
    "enabled": true,
    "sessionId": "SPIN_TRIGGER_abc123",

    "triggered": false,
    "retriggered": false,
    "event": "COMPLETED",

    "awardedThisSpin": 0,
    "totalAwarded": 10,
    "usedThisSummary": 10,
    "totalPlayed": 10,

    "remainingBefore": 1,
    "remainingAfter": 0,
    "remaining": 0,

    "lockedTotalBet": 450,
    "chargedAmount": 0,
    "displayBet": 0,
    "actualBet": 0,
    "referenceBet": 450
  },

  "currency": "VND",
  "balance": 100001280,

  "startedAt": 1780477630000,
  "completedAt": 1780477727000,

  "items": [
    {
      "mode": "FREE_SPIN",
      "spinId": "SPIN_FS_01",
      "roundId": "RND_MW2_SPIN_FS_01",
      "displaySpinId": "MW2-000131",
      "dailySpinCount": 131,
      "createdAt": 1780477630000,

      "bet": {
        "totalBet": 450,
        "lockedBet": 450,
        "referenceBet": 450,
        "chargedAmount": 0,
        "displayBet": 0,
        "actualBet": 0,
        "paid": false
      },

      "win": {
        "totalWin": 160,
        "profitAmount": 160
      },

      "freeSpin": {
        "event": "CONSUMED",
        "remainingBefore": 10,
        "remainingAfter": 9,
        "awarded": 0
      }
    },
    {
      "mode": "FREE_SPIN",
      "spinId": "SPIN_FS_10",
      "roundId": "RND_MW2_SPIN_FS_10",
      "displaySpinId": "MW2-000140",
      "dailySpinCount": 140,
      "createdAt": 1780477727000,

      "bet": {
        "totalBet": 450,
        "lockedBet": 450,
        "referenceBet": 450,
        "chargedAmount": 0,
        "displayBet": 0,
        "actualBet": 0,
        "paid": false
      },

      "win": {
        "totalWin": 240,
        "profitAmount": 240
      },

      "freeSpin": {
        "event": "COMPLETED",
        "remainingBefore": 1,
        "remainingAfter": 0,
        "awarded": 0
      }
    }
  ]
}
```

## Cùng schema này, nếu là BASE bình thường

Không đổi cấu trúc, chỉ đổi value:

```json
{
  "cmd": 4020,
  "summaryType": "PLAY_SUMMARY",
  "status": "COMPLETED",

  "mode": "BASE",
  "summaryScope": "SINGLE_SPIN",

  "sessionId": "SPIN_BASE_abc001",
  "triggerSpinId": null,
  "spinId": "SPIN_BASE_abc001",
  "roundId": "RND_MW2_SPIN_BASE_abc001",
  "displaySpinId": "MW2-000120",
  "dailySpinCount": 120,

  "roomId": 1,
  "betOptionId": "R1_BS_250_BL_9",

  "bet": {
    "totalBet": 450,
    "lockedBet": 450,
    "lockedTotalBet": 450,
    "referenceBet": 450,

    "chargedAmount": 450,
    "displayBet": 450,
    "actualBet": 450,
    "paid": true
  },

  "win": {
    "totalWin": 320,
    "profitAmount": -130,
    "winLevel": "NONE",
    "winMultiplier": 0.711111
  },

  "freeSpin": {
    "enabled": false,
    "sessionId": null,

    "triggered": false,
    "retriggered": false,
    "event": "NONE",

    "awardedThisSpin": 0,
    "totalAwarded": 0,
    "usedThisSummary": 0,
    "totalPlayed": 0,

    "remainingBefore": 0,
    "remainingAfter": 0,
    "remaining": 0,

    "lockedTotalBet": 450,
    "chargedAmount": 0,
    "displayBet": 0,
    "actualBet": 0,
    "referenceBet": 450
  },

  "currency": "VND",
  "balance": 999999870,

  "startedAt": 1780477627000,
  "completedAt": 1780477629000,

  "items": [
    {
      "mode": "BASE",
      "spinId": "SPIN_BASE_abc001",
      "roundId": "RND_MW2_SPIN_BASE_abc001",
      "displaySpinId": "MW2-000120",
      "dailySpinCount": 120,
      "createdAt": 1780477627000,

      "bet": {
        "totalBet": 450,
        "lockedBet": 450,
        "referenceBet": 450,
        "chargedAmount": 450,
        "displayBet": 450,
        "actualBet": 450,
        "paid": true
      },

      "win": {
        "totalWin": 320,
        "profitAmount": -130
      },

      "freeSpin": {
        "event": "NONE",
        "remainingBefore": 0,
        "remainingAfter": 0,
        "awarded": 0
      }
    }
  ]
}
```

## Nếu BASE trúng Free Spin

Vẫn cùng schema. Đây là tổng kết **lượt BASE vừa xong**, chưa phải tổng kết cả phiên Free Spin:

```json
{
  "cmd": 4020,
  "summaryType": "PLAY_SUMMARY",
  "status": "COMPLETED",

  "mode": "BASE",
  "summaryScope": "SINGLE_SPIN",

  "sessionId": "SPIN_TRIGGER_abc123",
  "triggerSpinId": "SPIN_TRIGGER_abc123",
  "spinId": "SPIN_TRIGGER_abc123",
  "roundId": "RND_MW2_SPIN_TRIGGER_abc123",
  "displaySpinId": "MW2-000130",
  "dailySpinCount": 130,

  "roomId": 1,
  "betOptionId": "R1_BS_250_BL_9",

  "bet": {
    "totalBet": 450,
    "lockedBet": 450,
    "lockedTotalBet": 450,
    "referenceBet": 450,

    "chargedAmount": 450,
    "displayBet": 450,
    "actualBet": 450,
    "paid": true
  },

  "win": {
    "totalWin": 100,
    "profitAmount": -350,
    "winLevel": "NONE",
    "winMultiplier": 0.222222
  },

  "freeSpin": {
    "enabled": true,
    "sessionId": "SPIN_TRIGGER_abc123",

    "triggered": true,
    "retriggered": false,
    "event": "TRIGGERED",

    "awardedThisSpin": 10,
    "totalAwarded": 10,
    "usedThisSummary": 0,
    "totalPlayed": 0,

    "remainingBefore": 0,
    "remainingAfter": 10,
    "remaining": 10,

    "lockedTotalBet": 450,
    "chargedAmount": 0,
    "displayBet": 0,
    "actualBet": 0,
    "referenceBet": 450
  },

  "currency": "VND",
  "balance": 999999650,

  "startedAt": 1780477627000,
  "completedAt": 1780477629000,

  "items": [
    {
      "mode": "BASE",
      "spinId": "SPIN_TRIGGER_abc123",
      "roundId": "RND_MW2_SPIN_TRIGGER_abc123",
      "displaySpinId": "MW2-000130",
      "dailySpinCount": 130,
      "createdAt": 1780477627000,

      "bet": {
        "totalBet": 450,
        "lockedBet": 450,
        "referenceBet": 450,
        "chargedAmount": 450,
        "displayBet": 450,
        "actualBet": 450,
        "paid": true
      },

      "win": {
        "totalWin": 100,
        "profitAmount": -350
      },

      "freeSpin": {
        "event": "TRIGGERED",
        "remainingBefore": 0,
        "remainingAfter": 10,
        "awarded": 10
      }
    }
  ]
}
```

## Ý nghĩa field chính

`summaryType` luôn là `PLAY_SUMMARY`, để frontend không phải phân biệt schema.

`summaryScope` cho biết gói này tổng kết phạm vi nào:

```text
SINGLE_SPIN = tổng kết 1 spin vừa xong, thường là BASE
FREE_SPIN_SESSION = tổng kết cả phiên Free Spin đã kết thúc
```

`mode` vẫn giữ để biết summary này phát sinh từ mode nào, nhưng frontend không cần đổi schema theo mode.

`bet.totalBet`, `bet.lockedBet`, `bet.referenceBet` là mức cược dùng để tính payout.

`bet.chargedAmount`, `bet.displayBet`, `bet.actualBet` là tiền thực tế bị trừ ví.

`win.totalWin` là tổng thắng trong phạm vi summary.

`win.profitAmount` là thắng/thua thực tế:

```text
profitAmount = totalWin - chargedAmount
```

`freeSpin.awardedThisSpin` là số lượt Free Spin vừa được cộng từ spin hiện tại.

`freeSpin.usedThisSummary` là số lượt Free Spin đã dùng trong phạm vi summary.

Với BASE bình thường:

```text
awardedThisSpin = 0
usedThisSummary = 0
remaining = 0
```

Với BASE trigger Free Spin:

```text
awardedThisSpin = 10
usedThisSummary = 0
remaining = 10
```

Với tổng kết phiên Free Spin:

```text
awardedThisSpin = 0
usedThisSummary = 10
totalPlayed = 10
remaining = 0
```

## Rule frontend dùng chung

Frontend chỉ cần xử lý:

```js
if (message.cmd === 4020) {
  renderSummary({
    bet: message.bet.displayBet,
    referenceBet: message.bet.referenceBet,
    totalWin: message.win.totalWin,
    profit: message.win.profitAmount,
    freeSpinUsed: message.freeSpin.usedThisSummary,
    freeSpinRemaining: message.freeSpin.remaining
  })
}
```

Không cần chia hai object khác nhau cho BASE và FREE_SPIN nữa.

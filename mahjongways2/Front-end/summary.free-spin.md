
---

## 1. `cmd=4020` cho `mode=BASE`

Dùng sau khi server đã trả xong `cmd=4001` của một lượt quay BASE. Nếu BASE spin có trúng Free Spin thì `freeSpin.triggered = true`; nếu không trúng thì `freeSpin.triggered = false`.

```json
{
  "cmd": 4020,
  "mode": "BASE",
  "summaryType": "BASE_SPIN_SUMMARY",

  "status": "COMPLETED",

  "sessionId": "SPIN_TRIGGER_abc123",
  "spinId": "SPIN_TRIGGER_abc123",
  "roundId": "RND_MW2_SPIN_TRIGGER_abc123",
  "displaySpinId": "MW2-000130",
  "dailySpinCount": 130,

  "roomId": 1,
  "betOptionId": "R1_BS_250_BL_9",

  "totalBet": 450,
  "lockedTotalBet": 450,
  "chargedAmount": 450,
  "displayBet": 450,
  "actualBet": 450,
  "referenceBet": 450,
  "paid": true,

  "totalWin": 100,
  "profitAmount": -350,
  "winLevel": "NONE",
  "winMultiplier": 0.222222,

  "currency": "VND",
  "balance": 999999650,

  "freeSpin": {
    "triggered": true,
    "awarded": 10,
    "remaining": 10,
    "remainingBefore": 0,
    "remainingAfter": 10,
    "event": "TRIGGERED",
    "sessionId": "SPIN_TRIGGER_abc123",
    "lockedTotalBet": 450
  },

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

      "totalBet": 450,
      "lockedBet": 450,
      "referenceBet": 450,

      "chargedAmount": 450,
      "displayBet": 450,
      "actualBet": 450,
      "paid": true,

      "totalWin": 100,
      "profitAmount": -350,

      "freeSpinTriggered": true,
      "freeSpinAwarded": 10,
      "freeSpinEvent": "TRIGGERED",
      "freeSpinSessionId": "SPIN_TRIGGER_abc123"
    }
  ]
}
```

Nếu BASE spin **không trúng Free Spin**, phần `freeSpin` sẽ là:

```json
{
  "triggered": false,
  "awarded": 0,
  "remaining": 0,
  "remainingBefore": 0,
  "remainingAfter": 0,
  "event": "NONE",
  "sessionId": null,
  "lockedTotalBet": 450
}
```

---

## 2. `cmd=4020` cho `mode=FREE_SPIN`

Dùng khi người chơi đã quay hết toàn bộ lượt Free Spin. Server push gói này sau khi `4001` của lượt Free Spin cuối đã gửi xong.

```json
{
  "cmd": 4020,
  "mode": "FREE_SPIN",
  "summaryType": "FREE_SPIN_SESSION_SUMMARY",

  "status": "COMPLETED",

  "sessionId": "SPIN_TRIGGER_abc123",
  "triggerSpinId": "SPIN_TRIGGER_abc123",

  "totalAwarded": 10,
  "totalPlayed": 10,
  "remaining": 0,

  "roomId": 1,
  "betOptionId": "R1_BS_250_BL_9",

  "totalBet": 450,
  "lockedTotalBet": 450,
  "chargedAmount": 0,
  "displayBet": 0,
  "actualBet": 0,
  "referenceBet": 450,
  "paid": false,

  "totalWin": 1280,
  "profitAmount": 1280,

  "currency": "VND",
  "balance": 100001280,

  "freeSpin": {
    "triggered": false,
    "awarded": 0,
    "remaining": 0,
    "event": "COMPLETED",
    "sessionId": "SPIN_TRIGGER_abc123",
    "lockedTotalBet": 450
  },

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

      "totalBet": 450,
      "lockedBet": 450,
      "referenceBet": 450,

      "chargedAmount": 0,
      "displayBet": 0,
      "actualBet": 0,
      "paid": false,

      "totalWin": 160,
      "profitAmount": 160,

      "remainingBefore": 10,
      "remainingAfter": 9,
      "event": "CONSUMED"
    },
    {
      "mode": "FREE_SPIN",

      "spinId": "SPIN_FS_02",
      "roundId": "RND_MW2_SPIN_FS_02",
      "displaySpinId": "MW2-000132",
      "dailySpinCount": 132,
      "createdAt": 1780477640000,

      "totalBet": 450,
      "lockedBet": 450,
      "referenceBet": 450,

      "chargedAmount": 0,
      "displayBet": 0,
      "actualBet": 0,
      "paid": false,

      "totalWin": 0,
      "profitAmount": 0,

      "remainingBefore": 9,
      "remainingAfter": 8,
      "event": "CONSUMED"
    },
    {
      "mode": "FREE_SPIN",

      "spinId": "SPIN_FS_03",
      "roundId": "RND_MW2_SPIN_FS_03",
      "displaySpinId": "MW2-000133",
      "dailySpinCount": 133,
      "createdAt": 1780477650000,

      "totalBet": 450,
      "lockedBet": 450,
      "referenceBet": 450,

      "chargedAmount": 0,
      "displayBet": 0,
      "actualBet": 0,
      "paid": false,

      "totalWin": 220,
      "profitAmount": 220,

      "remainingBefore": 8,
      "remainingAfter": 7,
      "event": "CONSUMED"
    },
    {
      "mode": "FREE_SPIN",

      "spinId": "SPIN_FS_10",
      "roundId": "RND_MW2_SPIN_FS_10",
      "displaySpinId": "MW2-000140",
      "dailySpinCount": 140,
      "createdAt": 1780477727000,

      "totalBet": 450,
      "lockedBet": 450,
      "referenceBet": 450,

      "chargedAmount": 0,
      "displayBet": 0,
      "actualBet": 0,
      "paid": false,

      "totalWin": 240,
      "profitAmount": 240,

      "remainingBefore": 1,
      "remainingAfter": 0,
      "event": "COMPLETED"
    }
  ]
}
```

---

## Rule frontend cần hiểu

`cmd=4020` là gói summary server tự push sau `cmd=4001`.

Với `mode=BASE`:

```text
summaryType = BASE_SPIN_SUMMARY
```

Nó là tổng kết của **1 lượt quay BASE vừa xong**.

Với `mode=FREE_SPIN`:

```text
summaryType = FREE_SPIN_SESSION_SUMMARY
```

Nó là tổng kết của **cả phiên Free Spin đã quay hết**.

Rule hiển thị tiền cược:

```text
displayBet / chargedAmount = tiền thực tế bị trừ ví
lockedTotalBet / referenceBet = mức cược dùng để tính payout
```

Nên:

```text
BASE      → displayBet = 450, chargedAmount = 450
FREE_SPIN → displayBet = 0, chargedAmount = 0, referenceBet = 450
```

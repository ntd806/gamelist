```text
cmd=4001 có thể trả mode = BASE hoặc FREE_SPIN khi ở mode=freespin.
cmd=4020 chỉ trả cho FREE_SPIN summary, không có mode BASE.
```

---

# 1. `cmd=4001` — Mode `BASE`, không trúng Free Spin

Trường hợp quay thường, không có scatter đủ để vào Free Spin.

```json
{
  "cmd": 4001,
  "clientRequestId": "base-spin-001",
  "spinId": "SPIN_BASE_001",
  "roundId": "RND_MW2_SPIN_BASE_001",
  "roomId": 1,

  "totalWin": 0,
  "winLevel": "NONE",
  "winMultiplier": 0,
  "balance": 999999550,

  "bet": {
    "roomId": 1,
    "betOptionId": "R1_BS_250_BL_9",
    "betSize": 2.5,
    "betLevel": 9,
    "baseBet": 20,
    "lineBet": 22.5,
    "totalBet": 450,

    "chargedAmount": 450,
    "displayBet": 450,
    "actualBet": 450,
    "lockedBet": 450,
    "referenceBet": 450,
    "paid": true
  },

  "seamless": {
    "enabled": true,
    "payoutStatus": "SUCCESS"
  },

  "freeSpin": {
    "triggered": false,
    "awarded": 0,
    "remaining": 0,
    "retriggered": false,
    "scatterCount": 1,
    "event": "NONE",

    "requiredScatterCount": 3,
    "totalAwarded": 0,
    "remainingBefore": 0,
    "remainingAfter": 0,

    "active": false,
    "mode": "BASE",
    "sessionId": null,

    "lockedTotalBet": null,
    "chargedAmount": null,
    "displayBet": null,
    "actualBet": null,
    "referenceBet": null,

    "requestTotalBet": 450,
    "betMismatchIgnored": false
  },

  "state": {
    "mode": "BASE",
    "bigWin": false,
    "winLevel": "NONE",
    "winMultiplier": 0,
    "turbo": false,
    "autoPlay": false
  },

  "dailySpinCount": 120
}
```

### Frontend xử lý

```text
Mode = BASE
Bet hiển thị = displayBet = 450
Có trừ ví = paid true
Không có 4020 sau response này
```

---

# 2. `cmd=4001` — Mode `BASE`, trúng Free Spin

Đây là lượt quay thường nhưng ra đủ Scatter để **kích hoạt Free Spin**.

Lưu ý: **vẫn là mode `BASE`**, vì lượt này là lượt trả tiền thật. Sau response này **không gửi 4020**, vì Free Spin mới bắt đầu, chưa kết thúc.

```json
{
  "cmd": 4001,
  "clientRequestId": "base-trigger-freespin-001",
  "spinId": "SPIN_TRIGGER_abc123",
  "roundId": "RND_MW2_SPIN_TRIGGER_abc123",
  "roomId": 1,

  "totalWin": 100,
  "winLevel": "NONE",
  "winMultiplier": 0.222222,
  "balance": 999999650,

  "bet": {
    "roomId": 1,
    "betOptionId": "R1_BS_250_BL_9",
    "betSize": 2.5,
    "betLevel": 9,
    "baseBet": 20,
    "lineBet": 22.5,
    "totalBet": 450,

    "chargedAmount": 450,
    "displayBet": 450,
    "actualBet": 450,
    "lockedBet": 450,
    "referenceBet": 450,
    "paid": true
  },

  "seamless": {
    "enabled": true,
    "payoutStatus": "SUCCESS"
  },

  "freeSpin": {
    "triggered": true,
    "awarded": 10,
    "remaining": 10,
    "retriggered": false,
    "scatterCount": 3,
    "event": "TRIGGERED",

    "requiredScatterCount": 3,
    "totalAwarded": 10,
    "remainingBefore": 0,
    "remainingAfter": 10,

    "scatterColumns": [0, 2, 4],
    "scatterPositions": [
      { "col": 0, "row": 2, "cellId": "s0-c0-r2" },
      { "col": 2, "row": 1, "cellId": "s0-c2-r1" },
      { "col": 4, "row": 3, "cellId": "s0-c4-r3" }
    ],

    "active": true,
    "mode": "FREE_SPIN",
    "sessionId": "SPIN_TRIGGER_abc123",

    "lockedTotalBet": 450,
    "chargedAmount": 0,
    "displayBet": 0,
    "actualBet": 0,
    "referenceBet": 450,

    "requestTotalBet": 450,
    "betMismatchIgnored": false
  },

  "state": {
    "mode": "BASE",
    "bigWin": false,
    "winLevel": "NONE",
    "winMultiplier": 0.222222,
    "turbo": false,
    "autoPlay": false
  },

  "dailySpinCount": 121
}
```

### Frontend xử lý

```text
state.mode = BASE
freeSpin.event = TRIGGERED
freeSpin.awarded = 10

Hiểu là:
- Đây là lượt BASE có trả tiền cược.
- Người chơi vừa được cấp 10 lượt Free Spin.
- Chưa show summary.
- Không có gói 4020 sau response này.
```

---

# 3. `cmd=4001` — Mode `FREE_SPIN`, đang còn lượt

Đây là một lượt Free Spin đang được tiêu thụ. Không bị trừ tiền.

```json
{
  "cmd": 4001,
  "clientRequestId": "freespin-consumed-001",
  "spinId": "SPIN_FS_01",
  "roundId": "RND_MW2_SPIN_FS_01",
  "roomId": 1,

  "totalWin": 160,
  "winLevel": "NONE",
  "winMultiplier": 0.355555,
  "balance": 999999810,

  "bet": {
    "roomId": 1,
    "betOptionId": "R1_BS_250_BL_9",
    "betSize": 2.5,
    "betLevel": 9,
    "baseBet": 20,
    "lineBet": 22.5,
    "totalBet": 450,

    "chargedAmount": 0,
    "displayBet": 0,
    "actualBet": 0,
    "lockedBet": 450,
    "referenceBet": 450,
    "paid": false
  },

  "seamless": {
    "enabled": true,
    "payoutStatus": "SUCCESS"
  },

  "freeSpin": {
    "triggered": false,
    "awarded": 0,
    "remaining": 9,
    "retriggered": false,
    "scatterCount": 0,
    "event": "CONSUMED",

    "requiredScatterCount": 3,
    "totalAwarded": 10,
    "remainingBefore": 10,
    "remainingAfter": 9,

    "active": true,
    "mode": "FREE_SPIN",
    "sessionId": "SPIN_TRIGGER_abc123",

    "lockedTotalBet": 450,
    "chargedAmount": 0,
    "displayBet": 0,
    "actualBet": 0,
    "referenceBet": 450,

    "requestTotalBet": 450,
    "betMismatchIgnored": false
  },

  "state": {
    "mode": "FREE_SPIN",
    "bigWin": false,
    "winLevel": "NONE",
    "winMultiplier": 0.355555,
    "turbo": false,
    "autoPlay": false
  },

  "dailySpinCount": 122
}
```

### Frontend xử lý

```text
state.mode = FREE_SPIN
freeSpin.event = CONSUMED
remainingAfter = 9

Hiểu là:
- Đang quay Free Spin.
- Còn 9 lượt.
- Không trừ ví.
- Không có 4020 sau response này.
```

---

# 4. `cmd=4001` — Mode `FREE_SPIN`, lượt cuối

Đây là lượt Free Spin cuối. Server trả `4001` trước.

```json
{
  "cmd": 4001,
  "clientRequestId": "freespin-final-001",
  "spinId": "SPIN_FS_10",
  "roundId": "RND_MW2_SPIN_FS_10",
  "roomId": 1,

  "totalWin": 240,
  "winLevel": "NONE",
  "winMultiplier": 0.533333,
  "balance": 100001280,

  "bet": {
    "roomId": 1,
    "betOptionId": "R1_BS_250_BL_9",
    "betSize": 2.5,
    "betLevel": 9,
    "baseBet": 20,
    "lineBet": 22.5,
    "totalBet": 450,

    "chargedAmount": 0,
    "displayBet": 0,
    "actualBet": 0,
    "lockedBet": 450,
    "referenceBet": 450,
    "paid": false
  },

  "seamless": {
    "enabled": true,
    "payoutStatus": "SUCCESS"
  },

  "freeSpin": {
    "triggered": false,
    "awarded": 0,
    "remaining": 0,
    "retriggered": false,
    "scatterCount": 0,
    "event": "COMPLETED",

    "requiredScatterCount": 3,
    "totalAwarded": 10,
    "remainingBefore": 1,
    "remainingAfter": 0,

    "active": false,
    "mode": "FREE_SPIN",
    "sessionId": "SPIN_TRIGGER_abc123",

    "lockedTotalBet": 450,
    "chargedAmount": 0,
    "displayBet": 0,
    "actualBet": 0,
    "referenceBet": 450,

    "requestTotalBet": 450,
    "betMismatchIgnored": false
  },

  "state": {
    "mode": "FREE_SPIN",
    "bigWin": false,
    "winLevel": "NONE",
    "winMultiplier": 0.533333,
    "turbo": false,
    "autoPlay": false
  },

  "dailySpinCount": 131
}
```

Sau khi client nhận xong gói này, server tự push tiếp `cmd=4020`.

---

# 5. `cmd=4020` — Free Spin Summary

Gói này **chỉ có cho mode `FREE_SPIN` đã kết thúc**. Không có `4020` cho BASE.

```json
{
  "cmd": 4020,
  "mode": "FREE_SPIN",

  "sessionId": "SPIN_TRIGGER_abc123",
  "triggerSpinId": "SPIN_TRIGGER_abc123",

  "status": "COMPLETED",

  "totalAwarded": 10,
  "totalPlayed": 10,
  "remaining": 0,

  "lockedTotalBet": 450,
  "chargedAmount": 0,
  "displayBet": 0,
  "actualBet": 0,
  "referenceBet": 450,

  "totalWin": 1280,
  "currency": "VND",

  "startedAt": 1780477627000,
  "completedAt": 1780477727000,

  "items": [
    {
      "spinId": "SPIN_FS_01",
      "roundId": "RND_MW2_SPIN_FS_01",
      "displaySpinId": "MW2-000122",
      "dailySpinCount": 122,
      "createdAt": 1780477630000,

      "totalBet": 450,
      "lockedBet": 450,
      "referenceBet": 450,

      "chargedAmount": 0,
      "displayBet": 0,
      "actualBet": 0,
      "paid": false,

      "totalWin": 160,
      "remainingBefore": 10,
      "remainingAfter": 9,
      "event": "CONSUMED"
    },
    {
      "spinId": "SPIN_FS_02",
      "roundId": "RND_MW2_SPIN_FS_02",
      "displaySpinId": "MW2-000123",
      "dailySpinCount": 123,
      "createdAt": 1780477640000,

      "totalBet": 450,
      "lockedBet": 450,
      "referenceBet": 450,

      "chargedAmount": 0,
      "displayBet": 0,
      "actualBet": 0,
      "paid": false,

      "totalWin": 0,
      "remainingBefore": 9,
      "remainingAfter": 8,
      "event": "CONSUMED"
    },
    {
      "spinId": "SPIN_FS_03",
      "roundId": "RND_MW2_SPIN_FS_03",
      "displaySpinId": "MW2-000124",
      "dailySpinCount": 124,
      "createdAt": 1780477650000,

      "totalBet": 450,
      "lockedBet": 450,
      "referenceBet": 450,

      "chargedAmount": 0,
      "displayBet": 0,
      "actualBet": 0,
      "paid": false,

      "totalWin": 220,
      "remainingBefore": 8,
      "remainingAfter": 7,
      "event": "CONSUMED"
    },
    {
      "spinId": "SPIN_FS_10",
      "roundId": "RND_MW2_SPIN_FS_10",
      "displaySpinId": "MW2-000131",
      "dailySpinCount": 131,
      "createdAt": 1780477727000,

      "totalBet": 450,
      "lockedBet": 450,
      "referenceBet": 450,

      "chargedAmount": 0,
      "displayBet": 0,
      "actualBet": 0,
      "paid": false,

      "totalWin": 240,
      "remainingBefore": 1,
      "remainingAfter": 0,
      "event": "COMPLETED"
    }
  ]
}
```

## Rule cuối cùng cho frontend

```text
1. BASE bình thường:
   Nhận 4001.
   Không có 4020.

2. BASE trúng Free Spin:
   Nhận 4001 với state.mode=BASE, freeSpin.event=TRIGGERED.
   Không có 4020.

3. FREE_SPIN đang quay:
   Nhận 4001 với state.mode=FREE_SPIN, freeSpin.event=CONSUMED hoặc RETRIGGERED.
   Không có 4020.

4. FREE_SPIN lượt cuối:
   Nhận 4001 với state.mode=FREE_SPIN, freeSpin.event=COMPLETED, remainingAfter=0.
   Sau đó server tự push thêm 4020.
```

Điều kiện frontend show popup summary:

```js
if (response.cmd === 4020 && response.mode === "FREE_SPIN" && response.status === "COMPLETED") {
  showFreeSpinSummary(response)
}
```

Cách hiển thị Bet:

```text
displayBet / chargedAmount = tiền thực bị trừ
lockedTotalBet / referenceBet = mức cược dùng để tính thưởng
```

Với Free Spin:

```text
Bet hiển thị: 0
Locked/Reference Bet: 450
Total Win: 1280
```

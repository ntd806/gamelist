
---

## 1. Các field mới trong `bet`

Áp dụng cho response `cmd=4001` và history detail nếu có object `bet`.

```json
"bet": {
  "totalBet": 450,
  "chargedAmount": 0,
  "paid": false,

  "displayBet": 0,
  "actualBet": 0,
  "lockedBet": 450,
  "referenceBet": 450
}
```

### `chargedAmount`

Số tiền **thực tế bị trừ ví** ở lượt quay đó.

```text
BASE spin     → chargedAmount = totalBet
FREE_SPIN     → chargedAmount = 0
```

Ví dụ Free Spin được tính theo bet 450 nhưng không trừ ví:

```json
"chargedAmount": 0
```

---

### `displayBet`

Field khuyến nghị frontend dùng để hiển thị ở cột **Bet**.

```text
Nếu UI hiểu “Bet” = tiền người chơi thật sự bị trừ
→ dùng displayBet
```

Ví dụ:

```text
BASE spin     → displayBet = 450
FREE_SPIN     → displayBet = 0
```

---

### `actualBet`

Alias của `displayBet`.

Ý nghĩa cũng là:

```text
Tiền cược thực tế phát sinh/trừ ví trong lượt đó.
```

Frontend có thể dùng `displayBet` là chính, `actualBet` để đọc cho rõ nghĩa.

---

### `lockedBet`

Mức cược được khóa để tính payout.

Với Free Spin, dù người chơi không bị trừ tiền, game vẫn phải biết Free Spin đang tính thưởng theo mức cược nào.

Ví dụ người chơi trigger Free Spin từ bet 450:

```json
"lockedBet": 450
```

Các lượt Free Spin sau đó vẫn có:

```json
"lockedBet": 450
```

---

### `referenceBet`

Alias của `lockedBet`.

Ý nghĩa:

```text
Mức cược tham chiếu để tính tiền thắng.
```

Frontend có thể dùng để hiển thị tooltip/detail:

```text
Reference Bet: 450
```

---

### `paid`

Cho biết lượt quay này có trừ tiền ví hay không.

```text
BASE spin     → paid = true
FREE_SPIN     → paid = false
```

---

## 2. Các field mới trong history item `cmd=4016`

Mỗi item history sẽ có thêm:

```json
{
  "mode": "FREE_SPIN",
  "isFreeSpin": true,

  "totalBet": 450,
  "lockedBet": 450,
  "referenceBet": 450,

  "chargedAmount": 0,
  "displayBet": 0,
  "actualBet": 0,
  "paid": false
}
```

### Frontend nên dùng như sau

Nếu hiển thị cột **Bet**:

```text
Dùng displayBet hoặc chargedAmount
```

Nếu muốn hiển thị mức cược Free Spin được tính theo:

```text
Dùng lockedBet hoặc referenceBet
```

Ví dụ với Free Spin:

```text
Bet: 0
Locked Bet: 450
Win: 240
```

Không nên lấy `totalBet` để hiển thị tiền thực bị trừ ở Free Spin, vì `totalBet` là mức cược tham chiếu.

---

## 3. Field mới trong `freeSpin`

```json
"freeSpin": {
  "lockedTotalBet": 450,
  "chargedAmount": 0,
  "summary": { ... }
}
```

### `freeSpin.lockedTotalBet`

Mức cược khóa của toàn bộ phiên Free Spin.

Ví dụ:

```text
Người chơi quay BASE bet 450 và trúng 10 Free Spin
→ toàn bộ 10 lượt Free Spin dùng lockedTotalBet = 450 để tính thưởng
```

---

### `freeSpin.chargedAmount`

Số tiền thực tế bị trừ khi quay Free Spin.

Với Free Spin:

```json
"chargedAmount": 0
```

---

## 4. Object mới `freeSpin.summary`

Object này chỉ xuất hiện khi phiên Free Spin kết thúc:

```text
freeSpin.event = "COMPLETED"
remainingAfter = 0
```

Ví dụ:

```json
"freeSpin": {
  "event": "COMPLETED",
  "remainingAfter": 0,
  "summary": {
    "status": "COMPLETED",
    "sessionId": "SPIN_TRIGGER_abc123",
    "triggerSpinId": "SPIN_TRIGGER_abc123",

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

    "items": []
  }
}
```

### `summary.status`

Trạng thái phiên Free Spin.

```text
COMPLETED = đã quay hết phiên Free Spin
ACTIVE    = vẫn còn lượt
```

Trong popup tổng kết, frontend chỉ cần xử lý khi:

```text
status = COMPLETED
```

---

### `summary.sessionId`

ID của phiên Free Spin.

Dùng để group các lượt Free Spin thuộc cùng một phiên.

---

### `summary.triggerSpinId`

Spin ID của lượt BASE đã trigger ra Free Spin.

Thường bằng `sessionId`.

---

### `summary.totalAwarded`

Tổng số lượt Free Spin được cấp.

Ví dụ:

```text
3 Scatter → totalAwarded = 10
4 Scatter → totalAwarded = 12
5 Scatter → totalAwarded = 14
```

Nếu có retrigger, số này có thể lớn hơn số ban đầu.

---

### `summary.totalPlayed`

Số lượt Free Spin đã quay trong phiên.

Khi kết thúc bình thường:

```text
totalPlayed = totalAwarded
```

Ví dụ:

```json
"totalPlayed": 10
```

---

### `summary.remaining`

Số lượt Free Spin còn lại.

Khi popup tổng kết xuất hiện:

```json
"remaining": 0
```

---

### `summary.lockedTotalBet`

Mức cược khóa để tính payout cho toàn bộ phiên Free Spin.

Ví dụ:

```json
"lockedTotalBet": 450
```

---

### `summary.chargedAmount`

Tổng tiền thực tế bị trừ trong phiên Free Spin.

Với Free Spin:

```json
"chargedAmount": 0
```

---

### `summary.displayBet`

Field frontend có thể dùng để hiển thị Bet trong popup.

Với Free Spin:

```json
"displayBet": 0
```

---

### `summary.actualBet`

Alias của `displayBet`.

Ý nghĩa:

```text
Tiền thực tế bị trừ trong phiên Free Spin.
```

---

### `summary.referenceBet`

Mức cược tham chiếu để tính thưởng.

Ví dụ:

```json
"referenceBet": 450
```

---

### `summary.totalWin`

Tổng tiền thắng trong toàn bộ phiên Free Spin.

Lưu ý:

```text
Không cộng tiền thắng của spin BASE trigger.
Chỉ cộng các lượt mode = FREE_SPIN.
```

Ví dụ:

```json
"totalWin": 1280
```

Frontend dùng field này để hiển thị popup:

```text
You won 1280
```

---

### `summary.currency`

Đơn vị tiền tệ.

Ví dụ:

```json
"currency": "VND"
```

---

### `summary.startedAt`

Thời điểm bắt đầu phiên Free Spin, dạng timestamp milliseconds.

---

### `summary.completedAt`

Thời điểm kết thúc phiên Free Spin, dạng timestamp milliseconds.

---

### `summary.items`

Danh sách từng lượt Free Spin trong phiên, nếu backend trả.

Mỗi item gồm:

```json
{
  "spinId": "SPIN_FS_01",
  "roundId": "RND_MW2_SPIN_FS_01",
  "displaySpinId": "MW2-000101",
  "dailySpinCount": 101,
  "createdAt": 1780477630000,
  "totalWin": 160,
  "remainingBefore": 10,
  "remainingAfter": 9,
  "event": "CONSUMED"
}
```

Frontend chỉ cần dùng `items` nếu muốn hiển thị bảng chi tiết từng lượt Free Spin.

Nếu chỉ làm popup tổng kết, có thể bỏ qua `items`.

---

## 5. Rule frontend cần nhớ

```text
Nếu cần hiển thị tiền người chơi thật sự bị trừ:
→ dùng chargedAmount / displayBet / actualBet

Nếu cần hiển thị mức cược dùng để tính thắng:
→ dùng lockedBet / referenceBet / lockedTotalBet

Nếu cần hiện popup tổng kết Free Spin:
→ check freeSpin.event = "COMPLETED"
→ lấy freeSpin.summary.totalWin
```

Ví dụ Free Spin:

```text
Bet hiển thị: 0
Locked Bet: 450
Total Free Spin Win: 1280
```

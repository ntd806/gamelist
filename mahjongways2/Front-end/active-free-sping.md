# Frontend Guide — Scatter Anticipation to Free Spin Flow

## 1. Mục tiêu animation

Khi người chơi spin ở mode `BASE`, nếu kết quả có Free Spin trigger, frontend cần diễn đúng flow:

1. Reels bắt đầu quay bình thường.
2. Cột 1 và cột 2 xuất hiện Scatter trước.
3. Khi đã có 2 Scatter đầu, bật hiệu ứng anticipation cho 3 cột sau.
4. Cột 3, 4, 5 tiếp tục quay/chờ với hiệu ứng hồi hộp.
5. Nếu một trong 3 cột sau ra Scatter thứ 3 thì trigger Free Spin.
6. Hiển thị tổng số lượt Free Spin được thưởng.
7. Chuyển UI sang trạng thái Free Spin cho lượt spin tiếp theo.

Backend đã trả đủ metadata để frontend không cần tự đoán.

---

## 2. Cách xác định response này là BASE spin trigger Free Spin

Frontend check các field sau:

```json
state.mode = "BASE"
freeSpin.event = "TRIGGERED"
freeSpin.triggered = true
freeSpin.awarded > 0
freeSpin.remainingAfter > 0
```

Ví dụ response đạt:

```json
"state": {
  "mode": "BASE"
},
"freeSpin": {
  "triggered": true,
  "event": "TRIGGERED",
  "awarded": 2,
  "totalAwarded": 2,
  "remainingBefore": 0,
  "remainingAfter": 2,
  "remaining": 2
}
```

Ý nghĩa cho frontend:

```text
Đây là lượt BASE spin.
Lượt này có trigger Free Spin.
Người chơi được thưởng 2 lượt Free Spin.
Sau lượt này remaining Free Spin = 2.
```

---

## 3. Mapping cột backend và frontend

Backend dùng index từ `0`.

Frontend hiển thị theo cách người chơi nhìn là cột 1–5.

| Frontend | Backend |
| -------- | ------- |
| Cột 1    | col = 0 |
| Cột 2    | col = 1 |
| Cột 3    | col = 2 |
| Cột 4    | col = 3 |
| Cột 5    | col = 4 |

Vì vậy:

```json
firstScatterColumns: [0, 1]
```

nghĩa là:

```text
Scatter đầu tiên nằm ở cột 1 và cột 2.
```

---

## 4. Field chính để diễn Scatter anticipation

Frontend không cần tự tính anticipation. Dùng field này:

```json
"triggerAnimation": {
  "enabled": true,
  "type": "SCATTER_ANTICIPATION",
  "firstScatterColumns": [0, 1],
  "anticipationColumns": [2, 3, 4],
  "triggeredByColumns": [0, 1, 4],
  "revealOrder": [0, 1, 2, 3, 4]
}
```

Ý nghĩa:

```text
enabled = true
=> Có animation trigger Free Spin.

type = SCATTER_ANTICIPATION
=> Dùng flow anticipation cho Scatter.

firstScatterColumns = [0, 1]
=> Cột 1 và cột 2 là 2 Scatter đầu.

anticipationColumns = [2, 3, 4]
=> Cột 3, 4, 5 là các cột cần diễn hiệu ứng anticipation.

triggeredByColumns = [0, 1, 4]
=> Free Spin được trigger bởi Scatter ở cột 1, 2, 5.

revealOrder = [0, 1, 2, 3, 4]
=> Thứ tự reveal reel từ trái qua phải.
```

---

## 5. Sequence animation đề xuất cho frontend

### Phase 1 — Spin bình thường

Khi nhận response `cmd=4001`, frontend bắt đầu render `animationReels`.

Nếu:

```json
freeSpin.triggerAnimation.enabled = true
freeSpin.triggerAnimation.type = "SCATTER_ANTICIPATION"
```

thì dùng special flow Free Spin anticipation.

---

### Phase 2 — Reveal cột 1 và cột 2

Dựa vào:

```json
firstScatterColumns = [0, 1]
```

Frontend reveal cột 1 và cột 2 trước.

Sau khi 2 cột này dừng, tìm Scatter thật bằng `freeSpin.scatterPositions`.

Ví dụ:

```json
"scatterPositions": [
  {
    "col": 0,
    "row": 2,
    "cellId": "s0-c0-r2"
  },
  {
    "col": 1,
    "row": 1,
    "cellId": "s0-c1-r1"
  },
  {
    "col": 4,
    "row": 0,
    "cellId": "s0-c4-r0"
  }
]
```

Frontend highlight:

```text
cellId = s0-c0-r2
cellId = s0-c1-r1
```

Đây là 2 Scatter đầu.

---

### Phase 3 — Bật anticipation cho cột 3, 4, 5

Dựa vào:

```json
anticipationColumns = [2, 3, 4]
```

Frontend bật hiệu ứng anticipation cho cột 3, 4, 5.

Gợi ý animation:

```text
- Reels 3, 4, 5 quay chậm hơn.
- Thêm glow / shake / suspense sound.
- Có thể làm cột 3 dừng trước, rồi cột 4, rồi cột 5.
- Khi chưa thấy Scatter thứ 3 thì vẫn giữ cảm giác chờ.
```

Không nên tự hardcode cột 3,4,5 bằng frontend logic. Nên đọc trực tiếp từ:

```json
freeSpin.triggerAnimation.anticipationColumns
```

---

### Phase 4 — Reveal Scatter thứ 3

Dựa vào:

```json
triggeredByColumns = [0, 1, 4]
```

Trong ví dụ này, Scatter thứ 3 nằm ở:

```json
{
  "col": 4,
  "row": 0,
  "cellId": "s0-c4-r0"
}
```

Tức là frontend hiển thị Scatter thứ 3 ở cột 5.

Khi reveal tới `cellId=s0-c4-r0`, frontend nên:

```text
- Highlight Scatter thứ 3.
- Play âm thanh trigger.
- Dừng anticipation.
- Hiển thị hiệu ứng "Free Spin Triggered".
```

---

### Phase 5 — Hiển thị số lượt Free Spin được thưởng

Dùng các field:

```json
freeSpin.awarded
freeSpin.totalAwarded
freeSpin.remainingAfter
freeSpin.remaining
```

Ví dụ:

```json
"awarded": 2,
"totalAwarded": 2,
"remainingAfter": 2,
"remaining": 2
```

Frontend hiển thị:

```text
Free Spin x2
```

hoặc:

```text
2 Free Spins Awarded
```

Sau animation trigger, cập nhật UI Free Spin counter:

```text
Free Spins Remaining: 2
```

---

## 6. Cách xác định Scatter thật trên board

Không nên chỉ dựa vào `symbol=SCATTER` trong toàn bộ `animationReels`, vì một số cell có thể là buffer:

```json
"displayOnly": true
```

Frontend nên ưu tiên dùng:

```json
freeSpin.scatterPositions
```

và match theo:

```text
cellId
```

Ví dụ Scatter thật:

```text
s0-c0-r2
s0-c1-r1
s0-c4-r0
```

Không tính cell buffer như:

```text
s0-c4-bt0
```

vì cell này có:

```json
"displayOnly": true
```

Rule an toàn:

```text
Chỉ highlight Scatter trigger nếu cellId nằm trong freeSpin.scatterPositions.
Không highlight tất cả symbol=SCATTER nếu displayOnly=true.
```

---

## 7. Khi vào lượt Free Spin tiếp theo

Sau khi BASE trigger xong, frontend gửi spin tiếp theo như bình thường.

Backend sẽ trả:

```json
state.mode = "FREE_SPIN"
bet.chargedAmount = 0
bet.paid = false
```

Frontend hiểu:

```text
Đây là lượt quay Free Spin.
Không trừ tiền người chơi.
```

Khi consume lượt Free Spin, dùng:

```json
freeSpin.remainingBefore
freeSpin.remainingAfter
freeSpin.remaining
freeSpin.event
```

Ví dụ consume lượt đầu:

```json
"state": {
  "mode": "FREE_SPIN"
},
"bet": {
  "chargedAmount": 0,
  "paid": false
},
"freeSpin": {
  "event": "CONSUMED",
  "remainingBefore": 2,
  "remainingAfter": 1,
  "remaining": 1
}
```

Frontend hiển thị:

```text
Trước lượt này còn 2 Free Spin.
Sau lượt này còn 1 Free Spin.
```

---

## 8. Khi Free Spin kết thúc

Nếu response trả:

```json
state.mode = "FREE_SPIN"
freeSpin.event = "COMPLETED"
freeSpin.remainingBefore = 1
freeSpin.remainingAfter = 0
freeSpin.remaining = 0
```

Frontend hiểu:

```text
Đây là lượt Free Spin cuối.
Sau lượt này Free Spin kết thúc.
```

Sau khi animation win/cascade của lượt này kết thúc, frontend có thể:

```text
- Ẩn Free Spin counter.
- Hiển thị end Free Spin nếu có UI.
- Chuyển trạng thái chờ spin tiếp theo về BASE.
```

Lượt spin tiếp theo nếu không còn Free Spin sẽ là BASE spin bình thường và có trừ tiền.

---

## 9. Pseudo-code frontend

```js
function handleSpinResponse(res) {
  const fs = res.freeSpin;
  const mode = res.state?.mode;

  renderReels(res.animationReels);

  if (
    mode === "BASE" &&
    fs?.event === "TRIGGERED" &&
    fs?.triggered === true &&
    fs?.triggerAnimation?.enabled === true &&
    fs?.triggerAnimation?.type === "SCATTER_ANTICIPATION"
  ) {
    playScatterAnticipation(res);
    return;
  }

  if (mode === "FREE_SPIN") {
    updateFreeSpinCounter(fs.remainingAfter ?? fs.remaining);

    if (fs.event === "COMPLETED") {
      playFreeSpinCompleted();
    }

    return;
  }

  playNormalSpinResult(res);
}

function playScatterAnticipation(res) {
  const fs = res.freeSpin;
  const anim = fs.triggerAnimation;

  const firstCols = anim.firstScatterColumns;      // [0, 1]
  const anticipationCols = anim.anticipationColumns; // [2, 3, 4]
  const revealOrder = anim.revealOrder;            // [0, 1, 2, 3, 4]

  const scatterCellIds = new Set(
    fs.scatterPositions.map(pos => pos.cellId)
  );

  // 1. Reveal theo order.
  for (const col of revealOrder) {
    revealColumn(col);

    // 2. Nếu là cột Scatter thật thì highlight Scatter.
    const scatterInThisCol = fs.scatterPositions.filter(pos => pos.col === col);

    for (const pos of scatterInThisCol) {
      highlightCellById(pos.cellId);
    }

    // 3. Sau khi reveal cột 1,2 thì bật anticipation cho cột 3,4,5.
    if (arraysEqual(firstCols, [0, 1]) && col === 1) {
      startAnticipationOnColumns(anticipationCols);
    }
  }

  // 4. Khi đủ Scatter trigger, play Free Spin triggered.
  playFreeSpinTriggeredEffect({
    awarded: fs.awarded,
    totalAwarded: fs.totalAwarded,
    remaining: fs.remainingAfter
  });

  updateFreeSpinCounter(fs.remainingAfter);
}
```

---

## 10. Checklist frontend cần đảm bảo

```text
[ ] BASE trigger dùng freeSpin.event=TRIGGERED để xác định trúng Free Spin.
[ ] Không tự đếm Scatter để quyết định trigger nếu backend đã trả freeSpin.triggered.
[ ] Dùng freeSpin.awarded / totalAwarded để hiển thị tổng lượt được thưởng.
[ ] Dùng freeSpin.remainingAfter để cập nhật số lượt còn lại sau BASE trigger.
[ ] Dùng triggerAnimation.firstScatterColumns để reveal/highlight 2 Scatter đầu.
[ ] Dùng triggerAnimation.anticipationColumns để bật effect cho cột 3,4,5.
[ ] Dùng triggerAnimation.revealOrder để diễn thứ tự reveal.
[ ] Dùng freeSpin.scatterPositions.cellId để highlight Scatter thật.
[ ] Không highlight Scatter displayOnly=true nếu cellId không nằm trong scatterPositions.
[ ] Khi state.mode=FREE_SPIN thì không trừ tiền, đọc remainingBefore/remainingAfter để update counter.
[ ] Khi freeSpin.event=COMPLETED và remainingAfter=0 thì kết thúc Free Spin mode.
```

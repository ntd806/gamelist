# Thông tin chính
```text
1. Game này có Big Win và có Platform Jackpot.

2. Big Win là hiệu ứng thắng lớn dựa trên totalWin.

3. Jackpot là hũ thưởng riêng của platform, chỉ render khi jackpot.enabled và jackpot.triggered.

4. Free Spin do server quản lý. Còn Free Spin thì server ép dùng hết trước, không trừ tiền cược mới.

5. 4009 dùng để init UI: room, bet options, player state, dailySpinCount.

6. 4001 dùng để render kết quả spin: win, cascade, freeSpin, jackpot, dailySpinCount.

7. 4016 dùng để render history: bet data, dailySpinCount, createdAt, updatedAt.

8. Frontend không tự quyết định Base Spin hay Free Spin, không tự tính jackpot, không gộp Big Win với Jackpot.
```

# Frontend Guide — Jackpot, Big Win, Free Spin và các response cần xử lý

## 1. Tóm tắt ngắn

Bản game này là Mahjong Ways 2 có core gameplay gồm:

```text
- 2,000 ways
- Cascade / thắng liên hoàn
- Multiplier
- Golden Symbol
- Free Spin
- Big Win / thắng lớn
```

Ngoài core gameplay, hệ thống hiện có thêm **Platform Jackpot** theo thiết kế riêng.

Vì vậy frontend cần hiểu rõ:

```text
Big Win ≠ Jackpot
```

* **Big Win** là hiệu ứng khi tổng thắng của một spin đủ lớn.
* **Jackpot** là hũ/quỹ thưởng riêng của platform, có logic pot/fund/điều kiện nổ hũ riêng.
* **Free Spin** là trạng thái server quản lý. Khi còn lượt Free Spin, server sẽ ưu tiên dùng hết Free Spin trước rồi mới quay lại lượt quay thường.

---

# 2. Game có jackpot


Game hiện tại đang được thiết kế thêm **Platform Jackpot** ở tầng hệ thống/economy. Jackpot này không phải là “ways win” hay “Big Win”, mà là một hũ thưởng riêng của platform.

Nói cách khác:

```text
Mahjong Ways 2 core = ways + cascade + multiplier + golden + free spin
Platform Jackpot = lớp jackpot/economy riêng được hệ thống thêm vào
```

Vì design/product đã chốt có Jackpot, frontend vẫn cần làm UI Jackpot, nhưng chỉ render khi backend trả jackpot đang bật hoặc jackpot triggered.

---

# 3. Tại sao lại có Jackpot?

Game này có Jackpot vì hệ thống đang thêm **Platform Jackpot** vào bản game này.

Jackpot không phải logic thắng thường. Jackpot có cơ chế riêng:

```text
Tiền cược vào
→ chia một phần vào fee
→ chia một phần vào jackpot pot
→ chia một phần vào fund
→ nếu đủ điều kiện quỹ và random hit
→ người chơi trúng jackpot
→ pot reset về giá trị gốc
```

Frontend không cần tự tính pot/fund hay điều kiện nổ hũ. Frontend chỉ đọc response từ backend.

Nếu backend trả:

```json
{
  "gameConfig": {
    "hasJackpot": true
  }
}
```

thì frontend hiểu game này có Jackpot feature.

Nếu backend trả:

```json
{
  "jackpot": {
    "enabled": true,
    "triggered": true
  }
}
```

thì spin hiện tại đã trúng Jackpot và frontend cần xử lý Jackpot UI/animation.

---

# 4. Game có Big Win / Mega Win / Super Win

Không chỉ có thắng lớn.

Game có các loại kết quả/hiệu ứng sau:

```text
1. Win thường
2. Big Win / Mega Win / Super Win
3. Cascade win
4. Multiplier
5. Golden Symbol transform
6. Free Spin
7. Platform Jackpot
```

Trong đó:

## Big Win là gì?

Big Win là hiệu ứng khi tổng thắng của spin đủ lớn so với tiền cược.

Ví dụ:

```text
totalBet = 450
totalWin = 4,500
→ có thể hiện Big Win
```

Big Win chỉ là cách phân loại/thể hiện một kết quả thắng lớn.

Big Win không phải là một hũ tiền riêng.

## Jackpot là gì?

Jackpot là hũ/quỹ thưởng riêng của platform.

Ví dụ:

```text
jackpot pot = 1,200,000
spin này trúng jackpot
→ người chơi nhận jackpot amount
→ frontend play Jackpot animation
```

Jackpot có field riêng trong response:

```json
{
  "jackpot": {
    "enabled": true,
    "triggered": true,
    "type": "MINI",
    "amountMinor": 120000,
    "currency": "VND",
    "animation": {
      "enabled": true,
      "event": "JACKPOT_TRIGGERED",
      "blocking": true
    }
  }
}
```

Frontend không nên dùng Big Win UI thay cho Jackpot UI.

---

# 5. Khi nào frontend hiển thị Jackpot?

Frontend chỉ hiển thị Jackpot khi backend trả:

```json
{
  "jackpot": {
    "enabled": true,
    "triggered": true
  }
}
```

Nếu có animation:

```json
{
  "jackpot": {
    "animation": {
      "enabled": true,
      "event": "JACKPOT_TRIGGERED"
    }
  }
}
```

thì frontend cần play Jackpot animation.

## Điều kiện render Jackpot UI

```text
jackpot.enabled = true
AND jackpot.triggered = true
```

## Điều kiện play Jackpot animation

```text
jackpot.animation.enabled = true
AND jackpot.animation.event = "JACKPOT_TRIGGERED"
```

Nếu:

```json
{
  "jackpot": {
    "enabled": true,
    "triggered": false
  }
}
```

thì game có Jackpot feature, nhưng spin hiện tại không trúng Jackpot. Frontend không play animation trúng Jackpot.

---

# 6. Field Jackpot frontend cần hiểu

Ví dụ response:

```json
{
  "jackpot": {
    "enabled": true,
    "triggered": true,
    "type": "MINI",
    "amount": 1200,
    "amountMinor": 120000,
    "currency": "VND",
    "eventId": "JP_SPIN_xxx",
    "animation": {
      "enabled": true,
      "event": "JACKPOT_TRIGGERED",
      "type": "MINI",
      "amountMinor": 120000,
      "priority": "HIGH",
      "playAfter": "REEL_STOP",
      "blocking": true
    },
    "status": "PAID"
  }
}
```

Ý nghĩa:

```text
enabled:
Jackpot feature đang bật.

triggered:
Spin hiện tại có trúng Jackpot không.

type:
Loại jackpot, ví dụ MINI / MINOR / MAJOR / GRAND.

amountMinor:
Số tiền jackpot theo minor unit. Frontend nên ưu tiên dùng field này để tính toán.

amount:
Số tiền hiển thị theo đơn vị chính.

currency:
Đơn vị tiền.

eventId:
ID sự kiện jackpot, dùng để trace hoặc tránh play trùng animation.

animation.enabled:
Có cần play animation jackpot không.

animation.event:
Event frontend dùng để bắt animation.

animation.playAfter:
Thời điểm play animation, ví dụ sau khi reel stop.

animation.blocking:
Nếu true, không cho người chơi bấm spin tiếp trong lúc animation đang chạy.

status:
Trạng thái jackpot. Nếu là FORCED thì đây là case test/dev, không phải random production.
```

---

# 7. Nếu vừa Big Win vừa Jackpot thì sao?

Big Win và Jackpot là hai hiệu ứng khác nhau, có thể cùng xuất hiện trong một spin.

Gợi ý thứ tự xử lý animation:

```text
1. Spin reels
2. Reel stop
3. Cascade / win animation
4. Big Win nếu totalWin đạt ngưỡng
5. Free Spin trigger nếu có
6. Jackpot animation nếu jackpot.animation.enabled = true
7. Update balance / state
8. Unlock spin button
```

Nếu `jackpot.animation.blocking = true`, frontend không cho người chơi bấm spin tiếp cho đến khi animation kết thúc.

Thứ tự cuối cùng có thể điều chỉnh theo game feel/design, nhưng frontend không được gộp Big Win và Jackpot thành một.

---

# 8. Free Spin là do server quản lý.

Free Spin là state do server quản lý.

Khi người chơi trigger Free Spin, ví dụ quay ra 3 Scatter được 10 lượt, server sẽ lưu số lượt Free Spin còn lại. Những lần spin tiếp theo, nếu còn Free Spin, server sẽ ưu tiên chạy ở mode `FREE_SPIN` trước.

Flow đúng:

```text
Base Spin quay ra Scatter đủ điều kiện
→ server cộng Free Spin
→ spin tiếp theo dùng Free Spin trước
→ mỗi lượt Free Spin giảm remaining
→ nếu trong Free Spin lại trigger Scatter thì có thể retrigger/cộng thêm lượt
→ khi remaining = 0 thì quay lại Base Spin
```

Frontend không tự quyết định đang là Base Spin hay Free Spin. Frontend chỉ đọc response từ server.

---

# 9. Field Free Spin frontend cần hiểu

Ví dụ:

```json
{
  "freeSpin": {
    "triggered": true,
    "awarded": 10,
    "remaining": 10,
    "retriggered": false,
    "scatterCount": 3
  }
}
```

Ý nghĩa:

```text
triggered:
Spin này vừa kích hoạt Free Spin.

awarded:
Số lượt Free Spin được tặng trong spin này.

remaining:
Số lượt Free Spin còn lại sau spin hiện tại.

retriggered:
Có phải cộng thêm lượt trong lúc đang Free Spin không.

scatterCount:
Số Scatter xuất hiện trong spin.
```

Ví dụ:

```text
3 Scatter → awarded = 10
4 Scatter → awarded = 12
5 Scatter → awarded = 14
```

---

# 10. Trong Free Spin không trừ tiền cược.

Free Spin không trừ tiền cược mới. Tuy nhiên frontend vẫn có thể nhận bet info để biết payout đang tính theo mức cược gốc nào.

Ví dụ response có thể là:

```json
{
  "state": {
    "mode": "FREE_SPIN"
  },
  "bet": {
    "betOptionId": "R1_BS_250_BL_9",
    "betSize": 2.5,
    "betLevel": 9,
    "baseBet": 20,
    "lineBet": 22.5,
    "totalBet": 450,
    "chargedAmount": 0,
    "paid": false
  },
  "freeSpin": {
    "remaining": 4
  }
}
```

Ý nghĩa:

```text
totalBet:
Mức cược gốc dùng để tính payout.

chargedAmount:
Số tiền bị trừ ở spin này. Free Spin thì bằng 0.

paid:
Free Spin thì false, paid spin thì true.
```

Nếu backend chưa trả `chargedAmount` hoặc `paid`, frontend có thể tạm dựa vào:

```text
state.mode = "FREE_SPIN"
```

để hiểu lượt này không phải paid spin.

---

# 11. Khi nào quay lại lượt quay bình thường?

Khi server trả:

```json
{
  "freeSpin": {
    "remaining": 0
  },
  "state": {
    "mode": "BASE"
  }
}
```

Lúc đó spin tiếp theo mới là lượt quay thường và có trừ tiền cược theo bet option.

---

# 12. Frontend cần đọc gì ở `4003 → 4009`?

`4003` là command subscribe/init. Response hiện là `4009`.

Frontend dùng response này để dựng UI ban đầu.

Các phần cần đọc:

```text
rooms
room
betOptions
gameConfig
symbols
wildRule
goldenRule
multipliers
freeSpinRule
playerState
animationConfig
```

Phần bet cần dùng:

```json
{
  "room": {
    "baseBet": 20,
    "betSizes": [0.02, 0.2, 0.75, 2.5],
    "betLevels": [1,2,3,4,5,6,7,8,9,10],
    "defaultBetSize": 2.5,
    "defaultBetLevel": 9,
    "defaultBetOptionId": "R1_BS_250_BL_9"
  },
  "playerState": {
    "selectedBetOptionId": "R1_BS_250_BL_9",
    "dailySpinCount": 3
  }
}
```

Frontend tính total bet theo công thức:

```text
totalBet = betSize × betLevel × baseBet
```

Ví dụ:

```text
2.50 × 9 × 20 = 450
```

---

# 13. Frontend cần đọc gì ở `4001`?

`4001` là response kết quả spin.

Frontend cần đọc:

```text
reels / animationReels
cascadeSteps
totalWin
balance
bet
seamless
freeSpin
jackpot
state
dailySpinCount
clientRequestId
```

Phần bet nên có đủ:

```json
{
  "bet": {
    "roomId": 1,
    "betOptionId": "R1_BS_250_BL_9",
    "betSize": 2.5,
    "betLevel": 9,
    "baseBet": 20,
    "lineBet": 22.5,
    "totalBet": 450
  }
}
```

Nếu `state.mode = "FREE_SPIN"`, frontend hiểu đây là lượt Free Spin, không phải lượt paid spin.

---

# 14. Frontend cần đọc gì ở `4015 → 4016`?

`4015` là command lấy lịch sử. Response hiện là `4016`.

Mỗi history item nên có:

```json
{
  "betOptionId": "R1_BS_250_BL_9",
  "betSize": 2.5,
  "betLevel": 9,
  "baseBet": 20,
  "lineBet": 22.5,
  "totalBet": 450,
  "dailySpinCount": 3,
  "createdAt": 1730000000000,
  "updatedAt": 1730000000000
}
```
---

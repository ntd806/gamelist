{
  "freeSpin": {
    "triggered": true,
    "awarded": 10,
    "remaining": 10,
    "retriggered": false,
    "scatterCount": 3
  },
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
    "status": "FORCED"
  }
}

## 1. Phần Free Spin

```json id="dio7ew"
"freeSpin": {
  "triggered": true,
  "awarded": 10,
  "remaining": 10,
  "retriggered": false,
  "scatterCount": 3
}
```

Ý nghĩa từng field:

```txt id="8hkvcq"
triggered: true
```

Spin này **vừa kích hoạt Free Spin mới**.

```txt id="xxc5r0"
awarded: 10
```

Người chơi được tặng **10 lượt Free Spin**.

```txt id="pp3ei0"
remaining: 10
```

Sau spin này, người chơi đang còn **10 lượt Free Spin** để chơi tiếp.

```txt id="za73fq"
retriggered: false
```

Đây là lần trigger Free Spin ban đầu, **không phải retrigger trong lúc đang chơi Free Spin**.

Ví dụ:

```txt id="21r01c"
Base Spin quay ra 3 Scatter
=> triggered = true
=> awarded = 10
=> remaining = 10
=> retriggered = false
```

Nếu đang trong Free Spin mà lại quay ra Scatter để cộng thêm lượt, lúc đó có thể là:

```json id="5uotyb"
"retriggered": true
```

```txt id="w9pco0"
scatterCount: 3
```

Board có **3 Scatter**, đủ điều kiện kích hoạt Free Spin.

Theo rule bạn đang dùng:

```txt id="2w45jy"
3 Scatter = 10 Free Spins
4 Scatter = 12 Free Spins
5 Scatter = 14 Free Spins
```

## 2. Phần Jackpot

```json id="davuh9"
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
  "status": "FORCED"
}
```

Ý nghĩa:

```txt id="t4daeo"
enabled: true
```

Tính năng Jackpot đang được bật.

```txt id="zmdqzz"
triggered: true
```

Spin này **đã trúng Jackpot**.

```txt id="z4765t"
type: "MINI"
```

Loại jackpot trúng là **MINI Jackpot**.

Có thể có các loại khác như:

```txt id="e1x550"
MINI
MINOR
MAJOR
GRAND
```

```txt id="f9vuyn"
amount: 1200
```

Số tiền jackpot hiển thị theo đơn vị chính.

```txt id="wvvfgc"
amountMinor: 120000
```

Số tiền jackpot theo **minor unit**.

Ví dụ nếu hệ thống quy ước:

```txt id="qdufln"
100 minor = 1 VND/display unit
```

thì:

```txt id="m0465x"
120000 minor = 1200
```

Frontend nên ưu tiên dùng `amountMinor` để tính toán, còn `amount` để hiển thị.

```txt id="37ka6c"
currency: "VND"
```

Đơn vị tiền là VND.

```txt id="f1hn9g"
eventId: "JP_SPIN_xxx"
```

ID sự kiện jackpot. Frontend/backend có thể dùng để trace log, tránh diễn trùng hoặc debug animation.

## 3. Phần animation Jackpot

```json id="zfl09b"
"animation": {
  "enabled": true,
  "event": "JACKPOT_TRIGGERED",
  "type": "MINI",
  "amountMinor": 120000,
  "priority": "HIGH",
  "playAfter": "REEL_STOP",
  "blocking": true
}
```

Đây là phần rất quan trọng cho frontend.

```txt id="q7kffk"
animation.enabled: true
```

Frontend **cần diễn animation jackpot**.

```txt id="u6rlty"
event: "JACKPOT_TRIGGERED"
```

Tên event để frontend bắt logic animation.

Ví dụ frontend có thể viết:

```js id="8d26jv"
if (response.jackpot?.animation?.event === "JACKPOT_TRIGGERED") {
  playJackpotAnimation(response.jackpot);
}
```

```txt id="4e1v3d"
type: "MINI"
```

Animation cần hiển thị loại jackpot MINI.

```txt id="wria06"
amountMinor: 120000
```

Số tiền jackpot truyền vào animation.

```txt id="3vwfju"
priority: "HIGH"
```

Sự kiện này có độ ưu tiên cao. Nếu cùng lúc có nhiều animation, frontend nên ưu tiên jackpot hơn animation nhỏ.

```txt id="h1r8ph"
playAfter: "REEL_STOP"
```

Frontend nên diễn jackpot **sau khi reels dừng**.

Flow gợi ý:

```txt id="ym21ub"
1. Spin reels
2. Reels stop
3. Show win/cascade nếu có
4. Show Free Spin trigger
5. Show Jackpot animation
6. Update balance / state
```

Tùy game feel, bạn có thể để Jackpot diễn trước Free Spin nếu muốn nó nổi bật hơn.

```txt id="c5dwhi"
blocking: true
```

Animation này là **blocking animation**. Nghĩa là khi jackpot đang diễn, frontend không nên cho người chơi bấm spin tiếp hoặc chuyển state quá sớm.

## 4. `status: "FORCED"` nghĩa là gì?

```txt id="rbc5x7"
status: "FORCED"
```

Nghĩa là jackpot này được **ép trigger để test/dev/smoke**, không phải jackpot random thật trong production.

Field này rất hữu ích để frontend/backend biết đây là case test.

Trong production thật, status có thể là dạng khác, ví dụ:

```txt id="zq3dax"
PENDING
PAID
FAILED_NEED_REVIEW
SETTLED
```

Tùy code bạn implement.

## 5. Frontend nên hiểu toàn bộ response này như thế nào?

Response này báo rằng:

```txt id="qa16jh"
Spin hiện tại:
- Có 3 Scatter.
- Vừa kích hoạt 10 Free Spins.
- Còn 10 lượt Free Spin.
- Đồng thời trúng MINI Jackpot.
- Jackpot amount = 1200 VND/display unit.
- Frontend cần diễn Jackpot animation sau khi reel dừng.
- Jackpot animation là blocking.
```

## 6. Cách xử lý frontend đề xuất

Pseudo-flow:

```js id="8prckf"
const { freeSpin, jackpot } = response;

await playReelStopAnimation(response);

if (freeSpin?.triggered) {
  await playFreeSpinTriggerAnimation({
    scatterCount: freeSpin.scatterCount,
    awarded: freeSpin.awarded,
    remaining: freeSpin.remaining,
  });
}

if (jackpot?.animation?.enabled && jackpot.animation.event === "JACKPOT_TRIGGERED") {
  await playJackpotAnimation({
    type: jackpot.type,
    amountMinor: jackpot.amountMinor,
    amount: jackpot.amount,
    currency: jackpot.currency,
    eventId: jackpot.eventId,
  });
}

updateFreeSpinCounter(freeSpin.remaining);
updateBalance(response.balance);
unlockSpinButton();
```

## 7. Tóm tắt cực ngắn

```txt id="m3ppue"
freeSpin.triggered = true
=> Diễn animation kích hoạt Free Spin.

freeSpin.awarded = 10
=> Người chơi được 10 lượt Free Spin.

jackpot.triggered = true
=> Spin này trúng Jackpot.

jackpot.type = MINI
=> Trúng MINI Jackpot.

jackpot.animation.enabled = true
=> Frontend phải diễn animation Jackpot.

jackpot.animation.playAfter = REEL_STOP
=> Diễn sau khi reel dừng.

jackpot.animation.blocking = true
=> Đang diễn thì không cho spin tiếp.

status = FORCED
=> Đây là jackpot bị ép để test, không phải random production.
```

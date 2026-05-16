# Mahjong2 — Frontend Integration Specification

## Final Flow: Reuse Socket Cũ, Mở Rộng Result Payload

---

# 1. Mục tiêu

Mahjong2 frontend **không cần tích hợp lại socket flow mới**.

Game mới sẽ:

```text
reuse socket architecture cũ
reuse numeric command convention cũ
reuse subscribe / play / autoplay flow cũ
```

Chỉ mở rộng phần:

```text
RESULT payload
cascadeSteps
goldenTransforms
freeSpin state
```

---

# 2. Game overview

Mahjong2 là game:

```text
5 reels
layout 4-5-5-5-4
2000 ways
có cascade
có multiplier theo cascade
có Golden Symbol
có Golden → Wild transform
có Free Spin
```

Frontend không được giả định game là:

```text
4x5 đều
1024 ways
1 spin = 1 result đơn giản
```

---

# 3. Command convention

Dự án cũ đang dùng **numeric command**.

Mahjong2 nên map theo convention hiện tại, ví dụ theo block Avengers:

| Action          | Avengers hiện tại | Mahjong2 đề xuất |
| --------------- | ----------------: | ---------------: |
| PLAY            |              4001 |             4101 |
| UPDATE_POT      |              4002 |             4102 |
| SUBSCRIBE       |              4003 |             4103 |
| UNSUBSCRIBE     |              4004 |             4104 |
| CHANGE_ROOM     |              4005 |             4105 |
| AUTO_PLAY       |              4006 |             4106 |
| STOP_AUTO_PLAY  |              4007 |             4107 |
| FORCE_STOP_AUTO |              4008 |             4108 |
| INFO            |              4009 |             4109 |
| BIG_WIN         |              4010 |             4110 |
| TOTAL_FREE_SPIN |              4011 |             4111 |
| FREE_DAILY      |              4012 |             4112 |
| MINIMIZE        |              4013 |             4113 |
| MINIMIZE_RESULT |              4014 |             4114 |

> ID `4101–4114` là block đề xuất theo convention hiện tại. Nếu backend đã cấp ID khác, frontend dùng ID backend cấp.

---

# 4. Command list cho Mahjong2

## Client → Server

| Command                 | ID đề xuất | Mục đích             |
| ----------------------- | ---------: | -------------------- |
| PLAY_MAHJONG2           |       4101 | quay 1 lượt          |
| SUBSCRIBE_MAHJONG2      |       4103 | vào game / join room |
| UNSUBSCRIBE_MAHJONG2    |       4104 | thoát game           |
| CHANGE_ROOM_MAHJONG2    |       4105 | đổi room cược        |
| AUTO_PLAY_MAHJONG2      |       4106 | bật auto play        |
| STOP_AUTO_PLAY_MAHJONG2 |       4107 | dừng auto play       |
| MINIMIZE_MAHJONG2       |       4113 | minimize game        |

## Server → Client

| Command                  | ID đề xuất | Mục đích                 |
| ------------------------ | ---------: | ------------------------ |
| RESULT_MAHJONG2          |       4101 | trả kết quả spin         |
| UPDATE_POT_MAHJONG2      |       4102 | cập nhật jackpot pot     |
| FORCE_STOP_AUTO_MAHJONG2 |       4108 | server bắt dừng auto     |
| INFO_MAHJONG2            |       4109 | trả thông tin room/game  |
| BIG_WIN_MAHJONG2         |       4110 | broadcast big win        |
| TOTAL_FREE_SPIN_MAHJONG2 |       4111 | sync tổng free spin      |
| MINIMIZE_RESULT_MAHJONG2 |       4114 | trả kết quả khi minimize |

---

# 5. Nguyên tắc quan trọng

Không cần tạo command riêng cho:

```text
CASCADE_STEP
GOLDEN_TRANSFORM
FREE_SPIN_STATE
```

Vì Mahjong2 nên trả toàn bộ dữ liệu animation trong **một RESULT payload**.

Lý do:

```text
giảm socket spam
tránh desync animation
frontend tự chạy animation queue
dễ support mobile / slow network
```

---

# 6. Flow tổng thể

```text
LOGIN
↓
SUBSCRIBE_MAHJONG2
↓
INFO_MAHJONG2
↓
CHANGE_ROOM_MAHJONG2 nếu cần
↓
PLAY_MAHJONG2
↓
RESULT_MAHJONG2
↓
UPDATE_POT_MAHJONG2 nếu pot đổi
↓
BIG_WIN_MAHJONG2 nếu đủ điều kiện
↓
AUTO_PLAY_MAHJONG2 nếu bật auto
↓
STOP_AUTO_PLAY_MAHJONG2 hoặc FORCE_STOP_AUTO_MAHJONG2
↓
UNSUBSCRIBE_MAHJONG2
```

---

# 7. Subscribe flow

## Frontend gửi

```json
{
  "cmd": 4103,
  "roomId": 1
}
```

## Server trả

```json
{
  "cmd": 4109,
  "room": {
    "roomId": 1,
    "betSize": 2.5,
    "betLevel": 9,
    "baseBet": 20,
    "totalBet": 450,
    "pot": 1200000
  },
  "playerState": {
    "balance": 1000000,
    "mode": "BASE",
    "remainingFreeSpin": 0
  }
}
```

Frontend cần:

```text
set currentRoom
set balance
set pot
set mode
render default reels nếu backend trả
```

---

# 8. Change room flow

## Frontend gửi

```json
{
  "cmd": 4105,
  "roomId": 2
}
```

## Server trả

```json
{
  "cmd": 4109,
  "room": {
    "roomId": 2,
    "betSize": 5,
    "betLevel": 9,
    "baseBet": 20,
    "totalBet": 900,
    "pot": 5000000
  },
  "playerState": {
    "balance": 1000000,
    "mode": "BASE",
    "remainingFreeSpin": 0
  }
}
```

---

# 9. Play request

Mahjong2 dùng 3 thành phần cược:

```text
totalBet = betSize × betLevel × baseBet
```

## Frontend gửi

```json
{
  "cmd": 4101,
  "betSize": 2.5,
  "betLevel": 9,
  "baseBet": 20,
  "turbo": false
}
```

---

# 10. Result payload — cấu trúc chuẩn

```json
{
  "cmd": 4101,
  "spinId": "SPIN_10001",

  "reels": [],

  "cascadeSteps": [],

  "totalWin": 0,
  "balance": 0,

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

# 11. Reels format

Vì layout là `4-5-5-5-4`, frontend nhận dạng:

```text
reels[reelIndex][rowIndex]
```

## Ví dụ

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

# 12. Symbol expectation

| Symbol  | Code           | FE behavior                              |
| ------- | -------------- | ---------------------------------------- |
| Wild    | `WILD`         | render wild, thay symbol thường          |
| Scatter | `SCATTER`      | render scatter, trigger free spin        |
| Normal  | `ITEM_1`…      | render symbol thường                     |
| Golden  | `golden: true` | render golden overlay trên symbol thường |

Frontend không nên tự giả định có:

```text
BONUS
JP symbol trên reels
```

trừ khi backend trả về trong reels.

---

# 13. Cascade steps

Một spin có thể có nhiều cascade.

Frontend không nên render ngay kết quả cuối, mà phải chạy theo từng step.

## Format

```json
"cascadeSteps": [
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
  },
  {
    "step": 2,
    "mode": "BASE",
    "multiplier": 2,
    "reelsBefore": [],
    "wins": [],
    "removedPositions": [],
    "goldenTransforms": [],
    "reelsAfterDrop": [],
    "stepWin": 3600
  }
]
```

---

# 14. Win object

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

Frontend dùng:

```text
wins[].positions để highlight symbol thắng
```

---

# 15. Removed positions

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
explode symbol thắng
xóa symbol
chạy animation rơi
```

---

# 16. Golden transforms

```json
"goldenTransforms": [
  {
    "from": {
      "reel": 2,
      "row": 1,
      "symbol": "ITEM_3",
      "golden": true
    },
    "to": {
      "reel": 2,
      "row": 1,
      "symbol": "WILD",
      "golden": false
    }
  }
]
```

Frontend dùng để animate:

```text
Golden Symbol → Wild
```

---

# 17. Multiplier

## Base game

| Cascade step | Multiplier |
| ------------ | ---------: |
| 1            |         x1 |
| 2            |         x2 |
| 3            |         x3 |
| 4+           |         x5 |

## Free spin

| Cascade step | Multiplier |
| ------------ | ---------: |
| 1            |         x2 |
| 2            |         x4 |
| 3            |         x6 |
| 4+           |        x10 |

Frontend lấy multiplier từ:

```text
cascadeSteps[].multiplier
```

không tự tính.

---

# 18. Free spin state

## Trigger rule

```text
3 Scatter = 10 free spins
mỗi Scatter thêm = +2 spins
```

## Response

```json
"freeSpin": {
  "triggered": true,
  "awarded": 10,
  "remaining": 10,
  "retriggered": false,
  "scatterCount": 3
}
```

Nếu đang free spin:

```json
"state": {
  "mode": "FREE_SPIN",
  "pot": 1200000,
  "bigWin": false,
  "turbo": false
}
```

Frontend cần hiển thị:

```text
free spin intro
remaining free spin
free spin multiplier table/effect
retrigger nếu có
```

---

# 19. Update pot

## Server broadcast

```json
{
  "cmd": 4102,
  "roomId": 1,
  "pot": 1300000
}
```

Frontend update jackpot pot realtime.

---

# 20. Big win

## Server broadcast

```json
{
  "cmd": 4110,
  "nickname": "playerA",
  "amount": 5000000,
  "roomId": 1
}
```

Frontend render big win ticker / popup theo UI hiện tại.

---

# 21. Auto play

## Frontend gửi

```json
{
  "cmd": 4106,
  "betSize": 2.5,
  "betLevel": 9,
  "baseBet": 20,
  "rounds": 100,
  "turbo": false
}
```

Server trả liên tục các payload:

```text
RESULT_MAHJONG2
RESULT_MAHJONG2
RESULT_MAHJONG2
...
```

## Stop auto

```json
{
  "cmd": 4107
}
```

## Force stop từ server

```json
{
  "cmd": 4108,
  "reason": "NOT_ENOUGH_MONEY"
}
```

---

# 22. Minimize flow

Reuse flow cũ.

## Frontend gửi

```json
{
  "cmd": 4113
}
```

## Server trả

```json
{
  "cmd": 4114,
  "result": {
    "spinId": "SPIN_10001",
    "totalWin": 1200,
    "balance": 1001200,
    "freeSpin": {
      "remaining": 0
    }
  }
}
```

---

# 23. Error response

```json
{
  "cmd": -1,
  "errorCode": 1001,
  "message": "NOT_ENOUGH_MONEY"
}
```

| Code | Meaning          |
| ---: | ---------------- |
| 1001 | NOT_ENOUGH_MONEY |
| 1002 | INVALID_ROOM     |
| 1003 | INVALID_BET      |
| 1004 | SESSION_EXPIRED  |
| 1005 | GAME_MAINTENANCE |

---

# 24. Frontend render flow

```text
Receive RESULT_MAHJONG2
↓
Render initial reels layout 4-5-5-5-4
↓
For each cascadeStep:
    render reelsBefore
    highlight wins[].positions
    show multiplier
    show stepWin
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
    play jackpot effect
↓
Ready next spin / next autoplay spin
```

---

# 25. Frontend state management

| State             | Purpose                         |
| ----------------- | ------------------------------- |
| currentRoom       | room hiện tại                   |
| reels             | board hiện tại                  |
| cascadeSteps      | animation queue                 |
| balance           | số dư user                      |
| pot               | jackpot pot                     |
| mode              | BASE / FREE_SPIN                |
| remainingFreeSpin | free spin còn lại               |
| currentMultiplier | multiplier của cascade hiện tại |
| totalWin          | tổng thắng                      |
| autoPlay          | trạng thái auto                 |
| turbo             | trạng thái quay nhanh           |

---

# 26. Những thứ frontend không được tự giả định

Frontend không nên tự giả định:

```text
board là 4x5 đều
ways là 1024
một spin chỉ có một animation win
multiplier luôn x1
free spin luôn đúng 10 mà không cộng thêm
Golden chỉ là asset, không có transform
có BONUS/JP symbol trên reel
```

Frontend phải đọc từ response:

```text
reels
cascadeSteps
goldenTransforms
freeSpin
state.mode
multiplier
removedPositions
```

---

# 27. Kết luận

Mahjong2 frontend nên:

```text
reuse socket flow cũ
reuse numeric command convention cũ
reuse subscribe/play/autoplay flow cũ
```

Chỉ cần mở rộng:

```text
RESULT payload
cascadeSteps
goldenTransforms
freeSpin state
dynamic reels 4-5-5-5-4
```

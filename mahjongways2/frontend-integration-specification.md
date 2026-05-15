# Mahjong2 — Frontend Integration Specification

## (Final Frontend Design)

---

# 1. OVERVIEW

## Game Type

```text
Mahjong2
```

---

## Core Design

| Thành phần   | Thiết kế         |
| ------------ | ---------------- |
| Board        | 4 rows × 5 reels |
| Win System   | Ways System      |
| Payline      | Không sử dụng    |
| Socket Style | numeric command  |
| Highlight    | positions[]      |
| Animation    | ways-centric     |
| Pot Update   | realtime         |
| Auto Play    | supported        |

---

# 2. FRONTEND FLOW

```text
LOGIN
↓
SUBSCRIBE_MAHJONG2
↓
CHANGE_ROOM_MAHJONG2
↓
PLAY_MAHJONG2
↓
RESULT_MAHJONG2
↓
UPDATE_POT_MAHJONG2
↓
BIG_WIN_MAHJONG2
↓
AUTO_PLAY_MAHJONG2
↓
STOP_PLAY_MAHJONG2
↓
UNSUBSCRIBE_MAHJONG2
↓
DISCONNECT
```

---

# 3. SOCKET COMMANDS

## Client → Server

| Command              | ID   | Purpose     |
| -------------------- | ---- | ----------- |
| SUBSCRIBE_MAHJONG2   | 6000 | join room   |
| CHANGE_ROOM_MAHJONG2 | 6001 | change room |
| PLAY_MAHJONG2        | 6002 | spin        |
| AUTO_PLAY_MAHJONG2   | 6003 | auto spin   |
| STOP_PLAY_MAHJONG2   | 6004 | stop auto   |
| UNSUBSCRIBE_MAHJONG2 | 6005 | leave room  |

---

## Server → Client

| Command                  | ID   | Purpose            |
| ------------------------ | ---- | ------------------ |
| RESULT_MAHJONG2          | 6050 | spin result        |
| UPDATE_POT_MAHJONG2      | 6051 | update jackpot pot |
| BIG_WIN_MAHJONG2         | 6052 | broadcast big win  |
| FORCE_STOP_PLAY_MAHJONG2 | 6053 | stop auto play     |

---

# 4. LOGIN FLOW

## Frontend → Server

```json
{
  "cmd": 1,
  "token": "USER_TOKEN"
}
```

---

## Server → Frontend

```json
{
  "cmd": 1,

  "user": {
    "userId": 1001,
    "nickname": "playerA",
    "balance": 1000000
  }
}
```

---

# 5. SUBSCRIBE ROOM

## Frontend → Server

```json
{
  "cmd": 6000,
  "roomId": 1
}
```

---

## Server → Frontend

```json
{
  "cmd": 6000,

  "room": {
    "roomId": 1,
    "betValue": 1000,
    "pot": 1200000
  },

  "playerState": {
    "balance": 1000000,
    "remainFreeSpin": 0
  }
}
```

---

# 6. CHANGE ROOM

## Frontend → Server

```json
{
  "cmd": 6001,
  "roomId": 2
}
```

---

## Server → Frontend

```json
{
  "cmd": 6001,

  "room": {
    "roomId": 2,
    "betValue": 5000,
    "pot": 5000000
  }
}
```

---

# 7. PLAY REQUEST

## Frontend → Server

```json
{
  "cmd": 6002,

  "betLevel": 20
}
```

---

# 8. RESULT RESPONSE

## Server → Frontend

```json
{
  "cmd": 6050,

  "spinId": "SPIN_10001",

  "matrix": [
    ["ITEM_1","ITEM_2","ITEM_3","ITEM_4","W"],
    ["ITEM_1","ITEM_1","ITEM_3","SC","ITEM_2"],
    ["ITEM_5","ITEM_1","W","ITEM_4","ITEM_2"],
    ["ITEM_1","ITEM_2","ITEM_3","BONUS","ITEM_1"]
  ],

  "wins": [
    {
      "symbol": "ITEM_1",

      "matchCount": 4,

      "ways": 8,

      "multiplier": 1,

      "winAmount": 3200,

      "positions": [
        [0,0],
        [1,0],
        [1,1],
        [2,1],
        [0,2],
        [3,2]
      ]
    }
  ],

  "totalWin": 3200,

  "balance": 983200,

  "bet": {
    "betValue": 1000,
    "betLevel": 20,
    "totalBet": 20000
  },

  "features": {
    "freeSpinTriggered": false,
    "freeSpinCount": 0,

    "bonusTriggered": false,

    "jackpotTriggered": false
  },

  "jackpot": {
    "triggered": false,
    "type": null,
    "amount": 0
  },

  "state": {
    "pot": 1200000,

    "remainFreeSpin": 0,

    "bigWin": false
  }
}
```

---

# 9. MATRIX DESIGN

## Board Size

```text
4 rows × 5 reels
```

---

## Frontend Matrix Format

```text
[row][column]
```

---

## Visual

```text
[r0,c0] [r0,c1] [r0,c2] [r0,c3] [r0,c4]
[r1,c0] [r1,c1] [r1,c2] [r1,c3] [r1,c4]
[r2,c0] [r2,c1] [r2,c2] [r2,c3] [r2,c4]
[r3,c0] [r3,c1] [r3,c2] [r3,c3] [r3,c4]
```

---

# 10. SYMBOL SPECIFICATION

## Special Symbols

| Symbol  | Code  | Behavior              |
| ------- | ----- | --------------------- |
| Wild    | W     | replace normal symbol |
| Scatter | SC    | trigger free spin     |
| Bonus   | BONUS | trigger bonus         |
| Jackpot | JP    | trigger jackpot       |

---

## Normal Symbols

| Symbol | Code   |
| ------ | ------ |
| ITEM_1 | ITEM_1 |
| ITEM_2 | ITEM_2 |
| ITEM_3 | ITEM_3 |
| ITEM_4 | ITEM_4 |
| ITEM_5 | ITEM_5 |
| ITEM_6 | ITEM_6 |
| ITEM_7 | ITEM_7 |

---

# 11. SYMBOL ASSET MAPPING

| Symbol | Asset       |
| ------ | ----------- |
| ITEM_1 | item_1.png  |
| ITEM_2 | item_2.png  |
| ITEM_3 | item_3.png  |
| W      | wild.png    |
| SC     | scatter.png |
| BONUS  | bonus.png   |
| JP     | jackpot.png |

---

# 12. WAYS SYSTEM

Mahjong2 không dùng paylines.

Mahjong2 dùng:

```text
ways system
```

---

# 13. WIN CONDITION

## Rule

```text
ít nhất 3 reel liên tiếp
có symbol giống nhau
```

---

# 14. WAYS RESPONSE

## Frontend cần render:

| Field      | Meaning             |
| ---------- | ------------------- |
| symbol     | symbol thắng        |
| matchCount | số reel match       |
| ways       | số tổ hợp thắng     |
| positions  | highlight positions |
| multiplier | multiplier          |
| winAmount  | payout              |

---

# 15. POSITIONS FORMAT

## Example

```json
[
  [0,0],
  [1,0],
  [1,1]
]
```

---

# 16. POSITIONS RULE

Frontend dùng:

```text
positions[]
```

để:

```text
- highlight symbol thắng
- play win animation
- render ways effect
```

---

# 17. MATCH COUNT

## Example

```json
"matchCount": 4
```

---

## Meaning

```text
match từ reel 1 → reel 4
```

---

# 18. FREE SPIN

## Trigger

```text
3 SCATTER anywhere
```

---

## Response

```json
"features": {
  "freeSpinTriggered": true,
  "freeSpinCount": 10
}
```

---

# 19. BONUS GAME

## Trigger

```text
3 BONUS anywhere
```

---

## Response

```json
"features": {
  "bonusTriggered": true
}
```

---

# 20. JACKPOT

## Response

```json
"jackpot": {
  "triggered": true,
  "type": "NORMAL",
  "amount": 5000000
}
```

---

# 21. UPDATE POT

## Server Broadcast

```json
{
  "cmd": 6051,

  "roomId": 1,

  "pot": 1300000
}
```

---

# 22. BIG WIN

## Server Broadcast

```json
{
  "cmd": 6052,

  "nickname": "playerA",

  "amount": 5000000,

  "roomId": 1
}
```

---

# 23. AUTO PLAY

## Frontend → Server

```json
{
  "cmd": 6003,

  "betLevel": 20
}
```

---

# 24. STOP AUTO PLAY

## Frontend → Server

```json
{
  "cmd": 6004
}
```

---

# 25. FORCE STOP AUTO PLAY

## Server → Frontend

```json
{
  "cmd": 6053,

  "reason": "NOT_ENOUGH_MONEY"
}
```

---

# 26. ERROR RESPONSE

```json
{
  "cmd": -1,

  "errorCode": 1001,

  "message": "NOT_ENOUGH_MONEY"
}
```

---

# 27. ERROR CODES

| Code | Meaning          |
| ---- | ---------------- |
| 1001 | NOT_ENOUGH_MONEY |
| 1002 | INVALID_ROOM     |
| 1003 | INVALID_BET      |
| 1004 | SESSION_EXPIRED  |
| 1005 | GAME_MAINTENANCE |

---

# 28. FRONTEND RENDER FLOW

```text
Receive RESULT_MAHJONG2
↓
Render 4x5 matrix
↓
Loop wins[]
↓
Highlight positions
↓
Play ways animation
↓
Show win amount
↓
Update balance
↓
Update jackpot pot
↓
Check feature trigger
↓
Play free spin / bonus / jackpot animation
↓
Ready next spin
```

---

# 29. FRONTEND STATE MANAGEMENT

Frontend nên quản lý:

| State          | Purpose          |
| -------------- | ---------------- |
| currentRoom    | room hiện tại    |
| balance        | wallet           |
| pot            | jackpot pot      |
| autoPlay       | auto play state  |
| remainFreeSpin | free spin count  |
| currentMatrix  | current board    |
| wins           | animation render |
| jackpotState   | jackpot effect   |

---

# 30. FINAL FRONTEND DESIGN

Mahjong2 frontend final structure:

| Thành phần   | Final Design                |
| ------------ | --------------------------- |
| Board        | 4x5                         |
| Win System   | Ways                        |
| Highlight    | positions[]                 |
| Socket       | numeric command             |
| Animation    | ways-centric                |
| Matrix       | symbol code                 |
| Feature Flow | free spin / bonus / jackpot |
| Pot Update   | realtime                    |
| Auto Play    | supported                   |

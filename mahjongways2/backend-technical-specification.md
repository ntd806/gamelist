# Mahjong2 — Backend Technical Specification

## (Final Backend Internal Design)

---

# 1. OVERVIEW

## Game Type

```text
Mahjong2
```

---

## Core Design

| Thành phần     | Thiết kế         |
| -------------- | ---------------- |
| Board          | 4 rows × 5 reels |
| Win System     | Ways System      |
| Payline        | Không sử dụng    |
| Bet Input      | betLevel         |
| Command Style  | numeric command  |
| Random System  | weighted random  |
| Wallet Flow    | reuse system cũ  |
| Pot/Fund Flow  | reuse system cũ  |
| Jackpot Flow   | reuse system cũ  |
| Auto Play Flow | reuse system cũ  |

---

# 2. CORE FLOW

```text
PLAY_MAHJONG2
↓
validate balance
↓
calculate totalBet
↓
deduct bet
↓
split fee / pot / fund
↓
update pot / fund
↓
generate 4x5 board
↓
calculate ways win
↓
check scatter / bonus / jackpot symbol
↓
check jackpot condition
↓
calculate totalWin
↓
safety check fund
↓
credit reward
↓
reset pot if jackpot
↓
save transaction
↓
save spin history
↓
return RESULT_MAHJONG2
```

---

# 3. PROJECT STRUCTURE

## Keep

```text
Mahjong2Module.java
Mahjong2Room.java
Mahjong2Utils.java
Mahjong2Item.java
Mahjong2PayTable.java
Mahjong2WaysEngine.java
ResultMahjong2Msg.java
```

---

## Remove

```text
Mahjong2Lines.java
```

Mahjong2 không dùng paylines.

---

# 4. BOARD DESIGN

## Board Size

```text
4 rows × 5 reels
```

---

## Internal Structure

Backend dùng:

```text
reels[reelIndex][rowIndex]
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

# 5. SYMBOL DESIGN

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

# 6. SYMBOL ENUM

```java
public enum Mahjong2Symbol {

    NONE(-1, "NONE", false, false, false, false, false),

    SCATTER(0, "SCATTER", true, false, false, false, false),
    BONUS(1, "BONUS", false, true, false, false, false),
    WILD(2, "WILD", false, false, true, false, false),
    JACKPOT(3, "JACKPOT", false, false, false, true, false),

    ITEM_1(4, "ITEM_1", false, false, false, false, true),
    ITEM_2(5, "ITEM_2", false, false, false, false, true),
    ITEM_3(6, "ITEM_3", false, false, false, false, true),
    ITEM_4(7, "ITEM_4", false, false, false, false, true),
    ITEM_5(8, "ITEM_5", false, false, false, false, true),
    ITEM_6(9, "ITEM_6", false, false, false, false, true),
    ITEM_7(10, "ITEM_7", false, false, false, false, true);
}
```

---

# 7. BET SYSTEM

## Frontend Request

```json
{
  "cmd": 6002,
  "betLevel": 20
}
```

---

## Formula

```text
totalBet = betValue × betLevel
```

---

# 8. ECONOMY FLOW

## Bet Split

```text
fee = totalBet × 2%
moneyToPot = totalBet × 1%
moneyToFund = totalBet × 97%
```

---

## Update

```text
pot += moneyToPot
fund += moneyToFund
```

---

# 9. RANDOM SYSTEM

## Weighted Random

Không random đều.

---

## Formula

```text
P(symbol) =
symbolWeight / totalWeight
```

---

# 10. RANDOM FLOW

```text
random number
↓
loop weight
↓
cumulative weight
↓
select symbol
```

---

# 11. BOARD GENERATION

```text
generate 4x5 board
↓
random từng cell theo weight
↓
return board
```

---

# 12. WAYS SYSTEM

## Mahjong2 không dùng paylines

Mahjong2 dùng:

```text
consecutive reel ways
```

---

# 13. WIN CONDITION

## Rule

```text
ít nhất 3 reel liên tiếp
có symbol giống nhau
```

---

# 14. WILD RULE

## Rule

```text
Wild replace payable symbol
```

---

## Example

```text
ITEM_1
ITEM_1
WILD
ITEM_1
```

→

```text
4 ITEM_1
```

---

# 15. WAYS CALCULATION

## Formula

```text
ways =
reel1Count ×
reel2Count ×
reel3Count ...
```

---

## Example

| Reel   | ITEM_1 Count |
| ------ | ------------ |
| Reel 1 | 2            |
| Reel 2 | 2            |
| Reel 3 | 1            |

---

## Ways

```text
2 × 2 × 1 = 4 ways
```

---

# 16. WAYS FLOW

```text
loop symbol
↓
count symbol per reel
↓
check consecutive reels
↓
calculate ways
↓
calculate payout
```

---

# 17. PAYTABLE DESIGN

Paytable là config.

Không hardcode payout giả thành luật thật.

---

# 18. PAYOUT FORMULA

```text
payout =
betValue ×
payRate ×
ways ×
multiplier
```

---

# 19. FREE SPIN RULE

## Trigger

```text
3 SCATTER anywhere
```

---

## Effect

```text
10 free spins
```

---

# 20. BONUS RULE

## Trigger

```text
3 BONUS anywhere
```

---

## Effect

```text
bonus game
```

---

# 21. JACKPOT RULE

## Trigger condition

```text
fund > 2 × initPot
```

và:

```text
random jackpot hit
```

---

## Jackpot Prize

```text
jackpotPrize = pot
```

hoặc:

```text
jackpotPrize = 2 × pot
```

---

## Reset

```text
pot = initPotValue
```

---

# 22. SAFETY CHECK

## Rule

```text
fund - payout >= 0
```

---

## Nếu không đủ fund

```text
deny jackpot
deny big payout
generate safe result
```

---

# 23. AUTO PLAY FLOW

```text
AUTO_PLAY_MAHJONG2
↓
loop PLAY_MAHJONG2
↓
STOP_PLAY_MAHJONG2
```

---

# 24. FORCE STOP CONDITION

## Trigger khi:

```text
- hết tiền
- disconnect
- invalid session
- room error
```

---

# 25. SOCKET COMMANDS

## Client → Server

| Command              | ID   |
| -------------------- | ---- |
| SUBSCRIBE_MAHJONG2   | 6000 |
| CHANGE_ROOM_MAHJONG2 | 6001 |
| PLAY_MAHJONG2        | 6002 |
| AUTO_PLAY_MAHJONG2   | 6003 |
| STOP_PLAY_MAHJONG2   | 6004 |
| UNSUBSCRIBE_MAHJONG2 | 6005 |

---

## Server → Client

| Command                  | ID   |
| ------------------------ | ---- |
| RESULT_MAHJONG2          | 6050 |
| UPDATE_POT_MAHJONG2      | 6051 |
| BIG_WIN_MAHJONG2         | 6052 |
| FORCE_STOP_PLAY_MAHJONG2 | 6053 |

---

# 26. DATABASE FLOW

## Core Tables

| Table           | Purpose         |
| --------------- | --------------- |
| wallets         | user balance    |
| fund            | game fund       |
| jackpot_pot     | jackpot pot     |
| transactions    | ledger          |
| spin_history    | spin history    |
| jackpot_history | jackpot history |

---

# 27. SPIN HISTORY

## Save Data

| Field        | Purpose      |
| ------------ | ------------ |
| userId       | player       |
| roomId       | current room |
| totalBet     | total bet    |
| matrix       | board result |
| wins         | ways result  |
| totalWin     | payout       |
| jackpotPrize | jackpot      |
| createdTime  | audit        |

---

# 28. RESPONSE DESIGN

## RESULT_MAHJONG2

```json
{
  "cmd": 6050,

  "spinId": "",

  "matrix": [],

  "wins": [],

  "totalWin": 0,

  "balance": 0,

  "bet": {},

  "features": {},

  "jackpot": {},

  "state": {}
}
```

---

# 29. WINS[] STRUCTURE

```json
{
  "symbol": "ITEM_1",

  "matchCount": 4,

  "ways": 8,

  "multiplier": 1,

  "winAmount": 3200,

  "positions": [
    [0,0],
    [1,0],
    [1,1]
  ]
}
```

---

# 30. FRONTEND HIGHLIGHT DATA

Frontend dùng:

```text
positions[]
```

để:

```text
highlight symbol thắng
play ways animation
```

---

# 31. FINAL BACKEND DESIGN

Mahjong2 final backend architecture:

| Thành phần | Final Design    |
| ---------- | --------------- |
| Board      | 4x5             |
| Win System | Ways            |
| Payline    | removed         |
| Engine     | Ways Engine     |
| Bet Input  | betLevel        |
| Random     | weighted random |
| Response   | ways-centric    |
| Highlight  | positions       |
| Economy    | reuse system cũ |
| Jackpot    | reuse system cũ |
| Socket     | numeric command |

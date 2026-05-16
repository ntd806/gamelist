# Mahjong2 — Jackpot / Economy System Specification

## (Full Internal Backend Design)

---

# 1. OVERVIEW

Mahjong2 không tự xây economy riêng.

Mahjong2 reuse toàn bộ hệ thống:

```text id="mjlwmu"
wallet
fund
pot
transaction
jackpot
```

từ SlotMachine system cũ.

---

# 2. CORE ECONOMY FLOW

## Full Flow

```text id="xxdqdt"
player spin
↓
deduct totalBet
↓
split bet
↓
update pot
↓
update fund
↓
calculate win
↓
calculate jackpot
↓
safety check
↓
credit reward
↓
save transaction
↓
save history
```

---

# 3. WALLET SYSTEM

## Purpose

Quản lý:

```text id="a4l7eo"
player balance
```

---

# 4. WALLET FLOW

## Before Spin

```text id="qugjlwm"
validate balance >= totalBet
```

---

## Deduct

```text id="s7e9v4"
balance -= totalBet
```

---

## Credit

```text id="9wnjlwm"
balance += totalWin
```

---

# 5. BET STRUCTURE

## Real Formula

```text id="x1t6j5"
totalBet =
betSize ×
betLevel ×
baseBet
```

---

## Example

```text id="cfrjlwm"
2.50 × 9 × 20 = 450
```

---

# 6. BET SPLIT SYSTEM

## Formula

```text id="66m1y0"
fee = totalBet × 2%
moneyToPot = totalBet × 1%
moneyToFund = totalBet × 97%
```

---

# 7. PURPOSE OF EACH PART

| Part        | Purpose              |
| ----------- | -------------------- |
| fee         | operator revenue     |
| moneyToPot  | jackpot accumulation |
| moneyToFund | payout reserve       |

---

# 8. JACKPOT POT SYSTEM

## Purpose

```text id="tjlwm0"
jackpot prize pool
```

---

# 9. POT UPDATE FLOW

## Formula

```text id="h3wdn5"
pot += moneyToPot
```

---

# 10. FUND SYSTEM

## Purpose

```text id="2jlwm0"
reserve money for payouts
```

---

# 11. FUND UPDATE FLOW

## Formula

```text id="0x2cbk"
fund += moneyToFund
```

---

# 12. FUND RESPONSIBILITY

Fund dùng để:

```text id="yjlwm0"
normal payout
big payout
jackpot payout
free spin payout
cascade payout
```

---

# 13. PAYOUT FLOW

## Formula

```text id="ujlwm0"
fund -= payout
```

---

# 14. SAFETY CHECK

## Rule

```text id="9bjlwm"
fund - payout >= 0
```

---

# 15. SAFETY PURPOSE

Mục tiêu:

```text id="pjlwm0"
không cho game trả vượt quỹ
```

---

# 16. SAFETY FAILURE

Nếu:

```text id="3mjlwm"
fund - payout < 0
```

backend phải:

```text id="wjlwm0"
deny jackpot
deny dangerous payout
generate safe result
```

---

# 17. JACKPOT SYSTEM

Mahjong2 reuse jackpot architecture cũ.

---

# 18. JACKPOT PURPOSE

## Goal

```text id="djlwm0"
big random reward
```

---

# 19. JACKPOT CONDITION

## Main Rule

```text id="vjlwm0"
fund > 2 × initPotValue
```

---

# 20. WHY THIS CONDITION EXISTS

Mục tiêu:

```text id="jjlwm0"
đảm bảo quỹ đủ lớn trước khi nổ jackpot
```

---

# 21. JACKPOT RANDOM FLOW

```text id="2zjlwm"
check jackpot condition
↓
random jackpot chance
↓
if hit
→ payout jackpot
```

---

# 22. JACKPOT PRIZE

## Formula

```text id="gjlwm0"
jackpotPrize = pot
```

---

## Optional Variant

Một số room có thể:

```text id="ajlwm0"
jackpotPrize = pot × 2
```

---

# 23. JACKPOT PAYOUT FLOW

```text id="d4h6br"
trigger jackpot
↓
reward player
↓
fund -= jackpotPrize
↓
reset pot
↓
save jackpot history
↓
broadcast big win
```

---

# 24. POT RESET

## Formula

```text id="8jlwm0"
pot = initPotValue
```

---

# 25. INIT POT VALUE

## Example

```text id="2djlwm"
room 1 = 1,000,000
room 2 = 5,000,000
room 3 = 10,000,000
```

---

# 26. ROOM-BASED ECONOMY

Mỗi room có:

| Property       | Description   |
| -------------- | ------------- |
| bet config     | mức cược      |
| pot            | jackpot riêng |
| fund           | quỹ riêng     |
| RTP config     | riêng         |
| jackpot config | riêng         |

---

# 27. RTP CONTROL

## Purpose

```text id="xjlwm0"
control long-term payout ratio
```

---

# 28. RTP FLOW

Backend có thể:

```text id="0jlwm0"
increase/decrease symbol weight
```

để:

```text id="rjlwm0"
control payout frequency
```

---

# 29. RTP CONTROL TARGET

Ví dụ:

| RTP | Meaning |
| --- | ------- |
| 94% | trả 94% |
| 96% | trả 96% |
| 98% | trả 98% |

---

# 30. RANDOM CONTROL SYSTEM

Backend không random đều.

Backend dùng:

```text id="7jlwm0"
weighted random
```

---

# 31. WEIGHT PURPOSE

Dùng để control:

| Feature             | Control |
| ------------------- | ------- |
| win rate            | YES     |
| RTP                 | YES     |
| jackpot frequency   | YES     |
| scatter frequency   | YES     |
| free spin frequency | YES     |
| golden frequency    | YES     |

---

# 32. GOLDEN CONTROL

Golden symbol chỉ spawn:

```text id="zjlwm0"
reels 2, 3, 4
```

---

# 33. GOLDEN RESTRICTION

Không cho:

```text id="m8jlwm"
WILD
SCATTER
```

spawn golden.

---

# 34. FREE SPIN ECONOMY

Free spin vẫn dùng:

```text id="njlwm0"
fund payout bình thường
```

---

# 35. FREE SPIN PAYOUT FLOW

```text id="v5jlwm"
free spin win
↓
calculate cascade
↓
apply multiplier
↓
deduct fund
↓
credit player
```

---

# 36. CASCADE ECONOMY

Cascade payout được cộng dồn.

---

# 37. CASCADE FLOW

```text id="0g69cn"
spin
↓
ways win
↓
payout step 1
↓
cascade
↓
ways win
↓
payout step 2
↓
cascade
↓
...
↓
final total payout
```

---

# 38. TOTAL WIN FORMULA

## Formula

```text id="r3jlwm"
totalWin =
sum(all cascade payouts)
+
jackpotPrize
```

---

# 39. BIG WIN SYSTEM

## Purpose

```text id="3jlwm0"
broadcast large reward
```

---

# 40. BIG WIN CONDITION

Ví dụ:

```text id="qjlwm0"
totalWin >= 100 × totalBet
```

---

# 41. BIG WIN FLOW

```text id="jlwm00"
detect big win
↓
broadcast to room/server
↓
frontend animation
```

---

# 42. TRANSACTION SYSTEM

## Purpose

Audit tài chính.

---

# 43. SAVE TRANSACTION FLOW

```text id="jlwm11"
deduct bet
↓
save debit transaction
↓
reward player
↓
save credit transaction
```

---

# 44. TRANSACTION TYPES

| Type          | Meaning          |
| ------------- | ---------------- |
| BET           | deduct bet       |
| WIN           | normal win       |
| JACKPOT       | jackpot reward   |
| FREE_SPIN_WIN | free spin reward |

---

# 45. SPIN HISTORY SYSTEM

## Purpose

```text id="jlwm22"
audit gameplay
```

---

# 46. SPIN HISTORY SAVE DATA

| Data         | Purpose  |
| ------------ | -------- |
| userId       | player   |
| roomId       | room     |
| totalBet     | bet      |
| reels        | board    |
| cascadeSteps | gameplay |
| totalWin     | payout   |
| jackpotPrize | jackpot  |
| createdTime  | audit    |

---

# 47. JACKPOT HISTORY SYSTEM

## Save Data

| Data          | Purpose        |
| ------------- | -------------- |
| userId        | jackpot player |
| jackpotAmount | reward         |
| roomId        | room           |
| createdTime   | audit          |

---

# 48. AUTO PLAY ECONOMY FLOW

```text id="jlwm33"
auto play
↓
repeat play flow
↓
stop if:
- not enough money
- disconnect
- invalid session
```

---

# 49. FORCE STOP AUTO PLAY

## Backend Trigger

| Trigger              | Reason |
| -------------------- | ------ |
| insufficient balance | stop   |
| room error           | stop   |
| disconnect           | stop   |
| invalid session      | stop   |

---

# 50. JACKPOT ARCHITECTURE SUMMARY

Mahjong2 jackpot system gồm:

| Component       | Purpose          |
| --------------- | ---------------- |
| wallet          | player balance   |
| fund            | payout reserve   |
| pot             | jackpot pool     |
| RTP control     | payout balancing |
| weighted random | outcome control  |
| safety check    | prevent bankrupt |
| transaction     | financial audit  |
| spin history    | gameplay audit   |

---

# 51. FINAL ECONOMY FLOW

```text id="jlwm44"
player spin
↓
deduct totalBet
↓
split fee/pot/fund
↓
update economy
↓
generate result
↓
process cascade
↓
process multiplier
↓
calculate payout
↓
check jackpot
↓
safety check
↓
reward player
↓
save transaction
↓
save history
↓
broadcast result
```

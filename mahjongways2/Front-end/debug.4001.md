# Mahjong Ways 2 — Tài liệu kỹ thuật cho `cmd=4001`

## 1. Mục đích

`cmd=4001` là command chịu trách nhiệm xử lý một lượt quay của Mahjong Ways 2, bao gồm toàn bộ vòng đời từ lúc nhận request đến khi trả response về frontend:

```text
- Tiếp nhận request từ WebSocket
- Validate session và bet option
- Xác định chế độ chơi BASE hoặc FREE_SPIN
- Kiểm tra balance và debit ví đối với paid spin
- Sinh kết quả game
- Tính ways win, golden transform, cascade và scatter trigger
- Kiểm tra an toàn quỹ thưởng thông qua prize fund safety
- Settlement tiền thắng
- Cập nhật free spin session
- Build response trả về frontend
```

Command ID được định nghĩa tại:

```text
src/main/java/com/socket/command/model/Mahjong2CommandIds.java
```

```java
public static final int PLAY_MAHJONG2 = 4001;
```

---

# 2. Luồng xử lý tổng quan

```text
Client WebSocket
  ↓
Mahjong2SocketCommandDispatcher
  ↓
PlayCommandHandler
  ↓
Mahjong2SocketRequestMapper
  ↓
Mahjong2CommandHandler
  ↓
SpinOrchestrator
  ↓
GameEngine
  ↓
PrizeSafetyService
  ↓
MoneyTransactionService
  ↓
ResultAssembler
  ↓
FeAnimationResponseMapper
  ↓
FrontendLiveSpinResponseMapper, nếu compact response được bật
  ↓
Socket response
```

---

# 3. Điểm vào của request

## 3.1 `Mahjong2SocketCommandDispatcher`

File:

```text
src/main/java/com/socket/command/dispatcher/Mahjong2SocketCommandDispatcher.java
```

Trách nhiệm chính:

```text
- Parse raw WebSocket message
- Trích xuất cmd
- Tìm SocketCommandHandler tương ứng
- Thực thi handler
- Chuyển exception thành error response 3999
```

Luồng xử lý liên quan:

```java
JsonNode root = objectMapper.readTree(rawMessage);
int cmd = requestMapper.requiredCommand(root);

SocketCommandHandler handler =
    handlers.stream()
        .filter(candidate -> candidate.supports(cmd))
        .findFirst()
        .orElseThrow(...);

return writeResponses(handler.handle(root));
```

Ghi chú debug:

```text
Nếu request không đi tới PlayCommandHandler:
- Kiểm tra raw JSON có hợp lệ không
- Kiểm tra request có field cmd không
- Kiểm tra cmd có bằng 4001 không
- Kiểm tra PlayCommandHandler đã được register dưới dạng Spring bean chưa
```

Nếu exception phát sinh tại đây, exception sẽ được map thành:

```text
cmd = 3999
```

thông qua `SocketErrorMapper`.

---

## 3.2 `PlayCommandHandler`

File:

```text
src/main/java/com/socket/command/handler/PlayCommandHandler.java
```

Trách nhiệm chính:

```text
- Xác nhận handler này support cmd=4001
- Kiểm tra feature flag
- Map request JSON sang SpinRequest
- Gọi Mahjong2CommandHandler.handleSpin()
- Nếu cần, chuyển full response sang compact frontend response
```

Điều kiện support:

```java
public boolean supports(int commandId) {
  return commandId == Mahjong2CommandIds.PLAY_MAHJONG2;
}
```

Luồng xử lý chính:

```java
featureFlagService.requirePlayAllowed(gameCode);

SpinRequest request = requestMapper.toSpinRequest(root);

ResultMahjong2Response response =
    commandHandler.handleSpin(request);

return compactIfEnabled(response);
```

Điểm đặt breakpoint:

```text
Đặt breakpoint tại PlayCommandHandler.handle()

Kiểm tra:
- cmd
- gameCode
- sessionToken
- clientRequestId
- roomId
- betOptionId
- compactResponseEnabled
```

---

# 4. Mapping request và bảo vệ dữ liệu bet

## 4.1 `Mahjong2SocketRequestMapper`

File:

```text
src/main/java/com/socket/command/model/Mahjong2SocketRequestMapper.java
```

Trách nhiệm chính:

```text
- Validate cấu trúc request
- Từ chối các field liên quan đến bet amount do client tự gửi lên
- Resolve player context
- Resolve bet option từ roomId + betOptionId
- Build SpinRequest
```

Quy tắc quan trọng:

```text
Client không được submit trực tiếp bet amount.
Client chỉ được chọn roomId và betOptionId.
Server là nơi resolve mức bet thực tế.
```

Các field bet client bị cấm gửi:

```java
private static final Set<String> FORBIDDEN_CLIENT_BET_FIELDS =
    Set.of(
        "betSize",
        "betSizeMinor",
        "betLevel",
        "baseBet",
        "lineBet",
        "totalBet",
        "totalBetMinor",
        "betAmount",
        "betAmountMinor",
        "amount");
```

Nếu tồn tại bất kỳ field bị cấm nào:

```java
throw new MoneyDomainException(
    MoneyErrorCode.CLIENT_BET_FIELDS_NOT_ALLOWED,
    "CLIENT_BET_FIELDS_NOT_ALLOWED");
```

Request shape mong đợi:

```json
{
  "cmd": 4001,
  "gameCode": "MAHJONG_WAYS_2",
  "sessionToken": "...",
  "clientRequestId": "...",
  "roomId": 1,
  "betOptionId": "...",
  "turbo": false
}
```

Resolve bet option:

```java
BetOption betOption =
    betOptionCatalogProvider.catalog().resolve(roomId, betOptionId);
```

Ghi chú debug:

```text
Nếu request fail trước khi đi vào game logic:
- Kiểm tra client có gửi forbidden bet fields không
- Kiểm tra roomId
- Kiểm tra betOptionId
- Kiểm tra session token
- Kiểm tra quá trình resolve player context
```

---

# 5. Command facade

## `Mahjong2CommandHandler`

File:

```text
src/main/java/com/game/mahjong2/game/service/Mahjong2CommandHandler.java
```

Trách nhiệm chính:

```text
Đây là một facade mỏng, không chứa game logic.
```

Implementation:

```java
public ResultMahjong2Response handleSpin(SpinRequest request) {
  return spinOrchestrator.spin(request);
}
```

Class cần đọc tiếp theo:

```text
SpinOrchestrator.spin()
```

---

# 6. Điều phối vòng đời spin

## `SpinOrchestrator`

File:

```text
src/main/java/com/game/mahjong2/game/service/SpinOrchestrator.java
```

Đây là flow trung tâm trong production.

Trách nhiệm chính:

```text
- Xác định mode BASE / FREE_SPIN
- Validate bet
- Reserve idempotency
- Check balance
- Acquire active spin lock
- Start bet
- Sinh game result
- Áp dụng free spin scatter no-win rule nếu cần
- Áp dụng prize safety
- Settle win
- Cập nhật free spin session
- Build final response
```

---

## 6.1 Resolve mode

Phạm vi cần đọc:

```text
SpinOrchestrator.spin()
Phần đầu nơi freeSpinRemainingBefore, freeSpin, debitMoney và mode được tính toán.
```

Core logic:

```java
int freeSpinRemainingBefore =
    freeSpinEngine.freeSpinPlayable()
        ? playerSessionService.currentFreeSpins(request)
        : 0;

boolean freeSpin = freeSpinRemainingBefore > 0 && !devForceBaseMode;
boolean debitMoney = !freeSpin || freeSpinEngine.freeSpinDebitsMoney();

GameMode mode = freeSpin ? GameMode.FREE_SPIN : GameMode.BASE;
```

Ý nghĩa:

```text
freeSpinRemainingBefore > 0
  -> mode = FREE_SPIN

freeSpinRemainingBefore == 0
  -> mode = BASE
```

Điểm quan trọng:

```text
BASE thường debit ví.
FREE_SPIN thường không debit ví.
```

Biến cần inspect:

```text
freeSpinRemainingBefore
freeSpin
debitMoney
mode
devForceBaseMode
```

---

## 6.2 Validate bet

Core logic:

```java
BetContext bet =
    freeSpin
        ? validateFreeSpinBet(request)
        : betValidationService.validate(request);
```

BASE path:

```text
BetValidationService.validate(request)
```

FREE_SPIN path:

```text
validateFreeSpinBet(request)
```

Hành vi quan trọng:

```text
FREE_SPIN phải tái sử dụng bet đã được lock tại thời điểm trigger free spin.
Không được chấp nhận bet mới từ client.
```

Free spin bet-lock flow:

```java
triggerBet = playerSessionService.freeSpinTriggerBet(request);

if (triggerBet != null) {
  return betValidationService.validateFreeSpin(request, triggerBet);
}

BetContext fallbackBet = betValidationService.validate(request);
playerSessionService.storeFreeSpinTriggerBet(request, fallbackBet);

return betValidationService.validateFreeSpin(request, fallbackBet);
```

Debug khi user báo free spin dùng sai bet:

```text
Kiểm tra:
- freeSpinTriggerBet
- fallbackBet
- roomId
- betOptionId
- bet.totalBetMinor
- bet.totalBet
```

---

## 6.3 Idempotency

Core logic:

```java
ReservedPlayRequest reservedPlay =
    playRequestIdempotencyPort.reserve(
        requestWithValidatedBet(request, bet));

String spinId = reservedPlay.spinId();
String roundId = reservedPlay.roundId();

if (reservedPlay.duplicate()) {
  return duplicateResponse(reservedPlay);
}
```

Mục đích:

```text
Cùng một clientRequestId không được tạo nhiều round.
Duplicate request phải trả về response của round hiện có hoặc trạng thái pending.
```

Các status thường gặp:

```text
BET_PENDING
BET_SUCCESS
RESULT_GENERATED
SETTLE_PENDING
JACKPOT_PENDING
COMPLETED
FAILED
```

Biến cần inspect:

```text
clientRequestId
spinId
roundId
reservedPlay.duplicate()
reservedPlay.status()
```

---

## 6.4 Balance check cho paid BASE spin

Core logic:

```java
if (debitMoney && mode == GameMode.BASE) {
  MoneyResult balanceResult =
      checkBalanceBeforePaidBaseBet(request, spinId, roundId);

  if (balanceResult.balance().compareTo(requiredAmount) < 0) {
    throw insufficientBalanceException(...);
  }
}
```

Nếu balance không đủ:

```json
{
  "cmd": 3999,
  "message": "INSUFFICIENT_BALANCE",
  "balance": "...",
  "requiredAmount": "...",
  "shortfall": "..."
}
```

Quan trọng:

```text
Nếu request fail tại đây, GameEngine sẽ chưa được execute.
```

Biến cần inspect:

```text
balance
requiredAmount
shortfall
bet.totalBetMinor
```

---

## 6.5 Active spin lock

Core logic:

```java
boolean acquired =
    activeSpinLockPort.acquire(
        partnerCode(request),
        request.userId(),
        request.gameCode(),
        roundId);

if (!acquired) {
  throw new ActiveSpinPendingException(...);
}
```

Mục đích:

```text
Ngăn concurrent active spins cho cùng một user/game.
```

Lỗi có thể gặp:

```text
ACTIVE_SPIN_ALREADY_EXISTS
```

Debug khi gặp lỗi này:

```text
Kiểm tra:
- Round trước đã completed chưa?
- Active lock đã được release chưa?
- Retry dùng cùng clientRequestId hay clientRequestId mới?
- Frontend có đang fire nhiều spin request đồng thời không?
```

---

## 6.6 Start bet

Core logic:

```java
MoneyResult betResult =
    moneyTransactionService.startBet(
        new StartBetCommand(
            request.userId(),
            request.sessionToken(),
            roundId,
            request.currency(),
            bet.totalBetMinor(),
            request.gameCode(),
            partnerCode(request)));

if (betResult.state() != MoneyTransactionState.BET_SUCCESS) {
  mark pending status;
  throw pendingException(...);
}
```

Mục đích:

```text
Debit wallet cho paid BASE spin.
```

Quan trọng:

```text
FREE_SPIN thường skip startBet vì debitMoney=false.
```

Biến cần inspect:

```text
roundId
bet.totalBetMinor
betResult.state()
betResult.balance()
transaction id
```

Nếu exception xảy ra sau khi bet thành công nhưng trước khi generate result, code sẽ cố gắng cancel bet.

---

## 6.7 Generate game result

Core logic:

```java
GameSpinResult spinResult =
    gameEngine.spin(spinId, mode, bet);

spinResult =
    forceFreeSpinScatterNoWinIfNeeded(spinResult);
```

Mục đích:

```text
GameEngine sinh math result.
Sau đó, SpinOrchestrator vẫn có thể điều chỉnh result bằng business rules.
```

Biến cần inspect:

```text
spinResult.mode()
spinResult.totalWinMinor()
spinResult.regularWinMinor()
spinResult.scatterCount()
spinResult.freeSpinsAwarded()
spinResult.cascadeSteps().size()
```

Quan trọng:

```text
GameEngine result chưa chắc là final result trả về player.
PrizeSafetyService vẫn có thể điều chỉnh result.
```

---

## 6.8 FREE_SPIN scatter no-win rule

Core logic:

```java
if (spinResult.mode() == GameMode.FREE_SPIN
    && !freeSpinEngine.freeSpinRetriggerEnabled()
    && spinResult.scatterCount() >= config.freeSpinScatterCount()) {
  return safeSpinResultFactory.noWin(spinResult);
}
```

Ý nghĩa:

```text
Nếu retrigger bị disable và một FREE_SPIN result kết thúc với đủ scatter,
result có thể bị convert thành no-win.
```

Debug grep:

```bash
grep -RIn "FREE_SPIN_SCATTER_FORCED_NOWIN" logs/
```

Ghi chú:

```text
Board generation và cascade đã có guard logic để tránh disabled retrigger cases,
vì vậy rule này là safety fallback.
```

---

## 6.9 Prize safety

Core logic:

```java
boolean paidSpinRequiresPrizeSafety = debitMoney;

boolean freeSpinPayoutRequiresPrizeSafety =
    mode == GameMode.FREE_SPIN
        && moneyTransactionService.supportsFreeSpinWinSettlement()
        && spinResult.regularWinMinor() > 0;

if ((paidSpinRequiresPrizeSafety || freeSpinPayoutRequiresPrizeSafety)
    && prizeSafetyService != null) {
  SafetyAdjustedResult safetyResult =
      prizeSafetyService.evaluateBeforeSettle(
          roundId,
          request.currency(),
          spinResult);

  spinResult = safetyResult.spinResult();
}
```

Mục đích:

```text
Đảm bảo prize payout được backing bởi pool/bucket fund.
```

Hành vi critical:

```text
PrizeSafetyService có thể convert một winning result thành no-win result
nếu prize fund không đủ.
```

Điều này đặc biệt quan trọng khi debug complaint dạng:

```text
"Players enter free spin often but rarely win."
```

Không chỉ inspect weights. Cần inspect cả các quyết định của prize safety.

---

# 7. Game math flow

## `GameEngine`

File:

```text
src/main/java/com/game/mahjong2/game/service/GameEngine.java
```

Trách nhiệm chính:

```text
- Generate initial board
- Chạy ways payout
- Áp dụng golden transform
- Chạy cascade
- Lặp lại cho đến khi không còn win hoặc chạm max cascade
- Đếm final scatters
- Award free spins
- Trả về GameSpinResult
```

---

## 7.1 Generate initial board

Core logic:

```java
Mahjong2Board initial = boardFactory.generate(mode);

if (mode == GameMode.BASE) {
  initial = forceFreeSpinTriggerService.force(initial);
}
```

Debug:

```text
Nếu initial board sai:
- Kiểm tra BoardFactory
- Kiểm tra WeightedSymbolGenerator
- Kiểm tra active config JSON
- Kiểm tra forceFreeSpinTriggerService
```

---

## 7.2 Select multiplier profile

Core logic:

```java
CascadeMultiplierProfile multiplierProfile =
    resolveMultiplierProfile(mode);
```

Resolver:

```java
if (mode == GameMode.FREE_SPIN) {
  return CascadeMultiplierProfile.FREE_SPIN;
}
return CascadeMultiplierProfile.BASE;
```

Expected multipliers:

```text
BASE      = [1, 2, 3, 5]
FREE_SPIN = [2, 4, 6, 10]
```

Quy tắc quan trọng:

```text
Nếu một BASE spin trigger free spins, spin hiện tại vẫn phải dùng BASE multipliers.
FREE_SPIN multipliers chỉ bắt đầu từ spin kế tiếp.
```

---

## 7.3 Cascade loop

Core logic:

```java
for (int step = 0; step < maxCascadeSteps; step++) {
  int multiplier = config.multiplierFor(multiplierProfile, step);

  PayoutResult payout =
      waysPayoutEngine.calculate(
          current,
          bet.lineBetMinor(),
          multiplier);

  if (!payout.hasWin()) {
    break;
  }

  Set<WinPosition> winningPositions =
      waysPayoutEngine.winningPositions(payout);

  winningPositions.removeIf(
      position -> ScatterReelGuard.isScatterPosition(
          config,
          boardBeforeCascade,
          position));

  GoldenTransformResult goldenResult =
      goldenSymbolEngine.transformWinningGoldenSymbols(
          current,
          winningPositions);

  Set<WinPosition> removedPositions =
      new HashSet<>(winningPositions);

  goldenResult.transformed()
      .forEach(transform -> removedPositions.remove(transform.position()));

  Mahjong2Board after =
      cascadeEngine.cascade(
          goldenResult.board(),
          removedPositions,
          mode);

  steps.add(new CascadeStep(...));

  totalWinMinor += payout.totalWinMinor();
  current = after;
}
```

Ý nghĩa:

```text
1. Calculate ways win.
2. Dừng nếu không có win.
3. Không remove scatter positions.
4. Golden winning symbols transform thành WILD.
5. Golden transformed cells không bị remove.
6. Remove non-golden winning cells.
7. Cascade board.
8. Tiếp tục với after board.
```

Biến cần inspect theo từng step:

```text
step
multiplier
boardBeforeCascade
winningWays
winningPositions
goldenTransforms
removedPositions
reelsAfterDrop
stepWinMinor
totalWinMinor
```

---

## 7.4 Scatter count và free spin award

Core logic:

```java
int scatterCount = freeSpinEngine.scatterCount(current);
int freeSpinsAwarded = freeSpinEngine.awardFor(mode, current);
```

Quan trọng:

```text
Scatter được count sau toàn bộ cascade, dựa trên final board.
```

Điều này fix nhóm bug cũ:

```text
Initial board chỉ có 1 hoặc 2 scatters.
Cascade drop thêm scatters.
Final board có 3/4/5 scatters.
Free spin phải được award.
```

Biến cần inspect:

```text
initial scatter count
final scatter count
freeSpinsAwarded
freeSpin.triggered
freeSpin.remaining
next spin mode
```

---

# 8. Board generation và symbol weights

## 8.1 `BoardFactory`

File:

```text
src/main/java/com/game/mahjong2/game/service/BoardFactory.java
```

Trách nhiệm chính:

```text
Generate initial math board từ reel layout và symbol weights.
```

Core logic:

```java
List<Integer> layout = config.reelLayout();

for each reel:
  for each row:
    if (mode == BASE) {
      cell = ScatterReelGuard.nextCellAvoidingDuplicateScatter(...);
    } else {
      cell = ScatterReelGuard.nextCellAvoidingDisabledFreeSpinRetrigger(...);
    }

return new Mahjong2Board(reels, layout);
```

Math layout:

```text
[4, 5, 5, 5, 4]
```

---

## 8.2 `WeightedSymbolGenerator`

File:

```text
src/main/java/com/game/mahjong2/game/service/WeightedSymbolGenerator.java
```

Trách nhiệm chính:

```text
Select symbol theo weighted random.
Apply golden flag nếu symbol đủ điều kiện.
```

Core logic:

```java
Map<String, Integer> weights =
    config.symbolWeightsForReel(mode, reelIndex);

int totalWeight = sum(weights);
int ticket = randomProvider.nextInt(totalWeight);

for each symbol weight:
  cursor += weight;
  if (ticket < cursor) {
    return selected symbol;
  }
```

Với FREE_SPIN:

```java
if (mode == GameMode.FREE_SPIN
    && freeSpinReelSymbolWeights exists) {
  return freeSpinReelSymbolWeights.get(reelIndex);
}
```

Debug nếu hit-rate sai:

```text
Log:
- mode
- reelIndex
- weights
- totalWeight
- ticket
- selectedSymbol
- golden
```

---

# 9. Ways payout

## `WaysPayoutEngine`

File:

```text
src/main/java/com/game/mahjong2/game/service/WaysPayoutEngine.java
```

Trách nhiệm chính:

```text
Calculate toàn bộ winning ways theo chiều left-to-right.
```

Core logic:

```java
for each payable symbol:
  ways = 1
  matchedReels = 0

  for reelIndex from 0 to 4:
    reelMatches = matchingPositions(symbol, reelIndex)

    if reelMatches is empty:
      break

    matchedReels++
    ways *= reelMatches.size()

  if matchedReels >= minMatchedReels:
    win = lineBet * paytable * ways * multiplier
```

Matching rule:

```java
current.equals(symbol)
|| current.equals(config.wildSymbol())
```

Quan trọng:

```text
Chỉ math/playable cells được tính vào payout.
displayOnly cells bị exclude thông qua MathBoardView.
```

Biến cần inspect:

```text
symbol
matchedReels
ways
paytable multiplier
cascade multiplier
lineBetMinor
winAmountMinor
positions
```

---

# 10. Golden transform

## `GoldenSymbolEngine`

File:

```text
src/main/java/com/game/mahjong2/game/service/GoldenSymbolEngine.java
```

Trách nhiệm chính:

```text
Transform winning golden symbols thành WILD.
```

Hành vi:

```text
Nếu golden symbol tham gia win:
- Nó được transform thành WILD
- Nó không bị remove trong cascade hiện tại
- Nó có thể hỗ trợ các cascade win tiếp theo
```

Core logic:

```java
if (cell.golden()) {
  Mahjong2Cell next =
      new Mahjong2Cell(config.wildSymbol(), false);

  board.set(position, next);
  transformed.add(new GoldenTransform(...));
}
```

Debug:

```text
Nếu golden symbol biến mất thay vì transform:
- Kiểm tra GoldenSymbolEngine
- Kiểm tra removedPositions logic trong GameEngine
- Kiểm tra visualGoldenTransforms trong response
```

---

# 11. Cascade và displayOnly

## 11.1 `MathBoardView`

File:

```text
src/main/java/com/game/mahjong2/game/service/MathBoardView.java
```

Trách nhiệm chính:

```text
Bridge giữa math board và visual board.
```

Math layout:

```text
[4, 5, 5, 5, 4]
```

Visual layout:

```text
[6, 5, 5, 5, 6]
```

Edge columns:

```text
col0 row0 = displayOnly
col0 row1-row4 = playable
col0 row5 = displayOnly

col4 row0 = displayOnly
col4 row1-row4 = playable
col4 row5 = displayOnly
```

Middle columns:

```text
col1/2/3 row0-row4 = playable
```

Quy tắc quan trọng:

```text
displayOnly là positional flag.
Nó phải được recompute từ col,row sau mỗi cascade.
Không được giữ displayOnly như state cố định gắn với item.
```

---

## 11.2 `CascadeEngine`

File:

```text
src/main/java/com/game/mahjong2/game/service/CascadeEngine.java
```

Trách nhiệm chính:

```text
Remove winning cells và generate next board.
```

Core flow:

```text
1. Convert board sang display layout.
2. Convert winning math rows sang board rows.
3. Không remove scatter cells.
4. Remove winning non-golden cells.
5. Giữ remaining cells theo thứ tự.
6. Append new symbols.
7. Recompute displayOnly theo final row.
8. Return display board.
```

Expected drop rule:

```text
REMOVE_THEN_KEEP_ORDER_APPEND_NEW_RECOMPUTE_DISPLAY_ONLY_BY_ROW
```

Debug nếu cascade visual sai:

```text
Kiểm tra:
- boardBeforeCascade
- removedPositions
- displayBoard before removal
- kept cells
- new symbols
- final after board
- displayOnly cho từng row
```

---

# 12. Animation mapping cho FE

## `FeAnimationResponseMapper`

File:

```text
src/main/java/com/game/mahjong2/game/service/FeAnimationResponseMapper.java
```

Trách nhiệm chính:

```text
Convert GameSpinResult thành frontend animation data:
- animationReels
- visualWins
- animationColumns.before
- animationColumns.removed
- animationColumns.moves
- animationColumns.newSymbols
- animationColumns.after
- visualGoldenTransforms
```

---

## 12.1 Initial animation reels

Hành vi:

```text
Convert initial math board thành visual board.
Edge columns có thêm top và bottom displayOnly buffer cells.
```

Output:

```text
animationReels
```

---

## 12.2 Cascade step mapping

Core flow:

```text
current = initial visual state

for each CascadeStep:
  before = current.visualBoard
  visualGoldenTransforms = map golden transforms
  visualWins = map math win positions sang visual positions
  animationColumns = build before/removed/moves/newSymbols/after
  after = animationColumns.after
  current = after
```

Invariant quan trọng:

```text
Step i+1 before phải bằng Step i after.
```

Debug nếu step 2 sai:

```text
So sánh:
- step 1 animationColumns.after
- step 2 animationColumns.before
```

Hai dữ liệu này phải match tuyệt đối.

---

## 12.3 Visual win validation

Mapper validate:

```text
- visual win position phải trỏ đúng internal cellId
- visual win position không được là displayOnly=true
- symbol tại visual win cell phải match winning symbol hoặc WILD
```

Nếu validate fail, bug thường nằm ở:

```text
- math row to visual row mapping
- cascade after board
- nextMathCellIds
- golden transform mapping
```

---

## 12.4 Animation columns

Mỗi cascade column gồm:

```text
before
removed
moves
newSymbols
after
```

Ý nghĩa:

```text
before:
  Column trước khi removal.

removed:
  Các cells bị remove do win.

moves:
  Các old cells thay đổi row sau cascade.

newSymbols:
  Newly generated symbols và target row tương ứng.

after:
  Column sau khi cascade hoàn tất.
```

Quan trọng:

```text
newSymbols.displayOnly phải match toRow.
moves.toDisplayOnly phải match toRow.
after.displayOnly phải match final row.
```

---

# 13. Free spin engine

## `FreeSpinEngine`

File:

```text
src/main/java/com/game/mahjong2/game/service/FreeSpinEngine.java
```

Trách nhiệm chính:

```text
- Count final scatters
- Award free spins
- Apply retrigger rules
```

Core logic:

```java
if (scatterCount < freeSpinScatterCount) {
  return 0;
}

awarded =
    freeSpinBaseAward
    + (scatterCount - freeSpinScatterCount)
      * freeSpinExtraPerScatter;
```

Expected award:

```text
3 scatters -> 10 free spins
4 scatters -> 12 free spins
5 scatters -> 14 free spins
```

Quan trọng:

```text
Scatter count sử dụng MathBoardView.cellsInReel().
displayOnly scatter không được count.
Playable scatter được count.
```

Debug nếu free spin không trigger:

```text
Kiểm tra:
- final board after cascade
- scatterCount
- freeSpinsAwarded
- freeSpin.triggered
- next spin state.mode
```

---

# 14. Prize safety

## `PrizeSafetyService`

File:

```text
src/main/java/com/game/mahjong2/jackpot/service/PrizeSafetyService.java
```

Trách nhiệm chính:

```text
Bảo vệ pool/bucket fund trước khi settle prize payout.
```

Core flow:

```text
1. Calculate prize breakdown.
2. Load spin intent.
3. Load jackpot pool.
4. Load prize fund bucket.
5. Calculate fund cost.
6. Nếu fund đủ, reserve payout cost.
7. Nếu fund không đủ, replace result bằng safe no-win result.
```

Hành vi critical:

```java
GameSpinResult safe =
    safeSpinResultFactory.noWin(spinResult);
```

Các safety block reason thường gặp:

```text
ALL_PRIZES_ZEROED_BY_FUND_SAFETY
AGGREGATE_FUND_MISMATCH
```

Debug grep:

```bash
grep -RIn "ALL_PRIZES_ZEROED_BY_FUND_SAFETY\|AGGREGATE_FUND_MISMATCH" logs/
```

Production note quan trọng:

```text
Một spin có thể win trong GameEngine nhưng vẫn trả no-win về FE
nếu bị PrizeSafetyService block.
```

Điều này đặc biệt critical với complaint dạng:

```text
"Free spin enters often but does not pay."
```

Biến cần inspect:

```text
roundId
regularWinMinor before safety
jackpotWinMinor before safety
fundCostMinor
poolCode
poolFundMinor
bucketCode
bucketFundMinor
safetyDecision.allowed
safetyDecision.reason
regularWinMinor after safety
```

---

# 15. Money settlement

## 15.1 Paid BASE spin

Main flow trong `SpinOrchestrator`:

```text
1. startBet
2. GameEngine spin
3. PrizeSafety check
4. settle regular win
5. jackpotWin nếu có
6. assemble response
7. update free spin session nếu được trigger
8. complete round
9. release active spin lock
```

Debug nếu có wallet issue:

```text
Kiểm tra:
- startBet state
- settle state
- jackpotWin state
- round status
- balance before
- balance after
```

---

## 15.2 FREE_SPIN spin

Main flow:

```text
1. Không startBet nếu freeSpinDebitsMoney=false
2. GameEngine spin
3. PrizeSafety check nếu win settlement được support
4. Nếu win > 0: settleFreeSpinWin
5. Nếu win = 0: getBalance
6. consume free spin
7. complete round
```

Quan trọng:

```text
FREE_SPIN vẫn có thể gọi wallet settlement nếu có win.
```

---

# 16. Response assembly

## 16.1 `ResultAssembler`

File:

```text
src/main/java/com/game/mahjong2/game/service/ResultAssembler.java
```

Trách nhiệm chính:

```text
Build full ResultMahjong2Response.
```

Các output fields chính:

```text
cmd
spinId
roundId
animationReels
cascadeSteps
totalWin
balance
bet
freeSpin
jackpot
state
```

Quan trọng:

```text
ResultAssembler nhận final spinResult sau PrizeSafety.
Vì vậy response phản ánh adjusted result,
không nhất thiết là raw GameEngine result.
```

---

## 16.2 `ResultMahjong2Response`

File:

```text
src/main/java/com/game/mahjong2/game/dto/ResultMahjong2Response.java
```

Internal DTO có `cellId`, nhưng nhiều field `cellId` được annotate bằng:

```java
@JsonIgnore
```

Ý nghĩa:

```text
cellId được dùng cho internal tracing nhưng không expose trong JSON response.
```

Nếu FE cần item identity tracing, việc expose field này phải là thay đổi có chủ đích.

---

## 16.3 `FrontendLiveSpinResponseMapper`

File:

```text
src/main/java/com/game/mahjong2/game/dto/frontend/FrontendLiveSpinResponseMapper.java
```

Trách nhiệm chính:

```text
Map full response sang compact response cho FE nếu compact mode được bật.
```

Compact response gồm:

```text
cmd
animationReels
cascadeSteps
totalWin
balance
bet
freeSpin
state
```

Current compact cascade data gồm:

```text
before
removed
moves
newSymbols
after
```

Tuy nhiên compact response vẫn chưa expose `cellId`.

---

# 17. Error response

## `Mahjong2ErrorResponse`

File:

```text
src/main/java/com/game/mahjong2/game/dto/Mahjong2ErrorResponse.java
```

Error command:

```text
cmd = 3999
```

Các lỗi thường gặp:

```text
INSUFFICIENT_BALANCE
ACTIVE_SPIN_ALREADY_EXISTS
CLIENT_BET_FIELDS_NOT_ALLOWED
BET_PENDING
SETTLE_PENDING
JACKPOT_PENDING
WALLET_TIMEOUT
```

Quy tắc debug quan trọng:

```text
Nếu response là 3999, không debug GameEngine trước.
Hãy kiểm tra error message và state transition trong SpinOrchestrator trước.
```

---

# 18. Debug playbooks

## 18.1 Response là `3999`

Kiểm tra theo thứ tự:

```text
1. SocketErrorMapper
2. Mahjong2ErrorResponse
3. SpinOrchestrator balance check
4. SpinOrchestrator active spin lock
5. Idempotency status
6. Wallet transaction state
```

Root causes thường gặp:

```text
- Insufficient balance
- Active spin chưa được release
- Client gửi forbidden bet fields
- Wallet timeout
- Bet hoặc settle đang pending
```

---

## 18.2 Free spin vào thường xuyên nhưng hiếm khi win

Kiểm tra theo thứ tự:

```text
1. WeightedSymbolGenerator
2. Active config freeSpinReelSymbolWeights
3. WaysPayoutEngine
4. GameEngine raw spinResult trước PrizeSafety
5. forceFreeSpinScatterNoWinIfNeeded
6. PrizeSafetyService
7. Final response totalWin
```

Phân biệt quan trọng:

```text
Raw GameEngine win > 0
Final response win = 0
  -> Kiểm tra PrizeSafetyService hoặc no-win safety rule.

Raw GameEngine win = 0
Final response win = 0
  -> Kiểm tra weights, paytable, ways logic, board distribution.
```

---

## 18.3 Scatter drop sau cascade nhưng free spin không trigger

Kiểm tra:

```text
1. GameEngine final board after cascade
2. FreeSpinEngine.scatterCount()
3. MathBoardView.cellsInReel()
4. FreeSpinEngine.awardFor()
5. SpinOrchestrator.startFreeSpinSession()
6. Next spin state.mode
```

Expected behavior:

```text
Nếu final playable scatter count >= 3 trong BASE spin:
- freeSpin.triggered = true
- remaining = 10/12/14
- next spin mode = FREE_SPIN
```

---

## 18.4 Cascade / displayOnly issue

Kiểm tra:

```text
1. CascadeEngine.cascade()
2. MathBoardView.toDisplayBoard()
3. FeAnimationResponseMapper.cascadeSteps()
4. animationColumns.before
5. animationColumns.removed
6. animationColumns.moves
7. animationColumns.newSymbols
8. animationColumns.after
```

Required invariants:

```text
- step i+1 before == step i after
- visualWins không được trỏ vào displayOnly=true
- visualWins symbol phải match actual symbol hoặc WILD
- removed không được chứa displayOnly=true
- moves.toDisplayOnly phải match destination row
- newSymbols.displayOnly phải match toRow
- after.displayOnly phải match row rule
```

---

## 18.5 Balance mismatch

Kiểm tra:

```text
1. BetValidationService
2. MoneyScale
3. SpinOrchestrator.startBet()
4. MoneyTransactionService
5. ResultAssembler bet object
6. Wallet balance response
```

Expected paid BASE formula:

```text
balanceDelta = totalWin - totalBet
```

Expected FREE_SPIN formula:

```text
balanceDelta = totalWin
```

---

# 19. Recommended breakpoints

Dùng thứ tự này cho một phiên end-to-end debug đầy đủ:

```text
1. Mahjong2SocketCommandDispatcher.dispatchAll()
2. PlayCommandHandler.handle()
3. Mahjong2SocketRequestMapper.toSpinRequest()
4. BetValidationService.validate()
5. SpinOrchestrator.spin()
6. SpinOrchestrator mode resolution
7. SpinOrchestrator bet validation
8. SpinOrchestrator idempotency reserve
9. SpinOrchestrator balance check
10. SpinOrchestrator active spin lock
11. SpinOrchestrator startBet
12. GameEngine.spin()
13. BoardFactory.generate()
14. WeightedSymbolGenerator.nextCell()
15. WaysPayoutEngine.calculate()
16. GoldenSymbolEngine.transformWinningGoldenSymbols()
17. CascadeEngine.cascade()
18. FreeSpinEngine.scatterCount()
19. FreeSpinEngine.awardFor()
20. SpinOrchestrator.forceFreeSpinScatterNoWinIfNeeded()
21. PrizeSafetyService.evaluateBeforeSettle()
22. MoneyTransactionService.settle()
23. SpinOrchestrator.applyFreeSpinSessionMutationAfterSuccessfulOutcome()
24. ResultAssembler.assemble()
25. FeAnimationResponseMapper.cascadeSteps()
26. FrontendLiveSpinResponseMapper.toFrontend()
```

---

# 20. Suggested production logs

Nên bổ sung structured logs tại các điểm sau.

## Request context

```text
cmd
clientRequestId
userId
sessionToken masked
gameCode
roomId
betOptionId
currency
```

## Mode / bet context

```text
mode
freeSpinRemainingBefore
debitMoney
freeSpinDebitsMoney
totalBetMinor
lineBetMinor
totalBetDisplay
```

## Game result trước safety

```text
spinId
roundId
mode
cascadeStepCount
cascadeMultipliers
regularWinMinor
totalWinMinor
scatterCount
freeSpinsAwarded
```

## Prize safety

```text
roundId
poolCode
bucketCode
fundCostMinor
poolFundMinor
bucketFundMinor
safetyAllowed
safetyReason
winBeforeSafety
winAfterSafety
```

## Money

```text
startBetState
settleState
jackpotState
balanceBefore
balanceAfterBet
balanceAfterSettle
requiredAmount
shortfall
```

## Free spin session

```text
remainingBefore
awarded
remainingAfter
retriggered
triggerBet
sessionMutated
```

---

# 21. Developer mental model

Dùng mental model sau khi debug:

```text
SpinOrchestrator quản lý lifecycle và money.
GameEngine quản lý math result.
PrizeSafetyService có thể override math result.
ResultAssembler quản lý final API response.
FeAnimationResponseMapper quản lý visual/cascade contract cho FE.
```

Sai lầm debug phổ biến nhất là chỉ đọc `GameEngine`.

Điều đó không đủ vì:

```text
- Request có thể fail trước GameEngine
- Wallet có thể fail trước hoặc sau GameEngine
- PrizeSafety có thể convert win thành no-win
- Free spin session chỉ update sau successful payout
- Compact response có thể ẩn internal fields như cellId
```

---

# 22. Final sequence cho `cmd=4001`

```text
1. WebSocket nhận raw JSON.
2. Dispatcher extract cmd.
3. PlayCommandHandler xử lý cmd=4001.
4. RequestMapper reject forbidden client bet fields.
5. RequestMapper resolve player và bet option.
6. Mahjong2CommandHandler gọi SpinOrchestrator.
7. SpinOrchestrator resolve BASE hoặc FREE_SPIN.
8. SpinOrchestrator validate bet.
9. SpinOrchestrator reserve idempotency.
10. BASE spin check balance.
11. Active spin lock được acquire.
12. BASE spin start bet và debit wallet.
13. GameEngine generate initial board.
14. WaysPayoutEngine calculate wins.
15. GoldenSymbolEngine transform winning golden symbols thành WILD.
16. CascadeEngine remove winning cells và drop board.
17. GameEngine lặp cascade cho tới khi không còn win.
18. GameEngine count final scatters.
19. GameEngine award free spins nếu đủ điều kiện.
20. SpinOrchestrator apply free spin scatter no-win guard nếu cần.
21. PrizeSafetyService check fund.
22. PrizeSafetyService có thể giữ nguyên result hoặc replace bằng no-win.
23. MoneyTransactionService settle regular/free spin win.
24. SpinOrchestrator mutate free spin session sau successful payout.
25. ResultAssembler build ResultMahjong2Response.
26. FeAnimationResponseMapper build visual animation data.
27. FrontendLiveSpinResponseMapper compact response nếu được bật.
28. WebSocket trả response về client.
```

---

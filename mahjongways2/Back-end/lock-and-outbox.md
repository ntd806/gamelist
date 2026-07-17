Dưới đây là bản tổng hợp có thể dùng làm **tài liệu chung cho mọi dự án backend có xử lý tiền / dữ liệu quan trọng**. Ví dụ cụ thể được lấy từ lần rà soát source **`slot-mahjong-ways2(49).zip`**. Nếu source mới đã thay đổi sau bản zip này thì cần audit lại.

# Tài liệu chung: Cơ chế khóa và bảo vệ dữ liệu / bảo vệ tiền

## 1. Nguyên tắc tổng quát

Với hệ thống có tiền thật, mục tiêu không phải là “chạy nhanh nhất”, mà là:

```text
Không double charge.
Không double payout.
Không mất event.
Không settle khi chưa reserve tiền.
Không ghi sai trạng thái.
Không mất dữ liệu khi Rabbit/Mongo/Wallet lỗi.
Có thể retry an toàn.
Có thể audit lại sau sự cố.
```

Một hệ thống tốt thường không dựa vào một lớp bảo vệ duy nhất. Nó nên có nhiều lớp:

```text
1. Idempotency
2. Unique constraint
3. DB transaction
4. Pessimistic lock
5. Optimistic version
6. State machine
7. Ledger/audit trail
8. Retry/recovery
9. Outbox pattern
10. Idempotent consumer
11. DLQ/manual review
12. Monitoring/reconciliation
```

Trong dự án Mahjong Ways 2, các lớp này đã xuất hiện khá rõ.

---

# 2. Idempotency: chống gửi lại request gây double tiền

## Mục đích

Idempotency giúp cùng một request bị gửi lại nhiều lần vẫn chỉ tạo **một kết quả tiền**.

Ví dụ lỗi thường gặp:

```text
Client gọi spin.
Server xử lý thành công nhưng response timeout.
Client retry cùng request.
Nếu không có idempotency => có thể bị trừ tiền 2 lần.
```

## Flow chuẩn

```text
Client gửi request với clientRequestId.
Backend kiểm tra clientRequestId đã tồn tại chưa.
Nếu chưa có:
  tạo round mới.
Nếu đã có:
  trả lại round/result cũ hoặc xử lý tiếp theo trạng thái hiện tại.
```

## Ví dụ trong dự án

Dự án có unique constraint cho round:

```text
PlatformMoneyRound
- uq_money_rounds_round_id
- uq_money_rounds_idempotency(partner_code, player_id, game_code, client_request_id)
```

File ví dụ:

```text
src/main/java/com/game/mahjong2/platformadapter/money/PlatformMoneyRound.java
src/main/java/com/game/mahjong2/platformadapter/money/PlatformMoneyStateService.java
```

Ngoài ra transaction wallet cũng có unique `transaction_id`:

```text
PlatformMoneyTransaction
- uq_money_transactions_transaction_id
```

Ý nghĩa:

```text
Cùng một round/spin sẽ có transactionId cố định.
Retry không sinh thêm transaction mới.
```

---

# 3. Redis lock: khóa nhanh ở tầng ngoài

Redis không nên là lớp bảo vệ tiền cuối cùng. Redis thường dùng để **chặn sớm**, giảm race/spam trước khi vào DB.

Trong dự án này, Redis đang dùng 3 kiểu chính.

## 3.1 Active Spin Lock

Mục đích:

```text
Một player không được mở nhiều spin active cùng lúc cho cùng game.
```

Cơ chế:

```text
SETNX + TTL + owner token + Lua compare-and-delete
```

Ví dụ source:

```text
src/main/java/com/game/mahjong2/platformadapter/lock/RedisMahjongActiveSpinLock.java
```

Key dạng:

```text
s8:lock:spin:{partnerCode}:{playerId}:{gameCode}
```

Value:

```text
roundId
```

TTL mặc định:

```text
120 giây
```

Acquire:

```java
setIfAbsent(key, lockOwner, lockTtl)
```

Release dùng Lua:

```lua
if redis.call('get', KEYS[1]) == ARGV[1] then
  return redis.call('del', KEYS[1])
else
  return 0
end
```

Vì sao cần owner token?

```text
Để round A không xóa nhầm lock của round B.
```

Rủi ro cần nhớ:

```text
Nếu spin/wallet treo lâu hơn TTL, lock có thể hết hạn.
Vì vậy Redis lock không thay thế DB lock.
```

---

## 3.2 Redis Idempotency Reservation

Mục đích:

```text
Chặn nhanh retry cùng clientRequestId.
```

Ví dụ source:

```text
src/main/java/com/game/mahjong2/platformadapter/idempotency/RedisMahjongIdempotencyCache.java
```

Key dạng:

```text
s8:idem:{partnerCode}:{playerId}:{gameCode}:{clientRequestId}
```

Value:

```text
roundId
```

TTL mặc định:

```text
86400 giây
```

Cơ chế:

```java
setIfAbsent(key, roundId, ttl)
```

Đây không phải mutex dài hạn, mà là **reservation idempotency**.

---

## 3.3 Rate Slot

Mục đích:

```text
Giới hạn spam event/metric/player trong thời gian ngắn.
```

Ví dụ source:

```text
src/main/java/com/platform/metrics/RealtimeMetricsCacheService.java
```

Key:

```text
s8:rate:player:{partnerCode}:{playerId}:{gameCode}
```

Cơ chế:

```java
setIfAbsent(key, "1", rateTtl)
```

Đây là rate gate, không phải money lock.

---

# 4. DB Pessimistic Lock: khóa chính để bảo vệ tiền

## Mục đích

Redis có thể hết TTL, mất kết nối, hoặc bị bypass. Vì vậy tiền thật cần khóa ở DB.

Pessimistic lock dùng khi:

```text
Nhiều request có thể cùng đọc/sửa một dòng tiền.
Cần serialize thao tác.
Không muốn 2 transaction cùng trừ một quỹ.
```

## Ví dụ trong dự án

### Lock money round

File:

```text
src/main/java/com/game/mahjong2/platformadapter/money/PlatformMoneyRoundRepository.java
```

Có:

```java
@Lock(LockModeType.PESSIMISTIC_WRITE)
Optional<PlatformMoneyRound> lockByRoundId(...)
```

Ý nghĩa:

```text
Cùng một round không thể settle/cancel/retry song song bừa bãi.
```

### Lock active round theo player/game

Cũng trong `PlatformMoneyRoundRepository` có:

```java
@Lock(LockModeType.PESSIMISTIC_WRITE)
lockActiveByPartnerPlayerGame(...)
```

Ý nghĩa:

```text
Một player không được có nhiều active money round cùng game.
```

### Lock prize fund bucket

File:

```text
src/main/java/com/game/mahjong2/jackpot/repository/PrizeFundBucketRepository.java
```

Có:

```java
@Lock(LockModeType.PESSIMISTIC_WRITE)
findByBucketCodeForUpdate(...)
```

Ý nghĩa:

```text
Cùng bucket quỹ không bị 2 request trừ/cộng song song gây âm quỹ hoặc sai balance.
```

### Lock jackpot pool

File:

```text
src/main/java/com/game/mahjong2/jackpot/repository/JackpotPoolRepository.java
```

Có:

```java
@Lock(LockModeType.PESSIMISTIC_WRITE)
findByPoolCode(...)
```

Ý nghĩa:

```text
Pool aggregate cũng được serialize khi tính budget/reserve.
```

### Lock free spin session

File:

```text
src/main/java/com/game/mahjong2/game/repository/Mw2FreeSpinSessionRepository.java
```

Có:

```java
@Lock(LockModeType.PESSIMISTIC_WRITE)
findWithLockByPartnerCodeAndUserIdAndGameCode(...)
```

Ý nghĩa:

```text
Tránh 2 request cùng tiêu hao/free spin session một lúc.
```

---

# 5. Optimistic Lock: chống ghi đè im lặng

## Mục đích

`@Version` giúp phát hiện trường hợp hai transaction cùng sửa một entity. Nếu version thay đổi, transaction sau sẽ fail thay vì ghi đè im lặng.

Dùng tốt cho:

```text
Pool
Bucket
Reservation
Config version
Entity ít sửa song song nhưng cần phát hiện conflict
```

## Ví dụ trong dự án

Theo source zip 49, các entity như `JackpotPool`, `PrizeFundBucket`, `JackpotReservation` có dùng `@Version`.

Ý nghĩa:

```text
Dù đã có pessimistic lock, @Version vẫn là lớp bảo vệ bổ sung khi save/update.
```

---

# 6. Unique Constraint: lớp bảo vệ cuối ở DB

## Mục đích

Code có thể bug, retry có thể race, Redis có thể fail. Unique constraint ở DB là chốt chặn cuối.

Các unique constraint nên có:

```text
round_id unique
transaction_id unique
clientRequestId unique theo partner/player/game
event_id unique trong outbox
bucket_code unique
reservation_id unique
```

## Ví dụ trong dự án

### Money round

```text
uq_money_rounds_round_id
uq_money_rounds_idempotency
```

### Money transaction

```text
uq_money_transactions_transaction_id
```

### Outbox event

File:

```text
src/main/java/com/game/mahjong2/platformadapter/outbox/PlatformOutboxEvent.java
```

Có:

```text
uq_outbox_event_id
```

Ý nghĩa:

```text
Cùng eventId không được ghi nhiều event trùng nhau.
```

---

# 7. State Machine: không cho tiền đi sai flow

## Mục đích

Với tiền, không được cho phép trạng thái nhảy lung tung.

Flow sai nguy hiểm:

```text
SETTLE trước BET_SUCCESS
CANCEL sau SETTLE_SUCCESS
JACKPOT trước SETTLE
COMPLETED khi wallet còn PENDING
```

## Flow chuẩn

```text
CREATED
  -> BET_PENDING
  -> BET_SUCCESS
  -> RESULT_GENERATED
  -> SETTLE_PENDING
  -> SETTLE_SUCCESS
  -> COMPLETED
```

Nếu lỗi:

```text
BET_PENDING -> FAILED_NEED_REVIEW
SETTLE_PENDING -> FAILED_NEED_REVIEW
```

## Ví dụ trong dự án

File:

```text
src/main/java/com/game/mahjong2/money/service/transaction/RoundTransactionStateService.java
```

Class này định nghĩa các transition hợp lệ. Nếu đi sai flow thì throw domain exception.

Ý nghĩa:

```text
Không chỉ khóa dữ liệu, mà còn khóa logic nghiệp vụ.
```

---

# 8. Reserve-before-settle: bảo vệ quỹ trước khi trả tiền

## Nguyên tắc

Với game có quỹ payout, không được settle wallet trước rồi mới kiểm tra quỹ.

Flow đúng:

```text
Generate result
  -> safety evaluate
  -> reserve fund
  -> wallet settle
  -> commit history
```

Flow sai:

```text
Generate result
  -> wallet settle
  -> sau đó mới trừ quỹ
```

Vì nếu settle trước rồi quỹ không đủ:

```text
Người chơi đã nhận tiền
nhưng hệ thống không reserve được fund
=> lệch tiền
```

## Ví dụ trong dự án

Flow được thiết kế quanh:

```text
PrizeSafetyService
FinalPayoutReservationService
JackpotEconomyService
Mw2EconomyLedger
```

Các safety action:

```text
ACCEPT_NATURAL
TIER_DOWNGRADE
DETERMINISTIC_AFFORDABLE_REROLL
NO_WIN_FALLBACK
```

Không phải mỗi action có lock riêng. Lock nằm ở tầng:

```text
lock pool
lock bucket
evaluate safety
reserve final payout
```

Ý nghĩa:

```text
Action chỉ là quyết định payout.
Quỹ được bảo vệ ở transaction + pool/bucket lock + reserve.
```

---

# 9. Prize Safety: không trả vượt khả năng chi

## Mục đích

Không để natural engine tạo payout vượt quá fund có thể chi.

Flow chuẩn:

```text
1. Tính budget có thể chi
2. Nếu natural win nằm trong budget: ACCEPT_NATURAL
3. Nếu vượt budget: TIER_DOWNGRADE
4. Nếu vẫn không ổn: DETERMINISTIC_AFFORDABLE_REROLL
5. Nếu vẫn không ổn: NO_WIN_FALLBACK
6. Reserve final payout đúng một lần
```

## Ví dụ trong dự án

File nhóm:

```text
src/main/java/com/game/mahjong2/jackpot/service/safety/PrizeSafetyAlgorithm.java
src/main/java/com/game/mahjong2/jackpot/service/safety/ReserveBudgetCalculator.java
src/main/java/com/game/mahjong2/jackpot/service/safety/FinalPayoutReservationService.java
```

Các guard quan trọng:

```text
budget floor
bucket floor
pool floor
max available ratio
max total bet multiplier
reserved == paid
```

---

# 10. Ledger: audit trail và chống sửa sai

## Mục đích

Ledger giúp trả lời:

```text
Tiền vào từ đâu?
Tiền ra vì round nào?
Reserve bao nhiêu?
Release bao nhiêu?
Payout đã commit chưa?
Có mismatch không?
```

## Ví dụ trong dự án

File:

```text
src/main/java/com/game/mahjong2/economy/domain/Mw2EconomyLedger.java
```

Ledger ghi các nhóm dữ liệu:

```text
bet_amount
win_amount
fee
pot_contribution
fund_contribution
fund_before
fund_after
bucket_before
bucket_after
fund_reserved
fund_released
status
blocked_reason
```

Ý nghĩa:

```text
Nếu có tranh chấp hoặc bug, có thể đối soát từng round.
```

Điểm cần gia cố đã phát hiện trong source zip 49:

```text
Mw2EconomyLedgerRepository chưa thấy @Lock(PESSIMISTIC_WRITE).
Mw2EconomyLedger chưa thấy @Version.
```

Khuyến nghị chung:

```text
Ledger tiền quan trọng nên có:
- unique round_id
- @Version hoặc lock row khi mutate
- status rõ ràng
- append-only nếu nghiệp vụ cho phép
- audit createdAt/updatedAt/operator/reason
```

---

# 11. Wallet protection: timeout, retry, need-review

## Mục đích

Wallet là external system. Không được assume thành công/thất bại bừa khi timeout.

Các trạng thái cần phân biệt:

```text
Success chắc chắn
Business failure chắc chắn
Transient failure
Timeout/unknown
Need manual review
```

## Flow chuẩn

```text
Call wallet debit/settle
Nếu success:
  mark success
Nếu lỗi chắc chắn không trừ/không cộng:
  mark failed/release reserve nếu cần
Nếu timeout/unknown:
  mark pending hoặc failed_need_review
  không tự ý reverse nếu không chắc
```

## Ví dụ trong dự án

File nhóm:

```text
src/main/java/com/game/mahjong2/money/service/transaction/MoneyTransactionService.java
src/main/java/com/game/mahjong2/money/service/transaction/PendingMoneyRecoveryWorker.java
src/main/java/com/game/mahjong2/money/service/wallet/SeamlessWalletHttpGateway.java
src/main/java/com/game/mahjong2/money/service/wallet/SeamlessWalletCircuitBreaker.java
```

Có các kỹ thuật:

```text
transactionId deterministic
lock money round
retry pending actions
mark FAILED_NEED_REVIEW khi không chắc
circuit breaker
connect/read timeout
release fund khi settle chắc chắn fail
```

---

# 12. SQL Outbox: không mất event khi Rabbit/Mongo lỗi

## Mục đích

SQL Outbox không phải để giảm tải SQL. Nó dùng để tránh mất event khi phải ghi SQL và gửi Rabbit.

Vấn đề cần giải quyết gọi là **dual write problem**:

```text
Ghi SQL thành công
Gửi Rabbit thất bại
=> Mongo/consumer không có event
```

## Flow chuẩn

```text
Business transaction:
  ghi dữ liệu chính vào SQL
  ghi event vào outbox_events cùng transaction
  commit

Outbox publisher job:
  đọc NEW/FAILED
  claim PUBLISHING
  publish Rabbit
  chờ publisher confirm
  confirm OK -> mark PUBLISHED
  lỗi -> mark FAILED
  quá retry -> DEAD_LETTER
```

## Ví dụ trong dự án

Các file:

```text
src/main/java/com/game/mahjong2/platformadapter/outbox/PlatformOutboxEvent.java
src/main/java/com/game/mahjong2/platformadapter/outbox/PlatformOutboxEventRepository.java
src/main/java/com/game/mahjong2/platformadapter/outbox/PlatformOutboxPublisherJob.java
src/main/java/com/game/mahjong2/platformadapter/outbox/PlatformRabbitOutboxPublisher.java
```

`PlatformOutboxEvent` có status:

```text
NEW
PUBLISHING
FAILED
PUBLISHED
DEAD_LETTER
```

`PlatformOutboxPublisherJob` chạy định kỳ:

```text
s8.outbox.publish-delay-ms, default 5000ms
```

Default max retry:

```text
5
```

Khi publish thành công, source mark:

```text
PUBLISHED
```

Không xóa ngay. Retention job dọn sau một thời gian.

---

# 13. RabbitMQ protection: confirm, persistent, durable, DLQ

## Mục đích

Rabbit là kênh vận chuyển. Để giảm mất message, cần:

```text
publisher confirm
persistent message
durable exchange
durable queue
DLQ
```

## Ví dụ trong dự án

File:

```text
src/main/java/com/game/mahjong2/platformadapter/outbox/PlatformRabbitOutboxPublisher.java
```

Có:

```java
waitForConfirmsOrDie(confirmTimeoutMs)
```

Message delivery mode:

```text
PERSISTENT nếu config bật
```

Topology:

```text
src/main/java/com/game/mahjong2/platformadapter/outbox/S8RabbitTopologyConfiguration.java
```

Có durable exchanges/queues:

```text
s8.game.results
s8.ops.logs
s8.error.logs
s8.game.results.mongo
s8.ops.logs.mongo
s8.error.logs.mongo
```

Có DLQ:

```text
s8.game.results.dlq
s8.ops.logs.dlq
s8.error.logs.dlq
```

---

# 14. Mongo consumer: at-least-once + idempotent upsert

## Nguyên tắc

Rabbit thường là **at-least-once delivery**:

```text
Message có thể được gửi lại.
Không được thiết kế consumer theo giả định chỉ nhận đúng một lần.
```

Vì vậy consumer phải idempotent.

## Flow chuẩn

```text
Consumer nhận message
validate payload
upsert Mongo bằng idempotent key
Mongo OK mới ACK Rabbit
Nếu lỗi retry được: retry/nack
Nếu lỗi không retry được: DLQ
```

## Ví dụ trong dự án

Consumer:

```text
src/main/java/com/platform/logpipeline/PlatformRabbitMongoConsumerListeners.java
```

Game result writer:

```text
src/main/java/com/game/mahjong2/platformadapter/result/MongoGameResultDocumentWriter.java
```

Mongo dùng:

```text
_id = roundId
upsert(...)
```

Ý nghĩa:

```text
Rabbit gửi lại cùng message 2 lần
=> Mongo vẫn chỉ có một document theo roundId.
```

Log writer cũng upsert theo `eventId`.

---

# 15. Hybrid Mongo write trong dự án này

Theo source zip 49, flow result store không phải “chỉ Outbox -> Rabbit -> Mongo”.

File:

```text
src/main/java/com/game/mahjong2/platformadapter/result/ElasticViaRabbitMahjongGameResultStore.java
```

Flow thực tế:

```text
save result
  -> tạo payload
  -> publish event vào SQL Outbox
  -> nếu mongoWriter != null thì upsert Mongo trực tiếp
  -> sau đó Rabbit consumer cũng có thể upsert lại
```

Ý nghĩa:

```text
Mongo có dữ liệu sớm hơn.
Rabbit/outbox vẫn là pipeline async/replay.
Duplicate không sao vì Mongo upsert theo roundId.
```

Điểm cần kiểm soát:

```text
Hai đường ghi Mongo phải cùng schema.
Nếu một đường thiếu field, document có thể lệch.
```

---

# 16. SQL Outbox có giảm tải SQL không?

Không.

SQL Outbox làm tăng an toàn, không giảm write SQL. Thậm chí nó thêm một dòng:

```text
business row + outbox row
```

Nó giúp:

```text
request chính không phải chờ Rabbit/Mongo
Rabbit lỗi vẫn không mất event
Mongo có thể xử lý async
```

Nếu dữ liệu lớn, không nên nhét toàn bộ payload khổng lồ vào outbox.

Khuyến nghị chung:

```text
SQL lưu dữ liệu tiền/trạng thái quan trọng.
Outbox lưu envelope nhỏ.
Payload lớn để Mongo/object storage/detail table.
Rabbit message có thể chỉ mang roundId/eventId/payloadRef.
```

Ví dụ envelope nhỏ:

```json
{
  "eventId": "evt_123",
  "eventType": "GameResultGenerated",
  "roundId": "MW2-000207",
  "payloadRef": "mongo/game_round_results/MW2-000207",
  "version": 1
}
```

---

# 17. Bảo vệ dữ liệu nhạy cảm

## Các kỹ thuật nên có

```text
Hash token trong DB
Mask sensitive logs
Không log password/token/signature
TTL cho cache token
Không bật fake wallet ở production
HTTPS/TLS
Secret management
```

## Ví dụ trong dự án

Hash session token:

```text
src/main/java/com/game/mahjong2/money/service/security/SessionTokenHashing.java
```

Mask log:

```text
src/main/java/com/platform/security/SensitiveDataMasker.java
```

Guard fake wallet:

```text
src/main/java/com/game/mahjong2/money/service/wallet/SeamlessWalletModeStartupGuard.java
```

Retry token cache:

```text
src/main/java/com/game/mahjong2/money/service/transaction/RetrySessionTokenCache.java
```

Lưu ý:

```text
DB không lưu raw token trong entity chính.
Nhưng Redis/runtime có thể giữ raw token để retry.
Cần TTL, ACL, network isolation cho Redis.
```

---

# 18. Monitoring và reconciliation

Một hệ thống tiền không chỉ cần lock, mà cần biết khi nào lệch.

Nên monitor:

```text
outbox_events status FAILED
outbox_events status DEAD_LETTER
outbox_events kẹt PUBLISHING quá lâu
Rabbit queue depth
Rabbit DLQ count
Mongo consumer error
wallet pending count
FAILED_NEED_REVIEW count
ledgerMismatchCount
fundAccountingMismatchCount
paidWinNotReservedAmount
reservedGreaterThanPaidCount
fundRuinCount
```

Trong simulator/report của dự án đã có các chỉ số kiểu:

```text
ledgerMismatchCount
fundAccountingMismatchCount
paidWinNotReservedAmount
paidWinReservedRatio
reservedGreaterThanPaidCount
fundRuinCount
```

Đây là hướng đúng: không chỉ xử lý, mà còn đối soát.

---

# 19. Checklist áp dụng cho mọi dự án

## Với request tiền

```text
Có clientRequestId chưa?
Có idempotency key chưa?
Có unique constraint chưa?
Có lock round chưa?
Có state machine chưa?
Có transaction boundary rõ chưa?
Có retry safe chưa?
Có manual review cho uncertain chưa?
```

## Với quỹ/payout

```text
Có lock bucket/pool chưa?
Có reserve-before-settle chưa?
Có invariant reserved == paid chưa?
Có ledger before/after chưa?
Có release khi settle chắc chắn fail chưa?
Có chặn settle nếu chưa reserve chưa?
```

## Với Rabbit/Mongo

```text
Có SQL Outbox chưa?
Outbox event_id unique chưa?
Có status NEW/PUBLISHING/FAILED/PUBLISHED/DEAD_LETTER chưa?
Có publisher confirm chưa?
Message persistent chưa?
Queue/exchange durable chưa?
Có DLQ chưa?
Consumer có idempotent upsert chưa?
ACK sau khi Mongo write OK chưa?
Có monitoring DLQ/FAILED chưa?
```

## Với Redis

```text
Redis lock có TTL chưa?
Có owner token chưa?
Release có compare owner không?
Có fallback DB lock không?
Có fencing token nếu cần không?
Redis có ACL/TLS/network isolation không?
```

## Với dữ liệu nhạy cảm

```text
Token có hash không?
Log có mask không?
Secret có nằm trong config plain text không?
Fake/mock có bị chặn ở prod không?
Cache token có TTL không?
```

---

# 20. Các điểm dự án này nên gia cố tiếp

Theo source zip 49, các điểm nên bổ sung:

```text
1. Thêm @Lock(PESSIMISTIC_WRITE) cho Mw2EconomyLedgerRepository.findByRoundIdForUpdate().
2. Thêm @Version cho Mw2EconomyLedger nếu ledger còn mutate nhiều lần.
3. Sửa JackpotPool find-or-create để catch duplicate create giống PrizeFundBucket.
4. Thêm RabbitTemplate mandatory=true + returns callback để bắt unroutable message.
5. Cấu hình rõ listener ACK/retry/DLQ cho Mongo consumer.
6. Thêm Inbox table hoặc processed_event collection cho consumer nếu cần audit exactly processed.
7. Đảm bảo direct Mongo write và Rabbit consumer write cùng schema.
8. Với dữ liệu lớn, đổi outbox payload lớn thành envelope nhỏ + payloadRef.
9. Nếu wallet yêu cầu bảo mật cao, thêm HMAC/signature request.
10. Verify source mới đã chuyển fund/ledger money fields sang DECIMAL nếu dùng hướng display money.
```

---

# 21. Kết luận ngắn

Tài liệu chuẩn có thể tóm thành một câu:

```text
Dữ liệu tiền phải được bảo vệ bằng nhiều lớp:
idempotency để chống retry,
unique constraint để chặn duplicate,
transaction + DB lock để chống race,
state machine để chống sai flow,
ledger để audit,
reserve-before-settle để không trả vượt quỹ,
outbox để không mất event,
Rabbit confirm/durable/DLQ để vận chuyển an toàn,
Mongo upsert để chịu duplicate,
monitoring/reconciliation để phát hiện lệch.
```

Ví dụ từ dự án này cho thấy kiến trúc đang đi theo hướng đúng:

```text
Redis khóa active spin ở tầng ngoài.
DB khóa money round / pool / bucket / free spin session ở tầng tiền thật.
PrizeSafety reserve payout trước khi settle.
SQL Outbox bảo vệ event trước Rabbit.
RabbitMQ dùng confirm + durable + persistent + DLQ.
Mongo dùng upsert theo roundId/eventId để idempotent.
```

Nhưng cần nhớ:

```text
Redis không thay DB lock.
Outbox không giảm write SQL.
Rabbit không đảm bảo exactly-once.
Mongo consumer phải idempotent.
Tiền thật cần ledger và reconciliation, không chỉ cần code chạy đúng một lần.
```

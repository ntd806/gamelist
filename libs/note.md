Rà soát xong. Tóm lại: **các vertical quan trọng đã rewrite và test được**, nhưng **chưa thể gọi là rewrite 100% toàn bộ legacy `Libs`**. Repo hiện sạch trên branch `anthony/rewrite-platform-domain-integration-apps`.

**Đã xong**
- Kiến trúc mới `platform + domain + integration + apps` trong [Libs/spring-boot3](</Users/anthonynguyen/Downloads/ProjectsS8/winall_svn/s8-backend/Libs/spring-boot3>).
- Core nền: `platform-common`, `platform-contracts`, `security-core`, `security-autoconfigure`, `game-cardlib`.
- Domain chính: user/profile/session, wallet/money transfer, ledger audit, payment merchant/exchange log, payout bank/USDT policy, loyalty/vippoint, game account/session/game data, notification brandname, reconciliation.
- Integration chính: JDBC adapters, Mongo legacy factory/operator routing, Hazelcast facade, RabbitMQ facade, bank/Napas/USDT payment gateway, bank/USDT payout gateway, brandname integration.
- Testbed: `MoneyCriticalCasesTest` có 66 tests, `LegacyRemainingRewriteTest` có 22 tests, tổng `money-testbed` 88 tests pass trong Docker.
- Các case tiền nguy hiểm đã cover: duplicate callback, concurrent withdraw, deadlock transfer chéo, high-volume same `requestId`, timeout payment/payout pending, double-entry ledger, reconciliation cuối ngày.
- Các provider đã loại khỏi scope được ghi rõ trong [REWRITE_IGNORE.md](</Users/anthonynguyen/Downloads/ProjectsS8/winall_svn/s8-backend/Libs/spring-boot3/REWRITE_IGNORE.md>): `1Pay, ABTPay, Epay, Gate247, Lucky79, Maxpay, Paygate, VTC, VTCPay, IAP, Momo, ClickGem`.

**Chưa xong**
- Chưa có test retry sau khi process crash/restart, đây là gap rõ nhất trong [MONEY_TEST_REPORT.md](</Users/anthonynguyen/Downloads/ProjectsS8/winall_svn/s8-backend/Libs/spring-boot3/MONEY_TEST_REPORT.md>).
- `requestLocks` vẫn là JVM-local; DB có unique `request_id`, nhưng nếu scale nhiều instance thì nên thêm distributed lock/idempotency guard trước DB.
- Chưa có production app/API hoàn chỉnh ngoài `money-testbed` và starter; hiện chủ yếu là library + regression harness.
- Một số legacy class trong `platform-common` vẫn là compatibility DTO/constant decompile, không phải rewrite nghiệp vụ sạch hoàn toàn.
- Một số adapter còn là “bridge/facade an toàn” thay vì gọi provider thật, ví dụ SOAP brandname/VMQ dùng handler cấu hình được để tránh Axis/Java 8 và tránh gửi thật ngoài ý muốn.
- Chưa phủ toàn bộ bề mặt legacy cũ như mọi DAO/report/game tournament persistence/API admin; hiện mới ưu tiên các flow quan trọng và đã có test.

**Kết luận**
Phần rewrite quan trọng cho money/user/payment-payout bank-USDT/loyalty/game/notification/reconciliation đã xong ở mức chạy test được. Phần nên làm tiếp hợp lý nhất là: **retry sau crash/restart**, sau đó **distributed idempotency lock**, rồi mới mở rộng production app/API và các DAO/report legacy còn thiếu.



Ngoại trừ các provider đã loại trừ (`1Pay, ABTPay, Epay, Gate247, Lucky79, Maxpay, Paygate, VTC, VTCPay, IAP, Momo, ClickGem`), phần rewrite **đã dùng được cho test/regression và làm nền tích hợp**, nhưng **chưa nên coi là production-ready 100%**.

Ước lượng hiện tại:

- **Core library / kiến trúc module:** khoảng **85-90% xong**.
- **Nghiệp vụ tiền quan trọng:** khoảng **80-85% xong** vì đã có idempotency, ledger, callback, timeout, reconciliation, bank/USDT payout/payment.
- **User/session/profile:** khoảng **75-80% xong**.
- **Integration JDBC/Mongo/Cache/RabbitMQ:** khoảng **70-80% xong**, đủ adapter nền nhưng cần wiring production thật.
- **Testbed/regression:** khoảng **85% xong**, còn thiếu crash/restart retry và distributed multi-instance lock.
- **Production app/API vận hành thật:** khoảng **45-55% xong**, vì hiện chủ yếu là library + testbed, chưa phải app backend hoàn chỉnh.

Nếu gom toàn dự án rewrite `Libs/spring-boot3` và bỏ qua các provider đã exclude, mình đánh giá **khoảng 75-80% hoàn tất**.

Có thể dùng được để:
- build Spring Boot 3/Java 21,
- chạy test nghiệp vụ tiền,
- tích hợp dần vào backend mới,
- làm nền thay legacy libs.

Chưa nên dùng ngay cho production nếu chưa làm tiếp:
- test retry sau crash/restart,
- distributed idempotency/lock khi scale nhiều instance,
- wiring production app/API thật,
- cấu hình thật cho DB/cache/RabbitMQ/provider,
- hardening monitoring/logging/migration data.
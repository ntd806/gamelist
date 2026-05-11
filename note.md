Game có source nhưng handler đang comment/chưa active nhĩa là **trong repo có code của game đó**, nhưng server hiện tại **không đăng ký route/handler để client gọi vào chơi**.

Cụ thể:

- Có file source, ví dụ `GaiNhayModule.java`, `DeCheLaMaModule.java`, `XoSoModule.java`.
- Nhưng trong file khởi tạo socket, dòng đăng ký handler đang bị comment bằng `//`.
- Khi bị comment thì server không bind command id cho module đó, nên client gửi packet tới command id đó sẽ không được xử lý như game active.

Ví dụ trong `SlotMachineExtension.java`:

```java
addRequestHandler((short) 2000, KhoBauModule.class);
addRequestHandler((short) 3000, NuDiepVienModule.class);
addRequestHandler((short) 4000, AvengerModule.class);
addRequestHandler((short) 5000, VQVModule.class);
// addRequestHandler((short) 6000, GaiNhayModule.class);
// addRequestHandler((short) 7000, DeCheLaMaModule.class);
```

Ở đây `KhoBau`, `NuDiepVien`, `Avenger`, `VQV` là active.  
Còn `GaiNhay`, `DeCheLaMa` có code nhưng chưa active vì handler bị comment.

Tương tự trong `BaseGameExtension.java` của `minigame`:

```java
addRequestHandler((short) 2000, TaiXiuModule.class);
addRequestHandler((short) 4000, MiniPokerModule.class);
addRequestHandler((short) 5000, BauCuaModule.class);
addRequestHandler((short) 6000, CaoThapModule.class);
addRequestHandler((short) 7000, PokeGoModule.class);
// addRequestHandler((short) 8000, XoSoModule.class);
```
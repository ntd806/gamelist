**Tổng quan**
| Nhóm | Số lượng |
|---|---:|
| Game active có source và đang được đăng ký handler/service | 23 |
| Game có source nhưng handler đang comment/chưa active | 3 |
| Tổng nếu tính cả chưa active | 26 |

**Thống kê Theo Thể Loại**
| Thể loại | Số lượng | Game |
|---|---:|---|
| Game bài | 10 | `BaCay`, `BaiCao`, `Binh`, `CoUp`, `Lieng`, `Poker`, `PokerTour`, `Sam`, `Tlmn`, `XiDzach` |
| Cờ | 2 | `Caro`, `CoTuong` |
| Xóc đĩa | 1 | `XocDia` |
| Bắn cá | 1 | `BanCa` |
| Minigame | 5 | `TaiXiu`, `MiniPoker`, `BauCua`, `CaoThap`, `PokeGo` |
| Slot | 4 | `KhoBau`, `NuDiepVien`, `SieuAnhHung`, `VuongQuocVin` |

**Danh Sách 23 Game Active**
| STT | Game | Thể loại | Source | TCP/Game | WebSocket | WSS | Admin |
|---:|---|---|---|---:|---:|---:|---:|
| 1 | `BaCay` | Game bài | `Socket/Bacay` | 21043 | 21044 | 21046 | 21045 |
| 2 | `BaiCao` | Game bài | `Socket/Baicao` | 21143 | 21144 | 21146 | 21145 |
| 3 | `BanCa` | Bắn cá | `Socket/BanCa` | 21243 | 21244 | 21246 | 21245 |
| 4 | `Binh` | Game bài | `Socket/Binh` | 21343 | 21344 | 21346 | 21345 |
| 5 | `Caro` | Cờ | `Socket/Caro` | 21443 | 21444 | 21446 | 21445 |
| 6 | `CoUp` | Game bài/Cờ Úp | `Socket/Coup` | 21543 | 21544 | 21546 | 21545 |
| 7 | `Lieng` | Game bài | `Socket/Lieng` | 21643 | 21644 | 21646 | 21645 |
| 8 | `Poker` | Game bài | `Socket/Poker` | 21743 | 21744 | 21746 | 21745 |
| 9 | `PokerTour` | Game bài | `Socket/PokerTour` | 21843 | 21844 | 21846 | 21845 |
| 10 | `Sam` | Game bài | `Socket/Sam` | 21943 | 21944 | 21946 | 21945 |
| 11 | `Tlmn` | Game bài | `Socket/Tienlen` | 22143 | 22144 | 22146 | 22145 |
| 12 | `XiDzach` | Game bài | `Socket/Xizach` | 22243 | 22244 | 22246 | 22245 |
| 13 | `XocDia` | Xóc đĩa | `Socket/xocdia` | 22443 | 22444 | 22446 | 22445 |
| 14 | `CoTuong` | Cờ | `Socket/Cotuong` | 22543 | 22544 | 22546 | 22545 |
| 15 | `TaiXiu` | Minigame | `Socket/minigame` | 22343 | 22344 | 22346 | 22345 |
| 16 | `MiniPoker` | Minigame | `Socket/minigame` | 22343 | 22344 | 22346 | 22345 |
| 17 | `BauCua` | Minigame | `Socket/minigame` | 22343 | 22344 | 22346 | 22345 |
| 18 | `CaoThap` | Minigame | `Socket/minigame` | 22343 | 22344 | 22346 | 22345 |
| 19 | `PokeGo` | Minigame | `Socket/minigame` | 22343 | 22344 | 22346 | 22345 |
| 20 | `KhoBau` | Slot | `Socket/SlotMachine` | 22043 | 22044 | 22046 | 22045 |
| 21 | `NuDiepVien` | Slot | `Socket/SlotMachine` | 22043 | 22044 | 22046 | 22045 |
| 22 | `SieuAnhHung` / `Avengers` | Slot | `Socket/SlotMachine` | 22043 | 22044 | 22046 | 22045 |
| 23 | `VuongQuocVin` | Slot | `Socket/SlotMachine` | 22043 | 22044 | 22046 | 22045 |

**Có Source Nhưng Chưa Active**
| Game | Source | Port nếu dùng chung service | Ghi chú |
|---|---|---|---|
| `GaiNhay` | `Socket/SlotMachine` | WS `22044` | Có `GaiNhayModule`, nhưng handler đang comment |
| `DeCheLaMa` | `Socket/SlotMachine` | WS `22044` | Có `DeCheLaMaModule`, nhưng handler đang comment |
| `XoSo` | `Socket/minigame` | WS `22344` | Có `XoSoModule`, nhưng handler đang comment |

Ghi chú: `Minigame` là một service socket chung, nên 5 game con dùng cùng port `22344`. `SlotMachine` cũng là một service chung, nên 4 slot active dùng cùng port `22044`.
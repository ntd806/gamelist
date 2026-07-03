| Bước                                            | Chú thích ngắn                                                                                               |
| ----------------------------------------------- | ------------------------------------------------------------------------------------------------------------ |
| **1. Free Spin Bonus Fund riêng**               | Tách riêng một quỹ chỉ dùng để trả thưởng cho Free Spin, không dùng chung với quỹ regular/base spin.         |
| **2. Reserve budget khi trigger Free Spin**     | Khi BASE spin kích hoạt Free Spin, hệ thống giữ trước một khoản ngân sách cho toàn bộ bonus session.         |
| **3. Budget-Constrained Bonus Pacing**          | Điều phối tiền thưởng trong cả session Free Spin theo ngân sách còn lại, tránh quá khô nhưng không vượt quỹ. |
| **4. Prize Tier Downgrade**                     | Nếu kết quả thắng quá lớn so với budget, hạ xuống một tier thưởng nhỏ hơn nhưng vẫn hợp lệ theo paytable.    |
| **5. Deterministic Affordable Reroll fallback** | Nếu không downgrade được, reroll bằng seed cố định để tìm kết quả thắng hợp lệ nằm trong budget.             |
| **6. No-win chỉ là fallback cuối**              | Chỉ chuyển về no-win khi không còn budget hoặc không tìm được kết quả hợp lệ sau các bước trên.              |


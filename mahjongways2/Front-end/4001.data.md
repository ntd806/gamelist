# Response `4001` — FE Animation Contract

## Các chỉnh sửa đã áp dụng

- `step` bắt đầu từ `1` cho response thật.
- Không trả `reels`, `reelsBefore`, `reelsAfterDrop`, `removedPositions`, `goldenTransforms` dạng math cho frontend.
- `animationColumns.before` và `animationColumns.after` dùng object đầy đủ: `row`, `cellId`, `symbol`, `golden`, `displayOnly`.
- Mỗi item trong `animationReels` có `golden`.
- `animationColumns` group theo từng cột.
- Item mới append vào cuối cột theo rule `REMOVE_THEN_KEEP_ORDER_THEN_APPEND_NEW`.
- Có sample `visualGoldenTransforms` khi golden thắng và transform thành `WILD`.

## Rule chính

```txt
1. Frontend chỉ dùng animationReels và cascadeSteps[].animation* để diễn.
2. Mỗi cột là một animation unit riêng trong animationColumns.
3. Remove xong thì giữ nguyên thứ tự mảng.
4. Item phía sau vị trí remove dồn lên để lấp chỗ trống.
5. Item mới append vào cuối cột.
6. animationColumns.after phải khớp animationReelsAfterDrop.
7. Nếu còn cascade step tiếp theo:
   cascadeSteps[n].animationReelsAfterDrop phải bằng cascadeSteps[n+1].animationReelsBeforeDrop.
8. Golden không phải do item drop gom thành.
9. Golden item thắng thì không remove, mà transform thành WILD qua visualGoldenTransforms.
```

## Response mẫu

```json
{
  "cmd": 4001,
  "spinId": "SPIN_001",
  "roundId": "RND_001",
  "roomId": 1,
  "animationMeta": {
    "displayLayout": [
      6,
      5,
      5,
      5,
      6
    ],
    "rowOrder": "ARRAY_ORDER",
    "dropRule": "REMOVE_THEN_KEEP_ORDER_THEN_APPEND_NEW",
    "description": "Trong mỗi cột, backend giữ nguyên thứ tự mảng. Khi remove item, các item phía sau vị trí bị remove dồn lên để lấp chỗ trống, item mới append vào cuối cột."
  },
  "animationReels": [
    [
      {
        "cellId": "s1-c0-r0",
        "symbol": "ITEM_5",
        "golden": false,
        "displayOnly": true
      },
      {
        "cellId": "s1-c0-r1",
        "symbol": "ITEM_5",
        "golden": false,
        "displayOnly": false
      },
      {
        "cellId": "s1-c0-r2",
        "symbol": "ITEM_2",
        "golden": false,
        "displayOnly": false
      },
      {
        "cellId": "s1-c0-r3",
        "symbol": "ITEM_5",
        "golden": false,
        "displayOnly": false
      },
      {
        "cellId": "s1-c0-r4",
        "symbol": "ITEM_7",
        "golden": false,
        "displayOnly": false
      },
      {
        "cellId": "s1-c0-r5",
        "symbol": "ITEM_7",
        "golden": false,
        "displayOnly": true
      }
    ],
    [
      {
        "cellId": "s1-c1-r0",
        "symbol": "ITEM_1",
        "golden": false,
        "displayOnly": false
      },
      {
        "cellId": "s1-c1-r1",
        "symbol": "ITEM_3",
        "golden": false,
        "displayOnly": false
      },
      {
        "cellId": "s1-c1-r2",
        "symbol": "ITEM_6",
        "golden": false,
        "displayOnly": false
      },
      {
        "cellId": "s1-c1-r3",
        "symbol": "ITEM_7",
        "golden": false,
        "displayOnly": false
      },
      {
        "cellId": "s1-c1-r4",
        "symbol": "ITEM_4",
        "golden": false,
        "displayOnly": false
      }
    ],
    [
      {
        "cellId": "s1-c2-r0",
        "symbol": "ITEM_2",
        "golden": false,
        "displayOnly": false
      },
      {
        "cellId": "s1-c2-r1",
        "symbol": "ITEM_7",
        "golden": false,
        "displayOnly": false
      },
      {
        "cellId": "s1-c2-r2",
        "symbol": "ITEM_5",
        "golden": true,
        "displayOnly": false
      },
      {
        "cellId": "s1-c2-r3",
        "symbol": "ITEM_2",
        "golden": false,
        "displayOnly": false
      },
      {
        "cellId": "s1-c2-r4",
        "symbol": "ITEM_4",
        "golden": false,
        "displayOnly": false
      }
    ],
    [
      {
        "cellId": "s1-c3-r0",
        "symbol": "ITEM_2",
        "golden": false,
        "displayOnly": false
      },
      {
        "cellId": "s1-c3-r1",
        "symbol": "ITEM_3",
        "golden": false,
        "displayOnly": false
      },
      {
        "cellId": "s1-c3-r2",
        "symbol": "ITEM_3",
        "golden": false,
        "displayOnly": false
      },
      {
        "cellId": "s1-c3-r3",
        "symbol": "ITEM_4",
        "golden": false,
        "displayOnly": false
      },
      {
        "cellId": "s1-c3-r4",
        "symbol": "ITEM_3",
        "golden": false,
        "displayOnly": false
      }
    ],
    [
      {
        "cellId": "s1-c4-r0",
        "symbol": "ITEM_2",
        "golden": false,
        "displayOnly": true
      },
      {
        "cellId": "s1-c4-r1",
        "symbol": "ITEM_2",
        "golden": false,
        "displayOnly": false
      },
      {
        "cellId": "s1-c4-r2",
        "symbol": "ITEM_3",
        "golden": false,
        "displayOnly": false
      },
      {
        "cellId": "s1-c4-r3",
        "symbol": "ITEM_3",
        "golden": false,
        "displayOnly": false
      },
      {
        "cellId": "s1-c4-r4",
        "symbol": "ITEM_3",
        "golden": false,
        "displayOnly": false
      },
      {
        "cellId": "s1-c4-r5",
        "symbol": "ITEM_3",
        "golden": false,
        "displayOnly": true
      }
    ]
  ],
  "cascadeSteps": [
    {
      "step": 1,
      "mode": "BASE",
      "multiplier": 3,
      "stepWin": 675,
      "animationReelsBeforeDrop": [
        [
          {
            "cellId": "s1-c0-r0",
            "symbol": "ITEM_5",
            "golden": false,
            "displayOnly": true
          },
          {
            "cellId": "s1-c0-r1",
            "symbol": "ITEM_5",
            "golden": false,
            "displayOnly": false
          },
          {
            "cellId": "s1-c0-r2",
            "symbol": "ITEM_2",
            "golden": false,
            "displayOnly": false
          },
          {
            "cellId": "s1-c0-r3",
            "symbol": "ITEM_5",
            "golden": false,
            "displayOnly": false
          },
          {
            "cellId": "s1-c0-r4",
            "symbol": "ITEM_7",
            "golden": false,
            "displayOnly": false
          },
          {
            "cellId": "s1-c0-r5",
            "symbol": "ITEM_7",
            "golden": false,
            "displayOnly": true
          }
        ],
        [
          {
            "cellId": "s1-c1-r0",
            "symbol": "ITEM_1",
            "golden": false,
            "displayOnly": false
          },
          {
            "cellId": "s1-c1-r1",
            "symbol": "ITEM_3",
            "golden": false,
            "displayOnly": false
          },
          {
            "cellId": "s1-c1-r2",
            "symbol": "ITEM_6",
            "golden": false,
            "displayOnly": false
          },
          {
            "cellId": "s1-c1-r3",
            "symbol": "ITEM_7",
            "golden": false,
            "displayOnly": false
          },
          {
            "cellId": "s1-c1-r4",
            "symbol": "ITEM_4",
            "golden": false,
            "displayOnly": false
          }
        ],
        [
          {
            "cellId": "s1-c2-r0",
            "symbol": "ITEM_2",
            "golden": false,
            "displayOnly": false
          },
          {
            "cellId": "s1-c2-r1",
            "symbol": "ITEM_7",
            "golden": false,
            "displayOnly": false
          },
          {
            "cellId": "s1-c2-r2",
            "symbol": "ITEM_5",
            "golden": true,
            "displayOnly": false
          },
          {
            "cellId": "s1-c2-r3",
            "symbol": "ITEM_2",
            "golden": false,
            "displayOnly": false
          },
          {
            "cellId": "s1-c2-r4",
            "symbol": "ITEM_4",
            "golden": false,
            "displayOnly": false
          }
        ],
        [
          {
            "cellId": "s1-c3-r0",
            "symbol": "ITEM_2",
            "golden": false,
            "displayOnly": false
          },
          {
            "cellId": "s1-c3-r1",
            "symbol": "ITEM_3",
            "golden": false,
            "displayOnly": false
          },
          {
            "cellId": "s1-c3-r2",
            "symbol": "ITEM_3",
            "golden": false,
            "displayOnly": false
          },
          {
            "cellId": "s1-c3-r3",
            "symbol": "ITEM_4",
            "golden": false,
            "displayOnly": false
          },
          {
            "cellId": "s1-c3-r4",
            "symbol": "ITEM_3",
            "golden": false,
            "displayOnly": false
          }
        ],
        [
          {
            "cellId": "s1-c4-r0",
            "symbol": "ITEM_2",
            "golden": false,
            "displayOnly": true
          },
          {
            "cellId": "s1-c4-r1",
            "symbol": "ITEM_2",
            "golden": false,
            "displayOnly": false
          },
          {
            "cellId": "s1-c4-r2",
            "symbol": "ITEM_3",
            "golden": false,
            "displayOnly": false
          },
          {
            "cellId": "s1-c4-r3",
            "symbol": "ITEM_3",
            "golden": false,
            "displayOnly": false
          },
          {
            "cellId": "s1-c4-r4",
            "symbol": "ITEM_3",
            "golden": false,
            "displayOnly": false
          },
          {
            "cellId": "s1-c4-r5",
            "symbol": "ITEM_3",
            "golden": false,
            "displayOnly": true
          }
        ]
      ],
      "visualWins": [
        {
          "symbol": "ITEM_7",
          "matchedReels": 3,
          "ways": 1,
          "winAmount": 675,
          "positions": [
            {
              "col": 0,
              "row": 4,
              "cellId": "s1-c0-r4"
            },
            {
              "col": 1,
              "row": 3,
              "cellId": "s1-c1-r3"
            },
            {
              "col": 2,
              "row": 1,
              "cellId": "s1-c2-r1"
            }
          ]
        }
      ],
      "animationColumns": [
        {
          "col": 0,
          "before": [
            {
              "row": 0,
              "cellId": "s1-c0-r0",
              "symbol": "ITEM_5",
              "golden": false,
              "displayOnly": true
            },
            {
              "row": 1,
              "cellId": "s1-c0-r1",
              "symbol": "ITEM_5",
              "golden": false,
              "displayOnly": false
            },
            {
              "row": 2,
              "cellId": "s1-c0-r2",
              "symbol": "ITEM_2",
              "golden": false,
              "displayOnly": false
            },
            {
              "row": 3,
              "cellId": "s1-c0-r3",
              "symbol": "ITEM_5",
              "golden": false,
              "displayOnly": false
            },
            {
              "row": 4,
              "cellId": "s1-c0-r4",
              "symbol": "ITEM_7",
              "golden": false,
              "displayOnly": false
            },
            {
              "row": 5,
              "cellId": "s1-c0-r5",
              "symbol": "ITEM_7",
              "golden": false,
              "displayOnly": true
            }
          ],
          "removed": [
            {
              "row": 4,
              "cellId": "s1-c0-r4",
              "symbol": "ITEM_7",
              "golden": false,
              "displayOnly": false
            }
          ],
          "moves": [
            {
              "cellId": "s1-c0-r5",
              "symbol": "ITEM_7",
              "golden": false,
              "fromRow": 5,
              "toRow": 4,
              "fromDisplayOnly": true,
              "toDisplayOnly": false
            }
          ],
          "newSymbols": [
            {
              "cellId": "s1-new-c0-r5",
              "symbol": "ITEM_1",
              "golden": false,
              "toRow": 5,
              "displayOnly": true,
              "enterFromRow": 6
            }
          ],
          "after": [
            {
              "row": 0,
              "cellId": "s1-c0-r0",
              "symbol": "ITEM_5",
              "golden": false,
              "displayOnly": true
            },
            {
              "row": 1,
              "cellId": "s1-c0-r1",
              "symbol": "ITEM_5",
              "golden": false,
              "displayOnly": false
            },
            {
              "row": 2,
              "cellId": "s1-c0-r2",
              "symbol": "ITEM_2",
              "golden": false,
              "displayOnly": false
            },
            {
              "row": 3,
              "cellId": "s1-c0-r3",
              "symbol": "ITEM_5",
              "golden": false,
              "displayOnly": false
            },
            {
              "row": 4,
              "cellId": "s1-c0-r5",
              "symbol": "ITEM_7",
              "golden": false,
              "displayOnly": false
            },
            {
              "row": 5,
              "cellId": "s1-new-c0-r5",
              "symbol": "ITEM_1",
              "golden": false,
              "displayOnly": true
            }
          ]
        },
        {
          "col": 1,
          "before": [
            {
              "row": 0,
              "cellId": "s1-c1-r0",
              "symbol": "ITEM_1",
              "golden": false,
              "displayOnly": false
            },
            {
              "row": 1,
              "cellId": "s1-c1-r1",
              "symbol": "ITEM_3",
              "golden": false,
              "displayOnly": false
            },
            {
              "row": 2,
              "cellId": "s1-c1-r2",
              "symbol": "ITEM_6",
              "golden": false,
              "displayOnly": false
            },
            {
              "row": 3,
              "cellId": "s1-c1-r3",
              "symbol": "ITEM_7",
              "golden": false,
              "displayOnly": false
            },
            {
              "row": 4,
              "cellId": "s1-c1-r4",
              "symbol": "ITEM_4",
              "golden": false,
              "displayOnly": false
            }
          ],
          "removed": [
            {
              "row": 3,
              "cellId": "s1-c1-r3",
              "symbol": "ITEM_7",
              "golden": false,
              "displayOnly": false
            }
          ],
          "moves": [
            {
              "cellId": "s1-c1-r4",
              "symbol": "ITEM_4",
              "golden": false,
              "fromRow": 4,
              "toRow": 3,
              "fromDisplayOnly": false,
              "toDisplayOnly": false
            }
          ],
          "newSymbols": [
            {
              "cellId": "s1-new-c1-r4",
              "symbol": "ITEM_5",
              "golden": false,
              "toRow": 4,
              "displayOnly": false,
              "enterFromRow": 5
            }
          ],
          "after": [
            {
              "row": 0,
              "cellId": "s1-c1-r0",
              "symbol": "ITEM_1",
              "golden": false,
              "displayOnly": false
            },
            {
              "row": 1,
              "cellId": "s1-c1-r1",
              "symbol": "ITEM_3",
              "golden": false,
              "displayOnly": false
            },
            {
              "row": 2,
              "cellId": "s1-c1-r2",
              "symbol": "ITEM_6",
              "golden": false,
              "displayOnly": false
            },
            {
              "row": 3,
              "cellId": "s1-c1-r4",
              "symbol": "ITEM_4",
              "golden": false,
              "displayOnly": false
            },
            {
              "row": 4,
              "cellId": "s1-new-c1-r4",
              "symbol": "ITEM_5",
              "golden": false,
              "displayOnly": false
            }
          ]
        },
        {
          "col": 2,
          "before": [
            {
              "row": 0,
              "cellId": "s1-c2-r0",
              "symbol": "ITEM_2",
              "golden": false,
              "displayOnly": false
            },
            {
              "row": 1,
              "cellId": "s1-c2-r1",
              "symbol": "ITEM_7",
              "golden": false,
              "displayOnly": false
            },
            {
              "row": 2,
              "cellId": "s1-c2-r2",
              "symbol": "ITEM_5",
              "golden": true,
              "displayOnly": false
            },
            {
              "row": 3,
              "cellId": "s1-c2-r3",
              "symbol": "ITEM_2",
              "golden": false,
              "displayOnly": false
            },
            {
              "row": 4,
              "cellId": "s1-c2-r4",
              "symbol": "ITEM_4",
              "golden": false,
              "displayOnly": false
            }
          ],
          "removed": [
            {
              "row": 1,
              "cellId": "s1-c2-r1",
              "symbol": "ITEM_7",
              "golden": false,
              "displayOnly": false
            }
          ],
          "moves": [
            {
              "cellId": "s1-c2-r2",
              "symbol": "ITEM_5",
              "golden": true,
              "fromRow": 2,
              "toRow": 1,
              "fromDisplayOnly": false,
              "toDisplayOnly": false
            },
            {
              "cellId": "s1-c2-r3",
              "symbol": "ITEM_2",
              "golden": false,
              "fromRow": 3,
              "toRow": 2,
              "fromDisplayOnly": false,
              "toDisplayOnly": false
            },
            {
              "cellId": "s1-c2-r4",
              "symbol": "ITEM_4",
              "golden": false,
              "fromRow": 4,
              "toRow": 3,
              "fromDisplayOnly": false,
              "toDisplayOnly": false
            }
          ],
          "newSymbols": [
            {
              "cellId": "s1-new-c2-r4",
              "symbol": "ITEM_1",
              "golden": false,
              "toRow": 4,
              "displayOnly": false,
              "enterFromRow": 5
            }
          ],
          "after": [
            {
              "row": 0,
              "cellId": "s1-c2-r0",
              "symbol": "ITEM_2",
              "golden": false,
              "displayOnly": false
            },
            {
              "row": 1,
              "cellId": "s1-c2-r2",
              "symbol": "ITEM_5",
              "golden": true,
              "displayOnly": false
            },
            {
              "row": 2,
              "cellId": "s1-c2-r3",
              "symbol": "ITEM_2",
              "golden": false,
              "displayOnly": false
            },
            {
              "row": 3,
              "cellId": "s1-c2-r4",
              "symbol": "ITEM_4",
              "golden": false,
              "displayOnly": false
            },
            {
              "row": 4,
              "cellId": "s1-new-c2-r4",
              "symbol": "ITEM_1",
              "golden": false,
              "displayOnly": false
            }
          ]
        },
        {
          "col": 3,
          "before": [
            {
              "row": 0,
              "cellId": "s1-c3-r0",
              "symbol": "ITEM_2",
              "golden": false,
              "displayOnly": false
            },
            {
              "row": 1,
              "cellId": "s1-c3-r1",
              "symbol": "ITEM_3",
              "golden": false,
              "displayOnly": false
            },
            {
              "row": 2,
              "cellId": "s1-c3-r2",
              "symbol": "ITEM_3",
              "golden": false,
              "displayOnly": false
            },
            {
              "row": 3,
              "cellId": "s1-c3-r3",
              "symbol": "ITEM_4",
              "golden": false,
              "displayOnly": false
            },
            {
              "row": 4,
              "cellId": "s1-c3-r4",
              "symbol": "ITEM_3",
              "golden": false,
              "displayOnly": false
            }
          ],
          "removed": [],
          "moves": [],
          "newSymbols": [],
          "after": [
            {
              "row": 0,
              "cellId": "s1-c3-r0",
              "symbol": "ITEM_2",
              "golden": false,
              "displayOnly": false
            },
            {
              "row": 1,
              "cellId": "s1-c3-r1",
              "symbol": "ITEM_3",
              "golden": false,
              "displayOnly": false
            },
            {
              "row": 2,
              "cellId": "s1-c3-r2",
              "symbol": "ITEM_3",
              "golden": false,
              "displayOnly": false
            },
            {
              "row": 3,
              "cellId": "s1-c3-r3",
              "symbol": "ITEM_4",
              "golden": false,
              "displayOnly": false
            },
            {
              "row": 4,
              "cellId": "s1-c3-r4",
              "symbol": "ITEM_3",
              "golden": false,
              "displayOnly": false
            }
          ]
        },
        {
          "col": 4,
          "before": [
            {
              "row": 0,
              "cellId": "s1-c4-r0",
              "symbol": "ITEM_2",
              "golden": false,
              "displayOnly": true
            },
            {
              "row": 1,
              "cellId": "s1-c4-r1",
              "symbol": "ITEM_2",
              "golden": false,
              "displayOnly": false
            },
            {
              "row": 2,
              "cellId": "s1-c4-r2",
              "symbol": "ITEM_3",
              "golden": false,
              "displayOnly": false
            },
            {
              "row": 3,
              "cellId": "s1-c4-r3",
              "symbol": "ITEM_3",
              "golden": false,
              "displayOnly": false
            },
            {
              "row": 4,
              "cellId": "s1-c4-r4",
              "symbol": "ITEM_3",
              "golden": false,
              "displayOnly": false
            },
            {
              "row": 5,
              "cellId": "s1-c4-r5",
              "symbol": "ITEM_3",
              "golden": false,
              "displayOnly": true
            }
          ],
          "removed": [],
          "moves": [],
          "newSymbols": [],
          "after": [
            {
              "row": 0,
              "cellId": "s1-c4-r0",
              "symbol": "ITEM_2",
              "golden": false,
              "displayOnly": true
            },
            {
              "row": 1,
              "cellId": "s1-c4-r1",
              "symbol": "ITEM_2",
              "golden": false,
              "displayOnly": false
            },
            {
              "row": 2,
              "cellId": "s1-c4-r2",
              "symbol": "ITEM_3",
              "golden": false,
              "displayOnly": false
            },
            {
              "row": 3,
              "cellId": "s1-c4-r3",
              "symbol": "ITEM_3",
              "golden": false,
              "displayOnly": false
            },
            {
              "row": 4,
              "cellId": "s1-c4-r4",
              "symbol": "ITEM_3",
              "golden": false,
              "displayOnly": false
            },
            {
              "row": 5,
              "cellId": "s1-c4-r5",
              "symbol": "ITEM_3",
              "golden": false,
              "displayOnly": true
            }
          ]
        }
      ],
      "visualGoldenTransforms": [],
      "animationReelsAfterDrop": [
        [
          {
            "cellId": "s1-c0-r0",
            "symbol": "ITEM_5",
            "golden": false,
            "displayOnly": true
          },
          {
            "cellId": "s1-c0-r1",
            "symbol": "ITEM_5",
            "golden": false,
            "displayOnly": false
          },
          {
            "cellId": "s1-c0-r2",
            "symbol": "ITEM_2",
            "golden": false,
            "displayOnly": false
          },
          {
            "cellId": "s1-c0-r3",
            "symbol": "ITEM_5",
            "golden": false,
            "displayOnly": false
          },
          {
            "cellId": "s1-c0-r5",
            "symbol": "ITEM_7",
            "golden": false,
            "displayOnly": false
          },
          {
            "cellId": "s1-new-c0-r5",
            "symbol": "ITEM_1",
            "golden": false,
            "displayOnly": true
          }
        ],
        [
          {
            "cellId": "s1-c1-r0",
            "symbol": "ITEM_1",
            "golden": false,
            "displayOnly": false
          },
          {
            "cellId": "s1-c1-r1",
            "symbol": "ITEM_3",
            "golden": false,
            "displayOnly": false
          },
          {
            "cellId": "s1-c1-r2",
            "symbol": "ITEM_6",
            "golden": false,
            "displayOnly": false
          },
          {
            "cellId": "s1-c1-r4",
            "symbol": "ITEM_4",
            "golden": false,
            "displayOnly": false
          },
          {
            "cellId": "s1-new-c1-r4",
            "symbol": "ITEM_5",
            "golden": false,
            "displayOnly": false
          }
        ],
        [
          {
            "cellId": "s1-c2-r0",
            "symbol": "ITEM_2",
            "golden": false,
            "displayOnly": false
          },
          {
            "cellId": "s1-c2-r2",
            "symbol": "ITEM_5",
            "golden": true,
            "displayOnly": false
          },
          {
            "cellId": "s1-c2-r3",
            "symbol": "ITEM_2",
            "golden": false,
            "displayOnly": false
          },
          {
            "cellId": "s1-c2-r4",
            "symbol": "ITEM_4",
            "golden": false,
            "displayOnly": false
          },
          {
            "cellId": "s1-new-c2-r4",
            "symbol": "ITEM_1",
            "golden": false,
            "displayOnly": false
          }
        ],
        [
          {
            "cellId": "s1-c3-r0",
            "symbol": "ITEM_2",
            "golden": false,
            "displayOnly": false
          },
          {
            "cellId": "s1-c3-r1",
            "symbol": "ITEM_3",
            "golden": false,
            "displayOnly": false
          },
          {
            "cellId": "s1-c3-r2",
            "symbol": "ITEM_3",
            "golden": false,
            "displayOnly": false
          },
          {
            "cellId": "s1-c3-r3",
            "symbol": "ITEM_4",
            "golden": false,
            "displayOnly": false
          },
          {
            "cellId": "s1-c3-r4",
            "symbol": "ITEM_3",
            "golden": false,
            "displayOnly": false
          }
        ],
        [
          {
            "cellId": "s1-c4-r0",
            "symbol": "ITEM_2",
            "golden": false,
            "displayOnly": true
          },
          {
            "cellId": "s1-c4-r1",
            "symbol": "ITEM_2",
            "golden": false,
            "displayOnly": false
          },
          {
            "cellId": "s1-c4-r2",
            "symbol": "ITEM_3",
            "golden": false,
            "displayOnly": false
          },
          {
            "cellId": "s1-c4-r3",
            "symbol": "ITEM_3",
            "golden": false,
            "displayOnly": false
          },
          {
            "cellId": "s1-c4-r4",
            "symbol": "ITEM_3",
            "golden": false,
            "displayOnly": false
          },
          {
            "cellId": "s1-c4-r5",
            "symbol": "ITEM_3",
            "golden": false,
            "displayOnly": true
          }
        ]
      ]
    },
    {
      "step": 2,
      "mode": "BASE",
      "multiplier": 5,
      "stepWin": 2250,
      "animationReelsBeforeDrop": [
        [
          {
            "cellId": "s1-c0-r0",
            "symbol": "ITEM_5",
            "golden": false,
            "displayOnly": true
          },
          {
            "cellId": "s1-c0-r1",
            "symbol": "ITEM_5",
            "golden": false,
            "displayOnly": false
          },
          {
            "cellId": "s1-c0-r2",
            "symbol": "ITEM_2",
            "golden": false,
            "displayOnly": false
          },
          {
            "cellId": "s1-c0-r3",
            "symbol": "ITEM_5",
            "golden": false,
            "displayOnly": false
          },
          {
            "cellId": "s1-c0-r5",
            "symbol": "ITEM_7",
            "golden": false,
            "displayOnly": false
          },
          {
            "cellId": "s1-new-c0-r5",
            "symbol": "ITEM_1",
            "golden": false,
            "displayOnly": true
          }
        ],
        [
          {
            "cellId": "s1-c1-r0",
            "symbol": "ITEM_1",
            "golden": false,
            "displayOnly": false
          },
          {
            "cellId": "s1-c1-r1",
            "symbol": "ITEM_3",
            "golden": false,
            "displayOnly": false
          },
          {
            "cellId": "s1-c1-r2",
            "symbol": "ITEM_6",
            "golden": false,
            "displayOnly": false
          },
          {
            "cellId": "s1-c1-r4",
            "symbol": "ITEM_4",
            "golden": false,
            "displayOnly": false
          },
          {
            "cellId": "s1-new-c1-r4",
            "symbol": "ITEM_5",
            "golden": false,
            "displayOnly": false
          }
        ],
        [
          {
            "cellId": "s1-c2-r0",
            "symbol": "ITEM_2",
            "golden": false,
            "displayOnly": false
          },
          {
            "cellId": "s1-c2-r2",
            "symbol": "ITEM_5",
            "golden": true,
            "displayOnly": false
          },
          {
            "cellId": "s1-c2-r3",
            "symbol": "ITEM_2",
            "golden": false,
            "displayOnly": false
          },
          {
            "cellId": "s1-c2-r4",
            "symbol": "ITEM_4",
            "golden": false,
            "displayOnly": false
          },
          {
            "cellId": "s1-new-c2-r4",
            "symbol": "ITEM_1",
            "golden": false,
            "displayOnly": false
          }
        ],
        [
          {
            "cellId": "s1-c3-r0",
            "symbol": "ITEM_2",
            "golden": false,
            "displayOnly": false
          },
          {
            "cellId": "s1-c3-r1",
            "symbol": "ITEM_3",
            "golden": false,
            "displayOnly": false
          },
          {
            "cellId": "s1-c3-r2",
            "symbol": "ITEM_3",
            "golden": false,
            "displayOnly": false
          },
          {
            "cellId": "s1-c3-r3",
            "symbol": "ITEM_4",
            "golden": false,
            "displayOnly": false
          },
          {
            "cellId": "s1-c3-r4",
            "symbol": "ITEM_3",
            "golden": false,
            "displayOnly": false
          }
        ],
        [
          {
            "cellId": "s1-c4-r0",
            "symbol": "ITEM_2",
            "golden": false,
            "displayOnly": true
          },
          {
            "cellId": "s1-c4-r1",
            "symbol": "ITEM_2",
            "golden": false,
            "displayOnly": false
          },
          {
            "cellId": "s1-c4-r2",
            "symbol": "ITEM_3",
            "golden": false,
            "displayOnly": false
          },
          {
            "cellId": "s1-c4-r3",
            "symbol": "ITEM_3",
            "golden": false,
            "displayOnly": false
          },
          {
            "cellId": "s1-c4-r4",
            "symbol": "ITEM_3",
            "golden": false,
            "displayOnly": false
          },
          {
            "cellId": "s1-c4-r5",
            "symbol": "ITEM_3",
            "golden": false,
            "displayOnly": true
          }
        ]
      ],
      "visualWins": [
        {
          "symbol": "ITEM_5",
          "matchedReels": 3,
          "ways": 1,
          "winAmount": 2250,
          "positions": [
            {
              "col": 0,
              "row": 1,
              "cellId": "s1-c0-r1"
            },
            {
              "col": 1,
              "row": 4,
              "cellId": "s1-new-c1-r4"
            },
            {
              "col": 2,
              "row": 1,
              "cellId": "s1-c2-r2"
            }
          ]
        }
      ],
      "animationColumns": [
        {
          "col": 0,
          "before": [
            {
              "row": 0,
              "cellId": "s1-c0-r0",
              "symbol": "ITEM_5",
              "golden": false,
              "displayOnly": true
            },
            {
              "row": 1,
              "cellId": "s1-c0-r1",
              "symbol": "ITEM_5",
              "golden": false,
              "displayOnly": false
            },
            {
              "row": 2,
              "cellId": "s1-c0-r2",
              "symbol": "ITEM_2",
              "golden": false,
              "displayOnly": false
            },
            {
              "row": 3,
              "cellId": "s1-c0-r3",
              "symbol": "ITEM_5",
              "golden": false,
              "displayOnly": false
            },
            {
              "row": 4,
              "cellId": "s1-c0-r5",
              "symbol": "ITEM_7",
              "golden": false,
              "displayOnly": false
            },
            {
              "row": 5,
              "cellId": "s1-new-c0-r5",
              "symbol": "ITEM_1",
              "golden": false,
              "displayOnly": true
            }
          ],
          "removed": [
            {
              "row": 1,
              "cellId": "s1-c0-r1",
              "symbol": "ITEM_5",
              "golden": false,
              "displayOnly": false
            }
          ],
          "moves": [
            {
              "cellId": "s1-c0-r2",
              "symbol": "ITEM_2",
              "golden": false,
              "fromRow": 2,
              "toRow": 1,
              "fromDisplayOnly": false,
              "toDisplayOnly": false
            },
            {
              "cellId": "s1-c0-r3",
              "symbol": "ITEM_5",
              "golden": false,
              "fromRow": 3,
              "toRow": 2,
              "fromDisplayOnly": false,
              "toDisplayOnly": false
            },
            {
              "cellId": "s1-c0-r5",
              "symbol": "ITEM_7",
              "golden": false,
              "fromRow": 4,
              "toRow": 3,
              "fromDisplayOnly": false,
              "toDisplayOnly": false
            },
            {
              "cellId": "s1-new-c0-r5",
              "symbol": "ITEM_1",
              "golden": false,
              "fromRow": 5,
              "toRow": 4,
              "fromDisplayOnly": true,
              "toDisplayOnly": false
            }
          ],
          "newSymbols": [
            {
              "cellId": "s2-new-c0-r5",
              "symbol": "ITEM_6",
              "golden": false,
              "toRow": 5,
              "displayOnly": true,
              "enterFromRow": 6
            }
          ],
          "after": [
            {
              "row": 0,
              "cellId": "s1-c0-r0",
              "symbol": "ITEM_5",
              "golden": false,
              "displayOnly": true
            },
            {
              "row": 1,
              "cellId": "s1-c0-r2",
              "symbol": "ITEM_2",
              "golden": false,
              "displayOnly": false
            },
            {
              "row": 2,
              "cellId": "s1-c0-r3",
              "symbol": "ITEM_5",
              "golden": false,
              "displayOnly": false
            },
            {
              "row": 3,
              "cellId": "s1-c0-r5",
              "symbol": "ITEM_7",
              "golden": false,
              "displayOnly": false
            },
            {
              "row": 4,
              "cellId": "s1-new-c0-r5",
              "symbol": "ITEM_1",
              "golden": false,
              "displayOnly": false
            },
            {
              "row": 5,
              "cellId": "s2-new-c0-r5",
              "symbol": "ITEM_6",
              "golden": false,
              "displayOnly": true
            }
          ]
        },
        {
          "col": 1,
          "before": [
            {
              "row": 0,
              "cellId": "s1-c1-r0",
              "symbol": "ITEM_1",
              "golden": false,
              "displayOnly": false
            },
            {
              "row": 1,
              "cellId": "s1-c1-r1",
              "symbol": "ITEM_3",
              "golden": false,
              "displayOnly": false
            },
            {
              "row": 2,
              "cellId": "s1-c1-r2",
              "symbol": "ITEM_6",
              "golden": false,
              "displayOnly": false
            },
            {
              "row": 3,
              "cellId": "s1-c1-r4",
              "symbol": "ITEM_4",
              "golden": false,
              "displayOnly": false
            },
            {
              "row": 4,
              "cellId": "s1-new-c1-r4",
              "symbol": "ITEM_5",
              "golden": false,
              "displayOnly": false
            }
          ],
          "removed": [
            {
              "row": 4,
              "cellId": "s1-new-c1-r4",
              "symbol": "ITEM_5",
              "golden": false,
              "displayOnly": false
            }
          ],
          "moves": [],
          "newSymbols": [
            {
              "cellId": "s2-new-c1-r4",
              "symbol": "ITEM_2",
              "golden": false,
              "toRow": 4,
              "displayOnly": false,
              "enterFromRow": 5
            }
          ],
          "after": [
            {
              "row": 0,
              "cellId": "s1-c1-r0",
              "symbol": "ITEM_1",
              "golden": false,
              "displayOnly": false
            },
            {
              "row": 1,
              "cellId": "s1-c1-r1",
              "symbol": "ITEM_3",
              "golden": false,
              "displayOnly": false
            },
            {
              "row": 2,
              "cellId": "s1-c1-r2",
              "symbol": "ITEM_6",
              "golden": false,
              "displayOnly": false
            },
            {
              "row": 3,
              "cellId": "s1-c1-r4",
              "symbol": "ITEM_4",
              "golden": false,
              "displayOnly": false
            },
            {
              "row": 4,
              "cellId": "s2-new-c1-r4",
              "symbol": "ITEM_2",
              "golden": false,
              "displayOnly": false
            }
          ]
        },
        {
          "col": 2,
          "before": [
            {
              "row": 0,
              "cellId": "s1-c2-r0",
              "symbol": "ITEM_2",
              "golden": false,
              "displayOnly": false
            },
            {
              "row": 1,
              "cellId": "s1-c2-r2",
              "symbol": "ITEM_5",
              "golden": true,
              "displayOnly": false
            },
            {
              "row": 2,
              "cellId": "s1-c2-r3",
              "symbol": "ITEM_2",
              "golden": false,
              "displayOnly": false
            },
            {
              "row": 3,
              "cellId": "s1-c2-r4",
              "symbol": "ITEM_4",
              "golden": false,
              "displayOnly": false
            },
            {
              "row": 4,
              "cellId": "s1-new-c2-r4",
              "symbol": "ITEM_1",
              "golden": false,
              "displayOnly": false
            }
          ],
          "removed": [],
          "moves": [],
          "newSymbols": [],
          "after": [
            {
              "row": 0,
              "cellId": "s1-c2-r0",
              "symbol": "ITEM_2",
              "golden": false,
              "displayOnly": false
            },
            {
              "row": 1,
              "cellId": "s1-c2-r2",
              "symbol": "WILD",
              "golden": false,
              "displayOnly": false
            },
            {
              "row": 2,
              "cellId": "s1-c2-r3",
              "symbol": "ITEM_2",
              "golden": false,
              "displayOnly": false
            },
            {
              "row": 3,
              "cellId": "s1-c2-r4",
              "symbol": "ITEM_4",
              "golden": false,
              "displayOnly": false
            },
            {
              "row": 4,
              "cellId": "s1-new-c2-r4",
              "symbol": "ITEM_1",
              "golden": false,
              "displayOnly": false
            }
          ]
        },
        {
          "col": 3,
          "before": [
            {
              "row": 0,
              "cellId": "s1-c3-r0",
              "symbol": "ITEM_2",
              "golden": false,
              "displayOnly": false
            },
            {
              "row": 1,
              "cellId": "s1-c3-r1",
              "symbol": "ITEM_3",
              "golden": false,
              "displayOnly": false
            },
            {
              "row": 2,
              "cellId": "s1-c3-r2",
              "symbol": "ITEM_3",
              "golden": false,
              "displayOnly": false
            },
            {
              "row": 3,
              "cellId": "s1-c3-r3",
              "symbol": "ITEM_4",
              "golden": false,
              "displayOnly": false
            },
            {
              "row": 4,
              "cellId": "s1-c3-r4",
              "symbol": "ITEM_3",
              "golden": false,
              "displayOnly": false
            }
          ],
          "removed": [],
          "moves": [],
          "newSymbols": [],
          "after": [
            {
              "row": 0,
              "cellId": "s1-c3-r0",
              "symbol": "ITEM_2",
              "golden": false,
              "displayOnly": false
            },
            {
              "row": 1,
              "cellId": "s1-c3-r1",
              "symbol": "ITEM_3",
              "golden": false,
              "displayOnly": false
            },
            {
              "row": 2,
              "cellId": "s1-c3-r2",
              "symbol": "ITEM_3",
              "golden": false,
              "displayOnly": false
            },
            {
              "row": 3,
              "cellId": "s1-c3-r3",
              "symbol": "ITEM_4",
              "golden": false,
              "displayOnly": false
            },
            {
              "row": 4,
              "cellId": "s1-c3-r4",
              "symbol": "ITEM_3",
              "golden": false,
              "displayOnly": false
            }
          ]
        },
        {
          "col": 4,
          "before": [
            {
              "row": 0,
              "cellId": "s1-c4-r0",
              "symbol": "ITEM_2",
              "golden": false,
              "displayOnly": true
            },
            {
              "row": 1,
              "cellId": "s1-c4-r1",
              "symbol": "ITEM_2",
              "golden": false,
              "displayOnly": false
            },
            {
              "row": 2,
              "cellId": "s1-c4-r2",
              "symbol": "ITEM_3",
              "golden": false,
              "displayOnly": false
            },
            {
              "row": 3,
              "cellId": "s1-c4-r3",
              "symbol": "ITEM_3",
              "golden": false,
              "displayOnly": false
            },
            {
              "row": 4,
              "cellId": "s1-c4-r4",
              "symbol": "ITEM_3",
              "golden": false,
              "displayOnly": false
            },
            {
              "row": 5,
              "cellId": "s1-c4-r5",
              "symbol": "ITEM_3",
              "golden": false,
              "displayOnly": true
            }
          ],
          "removed": [],
          "moves": [],
          "newSymbols": [],
          "after": [
            {
              "row": 0,
              "cellId": "s1-c4-r0",
              "symbol": "ITEM_2",
              "golden": false,
              "displayOnly": true
            },
            {
              "row": 1,
              "cellId": "s1-c4-r1",
              "symbol": "ITEM_2",
              "golden": false,
              "displayOnly": false
            },
            {
              "row": 2,
              "cellId": "s1-c4-r2",
              "symbol": "ITEM_3",
              "golden": false,
              "displayOnly": false
            },
            {
              "row": 3,
              "cellId": "s1-c4-r3",
              "symbol": "ITEM_3",
              "golden": false,
              "displayOnly": false
            },
            {
              "row": 4,
              "cellId": "s1-c4-r4",
              "symbol": "ITEM_3",
              "golden": false,
              "displayOnly": false
            },
            {
              "row": 5,
              "cellId": "s1-c4-r5",
              "symbol": "ITEM_3",
              "golden": false,
              "displayOnly": true
            }
          ]
        }
      ],
      "visualGoldenTransforms": [
        {
          "cellId": "s1-c2-r2",
          "fromSymbol": "ITEM_5",
          "toSymbol": "WILD",
          "fromGolden": true,
          "toGolden": false,
          "from": {
            "col": 2,
            "row": 1
          },
          "to": {
            "col": 2,
            "row": 1
          }
        }
      ],
      "animationReelsAfterDrop": [
        [
          {
            "cellId": "s1-c0-r0",
            "symbol": "ITEM_5",
            "golden": false,
            "displayOnly": true
          },
          {
            "cellId": "s1-c0-r2",
            "symbol": "ITEM_2",
            "golden": false,
            "displayOnly": false
          },
          {
            "cellId": "s1-c0-r3",
            "symbol": "ITEM_5",
            "golden": false,
            "displayOnly": false
          },
          {
            "cellId": "s1-c0-r5",
            "symbol": "ITEM_7",
            "golden": false,
            "displayOnly": false
          },
          {
            "cellId": "s1-new-c0-r5",
            "symbol": "ITEM_1",
            "golden": false,
            "displayOnly": false
          },
          {
            "cellId": "s2-new-c0-r5",
            "symbol": "ITEM_6",
            "golden": false,
            "displayOnly": true
          }
        ],
        [
          {
            "cellId": "s1-c1-r0",
            "symbol": "ITEM_1",
            "golden": false,
            "displayOnly": false
          },
          {
            "cellId": "s1-c1-r1",
            "symbol": "ITEM_3",
            "golden": false,
            "displayOnly": false
          },
          {
            "cellId": "s1-c1-r2",
            "symbol": "ITEM_6",
            "golden": false,
            "displayOnly": false
          },
          {
            "cellId": "s1-c1-r4",
            "symbol": "ITEM_4",
            "golden": false,
            "displayOnly": false
          },
          {
            "cellId": "s2-new-c1-r4",
            "symbol": "ITEM_2",
            "golden": false,
            "displayOnly": false
          }
        ],
        [
          {
            "cellId": "s1-c2-r0",
            "symbol": "ITEM_2",
            "golden": false,
            "displayOnly": false
          },
          {
            "cellId": "s1-c2-r2",
            "symbol": "WILD",
            "golden": false,
            "displayOnly": false
          },
          {
            "cellId": "s1-c2-r3",
            "symbol": "ITEM_2",
            "golden": false,
            "displayOnly": false
          },
          {
            "cellId": "s1-c2-r4",
            "symbol": "ITEM_4",
            "golden": false,
            "displayOnly": false
          },
          {
            "cellId": "s1-new-c2-r4",
            "symbol": "ITEM_1",
            "golden": false,
            "displayOnly": false
          }
        ],
        [
          {
            "cellId": "s1-c3-r0",
            "symbol": "ITEM_2",
            "golden": false,
            "displayOnly": false
          },
          {
            "cellId": "s1-c3-r1",
            "symbol": "ITEM_3",
            "golden": false,
            "displayOnly": false
          },
          {
            "cellId": "s1-c3-r2",
            "symbol": "ITEM_3",
            "golden": false,
            "displayOnly": false
          },
          {
            "cellId": "s1-c3-r3",
            "symbol": "ITEM_4",
            "golden": false,
            "displayOnly": false
          },
          {
            "cellId": "s1-c3-r4",
            "symbol": "ITEM_3",
            "golden": false,
            "displayOnly": false
          }
        ],
        [
          {
            "cellId": "s1-c4-r0",
            "symbol": "ITEM_2",
            "golden": false,
            "displayOnly": true
          },
          {
            "cellId": "s1-c4-r1",
            "symbol": "ITEM_2",
            "golden": false,
            "displayOnly": false
          },
          {
            "cellId": "s1-c4-r2",
            "symbol": "ITEM_3",
            "golden": false,
            "displayOnly": false
          },
          {
            "cellId": "s1-c4-r3",
            "symbol": "ITEM_3",
            "golden": false,
            "displayOnly": false
          },
          {
            "cellId": "s1-c4-r4",
            "symbol": "ITEM_3",
            "golden": false,
            "displayOnly": false
          },
          {
            "cellId": "s1-c4-r5",
            "symbol": "ITEM_3",
            "golden": false,
            "displayOnly": true
          }
        ]
      ]
    }
  ],
  "totalWin": 2925,
  "balance": 1002475,
  "bet": {
    "roomId": 1,
    "betOptionId": "R1_BS_250_BL_9",
    "totalBet": 450
  },
  "seamless": {
    "enabled": true,
    "payoutStatus": "SUCCESS"
  },
  "freeSpin": {
    "triggered": false,
    "awarded": 0,
    "remaining": 0,
    "scatterCount": 0
  },
  "jackpot": {
    "enabled": false,
    "triggered": false,
    "amount": 0
  },
  "state": {
    "mode": "BASE",
    "bigWin": false,
    "turbo": false,
    "autoPlay": false
  },
  "clientRequestId": "sample-001"
}
```

## Field frontend dùng

```txt
animationReels
cascadeSteps[].animationReelsBeforeDrop
cascadeSteps[].visualWins
cascadeSteps[].animationColumns
cascadeSteps[].visualGoldenTransforms
cascadeSteps[].animationReelsAfterDrop
```

## Field không trả cho frontend

```txt
reels
reelsBefore
reelsAfterDrop
removedPositions
goldenTransforms
wins.positions theo math coordinate
```

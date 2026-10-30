# SoC Block Diagram

```mermaid
graph TB
    subgraph SoC["soc_mini"]
        CPU["PicoRV32 Core"]
        BUS["Memory Bus<br/>mem_valid, mem_instr, mem_ready<br/>mem_addr, mem_wdata, mem_wstrb, mem_rdata"]
        RAM["4 KB RAM<br/>0x0000_0000<br/>1024 × 32-bit"]
        
        subgraph Accel["accel_mmio @ 0x8000_0000"]
            MMIO["Register Map<br/>0x000: start<br/>0x004: status<br/>0x100–0x13C: A[0:15]<br/>0x200–0x23C: B[0:15]<br/>0x300–0x33C: C[0:15]"]
            
            subgraph Array["systolic_os_4x4"]
                PEs["4×4 PE Grid<br/>Output-Stationary"]
            end
            
            FSM["FSM<br/>feed_cnt, busy, done"]
        end
    end
    
    CPU -->|mem bus| BUS
    BUS -->|addr[31]| Accel
    BUS -->|addr[31]=0| RAM
    MMIO -->|a_vec, b_vec| FSM
    FSM -->|feed_cnt| PEs
```

## Register Map

| Address | Name | Bits | Description |
|---------|------|------|-------------|
| 0x000 | START | [0] | Write 1 to start |
| 0x004 | STATUS | [1:0] | done, busy |
| 0x100+4k | A[k] | [7:0] | A element k (k=0..15) |
| 0x200+4k | B[k] | [7:0] | B element k |
| 0x300+4k | C[k] | [31:0] | C result k |


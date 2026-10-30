#include <stdint.h>

#define ACC_BASE  0x80000000u
#define ACC_CTRL  (*(volatile uint32_t *)(ACC_BASE + 0x000))
#define ACC_STAT  (*(volatile uint32_t *)(ACC_BASE + 0x004))
#define ACC_A(k)  (*(volatile uint32_t *)(ACC_BASE + 0x100 + 4*(k)))
#define ACC_B(k)  (*(volatile uint32_t *)(ACC_BASE + 0x200 + 4*(k)))
#define ACC_C(k)  (*(volatile uint32_t *)(ACC_BASE + 0x300 + 4*(k)))

#define RAM_A(k)  (*(volatile int32_t *)(0x200 + 4*(k)))
#define RAM_B(k)  (*(volatile int32_t *)(0x240 + 4*(k)))
#define RAM_C(k)  (*(volatile int32_t *)(0x400 + 4*(k)))

int main(void) {
    /* Pipelined: interleave A and B loads to hide memory latency */
    for (int k = 0; k < 16; k++) {
        ACC_A(k) = RAM_A(k);
        ACC_B(k) = RAM_B(k);
    }
    
    ACC_CTRL = 1;                          /* start */
    while ((ACC_STAT & 1u) == 0) { }       /* poll done */
    
    for (int k = 0; k < 16; k++) RAM_C(k) = ACC_C(k);
    return 0;
}

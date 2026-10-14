#include <stdint.h>

/* Software 4x4 INT8 matmul using the hardware multiply instruction (rv32im). */
#define RAM_A(k)  (*(volatile int32_t *)(0x200 + 4*(k)))
#define RAM_B(k)  (*(volatile int32_t *)(0x240 + 4*(k)))
#define RAM_C(k)  (*(volatile int32_t *)(0x400 + 4*(k)))

int main(void) {
    for (int i = 0; i < 4; i++)
        for (int j = 0; j < 4; j++) {
            int32_t s = 0;
            for (int k = 0; k < 4; k++)
                s += RAM_A(i*4 + k) * RAM_B(k*4 + j);
            RAM_C(i*4 + j) = s;
        }
    return 0;
}

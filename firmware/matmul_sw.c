#include <stdint.h>

/* Software-only 4x4 INT8 matmul. No multiply instruction: shift-and-add. */
#define RAM_A(k)  (*(volatile int32_t *)(0x200 + 4*(k)))
#define RAM_B(k)  (*(volatile int32_t *)(0x240 + 4*(k)))
#define RAM_C(k)  (*(volatile int32_t *)(0x400 + 4*(k)))

static int32_t mul8(int32_t a, int32_t b) {
    int32_t neg = 0, r = 0;
    if (a < 0) { a = -a; neg ^= 1; }
    if (b < 0) { b = -b; neg ^= 1; }
    while (b) {
        if (b & 1) r += a;
        a <<= 1;
        b >>= 1;
    }
    return neg ? -r : r;
}

int main(void) {
    for (int i = 0; i < 4; i++)
        for (int j = 0; j < 4; j++) {
            int32_t s = 0;
            for (int k = 0; k < 4; k++)
                s += mul8(RAM_A(i*4 + k), RAM_B(k*4 + j));
            RAM_C(i*4 + j) = s;
        }
    return 0;
}

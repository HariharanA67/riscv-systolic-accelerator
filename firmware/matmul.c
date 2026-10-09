#include <stdint.h>

void _start() {
    // Just verify we can read/write memory
    int32_t *result = (int32_t *)0x80000000;
    *result = 0xDEADBEEF;
    
    // Infinite loop
    while(1);
}

# include <stdio.h>
int main() {
    long number = 2269503710;
    char sum = 0;    
    for (; number; number /= 10) sum += number % 10;    
    printf("%d\n", sum);
    return 0;
}
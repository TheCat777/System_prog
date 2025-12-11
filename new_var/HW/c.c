#include<stdio.h>

void start();
void add_num(int);
void add_random(int);
void del_num();
int count_prime();
int count_first();
int count_even();
void print_array();

int main(){
    start();
    add_num(1);
    add_num(2);
    add_random(10);
    add_num(3);
    add_num(4);

    del_num();
    print_array();

    printf("Even---%d\n", count_even());
    printf("Prime--%d\n", count_prime());
    printf("First--%d\n", count_first());

}
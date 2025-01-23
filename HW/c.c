#include<stdio.h>

void start();
void add_num(int);
void del_num();
int count_prime();
int count_first();
int count_even();
void close();
void print_array();

int main(){
    start();
    add_num(97);
    add_num(27);
    add_num(30);
    add_num(93);

    //del_num();
    print_array();

    printf("Even---%d\n", count_even());
    printf("Prime--%d\n", count_prime());
    printf("First--%d\n", count_first());

    //close();
}
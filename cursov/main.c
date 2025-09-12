#include <ncurses.h> //подключаем библиотеку ncurses
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

void delay(int number_of_seconds)
{
	// Converting time into milli_seconds
	int milli_seconds = 1000 * number_of_seconds;

	// Storing start time
	clock_t start_time = clock();

	// looping till required time is not achieved
	while (clock() < start_time + milli_seconds)
		;
}

int main(int argc, char *argv[])
{
    int type, type2;
    printf("Режим работы циклов:\n(1) - самостоятельная работа\n(2) - ручные итерации\n");
    scanf("%d", &type);
    printf("Стартовое наполнение:\n(1) - заполнение из файла\n(2) - случайное\n");
    scanf("%d", &type2);


    // инициализация (должна быть выполнена 
    // перед использованием ncurses)
    initscr();
    curs_set(0);  // "невидимый курсор"
    

    start_color();
    init_pair(1, COLOR_WHITE, COLOR_WHITE); // цвет живых клеток
    color_set(1, NULL);

    int max_y, max_x;
    getmaxyx(stdscr, max_y, max_x); // получение размера консоли

    bool array[max_y*max_x];
    bool new_array[max_y*max_x];

    for (int i = 0; i < max_y * max_x; ++i){  // первичное заполнение пустотой
        array[i] = false;
    }

    if (type2 == 1){
        // чтение из файла стартового состояния
        FILE *file = fopen("start.txt", "r");
        if (file == NULL) {
            perror("Ошибка при открытии файла");
            return 1;
        }

        int ch, row_i=0, col_j=0;
        while ((ch = fgetc(file)) != EOF) {
            if (ch == '\n'){
                ++row_i;
                col_j = 0;
            }
            if (ch == '1'){
                array[row_i*max_x+col_j] = true;
            }
            col_j++;
        }
        fclose(file);
    }
    else{
        for (int i = 1; i < max_y - 1; ++i){ // Блок подсчта количества соседних
            for (int j = 1; j < max_x - 1; ++j){
                if (rand() % 2){
                    array[i*max_x+j] = true;
                }
            }
        }
    }

    while(true){
        clear(); // отрисовка
        for (int i = 0; i < max_y * max_x; ++i){ 
            if (array[i] == true){
                move(i / max_x, i % max_x);
                printw(" ");
            }
        }
        refresh();
        if (type == 2){
            int ch = getch();
            if (ch == ' ') // условие выхода из игры
                break;
        }
        else{
            delay(100); // пауза между циклами
        }

        for (int i = 0; i < max_y; ++i){ // Блок подсчта количества соседних
            for (int j = 0; j < max_x; ++j){
                int sum = 0;
                if (i != 0 && j != 0 && i != max_y-1 && j != max_x-1){
                    if (array[(i-1)*max_x+j-1])
                        ++sum;
                    if (array[(i-1)*max_x+j])
                        ++sum;
                    if (array[(i-1)*max_x+j+1])
                        ++sum;
                    if (array[i*max_x+j-1])
                        ++sum;
                    if (array[i*max_x+j+1])
                        ++sum;
                    if (array[(i+1)*max_x+j-1])
                        ++sum;
                    if (array[(i+1)*max_x+j])
                        ++sum;
                    if (array[(i+1)*max_x+j+1])
                        ++sum;
                }
                
                
                if (array[i*max_x+j] && (sum == 2 || sum == 3))  // Если клетка живая условие
                    new_array[i*max_x+j] = true;
                else if (array[i*max_x+j] == false && sum == 3)  // Если клетка мёртвая условие
                    new_array[i*max_x+j] = true;
                else
                    new_array[i*max_x+j] = false;
            }
        }

        for (int i = 0; i < max_y * max_x; ++i){ // обновление на новый цикл
            array[i] = new_array[i];
        }
    }

    endwin(); // завершение работы с ncurses
}
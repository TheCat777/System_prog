#include <ncurses.h> //подключаем библиотеку ncurses
#include <stdio.h>
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
    int type;
    printf("Режим работы:\n(1) - самостоятельная работа\n(2) - ручные итерации\n");
    scanf("%d", &type);


    // инициализация (должна быть выполнена 
    // перед использованием ncurses)
    initscr();
    curs_set(0);  // "невидимый курсор"
    

    start_color();
    init_pair(1, COLOR_WHITE, COLOR_WHITE); // цвет живых клеток
    color_set(1, NULL);

    int row, col;
    getmaxyx(stdscr, row, col); // получение размера консоли

    bool data[row*col];
    bool new_data[row*col];

    for (int i = 0; i < row * col; ++i){  // первичное заполнение пустотой
            data[i] = false;
        }

    //data[4*col+10] = true;  // глайдер для примера
    //data[4*col+9] = true;
    //data[3*col+8] = true;
    //data[3*col+10] = true;
    //data[2*col+10] = true;
    
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
            data[row_i*col+col_j] = true;
        }
        col_j++;
    }

    fclose(file);

    for (int i = 0; i < row * col; ++i){ // вторичное заполнение уже экрана, чтобы сразу увидеть начальные условия
        if (data[i] == true){
            move(i / col, i % col);
            printw(" ");
        }
    }
    refresh();
    if (type == 2)
        getch();

    while(true){
        for (int i = 0; i < row; ++i){ // Блок подсчта количества соседних
            for (int j = 0; j < col; ++j){
                int sum = 0;
                if (i != 0 && j != 0 && i != row-1 && j != col-1){
                    if (data[(i-1)*col+j-1])
                        ++sum;
                    if (data[(i-1)*col+j])
                        ++sum;
                    if (data[(i-1)*col+j+1])
                        ++sum;
                    if (data[i*col+j-1])
                        ++sum;
                    if (data[i*col+j+1])
                        ++sum;
                    if (data[(i+1)*col+j-1])
                        ++sum;
                    if (data[(i+1)*col+j])
                        ++sum;
                    if (data[(i+1)*col+j+1])
                        ++sum;
                }
                
                
                if (data[i*col+j] && (sum == 2 || sum == 3))  // Если клетка живая условие
                    new_data[i*col+j] = true;
                else if (data[i*col+j] == false && sum == 3)  // Если клетка мёртвая условие
                    new_data[i*col+j] = true;
                else
                    new_data[i*col+j] = false;
            }
        }

        for (int i = 0; i < row * col; ++i){ // обновление на новый цикл
            data[i] = new_data[i];
        }

        clear(); // отрисовка
        for (int i = 0; i < row * col; ++i){ 
            if (data[i] == true){
                move(i / col, i % col);
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
    }

    endwin(); // завершение работы с ncurses
}
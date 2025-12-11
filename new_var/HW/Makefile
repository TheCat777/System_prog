# Компиляторы
ASM = fasm
CC = gcc

# Флаги
CFLAGS = -Wall -Wextra -std=c11 -O2 -fPIC
LDFLAGS = -no-pie

# Исходные файлы
ASM_SOURCES = 1.asm
C_SOURCES = c.c

# Автоматическая генерация имен объектных файлов
ASM_OBJECTS = $(ASM_SOURCES:.asm=.o)
C_OBJECTS = $(C_SOURCES:.c=.o)
OBJECTS = $(ASM_OBJECTS) $(C_OBJECTS)

# Целевая программа
TARGET = program

# Правила
all: $(TARGET)

$(TARGET): $(OBJECTS)
	$(CC) $(LDFLAGS) -o $@ $^

# Правило для ASM файлов
%.o: %.asm
	$(ASM) $< $@

# Правило для C файлов
%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<

# Зависимости (если нужно указать)
#main.o: helpers.h
#helpers.o: helpers.h

run: $(TARGET)
	./$(TARGET)

clean:
	rm -f $(TARGET) $(OBJECTS)

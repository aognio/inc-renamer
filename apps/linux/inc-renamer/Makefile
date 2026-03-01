CC := gcc
CFLAGS := -std=c11 -Wall -Wextra -Werror -O2
TARGET := inc-renamer
SRC := src/inc_renamer_daemon.c

all: $(TARGET)

$(TARGET): $(SRC)
	$(CC) $(CFLAGS) -o $@ $<

clean:
	rm -f $(TARGET)

.PHONY: all clean

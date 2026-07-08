CC := clang
CFLAGS := -std=c23 -Wall -Wextra -Wpedantic -Werror -O2 -g
LDFLAGS :=

SRC := $(wildcard src/*.c)
OBJ := $(SRC:.c=.o)
BIN := build/app

.PHONY: all clean run lint fmt test

all: $(BIN)

$(BIN): $(OBJ)
	@mkdir -p build
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

src/%.o: src/%.c
	$(CC) $(CFLAGS) -c -o $@ $<

lint:
	clang-tidy $(SRC) -- $(CFLAGS) 2>/dev/null || true

fmt:
	clang-format -i $(SRC)

run: all
	./$(BIN)

test:
	@echo "No tests yet"

clean:
	rm -rf build src/*.o

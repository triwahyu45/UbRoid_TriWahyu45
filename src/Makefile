CC ?= gcc
CFLAGS ?= -O2 -fPIC $(shell pkg-config --cflags gtk+-3.0)
LIBS ?= $(shell pkg-config --libs gtk+-3.0) -ldl

all: libnogap.so

libnogap.so: libnogap.c
	$(CC) $(CFLAGS) -shared $< -o $@ $(LIBS)

clean:
	rm -f libnogap.so

.PHONY: all clean

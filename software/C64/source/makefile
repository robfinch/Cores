TARGET = c64
LIBS = -lm
CC = g++
#CFLAGS = -g -Wall
CFLAGS = -Wall

.PHONY: default all clean

default: $(TARGET)
all: default

OBJECTS = $(patsubst %.c, %.o, $(wildcard *.c))
HEADERS = $(wildcard *.h)

%.o: %.c $(HEADERS)
	$(CC) $(CFLAGS) -c $< -o $@

.PRECIOUS: $(TARGET) $(OBJECTS)

$(TARGET): $(OBJECTS)
	$(CC) $(OBJECTS) -Wall $(LIBS) -o $@

clean:
	-rm -f *.o
	-rm -f $(TARGET)
   

#HEADERS = c.h cglbdec.h code.h expr.h gen.h statement.h
#
#all: c64
#c64: c64.o
#%.o: %.c $(HEADERS)
#c64.o: Optimize.c OutCode.c ParseDeclarations.c ParseEnumDeclaration.c
#	g++ -c 
#

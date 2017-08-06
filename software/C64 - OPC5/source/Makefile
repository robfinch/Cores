SOURCES=$(wildcard *.cpp)
OBJECTS=$(SOURCES:.cpp=.o)

CXXFLAGS+=-I. -std=c++11 -fpermissive -Wno-write-strings 

all: c64

c64: $(OBJECTS)
	g++ -o c64 $(OBJECTS)

clean:
	rm -f c64 $(OBJECTS)


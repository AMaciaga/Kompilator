.PHONY = all clean cleanall

all: kompilator


kompilator: grammar.y lexer.l
	bison -o grammar.c -d grammar.y
	flex -o lexer.c lexer.l
	g++ -std=c++11 -o kompilator lexer.c grammar.c -lfl

clean:
	rm -f *.c *.h

cleanall: clean
	rm -f kompilator

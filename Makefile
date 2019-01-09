.PHONY = all clean cleanall

all: kompilator


calc: grammar.y lexer.l
	bison -o grammar.c -d grammar.y
	flex -o lexer.c lexer.l
	gcc -o kompilator grammar.c lexer.c -ll -lm

clean:
	rm -f *.c *.h

cleanall: clean
	rm -f kompilator

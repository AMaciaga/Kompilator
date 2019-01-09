%{
// #define YYSTYPE string
#include <math.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#include <stdarg.h>
#include <iostream>
#include <fstream>
#include <string>
#include <map>
#include <vector>
#include <algorithm>
using namespace std;
int yylex();
extern int yylineno;
int yyerror(const string str);

vector<string> code;
void command(string str);


%}
%union {
    char* str;
    long long int num;
}
%token SEM
%token EQ
%token ASSIGN
%token COL
%token LB
%token RB

%token ADD
%token SUB
%token MUL
%token DIV
%token MOD

%token NE
%token LT
%token GT
%token LE
%token GE

%token DECLARE
%token IN
%token END
%token IF
%token THEN
%token ELSE
%token ENDIF
%token WHILE
%token DO
%token ENDWHILE
%token ENDDO
%token FOR
%token FROM
%token TO
%token DOWNTO
%token ENDFOR
%token READ
%token WRITE

%token NUM
%token IDENTIFIER
%%
program: DECLARE declarations IN commands END {command("HALT");};

declarations: declarations pidentifier SEM {}
             | declarations pidentifier LB num COL num RB SEM {}
             | {};

commands:   commands command {}
             | command {};

command:    identifier ASSIGN expression SEM {}
             | IF condition THEN commands ELSE commands ENDIF {}
             | IF condition THEN commands ENDIF {}
             | WHILE condition DO commands ENDWHILE {}
             | DO commands WHILE condition ENDDO {}
             | FOR pidentifier FROM value TO value DO commands ENDFOR {}
             | FOR pidentifier FROM value DOWNTO value DO commands ENDFOR {}
             | READ identifier SEM {}
             | WRITE value SEM {} ;

expression:  value {}
             | value ADD value {}
             | value SUB value {}
             | value MUL value {}
             | value DIV value {}
             | value SUB value {};

condition:   value EQ value {}
             | value NE value {}
             | value LT value {}
             | value GT value {}
             | value LE value {}
             | value GE value {};

value:       num {}
             | identifier {};

identifier: pidentifier {}
             | pidentifier LB pidentifier RB {}
             | pidentifier LB num RB {};
num:
    NUM {};

pidentifier:
    IDENTIFIER {};
%%
void command(string str) {
    code.push_back(str);
}
void printCodeStd() {
	long long int i;
	for(i = 0; i < code.size(); i++)
        cout << code.at(i) << endl;
}

int main(int argv, char* argc[])
{
    yyparse();
    printCodeStd();
    return 0;
}
int yyerror(string str){
   exit(1);
}
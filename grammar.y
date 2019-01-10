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

typedef struct {
	string name;
    string type; 
  	long long int size; // 0 forn non array variables
    long long int memPlace;
} id;
long long int memAssign;
vector<string> code;
vector<string> varsName;
vector<id> vars;
void command(string str);


%}
%union {
    char* str;
    long long int num;
}
%token <str> SEM
%token <str> EQ
%token <str> ASSIGN
%token <str> COL
%token <str> LB
%token <str> RB

%token <str> ADD
%token <str>  SUB
%token <str> MUL
%token <str> DIV
%token <str> MOD

%token <str> NE
%token <str> LT
%token <str> GT
%token <str> LE
%token <str> GE

%token <str> DECLARE
%token <str> IN
%token <str> END
%token <str> IF
%token <str> THEN
%token <str> ELSE
%token <str> ENDIF
%token <str> WHILE
%token <str> DO
%token <str> ENDWHILE
%token <str> ENDDO
%token <str> FOR
%token <str> FROM
%token <str> TO
%token <str> DOWNTO
%token <str> ENDFOR
%token <str> READ
%token <str> WRITE

%token <str> NUM
%token <str> IDENTIFIER

%type <str> pidentifier
%type <str> num
%%
program: DECLARE declarations IN commands END {command("HALT");};

declarations: 
    declarations pidentifier SEM {
        std::vector<string>::iterator it = std::find(varsName.begin(), varsName.end(), $2);
        if(it != varsName.end()) {
            cout << "Błąd [linia: " << yylineno \
            << "]: Kolejna deklaracja zmiennej " << $<str>2 << "." << endl;
            exit(1);
        }
        else {
            cout<<"Zadeklarowano zmienna "<<$<str>2<<endl;
            id s;
            s.name = $2;
            s.type = "ID";
            s.size = 0;
            s.memPlace = memAssign;
            memAssign++;
            varsName.push_back($2);
            vars.push_back(s);
        }

    }
    | declarations pidentifier LB num COL num RB SEM {
        std::vector<string>::iterator it = std::find(varsName.begin(), varsName.end(), $2);
        if(it != varsName.end()) {
            cout << "Błąd [linia: " << yylineno \
            << "]: Kolejna deklaracja zmiennej " << $<str>2 << "." << endl;
            exit(1);
        }
        else if(atoi($4)>atoi($6)){
            cout << "Błąd [linia: " << yylineno \
            << "]: Niepoprawna deklaracja zmiennej " << $<str>2 << ". Pierwsza liczba wieksza od drugiej" << endl;
            exit(1);
        }
        else {
            cout<<"Zadeklarowano zmienna "<<$<str>2<<endl;
            id s;
            long long int size = atoi($6)-atoi($4)+1
            s.name = $2;
            s.type = "ARR";
            s.size = size;
            s.memPlace = memAssign;
            memAssign+= size;
            varsName.push_back($2);
            vars.push_back(s);
        }
    }
    | ;

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

void printCode(string file) {
    ofstream codeFile(file);
	long long int i;
	for(i = 0; i < code.size(); i++)
        codeFile << code.at(i) << endl;
}
int main(int argv, char* argc[])
{
    memAssign =0;
    yyparse();
    if(argv < 2){
        cout<<"Nie podano parametrow"<<endl;
    }
    else{
        string file = argc[1];
        printCode(file);
    }
    return 0;
}
int yyerror(string str){
   exit(1);
}
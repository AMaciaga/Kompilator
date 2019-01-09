%{
#define YYSTYPE int
#include<stdio.h>
#include<math.h>
extern int yylineno;  
int yylex();
int yyerror(char*);
int err = 0;
%}
%token SEMICOLON
%token EQUAL
%token ASSIGN
%token COLON
%token LBRAC
%token RBRAC

%token ADD
%token SUB
%token MULT
%token DIV
%token MOD

%token NEQUAL
%token LESS
%token GREAT
%token LESSEQUAL
%token GREATEQUAL

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
program: DECLARE declarations IN commands END;

declarations: declarations pidentifier SEMICOLON
             | declarations pidentifier LBARC num COLON num LBRAC SEMICOLON
             | ;

commands:   commands command
             | command;

command:    identifier ASSIGN expression SEMICOLON
             | IF condition THEN commands ELSE commands ENDIF
             | IF condition THEN commands ENDIF
             | WHILE condition DO commands ENDWHILE
             | DO commands WHILE condition ENDDO
             | FOR pidentifier FROM value TO value DO commands ENDFOR
             | FOR pidentifier FROM value DOWNTO value DO commands ENDFOR
             | READ identifier SEMICOLON
             | WRITE value SEMICOLON ;

expression:  value
             | value ADD value
             | value SUB value
             | value MULT value
             | value DIV value
             | value SUB value;

condition:   value EQUAL value
             | value NEQUAL value
             | value LESS value
             | value GREAT value
             | value LESSEQUAL value
             | value GREATEQUAL value;

value:       num
             | identifier;

identifier: pidentifier
             | pidentifier LBRAC pidentifier RBRAC
             | pidentifier LBARC num RBRAC;
%%
int yyerror(char *s)
{
    printf("%s\n",s);
    return 0;
}

int main()
{
    yyparse();
    return 0;
}
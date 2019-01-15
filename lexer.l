%option noyywrap
%option yylineno
%s IN_COMMENT
%{

#include "grammar.h"
#include <stdlib.h>
#include <string.h>
#include <iostream>
%}
%%

"["        BEGIN(IN_COMMENT);
";"        {    
                    return SEM;
                    }
"="        {
                    return EQ;
                    }
":="       {
                    return ASSIGN;
                    }
":"       {
                    return COL;
                    }
"("       {
                    return LB;
                    }
")"       {
                    return RB;
                    }

"+"        {
                    return ADD;
                    }
"-"        {
                    return SUB;
                    }
"*"        {
                    return MUL;
                    }
"/"        {
                    return DIV; 
                    }
"%"        {
                    return MOD;  
                    }

"!="       {
                    return NE;  
                    }
"<"        {  
                    return LT;    
                    }
">"        {
                    return GT;   
                    }
"<="       { 
                    return LE;
                    }
">="       {
                    return GE;  
                    }

<IN_COMMENT>"]"    BEGIN(INITIAL);
<IN_COMMENT>[^\]]+ 
	

"DECLARE"  {return DECLARE;}
"IN"  {return IN;}
"END"  {return END;}
"IF"  {return IF;}
"THEN"  {return THEN;}
"ELSE"  {return ELSE;}
"ENDIF"  {return ENDIF;}
"WHILE"  {return WHILE;}
"DO"  {return DO;}
"ENDWHILE"  {return ENDWHILE;}
"ENDDO"  {return ENDDO;}
"FOR"  {return FOR;}
"FROM"  {return FROM;}
"TO"  {return TO;}
"DOWNTO"  {return DOWNTO;}
"ENDFOR"  {return ENDFOR;}
"READ"  {return READ;}
"WRITE"  {return WRITE;}

[0-9]+         {
        
                yylval.str = (char *)strdup(yytext);
                return NUM;
                }
[_a-z]+        {
        
                yylval.str = (char *)strdup(yytext);
                return IDENTIFIER;  
                        }
[ \n\t\r]         
.               ;

%%

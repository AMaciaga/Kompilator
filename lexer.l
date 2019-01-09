%option noyywrap
%option yylineno
%s IN_COMMENT
%{

#include "grammar_y.h"

%}
%%

<INITIAL>"["        BEGIN(IN_COMMENT);
<INITIAL>";"        {
                    return SEMICOLON;
                    }
<INITIAL>"="        {
                    return EQUAL;
                    }
<INITIAL>":="       {
                    return ASSIGN;
                    }
<INITIAL>":"       {
                    return COLON;
                    }
<INITIAL>"("       {
                    return LBRAC;
                    }
<INITIAL>")"       {
                    return RBRAC;
                    }

<INITIAL>"+"        {
                    return ADD;
                    }
<INITIAL>"-"        {
                    return SUB;
                    }
<INITIAL>"*"        {
                    return MULT;
                    }
<INITIAL>"/"        {
                    return DIV; 
                    }
<INITIAL>"%"        {
                    // return MOD;  
                    }

<INITIAL>"!="       {
                    return NEQUAL;  
                    }
<INITIAL>"<"        {  
                    return LESS;    
                    }
<INITIAL>">"        {
                    return GREAT;   
                    }
<INITIAL>"<="       { 
                    return LESSEQUAL;
                    }
<INITIAL>">="       {
                    return GREATEQUAL;  
                    }

<IN_COMMENT>[^\]]   ;
<IN_COMMENT>\]      BEGIN(INITIAL);

<INITIAL>"DECLARE"  {return DECLARE;}
<INITIAL>"IN"  {return IN;}
<INITIAL>"END"  {return END;}
<INITIAL>"IF"  {return IF;}
<INITIAL>"THEN"  {return THEN;}
<INITIAL>"ELSE"  {return ELSE;}
<INITIAL>"ENDIF"  {return ENDIF;}
<INITIAL>"WHILE"  {return WHILE;}
<INITIAL>"DO"  {return DO;}
<INITIAL>"ENDWHILE"  {return ENDWHILE;}
<INITIAL>"ENDDO"  {return ENDDO;}
<INITIAL>"FOR"  {return FOR;}
<INITIAL>"FROM"  {return FROM;}
<INITIAL>"TO"  {return TO;}
<INITIAL>"DOWNTO"  {return DOWNTO;}
<INITIAL>"ENDFOR"  {return ENDFOR;}
<INITIAL>"READ"  {return READ;}
<INITIAL>"WRITE"  {return WRITE;}

<INITIAL>[A-Z]+	     {printf("ERROR_INVALID_KEYWORD");}
<INITIAL>[0-9]+         {ECHO; 
                        // yylval = std::string(yytext);
                        // return NUM; 
                        }
<INITIAL>[_a-z]+        {ECHO;
                        // yylval = std::string(yytext);  
                        // return IDENTIFIER;  
                        }
<INITIAL>[ \n\t]         ECHO;

%%
int main(){
	yylex();
	
}
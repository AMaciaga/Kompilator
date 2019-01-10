%{
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
    bool init;
	string name;
    string type; 
  	long long int size; // 0 forn non array variables
    long long int startsAt; // 0 forn non array variables
    long long int memPlace;
} id;
long long int memAssign;
vector<string> code;
vector<id> vars;
string reg[8];
bool isCurrAssign=true;
id assignedVar;
string expVal[2]={"-1","-1"};
string expReg;
void setIndex(long long int mem);
void storeToMem(string r);
string findEmptyReg();
void addVariable(id s);
void createVariable(id* s,string name, string type, long long int size,long long int startsAt, long long int mem, bool init );
void generateNumber(long long int arg,string r);
void writeCommand(string str);
void outCode(string file);
long long int findIndexOf(vector<id> v, string name);

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
%token <str> SUB
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
program: DECLARE declarations IN commands END {writeCommand("HALT");};

declarations: 
    declarations pidentifier SEM {
        
        if(findIndexOf(vars,$<str>2)!= -1) {
            cout << "Błąd [linia: " << yylineno \
            << "]: Kolejna deklaracja zmiennej " << $<str>2 << "." << endl;
            exit(1);
        }
        else {
            id s;
            createVariable(&s,$2,"ID",0,0,memAssign,false);
            memAssign++;
            addVariable(s);
        }

    }
    | declarations pidentifier LB num COL num RB SEM {
        if(findIndexOf(vars,$<str>2) != -1) {
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
            id s;
            long long int size = atoi($6)-atoi($4)+1;
            createVariable(&s,$2,"ARR",size,atoi($4),memAssign,false);
            memAssign+= size;
            addVariable(s);
        }
    }
    | ;

commands:   
    commands command 
    | command ;

command:    
    identifier {isCurrAssign=false;} ASSIGN expression SEM {
        if(assignedVar.type == "ARR"){
            
        }
        else{
            setIndex(assignedVar.memPlace);
            storeToMem(expReg);
        }
        vars.at(findIndexOf(vars,assignedVar.name)).init=true;
        isCurrAssign=true;
    }
    | IF condition THEN commands ELSE commands ENDIF {}
    | IF condition THEN commands ENDIF {}
    | WHILE condition DO commands ENDWHILE {}
    | DO commands WHILE condition ENDDO {}
    | FOR pidentifier FROM value TO value DO commands ENDFOR {}
    | FOR pidentifier FROM value DOWNTO value DO commands ENDFOR {}
    | READ identifier SEM {}
    | WRITE value SEM {} ;

expression: 
    value {
        id arg = vars.at(findIndexOf(vars,expVal[0]));
        if(arg.type == "NUM"){
            string regVal = findEmptyReg();
            if(regVal != "X"){
                generateNumber(atoi(arg.name.c_str()),regVal);
                expReg = regVal;
            }
        }
        else if(arg.type == "IDE") {
            // memToRegister(ide.mem);
        }
        expVal[0] = "-1";
    }
    | value ADD value {}
    | value SUB value {}
    | value MUL value {}
    | value DIV value {}
    | value MOD value {};

condition:   
    value EQ value {}
    | value NE value {}
    | value LT value {}
    | value GT value {}
    | value LE value {}
    | value GE value {};

value:       
    num {
        if(isCurrAssign){
            cout << "Błąd [linia: " << yylineno \
            << "]: " << $<str>1 << " nie jest zmienna." << endl;
            exit(1);
        }
        id s;
        createVariable(&s,$1,"NUM",0,0,memAssign,true);
        memAssign++;
        addVariable(s);
        if(expVal[0]=="-1"){
            expVal[0]=$1;
        }else{
            expVal[1]=$1;
        }
    }
    | identifier ;

identifier: 
    pidentifier {
        long long int index = findIndexOf(vars,$<str>1);
        if( index == -1) {
            cout << "Błąd [linia: " << yylineno \
            << "]: Proba skorzystania z niezadeklarowanej zmiennej " << $<str>1 << "." << endl;
            exit(1);
        }
        if(vars.at(index).type != "ARR"){
            if(!isCurrAssign){
                if(!vars.at(index).init){
                    cout << "Błąd [linia: " << yylineno \
                    << "]: Zmienna " << $<str>1 << " mogla zostac niezainicjowana." << endl;
                    exit(1);
                }
                if(expVal[0]=="-1"){
                    expVal[0]=$1;
                }else{
                    expVal[1]=$1;
                }
            }
            else{
                assignedVar = vars.at(index);
            }
        }
        
    }   
    | pidentifier LB pidentifier RB {}
    | pidentifier LB num RB {};
num:
    NUM;

pidentifier:
    IDENTIFIER;
%%
void setIndex(long long int mem){
    generateNumber(mem,"A");
}
void storeToMem(string r){
    string temp = "STORE "+ r;
    code.push_back(temp);
}
string findEmptyReg(){
    for(int i = 7;i>=1;--i){
        if(reg[i]==""){
            int unicode = 65+i;
            char character = (char) unicode;
            string text(1,character);
            reg[i]="full";
            return text;
        }
        
    }
    return "X";
}
void createVariable(id* s,string name, string type, long long int size,long long int startsAt, long long int mem, bool init ){
    s->name = name;
    s->type = type;
    s->size = size;
    s->startsAt = startsAt;
    s->memPlace = mem;
    s->init = init;
}

void addVariable(id s){
    vars.push_back(s);
}

void writeCommand(string str) {
    code.push_back(str);
}
void generateNumber(long long int arg,string r){
    vector<string>genNum;
    while(arg){
        if(arg & 1){
            string temp = "INC "+ r;
            genNum.push_back(temp);
        }
        arg>>=1;
        if(arg){
            string temp = "ADD "+ r+" "+r;
            genNum.push_back(temp);
        }
    }
    string temp = "SUB "+ r+" "+r;
    genNum.push_back(temp);
    for(int i=genNum.size()-1;i>=0;--i){
        code.push_back(genNum.at(i));
    }

}
void outCode(string file) {
    ofstream codeFile(file);
	long long int i;
	for(i = 0; i < code.size(); i++)
        codeFile << code.at(i) << endl;
}

long long int findIndexOf(vector<id> v, string name){
    for(long long int i = 0; i<v.size();++i){
        if(v.at(i).name == name){
            return i;
        }
    }
    return -1;
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
        outCode(file);
    }
    return 0;
}
int yyerror(string str){
   exit(1);
}
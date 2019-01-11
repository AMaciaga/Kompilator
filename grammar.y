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
long long int linesNo;
long long int memAssign;
vector<string> code;
vector<id> vars;
string reg[8];
bool isCurrAssign=true;
id assignedVar;
string expVal[2]={"-1","-1"};
string divReg;
string modReg;
string expReg;
void setIndex(long long int mem);
void writeCommandWithArg(string com,string arg);
void writeCommandWithTwoArg(string com,string arg1,string arg2);
string findEmptyReg();
void freeReg(string str);
void addVariable(id s);
void createVariable(id* s,string name, string type, long long int size,long long int startsAt, long long int mem, bool init );
void generateNumber(long long int arg,string r);
void writeCommand(string str);
void outCode(string file);
long long int findIndexOf(vector<id> v, string name);
void add(id a, id b);
void sub(id a, id b);
void mult(id a, id b);
void div(id a, id b);

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
            writeCommandWithArg("STORE",expReg);
        }
        freeReg(expReg);
        vars.at(findIndexOf(vars,assignedVar.name)).init=true;
        isCurrAssign=true;
    }
    | IF condition THEN commands ELSE commands ENDIF {}
    | IF condition THEN commands ENDIF {}
    | WHILE condition DO commands ENDWHILE {}
    | DO commands WHILE condition ENDDO {}
    | FOR pidentifier FROM value TO value DO commands ENDFOR {}
    | FOR pidentifier FROM value DOWNTO value DO commands ENDFOR {}
    | READ identifier SEM {
        
    }
    | WRITE {isCurrAssign = false;} value SEM {

        id arg = vars.at(findIndexOf(vars,expVal[0]));
        if(arg.type == "NUM"){
            string regVal = findEmptyReg();
            if(regVal != "X"){
                generateNumber(atoi(arg.name.c_str()),regVal);
                expReg = regVal;
            }
            else{
                cout << "zrzut pamieci" << endl;
                exit(1);
            }
        }
        else if(arg.type == "ID") {
            string regVal = findEmptyReg();
            if(regVal != "X"){
                setIndex(arg.memPlace);
                writeCommandWithArg("LOAD",regVal);
                expReg = regVal;
            }
            else{
                cout << "zrzut pamieci" << endl;
                exit(1);
            }
        }
        expVal[0] = "-1";


        writeCommandWithArg("PUT",expReg);
        freeReg(expReg);
        isCurrAssign=true;
    } ;

expression: 
    value {
        id arg = vars.at(findIndexOf(vars,expVal[0]));
        if(arg.type == "NUM"){
            string regVal = findEmptyReg();
            if(regVal != "X"){
                generateNumber(atoi(arg.name.c_str()),regVal);
                expReg = regVal;
            }
            else{
                cout << "zrzut pamieci" << endl;
                exit(1);
            }
        }
        else if(arg.type == "ID") {
            string regVal = findEmptyReg();
            if(regVal != "X"){
                setIndex(arg.memPlace);
                writeCommandWithArg("LOAD",regVal);
                expReg = regVal;
            }
            else{
                cout << "zrzut pamieci" << endl;
                exit(1);
            }
        }
        expVal[0] = "-1";
    }
    | value ADD value {
        id a = vars.at(findIndexOf(vars,expVal[0]));
        id b = vars.at(findIndexOf(vars,expVal[1]));
        if(a.type != "ARR" && b.type != "ARR")
            add(a, b);
        else{

        }
        expVal[0] = "-1";
        expVal[1] = "-1";
    }
    | value SUB value {
        id a = vars.at(findIndexOf(vars,expVal[0]));
        id b = vars.at(findIndexOf(vars,expVal[1]));
        if(a.type != "ARR" && b.type != "ARR")
            sub(a, b);
        else{

        }
        expVal[0] = "-1";
        expVal[1] = "-1";
    }
    | value MUL value {
        id a = vars.at(findIndexOf(vars,expVal[0]));
        id b = vars.at(findIndexOf(vars,expVal[1]));
        if(a.type != "ARR" && b.type != "ARR")
            mult(a, b);
        else{

        }
        expVal[0] = "-1";
        expVal[1] = "-1";
    }
    | value DIV value {
        id a = vars.at(findIndexOf(vars,expVal[0]));
        id b = vars.at(findIndexOf(vars,expVal[1]));
        if(a.type != "ARR" && b.type != "ARR"){
            cout<<a.name<<b.name<<endl;
            div(a, b);
            expReg = divReg;
            freeReg(modReg);
        }
        else{

        }
        expVal[0] = "-1";
        expVal[1] = "-1";
    }
    | value MOD value {
        id a = vars.at(findIndexOf(vars,expVal[0]));
        id b = vars.at(findIndexOf(vars,expVal[1]));
        if(a.type != "ARR" && b.type != "ARR"){
            div(a, b);
            expReg = modReg;
            freeReg(divReg);
        }
        else{

        }
        expVal[0] = "-1";
        expVal[1] = "-1";
    };

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
void writeCommandWithArg(string com,string arg){
    string temp = com+" "+ arg;
    code.push_back(temp);
    linesNo++;
}
void writeCommandWithTwoArg(string com,string arg1,string arg2){
    string temp = com+" "+ arg1 + " "+arg2;
    code.push_back(temp);
    linesNo++;
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

void add(id a, id b){

    if(a.type == "NUM" && b.type == "NUM") {
        string regValA = findEmptyReg();
        string regValB = findEmptyReg();
        if(regValA != "X" && regValB != "X"  ){
            generateNumber(atoi(a.name.c_str()),regValA);
            generateNumber(atoi(b.name.c_str()),regValB);
            writeCommandWithTwoArg("ADD",regValA,regValB);
            expReg = regValA;
            freeReg(regValB);
        }
        else{
            cout << "zrzut pamieci" << endl;
            exit(1);
        }
        
    }
    else if(a.type == "NUM" && b.type == "ID") {
        string regValA = findEmptyReg();
        string regValB = findEmptyReg();
        if(regValA != "X" && regValB != "X"  ){
            generateNumber(atoi(a.name.c_str()),regValA);
            setIndex(b.memPlace);
            writeCommandWithArg("LOAD",regValB);
            writeCommandWithTwoArg("ADD",regValA,regValB);
            expReg = regValA;
            freeReg(regValB);
        }
        else{
            cout << "zrzut pamieci" << endl;
            exit(1);
        }
    }
    else if(a.type == "ID" && b.type == "NUM") {
        string regValA = findEmptyReg();
        string regValB = findEmptyReg();
        if(regValA != "X" && regValB != "X"  ){
            generateNumber(atoi(b.name.c_str()),regValB);
            setIndex(a.memPlace);
            writeCommandWithArg("LOAD",regValA);
            writeCommandWithTwoArg("ADD",regValA,regValB);
            expReg = regValA;
            freeReg(regValB);
        }
        else{
            cout << "zrzut pamieci" << endl;
            exit(1);
        }
    }
    else if(a.type == "ID" && b.type == "ID") {
        if(a.name == b.name) {
            string regValA = findEmptyReg();
            if(regValA != "X" ){
                setIndex(a.memPlace);
                writeCommandWithArg("LOAD",regValA);
                writeCommandWithTwoArg("ADD",regValA,regValA);
                expReg = regValA;
            }
            else{
                cout << "zrzut pamieci" << endl;
                exit(1);
            }
        }
        else {
            string regValA = findEmptyReg();
            string regValB = findEmptyReg();
            if(regValA != "X" && regValB != "X"  ){
                setIndex(a.memPlace);
                writeCommandWithArg("LOAD",regValA);
                setIndex(b.memPlace);
                writeCommandWithArg("LOAD",regValB);
                writeCommandWithTwoArg("ADD",regValA,regValB);
                expReg = regValA;
                freeReg(regValB);
            }
            else{
                cout << "zrzut pamieci" << endl;
                exit(1);
            }
        }
    }
}

void sub(id a, id b){

    if(a.type == "NUM" && b.type == "NUM") {
        string regValA = findEmptyReg();
        string regValB = findEmptyReg();
        if(regValA != "X" && regValB != "X"  ){
            generateNumber(atoi(a.name.c_str()),regValA);
            generateNumber(atoi(b.name.c_str()),regValB);
            writeCommandWithTwoArg("SUB",regValA,regValB);
            expReg = regValA;
            freeReg(regValB);
        }
        else{
            cout << "zrzut pamieci" << endl;
            exit(1);
        }
        
    }
    else if(a.type == "NUM" && b.type == "ID") {
        string regValA = findEmptyReg();
        string regValB = findEmptyReg();
        if(regValA != "X" && regValB != "X"  ){
            generateNumber(atoi(a.name.c_str()),regValA);
            setIndex(b.memPlace);
            writeCommandWithArg("LOAD",regValB);
            writeCommandWithTwoArg("SUB",regValA,regValB);
            expReg = regValA;
            freeReg(regValB);
        }
        else{
            cout << "zrzut pamieci" << endl;
            exit(1);
        }
    }
    else if(a.type == "ID" && b.type == "NUM") {
        string regValA = findEmptyReg();
        string regValB = findEmptyReg();
        if(regValA != "X" && regValB != "X"  ){
            generateNumber(atoi(b.name.c_str()),regValB);
            setIndex(a.memPlace);
            writeCommandWithArg("LOAD",regValA);
            writeCommandWithTwoArg("SUB",regValA,regValB);
            expReg = regValA;
            freeReg(regValB);
        }
        else{
            cout << "zrzut pamieci" << endl;
            exit(1);
        }
    }
    else if(a.type == "ID" && b.type == "ID") {
        if(a.name == b.name) {
            string regValA = findEmptyReg();
            if(regValA != "X" ){
                setIndex(a.memPlace);
                writeCommandWithArg("LOAD",regValA);
                writeCommandWithTwoArg("SUB",regValA,regValA);
                expReg = regValA;
            }
            else{
                cout << "zrzut pamieci" << endl;
                exit(1);
            }
        }
        else {
            string regValA = findEmptyReg();
            string regValB = findEmptyReg();
            if(regValA != "X" && regValB != "X"  ){
                setIndex(a.memPlace);
                writeCommandWithArg("LOAD",regValA);
                setIndex(b.memPlace);
                writeCommandWithArg("LOAD",regValB);
                writeCommandWithTwoArg("SUB",regValA,regValB);
                expReg = regValA;
                freeReg(regValB);
            }
            else{
                cout << "zrzut pamieci" << endl;
                exit(1);
            }
        }
    }
}
void mult(id a, id b){

    if(a.type == "NUM" && b.type == "NUM") {
        string regValA = findEmptyReg();
        string regValB = findEmptyReg();
        string regValC = findEmptyReg();
        if(regValA != "X" && regValB != "X" && regValC != "X"  ){
            generateNumber(atoi(a.name.c_str()),regValA);
            generateNumber(atoi(b.name.c_str()),regValB);
            writeCommandWithTwoArg("SUB",regValC,regValC);
            writeCommandWithTwoArg("JZERO",regValA,to_string(linesNo+7));
            writeCommandWithTwoArg("JODD",regValA,to_string(linesNo+2));
            writeCommandWithArg("JUMP",to_string(linesNo+2));
            writeCommandWithTwoArg("ADD",regValC,regValB);
            writeCommandWithArg("HALF",regValA);
            writeCommandWithTwoArg("ADD",regValB,regValB);
            writeCommandWithArg("JUMP",to_string(linesNo-6));
            expReg = regValC;
            freeReg(regValA);
            freeReg(regValB);
        }
        else{
            cout << "zrzut pamieci" << endl;
            exit(1);
        }
        
    }
    else if(a.type == "NUM" && b.type == "ID") {
        string regValA = findEmptyReg();
        string regValB = findEmptyReg();
        string regValC = findEmptyReg();
        if(regValA != "X" && regValB != "X" && regValC != "X"  ){
            generateNumber(atoi(a.name.c_str()),regValA);
            setIndex(b.memPlace);
            writeCommandWithArg("LOAD",regValB);
            writeCommandWithTwoArg("SUB",regValC,regValC);
            writeCommandWithTwoArg("JZERO",regValA,to_string(linesNo+7));
            writeCommandWithTwoArg("JODD",regValA,to_string(linesNo+2));
            writeCommandWithArg("JUMP",to_string(linesNo+2));
            writeCommandWithTwoArg("ADD",regValC,regValB);
            writeCommandWithArg("HALF",regValA);
            writeCommandWithTwoArg("ADD",regValB,regValB);
            writeCommandWithArg("JUMP",to_string(linesNo-6));
            expReg = regValC;
            freeReg(regValA);
            freeReg(regValB);
        }
        else{
            cout << "zrzut pamieci" << endl;
            exit(1);
        }
    }
    else if(a.type == "ID" && b.type == "NUM") {
        string regValA = findEmptyReg();
        string regValB = findEmptyReg();
        string regValC = findEmptyReg();
        if(regValA != "X" && regValB != "X"  && regValC != "X" ){
            generateNumber(atoi(b.name.c_str()),regValB);
            setIndex(a.memPlace);
            writeCommandWithArg("LOAD",regValA);
            writeCommandWithTwoArg("SUB",regValC,regValC);
            writeCommandWithTwoArg("JZERO",regValA,to_string(linesNo+7));
            writeCommandWithTwoArg("JODD",regValA,to_string(linesNo+2));
            writeCommandWithArg("JUMP",to_string(linesNo+2));
            writeCommandWithTwoArg("ADD",regValC,regValB);
            writeCommandWithArg("HALF",regValA);
            writeCommandWithTwoArg("ADD",regValB,regValB);
            writeCommandWithArg("JUMP",to_string(linesNo-6));
            expReg = regValC;
            freeReg(regValA);
            freeReg(regValB);
        }
        else{
            cout << "zrzut pamieci" << endl;
            exit(1);
        }
    }
    else if(a.type == "ID" && b.type == "ID") {
        
        string regValA = findEmptyReg();
        string regValB = findEmptyReg();
        string regValC = findEmptyReg();
        if(regValA != "X" && regValB != "X" && regValC != "X"  ){
            setIndex(a.memPlace);
            writeCommandWithArg("LOAD",regValA);
            setIndex(b.memPlace);
            writeCommandWithArg("LOAD",regValB);
            writeCommandWithTwoArg("SUB",regValC,regValC);
            writeCommandWithTwoArg("JZERO",regValA,to_string(linesNo+7));
            writeCommandWithTwoArg("JODD",regValA,to_string(linesNo+2));
            writeCommandWithArg("JUMP",to_string(linesNo+2));
            writeCommandWithTwoArg("ADD",regValC,regValB);
            writeCommandWithArg("HALF",regValA);
            writeCommandWithTwoArg("ADD",regValB,regValB);
            writeCommandWithArg("JUMP",to_string(linesNo-6));
            expReg = regValC;
            freeReg(regValA);
            freeReg(regValB);
        }
        else{
            cout << "zrzut pamieci" << endl;
            exit(1);
        }
        
    }
}
void div(id a, id b){

    if(a.type == "NUM" && b.type == "NUM") {
        string regValA = findEmptyReg();
        string regValB = findEmptyReg();
        string regValC = findEmptyReg();
        string regValD = findEmptyReg();
        string regValE = findEmptyReg();
        if(regValA != "X" && regValB != "X" && regValC != "X" && regValD != "X" && regValE != "X" ){
            generateNumber(atoi(a.name.c_str()),regValA);
            generateNumber(atoi(b.name.c_str()),regValB);
            writeCommandWithTwoArg("SUB",regValC,regValC);
            writeCommandWithTwoArg("SUB",regValD,regValD);
            writeCommandWithArg("INC",regValD);
            writeCommandWithTwoArg("COPY",regValE,regValA);
            writeCommandWithTwoArg("SUB",regValE,regValB);
            writeCommandWithTwoArg("JZERO",regValE,to_string(linesNo+4));
            writeCommandWithTwoArg("ADD",regValB,regValB);
            writeCommandWithTwoArg("ADD",regValD,regValD);
            writeCommandWithArg("JUMP",to_string(linesNo-5));
            writeCommandWithTwoArg("COPY",regValE,regValA);
            writeCommandWithArg("INC",regValE);
            writeCommandWithTwoArg("SUB",regValE,regValB);
            writeCommandWithTwoArg("JZERO",regValE,to_string(linesNo+3));
            writeCommandWithTwoArg("SUB",regValA,regValB);
            writeCommandWithTwoArg("ADD",regValC,regValD);
            writeCommandWithArg("HALF",regValB);
            writeCommandWithArg("HALF",regValD);
            writeCommandWithTwoArg("JZERO",regValD,to_string(linesNo+2));
            writeCommandWithArg("JUMP",to_string(linesNo-9));
            divReg = regValC;
            modReg = regValA;
            freeReg(regValB);
            freeReg(regValD);
            freeReg(regValE);
        }
        else{
            cout << "zrzut pamieci" << endl;
            exit(1);
        }
        
    }
    else if(a.type == "NUM" && b.type == "ID") {
        string regValA = findEmptyReg();
        string regValB = findEmptyReg();
        string regValC = findEmptyReg();
        string regValD = findEmptyReg();
        string regValE = findEmptyReg();
        if(regValA != "X" && regValB != "X" && regValC != "X" && regValD != "X" && regValE != "X" ){
            generateNumber(atoi(a.name.c_str()),regValA);
            setIndex(b.memPlace);
            writeCommandWithArg("LOAD",regValB);
            writeCommandWithTwoArg("SUB",regValC,regValC);
            writeCommandWithTwoArg("SUB",regValD,regValD);
            writeCommandWithArg("INC",regValD);
            writeCommandWithTwoArg("COPY",regValE,regValA);
            writeCommandWithTwoArg("SUB",regValE,regValB);
            writeCommandWithTwoArg("JZERO",regValE,to_string(linesNo+4));
            writeCommandWithTwoArg("ADD",regValB,regValB);
            writeCommandWithTwoArg("ADD",regValD,regValD);
            writeCommandWithArg("JUMP",to_string(linesNo-5));
            writeCommandWithTwoArg("COPY",regValE,regValA);
            writeCommandWithArg("INC",regValE);
            writeCommandWithTwoArg("SUB",regValE,regValB);
            writeCommandWithTwoArg("JZERO",regValE,to_string(linesNo+3));
            writeCommandWithTwoArg("SUB",regValA,regValB);
            writeCommandWithTwoArg("ADD",regValC,regValD);
            writeCommandWithArg("HALF",regValB);
            writeCommandWithArg("HALF",regValD);
            writeCommandWithTwoArg("JZERO",regValD,to_string(linesNo+2));
            writeCommandWithArg("JUMP",to_string(linesNo-9));
            divReg = regValC;
            modReg = regValA;
            freeReg(regValB);
            freeReg(regValD);
            freeReg(regValE);
        }
        else{
            cout << "zrzut pamieci" << endl;
            exit(1);
        }
    }
    else if(a.type == "ID" && b.type == "NUM") {
        string regValA = findEmptyReg();
        string regValB = findEmptyReg();
        string regValC = findEmptyReg();
        string regValD = findEmptyReg();
        string regValE = findEmptyReg();
        if(regValA != "X" && regValB != "X" && regValC != "X" && regValD != "X" && regValE != "X" ){
            generateNumber(atoi(b.name.c_str()),regValB);
            setIndex(a.memPlace);
            writeCommandWithArg("LOAD",regValA);
            writeCommandWithTwoArg("SUB",regValC,regValC);
            writeCommandWithTwoArg("SUB",regValD,regValD);
            writeCommandWithArg("INC",regValD);
            writeCommandWithTwoArg("COPY",regValE,regValA);
            writeCommandWithTwoArg("SUB",regValE,regValB);
            writeCommandWithTwoArg("JZERO",regValE,to_string(linesNo+4));
            writeCommandWithTwoArg("ADD",regValB,regValB);
            writeCommandWithTwoArg("ADD",regValD,regValD);
            writeCommandWithArg("JUMP",to_string(linesNo-5));
            writeCommandWithTwoArg("COPY",regValE,regValA);
            writeCommandWithArg("INC",regValE);
            writeCommandWithTwoArg("SUB",regValE,regValB);
            writeCommandWithTwoArg("JZERO",regValE,to_string(linesNo+3));
            writeCommandWithTwoArg("SUB",regValA,regValB);
            writeCommandWithTwoArg("ADD",regValC,regValD);
            writeCommandWithArg("HALF",regValB);
            writeCommandWithArg("HALF",regValD);
            writeCommandWithTwoArg("JZERO",regValD,to_string(linesNo+2));
            writeCommandWithArg("JUMP",to_string(linesNo-9));
            divReg = regValC;
            modReg = regValA;
            freeReg(regValB);
            freeReg(regValD);
            freeReg(regValE);
        }
        else{
            cout << "zrzut pamieci" << endl;
            exit(1);
        }
    }
    else if(a.type == "ID" && b.type == "ID") {
        
        string regValA = findEmptyReg();
        string regValB = findEmptyReg();
        string regValC = findEmptyReg();
        string regValD = findEmptyReg();
        string regValE = findEmptyReg();
        if(regValA != "X" && regValB != "X" && regValC != "X" && regValD != "X" && regValE != "X" ){
            setIndex(a.memPlace);
            writeCommandWithArg("LOAD",regValA);
            setIndex(b.memPlace);
            writeCommandWithArg("LOAD",regValB);
            writeCommandWithTwoArg("SUB",regValC,regValC);
            writeCommandWithTwoArg("SUB",regValD,regValD);
            writeCommandWithArg("INC",regValD);
            writeCommandWithTwoArg("COPY",regValE,regValA);
            writeCommandWithTwoArg("SUB",regValE,regValB);
            writeCommandWithTwoArg("JZERO",regValE,to_string(linesNo+4));
            writeCommandWithTwoArg("ADD",regValB,regValB);
            writeCommandWithTwoArg("ADD",regValD,regValD);
            writeCommandWithArg("JUMP",to_string(linesNo-5));
            writeCommandWithTwoArg("COPY",regValE,regValA);
            writeCommandWithArg("INC",regValE);
            writeCommandWithTwoArg("SUB",regValE,regValB);
            writeCommandWithTwoArg("JZERO",regValE,to_string(linesNo+3));
            writeCommandWithTwoArg("SUB",regValA,regValB);
            writeCommandWithTwoArg("ADD",regValC,regValD);
            writeCommandWithArg("HALF",regValB);
            writeCommandWithArg("HALF",regValD);
            writeCommandWithTwoArg("JZERO",regValD,to_string(linesNo+2));
            writeCommandWithArg("JUMP",to_string(linesNo-9));
            divReg = regValC;
            modReg = regValA;
            freeReg(regValB);
            freeReg(regValD);
            freeReg(regValE);
        }
        else{
            cout << "zrzut pamieci" << endl;
            exit(1);
        }
        
    }
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
void freeReg(string str){
    char c = str.at(0);
    int i = (int)c -65;
    reg[i] = "";

}
void writeCommand(string str) {
    code.push_back(str);
    linesNo++;
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
        writeCommand(genNum.at(i));
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
    linesNo = 0;

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
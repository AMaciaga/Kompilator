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
extern FILE *yyin;
int yyerror(const string str);

typedef struct {
    bool init;
    bool isLocal;
	string name;
    string type; 
  	long long int size; // 0 forn non array variables
    long long int startsAt; // 0 forn non array variables
    long long int memPlace;
} id;
typedef struct{
    string name; // "" when not needed
    long long int currLineNo;
    string counter; // "" when not needed
}loop;
long long int linesNo;
long long int memAssign;
vector<string> code;
vector<id> vars;
vector<loop> loops;
string reg[8];
bool isCurrAssign=true;
id assignedVar;
string assignedVarInd;
string expVal[2]={"-1","-1"};
string expInd[2]={"-1","-1"};
string divReg;
string modReg;
string expReg;
void setIndex(long long int mem);
void setIndexForTab(id tab, string ind);
void writeCommandWithArg(string com,string arg);
void writeCommandWithTwoArg(string com,string arg1,string arg2);
string findEmptyReg();
void freeReg(string str);
void addVariable(id s);
void removeVariable(id s);
void createVariable(id* s,string name, string type, long long int size,long long int startsAt, long long int mem, bool init,bool isLocal );
void createLoop(loop* l,string name,long long int currLineNo,string counter);
void generateNumber(long long int arg,string r);
void writeCommand(string str);
void replaceJump(long long int curr, string prev);
void outCode(string file);
long long int findIndexOf(vector<id> v, string name);
void add(id a, id b);
void addTab(id a, id b, string aInd, string bInd);
void addCode(string regValA,string regValB);
void sub(id a, id b,bool isInc);
void subTab(id a, id b, string aInd, string bInd,bool isInc);
void subCode(string regValA,string regValB,bool isInc);
void mult(id a, id b);
void multTab(id a, id b, string aInd, string bInd);
void multCode(string regValA,string regValB,string regValC);
void div(id a, id b);
void divTab(id a, id b, string aInd, string bInd);
void divCode(string regValA,string regValB,string regValC,string regValD,string regValE);
void eq(id a, id b);
void eqTab(id a, id b, string aInd, string bInd);
void eqCode(string regValA,string regValB,string regValC);
void neq(id a, id b);
void neqTab(id a, id b, string aInd, string bInd);
void neqCode(string regValA,string regValB,string regValC);
void lt(id a, id b);
void ltTab(id a, id b, string aInd, string bInd);
void ltCode(string regValA,string regValB);
void gt(id a, id b);
void gtTab(id a, id b, string aInd, string bInd);
void gtCode(string regValA,string regValB);
void le(id a, id b);
void leTab(id a, id b, string aInd, string bInd);
void leCode(string regValA,string regValB);
void ge(id a, id b);
void geTab(id a, id b, string aInd, string bInd);
void geCode(string regValA,string regValB);

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
            createVariable(&s,$2,"ID",0,0,memAssign,false,false);
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
            createVariable(&s,$2,"ARR",size,atoi($4),memAssign,false,false);
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
            setIndexForTab(assignedVar,assignedVarInd);
            writeCommandWithArg("STORE",expReg);
        }
        else{
            setIndex(assignedVar.memPlace);
            writeCommandWithArg("STORE",expReg);
        }
        freeReg(expReg);
        vars.at(findIndexOf(vars,assignedVar.name)).init=true;
        isCurrAssign=true;
    }
    | IF {isCurrAssign = false;} condition THEN{
        writeCommandWithTwoArg("JZERO",expReg,to_string(linesNo+2));
        freeReg(expReg);
        loop l;
        createLoop(&l,"",linesNo,"");
        loops.push_back(l);
        writeCommandWithArg("JUMP",to_string(-linesNo));
        isCurrAssign= true;
        } commands ifcond
    | whileloop DO{
        writeCommandWithTwoArg("JZERO",expReg,to_string(linesNo+2));
        freeReg(expReg);
        loop l;
        createLoop(&l,"",linesNo,"");
        loops.push_back(l);
        writeCommandWithArg("JUMP",to_string(-linesNo));
        isCurrAssign= true;
    } commands ENDWHILE {
        loop l = loops.back();
        loops.pop_back();
        replaceJump(linesNo+1,to_string(-l.currLineNo));
        l = loops.back();
        loops.pop_back();
        writeCommandWithArg("JUMP",to_string(l.currLineNo));
    }
    | DO{
        loop l;
        createLoop(&l,"",linesNo,"");
        loops.push_back(l);
    } commands whileloop ENDDO {
        loops.pop_back();
        loop l = loops.back();
        loops.pop_back();
        writeCommandWithTwoArg("JZERO",expReg,to_string(l.currLineNo));
        freeReg(expReg);
        isCurrAssign =true;
    }
    | FOR pidentifier{
        if(findIndexOf(vars,$<str>2)!= -1) {
            cout << "Błąd [linia: " << yylineno \
            << "]: Kolejna deklaracja zmiennej " << $<str>2 << "." << endl;
            exit(1);
        }
        else {
            id s;
            createVariable(&s,$2,"ID",0,0,memAssign,false,true);
            memAssign++;
            addVariable(s);
        }
        isCurrAssign = false;
        assignedVar = vars.at(findIndexOf(vars,$<str>2));

    } FROM value forloop 
    | READ identifier SEM {
        if(assignedVar.type == "ARR"){
            string regVal = findEmptyReg();
            if(regVal != "X"){
                writeCommandWithArg("GET",regVal);
                setIndexForTab(assignedVar,assignedVarInd);
                writeCommandWithArg("STORE",regVal);
                freeReg(regVal);
            }
            else{
                cout << "zrzut pamieci"<<yylineno << endl;
                exit(1);
            }
        }
        else{
            string regVal = findEmptyReg();
            if(regVal != "X"){
                writeCommandWithArg("GET",regVal);
                setIndex(assignedVar.memPlace);
                writeCommandWithArg("STORE",regVal);
                freeReg(regVal);
            }
            else{
                cout << "zrzut pamieci"<<yylineno << endl;
                exit(1);
            }
        }
        vars.at(findIndexOf(vars,assignedVar.name)).init=true;
        isCurrAssign=true;
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
                cout << "zrzut pamieci"<<yylineno << endl;
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
                cout << "zrzut pamieci"<<yylineno << endl;
                exit(1);
            }
        }
        else{
            string regVal = findEmptyReg();
            if(regVal != "X"){
                setIndexForTab(arg,expInd[0]);
                writeCommandWithArg("LOAD",regVal);
                expReg = regVal;
            }
            else{
                cout << "zrzut pamieci"<<yylineno << endl;
                exit(1);
            }
        }
        expVal[0] = "-1";
        expInd[0]= "-1";


        writeCommandWithArg("PUT",expReg);
        freeReg(expReg);
        isCurrAssign=true;
    } ;
whileloop:
    WHILE{
        loop l;
        createLoop(&l,"",linesNo,"");
        loops.push_back(l);
        isCurrAssign = false;
    } condition
;
forloop:
    TO value DO {
        id a = vars.at(findIndexOf(vars,expVal[0]));
        id b = vars.at(findIndexOf(vars,expVal[1]));
        string regVal = findEmptyReg();
        if(regVal != "X"){
            if(a.type == "NUM") {
                generateNumber(atoi(a.name.c_str()),regVal);
            }
            else if(a.type == "ID") {
                setIndex(a.memPlace);
                writeCommandWithArg("LOAD",regVal);
            }
            else {
                setIndexForTab(a,expInd[0]);
                writeCommandWithArg("LOAD",regVal);
            }
            setIndex(assignedVar.memPlace);
            writeCommandWithArg("STORE",regVal);
            freeReg(regVal);
            vars.at(findIndexOf(vars,assignedVar.name)).init=true;
        }
        else{
            cout << "zrzut pamieci"<<yylineno << endl;
            exit(1);
        }
        if(a.type != "ARR" && b.type != "ARR")
            sub(b, a,true);
        else{
            subTab(b,a,expInd[1],expInd[0],true);
        }
        id s;
        string name = "C" + to_string(linesNo);
        createVariable(&s,name,"ID",0,0,memAssign,true,true);
        memAssign++;
        addVariable(s);
        setIndex(s.memPlace);
        writeCommandWithArg("STORE",expReg);
        freeReg(expReg);
        long long int currLineNo = linesNo;
        regVal = findEmptyReg();
        if(regVal != "X"){
            loop l;
            createLoop(&l,assignedVar.name,currLineNo,s.name);
            loops.push_back(l);
            setIndex(s.memPlace);
            writeCommandWithArg("LOAD",regVal);
            writeCommandWithTwoArg("JZERO",regVal,to_string(-currLineNo));
        }
        else{
            cout << "zrzut pamieci"<<yylineno << endl;
            exit(1);
        }  
        expVal[0] = "-1";
        expVal[1] = "-1";
        expInd[0]= "-1";
        expInd[1]= "-1";
        isCurrAssign=true;

        
    }commands ENDFOR {
        loop l = loops.back();
        loops.pop_back();
        
        string regVal = findEmptyReg();
        if(regVal != "X"){
            id a = vars.at(findIndexOf(vars,l.name));
            setIndex(a.memPlace);
            writeCommandWithArg("LOAD",regVal);
            writeCommandWithArg("INC",regVal);
            writeCommandWithArg("STORE",regVal);
            removeVariable(a);
            a = vars.at(findIndexOf(vars,l.counter));
            setIndex(a.memPlace);
            writeCommandWithArg("LOAD",regVal);
            writeCommandWithArg("DEC",regVal);
            writeCommandWithArg("STORE",regVal);
            removeVariable(a);
            freeReg(regVal);
            writeCommandWithArg("JUMP",to_string(l.currLineNo));
            replaceJump(linesNo,to_string(-l.currLineNo));
            
            
        } 
        else{
            cout << "zrzut pamieci"<<yylineno << endl;
            exit(1);
        }

    }
    | DOWNTO value DO{
        id a = vars.at(findIndexOf(vars,expVal[0]));
        id b = vars.at(findIndexOf(vars,expVal[1]));
        string regVal = findEmptyReg();
        if(regVal != "X"){
            if(a.type == "NUM") {
                generateNumber(atoi(a.name.c_str()),regVal);
            }
            else if(a.type == "ID") {
                setIndex(a.memPlace);
                writeCommandWithArg("LOAD",regVal);
            }
            else {
                setIndexForTab(a,expInd[0]);
                writeCommandWithArg("LOAD",regVal);
            }
            setIndex(assignedVar.memPlace);
            writeCommandWithArg("STORE",regVal);
            freeReg(regVal);
            vars.at(findIndexOf(vars,assignedVar.name)).init=true;
        }
        else{
            cout << "zrzut pamieci"<<yylineno << endl;
            exit(1);
        }
        if(a.type != "ARR" && b.type != "ARR")
            sub(a,b,true);
        else{
            subTab(a,b,expInd[0],expInd[1],true);
        }
        id s;
        string name = "C" + to_string(linesNo);
        createVariable(&s,name,"ID",0,0,memAssign,true,true);
        memAssign++;
        addVariable(s);
        setIndex(s.memPlace);
        writeCommandWithArg("STORE",expReg);
        freeReg(expReg);
        long long int currLineNo = linesNo;
        regVal = findEmptyReg();
        if(regVal != "X"){
            loop l;
            createLoop(&l,assignedVar.name,currLineNo,s.name);
            loops.push_back(l);
            setIndex(s.memPlace);
            writeCommandWithArg("LOAD",regVal);
            writeCommandWithTwoArg("JZERO",regVal,to_string(-currLineNo));
        }
        else{
            cout << "zrzut pamieci"<<yylineno << endl;
            exit(1);
        }  
        expVal[0] = "-1";
        expVal[1] = "-1";
        expInd[0]= "-1";
        expInd[1]= "-1";
        isCurrAssign=true;
    } commands ENDFOR{
        loop l = loops.back();
        loops.pop_back();
        
        string regVal = findEmptyReg();
        if(regVal != "X"){
            id a = vars.at(findIndexOf(vars,l.name));
            setIndex(a.memPlace);
            writeCommandWithArg("LOAD",regVal);
            writeCommandWithArg("DEC",regVal);
            writeCommandWithArg("STORE",regVal);
            removeVariable(a);
            a = vars.at(findIndexOf(vars,l.counter));
            setIndex(a.memPlace);
            writeCommandWithArg("LOAD",regVal);
            writeCommandWithArg("DEC",regVal);
            writeCommandWithArg("STORE",regVal);
            removeVariable(a);
            freeReg(regVal);
            writeCommandWithArg("JUMP",to_string(l.currLineNo));
            replaceJump(linesNo,to_string(-l.currLineNo));
            
            
        } 
        else{
            cout << "zrzut pamieci"<<yylineno << endl;
            exit(1);
        }
    }
;
ifcond: 
    ENDIF{
        loop l = loops.back();
        loops.pop_back();
        replaceJump(linesNo,to_string(-l.currLineNo));

    }
    | ELSE{
        loop l = loops.back();
        loops.pop_back();
        replaceJump(linesNo+1,to_string(-l.currLineNo));
        createLoop(&l,"",linesNo,"");
        loops.push_back(l);
        writeCommandWithArg("JUMP",to_string(-linesNo));
    } commands ENDIF{
        loop l = loops.back();
        loops.pop_back();
        replaceJump(linesNo,to_string(-l.currLineNo));
    }

;
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
                cout << "zrzut pamieci"<<yylineno << endl;
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
                cout << "zrzut pamieci"<<yylineno << endl;
                exit(1);
            }
        }
        else{
            string regVal = findEmptyReg();
            if(regVal != "X"){
                setIndexForTab(arg,expInd[0]);
                writeCommandWithArg("LOAD",regVal);
                expReg = regVal;
            }
            else{
                cout << "zrzut pamieci"<<yylineno << endl;
                exit(1);
            }
        }
        expVal[0] = "-1";
        expInd[0] = "-1";
    }
    | value ADD value {
        id a = vars.at(findIndexOf(vars,expVal[0]));
        id b = vars.at(findIndexOf(vars,expVal[1]));
        if(a.type != "ARR" && b.type != "ARR")
            add(a, b);
        else{
            addTab(a,b,expInd[0],expInd[1]);
        }
        expVal[0] = "-1";
        expVal[1] = "-1";
        expInd[0]= "-1";
        expInd[1]= "-1";
    }
    | value SUB value {
        id a = vars.at(findIndexOf(vars,expVal[0]));
        id b = vars.at(findIndexOf(vars,expVal[1]));
        if(a.type != "ARR" && b.type != "ARR")
            sub(a, b,false);
        else{
            subTab(a,b,expInd[0],expInd[1],false);
        }
        expVal[0] = "-1";
        expVal[1] = "-1";
        expInd[0]= "-1";
        expInd[1]= "-1";
    }
    | value MUL value {
        id a = vars.at(findIndexOf(vars,expVal[0]));
        id b = vars.at(findIndexOf(vars,expVal[1]));
        if(a.type != "ARR" && b.type != "ARR")
            mult(a, b);
        else{
            multTab(a,b,expInd[0],expInd[1]);
        }
        expVal[0] = "-1";
        expVal[1] = "-1";
        expInd[0]= "-1";
        expInd[1]= "-1";
    }
    | value DIV value {
        id a = vars.at(findIndexOf(vars,expVal[0]));
        id b = vars.at(findIndexOf(vars,expVal[1]));
        if(a.type != "ARR" && b.type != "ARR"){
            div(a, b);
            expReg = divReg;
            freeReg(modReg);
        }
        else{
            divTab(a,b,expInd[0],expInd[1]);
            expReg = divReg;
            freeReg(modReg);
        }
        expVal[0] = "-1";
        expVal[1] = "-1";
        expInd[0]= "-1";
        expInd[1]= "-1";
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
            divTab(a,b,expInd[0],expInd[1]);
            expReg = modReg;
            freeReg(divReg);
        }
        expVal[0] = "-1";
        expVal[1] = "-1";
        expInd[0]= "-1";
        expInd[1]= "-1";
    };

condition:   
    value EQ value {
        id a = vars.at(findIndexOf(vars,expVal[0]));
        id b = vars.at(findIndexOf(vars,expVal[1]));
        if(a.type != "ARR" && b.type != "ARR")
            eq(a, b);
        else{
            eqTab(a,b,expInd[0],expInd[1]);
        }
        expVal[0] = "-1";
        expVal[1] = "-1";
        expInd[0]= "-1";
        expInd[1]= "-1"; 
    }
    | value NE value {
        id a = vars.at(findIndexOf(vars,expVal[0]));
        id b = vars.at(findIndexOf(vars,expVal[1]));
        if(a.type != "ARR" && b.type != "ARR")
            neq(a, b);
        else{
            neqTab(a,b,expInd[0],expInd[1]);
        }
        expVal[0] = "-1";
        expVal[1] = "-1";
        expInd[0]= "-1";
        expInd[1]= "-1"; 
    }
    | value LT value {
        id a = vars.at(findIndexOf(vars,expVal[0]));
        id b = vars.at(findIndexOf(vars,expVal[1]));
        if(a.type != "ARR" && b.type != "ARR")
            lt(a, b);
        else{
            ltTab(a,b,expInd[0],expInd[1]);
        }
        expVal[0] = "-1";
        expVal[1] = "-1";
        expInd[0]= "-1";
        expInd[1]= "-1"; 
    }
    | value GT value {
        id a = vars.at(findIndexOf(vars,expVal[0]));
        id b = vars.at(findIndexOf(vars,expVal[1]));
        if(a.type != "ARR" && b.type != "ARR")
            gt(a, b);
        else{
            gtTab(a,b,expInd[0],expInd[1]);
        }
        expVal[0] = "-1";
        expVal[1] = "-1";
        expInd[0]= "-1";
        expInd[1]= "-1"; 
    }
    | value LE value {
        id a = vars.at(findIndexOf(vars,expVal[0]));
        id b = vars.at(findIndexOf(vars,expVal[1]));
        if(a.type != "ARR" && b.type != "ARR")
            le(a, b);
        else{
            leTab(a,b,expInd[0],expInd[1]);
        }
        expVal[0] = "-1";
        expVal[1] = "-1";
        expInd[0]= "-1";
        expInd[1]= "-1"; 
    }
    | value GE value {
        id a = vars.at(findIndexOf(vars,expVal[0]));
        id b = vars.at(findIndexOf(vars,expVal[1]));
        if(a.type != "ARR" && b.type != "ARR")
            ge(a, b);
        else{
            geTab(a,b,expInd[0],expInd[1]);
        }
        expVal[0] = "-1";
        expVal[1] = "-1";
        expInd[0]= "-1";
        expInd[1]= "-1"; 
    };

value:       
    num {
        if(isCurrAssign){
            cout << "Błąd [linia: " << yylineno \
            << "]: " << $<str>1 << " nie jest zmienna." << endl;
            exit(1);
        }
        id s;
        createVariable(&s,$1,"NUM",0,0,memAssign,true,false);
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
                if(vars.at(index).isLocal){
                    cout << "Błąd linia " << yylineno << \
                    "]: Próba modyfikacji iteratora pętli." << endl;
                    exit(1);
                }
                assignedVar = vars.at(index);
            }
        }
        else{
            cout << "Błąd [linia: " << yylineno \
                    << "]: Niepoprawne uzycie zmiennej tablicowej " << $<str>1 << "." << endl;
                    exit(1);
        }
        
    }   
    | pidentifier LB pidentifier RB {

        long long int index1 = findIndexOf(vars,$<str>1);
        if( index1 == -1) {
            cout << "Błąd [linia: " << yylineno \
            << "]: Proba skorzystania z niezadeklarowanej zmiennej " << $<str>1 << "." << endl;
            exit(1);
        }
        long long int index2 = findIndexOf(vars,$<str>3);
        if( index2 == -1) {
            cout << "Błąd [linia: " << yylineno \
            << "]: Proba skorzystania z niezadeklarowanej zmiennej " << $<str>3 << "." << endl;
            exit(1);
        }
        
        if(vars.at(index1).type != "ARR") {
            cout << "Błąd [linia " << yylineno << \
            "]: Zmienna " << $1 << " nie jest tablicą." << endl;
            exit(1);
        }
        else {
            if(!vars.at(index2).init ) {
                cout << "Błąd [linia " << yylineno << \
                "]: Próba użycia niezainicjalizowanej zmiennej " << $3 << "." << endl;
                exit(1);
            }

            if(!isCurrAssign){
                if (expVal[0] == "-1"){
                    expVal[0] = $1;
                    expInd[0] = $3;
                }
                else{
                    expVal[1] = $1;
                    expInd[1] = $3;
                }

            }
            else {
                assignedVar = vars.at(index1);
                assignedVarInd = $3;
            }
        }
    }
    | pidentifier LB num RB {
        long long int index1 = findIndexOf(vars,$<str>1);
        if( index1 == -1) {
            cout << "Błąd [linia: " << yylineno \
            << "]: Proba skorzystania z niezadeklarowanej zmiennej " << $<str>1 << "." << endl;
            exit(1);
        }

        if(vars.at(index1).type != "ARR") {
            cout << "Błąd [linia " << yylineno << \
            "]: Zmienna " << $1 << " nie jest tablicą." << endl;
            exit(1);
        }
        else {
            id s;
            createVariable(&s,$3,"NUM",0,0,memAssign,true,false);
            memAssign++;
            addVariable(s);

            
            if(!isCurrAssign){
                
                if (expVal[0] == "-1"){
                    expVal[0] = $1;
                    expInd[0] = $3;
                }
                else{
                    expVal[1] = $1;
                    expInd[1] = $3;
                }

            }
            else {
                assignedVar = vars.at(index1);
                assignedVarInd = $3;
            }
        }
    };
num:
    NUM;

pidentifier:
    IDENTIFIER;
%%
void setIndex(long long int mem){
    generateNumber(mem,"A");
}
void setIndexForTab(id tab, string ind){
    id index = vars.at(findIndexOf(vars,ind));
    if(index.type == "NUM"){
        string regValA = findEmptyReg();
        if(regValA != "X" ){
            generateNumber(atoi(index.name.c_str()),regValA);
            setIndex(tab.memPlace);
            writeCommandWithTwoArg("ADD","A",regValA);
            generateNumber(tab.startsAt,regValA);
            writeCommandWithTwoArg("SUB","A",regValA);
            freeReg(regValA);
        }
        else{
            cout << "zrzut pamieci 4 "<<yylineno << endl;
            exit(1);
        }
        
    }
    else if(index.type == "ID"){
        string regValA = findEmptyReg();
        if(regValA != "X"  ){
            setIndex(index.memPlace);
            writeCommandWithArg("LOAD",regValA);
            setIndex(tab.memPlace);
            writeCommandWithTwoArg("ADD","A",regValA);
            generateNumber(tab.startsAt,regValA);
            writeCommandWithTwoArg("SUB","A",regValA);
            freeReg(regValA);
        }
        else{
            cout << "zrzut pamieci 5 " <<yylineno << endl;
            exit(1);
        }
        
    }

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
void addCode(string regValA,string regValB){
    writeCommandWithTwoArg("ADD",regValA,regValB);
}
void add(id a, id b){

    if(a.type == "NUM" && b.type == "NUM") {
        string regValA = findEmptyReg();
        string regValB = findEmptyReg();
        if(regValA != "X" && regValB != "X"  ){
            generateNumber(atoi(a.name.c_str()),regValA);
            generateNumber(atoi(b.name.c_str()),regValB);
            addCode(regValA,regValB);
            expReg = regValA;
            freeReg(regValB);
        }
        else{
            cout << "zrzut pamieci"<<yylineno << endl;
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
            addCode(regValA,regValB);
            expReg = regValA;
            freeReg(regValB);
        }
        else{
            cout << "zrzut pamieci"<<yylineno << endl;
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
            addCode(regValA,regValB);
            expReg = regValA;
            freeReg(regValB);
        }
        else{
            cout << "zrzut pamieci"<<yylineno << endl;
            exit(1);
        }
    }
    else if(a.type == "ID" && b.type == "ID") {
        if(a.name == b.name) {
            string regValA = findEmptyReg();
            if(regValA != "X" ){
                setIndex(a.memPlace);
                writeCommandWithArg("LOAD",regValA);
                addCode(regValA,regValA);
                expReg = regValA;
            }
            else{
                cout << "zrzut pamieci"<<yylineno << endl;
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
                addCode(regValA,regValB);
                expReg = regValA;
                freeReg(regValB);
            }
            else{
                cout << "zrzut pamieci"<<yylineno << endl;
                exit(1);
            }
        }
    }
}
void addTab(id a, id b, string aInd, string bInd){
    if(a.type == "ARR" && b.type == "NUM") {
        string regValA = findEmptyReg();
        string regValB = findEmptyReg();
        if(regValA != "X" && regValB != "X"  ){
            setIndexForTab(a,aInd);
            writeCommandWithArg("LOAD",regValA);
            generateNumber(atoi(b.name.c_str()),regValB);
            addCode(regValA,regValB);
            expReg = regValA;
            freeReg(regValB);
        }
        else{
            cout << "zrzut pamieci"<<yylineno << endl;
            exit(1);
        }
        
    }
    else if(a.type == "NUM" && b.type == "ARR") {
        string regValA = findEmptyReg();
        string regValB = findEmptyReg();
        if(regValA != "X" && regValB != "X"  ){
            generateNumber(atoi(a.name.c_str()),regValA);
            setIndexForTab(b,bInd);
            writeCommandWithArg("LOAD",regValB);
            addCode(regValA,regValB);
            expReg = regValA;
            freeReg(regValB);
        }
        else{
            cout << "zrzut pamieci"<<yylineno << endl;
            exit(1);
        }
    }
    else if(a.type == "ID" && b.type == "ARR") {
        string regValA = findEmptyReg();
        string regValB = findEmptyReg();
        if(regValA != "X" && regValB != "X"  ){
            setIndex(a.memPlace);
            writeCommandWithArg("LOAD",regValA);
            setIndexForTab(b,bInd);
            writeCommandWithArg("LOAD",regValB);
            addCode(regValA,regValB);
            expReg = regValA;
            freeReg(regValB);
        }
        else{
            cout << "zrzut pamieci"<<yylineno << endl;
            exit(1);
        }
    }
    else if(a.type == "ARR" && b.type == "ID") {
        string regValA = findEmptyReg();
        string regValB = findEmptyReg();
        if(regValA != "X" && regValB != "X"  ){
            setIndex(b.memPlace);
            writeCommandWithArg("LOAD",regValB);
            setIndexForTab(a,aInd);
            writeCommandWithArg("LOAD",regValA);
            addCode(regValA,regValB);
            expReg = regValA;
            freeReg(regValB);
        }
        else{
            cout << "zrzut pamieci"<<yylineno << endl;
            exit(1);
        }
    }
    else if(a.type == "ARR" && b.type == "ARR") {
        if(a.name == b.name && aInd == bInd) {
            string regValA = findEmptyReg();
            if(regValA != "X" ){
                setIndexForTab(a,aInd);
                writeCommandWithArg("LOAD",regValA);
                addCode(regValA,regValA);
                expReg = regValA;
            }
            else{
                cout << "zrzut pamieci"<<yylineno << endl;
                exit(1);
            }
        }
        else {
            string regValA = findEmptyReg();
            string regValB = findEmptyReg();
            if(regValA != "X" && regValB != "X"  ){
                setIndexForTab(a,aInd);
                writeCommandWithArg("LOAD",regValA);
                setIndexForTab(b,bInd);
                writeCommandWithArg("LOAD",regValB);
                addCode(regValA,regValB);
                expReg = regValA;
                freeReg(regValB);
            }
            else{
                cout << "zrzut pamieci"<<yylineno << endl;
                exit(1);
            }
        }
    }

}

void subCode(string regValA,string regValB,bool isInc){
    if(isInc){
        writeCommandWithArg("INC",regValA);
    }
    writeCommandWithTwoArg("SUB",regValA,regValB);
}

void sub(id a, id b,bool isInc){

    if(a.type == "NUM" && b.type == "NUM") {
        string regValA = findEmptyReg();
        string regValB = findEmptyReg();
        if(regValA != "X" && regValB != "X"  ){
            generateNumber(atoi(a.name.c_str()),regValA);
            generateNumber(atoi(b.name.c_str()),regValB);
            subCode(regValA,regValB,isInc);
            expReg = regValA;
            freeReg(regValB);
        }
        else{
            cout << "zrzut pamieci"<<yylineno << endl;
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
            subCode(regValA,regValB,isInc);
            expReg = regValA;
            freeReg(regValB);
        }
        else{
            cout << "zrzut pamieci"<<yylineno << endl;
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
            subCode(regValA,regValB,isInc);
            expReg = regValA;
            freeReg(regValB);
        }
        else{
            cout << "zrzut pamieci"<<yylineno << endl;
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
                if(isInc){
                    writeCommandWithArg("INC",regValA);
                }
                expReg = regValA;
            }
            else{
                cout << "zrzut pamieci"<<yylineno << endl;
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
                subCode(regValA,regValB,isInc);
                expReg = regValA;
                freeReg(regValB);
            }
            else{
                cout << "zrzut pamieci"<<yylineno << endl;
                exit(1);
            }
        }
    }
}

void subTab(id a, id b, string aInd, string bInd,bool isInc){
    if(a.type == "ARR" && b.type == "NUM") {
        string regValA = findEmptyReg();
        string regValB = findEmptyReg();
        if(regValA != "X" && regValB != "X"  ){
            setIndexForTab(a,aInd);
            writeCommandWithArg("LOAD",regValA);
            generateNumber(atoi(b.name.c_str()),regValB);
            subCode(regValA,regValB,isInc);
            expReg = regValA;
            freeReg(regValB);
        }
        else{
            cout << "zrzut pamieci"<<yylineno << endl;
            exit(1);
        }
        
    }
    else if(a.type == "NUM" && b.type == "ARR") {
        string regValA = findEmptyReg();
        string regValB = findEmptyReg();
        if(regValA != "X" && regValB != "X"  ){
            generateNumber(atoi(a.name.c_str()),regValA);
            setIndexForTab(b,bInd);
            writeCommandWithArg("LOAD",regValB);
            subCode(regValA,regValB,isInc);
            expReg = regValA;
            freeReg(regValB);
        }
        else{
            cout << "zrzut pamieci"<<yylineno << endl;
            exit(1);
        }
    }
    else if(a.type == "ID" && b.type == "ARR") {
        string regValA = findEmptyReg();
        string regValB = findEmptyReg();
        if(regValA != "X" && regValB != "X"  ){
            setIndex(a.memPlace);
            writeCommandWithArg("LOAD",regValA);
            setIndexForTab(b,bInd);
            writeCommandWithArg("LOAD",regValB);
            subCode(regValA,regValB,isInc);
            expReg = regValA;
            freeReg(regValB);
        }
        else{
            cout << "zrzut pamieci"<<yylineno << endl;
            exit(1);
        }
    }
    else if(a.type == "ARR" && b.type == "ID") {
        string regValA = findEmptyReg();
        string regValB = findEmptyReg();
        if(regValA != "X" && regValB != "X"  ){
            setIndex(b.memPlace);
            writeCommandWithArg("LOAD",regValB);
            setIndexForTab(a,aInd);
            writeCommandWithArg("LOAD",regValA);
            subCode(regValA,regValB,isInc);
            expReg = regValA;
            freeReg(regValB);
        }
        else{
            cout << "zrzut pamieci"<<yylineno << endl;
            exit(1);
        }
    }
    else if(a.type == "ARR" && b.type == "ARR") {
        if(a.name == b.name && aInd == bInd) {
            string regValA = findEmptyReg();
            if(regValA != "X" ){
                setIndexForTab(a,aInd);
                writeCommandWithArg("LOAD",regValA);
                writeCommandWithTwoArg("SUB",regValA,regValA);
                if(isInc){
                    writeCommandWithArg("INC",regValA);
                }
                expReg = regValA;
            }
            else{
                cout << "zrzut pamieci"<<yylineno << endl;
                exit(1);
            }
        }
        else {
            string regValA = findEmptyReg();
            string regValB = findEmptyReg();
            if(regValA != "X" && regValB != "X"  ){
                setIndexForTab(a,aInd);
                writeCommandWithArg("LOAD",regValA);
                setIndexForTab(b,bInd);
                writeCommandWithArg("LOAD",regValB);
                subCode(regValA,regValB,isInc);
                expReg = regValA;
                freeReg(regValB);
            }
            else{
                cout << "zrzut pamieci"<<yylineno << endl;
                exit(1);
            }
        }
    }

}
void multCode(string regValA,string regValB,string regValC){
    writeCommandWithTwoArg("SUB",regValC,regValC);
    writeCommandWithTwoArg("JZERO",regValA,to_string(linesNo+7));
    writeCommandWithTwoArg("JODD",regValA,to_string(linesNo+2));
    writeCommandWithArg("JUMP",to_string(linesNo+2));
    writeCommandWithTwoArg("ADD",regValC,regValB);
    writeCommandWithArg("HALF",regValA);
    writeCommandWithTwoArg("ADD",regValB,regValB);
    writeCommandWithArg("JUMP",to_string(linesNo-6));
}
void mult(id a, id b){

    if(a.type == "NUM" && b.type == "NUM") {
        string regValA = findEmptyReg();
        string regValB = findEmptyReg();
        string regValC = findEmptyReg();
        if(regValA != "X" && regValB != "X" && regValC != "X"  ){
            generateNumber(atoi(a.name.c_str()),regValA);
            generateNumber(atoi(b.name.c_str()),regValB);
            multCode(regValA,regValB,regValC);
            expReg = regValC;
            freeReg(regValA);
            freeReg(regValB);
        }
        else{
            cout << "zrzut pamieci"<<yylineno << endl;
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
            multCode(regValA,regValB,regValC);
            freeReg(regValA);
            freeReg(regValB);
        }
        else{
            cout << "zrzut pamieci"<<yylineno << endl;
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
            multCode(regValA,regValB,regValC);
            expReg = regValC;
            freeReg(regValA);
            freeReg(regValB);
        }
        else{
            cout << "zrzut pamieci"<<yylineno << endl;
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
            multCode(regValA,regValB,regValC);
            expReg = regValC;
            freeReg(regValA);
            freeReg(regValB);
        }
        else{
            cout << "zrzut pamieci"<<yylineno << endl;
            exit(1);
        }
        
    }
}
void multTab(id a, id b, string aInd, string bInd){
    if(a.type == "ARR" && b.type == "NUM") {
        string regValA = findEmptyReg();
        string regValB = findEmptyReg();
        string regValC = findEmptyReg();
        if(regValA != "X" && regValB != "X" && regValC != "X"  ){
            setIndexForTab(a,aInd);
            writeCommandWithArg("LOAD",regValA);
            generateNumber(atoi(b.name.c_str()),regValB);
            multCode(regValA,regValB,regValC);
            expReg = regValC;
            freeReg(regValA);
            freeReg(regValB);
        }
        else{
            cout << "zrzut pamieci"<<yylineno << endl;
            exit(1);
        }
        
    }
    else if(a.type == "NUM" && b.type == "ARR") {
        string regValA = findEmptyReg();
        string regValB = findEmptyReg();
        string regValC = findEmptyReg();
        if(regValA != "X" && regValB != "X"&& regValC != "X"   ){
            generateNumber(atoi(a.name.c_str()),regValA);
            setIndexForTab(b,bInd);
            writeCommandWithArg("LOAD",regValB);
            multCode(regValA,regValB,regValC);
            expReg = regValC;
            freeReg(regValA);
            freeReg(regValB);
        }
        else{
            cout << "zrzut pamieci"<<yylineno << endl;
            exit(1);
        }
    }
    else if(a.type == "ID" && b.type == "ARR") {
        string regValA = findEmptyReg();
        string regValB = findEmptyReg();
        string regValC = findEmptyReg();
        if(regValA != "X" && regValB != "X"  && regValC != "X" ){
            setIndex(a.memPlace);
            writeCommandWithArg("LOAD",regValA);
            setIndexForTab(b,bInd);
            writeCommandWithArg("LOAD",regValB);
            multCode(regValA,regValB,regValC);
            expReg = regValC;
            freeReg(regValA);
            freeReg(regValB);
        }
        else{
            cout << "zrzut pamieci"<<yylineno << endl;
            exit(1);
        }
    }
    else if(a.type == "ARR" && b.type == "ID") {
        string regValA = findEmptyReg();
        string regValB = findEmptyReg();
        string regValC = findEmptyReg();
        if(regValA != "X" && regValB != "X" && regValC != "X"  ){
            setIndex(b.memPlace);
            writeCommandWithArg("LOAD",regValB);
            setIndexForTab(a,aInd);
            writeCommandWithArg("LOAD",regValA);
            multCode(regValA,regValB,regValC);
            expReg = regValC;
            freeReg(regValA);
            freeReg(regValB);
        }
        else{
            cout << "zrzut pamieci"<<yylineno << endl;
            exit(1);
        }
    }
    else if(a.type == "ARR" && b.type == "ARR") {
        
        string regValA = findEmptyReg();
        string regValB = findEmptyReg();
        string regValC = findEmptyReg();
        if(regValA != "X" && regValB != "X" && regValC != "X"  ){
            setIndexForTab(a,aInd);
            writeCommandWithArg("LOAD",regValA);
            setIndexForTab(b,bInd);
            writeCommandWithArg("LOAD",regValB);
            multCode(regValA,regValB,regValC);
            expReg = regValC;
            freeReg(regValA);
            freeReg(regValB);
        }
        else{
            cout << "zrzut pamieci"<<yylineno << endl;
            exit(1);
        }
        
    }

}
void divCode(string regValA,string regValB,string regValC,string regValD,string regValE){
    writeCommandWithTwoArg("JZERO",regValB,to_string(linesNo+21));
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
    writeCommandWithArg("JUMP",to_string(linesNo+3));
    writeCommandWithTwoArg("SUB", regValA,regValA);
    writeCommandWithTwoArg("SUB",regValC,regValC);
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
            divCode( regValA, regValB, regValC, regValD, regValE);
            divReg = regValC;
            modReg = regValA;
            freeReg(regValB);
            freeReg(regValD);
            freeReg(regValE);
        }
        else{
            cout << "zrzut pamieci"<<yylineno << endl;
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
            divCode( regValA, regValB, regValC, regValD, regValE);
            divReg = regValC;
            modReg = regValA;
            freeReg(regValB);
            freeReg(regValD);
            freeReg(regValE);
        }
        else{
            cout << "zrzut pamieci"<<yylineno << endl;
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
            divCode( regValA, regValB, regValC, regValD, regValE);
            divReg = regValC;
            modReg = regValA;
            freeReg(regValB);
            freeReg(regValD);
            freeReg(regValE);
        }
        else{
            cout << "zrzut pamieci"<<yylineno << endl;
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
            divCode( regValA, regValB, regValC, regValD, regValE);
            divReg = regValC;
            modReg = regValA;
            freeReg(regValB);
            freeReg(regValD);
            freeReg(regValE);
        }
        else{
            cout << "zrzut pamieci"<<yylineno << endl;
            exit(1);
        }
        
    }
}

void divTab(id a, id b, string aInd, string bInd){
    if(a.type == "ARR" && b.type == "NUM") {
        string regValA = findEmptyReg();
        string regValB = findEmptyReg();
        string regValC = findEmptyReg();
        string regValD = findEmptyReg();
        string regValE = findEmptyReg();
        if(regValA != "X" && regValB != "X" && regValC != "X" && regValD != "X" && regValE != "X" ){
            setIndexForTab(a,aInd);
            writeCommandWithArg("LOAD",regValA);
            generateNumber(atoi(b.name.c_str()),regValB);
            divCode( regValA, regValB, regValC, regValD, regValE);
            divReg = regValC;
            modReg = regValA;
            freeReg(regValB);
            freeReg(regValD);
            freeReg(regValE);
        }
        else{
            cout << "zrzut pamieci"<<yylineno << endl;
            exit(1);
        }
        
    }
    else if(a.type == "NUM" && b.type == "ARR") {
        string regValA = findEmptyReg();
        string regValB = findEmptyReg();
        string regValC = findEmptyReg();
        string regValD = findEmptyReg();
        string regValE = findEmptyReg();
        if(regValA != "X" && regValB != "X"&& regValC != "X"  && regValD != "X" && regValE != "X" ){
            generateNumber(atoi(a.name.c_str()),regValA);
            setIndexForTab(b,bInd);
            writeCommandWithArg("LOAD",regValB);
            divCode( regValA, regValB, regValC, regValD, regValE);
            divReg = regValC;
            modReg = regValA;
            freeReg(regValB);
            freeReg(regValD);
            freeReg(regValE);
        }
        else{
            cout << "zrzut pamieci"<<yylineno << endl;
            exit(1);
        }
    }
    else if(a.type == "ID" && b.type == "ARR") {
        string regValA = findEmptyReg();
        string regValB = findEmptyReg();
        string regValC = findEmptyReg();
        string regValD = findEmptyReg();
        string regValE = findEmptyReg();
        if(regValA != "X" && regValB != "X"  && regValC != "X" && regValD != "X" && regValE != "X"){
            setIndex(a.memPlace);
            writeCommandWithArg("LOAD",regValA);
            setIndexForTab(b,bInd);
            writeCommandWithArg("LOAD",regValB);
            divCode( regValA, regValB, regValC, regValD, regValE);
            divReg = regValC;
            modReg = regValA;
            freeReg(regValB);
            freeReg(regValD);
            freeReg(regValE);
        }
        else{
            cout << "zrzut pamieci"<<yylineno << endl;
            exit(1);
        }
    }
    else if(a.type == "ARR" && b.type == "ID") {
        string regValA = findEmptyReg();
        string regValB = findEmptyReg();
        string regValC = findEmptyReg();
        string regValD = findEmptyReg();
        string regValE = findEmptyReg();
        if(regValA != "X" && regValB != "X" && regValC != "X"  && regValD != "X" && regValE != "X"){
            setIndex(b.memPlace);
            writeCommandWithArg("LOAD",regValB);
            setIndexForTab(a,aInd);
            writeCommandWithArg("LOAD",regValA);
            divCode( regValA, regValB, regValC, regValD, regValE);
            divReg = regValC;
            modReg = regValA;
            freeReg(regValB);
            freeReg(regValD);
            freeReg(regValE);
        }
        else{
            cout << "zrzut pamieci"<<yylineno << endl;
            exit(1);
        }
    }
    else if(a.type == "ARR" && b.type == "ARR") {
        
        string regValA = findEmptyReg();
        string regValB = findEmptyReg();
        string regValC = findEmptyReg();
        string regValD = findEmptyReg();
        string regValE = findEmptyReg();
        if(regValA != "X" && regValB != "X" && regValC != "X" && regValD != "X" && regValE != "X" ){
            setIndexForTab(a,aInd);
            writeCommandWithArg("LOAD",regValA);
            setIndexForTab(b,bInd);
            writeCommandWithArg("LOAD",regValB);
            divCode( regValA, regValB, regValC, regValD, regValE);
            divReg = regValC;
            modReg = regValA;
            freeReg(regValB);
            freeReg(regValD);
            freeReg(regValE);
        }
        else{
            cout << "zrzut pamieci"<<yylineno << endl;
            exit(1);
        }
        
    }

}

void eqCode(string regValA,string regValB,string regValC){
    writeCommandWithTwoArg("COPY",regValC,regValA);
    writeCommandWithTwoArg("SUB",regValC,regValB);
    writeCommandWithTwoArg("JZERO",regValC,to_string(linesNo+2));
    writeCommandWithArg("JUMP",to_string(linesNo+3));
    writeCommandWithTwoArg("COPY",regValC,regValB);
    writeCommandWithTwoArg("SUB",regValC,regValA);
}

void eq(id a, id b){

    if(a.type == "NUM" && b.type == "NUM") {
        string regValA = findEmptyReg();
        string regValB = findEmptyReg();
        string regValC = findEmptyReg();
        if(regValA != "X" && regValB != "X" && regValC != "X"){
            generateNumber(atoi(a.name.c_str()),regValA);
            generateNumber(atoi(b.name.c_str()),regValB);
            eqCode( regValA, regValB, regValC);
            expReg = regValC;
            freeReg(regValA);
            freeReg(regValB);
            
        }
        else{
            cout << "zrzut pamieci"<<yylineno << endl;
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
            eqCode( regValA, regValB, regValC);
            expReg = regValC;
            freeReg(regValA);
            freeReg(regValB);

        }
        else{
            cout << "zrzut pamieci"<<yylineno << endl;
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
            eqCode( regValA, regValB, regValC);
            expReg = regValC;
            freeReg(regValA);
            freeReg(regValB);
        }
        else{
            cout << "zrzut pamieci"<<yylineno << endl;
            exit(1);
        }
    }
    else if(a.type == "ID" && b.type == "ID") {
        if(a.name == b.name) {
            string regValA = findEmptyReg();
            if(regValA != "X" ){
                generateNumber(0,regValA);
                expReg = regValA;
            }
            else{
                cout << "zrzut pamieci"<<yylineno << endl;
                exit(1);
            }
        }
        else {
            string regValA = findEmptyReg();
            string regValB = findEmptyReg();
            string regValC = findEmptyReg();
            if(regValA != "X" && regValB != "X"  && regValC != "X" ){
                setIndex(a.memPlace);
                writeCommandWithArg("LOAD",regValA);
                setIndex(b.memPlace);
                writeCommandWithArg("LOAD",regValB);
                eqCode( regValA, regValB, regValC);
                expReg = regValC;
                freeReg(regValA);
                freeReg(regValB);

            }
            else{
                cout << "zrzut pamieci"<<yylineno << endl;
                exit(1);
            }
        }
    }
}
void eqTab(id a, id b, string aInd, string bInd){
    if(a.type == "ARR" && b.type == "NUM") {
        string regValA = findEmptyReg();
        string regValB = findEmptyReg();
        string regValC = findEmptyReg();
        if(regValA != "X" && regValB != "X"  && regValC != "X" ){
            setIndexForTab(a,aInd);
            writeCommandWithArg("LOAD",regValA);
            generateNumber(atoi(b.name.c_str()),regValB);
            eqCode( regValA, regValB, regValC);
            expReg = regValC;
            freeReg(regValA);
            freeReg(regValB);

        }
        else{
            cout << "zrzut pamieci"<<yylineno << endl;
            exit(1);
        }
        
    }
    else if(a.type == "NUM" && b.type == "ARR") {
        string regValA = findEmptyReg();
        string regValB = findEmptyReg();
        string regValC = findEmptyReg();

        if(regValA != "X" && regValB != "X"  && regValC != "X" ){
            generateNumber(atoi(a.name.c_str()),regValA);
            setIndexForTab(b,bInd);
            writeCommandWithArg("LOAD",regValB);
            eqCode( regValA, regValB, regValC);
            expReg = regValC;
            freeReg(regValA);
            freeReg(regValB);

        }
        else{
            cout << "zrzut pamieci"<<yylineno << endl;
            exit(1);
        }
    }
    else if(a.type == "ID" && b.type == "ARR") {
        string regValA = findEmptyReg();
        string regValB = findEmptyReg();
        string regValC = findEmptyReg();

        if(regValA != "X" && regValB != "X"   && regValC != "X" ){
            setIndex(a.memPlace);
            writeCommandWithArg("LOAD",regValA);
            setIndexForTab(b,bInd);
            writeCommandWithArg("LOAD",regValB);
            eqCode( regValA, regValB, regValC);
            expReg = regValC;
            freeReg(regValA);
            freeReg(regValB);

        }
        else{
            cout << "zrzut pamieci"<<yylineno << endl;
            exit(1);
        }
    }
    else if(a.type == "ARR" && b.type == "ID") {
        string regValA = findEmptyReg();
        string regValB = findEmptyReg();
        string regValC = findEmptyReg();
        if(regValA != "X" && regValB != "X"   && regValC != "X" ){
            setIndex(b.memPlace);
            writeCommandWithArg("LOAD",regValB);
            setIndexForTab(a,aInd);
            writeCommandWithArg("LOAD",regValA);
            eqCode( regValA, regValB, regValC);
            expReg = regValC;
            freeReg(regValA);
            freeReg(regValB);
        }
        else{
            cout << "zrzut pamieci"<<yylineno << endl;
            exit(1);
        }
    }
    else if(a.type == "ARR" && b.type == "ARR") {
        if(a.name == b.name && aInd == bInd) {
            string regValA = findEmptyReg();
            if(regValA != "X" ){
                generateNumber(0,regValA);
                expReg = regValA;
            }
            else{
                cout << "zrzut pamieci"<<yylineno << endl;
                exit(1);
            }
        }
        else {
            string regValA = findEmptyReg();
            string regValB = findEmptyReg();
            string regValC = findEmptyReg();

            if(regValA != "X" && regValB != "X"  && regValC != "X"  ){
                setIndexForTab(a,aInd);
                writeCommandWithArg("LOAD",regValA);
                setIndexForTab(b,bInd);
                writeCommandWithArg("LOAD",regValB);
                eqCode( regValA, regValB, regValC);
                expReg = regValC;
                freeReg(regValA);
                freeReg(regValB);

            }
            else{
                cout << "zrzut pamieci"<<yylineno << endl;
                exit(1);
            }
        }
    }

}

void neqCode(string regValA,string regValB,string regValC){
    writeCommandWithTwoArg("COPY",regValC,regValA);
    writeCommandWithTwoArg("SUB",regValC,regValB);
    writeCommandWithTwoArg("JZERO",regValC,to_string(linesNo+3));
    generateNumber(0,regValC);
    writeCommandWithArg("JUMP",to_string(linesNo+7));
    writeCommandWithTwoArg("COPY",regValC,regValB);
    writeCommandWithTwoArg("SUB",regValC,regValA);
    writeCommandWithTwoArg("JZERO",regValC,to_string(linesNo+3));
    generateNumber(0,regValC);
    writeCommandWithArg("JUMP",to_string(linesNo+2));
    writeCommandWithArg("INC",regValC);
}

void neq(id a, id b){

    if(a.type == "NUM" && b.type == "NUM") {
        string regValA = findEmptyReg();
        string regValB = findEmptyReg();
        string regValC = findEmptyReg();
       
        if(regValA != "X" && regValB != "X" && regValC != "X"  ){
            generateNumber(atoi(a.name.c_str()),regValA);
            generateNumber(atoi(b.name.c_str()),regValB);
            neqCode( regValA, regValB, regValC);
            expReg = regValC;
            freeReg(regValA);
            freeReg(regValB);
        }
        else{
            cout << "zrzut pamieci"<<yylineno << endl;
            exit(1);
        }
        
    }
    else if(a.type == "NUM" && b.type == "ID") {
        string regValA = findEmptyReg();
        string regValB = findEmptyReg();
        string regValC = findEmptyReg();
        if(regValA != "X" && regValB != "X" && regValC != "X" ){
            generateNumber(atoi(a.name.c_str()),regValA);
            setIndex(b.memPlace);
            writeCommandWithArg("LOAD",regValB);
            neqCode( regValA, regValB, regValC);
            expReg = regValC;
            freeReg(regValA);
            freeReg(regValB);
            
        }
        else{
            cout << "zrzut pamieci"<<yylineno << endl;
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
            neqCode( regValA, regValB, regValC);
            expReg = regValC;
            freeReg(regValA);
            freeReg(regValB);
        }
        else{
            cout << "zrzut pamieci"<<yylineno << endl;
            exit(1);
        }
    }
    else if(a.type == "ID" && b.type == "ID") {
        if(a.name == b.name) {
            string regValA = findEmptyReg();
            if(regValA != "X" ){
                generateNumber(1,regValA);
                expReg = regValA;
            }
            else{
                cout << "zrzut pamieci"<<yylineno << endl;
                exit(1);
            }
        }
        else {
            string regValA = findEmptyReg();
            string regValB = findEmptyReg();
            string regValC = findEmptyReg();

            if(regValA != "X" && regValB != "X"  && regValC != "X"  ){
                setIndex(a.memPlace);
                writeCommandWithArg("LOAD",regValA);
                setIndex(b.memPlace);
                writeCommandWithArg("LOAD",regValB);
                neqCode( regValA, regValB, regValC);
                expReg = regValC;
                freeReg(regValA);
                freeReg(regValB);

            }
            else{
                cout << "zrzut pamieci"<<yylineno << endl;
                exit(1);
            }
        }
    }
}
void neqTab(id a, id b, string aInd, string bInd){
    if(a.type == "ARR" && b.type == "NUM") {
        string regValA = findEmptyReg();
        string regValB = findEmptyReg();
        string regValC = findEmptyReg();

        if(regValA != "X" && regValB != "X"  && regValC != "X"  ){
            setIndexForTab(a,aInd);
            writeCommandWithArg("LOAD",regValA);
            generateNumber(atoi(b.name.c_str()),regValB);
            neqCode( regValA, regValB, regValC);
            expReg = regValC;
            freeReg(regValA);
            freeReg(regValB);
        }
        else{
            cout << "zrzut pamieci"<<yylineno << endl;
            exit(1);
        }
        
    }
    else if(a.type == "NUM" && b.type == "ARR") {
        string regValA = findEmptyReg();
        string regValB = findEmptyReg();
        string regValC = findEmptyReg();
        if(regValA != "X" && regValB != "X"  && regValC != "X"  ){
            generateNumber(atoi(a.name.c_str()),regValA);
            setIndexForTab(b,bInd);
            writeCommandWithArg("LOAD",regValB);
            neqCode( regValA, regValB, regValC);
            expReg = regValC;
            freeReg(regValA);
            freeReg(regValB);

        }
        else{
            cout << "zrzut pamieci"<<yylineno << endl;
            exit(1);
        }
    }
    else if(a.type == "ID" && b.type == "ARR") {
        string regValA = findEmptyReg();
        string regValB = findEmptyReg();
        string regValC = findEmptyReg();
        if(regValA != "X" && regValB != "X"   && regValC != "X" ){
            setIndex(a.memPlace);
            writeCommandWithArg("LOAD",regValA);
            setIndexForTab(b,bInd);
            writeCommandWithArg("LOAD",regValB);
            neqCode( regValA, regValB, regValC);
            expReg = regValC;
            freeReg(regValA);
            freeReg(regValB);

        }
        else{
            cout << "zrzut pamieci"<<yylineno << endl;
            exit(1);
        }
    }
    else if(a.type == "ARR" && b.type == "ID") {
        string regValA = findEmptyReg();
        string regValB = findEmptyReg();
        string regValC = findEmptyReg();
        if(regValA != "X" && regValB != "X"   && regValC != "X"){
            setIndex(b.memPlace);
            writeCommandWithArg("LOAD",regValB);
            setIndexForTab(a,aInd);
            writeCommandWithArg("LOAD",regValA);
            neqCode( regValA, regValB, regValC);
            expReg = regValC;
            freeReg(regValA);
            freeReg(regValB);

        }
        else{
            cout << "zrzut pamieci"<<yylineno << endl;
            exit(1);
        }
    }
    else if(a.type == "ARR" && b.type == "ARR") {
        if(a.name == b.name && aInd == bInd) {
            string regValA = findEmptyReg();
            if(regValA != "X" ){
                generateNumber(1,regValA);
                expReg = regValA;
            }
            else{
                cout << "zrzut pamieci"<<yylineno << endl;
                exit(1);
            }
        }
        else {
            string regValA = findEmptyReg();
            string regValB = findEmptyReg();
            string regValC = findEmptyReg();
            if(regValA != "X" && regValB != "X"  && regValC != "X"  ){
                setIndexForTab(a,aInd);
                writeCommandWithArg("LOAD",regValA);
                setIndexForTab(b,bInd);
                writeCommandWithArg("LOAD",regValB);
                neqCode( regValA, regValB, regValC);
                expReg = regValC;
                freeReg(regValA);
                freeReg(regValB);

            }
            else{
                cout << "zrzut pamieci"<<yylineno << endl;
                exit(1);
            }
        }
    }

}

void ltCode(string regValA,string regValB){
    writeCommandWithArg("INC", regValA);
    writeCommandWithTwoArg("SUB",regValA,regValB);
}
void lt(id a, id b){

    if(a.type == "NUM" && b.type == "NUM") {
        string regValA = findEmptyReg();
        string regValB = findEmptyReg();
        if(regValA != "X" && regValB != "X"  ){
            generateNumber(atoi(a.name.c_str()),regValA);
            generateNumber(atoi(b.name.c_str()),regValB);
            ltCode(regValA,regValB);
            expReg = regValA;
            freeReg(regValB);
        }
        else{
            cout << "zrzut pamieci"<<yylineno << endl;
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
            ltCode(regValA,regValB);
            expReg = regValA;
            freeReg(regValB);
        }
        else{
            cout << "zrzut pamieci"<<yylineno << endl;
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
            ltCode(regValA,regValB);
            expReg = regValA;
            freeReg(regValB);
        }
        else{
            cout << "zrzut pamieci"<<yylineno << endl;
            exit(1);
        }
    }
    else if(a.type == "ID" && b.type == "ID") {
        if(a.name == b.name) {
            string regValA = findEmptyReg();
            if(regValA != "X" ){
                generateNumber(1,regValA);
                expReg = regValA;
            }
            else{
                cout << "zrzut pamieci"<<yylineno << endl;
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
                ltCode(regValA,regValB);
                expReg = regValA;
                freeReg(regValB);
            }
            else{
                cout << "zrzut pamieci"<<yylineno << endl;
                exit(1);
            }
        }
    }
}
void ltTab(id a, id b, string aInd, string bInd){
    if(a.type == "ARR" && b.type == "NUM") {
        string regValA = findEmptyReg();
        string regValB = findEmptyReg();
        if(regValA != "X" && regValB != "X"  ){
            setIndexForTab(a,aInd);
            writeCommandWithArg("LOAD",regValA);
            generateNumber(atoi(b.name.c_str()),regValB);
            ltCode(regValA,regValB);
            expReg = regValA;
            freeReg(regValB);
        }
        else{
            cout << "zrzut pamieci"<<yylineno << endl;
            exit(1);
        }
        
    }
    else if(a.type == "NUM" && b.type == "ARR") {
        string regValA = findEmptyReg();
        string regValB = findEmptyReg();
        if(regValA != "X" && regValB != "X"  ){
            generateNumber(atoi(a.name.c_str()),regValA);
            setIndexForTab(b,bInd);
            writeCommandWithArg("LOAD",regValB);
            ltCode(regValA,regValB);
            expReg = regValA;
            freeReg(regValB);
        }
        else{
            cout << "zrzut pamieci"<<yylineno << endl;
            exit(1);
        }
    }
    else if(a.type == "ID" && b.type == "ARR") {
        string regValA = findEmptyReg();
        string regValB = findEmptyReg();
        if(regValA != "X" && regValB != "X"  ){
            setIndex(a.memPlace);
            writeCommandWithArg("LOAD",regValA);
            setIndexForTab(b,bInd);
            writeCommandWithArg("LOAD",regValB);
            ltCode(regValA,regValB);
            expReg = regValA;
            freeReg(regValB);
        }
        else{
            cout << "zrzut pamieci"<<yylineno << endl;
            exit(1);
        }
    }
    else if(a.type == "ARR" && b.type == "ID") {
        string regValA = findEmptyReg();
        string regValB = findEmptyReg();
        if(regValA != "X" && regValB != "X"  ){
            setIndex(b.memPlace);
            writeCommandWithArg("LOAD",regValB);
            setIndexForTab(a,aInd);
            writeCommandWithArg("LOAD",regValA);
            ltCode(regValA,regValB);
            expReg = regValA;
            freeReg(regValB);
        }
        else{
            cout << "zrzut pamieci"<<yylineno << endl;
            exit(1);
        }
    }
    else if(a.type == "ARR" && b.type == "ARR") {
        if(a.name == b.name && aInd == bInd) {
            string regValA = findEmptyReg();
            if(regValA != "X" ){
                generateNumber(1,regValA);
                expReg = regValA;
            }
            else{
                cout << "zrzut pamieci"<<yylineno << endl;
                exit(1);
            }
        }
        else {
            string regValA = findEmptyReg();
            string regValB = findEmptyReg();
            if(regValA != "X" && regValB != "X"  ){
                setIndexForTab(a,aInd);
                writeCommandWithArg("LOAD",regValA);
                setIndexForTab(b,bInd);
                writeCommandWithArg("LOAD",regValB);
                ltCode(regValA,regValB);
                expReg = regValA;
                freeReg(regValB);
            }
            else{
                cout << "zrzut pamieci"<<yylineno << endl;
                exit(1);
            }
        }
    }

}

void gtCode(string regValA,string regValB){
    writeCommandWithArg("INC", regValB);
    writeCommandWithTwoArg("SUB",regValB,regValA);
}
void gt(id a, id b){

    if(a.type == "NUM" && b.type == "NUM") {
        string regValA = findEmptyReg();
        string regValB = findEmptyReg();
        if(regValA != "X" && regValB != "X"  ){
            generateNumber(atoi(a.name.c_str()),regValA);
            generateNumber(atoi(b.name.c_str()),regValB);
            gtCode(regValA,regValB);
            expReg = regValB;
            freeReg(regValA);
        }
        else{
            cout << "zrzut pamieci"<<yylineno << endl;
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
            gtCode(regValA,regValB);
            expReg = regValB;
            freeReg(regValA);
        }
        else{
            cout << "zrzut pamieci"<<yylineno << endl;
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
            gtCode(regValA,regValB);
            expReg = regValB;
            freeReg(regValA);
        }
        else{
            cout << "zrzut pamieci"<<yylineno << endl;
            exit(1);
        }
    }
    else if(a.type == "ID" && b.type == "ID") {
        if(a.name == b.name) {
            string regValA = findEmptyReg();
            if(regValA != "X" ){
                generateNumber(1,regValA);
                expReg = regValA;
            }
            else{
                cout << "zrzut pamieci"<<yylineno << endl;
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
                gtCode(regValA,regValB);
                expReg = regValB;
                freeReg(regValA);
            }
            else{
                cout << "zrzut pamieci"<<yylineno << endl;
                exit(1);
            }
        }
    }
}
void gtTab(id a, id b, string aInd, string bInd){
    if(a.type == "ARR" && b.type == "NUM") {
        string regValA = findEmptyReg();
        string regValB = findEmptyReg();
        if(regValA != "X" && regValB != "X"  ){
            setIndexForTab(a,aInd);
            writeCommandWithArg("LOAD",regValA);
            generateNumber(atoi(b.name.c_str()),regValB);
            gtCode(regValA,regValB);
            expReg = regValB;
            freeReg(regValA);
        }
        else{
            cout << "zrzut pamieci"<<yylineno << endl;
            exit(1);
        }
        
    }
    else if(a.type == "NUM" && b.type == "ARR") {
        string regValA = findEmptyReg();
        string regValB = findEmptyReg();
        if(regValA != "X" && regValB != "X"  ){
            generateNumber(atoi(a.name.c_str()),regValA);
            setIndexForTab(b,bInd);
            writeCommandWithArg("LOAD",regValB);
            gtCode(regValA,regValB);
            expReg = regValB;
            freeReg(regValA);
        }
        else{
            cout << "zrzut pamieci"<<yylineno << endl;
            exit(1);
        }
    }
    else if(a.type == "ID" && b.type == "ARR") {
        string regValA = findEmptyReg();
        string regValB = findEmptyReg();
        if(regValA != "X" && regValB != "X"  ){
            setIndex(a.memPlace);
            writeCommandWithArg("LOAD",regValA);
            setIndexForTab(b,bInd);
            writeCommandWithArg("LOAD",regValB);
            gtCode(regValA,regValB);
            expReg = regValB;
            freeReg(regValA);
        }
        else{
            cout << "zrzut pamieci"<<yylineno << endl;
            exit(1);
        }
    }
    else if(a.type == "ARR" && b.type == "ID") {
        string regValA = findEmptyReg();
        string regValB = findEmptyReg();
        if(regValA != "X" && regValB != "X"  ){
            setIndex(b.memPlace);
            writeCommandWithArg("LOAD",regValB);
            setIndexForTab(a,aInd);
            writeCommandWithArg("LOAD",regValA);
            gtCode(regValA,regValB);
            expReg = regValB;
            freeReg(regValA);
        }
        else{
            cout << "zrzut pamieci 3 "<<yylineno << endl;
            exit(1);
        }
    }
    else if(a.type == "ARR" && b.type == "ARR") {
        if(a.name == b.name && aInd == bInd) {
            string regValA = findEmptyReg();
            if(regValA != "X" ){
                generateNumber(1,regValA);
                expReg = regValA;
            }
            else{
                cout << "zrzut pamieci"<<yylineno << endl;
                exit(1);
            }
        }
        else {
            string regValA = findEmptyReg();
            string regValB = findEmptyReg();
            if(regValA != "X" && regValB != "X"  ){
                setIndexForTab(a,aInd);
                writeCommandWithArg("LOAD",regValA);
                setIndexForTab(b,bInd);
                writeCommandWithArg("LOAD",regValB);
                gtCode(regValA,regValB);
                expReg = regValB;
                freeReg(regValA);
            }
            else{
                cout << "zrzut pamieci"<<yylineno << endl;
                exit(1);
            }
        }
    }

}

void leCode(string regValA,string regValB){
    writeCommandWithTwoArg("SUB",regValA,regValB);
}
void le(id a, id b){

    if(a.type == "NUM" && b.type == "NUM") {
        string regValA = findEmptyReg();
        string regValB = findEmptyReg();
        if(regValA != "X" && regValB != "X"  ){
            generateNumber(atoi(a.name.c_str()),regValA);
            generateNumber(atoi(b.name.c_str()),regValB);
            leCode(regValA,regValB);
            expReg = regValA;
            freeReg(regValB);
        }
        else{
            cout << "zrzut pamieci"<<yylineno << endl;
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
            leCode(regValA,regValB);
            expReg = regValA;
            freeReg(regValB);
        }
        else{
            cout << "zrzut pamieci"<<yylineno << endl;
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
            leCode(regValA,regValB);
            expReg = regValA;
            freeReg(regValB);
        }
        else{
            cout << "zrzut pamieci"<<yylineno << endl;
            exit(1);
        }
    }
    else if(a.type == "ID" && b.type == "ID") {
        if(a.name == b.name) {
            string regValA = findEmptyReg();
            if(regValA != "X" ){
                generateNumber(1,regValA);
                expReg = regValA;
            }
            else{
                cout << "zrzut pamieci"<<yylineno << endl;
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
                leCode(regValA,regValB);
                expReg = regValA;
                freeReg(regValB);
            }
            else{
                cout << "zrzut pamieci"<<yylineno << endl;
                exit(1);
            }
        }
    }
}
void leTab(id a, id b, string aInd, string bInd){
    if(a.type == "ARR" && b.type == "NUM") {
        string regValA = findEmptyReg();
        string regValB = findEmptyReg();
        if(regValA != "X" && regValB != "X"  ){
            setIndexForTab(a,aInd);
            writeCommandWithArg("LOAD",regValA);
            generateNumber(atoi(b.name.c_str()),regValB);
            leCode(regValA,regValB);
            expReg = regValA;
            freeReg(regValB);
        }
        else{
            cout << "zrzut pamieci"<<yylineno << endl;
            exit(1);
        }
        
    }
    else if(a.type == "NUM" && b.type == "ARR") {
        string regValA = findEmptyReg();
        string regValB = findEmptyReg();
        if(regValA != "X" && regValB != "X"  ){
            generateNumber(atoi(a.name.c_str()),regValA);
            setIndexForTab(b,bInd);
            writeCommandWithArg("LOAD",regValB);
            leCode(regValA,regValB);
            expReg = regValA;
            freeReg(regValB);
        }
        else{
            cout << "zrzut pamieci"<<yylineno << endl;
            exit(1);
        }
    }
    else if(a.type == "ID" && b.type == "ARR") {
        string regValA = findEmptyReg();
        string regValB = findEmptyReg();
        if(regValA != "X" && regValB != "X"  ){
            setIndex(a.memPlace);
            writeCommandWithArg("LOAD",regValA);
            setIndexForTab(b,bInd);
            writeCommandWithArg("LOAD",regValB);
            leCode(regValA,regValB);
            expReg = regValA;
            freeReg(regValB);
        }
        else{
            cout << "zrzut pamieci"<<yylineno << endl;
            exit(1);
        }
    }
    else if(a.type == "ARR" && b.type == "ID") {
        string regValA = findEmptyReg();
        string regValB = findEmptyReg();
        if(regValA != "X" && regValB != "X"  ){
            setIndex(b.memPlace);
            writeCommandWithArg("LOAD",regValB);
            setIndexForTab(a,aInd);
            writeCommandWithArg("LOAD",regValA);
            leCode(regValA,regValB);
            expReg = regValA;
            freeReg(regValB);
        }
        else{
            cout << "zrzut pamieci"<<yylineno << endl;
            exit(1);
        }
    }
    else if(a.type == "ARR" && b.type == "ARR") {
        if(a.name == b.name && aInd == bInd) {
            string regValA = findEmptyReg();
            if(regValA != "X" ){
                generateNumber(1,regValA);
                expReg = regValA;
            }
            else{
                cout << "zrzut pamieci"<<yylineno << endl;
                exit(1);
            }
        }
        else {
            string regValA = findEmptyReg();
            string regValB = findEmptyReg();
            if(regValA != "X" && regValB != "X"  ){
                setIndexForTab(a,aInd);
                writeCommandWithArg("LOAD",regValA);
                setIndexForTab(b,bInd);
                writeCommandWithArg("LOAD",regValB);
                leCode(regValA,regValB);
                expReg = regValA;
                freeReg(regValB);
            }
            else{
                cout << "zrzut pamieci"<<yylineno << endl;
                exit(1);
            }
        }
    }

}

void geCode(string regValA,string regValB){
    writeCommandWithTwoArg("SUB",regValB,regValA);
}
void ge(id a, id b){

    if(a.type == "NUM" && b.type == "NUM") {
        string regValA = findEmptyReg();
        string regValB = findEmptyReg();
        if(regValA != "X" && regValB != "X"  ){
            generateNumber(atoi(a.name.c_str()),regValA);
            generateNumber(atoi(b.name.c_str()),regValB);
            geCode(regValA,regValB);
            expReg = regValB;
            freeReg(regValA);
        }
        else{
            cout << "zrzut pamieci"<<yylineno << endl;
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
            geCode(regValA,regValB);
            expReg = regValB;
            freeReg(regValA);
        }
        else{
            cout << "zrzut pamieci"<<yylineno << endl;
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
            geCode(regValA,regValB);
            expReg = regValB;
            freeReg(regValA);
        }
        else{
            cout << "zrzut pamieci"<<yylineno << endl;
            exit(1);
        }
    }
    else if(a.type == "ID" && b.type == "ID") {
        if(a.name == b.name) {
            string regValA = findEmptyReg();
            if(regValA != "X" ){
                generateNumber(1,regValA);
                expReg = regValA;
            }
            else{
                cout << "zrzut pamieci"<<yylineno << endl;
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
                geCode(regValA,regValB);
                expReg = regValB;
                freeReg(regValA);
            }
            else{
                cout << "zrzut pamieci"<<yylineno << endl;
                exit(1);
            }
        }
    }
}
void geTab(id a, id b, string aInd, string bInd){
    if(a.type == "ARR" && b.type == "NUM") {
        string regValA = findEmptyReg();
        string regValB = findEmptyReg();
        if(regValA != "X" && regValB != "X"  ){
            setIndexForTab(a,aInd);
            writeCommandWithArg("LOAD",regValA);
            generateNumber(atoi(b.name.c_str()),regValB);
            geCode(regValA,regValB);
            expReg = regValB;
            freeReg(regValA);
        }
        else{
            cout << "zrzut pamieci"<<yylineno << endl;
            exit(1);
        }
        
    }
    else if(a.type == "NUM" && b.type == "ARR") {
        string regValA = findEmptyReg();
        string regValB = findEmptyReg();
        if(regValA != "X" && regValB != "X"  ){
            generateNumber(atoi(a.name.c_str()),regValA);
            setIndexForTab(b,bInd);
            writeCommandWithArg("LOAD",regValB);
            geCode(regValA,regValB);
            expReg = regValB;
            freeReg(regValA);
        }
        else{
            cout << "zrzut pamieci"<<yylineno << endl;
            exit(1);
        }
    }
    else if(a.type == "ID" && b.type == "ARR") {
        string regValA = findEmptyReg();
        string regValB = findEmptyReg();
        if(regValA != "X" && regValB != "X"  ){
            setIndex(a.memPlace);
            writeCommandWithArg("LOAD",regValA);
            setIndexForTab(b,bInd);
            writeCommandWithArg("LOAD",regValB);
            geCode(regValA,regValB);
            expReg = regValB;
            freeReg(regValA);
        }
        else{
            cout << "zrzut pamieci"<<yylineno << endl;
            exit(1);
        }
    }
    else if(a.type == "ARR" && b.type == "ID") {
        string regValA = findEmptyReg();
        string regValB = findEmptyReg();
        if(regValA != "X" && regValB != "X"  ){
            setIndex(b.memPlace);
            writeCommandWithArg("LOAD",regValB);
            setIndexForTab(a,aInd);
            writeCommandWithArg("LOAD",regValA);
            geCode(regValA,regValB);
            expReg = regValB;
            freeReg(regValA);
        }
        else{
            cout << "zrzut pamieci"<<yylineno << endl;
            exit(1);
        }
    }
    else if(a.type == "ARR" && b.type == "ARR") {
        if(a.name == b.name && aInd == bInd) {
            string regValA = findEmptyReg();
            if(regValA != "X" ){
                generateNumber(1,regValA);
                expReg = regValA;
            }
            else{
                cout << "zrzut pamieci"<<yylineno << endl;
                exit(1);
            }
        }
        else {
            string regValA = findEmptyReg();
            string regValB = findEmptyReg();
            if(regValA != "X" && regValB != "X"  ){
                setIndexForTab(a,aInd);
                writeCommandWithArg("LOAD",regValA);
                setIndexForTab(b,bInd);
                writeCommandWithArg("LOAD",regValB);
                geCode(regValA,regValB);
                expReg = regValB;
                freeReg(regValA);
            }
            else{
                cout << "zrzut pamieci"<<yylineno << endl;
                exit(1);
            }
        }
    }

}



void createVariable(id* s,string name, string type, long long int size,long long int startsAt, long long int mem, bool init ,bool isLocal){
    s->name = name;
    s->type = type;
    s->size = size;
    s->startsAt = startsAt;
    s->memPlace = mem;
    s->init = init;
    s->isLocal = isLocal;
}
void createLoop(loop* l,string name,long long int currLineNo,string counter){
    l->name = name;
    l->currLineNo = currLineNo;
    l->counter = counter;
}

void addVariable(id s){
    vars.push_back(s);
}
void removeVariable(id s){
    vector<id>::iterator it;
    it = vars.begin();
    long long int index = findIndexOf(vars,s.name);
    for(int i = 0;i<index;++i){
        it++;
    }
    vars.erase(it);
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
void replaceJump(long long int curr, string prev){
    for (int i = code.size()-1;i>=0;--i){
        string line = code.at(i);
        if(line.substr(0,5)=="JZERO"){
            long long int len = line.size()-8;
            if(line.substr(8,len)==prev){
                string newLine = line.substr(0,8)+to_string(curr);
                code.at(i)=newLine;
            }
        }
        if(line.substr(0,4)=="JUMP"){
            long long int len = line.size()-5;
            if(line.substr(5,len)==prev){
                string newLine = line.substr(0,5)+to_string(curr);
                code.at(i)=newLine;
            }
        }
    }
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

int main(int argc, char* argv[])
{
    
    if(argc < 3){
        cout<<"Nie podano parametrow"<<endl;
    }
    else{
        yyin = fopen(argv[1], "r");
        if ( ! yyin ) {
            cout << "Error - could not open file " << argv[1] << "." << endl;
        }
        memAssign =0;
        linesNo = 0;
        yyparse();
        string file = argv[2];
        outCode(file);
    }
    return 0;
}
int yyerror(string str){
    cout<<"Blad w lini "<<yylineno<<" - "<<str<<"."<<endl;
    exit(1);
}
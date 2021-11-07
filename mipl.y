/*
 *  bison specifications for the MIPL language.
 *  Written to meet requirements for CS 5500, Fall 2018.
 */

/*
 *  Declaration section.
 */
%{

#include <stdio.h>
#include <iostream>
#include <ctype.h>
#include <stack>
#include <cstring>
#include <string>
#include <map>
#include "SymbolTable.h"

// Function prototypes
void openScope();
void closeScope();
void ignoreComment();
void prRule(const char*, const char*);
void printTokenInfo(const char* tokenType, const char* lexeme);
void printSymbolTable();
int ckInt();
int yyerror(const char*);
bool findEntryInAnyScope(const string theName);
void setFrameSize(const int& size);

extern "C" {
    int yyparse(void);
    int yylex(void);
    int yywrap() {return 1;}
}

#define MAX_INT	            "2147483647"
#define LOGICAL_OP          100
#define ARITHMETIC_OP       101
#define OUTPUT_TOKENS	    0
#define OUTPUT_PRODUCTIONS  0

// Operator definitions
#define ADD_OP         1
#define SUB_OP         2
#define OR_OP          3
#define MULT_OP        4
#define DIV_OP         5
#define AND_OP         6
#define NOT_OP         7
#define NEG_OP         8
#define EQ_OP          9
#define NEQ_OP         10
#define LT_OP          11
#define LTE_OP         12
#define GT_OP          13
#define GTE_OP         14

// Global variables
map<int, const char*> typeMap;
stack<SYMBOL_TABLE> scopeStack;
stack<char*> identStack;
SYMBOL_TABLE* location;
int globalOffset = 20;
int localOffset = 0;
int nextLabel = 0;
int currentLevel = 0;
int lineNum = 1;     // source line number
stack<string> procedures;
stack<int> elseLabelStack;
stack<int> postConditionLabelStack;
stack<int> loopTopLabelStack;
stack<int> postLoopLabelStack;
string stringIndent = "  ";
char* indent = const_cast<char*>(stringIndent.c_str());

%}

%union
{
	char* text;
	TYPE_INFO typeInfo;
    OPERATOR_INFO operatorInfo;
    int intValue;
};

/*
 *  Token declaration. 'N_...' for rules, 'T_...' for tokens.
 *  Note: tokens are also used in the flex specification file.
 */
%token      T_LPAREN    T_RPAREN    T_MULT	     T_PLUS
%token      T_COMMA     T_MINUS     T_DOT       T_DOTDOT
%token      T_COLON     T_ASSIGN    T_SCOLON    T_LT
%token      T_LE        T_NE        T_EQ        T_GT
%token      T_GE        T_LBRACK    T_RBRACK    T_DO
%token      T_AND       T_ARRAY     T_BEGIN     T_BOOL
%token      T_CHAR      T_DIV       T_CHARCONST T_INTCONST
%token      T_END       T_FALSE     T_IF        T_INT
%token      T_NOT       T_OF        T_OR        T_PROC
%token      T_PROG      T_READ      T_TRUE      T_IDENT
%token      T_VAR       T_WHILE     T_WRITE     T_UNKNOWN
%token      ST_EOF

%type <text> T_IDENT T_INTCONST T_CHARCONST T_PLUS T_MINUS
%type <typeInfo>  N_TYPE N_ARRAY N_SIMPLE N_PROCIDENT N_PROCSTMT 
%type <typeInfo>  N_VARIDENT N_ENTIREVAR N_VARIABLE N_ARRAYVAR 
%type <typeInfo>  N_IDXVAR N_IDXRANGE N_IDENT N_INTCONST N_IDX
%type <typeInfo>  N_SIGN N_EXPR N_SIMPLEEXPR N_TERM N_FACTOR N_CONST
%type <typeInfo>  N_ADDOPLST N_MULTOPLST N_INPUTVAR
%type <intValue>  N_VARDEC N_VARDECLST N_BOOLCONST N_RELOP
%type <operatorInfo> N_ADDOP N_MULTOP N_ADDOP_LOGIC N_ADDOP_ARITH N_MULTOP_ARITH N_MULTOP_LOGIC

/*
 *  To eliminate ambiguities.
 */
%nonassoc   T_THEN
%nonassoc   T_ELSE

/*
 *  Starting point.
 */
%start      N_START

/*
 *  Translation rules.
 */
%%
N_START         : N_PROG
                    {
                        prRule("N_START", "N_PROG");
                        return 0;
                    }
                ;
N_ADDOP         : N_ADDOP_LOGIC 
                    {
                        $$.op = $1.op;
                        $$.opType = LOGICAL_OP;
                    }
                | N_ADDOP_ARITH
                    {
                        $$.op = $1.op;
                        $$.opType = ARITHMETIC_OP;
                    }
                ;
N_ADDOP_LOGIC   : T_OR
                    {
                        $$.op = OR_OP;
                        prRule("N_ADDOP", "T_OR");
                    }
                ;
N_ADDOP_ARITH   :  T_PLUS
                    {
                        $$.op = ADD_OP;
                        prRule("N_ADDOP", "T_PLUS");
                    }
                | T_MINUS
                    {
                        $$.op = SUB_OP;
                        prRule("N_ADDOP", "T_MINUS");
                    }
                ;
N_ADDOPLST      : /* epsilon */
                    {
                        prRule("N_ADDOPLST", "epsilon");
                        $$.type = NOT_APPLICABLE;
                    }
                | N_ADDOP N_TERM N_ADDOPLST
                    {
                        prRule("N_ADDOPLST", "N_ADDOP N_TERM N_ADDOPLST");

                        // Check for type consistency 
                        if ($1.opType == LOGICAL_OP && $2.type != BOOLEAN) { yyerror("Expression must be of type boolean"); }
                        else if ($1.opType == ARITHMETIC_OP && $2.type != INT) { yyerror("Expression must be of type integer"); }
                    
                        if ($2.type == $3.type || $3.type == NOT_APPLICABLE) { $$.type = $2.type; }
                        else { $$.type = UNDEFINED; }

                        switch($1.op) {
                            case ADD_OP: printf("%sadd\n", indent); break;
                            case SUB_OP: printf("%ssub\n", indent); break;
                            case OR_OP: printf("%sor\n", indent); break;
                        }
                    }
                ;
N_ARRAY         : T_ARRAY T_LBRACK N_IDXRANGE T_RBRACK T_OF N_SIMPLE
                    {
                        $$.type = ARRAY;
                        $$.startIndex = $3.startIndex;
                        $$.endIndex = $3.endIndex;
                        $$.baseType = $6.type;

                        prRule("N_ARRAY", "T_ARRAY T_LBRACK N_IDXRANGE T_RBRACK T_OF N_SIMPLE");
                    }
                ;
N_ARRAYVAR      : N_ENTIREVAR
                    {
                        prRule("N_ARRAYVAR", "N_ENTIREVAR");

                        if ($1.type != ARRAY) { yyerror("Indexed variable must be of array type"); }

                        $$.value = $1.value;
                        $$.type = $1.type;
                        $$.startIndex = $1.startIndex;
                        $$.endIndex = $1.endIndex;
                        $$.baseType = $1.baseType;
                    }
                ;
N_ASSIGN        : N_VARIABLE 
                    {
                    }
                    T_ASSIGN N_EXPR
                    {
                        prRule("N_ASSIGN", "N_VARIABLE T_ASSIGN N_EXPR");

                        if ($1.type == ARRAY && $1.baseType == UNDEFINED) { yyerror("Cannot make assignment to an array"); }
                        else {
                            if ($1.type == ARRAY) {
                                if ($4.type == ARRAY) {
                                    if ($1.baseType != $4.baseType) {
                                        yyerror("Expression must be of same type as variable");
                                    }
                                }
                                else if ($1.baseType != $4.type) {
                                    yyerror("Expression must be of same type as variable");
                                }
                            }
                            else {
                                if ($4.type == ARRAY) {
                                    if ($1.type != $4.baseType) {
                                        yyerror("Expression must be of same type as variable");
                                    }
                                }
                                else if ($1.type != $4.type) { 
                                    yyerror("Expression must be of same type as variable"); 
                                }
                            }
                        }

                        printf("%sst\n", indent);
                    }
                ;
N_BLOCK         : N_VARDECPART 
                    {
                        currentLevel++;

                        // Output memory reservation after processing global variables
                        if (currentLevel == 1) {
                            printf("L.%d:\n%sbss %d\n", 0, indent, globalOffset);
                            printf("L.%d:\n", 2);
                        }
                    } 
                    N_PROCDECPART N_STMTPART
                    {
                        prRule("N_BLOCK", "N_VARDECPART N_PROCDECPART N_STMTPART");
                        closeScope();
                    }
                ;
N_BOOLCONST     : T_TRUE
                    {
                        prRule("N_BOOLCONST", "T_TRUE");
                        $$ = 1;
                    }
                | T_FALSE
                    {
                        prRule("N_BOOLCONST", "T_FALSE");
                        $$ = 0;
                    }
                ;
N_COMPOUND      : T_BEGIN 
                    {
                        if (!procedures.empty() && loopTopLabelStack.empty() && findEntryInAnyScope(procedures.top())) {
                            TYPE_INFO procedure = location->getEntry(procedures.top());

                            printf("L.%d:\n%ssave %d, 0\n", procedure.labelNum, indent, procedure.staticNestLevel);

                            if (procedure.frameSize != 0) {
                                printf("%sasp %d\n", indent, procedure.frameSize);
                            }
                        }
                        else if (procedures.empty() && loopTopLabelStack.empty()) {
                            printf("L.3:\n");
                        }
                    }
                    N_STMT N_STMTLST T_END
                    {
                        if (!procedures.empty() && loopTopLabelStack.empty() && findEntryInAnyScope(procedures.top())) {
                            TYPE_INFO procedure = location->getEntry(procedures.top());

                            if (procedure.frameSize != 0) {
                                printf("%sasp %d\n", indent, -1 * procedure.frameSize);
                            }

                            printf("%sji\n", indent);
                        }

                        prRule("N_COMPOUND", "T_BEGIN N_STMT N_STMTLST T_END");
                    }
                ;
N_CONDITION     : T_IF N_EXPR 
                    {
                        printf("%sjf L.%d\n", indent, nextLabel);
                        elseLabelStack.push(nextLabel);
                        nextLabel++;
                        postConditionLabelStack.push(nextLabel);
                        nextLabel++;
                    } 
                    N_THEN 
                    {
                        if ($2.type != BOOLEAN) { yyerror("Expression must be of type boolean"); }
                    }
                ;
N_THEN          : T_THEN N_STMT
                    {
                        prRule("N_CONDITION", "T_IF N_EXPR T_THEN N_STMT");

                        printf("%sjp L.%d\n", indent, postConditionLabelStack.top());
                        printf("L.%d:\n", elseLabelStack.top());
                        elseLabelStack.pop();
                        printf("L.%d:\n", postConditionLabelStack.top());
                        postConditionLabelStack.pop();
                    }
                | T_THEN N_STMT T_ELSE 
                    {
                        printf("%sjp L.%d\n", indent, postConditionLabelStack.top());
                        printf("L.%d:\n", elseLabelStack.top());
                        elseLabelStack.pop();
                    } 
                    N_STMT
                    {
                        prRule("N_CONDITION", "T_IF N_EXPR T_THEN N_STMT T_ELSE N_STMT");

                        printf("L.%d:\n", postConditionLabelStack.top());
                        postConditionLabelStack.pop();
                    }
                ;
N_CONST         : N_INTCONST
                    {
                        prRule("N_CONST", "N_INTCONST");

                        $$.type = INT;
                        $$.startIndex = NOT_APPLICABLE;
                        $$.endIndex = NOT_APPLICABLE;
                        $$.baseType = NOT_APPLICABLE;

                        printf("%slc %s\n", indent, $1.value);
                    }
                | T_CHARCONST
                    {
                        prRule("N_CONST", "T_CHARCONST");

                        $$.type = CHAR;
                        $$.startIndex = NOT_APPLICABLE;
                        $$.endIndex = NOT_APPLICABLE;
                        $$.baseType = NOT_APPLICABLE;

                        printf("%slc %d\n", indent, $1[1]);
                    }
                | N_BOOLCONST
                    {
                        prRule("N_CONST", "N_BOOLCONST");

                        $$.type = BOOLEAN;
                        $$.startIndex = NOT_APPLICABLE;
                        $$.endIndex = NOT_APPLICABLE;
                        $$.baseType = NOT_APPLICABLE;

                        printf("%slc %d\n", indent, $1);
                    }
                ;
N_ENTIREVAR     : N_VARIDENT
                    {
                        prRule("N_ENTIREVAR", "N_VARIDENT");
                        
                        $$.value = $1.value;
                        $$.type = $1.type;
                        $$.startIndex = $1.startIndex;
                        $$.endIndex = $1.endIndex;
                        $$.baseType = $1.baseType;

                        TYPE_INFO lhs;
                        if (findEntryInAnyScope($1.value)) {
                            lhs = location->getEntry($1.value);

                            if ($1.type != ARRAY) {
                                printf("%sla %d, %d\n", indent, lhs.offset, lhs.staticNestLevel);
                            }
                            else {
                                printf("%sla %d, %d\n", indent, lhs.offset - lhs.startIndex, lhs.staticNestLevel);
                            }
                        }
                    }
                ;
N_EXPR          : N_SIMPLEEXPR
                    {
                        prRule("N_EXPR", "N_SIMPLEEXPR");

                        $$.type = $1.type;
                        $$.startIndex = $1.startIndex;
                        $$.endIndex = $1.endIndex;
                        $$.baseType = $1.baseType;
                    }
                | N_SIMPLEEXPR N_RELOP N_SIMPLEEXPR
                    {
                        prRule("N_EXPR", "N_SIMPLEEXPR N_RELOP N_SIMPLEEXPR");

                        // Handle cases if simple expr's are arrays
                        if ($1.type == ARRAY) {
                            if ($3.type == ARRAY) {
                                if ($1.baseType != $3.baseType) {
                                    yyerror("Expressions must both be int, or both char, or both boolean");
                                }
                            }
                            else if ($1.baseType != $3.type) {
                                yyerror("Expressions must both be int, or both char, or both boolean");
                            }
                        }
                        else {
                            if ($3.type == ARRAY) {
                                if ($1.type != $3.baseType) {
                                    yyerror("Expressions must both be int, or both char, or both boolean");
                                }
                            }
                            else if ($1.type != $3.type) { 
                                yyerror("Expressions must both be int, or both char, or both boolean"); 
                            }
                        }

                        switch($2) {
                            case LT_OP: printf("%s.lt.\n", indent); break;
                            case GT_OP: printf("%s.gt.\n", indent); break;
                            case LTE_OP: printf("%s.le.\n", indent); break;
                            case GTE_OP: printf("%s.ge.\n", indent); break;
                            case EQ_OP: printf("%s.eq.\n", indent); break;
                            case NEQ_OP: printf("%s.ne.\n", indent); break;
                        }

                        $$.type = BOOLEAN;
                        $$.startIndex = NOT_APPLICABLE;
                        $$.endIndex = NOT_APPLICABLE;
                        $$.baseType = NOT_APPLICABLE;
                    }
                ;
N_FACTOR        : N_SIGN N_VARIABLE
                    {
                        prRule("N_FACTOR", "N_SIGN N_VARIABLE");

                        if ($2.type == ARRAY && $2.baseType != INT && $1.baseType != NOT_APPLICABLE) { yyerror("Expression must be of type integer"); }
                        else if ($2.type != ARRAY && $2.type != INT && $1.baseType != NOT_APPLICABLE) { yyerror("Expression must be of type integer"); }

                        $$.type = $2.type;
                        $$.startIndex = $2.startIndex;
                        $$.endIndex = $2.endIndex;
                        $$.baseType = $2.baseType;

                        printf("%sderef\n", indent);
                        if ($1.baseType < 0) { printf("%sneg\n", indent); }
                    }
                | N_CONST
                    {
                        prRule("N_FACTOR", "N_CONST");

                        $$.type = $1.type;
                        $$.startIndex = $1.startIndex;
                        $$.endIndex = $1.endIndex;
                        $$.baseType = $1.baseType;
                    }
                | T_LPAREN N_EXPR T_RPAREN
                    {
                        prRule("N_FACTOR", "T_LPAREN N_EXPR T_RPAREN");

                        $$.type = $2.type;
                        $$.startIndex = $2.startIndex;
                        $$.endIndex = $2.endIndex;
                        $$.baseType = $2.baseType;
                    }
                | T_NOT N_FACTOR
                    {
                        prRule("N_FACTOR", "T_NOT N_FACTOR");

                        if ($2.type == ARRAY && $2.baseType != BOOLEAN) { yyerror("Expression must be of type boolean"); }
                        else if ($2.type != ARRAY && $2.type != BOOLEAN) { yyerror("Expression must be of type boolean"); }

                        $$.type = $2.type;
                        $$.startIndex = $2.startIndex;
                        $$.endIndex = $2.endIndex;
                        $$.baseType = $2.baseType;

                        printf("%snot\n", indent);
                    }
                ;
N_IDENT         : T_IDENT
                    {
                        prRule("N_IDENT", "T_IDENT");

                        $$.value = $1;
                    }
                ;
N_IDENTLST      : /* epsilon */
                    {
                        prRule("N_IDENTLST", "epsilon");
                    }
                | T_COMMA N_IDENT N_IDENTLST
                    {
                        prRule("N_IDENTLST", "T_COMMA N_IDENT N_IDENTLST");
                        identStack.push($2.value);
                    }
                ;
N_IDX           : N_INTCONST
                    {
                        prRule("N_IDX", "N_INTCONST");

                        $$.value = $1.value;
                        $$.type = $1.type;
                        $$.startIndex = $1.startIndex;
                        $$.endIndex = $1.endIndex;
                        $$.baseType = $1.baseType;
                    }
                ;
N_IDXRANGE      : N_IDX T_DOTDOT N_IDX
                    {
                        prRule("N_IDXRANGE", "N_IDX T_DOTDOT N_IDX");

                        int idx1 = atoi($1.value);
                        int idx2 = atoi($3.value);

                        if (idx1 > idx2) { yyerror("Start index must be less than or equal to end index of array"); }

                        $$.type = NOT_APPLICABLE;
                        $$.startIndex = atoi($1.value);
                        $$.endIndex = atoi($3.value);
                        $$.baseType = NOT_APPLICABLE;
                    }
                ;
N_IDXVAR        : N_ARRAYVAR T_LBRACK N_EXPR T_RBRACK
                    {
                        prRule("N_IDXVAR", "N_ARRAYVAR T_LBRACK N_EXPR T_RBRACK");

                        if ($3.type != INT && $3.baseType != INT) { yyerror("Index expression must be of type integer"); }

                        $$.value = $1.value;
                        $$.type = $1.type;
                        $$.startIndex = $1.startIndex;
                        $$.endIndex = $1.endIndex;
                        $$.baseType = $1.baseType;

                        printf("%sadd\n", indent);
                    }
                ;
N_INPUTLST      : /* epsilon */
                    {
                        prRule("N_INPUTLST", "epsilon");
                    }
                | T_COMMA N_INPUTVAR N_INPUTLST
                    {
                        prRule("N_INPUTLST", "T_COMMA N_INPUTVAR N_INPUTLST");
                    }
                ;
N_INPUTVAR      : N_VARIABLE
                    {
                        prRule("N_INPUTVAR", "N_VARIABLE");

                        if ($1.type != INT && $1.type != CHAR) { yyerror("Input variable must be of type integer or char"); }

                        $$.type = $1.type;
                        $$.startIndex = $1.startIndex;
                        $$.endIndex = $1.endIndex;
                        $$.baseType = $1.baseType;

                        findEntryInAnyScope($1.value);
                        TYPE_INFO inputVar = location->getEntry($1.value);

                        if (inputVar.type == CHAR) { printf("%scread\n", indent); }
                        else if (inputVar.type == INT || inputVar.type == BOOLEAN) { printf("%siread\n", indent); }
                        printf("%sst\n", indent);
                    }
                ;
N_INTCONST      : N_SIGN T_INTCONST
                    {
                        prRule("N_INTCONST", "N_SIGN T_INTCONST");

                        // If negative, prepend sign
                        if ($1.baseType < 0)
                        {
                            string sign = string($1.value);
                            string integer = string($2);
                            string signedInteger = sign + integer;
                            $$.value = strdup(const_cast<char*>(signedInteger.c_str()));
                        }
                        else { $$.value = $2; }

                        $$.type = INT;
                        $$.startIndex = NOT_APPLICABLE;
                        $$.endIndex = NOT_APPLICABLE;
                        $$.baseType = NOT_APPLICABLE;
                    }
                ;
N_MULTOP        : N_MULTOP_LOGIC
                    {
                        $$.op = $1.op;
                        $$.opType = LOGICAL_OP;
                    }
                | N_MULTOP_ARITH
                    {
                        $$.op = $1.op;
                        $$.opType = ARITHMETIC_OP;
                    }
                ;
N_MULTOP_LOGIC  : T_AND
                    {
                        $$.op = AND_OP;
                        prRule("N_MULTOP", "T_AND");
                    }
                ;
N_MULTOP_ARITH  : T_MULT
                    {
                        $$.op = MULT_OP;
                        prRule("N_MULTOP", "T_MULT");
                    }
                | T_DIV
                    {
                        $$.op = DIV_OP;
                        prRule("N_MULTOP", "T_DIV");
                    }
                ;
N_MULTOPLST     : /* epsilon */
                    {
                        prRule("N_MULTOPLST", "epsilon");
                        $$.type = NOT_APPLICABLE;
                    }
                | N_MULTOP N_FACTOR N_MULTOPLST
                    {
                        prRule("N_MULTOPLST", "N_MULTOP N_FACTOR N_MULTOPLST");

                        if ($1.opType == LOGICAL_OP && $2.type != BOOLEAN) { yyerror("Expression must be of type boolean"); }
                        else if ($1.opType == ARITHMETIC_OP && $2.type != INT) { yyerror("Expression must be of type integer"); }

                        if ($2.type == $3.type || $3.type == NOT_APPLICABLE) { $$.type = $2.type; }
                        else { $$.type = UNDEFINED; }

                        switch($1.op) {
                            case MULT_OP: printf("%smult\n", indent); break;
                            case DIV_OP: printf("%sdiv\n", indent); break;
                            case AND_OP: printf("%sand\n", indent); break;
                        }
                    }
                ;
N_OUTPUT        : N_EXPR
                    {
                        prRule("N_OUTPUT", "N_EXPR");

                        if ($1.type == ARRAY && $1.baseType != INT && $1.baseType != CHAR) { yyerror("Output expression must be of type integer or char"); }
                        else if ($1.type != ARRAY && $1.type != INT && $1.type != CHAR) { yyerror("Output expression must be of type integer or char"); }

                        if ($1.type == CHAR || ($1.type == ARRAY && $1.baseType == CHAR)) { printf("%scwrite\n", indent); }
                        else if ($1.type == INT || $1.type == BOOLEAN || 
                                ($1.type == ARRAY && ($1.baseType == INT || $1.baseType == BOOLEAN))) { 
                            printf("%siwrite\n", indent); 
                        }
                    }
                ;
N_OUTPUTLST     : /* epsilon */
                    {
                        prRule("N_OUTPUTLST", "epsilon");
                    }
                | T_COMMA N_OUTPUT N_OUTPUTLST
                    {
                        prRule("N_OUTPUTLST", "T_COMMA N_OUTPUT N_OUTPUTLST");
                    }
                ;
N_PROCDEC       : N_PROCHDR N_BLOCK
                    {
                        prRule("N_PROCDEC", "N_PROCHDR N_BLOCK");
                        currentLevel--;
                        procedures.pop();
                    }
                ;
N_PROCHDR       : T_PROC T_IDENT T_SCOLON
                    {
                        prRule("N_PROCHDR", "T_PROC T_IDENT T_SCOLON");
                        if (OUTPUT_PRODUCTIONS) { printf("___Adding %s to symbol table with type PROCEDURE\n", $2); }

                        if (!scopeStack.top().addEntry(SYMBOL_TABLE_ENTRY(string($2), UNDEFINED, nextLabel, currentLevel, PROCEDURE, UNDEFINED, UNDEFINED, PROCEDURE)))
                        {
                            yyerror("Multiply defined identifier");
							return 1;
                        }
                        procedures.push($2);
                        nextLabel++;
                        localOffset = 0;

                        openScope();
                    }
                ;
N_PROCDECPART   : /* epsilon */
                    {
                        prRule("N_PROCDECPART", "epsilon");
                    }
                | N_PROCDEC T_SCOLON N_PROCDECPART
                    {
                        prRule("N_PROCDECPART", "N_PROCDEC T_SCOLON N_PROCDECPART");
                    }
                ;
N_PROCIDENT     : T_IDENT
                    {
                        prRule("N_PROCIDENT", "T_IDENT");

                        if (!findEntryInAnyScope(string($1)))
						{
							yyerror("Undefined identifier");
							return 1;
						}
                        else
						{
							TYPE_INFO entry = location->getEntry(string($1));

                            $$.value = $1;
                            $$.type = entry.type;
                            $$.startIndex = entry.startIndex;
                            $$.endIndex = entry.endIndex;
                            $$.baseType = entry.baseType;
						}
                    }
                ;
N_PROCSTMT      : N_PROCIDENT
                    {
                        prRule("N_PROCSTMT", "N_PROCIDENT");

                        $$.value = $1.value;
                        $$.type = $1.type;
                        $$.startIndex = $1.startIndex;
                        $$.endIndex = $1.endIndex;
                        $$.baseType = $1.baseType;

                        TYPE_INFO callee, caller;

                        if (findEntryInAnyScope(string($1.value))) {
                            callee = location->getEntry(string($1.value));

                            if (!procedures.empty() && findEntryInAnyScope(procedures.top())) {
                                caller = location->getEntry(procedures.top());

                                if (caller.staticNestLevel >= callee.staticNestLevel) {
                                    for (int i = caller.staticNestLevel; i >= callee.staticNestLevel; i--) {
                                        printf("%spush %d, 0\n", indent, i);
                                    }
                                }
                            }
                        }

                        printf("%sjs L.%d\n", indent, callee.labelNum);
                    }
                ;
N_PROG          : N_PROGLBL T_IDENT T_SCOLON
                    {
                        prRule("N_PROG", "N_PROGLBL T_IDENT T_SCOLON N_BLOCK T_DOT");
                        if (OUTPUT_PRODUCTIONS) { printf("___Adding %s to symbol table with type PROGRAM\n", $2); }
						scopeStack.top().addEntry(SYMBOL_TABLE_ENTRY(string($2), UNDEFINED, UNDEFINED, UNDEFINED, PROGRAM, UNDEFINED, UNDEFINED, PROGRAM));
                    }
                  N_BLOCK T_DOT
                    {
                        printf("%shalt\nL.1:\n%sbss 500\n%send\n", indent, indent, indent);
                    }
                ;
N_PROGLBL       : T_PROG
                    {
                        prRule("N_PROGLBL", "T_PROG");
                        openScope();
                    }
                ;
N_READ          : T_READ T_LPAREN N_INPUTVAR N_INPUTLST T_RPAREN
                    {
                        

                        prRule("N_READ", "T_READ T_LPAREN N_INPUTVAR N_INPUTLST T_RPAREN");
                    }
                ;
N_RELOP         : T_LT
                    {
                        $$ = LT_OP;
                        prRule("N_RELOP", "T_LT");
                    }
                | T_GT
                    {
                        $$ = GT_OP;
                        prRule("N_RELOP", "T_GT");
                    }
                | T_LE
                    {
                        $$ = LTE_OP;
                        prRule("N_RELOP", "T_LE");
                    }
                | T_GE
                    {
                        $$ = GTE_OP;
                        prRule("N_RELOP", "T_GE");
                    }
                | T_EQ
                    {
                        $$ = EQ_OP;
                        prRule("N_RELOP", "T_EQ");
                    }
                | T_NE
                    {
                        $$ = NEQ_OP;
                        prRule("N_RELOP", "T_NE");
                    }
                ;
N_SIGN          : /* epsilon */
                    {
                        prRule("N_SIGN", "epsilon");
                        $$.type = NOT_APPLICABLE;
                        $$.baseType = NOT_APPLICABLE;
                    }
                | T_PLUS
                    {
                        prRule("N_SIGN", "T_PLUS");

                        $$.value = $1;
                        $$.baseType = 1;
                    }
                | T_MINUS
                    {
                        prRule("N_SIGN", "T_MINUS");

                        $$.value = $1;
                        $$.baseType = -1;
                    }
                ;
N_SIMPLE        : T_INT
                    {
                        $$.type = INT;
                        $$.startIndex = NOT_APPLICABLE;
                        $$.endIndex = NOT_APPLICABLE;
                        $$.baseType = NOT_APPLICABLE;

                        prRule("N_SIMPLE", "T_INT");
                    }
                | T_CHAR
                    {
                        $$.type = CHAR;
                        $$.startIndex = NOT_APPLICABLE;
                        $$.endIndex = NOT_APPLICABLE;
                        $$.baseType = NOT_APPLICABLE;

                        prRule("N_SIMPLE", "T_CHAR");
                    }
                | T_BOOL
                    {
                        $$.type = BOOLEAN;
                        $$.startIndex = NOT_APPLICABLE;
                        $$.endIndex = NOT_APPLICABLE;
                        $$.baseType = NOT_APPLICABLE;

                        prRule("N_SIMPLE", "T_BOOL");
                    }
                ;
N_SIMPLEEXPR    : N_TERM N_ADDOPLST
                    {
                        prRule("N_SIMPLEEXPR", "N_TERM N_ADDOPLST");

                        if ($1.type == $2.type || $2.type == NOT_APPLICABLE) { 
                            $$.type = $1.type;
                            $$.startIndex = $1.type;
                            $$.endIndex = $1.endIndex;
                            $$.baseType = $1.baseType;
                        }
                        else { 
                            $$.type = UNDEFINED; 
                            $$.startIndex = UNDEFINED;
                            $$.endIndex = UNDEFINED;
                            $$.baseType = UNDEFINED;
                        }
                    }
                ;
N_STMT          : N_ASSIGN
                    {
                        prRule("N_STMT", "N_ASSIGN");
                    }
                |  N_PROCSTMT
                    {
                        TYPE_INFO callee, caller;

                        if (findEntryInAnyScope(string($1.value))) {
                            callee = location->getEntry(string($1.value));

                            if (!procedures.empty() && findEntryInAnyScope(procedures.top())) {
                                caller = location->getEntry(procedures.top());

                                if (caller.staticNestLevel >= callee.staticNestLevel) {
                                    for (int i = callee.staticNestLevel; i <= caller.staticNestLevel; i++) {
                                        printf("%spop %d, 0\n", indent, i);
                                    }
                                }
                            }
                        }
                        prRule("N_STMT", "N_PROCSTMT");
                    }
                | N_READ
                    {
                        prRule("N_STMT", "N_READ");
                    }
                | N_WRITE
                    {
                        prRule("N_STMT", "N_WRITE");
                    }
                | N_CONDITION
                    {
                        prRule("N_STMT", "N_CONDITION");
                    }
                | N_WHILE
                    {
                        prRule("N_STMT", "N_WHILE");
                    }
                | N_COMPOUND
                    {
                        prRule("N_STMT", "N_COMPOUND");
                    }
                ;
N_STMTLST       : /* epsilon */
                    {
                        prRule("N_STMTLST", "epsilon");
                    }
                | T_SCOLON N_STMT N_STMTLST
                    {
                        prRule("N_STMTLST", "T_SCOLON N_STMT N_STMTLST");
                    }
                ;
N_STMTPART      :   { 
                        /*printSymbolTable(); 
                        cout << "=================================" << endl;*/
                    }
                    N_COMPOUND
                    {
                        prRule("N_STMTPART", "N_COMPOUND");
                    }
                ;
N_TERM          : N_FACTOR N_MULTOPLST
                    {
                        prRule("N_TERM", "N_FACTOR N_MULTOPLST");

                        if ($1.type == $2.type || $2.type == NOT_APPLICABLE) { 
                            $$.type = $1.type; 
                            $$.startIndex = $1.startIndex;
                            $$.endIndex = $1.endIndex;
                            $$.baseType = $1.baseType;
                        }
                        else { 
                            $$.type = UNDEFINED; 
                            $$.startIndex = UNDEFINED;
                            $$.endIndex = UNDEFINED;
                            $$.baseType = UNDEFINED;
                        }
                    }
                ;
N_TYPE          : N_SIMPLE
                    {
                        prRule("N_TYPE", "N_SIMPLE");

                        $$.type = $1.type;
                        $$.startIndex = NOT_APPLICABLE;
                        $$.endIndex = NOT_APPLICABLE;
                        $$.baseType = NOT_APPLICABLE;
                    }
                | N_ARRAY
                    {
                        prRule("N_TYPE", "N_ARRAY");

                        $$.type = $1.type;
                        $$.startIndex = $1.startIndex;
                        $$.endIndex = $1.endIndex;
                        $$.baseType = $1.baseType;
                    }
                ;
N_VARDEC        : N_IDENT N_IDENTLST T_COLON N_TYPE
                    {
                        prRule("N_VARDEC", "N_IDENT N_IDENTLST T_COLON N_TYPE");
                        if (OUTPUT_PRODUCTIONS) {
                            printf("___Adding %s to symbol table with type %s", $1.value, typeMap[$4.type]);

                            if (typeMap[$4.type] == "ARRAY") {
                                printf(" %d .. %d OF %s\n", $4.startIndex, $4.endIndex, typeMap[$4.baseType]);
                            }
                            else { printf("\n"); }
                        }

                        // If global variable, add globalOffset
                        if (currentLevel == 0) {
                            if (!scopeStack.top().addEntry(SYMBOL_TABLE_ENTRY(string($1.value), globalOffset, UNDEFINED, currentLevel, $4.type, $4.startIndex, $4.endIndex, $4.baseType)))
                            {
                                yyerror("Multiply defined identifier");
                                return 1;
                            }

                            if ($4.type == ARRAY) {
                                globalOffset += $4.endIndex - $4.startIndex + 1;
                            }
                            else { globalOffset++; }
                        }
                        else {
                            if (!scopeStack.top().addEntry(SYMBOL_TABLE_ENTRY(string($1.value), localOffset, UNDEFINED, currentLevel, $4.type, $4.startIndex, $4.endIndex, $4.baseType)))
                            {
                                yyerror("Multiply defined identifier");
                                return 1;
                            }
                            
                            if ($4.type == ARRAY) {
                                localOffset += $4.endIndex - $4.startIndex + 1;
                            }
                            else { localOffset++; }
                        }

                        // Frame size calculation
                        if ($4.type != ARRAY) {
                            $$ = 1 + identStack.size();
                        }
                        else {
                            $$ = $4.endIndex - $4.startIndex + 1 + identStack.size() * ($4.endIndex - $4.startIndex + 1);
                        }

                        // Also add all idents in the ident list to symbol table
                        while (!identStack.empty()) {
                            if (OUTPUT_PRODUCTIONS) {
                                printf("___Adding %s to symbol table with type %s", identStack.top(), typeMap[$4.type]);

                                if (typeMap[$4.type] == "ARRAY") {
                                    printf(" %d .. %d OF %s\n", $4.startIndex, $4.endIndex, typeMap[$4.baseType]);
                                }
                                else { printf("\n"); }
                            }

                            // If global variable, add globalOffset
                            if (currentLevel == 0) {
                                if (!scopeStack.top().addEntry(SYMBOL_TABLE_ENTRY(string(identStack.top()), globalOffset, UNDEFINED, currentLevel, $4.type, $4.startIndex, $4.endIndex, $4.baseType)))
                                {
                                    yyerror("Multiply defined identifier");
                                    return 1;
                                }

                                if ($4.type == ARRAY) {
                                    globalOffset += $4.endIndex - $4.startIndex + 1;
                                }
                                else { globalOffset++; }
                            }
                            else {
                                if (!scopeStack.top().addEntry(SYMBOL_TABLE_ENTRY(string(identStack.top()), localOffset, UNDEFINED, currentLevel, $4.type, $4.startIndex, $4.endIndex, $4.baseType)))
                                {
                                    yyerror("Multiply defined identifier");
                                    return 1;
                                }
                                
                                if ($4.type == ARRAY) {
                                    localOffset += $4.endIndex - $4.startIndex + 1;
                                }
                                else { localOffset++; }
                            }

                            identStack.pop();
                        }
                    }
                ;
N_VARDECLST     : /* epsilon */
                    {
                        prRule("N_VARDECLST", "epsilon");

                        // Set base for frame size calculation
                        $$ = 0;
                    }
                | N_VARDEC T_SCOLON N_VARDECLST
                    {
                        prRule("N_VARDECLST", "N_VARDEC T_SCOLON N_VARDECLST");

                        // Pass back frame size calculation
                        $$ = $1 + $3;
                    }
                ;
N_VARDECPART    : /* epsilon */
                    {
                        prRule("N_VARDECPART", "epsilon");

                        setFrameSize(0);
                    }
                | T_VAR N_VARDEC T_SCOLON N_VARDECLST
                    {
                        prRule("N_VARDECPART", "T_VAR N_VARDEC T_SCOLON N_VARDECLST");

                        setFrameSize($2 + $4);
                    }
                ;
N_VARIABLE      : N_ENTIREVAR
                    {
                        prRule("N_VARIABLE", "N_ENTIREVAR");

                        $$.value = $1.value;
                        $$.type = $1.type;
                        $$.startIndex = $1.startIndex;
                        $$.endIndex = $1.endIndex;
                        $$.baseType = UNDEFINED;
                    }
                | N_IDXVAR
                    {
                        prRule("N_VARIABLE", "N_IDXVAR");

                        $$.value = $1.value;
                        $$.type = $1.type;
                        $$.startIndex = $1.startIndex;
                        $$.endIndex = $1.endIndex;
                        $$.baseType = $1.baseType;
                    }
                ;
N_VARIDENT      : T_IDENT
                    {
                        prRule("N_VARIDENT", "T_IDENT");

                        if (!findEntryInAnyScope(string($1)))
						{
							yyerror("Undefined identifier");
							return 1;
						}
                        else
						{
							TYPE_INFO entry = location->getEntry(string($1));

                            if (entry.type == PROCEDURE) { yyerror("Procedure/variable mismatch"); }

                            $$.value = $1;
                            $$.type = entry.type;
                            $$.startIndex = entry.startIndex;
                            $$.endIndex = entry.endIndex;
                            $$.baseType = entry.baseType;
						}
                    }
                ;
N_WHILE         : T_WHILE 
                    {
                        printf("L.%d:\n", nextLabel);
                        loopTopLabelStack.push(nextLabel);
                        nextLabel++;
                        postLoopLabelStack.push(nextLabel);
                        nextLabel++;
                    }
                    N_EXPR
                    {
                        if ($3.type != BOOLEAN) { yyerror("Expression must be of type boolean"); }

                        printf("%sjf L.%d\n", indent, postLoopLabelStack.top());
                    } 
                    T_DO N_STMT
                    {
                        prRule("N_WHILE", "T_WHILE N_EXPR T_DO N_STMT");

                        printf("%sjp L.%d\n", indent, loopTopLabelStack.top());
                        loopTopLabelStack.pop();
                        printf("L.%d:\n", postLoopLabelStack.top());
                        postLoopLabelStack.pop();
                    }
                ;
N_WRITE         : T_WRITE T_LPAREN N_OUTPUT N_OUTPUTLST T_RPAREN
                    {
                        prRule("N_WRITE", "T_WRITE T_LPAREN N_OUTPUT N_OUTPUTLST T_RPAREN");
                    }
                ;
%%

#include "lex.yy.c"
extern FILE *yyin;


void openScope()
{
	scopeStack.push(SYMBOL_TABLE());
	if (OUTPUT_PRODUCTIONS) { printf("\n___Entering new scope...\n\n"); }

    return;
}

void closeScope()
{
	scopeStack.pop();
	if (OUTPUT_PRODUCTIONS) { printf("\n___Exiting scope...\n\n"); }

    return;
}

void prRule(const char *lhs, const char *rhs) 
{
    if (OUTPUT_PRODUCTIONS) { printf("%s -> %s\n", lhs, rhs); }
  
    return;
}

void ignoreComment() 
{
    char c, pc = 0;

    /* read and ignore the input until you get an ending token */
    while (((c = yyinput()) != ')' || pc != '*') && c != 0) {
        pc = c;
        if (c == '\n') lineNum++;
    }

    return;
}

void printTokenInfo(const char* tokenType, const char* lexeme) 
{
    if (OUTPUT_TOKENS) { printf("TOKEN: %-15s  LEXEME: %s\n", tokenType, lexeme); }
}

bool findEntryInAnyScope(const string theName)
{
	if (scopeStack.empty()) { return false; }
	bool found = scopeStack.top().findEntry(theName);

	if (found)
	{
		location = &scopeStack.top();
		return true;
	}
	else
	{
		// check in "next higher" scope
		SYMBOL_TABLE symbolTable = scopeStack.top();
		scopeStack.pop();
		found = findEntryInAnyScope(theName);
		scopeStack.push(symbolTable); // restore the stack
		return found;
	}
}

void printSymbolTable() 
{
    if (scopeStack.empty()) { return; }
    scopeStack.top().print();
    cout << "---------------------------" << endl;

    SYMBOL_TABLE temp = scopeStack.top();
    scopeStack.pop();
    printSymbolTable();
    scopeStack.push(temp);

    return;
}

void setFrameSize(const int& size) {
    SYMBOL_TABLE top = scopeStack.top();
    scopeStack.pop();
    bool found = false;

    if (!scopeStack.empty() && !procedures.empty()) {
        found = scopeStack.top().findEntry(procedures.top());
    }

    if (found) {
        scopeStack.top().setFrameSize(procedures.top(), size);
    }

    // Restore top of stack
    scopeStack.push(top);
    
    return;
}

int yyerror(const char *s) 
{
    printf("Line %d: %s\n", lineNum, s);
    exit(1);
}

int ckInt() 
{
    char *ptr;
    int	rc = 0;
    ptr = yytext;

    /* ignore sign and leading zeroes */
    if (*ptr == '-' || *ptr == '+')
        ++ptr;
    while (*ptr == '0')
        ++ptr;

    switch (*ptr) {
        case '1':	/* ALL are valid */
		    break;
        case '2':	/* it depends */
			if (strcmp(MAX_INT, ptr) < 0)
				rc = 1;
			break;

        default:	     /* ALL are invalid */
			rc = 1;
			break;
	}
  
    return rc;
}

int main(int argc, char** argv)
{
    // Populate the type map
    typeMap[UNDEFINED] = "UNDEFINED";
    typeMap[NOT_APPLICABLE] = "NOT_APPLICABLE";
    typeMap[INT] = "INTEGER";
    typeMap[BOOLEAN] = "BOOLEAN";
    typeMap[CHAR] = "CHAR";
    typeMap[ARRAY] = "ARRAY";
    typeMap[PROCEDURE] = "PROCEDURE";
    typeMap[PROGRAM] = "PROGRAM";
    

    // Output the OAL header and set next label number
    printf("%sinit L.%d, %d, L.%d, L.%d, L.%d\n", indent, 0, globalOffset, 1, 2, 3);
    nextLabel = 4;

    // Loop as long as there is anything to parse
    if (argc < 2) {
        printf("You must specify a file in the command line!\n"); exit(1);
    }
    yyin = fopen(argv[1], "r"); 

    // Loop as long as there is anything to parse
    do
    {
        yyparse();
    } 
    while (!feof(yyin));
    
    return 0;
}
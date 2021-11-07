/*
 	flex specifications for the MIPL language.
 	Written to meet requirements for CS5500, Fall 2018.

*/

/*
 *	Constant definitions are now in mipl.y
 */
%{

%}

/*
 *	Definitions of regular expressions
 */
QUOTE			'
UNDERSCORE		_

WSPACE		[ \t\r]+
NEWLINE          \n

SIGN			[+-]
COUNT_DIGIT	[1-9]
DIGIT			0|{COUNT_DIGIT}

LO_ALPHA		[a-z]
HI_ALPHA		[A-Z]
ALPHA			{LO_ALPHA}|{HI_ALPHA}

ALPHANUM		{ALPHA}|{DIGIT}

VALIDINT		(0*{COUNT_DIGIT}{DIGIT}{0,8})|(0*)
MAYBEINT		0*{COUNT_DIGIT}{DIGIT}{9,9}
INVALINT		0*{COUNT_DIGIT}{DIGIT}*

IDENT			({UNDERSCORE}|{ALPHA})({ALPHANUM}|{UNDERSCORE})*

CHARCONST		{QUOTE}.{QUOTE}
BADCHARCONST	{QUOTE}|{QUOTE}{QUOTE}

/*
 *	Tokens
 */
%%

"(*"		{
				/* checking for comment; if so, skip it */
				ignoreComment();
			}
"("			{
				printTokenInfo("T_LPAREN", yytext);
				return T_LPAREN;
			}
")"			{
				printTokenInfo("T_RPAREN", yytext);
				return T_RPAREN;
			}
"*"			{
				printTokenInfo("T_MULT", yytext);
				return T_MULT;
			}
"+"			{
				yylval.text = strdup(yytext);
				printTokenInfo("T_PLUS", yytext);
				return T_PLUS;
			}
","			{
				printTokenInfo("T_COMMA", yytext);
				return T_COMMA;
			}
"-"			{
				yylval.text = strdup(yytext);
				printTokenInfo("T_MINUS", yytext);
				return T_MINUS;
			}
".."		{
				printTokenInfo("T_DOTDOT", yytext);
				return T_DOTDOT;
			}
"."			{
				printTokenInfo("T_DOT", yytext);
				return T_DOT;
			}
":"			{
				printTokenInfo("T_COLON", yytext);
				return T_COLON;
			}
":="		{
				printTokenInfo("T_ASSIGN", yytext);
				return T_ASSIGN;
			}
";"			{
				printTokenInfo("T_SCOLON", yytext);
				return T_SCOLON;
			}
"<"			{
				printTokenInfo("T_LT", yytext);
				return T_LT;
			}
"<="		{
				printTokenInfo("T_LE", yytext);
				return T_LE;
			}
"<>"		{
				printTokenInfo("T_NE", yytext);
				return T_NE;
			}
"="			{
				printTokenInfo("T_EQ", yytext);
				return T_EQ;
			}
">"			{
				printTokenInfo("T_GT", yytext);
				return T_GT;
			}
">="		{
				printTokenInfo("T_GE", yytext);
				return T_GE;
			}
"["			{
				printTokenInfo("T_LBRACK", yytext);
				return T_LBRACK;
			}
"]"			{
				printTokenInfo("T_RBRACK", yytext);
				return T_RBRACK;
			}
"and"		{
				printTokenInfo("T_AND", yytext);
				return T_AND;
			}
"array"		{
				printTokenInfo("T_ARRAY", yytext);
				return T_ARRAY;
			}
"begin"		{
				printTokenInfo("T_BEGIN", yytext);
				return T_BEGIN;
			}
"boolean"	{
				printTokenInfo("T_BOOL", yytext);
				return T_BOOL;
			}
"char"		{
				printTokenInfo("T_CHAR", yytext);
				return T_CHAR;
			}
"div"		{
				printTokenInfo("T_DIV", yytext);
				return T_DIV;
			}
"do"		{
				printTokenInfo("T_DO", yytext);
				return T_DO;
			}
"else"		{
				printTokenInfo("T_ELSE", yytext);
				return T_ELSE;
			}
"end"		{
				printTokenInfo("T_END", yytext);
				return T_END;
			}
"false"		{
				printTokenInfo("T_FALSE", yytext);
				return T_FALSE;
			}
"if"		{
				printTokenInfo("T_IF", yytext);
				return T_IF;
			}
"integer"	{
				printTokenInfo("T_INT", yytext);
				return T_INT;
			}
"not"		{
				printTokenInfo("T_NOT", yytext);
				return T_NOT;
			}
"of"		{
				printTokenInfo("T_OF", yytext);
				return T_OF;
			}
"or"		{
				printTokenInfo("T_OR", yytext);
				return T_OR;
			}
"procedure"	{
				printTokenInfo("T_PROC", yytext);
				return T_PROC;
			}
"program"	{
				printTokenInfo("T_PROG", yytext);
				return T_PROG;
			}
"read"		{
				printTokenInfo("T_READ", yytext);
				return T_READ;
			}
"then"		{
				printTokenInfo("T_THEN", yytext);
				return T_THEN;
			}
"true"		{
				printTokenInfo("T_TRUE", yytext);
				return T_TRUE;
			}
"var"		{
				printTokenInfo("T_VAR", yytext);
				return T_VAR;
			}
"while"		{
				printTokenInfo("T_WHILE", yytext);
				return T_WHILE;
			}
"write"		{
				printTokenInfo("T_WRITE", yytext);
				return T_WRITE;
			}
{VALIDINT}	{
				yylval.text = strdup(yytext);
				printTokenInfo("T_INTCONST", yytext);
				return T_INTCONST;
			}
{MAYBEINT}	{
				if (ckInt())
				{
					yylval.text = strdup(yytext);
					printf("**** Invalid integer constant: %s\n", yytext);
					return T_UNKNOWN;
				}
				else
				{
					printTokenInfo("T_INTCONST", yytext);
					return T_INTCONST;
				}
			}
{INVALINT}	{
				printf("**** Invalid integer constant: %s\n", yytext);
				return T_UNKNOWN;
			}
{IDENT}		{
	 			yylval.text = strdup(yytext);
				printTokenInfo("T_IDENT", yytext);
				return T_IDENT;
			}
{BADCHARCONST}	{
				printf("**** Invalid character constant: %s\n", yytext);
				return T_UNKNOWN;
			}
{CHARCONST}	{
				yylval.text = strdup(yytext);
				printTokenInfo("T_CHARCONST", yytext);
				return T_CHARCONST;
			}
{NEWLINE}   {
                ++lineNum;
            }
{WSPACE}	{ }
.			{
				printTokenInfo("T_UNKNOWN", yytext);
				return T_UNKNOWN;
			}

%%


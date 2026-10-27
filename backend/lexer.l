%{
#include "parser.tab.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int line_no = 1;
int column_no = 1;

int token_line = 1;
int token_column = 1;
char current_lexeme[256] = "";

#define TOKEN_START \
    token_line = line_no; \
    token_column = column_no; \
    snprintf(current_lexeme, sizeof(current_lexeme), "%s", yytext);

#define MOVE_COLUMN \
    column_no += yyleng;
%}

%option noyywrap

%%
^[ \t]*#[ \t]*include[ \t]*[<"][^>\"]+[>\"][ \t]*\r?\n {
    column_no = 1;
    line_no++;
}

"int" {
    TOKEN_START
    MOVE_COLUMN
    return INT;
}

"float" {
    TOKEN_START
    MOVE_COLUMN
    return FLOAT;
}

"char" {
    TOKEN_START
    MOVE_COLUMN
    return CHAR;
}

"void" {
    TOKEN_START
    MOVE_COLUMN
    return VOID;
}

"if" {
    TOKEN_START
    MOVE_COLUMN
    return IF;
}

"else" {
    TOKEN_START
    MOVE_COLUMN
    return ELSE;
}

"while" {
    TOKEN_START
    MOVE_COLUMN
    return WHILE;
}

"for" {
    TOKEN_START
    MOVE_COLUMN
    return FOR;
}

"return" {
    TOKEN_START
    MOVE_COLUMN
    return RETURN;
}

"printf" {
    TOKEN_START
    MOVE_COLUMN
    return PRINTF;
}

"scanf" {
    TOKEN_START
    MOVE_COLUMN
    return SCANF;
}
"++" {
    TOKEN_START
    MOVE_COLUMN
    return INCREMENT;
}

"--" {
    TOKEN_START
    MOVE_COLUMN
    return DECREMENT;
}

"==" {
    TOKEN_START
    MOVE_COLUMN
    return EQ;
}

"!=" {
    TOKEN_START
    MOVE_COLUMN
    return NE;
}

">=" {
    TOKEN_START
    MOVE_COLUMN
    return GE;
}

"<=" {
    TOKEN_START
    MOVE_COLUMN
    return LE;
}

"&&" {
    TOKEN_START
    MOVE_COLUMN
    return AND;
}

"||" {
    TOKEN_START
    MOVE_COLUMN
    return OR;
}

"=" {
    TOKEN_START
    MOVE_COLUMN
    return ASSIGN;
}

">" {
    TOKEN_START
    MOVE_COLUMN
    return GT;
}

"<" {
    TOKEN_START
    MOVE_COLUMN
    return LT;
}

"+" {
    TOKEN_START
    MOVE_COLUMN
    return PLUS;
}

"-" {
    TOKEN_START
    MOVE_COLUMN
    return MINUS;
}

"*" {
    TOKEN_START
    MOVE_COLUMN
    return MULTIPLY;
}

"/" {
    TOKEN_START
    MOVE_COLUMN
    return DIVIDE;
}

"(" {
    TOKEN_START
    MOVE_COLUMN
    return LPAREN;
}

")" {
    TOKEN_START
    MOVE_COLUMN
    return RPAREN;
}

"{" {
    TOKEN_START
    MOVE_COLUMN
    return LBRACE;
}

"}" {
    TOKEN_START
    MOVE_COLUMN
    return RBRACE;
}

"[" {
    TOKEN_START
    MOVE_COLUMN
    return LBRACKET;
}

"]" {
    TOKEN_START
    MOVE_COLUMN
    return RBRACKET;
}

";" {
    TOKEN_START
    MOVE_COLUMN
    return SEMICOLON;
}

"," {
    TOKEN_START
    MOVE_COLUMN
    return COMMA;
}

[0-9]+(\.[0-9]+)? {
    TOKEN_START
    yylval.str = strdup(yytext);
    MOVE_COLUMN
    return NUMBER;
}

[a-zA-Z_][a-zA-Z0-9_]* {
    TOKEN_START
    yylval.str = strdup(yytext);
    MOVE_COLUMN
    return IDENTIFIER;
}

\"([^\"\\]|\\.)*\" {
    TOKEN_START
    yylval.str = strdup(yytext);
    MOVE_COLUMN
    return STRING;
}

"//".* {
    MOVE_COLUMN
}

[ \t\r]+ {
    MOVE_COLUMN
}

\n {
    line_no++;
    column_no = 1;
}

. {
    TOKEN_START

    fprintf(
        stderr,
        "\nLEXICAL ERROR\n"
        "Line   : %d\n"
        "Column : %d\n"
        "Character: '%s'\n",
        token_line,
        token_column,
        yytext
    );

    MOVE_COLUMN;
}

%%

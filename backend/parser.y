%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern int yylex();
extern FILE *yyin;

extern int line_no;
extern int column_no;

extern int token_line;
extern int token_column;
extern char current_lexeme[256];

int syntax_errors = 0;

void yyerror(const char *message);
void report_error(
    const char *type,
    const char *found,
    const char *expected,
    const char *suggestion
);
%}
%define parse.error detailed
%union {
    char *str;
}

%token <str> IDENTIFIER
%token <str> NUMBER
%token <str> STRING

%token INT FLOAT CHAR VOID

%token IF ELSE
%token WHILE FOR
%token RETURN

%token PRINTF SCANF

%token ASSIGN

%token PLUS MINUS MULTIPLY DIVIDE
%token INCREMENT DECREMENT
%token EQ NE
%token GE LE
%token GT LT
%token AND OR

%token LPAREN RPAREN
%token LBRACE RBRACE
%token LBRACKET RBRACKET

%token SEMICOLON COMMA
%right ASSIGN
%left OR
%left AND
%left EQ NE
%left GT LT GE LE
%left PLUS MINUS
%left MULTIPLY DIVIDE


%precedence LOWER_THAN_ELSE
%precedence ELSE

%%

program:
      function_list
      ;

function_list:
      function
    | function_list function
    ;

function:
      type IDENTIFIER LPAREN parameter_list_opt RPAREN compound_statement
    | type IDENTIFIER LPAREN error compound_statement
      {
          fprintf(
              stderr,
              "\n[RECOVERY] Invalid function declaration recovered at line %d, column %d\n",
              token_line,
              token_column
          );
          yyerrok;
      }
    ;
parameter_list_opt:
      %empty
    | parameter_list
    ;

parameter_list:
      parameter
    | parameter_list COMMA parameter
    ;

parameter:
      type IDENTIFIER
    ;

type:
      INT
    | FLOAT
    | CHAR
    | VOID
    ;

compound_statement:
      LBRACE statement_list_opt RBRACE

    | LBRACE error RBRACE
      {
          fprintf(
              stderr,
              "\n[RECOVERY] Invalid block recovered at line %d, column %d\n",
              token_line,
              token_column
          );
          yyerrok;
      }

    ;

statement_list_opt:
      %empty
    | statement_list
    ;
statement_list:
      statement
    | statement_list statement
    ;

statement:
      declaration
    | assignment
    | expression_statement
    | if_statement
    | while_statement
    | for_statement
    | return_statement
    | io_statement
    | compound_statement

        | error SEMICOLON
      {
          fprintf(
              stderr,
              "\n[RECOVERY] Invalid statement recovered near line %d, column %d\n",
              token_line,
              token_column
          );
          yyerrok;
      }

    ;
declaration:
      type declarator_list SEMICOLON

    | type declarator_list
      {
          report_error(
              "Missing Semicolon",
              "Next statement/token",
              ";",
              "Insert ';' at the end of the declaration"
          );
      }

    ;
declarator_list:
      declarator
    | declarator_list COMMA declarator
    ;

declarator:
      IDENTIFIER
    | IDENTIFIER ASSIGN expression
    | IDENTIFIER LBRACKET NUMBER RBRACKET
    | IDENTIFIER LBRACKET IDENTIFIER RBRACKET

    | IDENTIFIER LBRACKET NUMBER
      {
          report_error(
              "Missing Closing Bracket",
              ";",
              "]",
              "Insert ']' after the array size"
          );
      }
    ;

assignment:
      IDENTIFIER ASSIGN expression SEMICOLON

    | IDENTIFIER ASSIGN expression
      {
          report_error(
              "Missing Semicolon",
              "Next statement/token",
              ";",
              "Insert ';' at the end of the assignment"
          );
      }
    | IDENTIFIER LBRACKET expression RBRACKET ASSIGN expression SEMICOLON
    ;

expression_statement:
      expression SEMICOLON
    ;

if_statement:
      IF LPAREN expression RPAREN statement %prec LOWER_THAN_ELSE
    | IF LPAREN expression RPAREN statement ELSE statement

    | IF LPAREN error RPAREN statement
      {
          fprintf(stderr,
              "\n[RECOVERY] Invalid if condition near line %d, column %d\n",
              token_line, token_column);
          yyerrok;
      }

    | IF LPAREN expression LBRACE statement_list_opt RBRACE
      {
          report_error(
              "Missing Closing Parenthesis",
              "{",
              ")",
              "Insert ')' before '{' in the if condition"
          );
      }
    ;
while_statement:
      WHILE LPAREN expression RPAREN statement
    ;

for_statement:
      FOR LPAREN for_init SEMICOLON expression_opt SEMICOLON expression_opt RPAREN statement

    | FOR LPAREN for_init SEMICOLON expression_opt SEMICOLON expression_opt LBRACE statement_list_opt RBRACE
      {
          report_error(
              "Missing Closing Parenthesis",
              "{",
              ")",
              "Insert ')' before '{' in the for loop"
          );
      }
    ;

for_init:
      %empty
    | declaration_no_semicolon
    | assignment_no_semicolon
    ;

declaration_no_semicolon:
      type declarator_list
    ;

assignment_no_semicolon:
      IDENTIFIER ASSIGN expression
    ;

expression_opt:
      %empty
    | expression
    ;

return_statement:
      RETURN expression_opt SEMICOLON
    ;

io_statement:
      PRINTF LPAREN STRING RPAREN SEMICOLON
    | PRINTF LPAREN STRING COMMA expression RPAREN SEMICOLON
    | SCANF LPAREN STRING COMMA expression RPAREN SEMICOLON
    ;

expression:
      IDENTIFIER ASSIGN expression
    |  expression PLUS expression
    | expression MINUS expression
    | expression MULTIPLY expression
    | expression DIVIDE expression
    | expression EQ expression
    | expression NE expression
    | expression GT expression
    | expression LT expression
    | expression GE expression
    | expression LE expression
    | expression AND expression
    | expression OR expression
    | LPAREN expression RPAREN
    | primary_expression
    | IDENTIFIER INCREMENT
    | IDENTIFIER DECREMENT
    ;

primary_expression:
      IDENTIFIER
    | NUMBER
    | IDENTIFIER LBRACKET expression RBRACKET
    | IDENTIFIER LPAREN argument_list_opt RPAREN
    ;

argument_list_opt:
      %empty
    | argument_list
    ;

argument_list:
      expression
    | argument_list COMMA expression
    ;

%%
void yyerror(const char *message)
{
    syntax_errors++;

    printf(
        "\n================================================\n"
        "              SYNTAX ERROR #%d\n"
        "================================================\n"
        "Line       : %d\n"
        "Column     : %d\n"
        "Message    : %s\n"
        "Found      : '%s'\n",
        syntax_errors,
        token_line,
        token_column,
        message,
        current_lexeme
    );
    if (
        strcmp(current_lexeme, ";") == 0 &&
        strstr(message, "unexpected SEMICOLON") &&
        (strstr(message, "expecting IDENTIFIER") ||
         strstr(message, "expecting NUMBER"))
    ) {
        printf(
            "Error Type : Missing Expression\n"
            "Suggestion : Complete the expression before ';'\n"
        );
    }
    else if (strstr(message, "expecting SEMICOLON")) {
        printf(
            "Error Type : Possible Missing Semicolon\n"
            "Expected   : ;\n"
            "Suggestion : Check whether the preceding statement needs ';'\n"
        );
    }
    else if (strstr(message, "expecting RPAREN")) {
        printf(
            "Error Type : Possible Missing Closing Parenthesis\n"
            "Expected   : )\n"
            "Suggestion : Check the expression or function header\n"
        );
    }
    else if (strstr(message, "expecting RBRACE")) {
        printf(
            "Error Type : Possible Missing Closing Brace\n"
            "Expected   : }\n"
            "Suggestion : Check whether the current block is closed\n"
        );
    }
    else if (strstr(message, "expecting RBRACKET")) {
        printf(
            "Error Type : Possible Missing Closing Bracket\n"
            "Expected   : ]\n"
            "Suggestion : Check the array declaration or index\n"
        );
    }
    else if (strstr(message, "unexpected RPAREN")) {
    printf(
        "Error Type : Extra Closing Parenthesis\n"
        "Suggestion : Remove the unexpected ')'\n"
    );
}
    else if (strstr(message, "expecting LPAREN")) {
        printf(
            "Error Type : Unexpected Token\n"
            "Suggestion : Check the function call or control statement\n"
        );
    }
    else {
        printf(
            "Error Type : Syntax Error\n"
            "Suggestion : Review the unexpected token and surrounding syntax\n"
        );
    }

    printf("================================================\n");
} 


void report_error(
    const char *type,
    const char *found,
    const char *expected,
    const char *suggestion
)
{
    syntax_errors++;

    printf(
        "\n--------------------------------------------\n"
        "Syntax Error #%d\n"
        "--------------------------------------------\n"
        "Line       : %d\n"
        "Column     : %d\n"
        "Error Type : %s\n"
        "Found      : %s\n"
        "Expected   : %s\n"
        "Suggestion : %s\n"
        "--------------------------------------------\n",
        syntax_errors, token_line, token_column,
        type, found, expected, suggestion
    );
}

int main(int argc, char *argv[])
{
    printf("\n");
    printf("============================================\n");
    printf("       SYNTAXGUARD COMPILER TOOL\n");
    printf("============================================\n\n");

    if (argc < 2)
    {
        printf("Usage: %s <source_file>\n", argv[0]);
        return 1;
    }

    yyin = fopen(argv[1], "r");

    if (!yyin)
    {
        perror("Unable to open source file");
        return 1;
    }

    printf("Analyzing: %s\n\n", argv[1]);

    yyparse();

    fclose(yyin);

    printf("\n============================================\n");

    if (syntax_errors == 0)
    {
        printf(" RESULT: VALID SYNTAX\n");
        printf(" No syntax errors detected.\n");
    }
    else
    {
        printf(" RESULT: SYNTAX ERRORS FOUND\n");
        printf(" Total errors: %d\n", syntax_errors);
    }

    printf("============================================\n\n");

    return 0;
}
 

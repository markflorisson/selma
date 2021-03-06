grammar SELMA;


options {
	k=1;			// LL(1) - do not use LL(*)
	language=Java;		// target language is Java (= default)
	output=AST;		// build an AST
}

tokens {
	COLON		= ':';
	SEMICOLON	= ';';
	LPAREN		= '(';
	RPAREN		= ')';
	LCURLY		= '{';
	RCURLY		= '}';
	COMMA		= ',';
	EQ		= '=';
	APOSTROPHE	= '\'';
	UNDERSCORE	= '_';
	//arethemithic
	NOT		= '!';

	MULT		= '*';
	DIV		= '/';
	MOD		= '%';

	PLUS		= '+';
	MINUS		= '-';

	RELS		= '<';
	RELSE		= '<=';
	RELGE		= '>=';
	RELG		= '>';
	RELE		= '==';
	RELNE		= '<>';

	AND		= '&&';

	OR		= '||';

	//expressions
	BECOMES		= ':=';
	PRINT		= 'print';
	READ		= 'read';

	//declaration
	VAR		= 'var';
	CONST		= 'const';

	//types
	INT		= 'integer';
	BOOL		= 'boolean';
	CHAR		= 'character';
	//keywords
	IF		= 'if';
	THEN		= 'then';
	ELSE		= 'else';
	FI		= 'fi';

	WHILE		= 'while';
	DO		= 'do';
	OD		= 'od';

	FUNCDEF = 'function ';
	FUNCRETURN = 'return';
	FUNCTION = '@';

	UMIN;
	UPLUS;

	BEGIN;
	END;
	COMPOUND;
	EXPRESSION_STATEMENT;
}

@header {
  package SELMA;
}

@lexer::header {
  package SELMA;
}













// Parser rules - program at line 100 due to the report

program
	: compoundexpression EOF
		-> ^(BEGIN compoundexpression END)
	;

compoundexpression
	: cmp -> ^(COMPOUND cmp)
	;

cmp
  : ((declaration SEMICOLON!)* expression_statement? SEMICOLON! )+
  ;

//declaration

declaration
//	: VAR^ identifier (COMMA! identifier)* COLON! type
//	| CONST^ identifier (COMMA! identifier)* COLON! type EQ! unsignedConstant
	: VAR identifier (COMMA identifier)* COLON type
		-> ^(VAR type identifier)+
	| CONST identifier (COMMA identifier)* COLON type EQ unsignedConstant
		-> ^(CONST type unsignedConstant identifier)+
	| FUNCDEF^ identifier LPAREN! (funcpars SEMICOLON!)* RPAREN! funcbody
	;
funcpars : identifier (COMMA identifier)* COLON type -> (identifier type)+;
type
	: INT
	| BOOL
	| CHAR
	;

funcbody
	: COLON type LCURLY compoundexpression FUNCRETURN expression SEMICOLON RCURLY -> ^(FUNCRETURN type compoundexpression expression)
	| LCURLY! compoundexpression RCURLY!
	;









//expression statement at line 146

expression_statement
	: expression -> ^(EXPRESSION_STATEMENT expression)
	;
// note: - arithmetic can be "invisible" due to all the *-s that's why it is nested
// - assignment can be "invisible" due to the ? that's why it can also be only a identifier
expression
	: expr_assignment
	;

expr_assignment
	: expr_arithmetic (BECOMES^ expression)?
	;

expr_arithmetic
	: expr_al1
	;

	expr_al1					//expression arithmetic level 1
		: expr_al2 (OR^ expr_al2)*
		;

	expr_al2
		: expr_al3 (AND^ expr_al3)*
		;

	expr_al3
		: expr_al4 ((RELS|RELSE|RELG|RELGE|RELE|RELNE)^ expr_al4)*
		;

	expr_al4
		: expr_al5 ((PLUS|MINUS)^ expr_al5)*
		;

	expr_al5
		: expr_al6 ((MULT|DIV|MOD)^ expr_al6)*
		;

	expr_al6
		: PLUS expr_al7
			-> ^(UPLUS expr_al7)
		| MINUS expr_al7
			-> ^(UMIN expr_al7)
		| NOT expr_al7
			-> ^(NOT expr_al7)
		| expr_al7
		;

	expr_al7
		: unsignedConstant
		| identifier
//		| expr_assignment		//can be identifier
		| expr_read
		| expr_print
		| expr_if
		| expr_while
		| expr_closedcompound
		| expr_closed
		| expr_funccall
		;
expr_read
	: READ^ LPAREN! identifier (COMMA! identifier)* RPAREN!
	;

expr_print
	: PRINT LPAREN expression (COMMA expression)* RPAREN
		-> ^(PRINT expression+)
	;
expr_if
	: IF^ compoundexpression THEN compoundexpression (ELSE compoundexpression)? FI!
	;

expr_while
	: WHILE^ compoundexpression DO compoundexpression OD
	;

expr_funccall
	: FUNCTION^ identifier LPAREN! (expression COMMA!)* RPAREN!
	;

expr_closedcompound
	: LCURLY^ compoundexpression RCURLY
	;

expr_closed
	: LPAREN! expression RPAREN!
	;










//unsigned at line 244

unsignedConstant
	: boolval
	| charval
	| intval
	;

intval
	: NUMBER
	;

boolval
	: BOOLEAN
	;

charval
	: CHARV
	;

identifier
	: ID
	;

CHARV
  : APOSTROPHE (LETTER|UNDERSCORE) APOSTROPHE
  ;

BOOLEAN
	: TRUE
	| FALSE
	;

ID
	: LETTER (LETTER | DIGIT)*
	;

NUMBER
	: DIGIT+
	;

COMMENT
	: '//' ~('\n'|'\r')* '\r'? '\n' {$channel=HIDDEN;}
	| '/*' ( options {greedy=false;} : . )* '*/' {$channel=HIDDEN;}
	;
WS
	: ( ' '
	| '\t'
	| '\r'
	| '\n'
	) {$channel=HIDDEN;}
	;

fragment DIGIT
	: ('0'..'9')
	;

fragment LOWER
	: ('a'..'z')
	;

fragment UPPER
	: ('A'..'Z')
	;

fragment LETTER
  : LOWER
  | UPPER
  ;

fragment TRUE
	: 'true'
	;

fragment FALSE
	: 'false'
	;


//EOF


tree grammar SELMACompiler;

options {
  language = Java;
  output = template;
  tokenVocab = SELMA;
  ASTLabelType = SELMATree;
}

@header {
  package SELMA;
  import SELMA.SELMA;
  import SELMA.SELMATree.SR_Type;
  import SELMA.SELMATree.SR_Kind;
}

@rulecatch {
	catch (RecognitionException re) {
		throw re;
	}
}

@members {
  public SymbolTable<CompilerEntry> st = new SymbolTable<CompilerEntry>();
}

program
  : ^(BEGIN {st.openScope();} compoundexpression {st.closeScope();} END)
  -> program( instructions={$compoundexpression.st}, source_file={SELMA.inputFilename} )
  ;

compoundexpression
  : ^(node=COMPOUND (s+=declaration  | s+=expression)+)
  -> compound(instructions={$s})
  ;

declaration
  : ^(node=VAR INT id=ID)
  {st.enter($id,new CompilerEntry(SR_Type.INT,SR_Kind.VAR,st.nextAddr())); }
  -> declareVar(id={$id.text},type={"INT"},addr={st.nextAddr()-1})

  | ^(node=VAR BOOL id=ID)
  {st.enter($id,new CompilerEntry(SR_Type.BOOL,SR_Kind.VAR,st.nextAddr())); }
  -> declareVar(id={$id.text},type={"BOOL"},addr={st.nextAddr()-1})

  | ^(node=VAR CHAR id=ID)
  {st.enter($id,new CompilerEntry(SR_Type.CHAR,SR_Kind.VAR,st.nextAddr())); }
  -> declareVar(id={$id.text},type={"CHAR"},addr={st.nextAddr()-1})

  // store the const at a address? LOAD Or just copy LOADL?
  | ^(node=CONST INT val=NUMBER (id=ID)+)
  {st.enter($id,new CompilerEntry(SR_Type.INT,SR_Kind.CONST,st.nextAddr())); }
  -> declareConst(id={$id.text},value={$val.text},type={"INT"},addr={st.nextAddr()-1})

  | ^(node=CONST BOOL BOOLEAN (id=ID)+)
  {st.enter($id,new CompilerEntry(SR_Type.BOOL,SR_Kind.CONST,st.nextAddr()-1)); }
  -> declareConst(id={$id.text},value={($val.text.equals("true"))?"1":"0"},type={"BOOL"},addr={st.nextAddr()})

  | ^(node=CONST CHAR CHARV (id=ID)+)
  {st.enter($id,new CompilerEntry(SR_Type.CHAR,SR_Kind.CONST,st.nextAddr())); }
  -> declareConst(id={$id.text},value={Character.getNumericValue($val.text.charAt(1))},type={"CHAR"},addr={st.nextAddr()-1})
  ;

expression
//double arg expression
  : ^(MULT e1=expression e2=expression)
  -> biExpr(e1={$e1.st},e2={$e2.st},op={"mult"})

  | ^(DIV e1=expression e2=expression)
  -> biExpr(e1={$e1.st},e2={$e2.st},op={"div"})

  | ^(MOD e1=expression e2=expression)
  -> biExpr(e1={$e1.st},e2={$e2.st},op={"mod"})

  | ^(PLUS e1=expression e2=expression)
  -> biExpr(e1={$e1.st},e2={$e2.st},op={"add"})

  | ^(MINUS e1=expression e2=expression)
  -> biExpr(e1={$e1.st},e2={$e2.st},op={"sub"})

  | ^(RELS e1=expression e2=expression)
  -> biExpr(e1={$e1.st},e2={$e2.st},op={"lt"})

  | ^(RELSE e1=expression e2=expression)
  -> biExpr(e1={$e1.st},e2={$e2.st},op={"le"})

  | ^(RELG e1=expression e2=expression)
  -> biExpr(e1={$e1.st},e2={$e2.st},op={"gt"})

  | ^(RELGE e1=expression e2=expression)
  -> biExpr(e1={$e1.st},e2={$e2.st},op={"ge"})

  | ^(OR e1=expression e2=expression)
  -> biExpr(e1={$e1.st},e2={$e2.st},op={"or"})

  | ^(AND e1=expression e2=expression)
  -> biExpr(e1={$e1.st},e2={$e2.st},op={"and"})

  | ^(RELE e1=expression e2=expression)
  -> biExpr(e1={$e1.st},e2={$e2.st},op={"eq"})

  | ^(RELNE e1=expression e2=expression)
  -> biExpr(e1={$e1.st},e2={$e2.st},op={"neq"})

//single arg expression
  | ^(UPLUS e1=expression)
  {$st=$e1.st;}

  | ^(UMIN e1=expression)
  -> Expr(e1={$e1.st},op={"neg"})

  | ^(NOT e1=expression)
  -> Expr(e1={$e1.st},op={"not"})

//CONDITIONAL
  | ^(IF ec1=compoundexpression THEN ec2=compoundexpression (ELSE ec3=compoundexpression)?)
  -> if(ec1={$ec1.st},ec2={$ec2.st},ec3={$ec3.st})
  | ^(WHILE ec1=compoundexpression DO ec2=compoundexpression OD)
  -> while(ec1={$ec1.st},ec2={$ec2.st})

//IO
  | ^(READ (id=ID)+)

  | ^(PRINT expression+)

//ASSIGN
//  | ^(BECOMES expression expression)
  | ^(BECOMES node=ID e1=expression) { boolean isint = ($node.type == NUMBER  || 
  							$node.type == BOOLEAN || 
  							$node.type == LETTER); }
  	-> assign(id={$node.text},
  		  type={$node.type},
  		  addr={st.retrieve($node).addr},
  		  e1={$e1.st}, 
  		  isint={isint})

//closedcompound
  | LCURLY {st.openScope();} compoundexpression {st.closeScope();} RCURLY

//VALUES
  | node=NUMBER { int num = Integer.parseInt($node.text); }
    -> loadNum(val={$node.text}, iconst={num >= -1 && num <= 5}, bipush={num >= -128 && num <= 127})

  | node=BOOLEAN
    -> loadNum(val={($node.type==TRUE)?1:0}, iconst={TRUE})

  | node=LETTER
    -> loadNum(val={Character.getNumericValue($node.text.charAt(1))}, iconst={FALSE}, bipush={TRUE})

  | node=ID
    -> loadVal(id={$node.text}, addr={st.retrieve($node).addr})
  ;



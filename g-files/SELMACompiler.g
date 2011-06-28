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
  int curStackDepth;
  int maxStackDepth;

  int labelNum = 0;

  private void incrStackDepth() {
  	if (++curStackDepth > maxStackDepth)
  		maxStackDepth = curStackDepth;
  }
}

program
  : ^(node=BEGIN {st.openScope();} compoundexpression {st.closeScope();} END)
  -> program(instructions={$compoundexpression.st},
             source_file={SELMA.inputFilename},
             stack_limit={maxStackDepth},
             locals_limit={$node.localsCount})
  ;

compoundexpression
  : ^(node=COMPOUND (s+=declaration  | s+=expression_statement)+)
  -> compound(instructions={$s}, line={node.getLine()}, pop={$node.SR_type != SR_Type.VOID})
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


expression_statement
  : ^(node=EXPRESSION_STATEMENT e1=expression) { curStackDepth--; }
  -> exprStat(e1={e1.st}, line={$node.getLine()}, pop={$node.SR_type != SR_Type.VOID})
  ;

expression
//double arg expression
  : ^(node=MULT e1=expression e2=expression) { curStackDepth--; }
  -> biExpr(e1={$e1.st}, e2={$e2.st}, instr={"imul"}, line={node.getLine()}, op={"*"})

  | ^(node=DIV e1=expression e2=expression) { curStackDepth--; }
  -> biExpr(e1={$e1.st},e2={$e2.st},instr={"idiv"}, line={node.getLine()}, op={"/"})

  | ^(node=MOD e1=expression e2=expression) { curStackDepth--; }
  -> biExpr(e1={$e1.st},e2={$e2.st},instr={"imod"}, line={node.getLine()}, op={"\%"})

  | ^(node=PLUS e1=expression e2=expression) { curStackDepth--; }
  -> biExpr(e1={$e1.st},e2={$e2.st},instr={"iadd"}, line={node.getLine()}, op={"+"})

  | ^(node=MINUS e1=expression e2=expression) { curStackDepth--; }
  -> biExpr(e1={$e1.st},e2={$e2.st},instr={"isub"}, line={node.getLine()}, op={"-"})

  | ^(node=OR e1=expression e2=expression) { curStackDepth--; }
  -> biExpr(e1={$e1.st},e2={$e2.st},instr={"or"}, line={node.getLine()}, op={"or"})

  | ^(node=AND e1=expression e2=expression) { curStackDepth--; }
  -> biExpr(e1={$e1.st},e2={$e2.st},instr={"and"}, line={node.getLine()}, op={"and"})

  | ^(node=RELS e1=expression e2=expression) { curStackDepth--; }
  -> biExprJump(e1={$e1.st},e2={$e2.st},instr={"if_icmplt"}, line={node.getLine()},
  		op={"<"}, label_num1={labelNum++}, label_num2={labelNum++})

  | ^(node=RELSE e1=expression e2=expression) { curStackDepth--; }
  -> biExprJump(e1={$e1.st},e2={$e2.st},instr={"if_icmple"}, line={node.getLine()},
  		op={"<="}, label_num1={labelNum++}, label_num2={labelNum++})

  | ^(node=RELG e1=expression e2=expression) { curStackDepth--; }
  -> biExprJump(e1={$e1.st},e2={$e2.st},instr={"if_icmpgt"}, line={node.getLine()},
  		op={">"}, label_num1={labelNum++}, label_num2={labelNum++})

  | ^(node=RELGE e1=expression e2=expression) { curStackDepth--; }
  -> biExprJump(e1={$e1.st},e2={$e2.st},instr={"if_icmpge"}, line={node.getLine()},
  		op={">="}, label_num1={labelNum++}, label_num2={labelNum++})

  | ^(node=RELE e1=expression e2=expression) { curStackDepth--; }
  -> biExprJump(e1={$e1.st},e2={$e2.st},instr={"if_icmpeq"}, line={node.getLine()},
  		op={"="}, label_num1={labelNum++}, label_num2={labelNum++})

  | ^(node=RELNE e1=expression e2=expression) { curStackDepth--; }
  -> biExprJump(e1={$e1.st},e2={$e2.st},instr={"if_icmpne"}, line={node.getLine()},
  		op={"!="}, label_num1={labelNum++}, label_num2={labelNum++})

//single arg expression
  | ^(UPLUS e1=expression)
  {$st=$e1.st;}

  | ^(node=UMIN e1=expression)
  -> uExpr(e1={$e1.st}, instr={"ineg"}, line={node.getLine()}, op={"-"})

  | ^(node=NOT e1=expression)
  -> biExprJump(e1={$e1.st}, e2={"iconst_0"}, instr={"if_icmpeq"}, line={node.getLine()},
  		op={"not"}, label_num={labelNum++})

//CONDITIONAL
  | ^(IF ec1=compoundexpression THEN ec2=compoundexpression (ELSE ec3=compoundexpression)?)
  	{ boolean ec3NotEmpty = $ec3.st != null; }
  -> if(ec1={$ec1.st},ec2={$ec2.st},ec3={$ec3.st}, label_num1={labelNum++},
  	label_num2={ec3NotEmpty ? labelNum++ : 0}, ec3_not_empty={ec3NotEmpty})

  | ^(WHILE ec1=compoundexpression DO ec2=compoundexpression OD) { curStackDepth--; }
  -> while(ec1={$ec1.st},ec2={$ec2.st}, label_num1={labelNum++}, label_num2={labelNum++})

//IO
  | ^(READ id=ID)
  	-> read(id={$id.text}, addr={st.retrieve($id).addr}, dup_top={TRUE})

  | ^(READ id1=ID (id2=ID)+) { curStackDepth--; }
	-> read(id={$id1.text}, dup_top={FALSE})

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
  | node=NUMBER { incrStackDepth(); int num = Integer.parseInt($node.text); }
    -> loadNum(val={$node.text}, iconst={num >= -1 && num <= 5}, bipush={num >= -128 && num <= 127})

  | node=BOOLEAN { incrStackDepth(); }
    -> loadNum(val={($node.type==TRUE)?1:0}, iconst={TRUE})

  | node=LETTER { incrStackDepth(); }
    -> loadNum(val={Character.getNumericValue($node.text.charAt(1))}, iconst={FALSE}, bipush={TRUE})

  | node=ID { incrStackDepth(); }
    -> loadVal(id={$node.text}, addr={st.retrieve($node).addr})
  ;



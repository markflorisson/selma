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
  import SELMA.SELMATree.SR_Func;
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

    class StackDepthLabelCounter {
        public int curStackDepth;
        public int maxStackDepth;
        public int labelNum;
        public int nextAddr;
        public int localCount;
    }

    Stack<StackDepthLabelCounter> stack = new Stack<StackDepthLabelCounter>();

    private void incrStackDepth() {
    	if (curStackDepth > maxStackDepth)
    	    maxStackDepth = curStackDepth;
    }

    private void enterFuncScope() {
        StackDepthLabelCounter o = new StackDepthLabelCounter();
        o.curStackDepth = curStackDepth;
        o.maxStackDepth = maxStackDepth;
        o.labelNum = labelNum;
        o.nextAddr = st.nextAddr;
        o.localCount = st.localCount;

        stack.push(o); 
        
        st.openScope();
        curStackDepth = maxStackDepth = labelNum = st.nextAddr = st.localCount = 0;
    }
    
    private void leaveFuncScope() {
        StackDepthLabelCounter o = stack.pop();
        st.closeScope();
        curStackDepth = o.curStackDepth;
        maxStackDepth = o.maxStackDepth;
        labelNum = o.labelNum;
        st.nextAddr = o.nextAddr;
        st.localCount = o.localCount; 
    }

    private String getTypeDenoter(SR_Type type) {
        return getTypeDenoter(type, false);
    }

    private String getTypeDenoter(SR_Type type, boolean printing) {
        if (type == SR_Type.INT) {
            return "I";
        } else if (type == SR_Type.BOOL) {
            if (printing)
                return "Ljava/lang/String;";
            else
                return "I";
        } else if (type == SR_Type.VOID) {
            return "V";
        } else if (type == SR_Type.CHAR) {
            return "C";
        } else {
            throw new RuntimeException(":( Invalid type: " + type);
        }
    }
}

program
  : ^(node=BEGIN {st.openScope();} compoundexpression {st.closeScope();} END)
  { SELMATree expr = (SELMATree) $node.getChild(0); }
  -> program(instructions={$compoundexpression.st},
             source_file={SELMA.inputFilename},
             stack_limit={maxStackDepth + 3}, // +3 for print and other additionally loaded constants
             locals_limit={$node.localsCount + 1}, // +1 for the String[] argv parameter
             pop={expr.SR_type != SR_Type.VOID})
  ;

compoundexpression
  : ^(node=COMPOUND (s+=declaration  | s+=expression_statement)+)
  -> compound(instructions={$s}, line={node.getLine()}, pop={$node.SR_type != SR_Type.VOID})
  ;

declaration
  : ^(node=VAR INT id=ID)
  {st.enter($id, new CompilerEntry(SR_Type.INT, SR_Kind.VAR, st.nextAddr())); }
  //-> declareVar(id={$id.text},type={"INT"},addr={st.nextAddr()-1})

  | ^(node=VAR BOOL id=ID)
  {st.enter($id, new CompilerEntry(SR_Type.BOOL, SR_Kind.VAR, st.nextAddr())); }
  //-> declareVar(id={$id.text},type={"BOOL"},addr={st.nextAddr()-1})

  | ^(node=VAR CHAR id=ID)
  {st.enter($id, new CompilerEntry(SR_Type.CHAR, SR_Kind.VAR, st.nextAddr())); }
  //-> declareVar(id={$id.text},type={"CHAR"},addr={st.nextAddr()-1})

  // store the const at a address? LOAD Or just copy LOADL?
  | ^(node=CONST INT val=NUMBER (id=ID)+)
  {st.enter($id,new CompilerEntry(SR_Type.INT, SR_Kind.CONST, 0).setVal($val.text)); }
  //-> declareConst(id={$id.text}, val={$val.text}, type={"integer"}, addr={st.nextAddr()-1})

  | ^(node=CONST type=BOOL val=BOOLEAN id=ID)
  {st.enter($id, new CompilerEntry(SR_Type.BOOL, SR_Kind.CONST, 0).setBool($val.text)); }
  //-> declareConst(id={$id.text}, val={($val.text.equals("true"))?"1":"0"}, type={"boolean"}, addr={st.nextAddr()})

  | ^(node=CONST CHAR val=CHARV (id=ID)+)
  { char c = $node.text.charAt(1);
    st.enter($id, new CompilerEntry(SR_Type.CHAR, SR_Kind.CONST, 0).setChar(c)); }
  //-> declareConst(id={$id.text}, val={(int) c}, type={"character"}, addr={st.nextAddr()-1})

  | ^(node=FUNCDEF funcname=ID
  {
	st.enter($funcname, new CompilerEntry(SR_Type.VOID, SR_Kind.VAR, 0, SR_Func.YES));
	enterFuncScope();
	int paramCount = 0;
	List<String> paramTypeDenoters = new ArrayList<String>();
  } (param=ID typ1=(INT|BOOL|CHAR)
  {
  	SELMATree type1 = (SELMATree) $node.getChild(++paramCount * 2);
  	paramTypeDenoters.add(getTypeDenoter(type1.getSelmaType()));
  	st.addParamToFunc($funcname, param, type1);
  })*
  ( ^(return_node=FUNCRETURN (INT|BOOL|CHAR) (body+=compoundexpression) retexpr=expression)
  | (body+=compoundexpression)
  )
  {
  	SELMATree funcbody;
  	int stackLimit = maxStackDepth + 3;
  	int localsLimit = st.getLocalsCount();
  	String returnTypeDenoter;
  	
  	if ($return_node == null) {
  	    funcbody = (SELMATree) $node.getChild(paramCount * 2 + 1);
  	    returnTypeDenoter = "V";
  	} else {
  	    funcbody = (SELMATree) $return_node.getChild(1);
  	    SELMATree returnType = (SELMATree) $return_node.getChild(0);
  	    returnTypeDenoter = getTypeDenoter(returnType.getSelmaType());
	}
	leaveFuncScope();
  })
  -> function(funcname={$funcname.text}, 
              body={$body},
              param_types={paramTypeDenoters},
              return_expression={$retexpr.st},
              return_type={returnTypeDenoter}, 
              //pop={funcbody.SR_type != SR_Type.VOID && $node.SR_type == SR_Type.VOID},
              is_void={returnTypeDenoter.equals("V")},
              stack_limit={stackLimit},
              locals_limit={localsLimit + 1},
              line={$node.getLine()})
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
  -> biExpr(e1={$e1.st},e2={$e2.st},instr={"irem"}, line={node.getLine()}, op={"\%"})

  | ^(node=PLUS e1=expression e2=expression) { curStackDepth--; }
  -> biExpr(e1={$e1.st},e2={$e2.st},instr={"iadd"}, line={node.getLine()}, op={"+"})

  | ^(node=MINUS e1=expression e2=expression) { curStackDepth--; }
  -> biExpr(e1={$e1.st},e2={$e2.st},instr={"isub"}, line={node.getLine()}, op={"-"})

  | ^(node=OR e1=expression e2=expression) { curStackDepth--; }
  -> biExpr(e1={$e1.st},e2={$e2.st},instr={"ior"}, line={node.getLine()}, op={"or"})

  | ^(node=AND e1=expression e2=expression) { curStackDepth--; }
  -> biExpr(e1={$e1.st},e2={$e2.st},instr={"iand"}, line={node.getLine()}, op={"and"})

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
  -> not(e1={$e1.st}, line={node.getLine()},
  	 label_num1={labelNum++}, label_num2={labelNum++})

//CONDITIONAL
  | ^(node=IF { st.openScope(); } ec1=compoundexpression { st.closeScope(); } THEN 
  	      { st.openScope(); } ec2=compoundexpression { st.closeScope(); }
  	(ELSE { st.openScope(); } ec3=compoundexpression { st.closeScope(); })?)
  	{ boolean ec3NotEmpty = $ec3.st != null;
  	  SELMATree expr2 = (SELMATree) node.getChild(2);
  	  SELMATree expr3 = null;
  	  if (ec3NotEmpty)
  	  	expr3 = (SELMATree) node.getChild(4);
  	}
  -> if(ec1={$ec1.st},ec2={$ec2.st},ec3={$ec3.st}, label_num1={labelNum++},
  	label_num2={ec3NotEmpty ? labelNum++ : 0}, ec3_not_empty={ec3NotEmpty},
  	pop1={$node.SR_type == SR_Type.VOID && expr2.SR_type != SR_Type.VOID},
  	pop2={ec3NotEmpty && $node.SR_type == SR_Type.VOID && expr3.SR_type != SR_Type.VOID})

  | ^(node=WHILE 
      { st.openScope(); } ec1=compoundexpression { st.closeScope(); } DO 
      { st.openScope(); } ec2=compoundexpression { st.closeScope(); } OD)
  { SELMATree expr2 = (SELMATree) node.getChild(2);
    boolean pop = expr2.SR_type != SR_Type.VOID; 
    if (pop) 
        curStackDepth--; 
  }
  -> while(ec1={$ec1.st}, ec2={$ec2.st}, pop={pop}, 
           label_num1={labelNum++}, label_num2={labelNum++})

//IO

  | ^(node=READ ID+)
   	{ boolean isExpr = $node.SR_type != SR_Type.VOID;
          List<Integer> addrs = new ArrayList<Integer>();
          List<Boolean> isBool = new ArrayList<Boolean>();
          List<Boolean> isInt = new ArrayList<Boolean>();

          for (int i = 0; i < $node.getChildCount(); i++) {
              SELMATree child = (SELMATree) $node.getChild(i);

              addrs.add(st.retrieve($node.getChild(i)).addr);
              isBool.add(child.SR_type == SR_Type.BOOL);
              isInt.add(child.SR_type == SR_Type.INT);
          }
          //if (!isExpr)
          //    curStackDepth -= $node.getChildCount();
  	}
  	-> read(addrs={addrs}, dup_top={isExpr}, is_bool={isBool}, is_int={isInt},
            line={node.getLine()})

    | ^(node=PRINT (exprs+=expression)+)
    {
        boolean isExpr = $node.SR_type != SR_Type.VOID;
        int childCount = ((SELMATree) node).getChildCount();
        List<Integer> labelNums1 = new ArrayList<Integer>();
        List<Integer> labelNums2 = new ArrayList<Integer>();
        List<String> typeDenoters = new ArrayList<String>();
        List<Boolean> exprIsBool = new ArrayList<Boolean>();

        if (!isExpr)
            curStackDepth -= childCount;

        for (int i = 0; i < childCount; i++) {
            SELMATree child = (SELMATree) $node.getChild(i);
            boolean isBool = child.SR_type == SR_Type.BOOL;
            if (isBool) {
                labelNums1.add(labelNum++);
                labelNums2.add(labelNum++);
            } else {
                labelNums1.add(0);
                labelNums2.add(0);
            }
            typeDenoters.add(getTypeDenoter(child.SR_type, true));
            exprIsBool.add(isBool);
        }
    }
    -> print(exprs={$exprs}, type_denoters={typeDenoters}, dup_top={isExpr},
             expr_is_bool={exprIsBool},
             label_nums1={labelNums1}, label_nums2={labelNums2}, line={$node.getLine()})
//ASSIGN
  | ^(BECOMES node=ID e1=expression) { boolean isint = ($node.type == NUMBER  ||
                                       $node.type == BOOLEAN ||
                                       $node.type == LETTER); }
  	-> assign(id={$node.text},
      		  type={$node.type},
  	    	  addr={st.retrieve($node).addr},
  		      e1={$e1.st},
  		      isint={isint})

//closedcompound
  | ^(node=LCURLY {st.openScope();} cmp=compoundexpression {st.closeScope();} RCURLY)
	-> compound(instructions={$cmp.st}, line={$node.getLine()}, pop={false})
//VALUES
  | node=NUMBER { incrStackDepth();
                  int num = Integer.parseInt($node.text); }
    -> loadNum(val={$node.text}, iconst={num >= -1 && num <= 5}, bipush={num >= -128 && num <= 127})

  | node=BOOLEAN { incrStackDepth(); }
    -> loadNum(val={($node.text.equals("true")) ? 1 : 0}, iconst={true})

  | node=CHARV { incrStackDepth();
                 char c = $node.text.charAt(1); }
    //-> loadNum(val={(int) c}, iconst={false}, bipush={true})
    -> loadChar(val={(int) c}, char={$node.text}, line={$node.getLine()})

  | node=ID { incrStackDepth(); }
    {
    	CompilerEntry entry = st.retrieve(node);
    	boolean isConst = node.SR_kind == SR_Kind.CONST;
    }
    -> loadVal(id={$node.text}, addr={entry.addr}, val={entry.val}, is_const={isConst})
  ;



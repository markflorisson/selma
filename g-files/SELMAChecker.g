tree grammar SELMAChecker;

options {
	tokenVocab=SELMA;
	ASTLabelType=SELMATree;
	output=AST;
}

@header {
	package SELMA;
	import SELMA.SELMATree.SR_Type;
	import SELMA.SELMATree.SR_Kind;
	import SELMA.SELMATree.SR_Func;
}

// Alter code generation so catch-clauses get replaced with this action.
@rulecatch {
	catch (RecognitionException re) {
		/*
		if (node != null)
		    System.err.println(
		        String.format("Error on line \%d:\%d: \%s", node.getLine(),
		                                                    node.getCharPositionInLine(),
		                                                    re.getMessage()));
		*/
		throw re;
	}
}

@members {
	public SymbolTable<CheckerEntry> st = new SymbolTable<CheckerEntry>();

	public void matchType(Tree expectedType, SR_Type exprType) {
	    matchType(((SELMATree) expectedType).getSelmaType(), exprType);
	}

	public void matchType(Tree expectedType, Tree exprType) {
	    matchType(((SELMATree) expectedType).getSelmaType(),
	              ((SELMATree) exprType).getSelmaType());
	}

	public void matchType(SR_Type expectedType, SR_Type exprType) {
	    if (expectedType != exprType)
		throw new SELMAException(String.format(
			"Expected type \%s, got type \%s",
			expectedType,
			exprType));
	}
}

program
    : ^(node=BEGIN
        {st.openScope();}
        compoundexpression
        {$node.localsCount = st.getLocalsCount(); st.closeScope();}
        END)
	;

compoundexpression //do not open and close scope here (IF/WHILE)
	: ^(node=COMPOUND (declaration|expression_statement)+)
	{
	    SELMATree e1 = (SELMATree)node.getChild(node.getChildCount()-1);
	    if (e1.SR_type==SR_Type.VOID) {
	        node.SR_type=SR_Type.VOID;
	        node.SR_kind=null;
	    } else {
	        node.SR_type=e1.SR_type;
	        node.SR_kind=e1.SR_kind;
	    }
	}
	;

expression_statement
	: ^(node=EXPRESSION_STATEMENT expression)
	{
	    SELMATree e1 = (SELMATree)node.getChild(node.getChildCount()-1);
	    // System.err.println("..." + e1 + " " + e1.getLine());
	    $node.SR_type = e1.SR_type;
	    $node.SR_kind = e1.SR_kind;
	}
	;

declaration
	: ^(node=VAR type id=ID)
   {
       st.enter($id, new CheckerEntry(((SELMATree) node.getChild(0)).getSelmaType(),
                                      SR_Kind.VAR));
   }
	| ^(node=CONST type val id=ID)
    {
	     int type = node.getChild(0).getType();
         int val  = node.getChild(1).getType();

         switch (type) {
           case INT:
             if (val!=NUMBER) throw new SELMAException(id,"Expecting int-value");
             st.enter($id,new CheckerEntry(SR_Type.INT,SR_Kind.CONST));
             break;
           case BOOL:
             if (val!=BOOLEAN) throw new SELMAException(id,"Expecting bool-value");
             st.enter($id,new CheckerEntry(SR_Type.BOOL,SR_Kind.CONST));
             break;
           case CHAR:
             if (val!=CHARV) throw new SELMAException(id,"Expecting char-value");
             st.enter($id,new CheckerEntry(SR_Type.CHAR,SR_Kind.CONST));
             break;
         }
    }
	| ^(FUNCDEF funcname=ID
   {
       //enter as void
       st.enter($funcname, new CheckerEntry(SR_Type.VOID, SR_Kind.VAR, SR_Func.YES));
       st.openScope();
   }
       (param=ID typ1=(INT|BOOL|CHAR)
   {
	st.addParamToFunc($funcname, param, $typ1);
   }
		)*
		(
			^(node=FUNCRETURN type compoundexpression expression
   {
	SELMATree type = (SELMATree) node.getChild(0);
	SELMATree expr = (SELMATree) node.getChild(2);
	st.retrieve($funcname).type = expr.SR_type;
	
	matchType(type, expr.SR_type);
   })
 	| (compoundexpression))
   {
	//scope of function
	st.closeScope();
   });

type
  : node=INT
  | node=BOOL
  | node=CHAR
  ;

val
  : node=NUMBER
  | node=CHARV
  | node=BOOLEAN
  ;

expression
	: ^(node=(MULT|DIV|MOD|PLUS|MINUS) expression expression)
	 {
   SELMATree e1 = (SELMATree)node.getChild(0);
   SELMATree e2 = (SELMATree)node.getChild(1);

   if (e1.SR_type != SR_Type.INT || e2.SR_type != SR_Type.INT) {
    throw new SELMAException(
    	$node,
    	String.format("Wrong types must be int (found \%s and \%s)", e1.SR_type, e2.SR_type));
   }

   $node.SR_type = SR_Type.INT;

   if (e1.SR_kind == SR_Kind.CONST && e2.SR_kind == SR_Kind.CONST)
    $node.SR_kind = SR_Kind.CONST;
   else
    $node.SR_kind = SR_Kind.VAR;
   }

	| ^(node=(RELS|RELSE|RELG|RELGE) expression expression)
   {
   SELMATree e1 = (SELMATree)node.getChild(0);
   SELMATree e2 = (SELMATree)node.getChild(1);

   if (e1.SR_type!=SR_Type.INT || e2.SR_type!=SR_Type.INT)
    throw new SELMAException($node,"Wrong type must be int");
   $node.SR_type=SR_Type.BOOL;

   if (e1.SR_kind==SR_Kind.CONST && e2.SR_kind==SR_Kind.CONST)
    $node.SR_kind=SR_Kind.CONST;
   else
    $node.SR_kind=SR_Kind.VAR;
   }

	| ^(node=(OR|AND) expression expression)
   {
   SELMATree e1 = (SELMATree)node.getChild(0);
   SELMATree e2 = (SELMATree)node.getChild(1);

   if (e1.SR_type!=SR_Type.BOOL || e2.SR_type!=SR_Type.BOOL)
    throw new SELMAException($node,"Wrong type must be bool");
   $node.SR_type=SR_Type.BOOL;

   if (e1.SR_kind==SR_Kind.CONST && e2.SR_kind==SR_Kind.CONST)
    $node.SR_kind=SR_Kind.CONST;
   else
    $node.SR_kind=SR_Kind.VAR;
   }

	| ^(node=(RELE|RELNE) expression expression)
   {
   SELMATree e1 = (SELMATree)node.getChild(0);
   SELMATree e2 = (SELMATree)node.getChild(1);

   if (e1.SR_type!=e2.SR_type||e1.SR_type==SR_Type.VOID)
    throw new SELMAException($node,"Types must match and can't be void");
   $node.SR_type=SR_Type.BOOL;

   if (e1.SR_kind==SR_Kind.CONST && e2.SR_kind==SR_Kind.CONST)
    $node.SR_kind=SR_Kind.CONST;
   else
    $node.SR_kind=SR_Kind.VAR;
   }

	| ^(node=(UPLUS|UMIN) expression)
   {
   SELMATree e1 = (SELMATree)node.getChild(0);

   if (e1.SR_type!=SR_Type.INT)
    throw new SELMAException($node,"Wrong type must be int");
   $node.SR_type=SR_Type.INT;

   $node.SR_kind=e1.SR_kind;
   }

	| ^(node=NOT expression)
   {
        SELMATree e1 = (SELMATree)node.getChild(0);

        if (e1.SR_type != SR_Type.BOOL)
            throw new SELMAException(node, "Wrong type must be bool");

        node.SR_type = SR_Type.BOOL;
        node.SR_kind = e1.SR_kind;
   }

	| ^(node=IF {st.openScope();} compoundexpression
	     THEN {st.openScope();} compoundexpression {st.closeScope();}
	     (ELSE {st.openScope();} compoundexpression {st.closeScope();})?
	   {st.closeScope();})
   {
   SELMATree e1 = (SELMATree)node.getChild(0);
   SELMATree e2 = (SELMATree)node.getChild(2);
   SELMATree e3 = (SELMATree)node.getChild(4);

    if (e1.SR_type!=SR_Type.BOOL)
      throw new SELMAException(e1,"Expression must be boolean");

    if (e3==null) { //no else
      $node.SR_type=SR_Type.VOID;
      $node.SR_kind=null;
    } else { // there is a else
      if (e2.SR_type==e3.SR_type) {
        $node.SR_type=e3.SR_type;
	  if (e2.SR_kind==SR_Kind.CONST && e3.SR_kind==SR_Kind.CONST)
	    $node.SR_kind=SR_Kind.CONST;
	  else
	    $node.SR_kind=SR_Kind.VAR;
      } else {
        $node.SR_type=SR_Type.VOID;
        $node.SR_kind=null;
      }
    }
    }

	| ^(node=WHILE {st.openScope();} compoundexpression { st.closeScope(); }
	     DO {st.openScope();} compoundexpression {st.closeScope();}
	     OD) /*{st.closeScope();}) */
   {
   SELMATree e1 = (SELMATree)node.getChild(0);
   SELMATree e2 = (SELMATree)node.getChild(2);

   if (e1.SR_type!=SR_Type.BOOL)
    throw new SELMAException(e1,"Expression must be boolean");

   $node.SR_type=SR_Type.VOID;
   $node.SR_kind=null;

   }

	| ^(node=READ (id=ID
        {
            if (st.retrieve($id).kind!=SR_Kind.VAR)
                throw new SELMAException($id,"Must be a variable");
        })+
        {
            if ($node.getChildCount() == 1) {
                $node.SR_type = st.retrieve(node.getChild(0)).type;
                $node.SR_kind = SR_Kind.VAR;
            } else {
                $node.SR_type = SR_Type.VOID;
                $node.SR_kind = null;
            }
        }
	   )

	| ^(node=PRINT expression+)
	 {
    for (int i=0; i<((SELMATree)node).getChildCount(); i++){
      if (((SELMATree)node.getChild(i)).SR_type == SR_Type.VOID)
         throw new SELMAException($node, "Can not be of type void");
    }
       if ($node.getChildCount() == 1){
          $node.SR_type = ((SELMATree) node.getChild(0)).SR_type;
          $node.SR_kind = SR_Kind.VAR;
       } else {
         $node.SR_type = SR_Type.VOID;
         $node.SR_kind = null;
       }
	 }
     -> ^(PRINT expression)+

	| ^(node=FUNCTION ID expression*)
{
//retrieve function (if existent)
SELMATree func = (SELMATree)$node;
CheckerEntry entry = st.retrieve($ID);
$node.SR_type=entry.type;
$node.SR_kind=entry.kind;

//matchparamlists
//same length?
int argc = func.getChildCount()-1;
if (entry.params.size() != argc)
	throw new SELMAException(node, String.format(
		"\%s takes \%d arguments (\%d given)", $ID.text, entry.params.size(), argc));
//every entry matches?
for (int i=1; i<func.getChildCount(); i++){
    SELMATree expr = (SELMATree)func.getChild(i);
    if (expr.SR_type != entry.params.get(i-1).type)
	throw new SELMAException(expr,"Param is not of the right type");
}
}


	| ^(node=BECOMES expression expression)
	 {
   SELMATree e1 = (SELMATree)node.getChild(0);
   SELMATree e2 = (SELMATree)node.getChild(1);
   if (e1.getType()!=ID)
    throw new SELMAException(e1,"Must be a identifier");

   CheckerEntry ident = st.retrieve(e1);

   if (ident.kind!=SR_Kind.VAR)
    throw new SELMAException(e1,"Must be a variable");
   if (ident.type!=e2.SR_type)
    throw new SELMAException(e1,"Right side must be the same type "+ident.type+"/"+e2.SR_type);

   $node.SR_type=ident.type;
   $node.SR_kind=SR_Kind.VAR;
	 }

	| ^(node=LCURLY {st.openScope();} compoundexpression {st.closeScope();} RCURLY)
	{
	    SELMATree e1 = (SELMATree) node.getChild(0);
	    $node.SR_type = e1.SR_type;
	    $node.SR_kind = e1.SR_kind;
	}

	| node=NUMBER
	 {
	 $node.SR_type=SR_Type.INT;
	 $node.SR_kind=SR_Kind.CONST;
	 }

	| node=BOOLEAN
   {
   $node.SR_type=SR_Type.BOOL;
   $node.SR_kind=SR_Kind.CONST;
   }

	| node=CHARV
   {
   $node.SR_type=SR_Type.CHAR;
   $node.SR_kind=SR_Kind.CONST;
   }

	| node=ID
	 {
	 CheckerEntry entry = st.retrieve($node);
	 $node.SR_type=entry.type;
	 $node.SR_kind=entry.kind;
	 }
	;



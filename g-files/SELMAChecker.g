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
}

// Alter code generation so catch-clauses get replaced with this action.
@rulecatch {
	catch (RecognitionException re) {
		throw re;
	}
}

@members {
	public SymbolTable<CheckerEntry> st = new SymbolTable<CheckerEntry>();
}

program
	: ^(BEGIN {st.openScope();} compoundexpression {st.closeScope();} END)
	;

compoundexpression //do not open and close scope here (IF/WHILE)
	: ^(node=COMPOUND (declaration|expression)+)
	 {
	   SELMATree e1 = (SELMATree)node.getChild(node.getChildCount()-1);
	   if (e1.SR_type==SR_Type.VOID) {
      $node.SR_type=SR_Type.VOID;
      $node.SR_kind=null;
     } else {
      $node.SR_type=e1.SR_type;
      $node.SR_kind=e1.SR_kind;
     }
	 }
	;

declaration
	: ^(node=VAR type id=ID)
   {
   int type = node.getChild(0).getType();

   switch (type){
     case INT:
     st.enter($id,new CheckerEntry(SR_Type.INT,SR_Kind.VAR));
     break;
     case BOOL:
     st.enter($id,new CheckerEntry(SR_Type.BOOL,SR_Kind.VAR));
     break;
     case CHAR:
     st.enter($id,new CheckerEntry(SR_Type.CHAR,SR_Kind.VAR));
     break;
   }
   }
	| ^(node=CONST type val id=ID)
	 {
   int type = node.getChild(0).getType();
   int val  = node.getChild(1).getType();

	 switch (type){
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
	;

type
  : INT
  | BOOL
  | CHAR
  ;

val
  : NUMBER
  | CHARV
  | BOOLEAN
  ;

expression
	: ^(node=(MULT|DIV|MOD|PLUS|MINUS) expression expression)
	 {
   SELMATree e1 = (SELMATree)node.getChild(0);
   SELMATree e2 = (SELMATree)node.getChild(1);

   if (e1.SR_type!=SR_Type.INT || e2.SR_type!=SR_Type.INT)
    throw new SELMAException($node,"Wrong type must be int");
   $node.SR_type=SR_Type.INT;

   if (e1.SR_kind==SR_Kind.CONST && e2.SR_kind==SR_Kind.CONST)
    $node.SR_kind=SR_Kind.CONST;
   else
    $node.SR_kind=SR_Kind.VAR;
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

	| ^(node=(NOT) expression)
   {
   SELMATree e1 = (SELMATree)node.getChild(0);

   if (e1.SR_type!=SR_Type.BOOL)
    throw new SELMAException($node,"Wrong type must be bool");
   $node.SR_type=SR_Type.BOOL;

   $node.SR_kind=e1.SR_kind;
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

	| ^(node=WHILE {st.openScope();}compoundexpression
	     DO {st.openScope();} compoundexpression {st.closeScope();}
	    OD{st.closeScope();})
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
	       if ($node.getChildCount()==1){
	        $node.SR_type=((SELMATree)node.getChild(0)).SR_type;
          $node.SR_kind=SR_Kind.VAR;
       } else {
         $node.SR_type=SR_Type.VOID;
         $node.SR_kind=null;
       }
	     }
	   )

	| ^(node=PRINT expression+
	 {
    for (int i=0; i<((SELMATree)node).getChildCount(); i++){
      if (((SELMATree)node.getChild(i)).SR_type==SR_Type.VOID)
         throw new SELMAException($node,"Can not be of type void");
    }
       if ($node.getChildCount()==1){
          $node.SR_type=((SELMATree)node.getChild(0)).SR_type;
          $node.SR_kind=SR_Kind.VAR;
       } else {
         $node.SR_type=SR_Type.VOID;
         $node.SR_kind=null;
       }
	 })

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

	| LCURLY {st.openScope();} compoundexpression {st.closeScope();} RCURLY

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

	| node=LETTER
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


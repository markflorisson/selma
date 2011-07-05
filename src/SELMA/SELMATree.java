package SELMA;
import java.util.Arrays;
import SELMA.SELMAException;

import org.antlr.runtime.tree.*;
import org.antlr.runtime.Token;

/**
 * Custom tree. Heeft constanten die het type aangeven, de kind en of het een functie is.
 */
public class SELMATree extends CommonTree {

	public SELMATree(){
		super();
	}

	public SELMATree(Token t){
		super(t);
	}

	public SELMATree(SELMATree t){
		super(t);
	}

	public enum SR_Type {INT,BOOL,CHAR,VOID};
	public enum SR_Kind {VAR, CONST};
	public enum SR_Func {YES, NO};

	public SR_Type SR_type = null;
	public SR_Kind SR_kind = null;
	public SR_Func SR_func = null;

    /* Given a type as AST Tree node, return the SR_Type */
    public SR_Type getSelmaType() throws SELMAException {
        switch (token.getType()) {
          case SELMAChecker.INT:
            return SR_Type.INT;
          case SELMAChecker.BOOL:
            return SR_Type.BOOL;
          case SELMAChecker.CHAR:
            return SR_Type.CHAR;
          default:
            try {
                throw new SELMAException("Invalid type: " + token.getType());
            } catch (SELMAException e) {
                e.printStackTrace();
                throw e;
            }
        }
    }

	public String toStringTree() {
		return toStringTree(1);
	}

	public String toStringTree(int level) {
		if ( children==null || children.size()==0 ) {
			return this.toString();
		}
		StringBuffer buf = new StringBuffer();
		if ( !isNil() ) {
			buf.append("\n");
			char[] c = new char[level];
			Arrays.fill(c, '\t');
			buf.append(c);
			buf.append("(");
			buf.append(this.toString());
			buf.append(' ');
		}
		for (int i = 0; children!=null && i < children.size(); i++) {
			SELMATree t = (SELMATree)children.get(i);
			if ( i>0 ) {
				buf.append(' ');
			}
			buf.append(t.toStringTree(level+1));
		}
		if ( !isNil() ) {
			buf.append(")");
			buf.append("\n");
			char[] c = new char[level];
			Arrays.fill(c, '\t');
			buf.append(c);
		}
		return buf.toString();
	}


	public String toString() {
		String s = super.toString();
		s += " [";

		if (SR_type == null)
			s+="NULL";
		else
			switch (SR_type){
				case BOOL:
					s+="bool";
					break;
				case INT:
					s+="int";
					break;
				case CHAR:
					s+="char";
					break;
				case VOID:
					s+="void";
					break;
			}

		s+=",";

		if (SR_kind == null)
			s+="NULL";
		else
			switch (SR_kind){
				case VAR:
					s+="var";
					break;
				case CONST:
					s+="const";
					break;
			}

		s+=",";

		if (SR_func == null)
			s+="NULL";
		else
			switch (SR_func){
				case NO:
					s+="no_func";
					break;
				case YES:
					s+="function";
					break;
			}

		s+="]";

		return s;
	}
}


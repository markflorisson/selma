package SELMA;

import SELMA.SELMATree.SR_Kind;
import SELMA.SELMATree.SR_Type;
import SELMA.SELMATree.SR_Func;
import java.util.ArrayList; 
import org.antlr.runtime.tree.Tree;

public class CheckerEntry extends IdEntry {
    
class Param {
String name; SR_Type type;
Param (String name, SR_Type type){
this.name=name;this.type=type;
}
}

    public SR_Type type;
    public SR_Kind kind;
    public SR_Func func;
    public ArrayList<Param> params;


	public CheckerEntry(SR_Type type, SR_Kind kind) {
		super();
    	this.type=type;
    	this.kind=kind;
	this.func=SR_Func.NO;
	}
	public CheckerEntry(SR_Type type, SR_Kind kind, SR_Func func) {
		super();
    	this.type=type;
    	this.kind=kind;
	this.func=func;
	params=new ArrayList<Param>();
	}
	public void addParam(Tree id, SR_Type type) {
	    	String name = id.getText();
		params.add(new Param(name,type));
	}
	public String toString() {
		String s = "";
		s += " [";

		s+=level;

		s+=",";

		if (type == null)
			s+="NULL";
		else
			switch (type){
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

		if (kind == null)
			s+="NULL";
		else
			switch (kind){
				case VAR:
					s+="var";
					break;
				case CONST:
					s+="const";
					break;
			}


		s+=",";

		if (func == null)
			s+="NULL";
		else
			switch (func){
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

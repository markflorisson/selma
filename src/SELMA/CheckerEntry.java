package SELMA;

import SELMA.SELMATree.SR_Kind;
import SELMA.SELMATree.SR_Type;

public class CheckerEntry extends IdEntry {
    public SR_Type type;
    public SR_Kind kind;

	public CheckerEntry(SR_Type type, SR_Kind kind) {
		super();
    	this.type=type;
    	this.kind=kind;
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

		s+="]";

		return s;
	}

}

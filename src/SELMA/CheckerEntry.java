package SELMA;

import SELMA.SELMATree.SR_Kind;
import SELMA.SELMATree.SR_Type;
import SELMA.SELMATree.SR_Func;
import java.util.ArrayList;
import org.antlr.runtime.tree.Tree;

/**
 * Symbol table entry for the Checker phase.
 */
public class CheckerEntry extends IdEntry {

    /** Houd de naam en type van een parameter voor een functie bij */
    class Param {
        String name; SR_Type type;

        Param (String name, SR_Type type) {
            this.name = name;
            this.type = type;
        }
    }

    /** Het type van de entry */
    public SR_Type type;
    /** Wat voor soort entry het is (e.g. constante, variabele) */
    public SR_Kind kind;
    /** Of deze entry voor een functie is */
    public SR_Func func;
    /** Parameters voor een functie */
    public ArrayList<Param> params;

    public boolean initialized;

	public CheckerEntry(SR_Type type, SR_Kind kind) {
		super();
    	this.type = type;
    	this.kind = kind;
	    this.func = SR_Func.NO;
	}
	public CheckerEntry(SR_Type type, SR_Kind kind, SR_Func func) {
		super();
    	this.type = type;
    	this.kind = kind;
	    this.func = func;
	    params = new ArrayList<Param>();
	}

    /**
     * Add a parameter with id id and type type to this function entry.
     */
    public void addParam(Tree id, SR_Type type) {
	    String name = id.getText();
		params.add(new Param(name,type));
	}

    /**
     * See whether the variable is initialized
     */
    public boolean isInitialized(SymbolTable st) {
        if (kind == SR_Kind.VAR)
            return initialized || (st.funclevel > 0 && level == 0);

        return true;
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

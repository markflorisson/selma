package SELMA;

import SELMA.SELMATree.SR_Kind;
import SELMA.SELMATree.SR_Type;
import SELMA.SELMATree.SR_Func;

public class CompilerEntry extends CheckerEntry {
	public int addr;
    public int val;
    public String signature;
    public boolean isGlobal;

    int _mangleID;
    static int mangleId = 0;

	public CompilerEntry(SR_Type type, SR_Kind kind, int addr) {
		super(type, kind);
		this.addr = addr;
        _mangleID++;
	}

    public CompilerEntry(SR_Type type, SR_Kind kind, int addr, SR_Func func) {
        super(type, kind, func);
        this.addr = addr;
        _mangleID++;
    }

    public CompilerEntry setVal(String intval) {
        val = Integer.parseInt(intval);
        return this;
    }

    public CompilerEntry setBool(String bool) {
        val = bool.equals("true") ? 1 : 0;
        return this;
    }

    public CompilerEntry setChar(int c) {
        val = c;
        // System.err.println("Setting " + c + " on " + addr + " = " + val);
        return this;
    }

    public String getIdentifier(String ident) {
        return ident + "_" + _mangleID;
        /*
        String result = ident;
        for (int i = 0; i < level; i++)
            result = "_" + result;
        return result;    */
    }
}

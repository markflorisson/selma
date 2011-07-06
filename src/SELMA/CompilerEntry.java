package SELMA;

import SELMA.SELMATree.SR_Kind;
import SELMA.SELMATree.SR_Type;
import SELMA.SELMATree.SR_Func;

/**
 * Symbol table entry voor de Compiler phase.
 */
public class CompilerEntry extends CheckerEntry {
    /** Address van een locale variabele */
	public int addr;
    /** Value van een constante */
    public int val;
    /** Signature van een functie */
    public String signature;
    /** Geeft aan of de entry bij een globale variabele hoort */
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

    /**
     * Zet een waarde voor deze constante.
     */
    public CompilerEntry setVal(String intval) {
        val = Integer.parseInt(intval);
        return this;
    }

    /**
     * Zet een waarde voor deze constante.
     */
    public CompilerEntry setBool(String bool) {
        val = bool.equals("true") ? 1 : 0;
        return this;
    }

    /**
     * Zet een waarde voor deze constante.
     */
    public CompilerEntry setChar(int c) {
        val = c;
        // System.err.println("Setting " + c + " on " + addr + " = " + val);
        return this;
    }

    /**
     * @param ident De identifier voor deze variabele
     * @return Een unieke identifier met betrekking tot scope (voor Jasmin .fields (globale variabelen))
     */
    public String getIdentifier(String ident) {
        return ident + "_" + _mangleID;
    }
}

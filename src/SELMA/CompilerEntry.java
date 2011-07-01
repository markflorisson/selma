package SELMA;

import SELMA.SELMATree.SR_Kind;
import SELMA.SELMATree.SR_Type;

public class CompilerEntry extends CheckerEntry {
	public int addr;

	public CompilerEntry(SR_Type type, SR_Kind kind, int addr) {
		super(type, kind);
		this.addr=addr;
	}

}

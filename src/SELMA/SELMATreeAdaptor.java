package SELMA;
import org.antlr.runtime.tree.*;
import org.antlr.runtime.Token;

public class SELMATreeAdaptor extends CommonTreeAdaptor {
	public Object create(Token t) {
		return new SELMATree(t);
    }
	public Object dupNode (Object t) {
		return new SELMATree((SELMATree)t);
	}
}

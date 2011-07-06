package SELMA;

/** SuperClass for entries in the symbol table */
public class IdEntry {
	public int  level = -1;
    public IdEntry(){
    }
	public String toString() {
		return " ["+level+"]";
	}
}

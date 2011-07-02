package SELMA;

import java.util.*;
import SELMA.SELMATree.SR_Kind;

import org.antlr.runtime.RecognitionException;
import org.antlr.runtime.tree.Tree;

public class SymbolTable<Entry extends IdEntry> {
	public int nextAddr = 1;
    private int currentLevel;
    private Map<String, Stack<Entry>> entries;

    int localCount;

    public int nextAddr(){
    	return nextAddr;
    }

	/**
     * Constructor.
     * @ensure  this.currentLevel() == -1
     */
    public SymbolTable() {
    	currentLevel = -1;
        entries = new HashMap<String, Stack<Entry>>();
    }

    /**
     * Opens a new scope.
     * @ensure  this.currentLevel() == old.currentLevel()+1
     */
    public void openScope()  {
        currentLevel++;
    }

    /**
     * Closes the current scope. All identifiers in
     * the current scope will be removed from the SymbolTable.
     * @require old.currentLevel() > -1
     * @ensure  this.currentLevel() == old.currentLevel()-1
     */
    public void closeScope() {
    	for (Map.Entry<String, Stack<Entry>> entry: entries.entrySet()){
    		Stack<Entry> stack = entry.getValue();
    		if ((stack != null) && (!stack.isEmpty()) && (stack.peek().level >= currentLevel)){
    			stack.pop();
    			localCount = nextAddr > localCount ? nextAddr : localCount;
                nextAddr--;
    		}
    	}
       	currentLevel--;
    }

    /** Returns the current scope level. */
    public int currentLevel() {
        return currentLevel;
    }

    /**
     * Enters an id together with an entry into this SymbolTable using the
     * current scope level. The entry's level is set to currentLevel().
     * @require String != null && String != "" && entry != null
     * @ensure  this.retrieve(id).getLevel() == currentLevel()
     * @throws  SymbolTableException when there is no valid current scope level,
     *          or when the id is already declared on the current level.
     */
    public void enter(Tree tree, Entry entry) throws SymbolTableException {
    	String id = tree.getText();
    	if (currentLevel < 0) {
        	throw new SymbolTableException(tree, "Not in a valid scope.");
        }
        Stack<Entry> s = entries.get(id);
        if (s==null) {
        	s = new Stack<Entry>();
        	entry.level = currentLevel;
        	s.push(entry);
        	entries.put(id, s);
        	if (entry instanceof CheckerEntry && ((CheckerEntry) entry).kind != SR_Kind.CONST)
                nextAddr++;
        } else if (s.isEmpty() || s.peek().level != currentLevel){
        	entry.level=currentLevel;
        	s.push(entry);
        	if (entry instanceof CheckerEntry && ((CheckerEntry) entry).kind != SR_Kind.CONST)
                nextAddr++;
        } else {
        	throw new SymbolTableException(tree, "Entry "+id+" already exists in current scope.");
        }
    }


    /**
     * Get the Entry corresponding with id whose level is the highest.
     * In other words, the method returns the Entry that is defined last.
     * @return  Entry of this id on the highest level
     *          null if this SymbolTable does not contain id
     */
    public Entry retrieve(Tree tree) throws SymbolTableException{
    	String id = tree.getText();
    	Stack<Entry> s = entries.get(id);
    	if (s==null||s.isEmpty())
    		throw new SymbolTableException(tree, "Entry not found: "+id);
    	return s.peek();
    }

    public String toString(){
    	String s = "";
    	for (Map.Entry<String, Stack<Entry>> entry: entries.entrySet()){
    		Stack<Entry> stack = entry.getValue();
    		s+=entry.getKey();
   			s+=stack.toString();
    	}
    	return s;
    }

    /* Get the locals limit for this stack frame */
    public int  getLocalsCount() {
        return nextAddr > localCount ? nextAddr : localCount;
        /*
        int localCount = 0;

        for (Stack<Entry> stack : entries.values()) {
            if (stack.size() > 0 && stack.peek().level >= currentLevel) {
                localCount++;
            }
        }

        return localCount;     */
    }
}

/** Exception class to signal problems with the SymbolTable */
class SymbolTableException extends RecognitionException {
    public static final long serialVersionUID = 24362462L; // for Serializable
    private String msg;
    public SymbolTableException(Tree tree, String msg) {
    	super();
        this.msg = tree.getText() +
        " (" + tree.getLine() +
        ":" + tree.getCharPositionInLine() +
        ") " + msg;
    }
    public String getMessage() {
        return msg;
    }
}

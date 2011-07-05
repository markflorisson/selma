package SELMA;

import java.util.*;
import SELMA.SELMATree.SR_Type;
import SELMA.SELMATree.SR_Kind;
import SELMA.SELMATree.SR_Func;

import SELMA.SELMAChecker;

import org.antlr.runtime.RecognitionException;
import org.antlr.runtime.tree.Tree;

public class SymbolTable<Entry extends IdEntry> {
	public int nextAddr = 1;
    public int funclevel = 0;

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
    			Entry e = stack.pop();
    			localCount = nextAddr > localCount ? nextAddr : localCount;
                if (isLocal(e))
                    nextAddr--;
    		}
    	}
       	currentLevel--;
    }

    /** Returns the current scope level. */
    public int currentLevel() {
        return currentLevel;
    }

    /** Return whether the entry takes up space on the stack */
    private boolean isLocal(Entry entry) {
        return entry instanceof CheckerEntry && ((CheckerEntry) entry).kind != SR_Kind.CONST;
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
        if (s == null) {
            s = new Stack<Entry>();
            entries.put(id, s);
        }

        if (s.isEmpty() || s.peek().level != currentLevel) {
        	entry.level = currentLevel;
        	s.push(entry);
        	if (isLocal(entry))
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
    public Entry retrieve(Tree tree) throws SymbolTableException {
    	String id = tree.getText();
    	Stack<Entry> s = entries.get(id);
    	if (s==null||s.isEmpty()) {
            throw new SymbolTableException(tree, "Entry not found: " + id);
        }
    	return s.peek();
    }

    public void addParamToFunc(Tree func, Tree param, Tree type) {
        SR_Type selmaType = ((SELMATree) type).getSelmaType();
        CheckerEntry function = (CheckerEntry) retrieve(func);
        function.addParam(param, selmaType);
        CompilerEntry paramentry = new CompilerEntry(selmaType, SR_Kind.VAR, nextAddr);
        paramentry.initialized = true;
        enter(param, (Entry) paramentry);
    }

    public String toString(){
    	String s = "";
    	for (Map.Entry<String, Stack<Entry>> entry: entries.entrySet()){
    		Stack<Entry> stack = entry.getValue();
    		s += String.format("Id=%-10s : %s=%s\n", entry.getKey(), stack, stack.peek().getClass());
            //s+=entry.getKey();
   			//s+=stack.toString();
    	}
    	return s;
    }

    /* Get the locals limit for this stack frame */
    public int  getLocalsCount() {
        return nextAddr > localCount ? nextAddr : localCount;
    }

    /**
     * Return the JVM type denoter of the Symbol Table SR_Type
     * @param type the type to get the denoter for
     * @param printing whether the denoter is used to format
     *                 values using the print() statement
     * @return The type denoter (String)
     */
    public String getTypeDenoter(SR_Type type, boolean printing) {
        if (type == SR_Type.INT) {
            return "I";
        } else if (type == SR_Type.BOOL) {
            if (printing)
                return "Ljava/lang/String;";
            else
                return "I";
        } else if (type == SR_Type.VOID) {
            return "V";
        } else if (type == SR_Type.CHAR) {
            return "C";
        } else {
            throw new RuntimeException(":( Invalid type: " + type);
        }
    }

    /**
     * Get a list of strings for each local variable along with its type denoter.
     * This is used for global variables that are to become fields
     * @return
     */
    public List<String> getAllLocalVariablesWithTypes() {
        List<String> localVars = new ArrayList<String>();

        for (Map.Entry<String, Stack<Entry>> entry: entries.entrySet()){
    		Stack<Entry> stack = entry.getValue();
    		if (stack != null && !stack.isEmpty()) {
                CheckerEntry e = (CheckerEntry) stack.peek();
                if (e.kind != SR_Kind.CONST && e.func != SR_Func.YES) {
                    localVars.add(entry.getKey() + " " + getTypeDenoter(e.type, false));
                }
            }
        }

        return localVars;
    }

    public void enterFuncScope() {
        openScope();
        funclevel++;
    }

    public void leaveFuncScope() {
        closeScope();
        funclevel--;
    }
}

/** Exception class to signal problems with the SymbolTable */
class SymbolTableException extends RuntimeException { //RecognitionException {
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

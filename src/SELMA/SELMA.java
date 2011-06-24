package SELMA;

import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileReader;

import org.antlr.runtime.*;             // ANTLR runtime library
import org.antlr.runtime.tree.*;        // For ANTLR's Tree classes
import org.antlr.stringtemplate.*;      // For the DOTTreeGenerator

 

public class SELMA {
    private static boolean  opt_ast             = false,
                            opt_dot             = false,
                            opt_no_checker      = false,
							opt_code_generator	= false;
    
    public static void parseOptions(String[] args) {
    	for (int i=0; i<args.length; i++) {
            if (args[i].equals("-ast"))
                opt_ast = true;
            else if (args[i].equals("-dot"))
                opt_dot = true;
            else if (args[i].equals("-code_generator")){ 
				opt_code_generator = true;
				}
            else if (args[i].equals("-no_checker"))
                opt_no_checker = true;
            else {
            	System.err.println("error: unknown option '" + args[i] + "'");
                System.err.println("valid options: -ast -dot " +
                                   "-no_checker");
                System.exit(1);
            }
        }
    }
        
    public static void main(String[] args) throws FileNotFoundException {
        System.setIn(new FileInputStream("simple.SELMA"));
    	parseOptions(args);
        CommonTree tree;
        try {
            SELMALexer lexer = new SELMALexer(new ANTLRInputStream(System.in));
            CommonTokenStream tokens = new CommonTokenStream(lexer);

            if (! opt_no_checker) {      // check the AST
                SELMAParser parser = new SELMAParser(tokens);
                parser.setTreeAdaptor(new SELMATreeAdaptor());

                SELMAParser.program_return result = parser.program();
                tree = (SELMATree) result.getTree();

                TreeNodeStream nodes = new CommonTreeNodeStream(tree);
                SELMAChecker checker = new SELMAChecker(nodes);
                checker.setTreeAdaptor(new SELMATreeAdaptor());
                checker.program();
            } else {
                SELMAParser parser = new SELMAParser(tokens);

                SELMAParser.program_return result = parser.program();
                tree = (CommonTree)result.getTree();
            	
            }
            

			if ( opt_code_generator) {  // code the AST
	               // generate TAM assembler code using string template

                // read templates (src of code: [Parr 2007, p. 216])
                FileReader groupFileR = new FileReader("g-files/SELMACode.stg");
                StringTemplateGroup templates 
                    = new StringTemplateGroup(groupFileR);
                groupFileR.close();
                
                CommonTreeNodeStream nodes = new CommonTreeNodeStream(tree);
                SELMACompiler codegenerator 
                    = new SELMACompiler(nodes);
                codegenerator.setTemplateLib(templates);
                SELMACompiler.program_return r 
                    = codegenerator.program();
                StringTemplate output = (StringTemplate) r.getTemplate();
                System.out.println(output.toString());
            }


            if (opt_ast) {          // print the AST as string
                System.out.println(tree.toStringTree());
            } else if (opt_dot) {   // print the AST as DOT specification
                DOTTreeGenerator gen = new DOTTreeGenerator(); 
                StringTemplate st = gen.toDOT(tree); 
                System.out.println(st);
            }
            
        } catch (SELMAException e) { 
            System.err.print("ERROR: SELMAException thrown by compiler: ");
            System.err.println(e.getMessage());
        } catch (SymbolTableException e) { 
            System.err.print("ERROR: SymbolTableException thrown by compiler: ");
            System.err.println(e.getMessage());
        } catch (RecognitionException e) {
            System.err.print("ERROR: recognition exception thrown by compiler: ");
            System.err.println(e.getMessage());
            e.printStackTrace();
        } catch (Exception e) { 
            System.err.print("ERROR: uncaught exception thrown by compiler: ");
            System.err.println(e.getMessage());
            e.printStackTrace();
        }
    }
}

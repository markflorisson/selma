package SELMA;

import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.InputStream;
import java.util.*;

import org.antlr.runtime.*;             // ANTLR runtime library
import org.antlr.runtime.tree.*;        // For ANTLR's Tree classes
import org.antlr.stringtemplate.*;      // For the DOTTreeGenerator


/**
 * Classe die de lexer, parser, checker en code generator opzet en executeerd. Kan ook een ast printen.
 */
public class SELMA {
    private static boolean  opt_ast             = false,
                            opt_dot             = false,
                            opt_no_checker      = false,
                            opt_code_generator	= false;

    public static String inputFilename;
    private static InputStream inputFile;

    /**
     * Parse de command line opties
     */
    public static void parseOptions(String[] args) {
        int i;

        for (i = 0; i < args.length && args[i].startsWith("-"); i++) {
            if (args[i].equals("-ast"))
                opt_ast = true;
            else if (args[i].equals("-dot"))
                opt_dot = true;
            else if (args[i].equals("-code_generator"))
                opt_code_generator = true;
            else if (args[i].equals("-no_checker"))
                opt_no_checker = true;
            else {
                System.err.println("selma [options] file.selma");
                System.err.println("error: unknown option '" + args[i] + "'");
                System.err.println("valid options: -ast -dot " +
                                   "-no_checker -code_generator");
                System.exit(1);
            }
        }

        if (i < args.length) {
            inputFilename = args[i];
            try {
                inputFile = new FileInputStream(inputFilename);
            } catch (FileNotFoundException e) {
                System.err.println("No such file or directory: " + e.getMessage());
                System.exit(1);
            }
        } else {
            System.err.println("No filename provided, reading from stdin.");
            inputFilename = "<stdin>";
            inputFile = System.in;
        }
    }

    public static void main(String[] args) {
        parseOptions(args);
        CommonTree tree;
        try {
            SELMALexer lexer = new SELMALexer(new ANTLRInputStream(inputFile));
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
                // generate Jasmin assembler code using string template

                // read templates (src of code: [Parr 2007, p. 216])
                FileReader groupFileR = new FileReader("g-files/SELMACodeJasmin.stg");
                StringTemplateGroup templates =
                        new StringTemplateGroup(groupFileR);
                groupFileR.close();

                CommonTreeNodeStream nodes = new CommonTreeNodeStream(tree);
                SELMACompiler codegenerator = new SELMACompiler(nodes);
                codegenerator.setTemplateLib(templates);
                SELMACompiler.program_return r = codegenerator.program();
                StringTemplate output = (StringTemplate) r.getTemplate();

                // Remove instructions followed by 'removeLastInstruction' and remove
                // duplicate consecutive .line <line_num> instructions
                Stack<String> lines = new Stack<String>();
                Stack<Stack<String>> functions = new Stack<Stack<String>>();
                List<Stack<String>> collectedFunctions = new ArrayList<Stack<String>>();

                for (String line : output.toString().split("\r?\n")) {
                    String trimmed = line.trim();

                    if (trimmed.length() == 0 ||
                        (!lines.isEmpty() &&
                         lines.peek().trim().startsWith(".line") &&
                         lines.peek().equals(line)))
                        // Empty line or duplicate .line directive
                        continue;
                    else if (trimmed.startsWith("removeLastInstruction") && !lines.empty())
                        lines.pop();
                    else if (line.trim().equals("<method>")) {
                        functions.push(lines);
                        lines = new Stack<String>();
                    } else if (line.trim().equals("</method>")) {
                        collectedFunctions.add(lines);
                        lines = functions.pop();
                    } else
                        lines.push(line);
                }

                // Print the module-global code
                for (String line : lines)
                    System.out.println(line);

                // Print the code for all functions
                for (Stack<String> functionCode : collectedFunctions)
                    for (String line : functionCode)
                        System.out.println(line);

            } else if (opt_ast) {          // print the AST as string
                System.out.println(tree.toStringTree());
            } else if (opt_dot) {   // print the AST as DOT specification
                DOTTreeGenerator gen = new DOTTreeGenerator();
                StringTemplate st = gen.toDOT(tree);
                System.out.println(st);
            }

        } catch (SELMAException e) {
            System.err.print("ERROR: ");
            System.err.println(e.getMessage());
            System.exit(1);
        } catch (SymbolTableException e) {
            System.err.print("ERROR: ");
            System.err.println(e.getMessage());
            System.exit(1);
        } catch (RecognitionException e) {
            System.err.print("ERROR: recognition exception thrown by compiler: ");
            System.err.println(e.getMessage());
            e.printStackTrace();
            System.exit(1);
        } catch (Exception e) {
            System.err.print("ERROR: uncaught exception thrown by compiler: ");
            System.err.println(e.getMessage());
            e.printStackTrace();
            System.exit(1);
        }
    }
}

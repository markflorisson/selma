SELMA
=====


SELMA is a compiler for the simple programming language SELMA. It compiles SELMA code to Jasmin, which can be compiled to JVM bytecode.
Before doing anything, compile the compiler::

    $ make

To run tests::

    $ python test.py

The test-sources are located in::
    ./test/

To compile and execute a program::

    $ sh selma path/to/program.selma

Documentation can be found in::

    ./javadoc/index.html

    ./Versag/SELMA.pdf

You can build the report as follows::

    $ cd Verslag
    $ make

Source can be found in::

    ./src/SELMA

    ./g-files

The rest is self explainatory, if you look in the Makefile a few more compile-options are available.

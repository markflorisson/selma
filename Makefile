JAVA=java
JAVAC=javac
GIT=git

build:
	$(JAVA) -jar antlr-3.3-complete.jar -make g-files/*.g -fo src/SELMA/
	CLASSPATH="antlr-3.3-complete.jar" $(JAVAC) src/SELMA/*.java

run: build
	sh selma.sh simple.SELMA
	java Main

debug:
	javap -v Main

clean:
	$(GIT) clean -X -f

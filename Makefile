JAVA=java
JAVAC=javac
JAVAP=javap
GIT=git
PROGRAM=simple
PWD=$(shell pwd)
CLASSPATH="$(PWD)/jasmin.jar:$(PWD)/antlr-3.3-complete.jar:$(PWD)/src:$(PWD)"

export CLASSPATH

build:
	$(JAVA) -jar antlr-3.3-complete.jar -make g-files/*.g -fo src/SELMA/
	CLASSPATH="antlr-3.3-complete.jar" $(JAVAC) src/SELMA/*.java

run: build
	$(JAVA) SELMA.SELMA -code_generator $(PROGRAM).SELMA > $(PROGRAM).jasmin
	$(JAVA) -jar jasmin.jar -g $(PROGRAM).jasmin
	$(JAVA) -classpath . Main

ast: build
	$(JAVA) SELMA.SELMA -ast $(PROGRAM).SELMA

debug: build
	$(JAVAP) -v Main

clean:
	$(GIT) clean -X -f

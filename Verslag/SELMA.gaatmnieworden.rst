.. SELMA documentation master file, created by
   sphinx-quickstart on Mon Jun 27 16:03:36 2011.
   You can adapt this file completely to your liking, but it should at least
   contain the root `toctree` directive.

SELMA
=====

Titelblad
---------

 Vonk, J
 s0132778
 Matenweg 75-201

 Florisson, M
 s000000
 Box Calslaan xx-30

Inhoud
------

.. contents::

Inleiding
---------
Korte beschrijving van de practicumopdracht.

Beknopte beschrijving
---------------------
van de programmeertaal (maximaal een A4-tje).

Problemen en oplossingen
------------------------
uitleg over de wijze waarop je de problemen die je bent tegenge-
komen bij het maken van de opdracht hebt opgelost (maximaal twee A4-tjes).

Syntax, context-beperkingen en semantiek
----------------------------------------
van de taal met waar nodig nadere uitleg over de
betekenis. Geef de beschrijving bij voorkeur in dezelfde terminologie als die gebruikt is bij
de beschrijving van Triangle in Watt & Brown (hoofdstuk 1 en appendix B).

Vertaalregels
-------------
voor de taal, d.w.z. de transformaties waaruit blijkt op welke wijze een opeen-
volging van symbolen die voldoet aan een produktieregel wordt omgezet in een opeenvol-
ging van TAM-instructies. Vertaalregels zijn de ‘code templates’ van hoofdstuk 7 van Watt
& Brown.

Beschrijving van Java programmatuur
-----------------------------------
Beknopte bespreking van de extra Java klassen die
u gedefinieerd heeft voor uw compiler (b.v. symbol table management, type checking, code
generatie, error handling, etc.). Geef ook aan welke informatie in de AST-nodes opgeslagen
wordt.

Testplan en -resultaten
-----------------------
Bespreking van de ‘correctheids-tests’ aan de hand van de criteria
zoals deze zijn beschreven in het §A.5 van deze appendix. Aan de hand van deze criteria moet
een verzameling test-programma’s in het taal geschreven worden die de juiste werking van de
vertaler en interpreter controleren. Tot deze test-set behoren behalve correcte programma’s
die de verschillende taalconstructies testen, ook programma’s met syntactische, semantische
en run-time fouten.
Alle uitgevoerde tests moeten op de CD-R aanwezig zijn; van een testprogramma moet de
uitvoer in de appendix opgenomen worden (zie onder).

Conclusies
----------

Appendix
--------

ANTLR Lexer specificatie
~~~~~~~~~~~~~~~~~~~~~~~~
Specificatie van de invoer voor de ANTLR scanner generator,
d.w.z. de token-definities van het taaltje.

ANTLR Parser specificatie
~~~~~~~~~~~~~~~~~~~~~~~~~
Specificatie van de invoer voor de parser generator, d.w.z. de
structuur van de taal en de wijze waarop de AST gegenereerd wordt

Alle ANTLR TreeParser specificaties
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Waarschijnlijk zult u (tenminste) twee tree parsers
gebruiken: een context checker en een code generator.

Invoer- en uitvoer van een uitgebreid testprogramma
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Van een correct en uitgebreid test-
programma (met daarin alle features van uw programmeertaal) moet worden bijgevoegd: de
listing van het oorspronkelijk programma, de listing van de gegenereerde TAM-code (be-
standsnaam met extensie .tam) en een of meer executie voorbeelden met in- en uitvoer
waaruit de juiste werking van de gegenereerde code blijkt.






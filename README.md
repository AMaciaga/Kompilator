# Kompilator

Kompilator prostego języka imperatywnego przygotowany na kurs JFTT
Autor: **Aleksandra Maciąga**
Nr indeksu: **236369**

### Pliki

- `Makefile` — plik służący do kompilacji projektu,
- `opt_compiler.y` — plik `BISON`
- `opt_compiler.l`— plik `FLEX`.

### Sposób użycia

#### Kompilacja programu

W celu skompilowania projektu należy użyć polecenia 'make'.
Program wynikowy będzie znajdował się pod nazwą 'kompilator'.

#### Uruchamianie programu

Kompilator uruchamia się komendą `./kompilator`. Kod wejściowy przyjmowany jest na standardowe wejście, natomiast wynik działania programu wypisywany na standardowe wyjście lub do podanego jako argument pliku wyjściowego.

Aby odczytać kod z pliku wejśiowego `program.imp` i zapisać wynik do pliku `program.mr` można wywołać komendę:

`./compiler program.imp program.mr`

# Kompilator

Kompilator prostego języka imperatywnego przygotowany na kurs JFTT

Autor: **Aleksandra Maciąga**

Nr indeksu: **236369**

### Pliki

- `Makefile` — plik służący do kompilacji projektu,
- `opt_compiler.y` — plik `BISON`
- `opt_compiler.l`— plik `FLEX`.

### Kompilacja

Aby skompilować program wywołujemy w terminalu komende `make`.
Jako plik wynikowy otrzymujemy plik `kompilator`

### Uruchomienie kompilatora

Aby uruchomić kompilator wywołujemy w terminalu komende
`./kompilator <nazwa pliku wejściowego> <nazwa pliku wyjściowego>`
Naprzykćad jeżeli chcemy skompilować plik `program.imp` i zapisać
wynik kompilacji co pliku `program.mr` wywołamy komende
`./kompilator program.imp program.mr`

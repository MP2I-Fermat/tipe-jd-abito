# tipe-jd-abito
Le TIPE de @jd-develop et @abitofevrything. 2025!

## Bootstrapping

Notre TIPE consiste a explorer le concept du bootstrapping pour finalement
compiler du code OCaml.

Les étapes principales de notre chaîne sont les suivantes:

### Assembleur RISC-V

Language: C
Ce projet ne fait pas partie du TIPE.

C'est un assembleur.

### Interpréteur BASIC

Langage: Assembleur RISC-V

Cet interpréteur permet d'interpreter des programmes écrits en BASIC.

### Compilateur C

Langage: BASIC

Ce compilateur tres basique permet de compiler des programmes C _simples_.

### tinycc

Langage: C
Ce projet ne fait pas partie du TIPE.

Ce compilateur nous permet de passer de notre version restreinte du C aux
versions modernes, nous permettant de compiler OCaml.

### Compilateur & Runtime OCaml.

Langage: C & OCaml.
Ce projet ne fait pas partie du TIPE.

Le compilateur OCaml permet de compiler des programmes OCaml en langage
machine.

Il est lui-meme écrit en C et en OCaml, et requiert donc plusieurs étapes de
bootstrapping lui-meme avant de pouvoir compiler des programmes OCaml qui visent
la version 4 du langage.

### Émulateur RISC-V

Langage: OCaml.

Cet émulateur permet d’émuler un CPU RISC-V. Notamment, il permettrait
d'executer notre interpréteur BASIC et de fermer la boucle!

https://stackoverflow.com/questions/9429491/how-are-gcc-and-g-bootstrapped/65708958#65708958

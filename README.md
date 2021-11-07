# mipl-compiler

A compiler for the Mini Imperative Programming Language (MIPL), a subset of the Pascal language. Written using flex for token analysis and bison for grammar and semantic analysis.

To compile:

```
flex mipl.l
bison mipl.y
g++ mipl.tab.c –o mipl
mipl inputFileName
```

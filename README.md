[![Build Status](https://ci.ksteimel.duckdns.org/api/badges/ksteimel/CFG.jl/status.svg)](https://ci.ksteimel.duckdns.org/ksteimel/CFG.jl)

This is a project for parsing context free grammars and feature grammars using julia

The goals of this project are the following: 
-[x] Buila a method for ingestion of context free rules
-[] Build a method for ingestion of feature grammar rules
-[x] Implement a context free parsing algorithm most likely the Earley parser to start with
-[] Implement unification 
-[] Use a modular architecture that allows for new parsing algorithms to be used and new rule intake methods


# Installation

To install `CFG.jl` simply start the julia prompt and then type `]` to enter the `Pkg` shell. 

Then type `add https://git.ksteimel.duckdns.org/ksteimel/CFG.jl.git`

# Usage

To begin using CFG.jl simply state 

```
using CFG
```

at the beginning of your code. 

## Rule specifications

`CFG.jl` has specifications for lexical rules and syntactic rules. 

### Lexical rules

Lexical rules consist of a part of speech symbol, a colon and a single word with that part of speech or a list of words enclosed in icurly braces.

```
V : runs
N : {dog, cat}
```

Each rule must be on a separate line

### Syntactic rules

Syntactic rules consist of a phrase symbol, an arow and a series of daughters separated by spaces.

```
NP => D N
```

The rules cannot currently use parenthesis for optionality or asterisks for repetition but this is a future goal. 



[![Build Status](https://ci.ksteimel.duckdns.org/api/badges/ksteimel/CFG.jl/status.svg)](https://ci.ksteimel.duckdns.org/ksteimel/CFG.jl)

## This is a project for parsing context free grammars and feature grammars using julia

# Project Status: 
- [X] Basic functionality
  - [X] Ingest of context free rules
  - [X] Parse using Earley parsing algorithm
  - [X] Save trees to a file using `Luxor.jl`
- [ ] Optionality and repetition
  - [X] Handle optionality
  - [ ] Repetition
- [ ] Other parsing algorithms
   - [X] Rule binarization
   - [ ] Parse using CYK algorithm
   - [ ] Rule debinarization
- [ ] Feature grammar
   - [ ] Ingest feature grammar rules
   - [ ] Implement non-hierarchical unification
   - [ ] Integrate unification into Earley parsing algorithm
- [ ] Design
   - [ ] Use structs for nodes in lexicon and productions
   - [ ] Use struct for lexicon and productions with flags for optionality, repetition, features etc so that 
   parsing algorithms can use these traits to stipulate what types of grammars they can work with. *

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



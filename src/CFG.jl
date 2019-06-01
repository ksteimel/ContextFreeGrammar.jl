module CFG
"""
This will be the building block that trees are constructed
from
Rather than specifying that all nodes must have two daughters
(as would be required for most parser implementations), this utilizes 
an array of daughters so that the same structure can be used to represent flattened tree structures as well. 
"""
mutable struct Node
    root::Union{Node, Nothing}
    daughters::Array{Node}
end
Node(root=nothing, daughters=Array{Node}[]) = Node(root, daughters)

"""
This is a cyk parsing implementation 
"""
function parse_cyk(productions, lexicon, sent, start_symbol="S")
    # may need to change this up to allow for different  tokenization methods
    terminals = keys(lexicon)
    nonterminals = sort(values(productions))
    nonterminals = Dict(nont => i for (i,nont) in enumerate(nonterminals))
    tokens = split(sent) 
    input_length = length(tokens)
    lattice = zeros(Bool, input_length, input_length, length(nonterminals))
    # the backpointers are an array of indexes to the pieces that
    # contributed to making the constituent
    backpointers = Array{Array}(undef, input_length, input_length)
    # initial pass for dealing with terminals
    for (i, token) in enumerate(tokens)
        nterm_index = nonterminals[productions[token]]
        lattice[1, i, nterm_index] = true
        backpointers[1, i] = push!(backpointers[1,i], (0,0,0,0))
    end
    
    
end
"""
This function prints the lattice from its strange boolean format
"""
function print_lattice(lattice, non_terminals, tokens)
    n_rows, n_cols, n_non_terminals = size(lattice)
    tok_row = ""
    for token in tokens
        tok_row *= rpad(token, 6)
    end 
    println(tok_row)
    println("-" ^ (1 + n_cols * 6))
    for row = 1:n_rows
        row_string = "|"
        for col = 1:n_cols
            items = lattice[row, col, :]
            cell_pieces = non_terminals[items]
            cell = join(cell_pieces, ",")
            
            cell = rpad(cell, 5)
            cell = cell * "|"
            row_string = row_string * cell
        end
        println(row_string)
    end
    println("-" ^ (1 + n_cols * 6))
end
"""
This function parses a single sentence using the lexicon 
and production rules provided
"""
function parse_sent(productions, lexicon, sent)
    
end
function parse(productions, lexicon, text)
    # split sentences
    # call parse_sent on each sentence
    pass
end
"""
This function reads in a piece of text that contains various rules 
where the form of syntactic rules is X -> Y Z

and the form of lexical rules is V : X

todo: 
    - optionality using parenthesis
    - repetition using *
    - features
"""
function read_rules(rule_text)
    # each rule should be on a new line
    lines = split(rule_text, "\n", keepempty=false) 
    productions = Dict()#"null" => ["null"])
    lexicon = Dict()#"null" => ["null"]) # doing this as a cludge to 
    # get dictionaries initialized
    for line in lines
        if occursin(":", line)
            # we have a lexical rule
            pieces = split(line, ":")
            if length(pieces) != 2
                error("Multiple ':' symbols in input string")
            end
            left_hand = strip(pieces[1])
            right_hand = strip(pieces[2])
            # check to see if we have a multi-part right hand 
            if occursin("{", right_hand)
                tokens = split(right_hand, r"({|,|}) ?", keepempty=false)
                left_hand = strip(left_hand)
                for token in tokens
                    token = string(token)
                    if token in keys(lexicon)
                        lexicon[token] = push!(lexicon[token],
                                                    left_hand)
                    else
                        lexicon[token] = [left_hand]
                    end
                end
            else
                if right_hand in keys(lexicon)
                    lexicon[right_hand] = push!(lexicon[right_hand], left_hand)
                else
                    lexicon[right_hand] = [left_hand]
                end
            end
        elseif occursin("->", line)
            # we have a syntactic rule
            pieces = split(line, "->")
            if length(pieces) != 2
                error("Mutiple -> symbols in input string")
            end
            left_hand = strip(pieces[1])
            right_hand = strip(pieces[2])
            components = split(right_hand)
            components = [string(component) for component in components]
            # need to check if any of the components are optional 
            productions[Tuple(components)] = left_hand
        else
            println(line)
            error("Incorrect line format")
        end
    end
    return productions, lexicon
end
"""
This function creates binary rules from the flat rules presented
e.g. if we have an input rule `NP -> D Adj N` then this will 
create two rules:
    - NPbar -> Adj N
    - NP -> D NPbar
    
If a unary rule is found (e..g NP -> D) then it will first try to 
substitute out the intermediate e.g. if D pointed to a word, then the
NP would go to the word
"""
function binarize!(productions, lexicon)
    revised_prod = Dict()
    pairings = 0
    for rhs in keys(productions)
        lhs = productions[rhs]
        if length(rhs) > 2
            rhs_mod = rhs
            while length(rhs_mod) > 2
                lhsbar = lhs * "bar"
            end
        elseif length(rhs) == 1
            for word in keys(lexicon)
                poss_pos = lexicon[word]
                if rhs[1] in poss_pos
                    sub_ind = findfirst(x -> x == rhs[1], poss_pos)
                    lexicon[word][sub_ind] = lhs
                end
            end
            for input_tup in keys(productions)
                productions[input_tup] = lhs
                delete!(productions, rhs)
            end
        else
            continue
        end
    end
    return productions, lexicon, pairings
end
"""
This function checks to make sure that the set of rules are compatible. 

In essence, it is checking to see that there are no symbols that occur on the right hand side that
are nowhere on the left hand side

the following is an incompatible set: 

    NP => D N
    N : {dog, mouse}
    
because of the lack of specification for D in any of the lexical rules
"""
function verify_system(productions, lexicon)::Bool
    
end
end # module



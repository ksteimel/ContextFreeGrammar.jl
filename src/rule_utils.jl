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
This function expands symbols that indicate repetition a set number of times.
    In essence, it creates clones of rhe right hand side passed in with some number
    of repeated elements.

    This is a very hacky implementation. Repetition is complex just like optionality in that 
    all possible combinations of the number of possible repetitions up to repeat_count need
    to be considered. Because this is so similar to optionality, I am using the optionality code.
    In essence, I'm generating `repeat_count` optional elements for each  repeated thing.
    Then, I use `gen_opt_poss()` to create all the permutations.
    However, this results in a lot of duplicates so this is uniqued.
    Having duplicates would be okay but it has the potential to slow down the parser since
    Earley parser runtime is related to the grammar size.

# Examples
```julia-repl
julia> expand_repetition(["D", "AP+", "N", "PP+"], repeat_count=2)
[["D","AP", "N", "PP"],
 ["D", "AP", "AP", "N", "PP"],
 ["D", "AP", "AP", "N", "PP", "PP"],
 ["D", "AP", "N", "PP", "PP"]]
```

"""
function expand_repetition(rhs; repetition_symbol="+", repeat_count=5)
    expanded_rhs = String[]
    # build a modified version of rhs where each repeated symbol is replaced
    # with some number of optional additions
    # AP+ N => AP (AP) (AP) (AP) N
    for symbol in rhs 
        if symbol[end:end] == repetition_symbol
            trimmed_symbol = symbol[1:end-1]
            opt_trimmed_symbol = "(" * trimmed_symbol * ")"
            # add a non-optional symbol onto the right hand side because 
            # it has to occcur at least once
            push!(expanded_rhs, trimmed_symbol)
            append!(expanded_rhs, repeat([opt_trimmed_symbol], repeat_count))
        else
            push!(expanded_rhs, symbol)
        end
    end
    poss = gen_opt_poss(expanded_rhs)
    return unique(poss)
end
"""
This function reads in a piece of text that contains various rules 
where the form of syntactic rules is X -> Y Z

and the form of lexical rules is V : X

lines that begin with "#" are comments

todo
    - features
    
the lexicon returned takes in words and yields the part of speech 
candidates. the productions returned take in the left hand side of a rule
and return the right hand side.

These hash directions are ideal for the earley parsing algorithm
"""
function read_rules(rule_text)
    # each rule should be on a new line
    lines = split(rule_text, "\n", keepempty = false)
    lines = [line for line in lines if strip(line) != ""]
    productions = Dict()#"null" => ["null"])
    lexicon = Dict()#"null" => ["null"]) # doing this as a cludge to 
    # get dictionaries initialized
    for line in lines
        if strip(line)[1] == '#'
            continue
        end
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
                tokens = split(right_hand, r"({|,|}) ?", keepempty = false)
                left_hand = strip(left_hand)
                for token_seg in tokens
                    token = string(token_seg)
                    if token in keys(lexicon)
                        lexicon[token] = push!(lexicon[token], left_hand)
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
            for right_chunk in split(pieces[2], "|")
                left_hand = strip(pieces[1])
                right_chunk = strip(right_chunk)
                seg_components = split(right_chunk)
                components = [string(component) for component in seg_components]
                # run the components through gen_opt_poss to get all possible
                # permutations of the rule with optional components
                # If nothing is optional, the result will be components
                partial_powerset = gen_opt_poss(components)
                repetition_res = Array{String}[]
                for new_rhs in partial_powerset
                    repetition_rhs = expand_repetition(new_rhs)
                    append!(repetition_res, repetition_rhs)
                end
                unique!(repetition_res)
                if left_hand in keys(productions)
                    append!(productions[left_hand], repetition_res)
                else
                    productions[left_hand] = repetition_res
                end
            end
        else
            println(line)
            error("Incorrect line format. Line contained neither : nor -> (required to indicate lexical vs syntactic rules).")
        end
    end
    return productions, lexicon
end
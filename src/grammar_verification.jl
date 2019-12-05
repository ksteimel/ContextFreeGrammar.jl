"""
This function checks to make sure that the set of rules are compatible. 

In essence, it is checking to see that there are no symbols that occur on the right hand side that
are nowhere on the left hand side

the following is an incompatible set: 

    NP => D N
    N : {dog, mouse}
    
because of the lack of specification for D in any of the lexical rules
"""
function verify_productions(productions, lexicon)::Bool
    prod_items = collect(Iterators.flatten(values(productions)))
    prod_items = unique(prod_items)
    lex_items = collect(Iterators.flatten(values(lexicon)))
    lex_items = unique(lex_items)
    for options in prod_items
        for piece in options
            if !haskey(productions, piece) && !(piece in lex_items)
                return false
            end
        end
    end
    return true
end
"""
This works essentially the same as `verify_productions`
except that this one returns the array of mismatched pieces
not just a boolean value.
"""
function identify_missing_left_hand_sides(productions, lexicon)::Bool
    prod_items = collect(Iterators.flatten(values(productions)))
    prod_items = unique(prod_items)
    lex_items = collect(Iterators.flatten(values(lexicon)))
    lex_items = unique(lex_items)
    missing_lhs = []
    for options in prod_items
        for piece in options
            if !haskey(productions, piece) && !(piece in lex_items)
                push!(missing_lhs, piece)
            end
        end
    end
    return missing_lhs
end
"""
Checks to see if all the words in the sentence exist in the lexicon
"""
function verify_lexicon(lexicon, sentence)::Bool
    for word in sentence
        if !haskey(lexicon, word)
            println(word)
            return false
        end
    end
    return true
end


"""
Generate random sentence given productions and lexicon
"""
function generate_recur(productions, rev_lexicon, symbol)::String
    lex_flag = false
    lex_bias = 0.7
    if symbol in keys(productions) && symbol in keys(rev_lexicon)
        # determine whether we should treat this as a terminal
        # or non-terminal
        if rand() < lex_bias
            lex_flag = true
        end
    end
    if lex_flag || symbol in keys(rev_lexicon)
        # we have a terminal this is the base case
        opt_indices = collect(1:length(rev_lexicon[symbol]))
        selection_ind = rand(opt_indices, 1)[1]
        return rev_lexicon[symbol][selection_ind]
        
    elseif !lex_flag || symbol in keys(productions)
        # we have a non-terminal
        # we need to call generate on the parts of the non-terminal
        opt_indices = collect(1:length(productions[symbol]))
        selection_ind = rand(opt_indices, 1)[1]
        constituents =  productions[symbol][selection_ind]
        sent_fragment = ""
        for constituent in constituents
            sent_fragment *= generate_recur(productions, rev_lexicon, constituent) * " "
        end
        return sent_fragment
    end
end
"""
Wrapper to make the generate api more smooth.
Instead of reversing the lexicon prior to calling generate,
this method carries out the reversal and then calls `generate_recur`
"""
function generate(productions, lexicon)::String
    # flip the lexicon so that it goes from words to 
    rev_lexicon = rev_lex(lexicon)
    return generate_recur(productions, rev_lexicon, "S")
end
"""
Reverse the lexicon so that it goes from lexical categories to 
words instead of words to lexical categories
"""
function rev_lex(lexicon)::Dict
    res_lex = Dict{String,Array{String}}()
    for word in keys(lexicon)
        for lexical_cat in lexicon[word]
            if lexical_cat in keys(res_lex)
                push!(res_lex[lexical_cat], word)
            else
                res_lex[lexical_cat] = [word]
            end
        end
    end
    return res_lex
end

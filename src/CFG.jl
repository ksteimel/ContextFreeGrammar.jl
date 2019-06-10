module CFG
using Luxor
using AbstractTrees
"""
This will be the building block that trees are constructed
from
Rather than specifying that all nodes must have two daughters
(as would be required for most parser implementations), this utilizes 
an array of daughters so that the same structure can be used to represent flattened tree structures as well. 
"""
mutable struct EarleyState
    state_num::Int
    start_index::Int 
    end_index::Int
    right_hand::Array{String}
    left_hand::String
    dot_index::Int
    originating_states::Array{Int}
    
    function EarleyState(state_num::Int,
                        start_index::Int,
                        end_index::Int,
                        right_hand::Array{String},
                        left_hand::String,
                        dot_index::Int,
                        originating_states::Array)
        if dot_index > (length(right_hand) + 1)
            throw(BoundsError("Unable to declare a state with the given dot index"))
        elseif dot_index < 1
            throw(BoundsError("Unable to declare a state with the given dot index"))
        else
            new(state_num, 
                start_index, 
                end_index,
                right_hand, 
                left_hand, 
                dot_index,
                originating_states)
        end
    end
end

"""
Add keyword version of EarleyState
"""
function EarleyState(;state_num, start_index, end_index, right_hand, left_hand, dot_index, originating_states)
    EarleyState(state_num, start_index, end_index, right_hand, left_hand, dot_index, originating_states)
end

"""
Overload equality for EarleyStates
"""
function Base.:(==)(x::EarleyState, y::EarleyState)
    if  x.start_index == y.start_index &&
        x.end_index == y.end_index && 
        x.right_hand == y.right_hand && 
        x.left_hand == y.left_hand && 
        x.dot_index == y.dot_index && 
        x.originating_states == y.originating_states
        return true
    else
        return false
    end
end

function Base.show(io::IO, state::EarleyState)
    dot_index = state.dot_index
    cmp_string = "|" * rpad(string(state.state_num), 4) * "|" * rpad(state.left_hand, 4) * "->" * 
                lpad(join(state.right_hand[1:(dot_index - 1)], " "), 10) * "*" * rpad(join(state.right_hand[dot_index:end], " "), 10) *
                " <== " * string(state.originating_states)
    print(io, cmp_string)
end

function Base.show(io::IO, chart::Array{EarleyState})
    println("-" ^ 32)
    for state in chart
        println(state)
    end
    println("-" ^ 32)
end
"""
This is a simple uitlity to determine whether a rule is complete
(e.g. whether the dot has advanced all the way to the right)
"""
function is_incomplete(state::EarleyState)
    if state.dot_index < (length(state.right_hand) + 1)
        return true
    else 
        return false
    end
end

"""
Check to see if the state provided spans the entire input
"""
function is_spanning(state::EarleyState, sent_length::Int)
    if state.start_index == 1 && (state.end_index == sent_length + 1)
        return true
    else 
        return false
    end
end
"""
This is a simple utility that returns the next next category 
(whether terminal or non-terminal), given the current dot location
"""
function next_cat(state::EarleyState)
    if is_incomplete(state)
        return state.right_hand[state.dot_index]
    else
        return "NFound"
    end
end

"""
This is the completer from Earley's algorithm as described in 
Jurafsky & Martin (2009). 

In essence, this takes a rule which has been completed and
moves the parse along for all the states that were waiting on the constituent
produced by this rule.

e.g. if I have S => * NP VP in my chart and I also have NP => D N *,
then I can move the dot across the NP
"""
function completer!(charts, i, productions::Dict, lexicon::Dict, state::EarleyState)
    obtained_constituent = state.left_hand
    next_state_num = charts[end][end].state_num + 1
    for chart in charts
        for old_state in chart
            # if the right hand side has the dot just before something that matches
            # the constituent that we just found,
            # then we should move the dot to the right in a new state
            if is_incomplete(old_state) && old_state.right_hand[old_state.dot_index] == obtained_constituent
                if old_state.end_index == state.start_index # may need to check this
                    backpointers = old_state.originating_states[1:end]
                    backpointers = push!(backpointers, state.state_num)
                    new_state = EarleyState(next_state_num, old_state.start_index, 
                                            i, old_state.right_hand, old_state.left_hand,
                                            old_state.dot_index + 1, backpointers)
                    push!(charts[i], new_state)
                    next_state_num += 1
                end
            end
        end
    end 
end
function predictor!(charts, i, productions::Dict, lexicon::Dict, state::EarleyState)
    next_category = next_cat(state)
    right_hands = productions[next_category]
    next_state_num = charts[end][end].state_num + 1
    for right_hand in right_hands
        new_state = EarleyState(next_state_num,
                                i, i, right_hand, 
                                next_category, 1, []) 
        # check on originating_states once I write completer
        push!(charts[i], new_state)
        next_state_num += 1
    end
end

function scanner!(charts, sent::Array{String}, i::Int, productions::Dict,
                    lexicon::Dict, state::EarleyState)
    next_category = next_cat(state)
    next_word = ""
    if state.end_index > length(sent)
        return
    end
    next_word = sent[state.end_index]
    next_state_num = charts[end][end].state_num + 1
    if next_category in lexicon[next_word]
        new_state = EarleyState(next_state_num, i, i+1, [next_word], next_category, 2, [])
        for chart in charts
            if new_state in chart
                return
            end
        end
        chart = EarleyState[new_state]
        push!(charts, chart)
    end
end
    
function parse_earley(productions, lexicon, sent, start_symbol="S")
    parts_of_speech = unique(collect(Iterators.flatten(values(lexicon))))
    charts = []
    chart = EarleyState[]
    push!(charts, chart)
    # add initial state
    push!(charts[1], EarleyState(1,1, 1, ["S"], "γ", 1, []))
    for i=1:(length(sent) + 1)
        for state in charts[i]
            next_category = next_cat(state)
            if is_incomplete(state) && !(next_category in parts_of_speech)
                predictor!(charts, i, productions, lexicon, state)
                # println("-" ^ 32)
                # println("predictor")
                # println(charts)
            elseif is_incomplete(state) && next_category in parts_of_speech 
                scanner!(charts, sent, i, productions, lexicon, state)
                # println("-" ^ 32)
                # println("Scanner" * next_category)
                # println(charts)
            else
                completer!(charts, i, productions, lexicon, state)
                # println("-" ^ 32)
                # println("Completer")
                # println(charts)
            end
        end
    end
    return charts
end
"""
This is a recognizer. Given a chart, it determines if the 
sentence parsed is possible given the grammar used for parsing

if it returns true then the sentence is in the grammar and the parse
was successful. 
if it returns false then the sentence is not in the grammar.
"""
function chart_recognize(charts)
    final_state = charts[end][end]
    if final_state.left_hand == "γ" && final_state.right_hand == ["S"]
        if final_state.dot_index == length(final_state.right_hand) + 1
            return true
        end
    end
    return false
end
"""
    ["N" [
"""
function build_backtrace_array(state::EarleyState, state_stack::Array)
    if state.originating_states == [] # base case
        bottom_piece = [state.left_hand, state.right_hand]
        return bottom_piece
    else
        right_piece = Any[state.left_hand]
        for pointer in state.originating_states
            push!(right_piece, build_backtrace_array(state_stack[pointer], state_stack))
        end
        return right_piece
    end
end
"""
This is a method to construct a tree from the backpointers
generated during the parse
"""
function chart_to_tree(charts, sentence)
    # test that the parse was successful first 
    if !(chart_recognize(charts))
        return
    end
    final_state = charts[end][end]
    states = collect(Iterators.flatten(charts))
    trees = []
    for state_i = length(states):-1:1
        state = states[state_i]
        if state.left_hand == "S" && is_spanning(state, length(sentence))
            traces = build_backtrace_array(state, states)
            push!(trees, traces)
        end
    end
    return trees
end
"""
This is a utility to get a list of the terminal
nodes in the tree. In essence, grab the individual words.
"""
function get_terminals(tree)
    if typeof(tree) <: Array && length(tree) == 1
        return tree[1]
    else
        non_terms = []
        for daughter in tree[2:end]
            push!(non_terms, get_terminals(daughter))
        end
        return collect(Leaves(non_terms))
    end
end
"""
Returns the maximum depth of the tree
"""
function get_depth(tree, marker=0)
    if typeof(tree) <: Array && length(tree) == 1
        return marker
    else
        depths = []
        for daughter in tree[2:end]
            push!(depths, get_depth(daughter, marker + 1))
        end
        #println(collect(Leaves(depths)))
        return max(Leaves(depths)...)
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
    
the lexicon returned takes in words and yields the part of speech 
candidates. the productions returned take in the left hand side of a rule
and return the right hand side.

These hash directions are ideal for the earley parsing algorithm
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
            if left_hand in keys(productions)
                push!(productions[left_hand], components)
            else
                productions[left_hand] = [components]
            end
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
function verify_system(productions, lexicon, sentence)::Bool
    prod_items = collect(Iterators.flatten(values(productions)))
    prod_items = unique(prod_items)
    lex_items = collect(Iterators.flatten(values(lexicon)))
    lex_items = unique(lex_items)
    for item in prod_items
        if !haskey(productions, item) && !(item in lex_items)
            return false
        end
    end
    for word in sentence
        if !haskey(lexicon, word)
            return false
        end
    end
    return true
end

"""
Determines what the width of a tree drawing should be
Currently, this needs some work as the size of daughter-sep is
exponentially decaying as we go further and further down in the tree.
However, this function does not take that into account. 
"""
function find_extents(tree::Array, daughter_sep, layer_sep)
    terms = get_terminals(tree)
    total_width = daughter_sep / 2
    total_width += daughter_sep * length(terms)
    total_width += daughter_sep / 2
    layers = get_depth(tree)
    total_depth = layer_sep * layers
    total_depth += layer_sep
    return total_width, total_depth
end
"""
Writes a tree graphic at the filepath specified.
"""
function tree_img(outer_tree::Array, filename::String)
    daughter_sep = 150 # this decays as we recursively build the tree
    layer_sep = 50 # this remains constant throughout the drawing
    width, depth = find_extents(outer_tree, daughter_sep, layer_sep)
    println(string(width) * " " * string(depth))
    Drawing(width, depth, filename)
    background("white")
    sethue("black")
    begin_x = floor(width/6) #this probably needs to be tested with a variety of trees
    println(begin_x)
    begin_y = 20
    start = Point(begin_x, begin_y)
    origin(start)
    fontface("Georgia-Bold")
    fontsize(12)
    function place_point(tree, x, y, x_sep)
        if typeof(tree) <: Array && length(tree) == 1
            term_location = Point(x, y)
            text(tree[1], term_location, halign=:center, valign=:middle)
        else
            non_term_location = Point(x, y)
            non_term_line_attach = Point(x, y + (layer_sep / 5))
            text(tree[1], non_term_location, halign=:center, valign=:middle)
            daughters = tree[2:end]
            xs = zeros(length(daughters))
            ys = repeat([y + layer_sep], length(daughters))
            if iseven(length(daughters))
                left_center_i = Integer(floor(length(daughters) / 2))
                prev_x = x - Integer(round(layer_sep / 2))
                xs[left_center_i] = prev_x
                for daughter_i = (left_center_i - 1):-1:1
                    new_x = prev_x - x_sep
                    xs[daugher_i] = new_x 
                    prev_x = new_x
                end
                prev_x = xs[left_center_i]
                for daughter_i = (left_center_i + 1):length(daughters)
                    new_x = prev_x + x_sep
                    xs[daughter_i] = new_x
                    prev_x = new_x
                end
            else
                center_i = Integer(ceil(length(daughters) / 2))
                prev_x = x
                xs[center_i] = prev_x
                for daughter_i = (center_i - 1):-1:1
                    new_x = prev_x - x_sep
                    xs[daughter_i] = new_x 
                    prev_x = new_x
                end
                prev_x = xs[center_i]
                for daughter_i = (center_i + 1):length(daughters)
                    new_x = prev_x + x_sep
                    xs[daughter_i] = new_x
                    prev_x = new_x
                end
            end
            x_sep = x_sep ^ .9
            for daughter_i = 1:length(daughters)
                daughter = daughters[daughter_i]
                daughter_line_attach = Point(Integer(round(xs[daughter_i])), Integer(round(ys[daughter_i] - (layer_sep / 5))))
                line(non_term_line_attach, daughter_line_attach, :stroke)
                place_point(daughter, xs[daughter_i], ys[daughter_i], x_sep)
            end
        end
        
    end
    place_point(outer_tree, begin_x, begin_y, daughter_sep)
    finish()
    preview()
end
end # module



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
    right_hand::Array
    left_hand::String
    dot_index::Int
    originating_states::Array{Int}

    function EarleyState(
        state_num::Int,
        start_index::Int,
        end_index::Int,
        right_hand::Array,
        left_hand::String,
        dot_index::Int,
        originating_states::Array,
    )
        if dot_index > (length(right_hand) + 1)
            throw(BoundsError("Unable to declare a state with the given dot index"))
        elseif dot_index < 1
            throw(BoundsError("Unable to declare a state with the given dot index"))
        else
            new(
                state_num,
                start_index,
                end_index,
                right_hand,
                left_hand,
                dot_index,
                originating_states,
            )
        end
    end
end

"""
Add keyword version of EarleyState
"""
function EarleyState(;
    state_num,
    start_index,
    end_index,
    right_hand,
    left_hand,
    dot_index,
    originating_states,
)
    EarleyState(
        state_num,
        start_index,
        end_index,
        right_hand,
        left_hand,
        dot_index,
        originating_states,
    )
end

"""
Overload equality for EarleyStates
"""
function Base.:(==)(x::EarleyState, y::EarleyState)
    if x.start_index == y.start_index &&
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
    cmp_string =
        "|" *
        rpad(string(state.state_num), 4) *
        "|" *
        rpad(state.left_hand, 4) *
        "->" *
        lpad(join(state.right_hand[1:(dot_index-1)], " "), 10) *
        "*" *
        rpad(join(state.right_hand[dot_index:end], " "), 10) *
        " <== " *
        string(state.originating_states)
    print(io, cmp_string)
end

function Base.show(io::IO, chart::Array{EarleyState})
    println("-"^32)
    for state in chart
        println(state)
    end
    println("-"^32)
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

function increment_state_nums!(chart, start_num)
    for state in chart
        state.state_num = start_num
        start_num += 1
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
    next_state_num = charts[i][end].state_num + 1
    for chart in charts
        for old_state in chart
            # if the right hand side has the dot just before something that matches
            # the constituent that we just found,
            # then we should move the dot to the right in a new state
            if is_incomplete(old_state) &&
               old_state.right_hand[old_state.dot_index] == obtained_constituent
                if old_state.end_index == state.start_index # may need to check this
                    backpointers = old_state.originating_states[1:end]
                    backpointers = push!(backpointers, state.state_num)
                    new_state = EarleyState(
                        next_state_num,
                        old_state.start_index,
                        i,
                        old_state.right_hand,
                        old_state.left_hand,
                        old_state.dot_index + 1,
                        backpointers,
                    )
                    # if the left side and the right side of our rule are the same, don't add a new state
                    # this prevents infinite loops when you have VP -> VP rules.
                    if length(new_state.right_hand) == 1 &&
                       new_state.left_hand == new_state.right_hand[1]
                        continue
                    else
                        push!(charts[i], new_state)
                    end
                    next_state_num += 1
                end
            end
        end
    end
    if length(charts) >= i + 1 && length(charts[i+1]) != 0
        increment_state_nums!(charts[i+1], next_state_num)
    end
end

function predictor!(charts, i, productions::Dict, lexicon::Dict, state::EarleyState)
    next_category = next_cat(state)
    right_hands = productions[next_category]
    next_state_num = charts[i][end].state_num + 1
    for right_hand in right_hands
        new_state = EarleyState(next_state_num, i, i, right_hand, next_category, 1, [])
        # don't add a new state if it's the same as another state you've already added
        if !(new_state in charts[i])
            push!(charts[i], new_state)
            next_state_num += 1
        end
    end
    if length(charts) >= i + 1 && length(charts[i+1]) != 0
        increment_state_nums!(charts[i+1], next_state_num)
    end
end

function scanner!(
    charts,
    sent::Array{T},
    i::Int,
    productions::Dict,
    lexicon::Dict,
    state::EarleyState,
) where {T<:AbstractString}
    next_category = next_cat(state)
    next_word = ""
    if state.end_index > length(sent)
        return
    end
    next_word = sent[state.end_index]
    next_state_num = charts[i][end].state_num + 1
    if length(charts[i+1]) != 0
        next_state_num = charts[i+1][end].state_num + 1
    end
    if next_category in lexicon[next_word]
        new_state = EarleyState(next_state_num, i, i + 1, [next_word], next_category, 2, [])
        for chart in charts
            if new_state in chart
                return
            end
        end
        if length(charts[i+1]) == 0 || charts[i+1][end] != new_state
            push!(charts[i+1], new_state)
        end
    end
end

function parse_earley(productions, lexicon, sent, start_symbol = "S"; debug = false)
    parts_of_speech = unique(collect(Iterators.flatten(values(lexicon))))
    charts = []
    for i = 1:length(sent)+1
        push!(charts, EarleyState[])
    end
    # add initial state
    push!(charts[1], EarleyState(1, 1, 1, ["S"], "γ", 1, []))
    for i = 1:(length(sent)+1)
        for state in charts[i]
            next_category = next_cat(state)
            if is_incomplete(state) && !(next_category in parts_of_speech)
                predictor!(charts, i, productions, lexicon, state)
                if debug
                    println("-"^32)
                    println("predictor")
                    println(charts)
                end
            elseif is_incomplete(state) && next_category in parts_of_speech
                scanner!(charts, sent, i, productions, lexicon, state)
                if debug
                    println("-"^32)
                    println("Scanner" * next_category)
                    println(charts)
                end
            else
                completer!(charts, i, productions, lexicon, state)
                if debug
                    println("-"^32)
                    println("Completer")
                    println(charts)
                end
            end
        end
    end
    return charts
end
"""
This is a recognizer. Given an array of charts, it determines if the 
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
function build_backtrace_array(state::EarleyState, state_stack::Array, ; offset = "--")
    if state.originating_states == [] # base case
        bottom_piece = [state.left_hand, state.right_hand]
        return bottom_piece
    else
        right_piece = Any[state.left_hand]
        for pointer in state.originating_states
            push!(
                right_piece,
                build_backtrace_array(
                    state_stack[pointer],
                    state_stack,
                    offset = offset * "--",
                ),
            )
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
This function prints the lattice from its strange boolean format
"""
function print_lattice(lattice, non_terminals, tokens)
    n_rows, n_cols, n_non_terminals = size(lattice)
    tok_row = ""
    for token in tokens
        tok_row *= rpad(token, 6)
    end
    println(tok_row)
    println("-"^(1 + n_cols * 6))
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
    println("-"^(1 + n_cols * 6))
end

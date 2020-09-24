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
function get_depth(tree, marker = 0)
    if typeof(tree) <: Array && length(tree) == 1
        return marker
    else
        depths = []
        for daughter in tree[2:end]
            push!(depths, get_depth(daughter, marker + 1))
        end
        res = collect(Leaves(depths))
        if res[1] != []
            return max(res...)
        else
            return marker
        end
    end
end

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
Get the bracketed notation for the provided tree. 

This involves tree traversal
"""
function get_bracketed_string(tree)
    # base case
    str_res = ""
    if typeof(tree) == String
        return tree
    elseif length(tree) == 1
        return tree[1]
    else
        str_res = "["
        for sub_tree in tree
            str_res *= get_bracketed_string(sub_tree) * " "
        end
        return str_res * "]"
    end
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
                    xs[daughter_i] = new_x 
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
end

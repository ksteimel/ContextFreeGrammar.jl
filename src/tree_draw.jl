mutable struct TreePoint
    center_x::Float32
    center_y::Float32
    left_extent_x::Float32
    right_extent_x::Float32
end
NestedTreePoints = Union{TreePoint, Array{TreePoint}}
"""
Overload equality for TreePoint
"""
function Base.:(==)(a::TreePoint, b::TreePoint)
    if a.center_x == b.center_x &&
        a.center_y == b.center_y &&
        a.left_extent_x == b.left_extent_x &&
        a.right_extent_x == b.right_extent_x 
        return true
    else
        return false
    end
end
#function Base.show(io::IO, points::NestedTreePoints)
#    function print_tier(points::NestedTreePoints, indent_level::Int)
#        if length(points) == 1
#            println(io, "\t" ^ indent_level * String(points))
#        else
#            for daughter in points
#                print_tier(daughter, indent_level + 1)
#            end
#        end
#    end
#end
function TreePoint(;Fcenter_x, center_y, left_extent_x, right_extent_x)
    TreePoint(center_x, center_y, left_extent_x, right_extent_x)
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
This version of `find_extents` works with raw points trees,
finding the width is easy, finding the depth requires some traversal.
"""
function find_extents(points_tree::Array)
    top_y = points_tree[1].center_y
    left_x = points_tree[1].left_extent_x
    right_x = points_tree[1].right_extent_x
    bottom_y = top_y
    function find_bottom_y(tree)
        y = 0
        right = 0
        if typeof(tree) == TreePoint
            y = tree.center_y
            right = tree.right_extent_x
        else
            y = tree[1].center_y
            right = tree[1].right_extent_x
            for daughter in tree[2:end]
                daughter_y, daughter_right = find_bottom_y(daughter)
                if daughter_y > y
                    y = daughter_y
                end
                if daughter_right > right
                    right = daughter_right
                end
            end
        end
        return y, right
    end
    bottom_y, right_x = find_bottom_y(points_tree)
    total_width = right_x #- left_x
    total_depth = bottom_y #- top_y
    return round(1.5 * total_width), round(1.5 * total_depth)
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
function shift_point(tree_point::TreePoint, x_displacement)
    tree_point.center_x += x_displacement
    tree_point.left_extent_x += x_displacement
    tree_point.right_extent_x += x_displacement
end
"""
Shifts all points in the input tree over by x_displacement.
If x_displacement is negative, all points are shifted to the
left. If x_displacement is positive, all points are shifted to the
right.

Params:
--------
tree::Array
    The syntactic tree (typically a subtree), that is going to be shifted.
x_displacement<:Numeric
    The value to shift the tree. Positive shifts the
    tree right, negative left.
"""
function shift_tree(tree::Array, x_displacement::T) where T<:Number
    shift_point(tree[1], x_displacement)
    if length(tree) > 1
        for daughter in tree[2:end]
            if typeof(daughter) <: Array
                shift_tree(daughter, x_displacement)
            else
                shift_point(daughter, x_displacement)
            end
        end
        #right_ext = 0
        #if typeof(tree[end]) == TreePoint
        #    right_ext = tree[end].right_extent_x
        #else
        #    right_ext = tree[end][1].right_extent_x
        #end
        #if typeof(tree[1]) == TreePoint
        #    tree[1].right_extent_x = right_ext
        #else
        #    tree[1][1].right_extent_x = right_ext
        #end
    end
end
function verify_points_tree(tree)
    if typeof(tree[1]) == TreePoint
        return true
    else
        return false
    end
end
function naive_point_locate(outer_tree::Array)
    
end
"""
This function does the actual writing of the tree image once
all overlap and bounding box issues have been addressed. 

Params:
--------
syntactic_tree::Array                            
    This is the original syntactic tree that is going to be plotted.
points_tree::Array
    This is the tree of coordinate point information that has
    been built up and modified through other functions
"""
function write_tree_graphic(syntactic_tree::Array, points_tree::Array, filename::String)
    width, depth = find_extents(points_tree)
    Drawing(width, depth, filename)
    background("white")
    sethue("black")
    start = Point(points_tree[1].center_x, points_tree[1].center_y)
    origin(start)
    fontface("Georgia-Bold")
    fontsize(12)
    # recursive place point call
    function place_point_in_canvas(syntactic_tree, points_tree)
        if typeof(syntactic_tree) <: Array && length(syntactic_tree) == 1
            term_location = Point(points_tree[1].center_x, points_tree[1].center_y)
            text(syntactic_tree[1], term_location, halign=:center, valign=:middle)
        else
            non_term_location = Point(points_tree[1].center_x, points_tree[1].center_y)
            non_term_line_attach = Point(points_tree[1].center_x, points_tree[1].center_y + 10)
            text(syntactic_tree[1], non_term_location, halign=:center, valign=:middle)
            daughters = syntactic_tree[2:end]
            for daughter_i = 2:length(syntactic_tree)
                attach_x = 0
                attach_y = 0
                if typeof(points_tree[daughter_i]) == TreePoint
                    attach_x = points_tree[daughter_i].center_x
                    attach_y = points_tree[daughter_i].center_y
                else
                    attach_x = points_tree[daughter_i][1].center_x
                    attach_y = points_tree[daughter_i][1].center_y
                end
                daughter_line_attach = Point(attach_x, attach_y - 10)
                line(non_term_line_attach, daughter_line_attach, :stroke)
                place_point_in_canvas(syntactic_tree[daughter_i], points_tree[daughter_i])
            end
        end
    end
    place_point_in_canvas(syntactic_tree, points_tree)
    finish()
end
function center_tree(points_tree)
    if points_tree[1].left_extent_x < 0
        shift_tree(points_tree, points_tree[1].left_extent_x * - 1)
    elseif points_tree[1].left_extent_x > 0
        shift_tree(points_tree, 0 - points_tree[1].left_extent_x)
    end
end
"""
Writes a tree graphic at the filepath specified.

Here's how the tree drawing algorithm works: 
--------------------------------------------------
go through the tree from top to bottom, when you reach a terminal, record where you
think that point should go into a tree structure and also record the center, left extent,
and right extent.
as the stack collapses, the non-terminal nodes will take what they thought their position should be
as the center, the left extent as the left extent of their first daughter, the right extent as the 
right extent of their last daughter. 

This proceeds until the naive points for all nodes in the tree have been established

Then, we go through, breadth first and find out of there's overlap between the coordinates for any of
the daughters. If there are, an offset value is calculated for the x direction. All subtrees for one of
the overlapping daughters is modified so that they are no longer overlapping.

Then, a last pass is made to ensure that the tree isn't going to be very off center, 
e.g. if the left extent of the S node is way off base (too far away from 0 on the positive side or negative).
If this is the case, the whole tree is shifted to make it more centered.

Lastly, a Luxor canvas is prepared with the extents of the top node (plus a margin) and the points are
set from top to bottom.
"""
function tree_img(outer_tree::Array, filename::String)
    daughter_sep = 60 # this decays as we recursively build the tree
    layer_sep = 50 # this remains constant throughout the drawing
    begin_x =150
    begin_y = 20
    width_per_char = 10
    function naive_place_point(tree, x, y, x_sep)
        if typeof(tree) == String  || length(tree) == 1
            # we have a terminal in our tree, we should simply return
            # the x and y we have with half of the node sep 
            # on the left_x_extents and half on the right 
            node_width = 30
            if typeof(tree) == String
                node_width = width_per_char * length(tree)
            else
                node_width = width_per_char * length(tree[1])
            end
            disp = round(node_width/2)
            return TreePoint[TreePoint(x, y, x - disp, x + disp)]
        else
            # we have some number of daughters 
            # the array of daughters is stored in position
            daughters = tree[2:end]
            xs = zeros(length(daughters))
            ys = repeat([y + layer_sep], length(daughters))
            if iseven(length(daughters))
                left_center_i = Integer(floor(length(daughters) / 2))
                prev_x = x - Integer(round(x_sep / 2))
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
            x_sep = x_sep# ^ .9999
            daughters_point_array = []
            for daughter_i = 1:length(daughters)
                daughter = daughters[daughter_i]
                res = naive_place_point(daughter, xs[daughter_i], ys[daughter_i], x_sep)
                push!(daughters_point_array, res)
            end
            # gather information about the left extent of the left daughter and the 
            # right extent of the right daughter
            leftmost_daughter_left_x = 0
            rightmost_daughter_right_x = 0
            if typeof(daughters_point_array[1]) <: Array
                leftmost_daughter_left_x = daughters_point_array[1][1].left_extent_x
            else
                leftmost_daughter_left_x = daughters_point_array[1].left_extent_x
            end
            if typeof(daughters_point_array[end]) <: Array
                rightmost_daughter_right_x = daughters_point_array[end][1].right_extent_x
            else
                rightmost_daughter_right_x = daughters_point_array[end].right_extent_x
            end
            if !verify_points_tree([TreePoint(x, y, leftmost_daughter_left_x, rightmost_daughter_right_x), daughters_point_array])
                println("Unable to verify")
            end
            return vcat([TreePoint(x, y, leftmost_daughter_left_x, rightmost_daughter_right_x)], daughters_point_array)
        end
    end
    """
    This function fixes overlaps in the x direction
    """
    function fix_overlaps(tree, points_tree)
        horizontal_gap = 20
        # base case is that we are at the bottom of the tree
        if typeof(tree) == String || length(tree) == 1
            return
        else
            # we have some sort of non-terminal
            daughters = tree[2:end]
            daughter_points = points_tree[2:end]
            # correct nodes further down in the tree
            previous_right_edge = 0
            for daughter_i in 2:length(tree)
                # now correct the current level in the tree and return
                daughter_left_edge = 0
                if typeof(points_tree[daughter_i])  == TreePoint
                    daughter_left_edge = points_tree[daughter_i].left_extent_x
                else
                    daughter_left_edge = points_tree[daughter_i][1].left_extent_x
                end
                if previous_right_edge > daughter_left_edge + horizontal_gap
                    # we need to move daughter points over
                    shift_distance = horizontal_gap + (previous_right_edge - daughter_left_edge)
                    shift_tree(points_tree[daughter_i], shift_distance)
                end
                if typeof(points_tree[daughter_i]) == TreePoint
                    previous_right_edge = points_tree[daughter_i].right_extent_x
                else
                    previous_right_edge = points_tree[daughter_i][1].right_extent_x
                end
                fix_overlaps(tree[daughter_i], points_tree[daughter_i])
            end
            new_left = points_tree[1].left_extent_x 
            new_right = points_tree[1].right_extent_x
            if typeof(points_tree[2]) == TreePoint
                new_left = points_tree[2].left_extent_x 
            else
                new_left = points_tree[2][1].left_extent_x
            end
            if typeof(points_tree[end]) == TreePoint
                new_right = points_tree[end].left_extent_x
            else
                new_right = points_tree[end][1].left_extent_x
            end
            # modify the current root node's left and right extents
            points_tree[1].left_extent_x = new_left
            points_tree[1].right_extent_x = new_right
        end
    end
    points_tree = naive_place_point(outer_tree, begin_x, begin_y, daughter_sep)
    fix_overlaps(outer_tree, points_tree)
    center_tree(points_tree)
    write_tree_graphic(outer_tree, points_tree, filename)
end

"""
    opt_mask(rhs_pieces::Array; <keyword arguments>)
    
...
# Arguments
- `rhs_pieces::Array`:  The pieces of the right hand side
- `opt_marker::String`: This is the string that occurs at the beginning 
                        of the string to indicate that that piece is optional. 
                        This has to occur at the beginning of the string.
...
This is a utility function that takes a sequence of right hand side
elements and generates a bit mask representing which ones are optional

"""
function gen_opt_mask(rhs_pieces::Array; opt_marker::String="(")
    mask = Bool[]
    for rhs_piece in rhs_pieces
        if rhs_piece[1:1] == opt_marker
            push!(mask, true)
        else
            push!(mask, false)
        end 
    end
    return mask
end

"""
   strip_opt(rhs_pieces::Array; <keyword arguments>)
   
...
# Arguments
- `rhs_pieces::Array`: The pieces of the right hand side
- `opt_marker::String`: The string that occurs at the beginning 
                        of the rhs_piece to indicate that the string is optional. 
...

This function essentially just removes the `opt_marker` from the beginning of 
all right hand side elements.
"""
function strip_opt(rhs_pieces::Array; opt_marker::String="(")
    return [rhs_piece[1:1] != opt_marker ? rhs_piece : rhs_piece[2:end - 1] 
                for rhs_piece in rhs_pieces]
end

"""
    interleave_opts(rhs_pieces::Array, opt_mask::Array, pres_mask::Array)
    
...
# Arguments
- `rhs_pieces::Array`:  The pieces of the right hand side
- `opt_mask::Array`:    This is a mask representing the elements in rhs_pieces that are
                        optional. If true, then the element at that index in rhs_pieces
                        is optional.
- `pres_mask::Array`:   This mask indicates which optional elements should be 
                        present during the interleaving process.
...
"""
function interleave_opts(rhs_pieces::Array, opt_mask::Array, pres_mask::Array)
    pres_i = 1
    res = String[]
    for (mask_i, mask_element) in enumerate(opt_mask)
        if mask_element == false
            push!(res, rhs_pieces[mask_i])
        else
            if pres_mask[pres_i] == 1
                push!(res, rhs_pieces[mask_i])
            end 
            pres_i += 1
        end
    end
    return res
end

"""
    top_count(n_bits)
    
...
# Arguments:
- n_bits:   how many bits in boolean are available to represent
            the integer.
...
This gets the top value that can be represented using
the specified number of bits.

E.g. 3 bits can represent a value up to 14
"""
function top_count(n_bits::Int)
    if n_bits == 0 
        return 0
    else
        count = 2 * 2^(n_bits - 1)
        return count
    end
end

"""
    gen_opt_poss(rhs_pieces::Array)

...
# Arguments:
- rhs_pieces:   this is the array of elements on the right hand side
                of a rule. If there are optional elements in this
                rule, all variations of presence and absence of optional
                elements are returned
...

"""
function gen_opt_poss(rhs_pieces::Array)
    opt_mask = gen_opt_mask(rhs_pieces)
    n_opts = sum(opt_mask)
    #just return the whole rhs if there's no optional elements
    if n_opts == 0 
        return [rhs_pieces]
    end 
    rhs_pieces = strip_opt(rhs_pieces)
    #this tells us how high we have to count when computing the present masks
    top_end = top_count(n_opts) 
    poss = []
    for i=0:(top_end - 1)
        pres_mask = digits(i, base=2, pad=n_opts)
        push!(poss, interleave_opts(rhs_pieces, opt_mask, pres_mask))
    end
    return poss
end

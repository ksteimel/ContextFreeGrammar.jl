"""
This splits a sentence using the function in tokenize.

`tokenizer` is expected to be a function that takes a raw string
as input and then returns an array of SubStrings or an array of Strings
where each piece corresponds to a single token.
"""
function parse_sent(productions, lexicon, sent::T; tokenizer::Function=split) where T<:AbstractString
    words = tokenizer(sent)
    words = [strip(word) for word in sent if strip(word) != ""]
    return parse_earley(productions, lexicon, words, debug=false)
end

"""
This does sentence splitting and then parses each sentence in parallel.
The number of threads to use during parsing can be controlled by setting the 
`JULIA_NUM_THREADS` environment variable.

The tokenizer and ssplit functions must take strings in and return
some array of string pieces (either as full `Strings` or as `SubStrings`.
"""
function parse(productions::Dict, lexicon, text; 
               ssplit::Function=(text) -> split(text, "\n"),
               tokenizer::Function=split)
    # split sentences
    sents = ssplit(text)
    # call parse_sent on each sentence
    res_parses = []
    Threads.@threads for sent in sents
        if strip(sent) != ""
            push!(res, parse(productions, lexicon, sent, tokenizer=tokenizer))
        end
    end
end

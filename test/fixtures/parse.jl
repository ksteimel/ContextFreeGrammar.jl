using ContextFreeGrammar
rule_file = open("../doc/rules.txt")
rule_text = readlines(rule_file)
rule_text = join(rule_text, "\n")
productions, lexicon = read_rules(rule_text)
in_sents_file = open("fixtures/gen_sents.txt")
sents = readlines(in_sents_file)
function parse_all(productions, lexicon, sents)
    sent = [sent for sent in sents if strip(sent) != ""]
    Threads.@threads for sent in sents
        sent = split(sent, " ")
        sent = [string(strip(word)) for word in sent if strip(word) != ""]
        parse_earley(productions, lexicon, sent, debug = false)
    end
end
println("Problem sizes ")
println(sum([length(productions[kii]) for kii in keys(productions)]))
println(sum([length(lexicon[kii]) for kii in keys(lexicon)]))
@time parse_all(productions, lexicon, sents[1:300])

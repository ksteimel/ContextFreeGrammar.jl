using CFG
rule_file = open("./sample_rules.txt")
rule_text = readlines(rule_file)
rule_text = join(rule_text, "\n")
productions, lexicon = CFG.read_rules(rule_text)
sents = []
function gen_multiple(productions, lexicon, n_sents)
    sents = []
    for i = 1:n_sents
        push!(sents, CFG.generate(productions, lexicon))
    end
    return sents
end
@time sents = gen_multiple(productions, lexicon, 300000)
out_file = open("./gen_sents.txt", write = true, create = true)
for sent in sents
    write(out_file, sent * "\n")
end

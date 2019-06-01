using Test
include("src/CFG.jl")
@testset "rule_reading" begin
	simple_rules = """
			NP -> D N
			D : dog
			"""
	productions, lexicon = CFG.read_rules(simple_rules)
	res_productions = Dict(("D", "N") => "NP")
	res_lexicon = Dict("dog" => ["D"])
	@test res_productions == productions
	@test res_lexicon == lexicon
	multi_part_lexicon = 	"""
				NP -> Q N
				D : {dog, cat, mouse}
				"""
	productions, lexicon = CFG.read_rules(multi_part_lexicon)
	res_productions = Dict(("Q", "N") => "NP")
	res_lexicon = Dict("dog" => ["D"], "cat" => ["D"], "mouse" => ["D"])
	@test res_lexicon == lexicon
	@test res_productions == productions
	ambiguous_lexicon = 	"""
				D : dog
				V : dog
				"""
	res_lexicon = Dict("dog" => ["D","V"])
	productions, lexicon = CFG.read_rules(ambiguous_lexicon)
	@test lexicon == res_lexicon
end
@testset "binarization" begin
	@testset "binary_rules_are_unmodified" begin
		# check that binary rules pass through unadulterated
		binary_prod = Dict(("D","N") => "NP")
		lexicon = Dict("the" => ["D"], "dog" => ["N"])
		res_productions, res_lex, pairings = CFG.binarize!(binary_prod, lexicon)
		@test res_productions == binary_prod
	end
	@testset "unary_productions" begin
		# check that unary productions are fixed on the production side
		unary_prod = Dict(("D", "N") => "NP", ("NP",) => "S")
		lexicon = Dict("the" => ["D"], "dog" => ["N"])
		target_prod = Dict(("D", "N") => "S")
		res_prod, res_lex, pairings = CFG.binarize!(unary_prod, lexicon)	
		@test target_prod == res_prod
	
		# check that modifications to the lexicon in order to fix productions
		# are done appropriately
		unary_prod = Dict(("D",) => "NP")
		lexicon = Dict("the" => ["D"])
		res_prod, res_lex, pairings = CFG.binarize!(unary_prod, lexicon)
		target_lex = Dict("the" => ["NP"])
		@test target_lex == res_lex
	end
end
tokens = ["the","dog","runs","quite","fast"]
non_terminals = ["NP","VP","Av","Aj","D","N", "V", "AP", "S"]
lattice = zeros(Bool, 5, 5, length(non_terminals))
lattice[1,1,5] = true
lattice[1,2,6] = true
lattice[1,3,7] = true
lattice[1,4,3] = true
lattice[1,5,4] = true
lattice[2,1,1] = true
lattice[2,4,8] = true
lattice[5,1,9] = true
lattice[3,3,2] = true

CFG.print_lattice(lattice, non_terminals, tokens)

using Test
include("src/CFG.jl")
@testset "rule_reading" begin
	simple_rules = """
			NP -> D N
			D : dog
			"""
	productions, lexicon = CFG.read_rules(simple_rules)
	res_productions = Dict("NP" => [("D", "N")])
	res_lexicon = Dict("dog" => ["D"])
	@test res_productions == productions
	@test res_lexicon == lexicon
	multi_part_lexicon = 	"""
				NP -> Q N
				D : {dog, cat, mouse}
				"""
	productions, lexicon = CFG.read_rules(multi_part_lexicon)
	res_productions = Dict("NP" => [("Q", "N")])
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
	ambiguous_production = """
                            NP -> D N
                            NP -> Adj N
                            """
    productions, lexicon = CFG.read_rules(ambiguous_production)
    res_productions = Dict("NP" => [("D","N"), ("Adj","N")])
    @test productions == res_productions
end

@testset "rule_verify" begin
    productions = Dict("NP" => ["D","N"], "VP" => ["V", "NP"])
    lexicon = Dict("dog" => ["N", "V"], "the" => ["D"])
    @test CFG.verify_system(productions, lexicon) == true
    productions = Dict("NP" => ["D","N"], "VP" => ["V", "NP"])
    lexicon = Dict("dog" => ["N", "V"])
    @test CFG.verify_system(productions, lexicon) == false
    
end

@testset "earley_pieces" begin
    lexicon = Dict("dog" => ["V","N"], "cat" => ["N", "Adj"])
    parts_of_speech = ["V","N","Adj"]
    @test sort(parts_of_speech) == sort(unique(collect(Iterators.flatten(values(lexicon)))))
    @testset "EarleyState" begin
        @testset "ordered_constructor" begin
            sample_state = CFG.EarleyState(1,2,3,["NP","VP"], "S", 1, 3)
            @test sample_state.state_num == 1
            @test sample_state.start_index == 2
            @test sample_state.end_index == 3
            @test sample_state.right_hand == ["NP","VP"]
            @test sample_state.left_hand == "S"
            @test sample_state.dot_index == 1
            @test sample_state.originating_state_index == 3
        end
        @testset "malformed_construction" begin
            @test_throws BoundsError CFG.EarleyState(1,2,3,["NP","VP"], "S", 4, 3)
            @test_throws BoundsError CFG.EarleyState(1,2,3, ["NP","VP"], "S", 0, 3)
            @test CFG.EarleyState(1,2,3,["NP","VP"], "S", 3, 3).dot_index == 3
        end
        @testset "state_utils" begin
            initial_state = CFG.EarleyState(1,1, 1, ["S"], "γ", 1, 0)
            @test CFG.next_cat(initial_state) == "S"
            initial_state = CFG.EarleyState(1,1, 1, ["S"], "γ", 1, 0)
            @test CFG.is_incomplete(initial_state) == true
            complete_state = CFG.EarleyState(1,1, 1, ["S"], "γ", 2, 0)
            @test CFG.is_incomplete(complete_state) == false
        end
    end
    @testset "predictor" begin
        chart = CFG.EarleyState[]
        initial_state = CFG.EarleyState(1,1, 1, ["S"], "γ", 1, 0)
        push!(chart, initial_state)
        lexicon = Dict("dog" => ["N","V"], "cat" => ["N","Adj"])
        productions = Dict("S" => [["NP","VP"]], 
                            "NP" => [["N"]],
                            "VP" => [["V"]])
        step_index = 1
        charts = [chart]
        CFG.predictor!(charts, step_index, productions, lexicon, initial_state)
        @test length(charts[1]) == 2
        state_res = CFG.EarleyState(2, 1, 1, ["NP","VP"], "S", 1, 1)
        @test charts[1][2] == state_res
    end
end

println()
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

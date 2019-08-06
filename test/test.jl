using Test
using AbstractTrees
include("../src/CFG.jl")
PI = CFG.ProdItem
@testset "rule_reading" begin
	simple_rules = """
			NP -> D N
			D : dog
			"""
	productions, lexicon = CFG.read_rules(simple_rules)
	res_productions = Dict(PI("NP") => [[PI("D"), PI("N")]])
	res_lexicon = Dict(PI("dog") => [PI("D")])
	@test res_productions == productions
	@test res_lexicon == lexicon
	multi_part_lexicon = 	"""
				NP -> Q N
				D : {dog, cat, mouse}
				"""
	productions, lexicon = CFG.read_rules(multi_part_lexicon)
	res_productions = Dict(PI("NP") => [[PI("Q"), PI("N")]])
	res_lexicon = Dict(PI("dog") => [PI("D")], PI("cat") => [PI("D")], PI("mouse") => [PI("D")])
	@test res_lexicon == lexicon
	@test res_productions == productions
	ambiguous_lexicon = 	"""
				D : dog
				V : dog
				"""
	res_lexicon = Dict(PI("dog") => [PI("D"),PI("V")])
	productions, lexicon = CFG.read_rules(ambiguous_lexicon)
	@test lexicon == res_lexicon
	ambiguous_production = """
                            NP -> D N
                            NP -> Adj N
                            """
    productions, lexicon = CFG.read_rules(ambiguous_production)
    res_productions = Dict(PI("NP") => [[PI("D"),PI("N")], [PI("Adj"),PI("N")]])
    @test productions == res_productions
end

@testset "rule_verify" begin
    productions = Dict(PI("NP") => [[PI("D"),PI("N")]], PI("VP") => [[PI("V"), PI("NP")]])
    lexicon = Dict(PI("dog") => [PI("N"), PI("V")], PI("the") => [PI("D")])
    sent = ["the", "dog"]
    @test CFG.verify_productions(productions, lexicon) == true
    productions = Dict(PI("NP") => [[PI("D"),PI("N")]], PI("VP") => [[PI("V"), PI("NP")]])
    lexicon = Dict(PI("dog") => [PI("N"), PI("V")])
    one_word_sent = ["dog"]
    @test CFG.verify_productions(productions, lexicon) == false
    lexicon = Dict(PI("dog") => [PI("N"), PI("D"), PI("V")])
    @test CFG.verify_lexicon(lexicon, one_word_sent) == true
    @test CFG.verify_lexicon(lexicon, sent) == false
    # testing with phrases because that seems to cause an error 
    productions = Dict(PI("S") => [[PI("NP"), PI("VP")]], PI("NP") => [[PI("D"),PI("N")]], PI("VP") => [[PI("V"), PI("NP")]])

end

@testset "earley_pieces" begin
    lexicon = Dict(PI("dog") => [PI("V"),PI("N")], PI("cat") => [PI("N"), PI("Adj")])
    parts_of_speech = ["V","N","Adj"]
    @test sort(parts_of_speech) == sort(unique(collect(Iterators.flatten(values(lexicon)))))
    @testset "EarleyState" begin
        @testset "ordered_constructor" begin
            sample_state = CFG.EarleyState(1,2,3,[PI("NP"),PI("VP")], "S", 1, [3])
            @test sample_state.state_num == 1
            @test sample_state.start_index == 2
            @test sample_state.end_index == 3
            @test sample_state.right_hand == [PI("NP"),PI("VP")]
            @test sample_state.left_hand == PI("S")
            @test sample_state.dot_index == 1
            @test sample_state.originating_states == [3]
            @test !(CFG.is_spanning(sample_state, 4))
            spanning_state = CFG.EarleyState(1,1,3,[PI("NP"), PI("VP")], PI("S"), 1, [3])
            @test CFG.is_spanning(spanning_state, 2)
        end
        @testset "malformed_construction" begin
            @test_throws BoundsError CFG.EarleyState(1,2,3,[PI("NP"),PI("VP")], PI("S"), 4, [3])
            @test_throws BoundsError CFG.EarleyState(1,2,3, [PI("NP"),PI("VP")], PI("S"), 0, [3])
            @test CFG.EarleyState(1,2,3,[PI("NP"),PI("VP")], PI("S"), 3, [3]).dot_index == 3
        end
        @testset "state_utils" begin
            initial_state = CFG.EarleyState(1,1, 1, [PI("S")], PI("γ"), 1, [])
            @test CFG.next_cat(initial_state) == PI("S")
            initial_state = CFG.EarleyState(1,1, 1, [PI("S")], PI("γ"), 1, [])
            @test CFG.is_incomplete(initial_state) == true
            complete_state = CFG.EarleyState(1,1, 1, [PI("S")], PI("γ"), 2, [])
            @test CFG.is_incomplete(complete_state) == false
        end
    end
    
    @testset "predictor" begin
        chart = CFG.EarleyState[]
        initial_state = CFG.EarleyState(1,1, 1, [PI("S")], PI("γ"), 1, [])
        push!(chart, initial_state)
        lexicon = Dict(PI("dog") => [PI("N"),PI("V")], PI("cat") => [PI("N"),PI("Adj")])
        productions = Dict(PI("S") => [[PI("NP"),PI("VP")]], 
                            PI("NP") => [[PI("N")]],
                            PI("VP") => [[PI("V")]])
        step_index = 1
        charts = [chart, CFG.EarleyState[]]
        CFG.predictor!(charts, step_index, productions, lexicon, initial_state)
        @test length(charts[1]) == 2
        state_res = CFG.EarleyState(2, 1, 1, [PI("NP"),PI("VP")], PI("S"), 1, [])
        @test charts[1][2] == state_res
        ambiguous_productions = Dict(PI("S") => [[PI("CP"), PI("VP")], [PI("VP")]])
        step_index = 1 
        chart = CFG.EarleyState[]
        push!(chart, initial_state)
        charts = [chart, CFG.EarleyState[]]
        CFG.predictor!(charts, step_index, ambiguous_productions, lexicon, initial_state)
        @test length(charts[1]) == 3
    end
    
    @testset "scanner" begin
        @testset "no_change" begin
            chart = CFG.EarleyState[]
            initial_state = CFG.EarleyState(1,1, 1, ["S"], "γ", 1, [])
            push!(chart, initial_state)
            lexicon = Dict(PI("dog") => [PI("N"),PI("V")],
                            PI("the") => [PI("D")],
                            PI("ran") => [PI("V")])
            productions = Dict(PI("S") => [[PI("NP"),PI("VP")], [PI("VP")]],
                                PI("NP") => [[PI("D"), PI("N")], [PI("N")]],
                                PI("VP") => [[PI("VP")], [PI("VP"),PI("NP")]])
            state = CFG.EarleyState(2, 1, 1, [PI("NP"),PI("VP")], PI("S"), 1, []) # predictor applied
            push!(chart, state)
            state = CFG.EarleyState(3, 1, 1, [PI("VP")], PI("S"), 1, []) # predictor applied
            push!(chart, state)
            scan_state = CFG.EarleyState(4, 1, 1, [PI("D"), PI("N")], PI("NP"), 1, []) # predictor applied
            push!(chart, scan_state)
            state = CFG.EarleyState(5, 1, 1, [PI("N")], PI("NP"), 1, []) # predictor applied
            push!(chart, state)
            step_index = 1
            charts = [chart, CFG.EarleyState[], CFG.EarleyState[]]
            @test length(charts) == 3
            @test length(charts[1]) == 5
            sentence = ["the", "dog", "ran"]
            CFG.scanner!(charts, sentence, step_index, productions, lexicon, state) # this should not change anything
            @test length(charts) == 3
            @test length(charts[1]) == 5
        end 
        
        @testset "scan_applies" begin
            chart = CFG.EarleyState[]
            initial_state = CFG.EarleyState(1,1, 1, [PI("S")], PI("γ"), 1, [0])
            push!(chart, initial_state)
            lexicon = Dict(PI("dog") => [PI("N"),PI("V")],
                            PI("the") => [PI("D")],
                            PI("ran") => [PI("V")])
            productions = Dict(PI("S") => [[PI("NP"),PI("VP")], [PI("VP")]],
                                PI("NP") => [[PI("D"), PI("N")], [PI("N")]],
                                PI("VP") => [[PI("VP")], [PI("VP"), PI("NP")]])
            state = CFG.EarleyState(2, 1, 1, [PI("NP"),PI("VP")], PI("S"), 1, [])
            push!(chart, state)
            state = CFG.EarleyState(3, 1, 1, [PI("VP")], PI("S"), 1, [])
            push!(chart, state)
            scan_state = CFG.EarleyState(4, 1, 1, [PI("D"), PI("N")], PI("NP"), 1, [])
            push!(chart, scan_state)
            state = CFG.EarleyState(5, 1, 1, [PI("N")], PI("NP"), 1, [])
            push!(chart, state)
            step_index = 1
            charts = [chart, CFG.EarleyState[], CFG.EarleyState[]]
            @test length(charts[1]) == 5
            @test length(charts) == 3
            sentence = ["the", "dog", "ran"]
            CFG.scanner!(charts, sentence, step_index, productions, lexicon, scan_state) # this should not change anything
            @test length(charts[2]) == 1
            target_state = CFG.EarleyState(6, 1, 2, [PI("the")], PI("D"), 2, []) # come back to that last part
            @test charts[2][1] == target_state
        end
    end
    
    @testset "completer" begin
        chart = CFG.EarleyState[]
        initial_state = CFG.EarleyState(1,1, 1, [PI("S")], PI("γ"), 1, [])
        push!(chart, initial_state)
        lexicon = Dict(PI("dog") => [PI("N"),PI("V")],
                        PI("the") => [PI("D")],
                        PI("ran") => [PI("V")])
        productions = Dict(PI("S") => [[PI("NP"),PI("VP")], [PI("VP")]],
                            PI("NP") => [[PI("D"), PI("N")], [PI("N")]],
                            PI("VP") => [[PI("VP")], [PI("VP"),PI("NP")]])
        state = CFG.EarleyState(2, 1, 1, [PI("NP"),PI("VP")], PI("S"), 1, []) # predictor applied
        push!(chart, state)
        state = CFG.EarleyState(3, 1, 1, [PI("VP")], PI("S"), 1, []) # predictor applied
        push!(chart, state)
        scan_state = CFG.EarleyState(4, 1, 1, [PI("D"), PI("N")], PI("NP"), 1, []) # predictor applied
        push!(chart, scan_state)
        state = CFG.EarleyState(5, 1, 1, [PI("N")], PI("NP"), 1, []) # predictor applied
        push!(chart, state)
        state = CFG.EarleyState(6, 1, 2, [PI("N")], PI("NP"), 2, []) # scanner applied
        chart2 = [state]
        charts = [chart, chart2, CFG.EarleyState[]]
        step_index = 2
        CFG.completer!(charts, step_index, productions, lexicon, state)
        res_state = CFG.EarleyState(7, 1, 2, [PI("NP"), PI("VP")], PI("S"), 2, [6])
        @test length(charts[2]) == 2
        @test res_state == charts[2][end]
    end
end

@testset "earley" begin
    sentence = ["the", "dog", "runs"]
    productions = Dict(PI("S") => [[PI("VP")], [PI("NP"),PI("VP")]],
                        PI("NP") => [[PI("D"),PI("N")], [PI("N")]],
                        PI("VP") => [[PI("V")], [PI("V"),PI("NP")]])
    lexicon = Dict(PI("the") => [PI("D")], PI("dog") => [PI("N"), PI("V")], PI("runs") => [PI("V"), PI("N")])
    chart = CFG.parse_earley(productions, lexicon, sentence, debug=true)
    @test length(chart) > 1
    @test CFG.chart_recognize(chart)
    trees = CFG.chart_to_tree(chart, sentence)
    @test trees[1] == ["S", ["NP", ["D", ["the"]], ["N", ["dog"]]], ["VP", ["V", ["runs"]]]]
    @test collect(Leaves(trees[1])) == ["S","NP","D", "the","N", "dog","VP", "V", "runs"]
    sentence2 = ["I", "bought", "fireworks", "in", "Pennsylvania"]
    productions = Dict(PI("S") => [[PI("NP"),PI("VP")]],
                        PI("NP") => [[PI("N")]],
                        PI("VP") => [[PI("V")], [PI("V"), PI("NP")], [PI("V"), PI("NP"), PI("PP")]],
                        PI("PP") => [[PI("P"), PI("NP")]])
    lexicon = Dict(PI("I") => [PI("N")],
                    PI("bought") => [PI("V")], 
                    PI("fireworks") => [PI("N")], 
                    PI("in") => [PI("P")], 
                    PI("Pennsylvania") => [PI("N")])

    chart = CFG.parse_earley(productions, lexicon, sentence2, debug=true)
    #println(chart[1])
    trees = CFG.chart_to_tree(chart, sentence2)
    target_tree = ["S", ["NP", ["N", ["I"]]], 
                    ["VP", ["V", ["bought"]], 
                    ["NP", ["N", ["fireworks"]]], 
                    ["PP", ["P", ["in"]], ["NP", ["N", ["Pennsylvania"]]]]]]
    @test target_tree == trees[1]
    sentence = ["the", "large", "dog", "ran", "by", "the", "house"]
    lexicon = Dict(PI("the") => [PI("D")], PI("ran") => [PI("V")], PI("house") => [PI("N")],
                    PI("dog") => [PI("N")], PI("red") => [PI("Adj")], PI("large") => [PI("Adj")], 
                    PI("to") => [PI("P")], PI("in") => [PI("P")], PI("by") => [PI("P")])
    productions = Dict(PI("S") => [[PI("NP"), PI("VP")]], 
                        PI("VP") => [[PI("V")], [PI("V"), PI("PP")], [PI("V"), PI("P"), PI("PP")]], 
                        PI("NP") => [[PI("D"), PI("N")], [PI("N")], [PI("Adj"), PI("N")], [PI("D"), PI("Adj"), PI("N")]], 
                        PI("PP") => [[PI("P"), PI("NP")]])
    chart = CFG.parse_earley(productions, lexicon, sentence, debug=true)
    #println(chart)
    trees = CFG.chart_to_tree(chart, sentence)
    target_tree =  ["S", 
                        ["NP", 
                            ["D", ["the"]],
                            ["Adj", ["large"]], 
                            ["N", ["dog"]]
                        ],
                        ["VP", 
                        ["V", ["ran"]], 
                        ["PP", 
                            ["P", ["by"]], 
                            ["NP", 
                                ["D", ["the"]],
                                ["N", ["house"]]
                            ]
                        ]
                    ]
                ]
    @test target_tree == trees[1]
end

@testset "drawing_utils" begin
    parse_tree = ["S", ["NP", ["I"]], ["VP", ["V", ["fireworks"]]], ["PP", ["P", ["in"]], ["NP", ["N", ["Pennsylvania"]]]]]
    depth = 4
    println(CFG.get_depth(parse_tree))
    @test CFG.get_depth(parse_tree) == depth
end

@testset "production class" begin
    new_item = CFG.ProdItem("S")
    @test new_item.symbol == "S"
    @test new_item.optional == false
    @test new_item.repeat == false
    @test new_item.feats == []
end

lexicon = Dict(PI("dog") => [PI("N"),PI("V")],
                PI("the") => [PI("D")],
                PI("ran") => [PI("V")],
                PI("by") => [PI("P")],
                PI("my") => [PI("D")],
                PI("house") => [PI("N")],
                PI("houses") => [PI("N")])

productions = Dict("S" => [["NP","VP"], 
                            ["VP"]],
                    "NP" => [["D", "N"], 
                            ["N"]],
                    "VP" => [["V"], 
                            ["V","NP"], 
                            ["V", "NP", "PP"]],
                    "PP" => [["D","NP"]])
sent = CFG.generate(productions, lexicon)
println(sent)

z = ["S", ["NP", ["D", ["the"]], ["Adj", ["adventurous"]], ["N", ["dog"]]], ["VP", ["V", ["eats"]], ["NP", ["N", ["bacon"]], ["N", ["grease"]]]]]
CFG.tree_img(z, "testfile.png")
#println()
#tokens = ["the","dog","runs","quite","fast"]
#non_terminals = ["NP","VP","Av","Aj","D","N", "V", "AP", "S"]
#lattice = zeros(Bool, 5, 5, length(non_terminals))
#lattice[1,1,5] = true
#lattice[1,2,6] = true
#lattice[1,3,7] = true
#lattice[1,4,3] = true
#lattice[1,5,4] = true
#lattice[2,1,1] = true
#lattice[2,4,8] = true
#lattice[5,1,9] = true
#lattice[3,3,2] = true

#CFG.print_lattice(lattice, non_terminals, tokens)
#

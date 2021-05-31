#using JuMP, Test, NLPModels, NLPModelsJuMP, NLPModelsTest
using JuMP, Test, NLPModelsTest
using SparseArrays
using LinearAlgebra
using Statistics
using Printf
nlp_problems = setdiff(NLPModelsTest.nlp_problems, ["MGH01Feas"])

for problem in lowercase.(nlp_problems)
  include(joinpath("nlp_problems", "$problem.jl"))
end

include("../src/OnePhase.jl")
include("problems.jl")
include("kkt_system_solvers.jl")
include("linear_system_solvers.jl")
include("test_moi_nlp_solver.jl")
#include("test_moi_nlp_model.jl")
#include("nlp_consistency.jl")

function unit_tests()
    test_compare_columns()
    test_compute_indicies()
    test_linear_solvers()
    test_kkt_solvers()
end

#function basic_tests(solver)
function basic_tests(options::Dict{String, Any})
    @testset "rosenbrook" begin
        test_rosenbrook1(options)
        test_rosenbrook2(options)
        test_rosenbrook3(options)
        test_rosenbrook4(options)
    end

    @testset "LP" begin
        test_toy_lp1(options)
        test_toy_lp2(options)
        test_toy_lp3(options)
        test_toy_lp4(options)
        test_toy_lp5(options)
        test_toy_lp6(options)
        test_toy_lp7(options)
    end

    @testset "infeasible" begin
        model = toy_lp_inf1()
        #setsolver(model,solver)
        ##set_optimizer(model, OnePhase.OnePhaseSolver)
        ##set_optimizer(model, solver)
		attachSolverWithAttributesToJuMPModel(model, options)
        @test :Infeasible == optimize!(model)

        model = toy_lp_inf2()
        #setsolver(model,solver)
        ##set_optimizer(model, OnePhase.OnePhaseSolver)
        ##set_optimizer(model, solver)
		attachSolverWithAttributesToJuMPModel(model, options)
        @test :Infeasible == optimize!(model)

        model = circle_nc_inf1()
        #setsolver(model,solver)
        ##set_optimizer(model, OnePhase.OnePhaseSolver)
        ##set_optimizer(model, solver)
		attachSolverWithAttributesToJuMPModel(model, options)
        @test :Infeasible == optimize!(model)
    end

    @testset "convex_nlp" begin
        @testset "circle1" begin
            model = circle1()
            #setsolver(model,solver)
            ##set_optimizer(model, OnePhase.OnePhaseSolver)
            ##set_optimizer(model, solver)
			attachSolverWithAttributesToJuMPModel(model, options)
            @test :Optimal == optimize!(model)
            check_circle1(model)
        end
        @testset "circle2" begin
            model = circle2()
            #setsolver(model,solver)
            ##set_optimizer(model, OnePhase.OnePhaseSolver)
            ##set_optimizer(model, solver)
			attachSolverWithAttributesToJuMPModel(model, options)
            @test :Optimal == optimize!(model)
            check_circle2(model)
        end

        @testset "quad_opt" begin
            model = quad_opt()
            #setsolver(model,solver)
            ##set_optimizer(model, OnePhase.OnePhaseSolver)
            ##set_optimizer(model, solver)
			attachSolverWithAttributesToJuMPModel(model, options)
            if Test.Pass == @test :Optimal == optimize!(model)
                check_quad_opt(model)
            end
        end
    end

    @testset "nonconvex" begin
        model = circle_nc1()
        #setsolver(model,solver)
        ##set_optimizer(model, OnePhase.OnePhaseSolver)
        ##set_optimizer(model, solver)
		attachSolverWithAttributesToJuMPModel(model, options)
        @test :Optimal == optimize!(model)
        check_circle_nc1(model)

        model = circle_nc2()
        #setsolver(model,solver)
        ##set_optimizer(model, OnePhase.OnePhaseSolver)
        ##set_optimizer(model, solver)
		attachSolverWithAttributesToJuMPModel(model, options)
        @test :Optimal == optimize!(model)
        check_circle_nc2(model)
    end

    @testset "unbounded_opt_val" begin
        model = lp_unbd()
        #setsolver(model,solver)
        ##set_optimizer(model, OnePhase.OnePhaseSolver)
        ##set_optimizer(model, solver)
		attachSolverWithAttributesToJuMPModel(model, options)
        @test :Unbounded == optimize!(model)

        model = circle_nc_unbd()
        #setsolver(model,solver)
        ##set_optimizer(model, OnePhase.OnePhaseSolver)
        ##set_optimizer(model, solver)
		attachSolverWithAttributesToJuMPModel(model, options)
        status = optimize!(model)
        @test status == :Unbounded

        model = quad_unbd()
        #setsolver(model,solver)
        ##set_optimizer(model, OnePhase.OnePhaseSolver)
        ##set_optimizer(model, solver)
		attachSolverWithAttributesToJuMPModel(model, options)
        status = optimize!(model)
        @test_broken status == :Unbounded
    end

    @testset "unbounded_feasible_region" begin
        # problems with unbounded feasible region
        test_unbd_feas(solver)
    end

    @testset "starting point" begin
        test_starting_point(solver,0.5)
        test_starting_point(solver,-0.5)
    end
end

function basic_tests()
    max_it = 100
    output_level = 0
    a_norm_penalty = 1e-4
    @testset "basic_tests" begin
        @testset "cholseky linear system solve" begin
            #solver = OnePhase.OnePhaseSolver(max_iter=max_it,
            #solver = OnePhase.OnePhaseSolver(term!max_it=max_it,
            #a_norm_penalty = a_norm_penalty,
            #output_level=output_level,
            #kkt!kkt_solver_type=:schur)
            #basic_tests(solver)
			options = Dict{String, Any}("term!max_it"=>max_it, 
			"a_norm_penalty"=>a_norm_penalty,
            "output_level"=>output_level,
            "kkt!kkt_solver_type"=>:schur)
			basic_tests(options)
        end

        println("HSL not working")
        #=
        @testset "Ma97 linear system solve" begin
            #solver = OnePhase.OnePhaseSolver(term!max_it=max_it,
            #a_norm_penalty = a_norm_penalty,
            #output_level=output_level,
            #kkt!kkt_solver_type=:symmetric,
            #kkt!linear_solver_type=:HSL)
            #basic_tests(solver)
			options = Dict{String, Any}("term!max_it"=>max_it, 
			"a_norm_penalty"=>a_norm_penalty,
            "output_level"=>output_level,
            "kkt!kkt_solver_type"=>:symmetric,
            "kkt!linear_solver_type"=>:HSL)
			basic_tests(options)
        end

        @testset "Ma97 linear system solve with clever elimination" begin
            #solver = OnePhase.OnePhaseSolver(term!max_it=max_it,
            #a_norm_penalty = a_norm_penalty,
            #output_level=output_level,
            #kkt!kkt_solver_type=:clever_symmetric,
            #kkt!linear_solver_type=:HSL)
            #basic_tests(solver)
			options = Dict{String, Any}("term!max_it"=>max_it, 
			"a_norm_penalty"=>a_norm_penalty,
            "output_level"=>output_level,
            "kkt!kkt_solver_type"=>:clever_symmetric,
            "kkt!linear_solver_type"=>:HSL)
			basic_tests(options)
        end
        =#

        @testset "LDLT julia linear system solve" begin
            #solver = OnePhase.OnePhaseSolver(term!max_it=max_it,
            #a_norm_penalty = a_norm_penalty,
            #output_level=output_level,
            #kkt!kkt_solver_type=:clever_symmetric,
            #kkt!linear_solver_type=:julia)
            #basic_tests(solver)
			options = Dict{String, Any}("term!max_it"=>max_it, 
			"a_norm_penalty"=>a_norm_penalty,
            "output_level"=>output_level,
            "kkt!kkt_solver_type"=>:clever_symmetric,
            "kkt!linear_solver_type"=>:julia)
			basic_tests(options)
        end
    end
end

function moi_nlp_tests()
    @testset "test_moi_nlp_solver" begin
        test_lp1_feasible_MOI()
        test_lp1_optimal_MOI()
        test_nlp1_feasible_MOI()
        test_nlp1_optimal_MOI()
        test_lp1_feasible_JuMP()
        test_lp1_optimal_JuMP()
    end
end

# lets run the tests!
unit_tests()
moi_nlp_tests()
#basic_tests()
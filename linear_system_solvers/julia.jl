type linear_solver_JULIA <: abstract_linear_system_solver
	_factor # TO DO, give type

	# options
	sym::Symbol
	safe_mode::Bool

  function linear_solver_JULIA(sym::Symbol, safe_mode::Bool)
			this = new();
			this.sym = sym
			this.safe_mode = safe_mode
			return this
  end
end

function ls_factor!(solver::linear_solver_JULIA, SparseMatrix::SparseMatrixCSC{Float64,Int64}, n::Int64, m::Int64)
			inertia_status = 1;

			start_advanced_timer("JULIA/factorize")
			if solver.sym == :unsymmetric
				 solver._factor = lufact(SparseMatrix);
			elseif solver.sym == :definite
				try
					solver._factor = cholfact(Symmetric(SparseMatrix));
				catch(e)
					if typeof(e) == Base.LinAlg.PosDefException
							inertia_status = 0
					else
							println("ERROR in linear_solver_JULIA.ls_factor!")
							throw(e)
					end
				end
			else
				error("this.options.sym = " * string(solver.sym) * " not supported")
			end
			pause_advanced_timer("JULIA/factorize")

			return inertia_status; # inertia
end

function ls_solve!(solver::linear_solver_JULIA, my_rhs::Array{Float64,1}, my_sol::Array{Float64,1})
  my_sol[1:length(my_sol)] = solver._factor \ my_rhs; #::UmfpackLU{Float64,Int64}
end

function ls_solve(solver::linear_solver_JULIA, my_rhs::AbstractArray)
  return solver._factor \ my_rhs;
end

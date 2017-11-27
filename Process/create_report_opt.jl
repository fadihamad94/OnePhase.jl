include("../include.jl")
include("create_report.jl")
results = get_CUTEst_results()

####
#### Lets do an overall summary of the results
####

# i.e. create Table 3 through 5.

# compute median number of iterations

overlapping_results = overlap(results)

##### Comparison on time to find a KKT point
#####
##### Lets take a look at the problems for which
##### - one of the solvers finds a KKT point
##### - neither finds an unbounded solution
##### - if both find a local optima the local optima are the same
#####

dual_inf_free_results = remove_errors(overlapping_results, [:dual_infeasible,:primal_infeasible])
overlapping_opt_results = overlap(dual_inf_free_results)
overlapping_opt_results = restrict_to_set(overlapping_opt_results,[:optimal])
overlapping_opt_results = overlap(overlapping_opt_results)
f_TOL = 1e-1

function create_opt_res(res::Dict{String, Dict{String,problem_summary}}, method_list)
    opt_res = Dict{String, Dict{String,problem_summary}}()
    for method in method_list
        opt_res[method] = Dict{String,problem_summary}()
    end

    problem_list = keys(first(res)[2])
    for problem_name in problem_list
      same_fval = true
      first = true
      fval_others = Inf
      some_method_failed = false

      for method in method_list
         fval = res[method][problem_name].fval
         if first || abs(fval_others - fval) / (1.0 + max(abs(fval),abs(fval_others))) < f_TOL
           fval_others = min(fval_others, fval)
           first = false
         else
           same_fval = false
         end
         if res[method][problem_name].status != :optimal
           some_method_failed = true
         end
      end

      if same_fval || some_method_failed
          for method in method_list
             opt_res[method][problem_name] = res[method][problem_name]
          end
      end
    end
    return opt_res
end

method_list = keys(overlapping_opt_results)
opt_res = create_opt_res(overlapping_opt_results, method_list)

its, best, ratios, times = compute_its_etc(opt_res,MAX_IT=3000);

using PyPlot

plot_iteration_ratios(its, best, ratios)
savefig("opt_iter_ratios.pdf")

plot_iterations(its, best, ratios, 3000)
savefig("opt_iter_curve.pdf")




##
## FUNCTION VALUES
##


function best_fvals(method_name1, method_name2)
    better_fval = Dict()
    succeed = Dict()

    feas_tol = 1e-4
    fval_tol = 1e-1

    better_fval[method_name1] = 0
    better_fval[method_name2] = 0

    succeed[method_name1] = 0
    succeed[method_name2] = 0

    for problem_name in problem_list
      fval1 = overlapping_opt_results[method_name1][problem_name].fval
      con_vio1 = overlapping_opt_results[method_name1][problem_name].con_vio

      fval2 = overlapping_opt_results[method_name2][problem_name].fval
      con_vio2 = overlapping_opt_results[method_name2][problem_name].con_vio

      if con_vio1 < feas_tol && con_vio2 < feas_tol
        fbest = min(fval1,fval2)
        ftol_scaled = fval_tol * (1.0 + abs(fbest))

        if fval1 < fval2 - ftol_scaled
          better_fval[method_name1] += 1
        elseif fval2 < fval1 - ftol_scaled
          better_fval[method_name2] += 1
        end
      end

      if con_vio1 < feas_tol
        succeed[method_name1] += 1
      end

      if con_vio2 < feas_tol
        succeed[method_name2] += 1
      end
    end

    return better_fval, succeed
end

method_name1 = "IPOPT"
method_name2 = "IPOPT no perturb"
best_fvals(method_name1, method_name2)



##
## PLOT TIME CURVES
##
best = best_its(times)

min_y = 1.0

ratios = Dict()
y_vals = collect(1:length(best)) / length(best)
for (method_name, val) in its
  ratios[method_name] = times[method_name] ./ best
  semilogx(sort(ratios[method_name]), y_vals, label=method_name, basex=2)
  min_y = min(min_y,sum(ratios[method_name] .== 1.0) / length(best))
end
ax = gca()
ax[:set_xlim]([1.0,2^8.0])
ax[:set_ylim]([min_y,1.0])

#ax[:xaxis][:ticker] = 0.5
#title("Comparsion on 45 CUTEst problems")
xlabel("times ratio to best solver")
ylabel("proportion of problems")

legend()
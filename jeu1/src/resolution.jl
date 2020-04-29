# This file contains methods to solve an instance (heuristically or with CPLEX)

#using CPLEX
using JuMP
#using Cbc
using CPLEX


include("generation.jl")
#include("GA.jl")

TOL = 0.00001

#on commencera par dire que les contraintes de visibilité pour chaque ligne et colonne sont determine
#on pourra pas la suite faire une variante ou seules certaines le sont


################################# CPLEX ########################################


"""
Solve an instance with CPLEX

Argument
- t: array of size 4*n with values in [1, n]

Return
- status: :Optimal if the problem is solved optimally
- x: 3-dimensional variables array such that x[i, j, k] = 1 if cell (i, j) has value k
- getsolvetime(m): resolution time in seconds

"""

function cplexSolve(t::Array{Int64, 2})
    n = size(t, 2) #nbr d'elt par ligne

    # Create the model (two possible solvers, chose one)
    #CPLEX
    m = Model(CPLEX.Optimizer)
    #CBC
    #m = Model(with_optimizer(Cbc.Optimizer))


    # x[i, j, k] = 1 if cell (i, j) has value k
    @variable(m, x[1:n, 1:n, 1:n], Bin)

    # x[i, j, k, p] = 1 if cell (i, j) has value k, p the direction of visibility
    @variable(m, g[1:n, 1:n, 1:n, 1:4], Bin)

    ### Definition constrainte on x ###
    # Each cell (i, j) has one value k
    @constraint(m, [i in 1:n, j in 1:n], sum(x[i, j, k] for k in 1:n) == 1)

    # Each line l has one cell with value k
    @constraint(m, [k in 1:n, l in 1:n], sum(x[l, j, k] for j in 1:n) == 1)

    # Each column c has one cell with value k
    @constraint(m, [k in 1:n, c in 1:n], sum(x[i, c, k] for i in 1:n) == 1)


    ### Link g and x ###
    @constraint(m, [i in 1:n, j in 1:n, k in 1:n, d in 1:4], x[i,j,k] >= g[i,j,k,d])

    #one in the direction is visible
    @constraint(m, [i in 1:n, j in 1:n, k in 1:n], x[i,j,k]<=sum(g[i,c,h,4] for c in 1:j for h in 1:n))
    @constraint(m, [i in 1:n, j in 1:n, k in 1:n], x[i,j,k]<=sum(g[l,j,h,3] for l in j:n for h in 1:n))
    @constraint(m, [i in 1:n, j in 1:n, k in 1:n], x[i,j,k]<=sum(g[i,c,h,2] for c in j:n for h in 1:n))
    @constraint(m, [i in 1:n, j in 1:n, k in 1:n], x[i,j,k]<=sum(g[l,j,h,1] for l in 1:j for h in 1:n))



    ### constrainte on g ###
    # Define visible tower by Side
    @constraint(m, [i in 1:n, j in 1:n, k in 1:n], sum(g[i,m,h,4] for m in 1:j for h in k:n)>=x[i,j,k] )
    @constraint(m, [i in 1:n, j in 1:n, k in 1:n], sum(g[m,j,h,3] for m in i:n for h in k:n)>=x[i,j,k] )
    @constraint(m, [i in 1:n, j in 1:n, k in 1:n], sum(g[i,m,h,2] for m in j:n for h in k:n)>=x[i,j,k] )
    @constraint(m, [i in 1:n, j in 1:n, k in 1:n], sum(g[m,j,h,1] for m in 1:i for h in k:n)>=x[i,j,k] )


    ### visibility ###
    # number of visible tower in left side
    @constraint(m,[i in 1:n], sum(g[i,j,k,4] for j in 1:n for k in 1:n)==t[4,i])

    #right side
    @constraint(m,[i in 1:n], sum(g[i,j,k,2] for j in 1:n for k in 1:n)==t[2,i])

    #up side
    @constraint(m,[j in 1:n], sum(g[i,j,k,1] for i in 1:n for k in 1:n)==t[1,j])

    #down side
    @constraint(m,[j in 1:n], sum(g[i,j,k,3] for i in 1:n for k in 1:n)==t[3,j])


    ### Border ###
    @constraint(m, [i in 1:n], sum(g[i,1,k,4] for k in 1:n) == 1)
    @constraint(m, [i in 1:n], sum(g[i,n,k,2] for k in 1:n) == 1)
    @constraint(m, [j in 1:n], sum(g[1,j,k,1] for k in 1:n) == 1)
    @constraint(m, [j in 1:n], sum(g[n,j,k,3] for k in 1:n) == 1)


    # Maximize the top-left cell (reduce the problem symmetry)
    @objective(m, Max, sum(x[1, 1, k] + g[1,1,k,1] for k in 1:n))

    # Start a chronometer
    start = time()

    # Solve the model
    optimize!(m)

    # Return:
    # 1 - true if an optimum is found
    # 2 - the resolution time
    isSolved = JuMP.primal_status(m) == JuMP.MathOptInterface.FEASIBLE_POINT
    return isSolved, x, time() - start

end



############################# SOLVEDATASET ####################################


"""
Solve all the instances contained in "../data" through CPLEX and heuristics

The results are written in "../res/cplex" and "../res/heuristic"

Remark: If an instance has previously been solved (either by cplex or the heuristic) it will not be solved again
"""

function solveDataSet()

    dataFolder = "data/"
    resFolder = "res/"

    # Array which contains the name of the resolution methods
    resolutionMethod = ["cplex"]

    # Array which contains the result folder of each resolution method
    resolutionFolder = resFolder .* resolutionMethod

    # Create each result folder if it does not exist
    for folder in resolutionFolder
        if !isdir(folder)
            mkdir(folder)
        end
    end

    global isOptimal = false
    global solveTime = -1

    # For each instance
    # (for each file in folder dataFolder which ends by ".txt")
    for file in filter(x->occursin(".txt", x), readdir(dataFolder))

        println("-- Resolution of ", file)
        t = readInputFile(dataFolder * file)

        # For each resolution method
        for methodId in 1:size(resolutionMethod, 1)

            outputFile = resolutionFolder[methodId] * "/" * file

            # If the instance has not already been solved by this method
            #if !isfile(outputFile)

                fout = open(outputFile, "w")

                resolutionTime = -1
                isOptimal = false

                # If the method is cplex
                if resolutionMethod[methodId] == "cplex"

                    # Solve it and get the results
                    isOptimal, x, resolutionTime = cplexSolve(t)
                    println(isOptimal,resolutionTime)

                    # If a solution is found, write it
                    if isOptimal 
                        writeSolution(fout, x)
                    end
"""
                # If the method is one of the heuristics
                else

                    isSolved = false

                    # Start a chronometer
                    startingTime = time()
                    solution = []

                    # While the grid is not solved and less than 100 seconds are elapsed
                    while !isOptimal && resolutionTime < 1000
                        print(".")
                        Tpop = 20 #taille de la population
                        n = size(t,2)

                        # Solve it and get the results
                        isOptimal, best = GA(n,Tpop,t)

                        # Stop the chronometer
                        resolutionTime = time() - startingTime

                    end

                    println("")

                    # Write the solution (if any)
                    if isOptimal
                        writeSolution(fout, best)
                    end """
                end

                println(fout, "solveTime = ", resolutionTime)
                println(fout, "isOptimal = ", isOptimal)

                close(fout)
            #end


            # Display the results obtained with the method on the current instance
            include(outputFile)
            println(resolutionMethod[methodId], " optimal: ", isOptimal)
            println(resolutionMethod[methodId], " time: " * string(round(solveTime, sigdigits=2)) * "s\n")
        end
    end
end





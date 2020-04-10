# This file contains methods to solve an instance (heuristically or with CPLEX)
using CPLEX

include("generation.jl")

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

"""
function cplexSolve(t::Array{Int, 2})
    n = size(t, 2) #nbr d'elt par ligne

    # Create the model
    m = Model(CPLEX.Optimizer)

    # x[i, j, k] = 1 if cell (i, j) has value k
    @variable(m, x[1:n, 1:n, 1:n], Bin)

    # x[i, j, k, p] = 1 if cell (i, j) has value k, p the direction of visibility
    @variable(m, g[1:n, 1:n, 1:n, 1:4], Bin)

    #Definition constrainte on x
    # Each cell (i, j) has one value k
    @constraint(m, [i in 1:n, j in 1:n], sum(x[i, j, k] for k in 1:n) == 1)

    # Each line l has one cell with value k
    @constraint(m, [k in 1:n, l in 1:n], sum(x[l, j, k] for j in 1:n) == 1)

    # Each column c has one cell with value k
    @constraint(m, [k in 1:n, c in 1:n], sum(x[i, c, k] for i in 1:n) == 1)

    #Ling g and x
    @constraint(m, [i in 1:n, j in 1:n, k in 1:n, p in 1:4], x[i,j,k] == g[i,j,])


    # Define constrainte on g
    # Define visible tower Left Side
    @constraint(m, [i in 1:n, j in 1:n, k in 1:n], g[i,j,k,1]>=g[i,n,k,1] for n in 1:j))
    @constraint(m, [i in 1:n, j in 1:n, k in 1:n], g[i,j,k,1]>=g[i,n,k,1] for n in 1:j))

    # number of visible tower in left side
    @constraint(m,[i in 1:n, k in 1:4], sum(g[i,j,k,4] for j in 1:i)<=t[4,i])

    #right side
    @constraint(m,[i in 1:n, k in 1:4], sum(g[i,j,k,2] for j in i:n)<=t[2,i])

    #up side
    @constraint(m,[j in 1:n, k in 1:4], sum(g[i,j,k,1] for i in 1:j)<=t[1,j])

    #down side
    @constraint(m,[j in 1:n, k in 1:4], sum(g[i,j,k,3] for i in j:n)<=t[3,j])




    # Maximize the top-left cell (reduce the problem symmetry)
    @objective(m, Max, sum(x[1, 1, k] + g[1,1,k,1] for k in 1:n))

    # Start a chronometer
    start = time()

    # Solve the model
    optimize!(m)

    # Return:
    # 1 - true if an optimum is found
    # 2 - the resolution time
    return JuMP.primal_status(m) == JuMP.MathOptInterface.FEASIBLE_POINT, x, time() - start

end
"""


############################### HEURISTIC ######################################

"""
Heuristically solve an instance
- t: array of size 4*n with values in [1, n]
"""

function heuristicSolve(t::Array{Int, 2}, checkFeasibility::Bool)
  n = size(t, 2)
  g = Array{Int64,2} #grid of the problem

  # True if the grid has completely been filled
  gridFilled = false

  # True if the grid may still have a solution
  gridStillFeasible = true

  # While the grid is not filled and it may still be solvable
  while !gridFilled && gridStillFeasible

    # Coordinates of the most constrained cell
    mcCell = [-1 -1]

    # Values which can be assigned to the most constrained cell
    values = nothing

    # Randomly select a cell and a value
    l = ceil.(Int, n * rand())
    c = ceil.(Int, n * rand())
    id = 1

    # For each cell of the grid, while a cell with 0 values has not been found
    while id <= n*n && (values == nothing || size(values, 1)  != 0)

        # If the cell does not have a value
        if g[l, c] == 0

            # Get the values which can be assigned to the cell
            cValues = possibleValues(t, g, l, c)

            # If it is the first cell or if it is the most constrained cell currently found
            if values == nothing || size(cValues, 1) < size(values, 1)

                values = cValues
                mcCell = [l c]
            end
        end

        # Go to the next cell
        if c < n
            c += 1
        else
            if l < n
                l += 1
                c = 1
            else
                l = 1
                c = 1
            end
        end

        id += 1
    end

    # If all the cell have a value
    if values == nothing

        gridFilled = true
        gridStillFeasible = true
    else

        # If a cell cannot be assigned any value
        if size(values, 1) == 0
            gridStillFeasible = false

            # Else assign a random value to the most constrained cell
        else

            newValue = ceil.(Int, rand() * size(values, 1))
            if checkFeasibility

                gridStillFeasible = false
                id = 1
                while !gridStillFeasible && id <= size(values, 1)

                    g[mcCell[1], mcCell[2]] = values[rem(newValue, size(values, 1)) + 1]

                    if isGridFeasible(t,g)
                        gridStillFeasible = true
                    else
                        newValue += 1
                    end

                    id += 1

                end
            else
                g[mcCell[1], mcCell[2]] = values[newValue]
            end
        end
    end
  end

  return gridStillFeasible, g

end

############################ POSSIBLEVALUES ####################################

"""
Number of values which could currently be assigned to a cell

Arguments
- t: array of size 4*n with values in [1, n]
- x: array of size n*n with values in [0, n] (0 if empty)
- l, c: row and column of the cell

Return
- values: array of integers which do not appear on line l, column c or in the block of (l, c)
"""

function possibleValues(t::Array{Int, 2}, x::Array{Int,2}, l::Int64, c::Int64)

  values = Array{Int64, 1}()
  n = size(t, 2)
  for v in 1:n
    if isValid(t, x, l, c, v)
      values = append!(values, v)
    end
  end
  return values
end


############################# TESTFEASIBLE ####################################

"""
Test if the grid is feasible

Arguments
- t: array of size 4*n with values in [1, n]
- x: array of size n*n with values in [0, n] (0 if empty)
"""

function isGridFeasible(t::Array{Int64, 2}, x::Array{Int,2})

    n = size(t, 2)
    isFeasible = true

    l = 1
    c = 1

    # For each cell (l, c) while previous cells can be assigned a value
    while isFeasible && l <= n

        # If a value is not assigned to (l, c)
        if t[l, c] == 0

            # Test all values v until a value which can be assigned to (l, c) is found
            feasibleValueFound = false
            v = 1

            while !feasibleValueFound && v <= n

                if isValid(t, l, c, v)
                    feasibleValueFound = true
                end

                v += 1

            end

            if !feasibleValueFound
                isFeasible = false
            end
        end

        # Go to the next cell
        if c < n
            c += 1
        else
            l += 1
            c = 1
        end
    end

    return isFeasible
end

############################# BINTOINT ####################################

"""
convert binary matrix to int matrix

Arguments
- x: array of size 3*n with values in [0, 1]

return
- g: array of 2*n with values in [0:n]

"""

function bintoint(x :: Array{Int64,3})
  g = Array{Int64,2}
  for i in 1:n
    for j in 1:n
      for k in 1:n
        if x[i,j,k,1] == 1
          g[i,j] = k
        end
      end
    end
  end
end



############################# SOLVEDATASET ####################################


"""
Solve all the instances contained in "../data" through CPLEX and heuristics

The results are written in "../res/cplex" and "../res/heuristic"

Remark: If an instance has previously been solved (either by cplex or the heuristic) it will not be solved again
"""

function solveDataSet()

    dataFolder = "../data/"
    resFolder = "../res/"

    # Array which contains the name of the resolution methods
    resolutionMethod = ["cplex"]
    #resolutionMethod = ["cplex", "heuristique"]

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
        readInputFile(dataFolder * file)

        # TODO
        println("In file resolution.jl, in method solveDataSet(), TODO: read value returned by readInputFile()")

        # For each resolution method
        for methodId in 1:size(resolutionMethod, 1)

            outputFile = resolutionFolder[methodId] * "/" * file

            # If the instance has not already been solved by this method
            if !isfile(outputFile)

                fout = open(outputFile, "w")

                resolutionTime = -1
                isOptimal = false

                # If the method is cplex
                if resolutionMethod[methodId] == "cplex"

                    # TODO
                    println("In file resolution.jl, in method solveDataSet(), TODO: fix cplexSolve() arguments and returned values")

                    # Solve it and get the results
                    isOptimal, resolutionTime = cplexSolve()

                    # If a solution is found, write it
                    if isOptimal
                        # TODO
                        println("In file resolution.jl, in method solveDataSet(), TODO: write cplex solution in fout")
                    end

                # If the method is one of the heuristics
                else

                    isSolved = false

                    # Start a chronometer
                    startingTime = time()

                    # While the grid is not solved and less than 100 seconds are elapsed
                    while !isOptimal && resolutionTime < 100

                        # TODO
                        println("In file resolution.jl, in method solveDataSet(), TODO: fix heuristicSolve() arguments and returned values")

                        # Solve it and get the results
                        isOptimal, resolutionTime = heuristicSolve()

                        # Stop the chronometer
                        resolutionTime = time() - startingTime

                    end

                    # Write the solution (if any)
                    if isOptimal

                        # TODO
                        println("In file resolution.jl, in method solveDataSet(), TODO: write the heuristic solution in fout")

                    end
                end

                println(fout, "solveTime = ", resolutionTime)
                println(fout, "isOptimal = ", isOptimal)

                # TODO
                println("In file resolution.jl, in method solveDataSet(), TODO: write the solution in fout")
                close(fout)
            end


            # Display the results obtained with the method on the current instance
            include(outputFile)
            println(resolutionMethod[methodId], " optimal: ", isOptimal)
            println(resolutionMethod[methodId], " time: " * string(round(solveTime, sigdigits=2)) * "s\n")
        end
    end
end

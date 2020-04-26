# This file contains methods to solve an instance (heuristically or with CPLEX)
using CPLEX
using JuMP
#using Cbc

include("io.jl")

TOL = 0.00001


############################### CPLEX ######################################

"""
Solve an instance with CPLEX
"""

function cplexSolve(grid::Array{Int64, 2})

    n = size(grid, 1) #taille de la grille

    # Create the model
    m = Model(CPLEX.Optimizer)

    #variable d'environnement au coup k
    @variable(m, x[1:n, 1:n, 1:n*n], Int64)
    #variable pour le coup k
    @variable(m, y[1:n, 1:n, 1:4, 1:n*n], Bin)

    
    """
    #constraints of the grid
    # 1 : bas  ;  2 : gauche  ;  3 : haut  ;  4 : droite
    @constraints(m, [i in 1:n, j in 1:n], x[i,j,1] == grid[i,j])
    @constraints(m, [i in 1:n, k in 1:n*n], y[i,1,2,k] == 0)
    @constraints(m, [i in 1:n, k in 1:n*n], y[i,n,4,k] == 0)
    @constraints(m, [j in 1:n, k in 1:n*n], y[1,j,3,k] == 0)
    @constraints(m, [j in 1:n, k in 1:n*n], y[n,j,1,k] == 0)

    for i in 1:n
        for j in 1:n
            if grid[i,j] == -1
                @constraints(m, [d in 1:4, k in 1:n*n], y[i,j,d,k] == 0)
            elseif grid[i,j-1] == -1
                @constraints(m, [k in 1:n*n], y[i,j,2,k] == 0)
            elseif grid[i,j+1] == -1
                @constraints(m, [k in 1:n*n], y[i,j,4,k] == 0)
            elseif grid[i-1,j] == -1
                @constraints(m, [k in 1:n*n], y[i,j,3,k] == 0)
            elseif grid[i+1,j] == -1
                @constraints(m, [k in 1:n*n], y[i,j,1,k] == 0)
            end
        end
    end
    """
    # Start a chronometer
    start = time()

    # Solve the model
    optimize!(m)

    # Return:
    # 1 - true if an optimum is found
    # 2 - the resolution time
    return JuMP.primal_status(m) == JuMP.MathOptInterface.FEASIBLE_POINT, time() - start
    
end

############## PB DE TYPE A REGLER ENCORE #########################

############################# HEURISTIC ####################################

"""
Heuristically solve an instance (on parcourt toutes les branches)

- tk: array of size n*n with values in {0;1;2} at the beginning
"""

function heuristicSolve(t0::Array{Int64,2}) 
    Nb = 32 #nbr boules 
    move = zeros(Int64,Nb-1,3)
    iteration = zeros(Int64,Nb-1,20) #choix coup à l'itération k ( 20 coup max)
    #isSolution = false 
    tk = t0

    while Nb != 1 
        M = possiblemove(tk) #possible move in the grid
        N = size(M,1) #number of move 
        branch = true
        rand = ceil.(Int,N*rand())
        attempts = 0 # number of move at tk

        while attempts != N &&  N != 0

            if branch
                rand = ceil.(Int, N * rand())
                attempts = 0
            end

            if iteration[32-Nb+1,rand] != 1
                l = M[rand,1]
                c = M[rand,2]
                d = M[rand,3]
                tk = move(tk, l, c, d)
                Nb -= 1
                move[32-Nb] = [l, c, d]
                iteration[32-Nb, rand] = 1

                M = possiblemove(tk) #possible move in the grid
                N = size(M,1) #number of move
                branch = true
            else 
                rand = rem(rand+1,N)
                if rand == 0
                    rand = N
                end
                branch = false
                attempts += 1 
            end
        
        end

        #if no possible move or all move already test go back
        if N == 0 || attempts == N
            unmove(tk, l, c, d)
            Nb += 1
            move[32-Nb] = [0, 0, 0]
            iteration[32-Nb +1] = zeros(Int64, 20)
        end


    end
    return move 
end 


############################# ISVALID ####################################

"""
Test if cell (l, c) can be assigned value v

Arguments
- tk: array of size n*n with values in {-1;0;1} at the k-th iteration
- l, c: considered cell
- d: la direction de déplacement
- 

Return: true if t[l, c] can be set to v; false otherwise
"""
function isValid(t::Array{Int64, 2}, l::Int64, c::Int64, v::Int64)

    n = size(t, 1)
    isValid = true
    if t[l,c] == 0
        isValid = false
    else
        #grid border
        if (l == 1 || l == 2) && d == 3
            isValid = false
        elseif (l == n || l == n-1) && d == 1
            isValid = false
        elseif (c == 1 || c == 2) && d == 2
            isValid = false 
        elseif (c == n || c == n-1) && d == 4
            isValid = false
        #cross border
        elseif (t[l-1,c] == -1 || t[l-2,c] == -1) && d == 3
            isValid = false
        elseif (t[l+1,c] == -1 || t[l+2,c] == -1) && d == 1
            isValid = false    
        elseif (t[l,c-1] == -1 || t[l,c-2] == -1) && d == 2
            isValid = false            
        elseif (t[l,c+1] == -1 || t[l,c+2] == -1) && d == 4
            isValid = false 
        end 
        #possible move
        if isValid
            if !(t[l-1,c] == 1 && t[l-2,c] == 0) && d == 1
                isValid = false
            elseif !(t[l+1,c] == 1 && t[l+2,c] == 0) && d == 3
                isValid = false
            elseif !(t[l,c+1] == 1 && t[l,c+2] == 0) && d == 4
                isValid = false
            elseif !(t[l,c-1] == 1 && t[l,c-2] == 0) && d == 2
                isValid = false
        end
    end        
    return isValid   
end

############################# POSSIBLEMOVE ####################################

"""
give the possible move

Arguments
- tk: array of size n*n with values in {-1;0;1} at the k-th iteration

Return: list of move possible
"""
function possiblemove(t::Array{Int64, 2})

    n = size(t, 1)
    mv = Array{Int64, 2}
    for d in 1:4
        for l in 1:n
            for c in 1:n
                valid = isValid(t,l,c,d)
                if valid
                    append!(mv,[[l,c,d]])
                end
            end
        end
    end
    return mv
end

############################# MOVE ####################################

"""
one move 

arguments :
- tk: array of size n*n with values in {-1;0;1} at the beginning
- d : Int64, direction
- i : Int64, line
- j : Int64, column

return : 
- tk+1 (tk if not valid)

"""
function move(tk::Array{Int64, 2}, i::Int64, j::Int64, d::Int64)
    if isValid(tk,i,j,d)
        if d == 1
            tk[i,j] = 0
            tk[i-1,j] = 0
            tk[i-2,j] = 1
        elseif d == 2
            tk[i,j] = 0
            tk[i,j-1] = 0
            tk[i,j-2] = 1
        elseif d == 3
            tk[i,j] = 0
            tk[i+1,j] = 0
            tk[i+2,j] = 1
        elseif d == 4
            tk[i,j] = 0
            tk[i,j+1] = 0
            tk[i,j+2] = 1
        end
    end
    return tk    
end 

############################# UNMOVE ####################################

"""
unmove 

arguments :
- tk: array of size n*n with values in {-1;0;1} at the beginning
- d : Int64, direction
- i : Int64, line
- j : Int64, column

return : 
- tk-1 (tk if not valid)

"""
function unmove(tk::Array{Int64, 2}, i::Int64, j::Int64, d::Int64)
    if d == 1
        tk[i,j] = 1
        tk[i-1,j] = 1
        tk[i-2,j] = 0
    elseif d == 2
        tk[i,j] = 1
        tk[i,j-1] = 1
        tk[i,j-2] = 0
    elseif d == 3
        tk[i,j] = 1
        tk[i+1,j] = 1
        tk[i+2,j] = 0
    elseif d == 4
        tk[i,j] = 1
        tk[i,j+1] = 1
        tk[i,j+2] = 0
    end
    return tk    
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

    file = filter(x->occursin(".txt", x), readdir(dataFolder))
    t = readInputFile(dataFolder * file)

    # For each instance
    # (for each file in folder dataFolder which ends by ".txt")
    for i in 1:10  
        
        println("-- Resolution of ", file*i)

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
                    isOptimal, resolutionTime = cplexSolve(t)
                    
                    # If a solution is found, write it
                    if isOptimal
                        writeSolution(fout, x)
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
                
                close(fout)
            end


            # Display the results obtained with the method on the current instance
            include(outputFile)
            println(resolutionMethod[methodId], " optimal: ", isOptimal)
            println(resolutionMethod[methodId], " time: " * string(round(solveTime, sigdigits=2)) * "s\n")
        end         
    end 
end

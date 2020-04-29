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


############################# HEURISTIC ####################################

"""
Heuristically solve an instance (on parcourt toutes les branches)

- tk: array of size n*n with values in {0;1;2} at the beginning
"""

function heuristicSolve()

    t = readInputFile("data/test2.txt") 
    init = 11
    #init = 32
    #Nb = 32 #nbr boules 
    Nb = 11
    Move = zeros(Int64,Nb,3)
    iteration = zeros(Int64,Nb,20) #choix coup à l'itération k ( 20 coup max)
    isSolution = false 
    tk = t
    rd = Int(1)
    l = 5
    c = 5
    d = 1
    branch = true
    rd = ceil.(Int, N*rand())
    attempts = 1 
    a = 0   #compteur
    OPT = zeros(Int64,Nb,3)
    Nbmin = init

    
    while Nb != 1 && a < 10000000
        M = possiblemove(tk) #possible move in the grid
        N = size(M,1)-2 #number of move
        println("N=",N)
        println("tentative ", attempts)
        println(M)
        a += 1

        
        while attempts != N &&  N != 0
            
            #println("tentative 2   ", attempts)
            if branch
                rd = ceil.(Int, N*rand())
                attempts = 1
            
                if Nb > 28 || Nb < 5 || rem(a,1000000) == 0
                    #println(a)
                    #println("rand")
                end
            end
            if Nb == init
                println(iteration)
                println("iteration[",32-Nb+1, ",", rd, "] = ",1)
            end
            #println("iteration[",32-Nb+1, ",", rd, "] = ",1)
            #a += 1
            #if rem(a,100000) == 0
            """
            if Nb > 28 || Nb < 5 
                println("-----------------------------------------------------------------------------------------")
                println("")
                
                println("N : ",N)
                #println(M)
                #displayGrid(tk)
                #println(iteration)
                #println(l, ",", c, ",", d)
                println(attempts)
                #println(Move)
                #println("iteration[",32-Nb+1, ",", rd, "] = ",1)

            end
            """
            if iteration[init-Nb+1,rd] != 1
                #println("bug ",rd, " ",M)
                l = M[rd+2][1]
                c = M[rd+2][2]
                d = M[rd+2][3]
                tk = move(tk, l, c, d)
                if Nb > 28 || Nb < 5 
                    #println(l, ",", c, ",", d)
                    #println("it=",32-Nb+1)
                    #displayGrid(tk)
                    #println(iteration)
                end
                #println(tk)
                println("--------------------", Nb, "----------------")
                
                displayGrid(tk)
                Nb -= 1
                Move[init-Nb,1] = l 
                Move[init-Nb,2] = c 
                Move[init-Nb,3] = d
                
                #on attribue la réponse optimale
                if Nb < Nbmin
                    Nbmin = Nb
                    OPT = deepcopy(Move)
                end

                iteration[init-Nb, rd] = 1
                println(iteration)
               
                M = possiblemove(tk) #possible move in the grid
                println("M=",M)
                N = size(M,1)-2 #number of move
                branch = true
                """
                if Nb > 28 || Nb < 5 || rem(a,1000000) == 0
                    println("M=",M)
                    println(iteration)
                end
                """
            elseif N == 0
                #println("back")
            elseif attempts != N
                #println("N : ",N)
                rd = rem(rd+1,N)
                if rd == 0
                    rd = N
                end
                branch = false
                attempts += 1 
                """
                if Nb > 28 || Nb < 5 
                    println("next")
                    println(attempts)
                end
                """
                #println("rand = ", rd)
            end
            println("Move = ", Move)
        end
        #println("Move = ", Move)
        #if no possible move or all move already test go back


        if ((N == 0) || (attempts == N)) && Nb != 1 && Nb != init
            #println("000000-----------------------------------------------------------------------------------------")
            
            println("notvalid, Nb= ", Nb)
            #println("n=0 : ", N==0)
            #println("attempts=N : ", attempts == N)
            branch = true

            l = Move[init-Nb,1]
            c = Move[init-Nb,2]
            d = Move[init-Nb,3]
            println(32-Nb)
            println(l, ",", c, ",", d)
            #displayGrid(tk)
            tk = unmove(tk, l, c, d)
            #displayGrid(tk)

            #println(iteration)

            #println("N = ", N)
            Move[init-Nb,1] = 0
            Move[init-Nb,2] = 0
            Move[init-Nb,3] = 0
            if Nb > 28 || Nb < 5 
                println("Move = ", Move)
            end
            Nb += 1

            if N == 0
                attempts += 1
            elseif attempts == N
                attempts = 1
                #println("init")
            end

            iteration[init-Nb+1,rd] = 1
            for i in 1:size(iteration,2)
                iteration[init-Nb+2,i] = 0
            end
            """
            if  Nb < 5 
                println("erase ", init-Nb+2)
                println(iteration)
                println(tk)
                println(Move)
                println(M)
                println(attempts)
            end
            """
        end


    end
    if Nbmin == 1
        isSolution = true
    end

    return isSolution, OPT, Nbmin 

end 


############################# ISVALID ####################################

"""
Test if cell (l, c) can be assigned value v

Arguments
- tk: array of size n*n with values in {-1;0;1} at the k-th iteration
- l, c: considered cell
- d: la direction de déplacement


Return: true if t[l, c] can be set to v; false otherwise
"""
function isValid(t::Array{Int64, 2}, l::Int64, c::Int64, d::Int64)

    n = size(t, 1)
    isValid = true
    if t[l,c] == 0 || t[l,c] == 2
        isValid = false
        #println("no ball")
    else
        #grid border
        if (l == 1 || l == 2) && d == 3
            isValid = false
            #println("border 1")
        elseif (l == n || l == n-1) && d == 1
            isValid = false
            #println("border 2")
        elseif (c == 1 || c == 2) && d == 2
            isValid = false 
            #println("border 3")
        elseif (c == n || c == n-1) && d == 4
            isValid = false
            #println("border 4")
        #cross border
        elseif d == 3
            if t[l-1,c] == 2 || t[l-2,c] == 2
                isValid = false
                #println("cross 1")
            end
        elseif d == 1
            if t[l+1,c] == 2 || t[l+2,c] == 2
                isValid = false
                #println("cross 2")  
            end  
        elseif d == 2
            if t[l,c-1] == 2 || t[l,c-2] == 2 
                isValid = false
                #println("cross 3")  
            end          
        elseif d == 4
            if t[l,c+1] == 2 || t[l,c+2] == 2
                isValid = false
                #println("cross 4")
            end 
        end 

        #possible move
        if isValid
            if d == 1
                if !(t[l+1,c] == 1 && t[l+2,c] == 0)
                    isValid = false
                    #println("config 1")
                end           
            elseif d == 2
                if !(t[l,c-1] == 1 && t[l,c-2] == 0)
                    isValid = false
                    #println("config 2")
                end 
            elseif d == 4
                if !(t[l,c+1] == 1 && t[l,c+2] == 0)
                    isValid = false
                    #println("config 3")
                end
            elseif d == 3
                if !(t[l-1,c] == 1 && t[l-2,c] == 0)
                    isValid = false
                    #println("config 4")
                end
            end
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
    mv = [[0,0,0],[0,0,0]]
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
        #println("valid")
        if d == 1
            #println("d1")
            tk[i,j] = 0
            tk[i+1,j] = 0
            tk[i+2,j] = 1
        elseif d == 2
            tk[i,j] = 0
            tk[i,j-1] = 0
            tk[i,j-2] = 1
        elseif d == 3
            tk[i,j] = 0
            tk[i-1,j] = 0
            tk[i-2,j] = 1
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
    #tkk = copy(tk)
    #println("UNMOVE")
    if d == 1
        tk[i,j] = 1
        tk[i+1,j] = 1
        tk[i+2,j] = 0
    elseif d == 2
        tk[i,j] = 1
        tk[i,j-1] = 1
        tk[i,j-2] = 0
    elseif d == 3
        tk[i,j] = 1
        tk[i-1,j] = 1
        tk[i-2,j] = 0
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
                        isOptimal, Move, Nb = heuristicSolve()

                        # Stop the chronometer
                        resolutionTime = time() - startingTime
                        
                    end

                    # Write the solution (if any)
                    if isOptimal
                        writeSolution(fout, Move)
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

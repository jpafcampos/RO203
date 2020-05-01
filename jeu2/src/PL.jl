# This file contains methods to solve an instance (heuristically or with CPLEX)
using Cbc
using JuMP

#include("generation.jl")

TOL = 0.00001

"""
Solve an instance with CPLEX
"""


function cplexSolve()

    #n = size(grid, 1) #taille de la grille
    n = 7
    # Create the model
    m = Model(Cbc.Optimizer)

    #variable d'environnement au coup k
    # E[i,j, t] == 1 si la case (i,j) est occupée à l'instant t
    @variable(m, E[1:n, 1:n, 1:32], Bin)
    #variable pour le coup k
    # C[i,j,t,d] == 1 si un coup est fait dans la direction d, à partir de la case (i,j) à l'instant t 
    @variable(m, C[1:n, 1:n, 1:31, 1:4], Bin)

    #configuration initiale
    for i in 1:n
        for j in 1:n
            if (    !(i == 4 && j== 4) 
			   &&  !(i == 1 && j== 1) 
			   &&  !(i == 1 && j== 2) 
			   &&  !(i == 2 && j== 1) 
			   &&  !(i == 2 && j== 2) 
			   &&  !(i == 6 && j==1) 
			   &&  !(i == 6 && j==2) 
			   &&  !(i == 7 && j==1) 
			   &&  !(i == 7 && j==2) 
			   &&  !(i == 1 && j==6) 
			   &&  !(i == 1 && j==7) 
			   &&  !(i == 2 && j==6) 
			   &&  !(i == 2 && j==7) 
			   &&  !(i == 6 && j==6) 
			   &&  !(i == 6 && j==7) 
			   &&  !(i == 7 && j==6) 
			   &&  !(i == 7 && j==7) )
			
            @constraint(m, E[i, j, 1]==1) 
            end
        end
    end

    #contraintes de format de la grille
    @constraint(m, [i in 1:2, j in 1:2, t in 1:32], E[i,j,t] == 0)
    @constraint(m, [i in 6:n, j in 1:2, t in 1:32], E[i,j,t] == 0)
    @constraint(m, [i in 1:2, j in 6:n, t in 1:32], E[i,j,t] == 0)
    @constraint(m, [i in 6:n, j in 6:n, t in 1:32], E[i,j,t] == 0)
    
    @constraint(m, E[4, 4, 1]==0)
    
    #les directions : 1 = bas, 2 = haut, 3 = droite, 4 = gauche

    @constraint(m, [i in 1:n, j in 1:n, t in 1:31], C[i, j, t, 1] <= E[i, j, t])
    @constraint(m, [i in 1:n-1, j in 1:n, t in 1:31], C[i, j, t, 1] <= E[i+1, j, t])
    @constraint(m, [i in 1:n-2, j in 1:n, t in 1:31], C[i, j, t, 1] <= 1 - E[i+2, j, t])

    @constraint(m, [i in 1:n, j in 1:n, t in 1:31], C[i, j, t, 2] <= E[i, j, t])
    @constraint(m, [i in 2:n, j in 1:n, t in 1:31], C[i, j, t, 2] <= E[i-1, j, t])
    @constraint(m, [i in 3:n, j in 1:n, t in 1:31], C[i, j, t, 2] <= 1 - E[i-2, j, t])

    @constraint(m, [i in 1:n, j in 1:n, t in 1:31], C[i, j, t, 3] <= E[i, j, t])
    @constraint(m, [i in 1:n, j in 1:n-1, t in 1:31], C[i, j, t, 3] <= E[i, j+1, t])
    @constraint(m, [i in 1:n, j in 1:n-2, t in 1:31], C[i, j, t, 3] <= 1 - E[i, j+2, t])

    @constraint(m, [i in 1:n, j in 1:n, t in 1:31], C[i, j, t, 4] <= E[i, j, t])
    @constraint(m, [i in 1:n, j in 2:n, t in 1:31], C[i, j, t, 4] <= E[i, j-1, t])
    @constraint(m, [i in 1:n, j in 3:n, t in 1:31], C[i, j, t, 4] <= 1 - E[i, j-2, t])
    
    #@constraint(m, [i == 4, j == 4, t in 1:31], E[i, j, t]-E[i, j, t+1]==sum(C[i, j, t, d] for d in 1 : 4) + C[i-1, , t, 1] - C[i-2, j, t, 1] + C[i+1, j, t, 2] - C[i+2, j, t, 2] + C[i,j-1, t, 3] - C[i, j-2, t, 3] + C[i, j+1, t, ] - C[i, j+2, t, 4])
    #j in 1 : 7 ; i in 3:7
    #@constraint(m, [i in 3:n, j in 1:n, t in 1:31], E[i, j, t]-E[i, j, t+1]==sum(C[i, j, t, d] for d in 1 : 4) + C[i-1, j, t, 1] - C[i-2, j, t, 1])
#
    ##j in 1 : 7 ; i in 1:5
    #@constraint(m, [i in 1:5, j in 1:n, t in 1:31], E[i, j, t]-E[i, j, t+1]==sum(C[i, j, t, d] for d in 1 : 4) + C[i+1, j, t, 2] - C[i+2, j, t, 2])
#
    ##i in 1 : 7 ; j in 3:7
    #@constraint(m, [i in 1:n, j in 3:n, t in 1:31], E[i, j, t]-E[i, j, t+1]==sum(C[i, j, t, d] for d in 1 : 4) + C[i,j-1, t, 3] - C[i, j-2, t, 3])
#
    ##i 1 a n;  j 1 a 5  
    #@constraint(m, [i in 1:n, j in 1:5, t in 1:31], E[i, j, t]-E[i, j, t+1]==sum(C[i, j, t, d] for d in 1 : 4) + C[i, j+1, t, 4] - C[i, j+2, t, 4])

    #coups vers le bas
    @constraint(m, [i in 1:2, j in 3:5, t in 1:31], E[i+2, j, t] - E[i+2, j, t+1] == sum(C[i+2, j, t, d] for d in 1 : 4) + C[i+1, j, t, 1] - C[i, j, t, 1])
    @constraint(m, [i in 3:3, j in 1:7, t in 1:31], E[i+2, j, t] - E[i+2, j, t+1] == sum(C[i+2, j, t, d] for d in 1 : 4) + C[i+1, j, t, 1] - C[i, j, t, 1])
    @constraint(m, [i in 4:5, j in 3:5, t in 1:31], E[i+2, j, t] - E[i+2, j, t+1] == sum(C[i+2, j, t, d] for d in 1 : 4) + C[i+1, j, t, 1] - C[i, j, t, 1])

    #coups vers le haut
    @constraint(m, [i in 6:7, j in 3:5, t in 1:31], E[i-2, j, t] - E[i-2, j, t+1] == sum(C[i-2, j, t, d] for d in 1 : 4) + C[i-1, j, t, 2] - C[i, j, t, 2])
    @constraint(m, [i in 5:5, j in 1:7, t in 1:31], E[i-2, j, t] - E[i-2, j, t+1] == sum(C[i-2, j, t, d] for d in 1 : 4) + C[i-1, j, t, 2] - C[i, j, t, 2])
    @constraint(m, [i in 3:4, j in 3:5, t in 1:31], E[i-2, j, t] - E[i-2, j, t+1] == sum(C[i-2, j, t, d] for d in 1 : 4) + C[i-1, j, t, 1] - C[i, j, t, 2])

    #coups vers la droite
    @constraint(m, [i in 1:2, j in 1:1, t in 1:31], E[i, j+2, t] - E[i, j+2, t+1] == sum(C[i, j+2, t, d] for d in 1 : 4) + C[i, j+1, t, 1] - C[i, j, t, 3])
    @constraint(m, [i in 3:5, j in 1:5, t in 1:31], E[i, j+2, t] - E[i, j+2, t+1] == sum(C[i, j+2, t, d] for d in 1 : 4) + C[i, j+1, t, 1] - C[i, j, t, 3])
    @constraint(m, [i in 6:7, j in 1:1, t in 1:31], E[i, j+2, t] - E[i, j+2, t+1] == sum(C[i, j+2, t, d] for d in 1 : 4) + C[i, j+1, t, 1] - C[i, j, t, 3])

    #cousp vers la gauche
    @constraint(m, [i in 1:2, j in 5:5, t in 1:31], E[i, j-2, t] - E[i, j-2, t+1] == sum(C[i, j-2, t, d] for d in 1 : 4) + C[i, j-1, t, 1] - C[i, j, t, 4])
    @constraint(m, [i in 3:5, j in 3:7, t in 1:31], E[i, j-2, t] - E[i, j-2, t+1] == sum(C[i, j-2, t, d] for d in 1 : 4) + C[i, j-1, t, 1] - C[i, j, t, 4])
    @constraint(m, [i in 6:7, j in 5:5, t in 1:31], E[i, j-2, t] - E[i, j-2, t+1] == sum(C[i, j-2, t, d] for d in 1 : 4) + C[i, j-1, t, 1] - C[i, j, t, 4])

    #les bords de la grille
    @constraint(m, [i in 6:7, j in 3:5, t in 1:31], C[i,j,t,1] == 0)
    @constraint(m, [i in 1:2, j in 3:5, t in 1:31], C[i,j,t,2] == 0)
    @constraint(m, [i in 3:5, j in 6:7, t in 1:31], C[i,j,t,3] == 0)
    @constraint(m, [i in 3:5, j in 1:2, t in 1:31], C[i,j,t,4] == 0)

    #un coup par t
    @constraint(m, [i in 1:n, j in 1:n, t in 1:31], sum(C[i, j, t, d] for d in 1:4) <= 1  )

    #à la fin il faut y avoir un seul peg
    #@constraint(m, [i in 1:7, j in 1:7], sum(E[i,j,32]) == 1)

    #on veut que, à la fin, la case (4,4) soit occupée
    @objective(m, Max, E[4,4,32])

    #for i in 1:n
    #    for j in 1:n
    #        if (    !(i == 4 && j== 4) 
	#		   &&  !(i == 1 && j== 1) 
	#		   &&  !(i == 1 && j== 2) 
	#		   &&  !(i == 2 && j== 1) 
	#		   &&  !(i == 2 && j== 2) 
	#		   &&  !(i == 6 && j==1) 
	#		   &&  !(i == 6 && j==2) 
	#		   &&  !(i == 7 && j==1) 
	#		   &&  !(i == 7 && j==2) 
	#		   &&  !(i == 1 && j==6) 
	#		   &&  !(i == 1 && j==7) 
	#		   &&  !(i == 2 && j==6) 
	#		   &&  !(i == 2 && j==7) 
	#		   &&  !(i == 6 && j==6) 
	#		   &&  !(i == 6 && j==7) 
	#		   &&  !(i == 7 && j==6) 
	#		   &&  !(i == 7 && j==7) )
	#		
    #        @objective(m, Min, E[i, j, 32]) 
    #        end
    #    end
    #end
    #
    # Start a chronometer
    start = time()

    # Solve the model
    optimize!(m)

    # Return:
    # 1 - true if an optimum is found
    # 2 - the resolution time
	leStatut = (JuMP.primal_status(m) == JuMP.MathOptInterface.FEASIBLE_POINT)
	println("statut = ", leStatut)
    return JuMP.primal_status(m) == JuMP.MathOptInterface.FEASIBLE_POINT, E, C, time() - start
    
end

function sequenceOfMoves(C)
    moves = zeros(Int,31,4)
    indice = 1
    for t in 1:31
        for i in 1:7
            for j in 1:7
                for d in 1:4
                    if JuMP.value.(C[i,j,t,d]) == 1
                        moves[indice,1] = i
                        moves[indice,2] = j
                        moves[indice,3] = t
                        moves[indice,4] = d
                        indice += 1
                    end
                end
            end
        end
    end
    return moves
end
    
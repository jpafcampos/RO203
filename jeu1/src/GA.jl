########################################################
####### Genetic Algorithm to solve Towers puzzle #######
########################################################
using JuMP
using Random

#-------------------------------------------------------------
function roll(arr, step)
  return vcat(arr[end-step+1:end], arr[1:end-step])'
end

#-------------------------------------------------------------
function hasDoubles(ind, n)
  x = copy(ind)
  if size(x,1)==1 || size(x,2)==1
    x = reshape(ind,n,n)
    x = x'
  end
  
  for i in 1:n
    if countDoubles(x[i,:]) >= 1 || countDoubles(x[:,i]) >= 1
      return true
    end
  end
  
  return false
end


#-------------------------------------------------------------
function hasDoublesInRow(ind, n)
  x = copy(ind)
  if size(x,1)==1 || size(x,2)==1
    x = reshape(ind,n,n)
    x = x'
  end
  
  for i in 1:n
    if countDoubles(x[i,:]) >= 1
      return true
    end
  end
  
  return false
end
#-------------------------------------------------------------
function hasDoublesInCol(ind, n)
  x = copy(ind)
  if size(x,1)==1 || size(x,2)==1
    x = reshape(ind,n,n)
    x = x'
  end
  
  for i in 1:n
    if countDoubles(x[:,i]) >= 1
      return true
    end
  end
  
  return false
end

#-------------------------------------------------------------
"""
function to refine a good solution, fixing doubled elements
"""
function refinement(ind, n , cont)
  x = copy(ind)
  if size(x,1)==1 || size(x,2)==1
    x = reshape(ind,n,n)
    x = x'
  end
  fit1 = 0
  fit2 = 0

  if hasDoublesInRow(x,n)
    x1 = refinementRow(x, n, cont)
    fit1 = fitness(x1, cont)
  end

  if hasDoublesInCol(x,n)
    x2 = refinementCol(x,n,cont)
    fit2 = fitness(x2,cont)
  end

  fitOriginal = fitness(x,cont)

    if fit1 > fit2 
      return x1
    elseif (fit2 > fit1)
      return x2
    else
      return x
    end

end


function refinementRow(ind, n, cont)
  x = copy(ind)
  if size(x,1)==1 || size(x,2)==1
    x = reshape(ind,n,n)
    x = x'
  end
  map = Int64.(zeros(n))
  duplicatedElem = 0
  missingElem =0
  Index = 0

  for j in 1:n
    if Index>0 break end
    map = Int64.(zeros(n))
    arr = x[j,:]
    for i in 1:n
      map[arr[i]] += 1
      if map[arr[i]] > 1
        Index = j
      end
    end  
  end

  for i in 1:n
    if map[i] == 0
      missingElem = i
    end
    if map[i] == 2
      duplicatedElem = i
    end
  end

  if Index > 0
    for i in 1:n
      if x[Index, i] == duplicatedElem
        x[Index, i] = missingElem
        break
      end
    end
  end

  
  return x

end

function refinementCol(ind, n, cont)
   #pour les colonnes
   x = copy(ind)
   if size(x,1)==1 || size(x,2)==1
     x = reshape(ind,n,n)
     x = x'
   end

  map = Int64.(zeros(n))
  duplicatedElem = 0
  missingElem =0
  Index = 0

  for j in 1:n
    if Index>0 break end
    map = Int64.(zeros(n))
    arr = x[:,j]
    for i in 1:n
      map[arr[i]] += 1
      if map[arr[i]] > 1
        Index = j
      end
    end  
  end

  for i in 1:n
    if map[i] == 0
      missingElem = i
    end
    if map[i] == 2
      duplicatedElem = i
    end
  end

  if Index > 0
    for i in 1:n
      if x[i,Index] == duplicatedElem
        x[i,Index] = missingElem
        break
      end
    end
  end

  return x
end

#-------------------------------------------------------------
"""
verifies if a giver row or column verifies the constraints on both directions
Arguments:
ind: individual 
Index: index of row or column
cont: constraints matrix
orientation: char, 'h' for horizontal, 'v' for vertical

return: true of false
"""
function verifiesBothConstraints(ind, Index, cont, orientation)
  n = size(cont,2)
  x = copy(ind)
  if size(x,1)==1 || size(x,2)==1
    x = reshape(ind,n,n)
    x = x'
  end
  if orientation == 'h'
    #firstCont = cont[2, Index]
    return(nbvisible(x, Index, 2) == cont[2, Index] && nbvisible(x, Index, 4) == cont[4, Index]) 
  end

  if orientation == 'v'
    #firstCont = cont[2, Index]
    return(nbvisible(x, Index, 1) == cont[1, Index] && nbvisible(x, Index, 3) == cont[3, Index]) 
  end

end

#--------------------------------------------------------------
function countDoubles(arr)
  map = Int32.(zeros(length(arr)))
  numberOfDoubles = 0
  for i in 1:length(arr)
    map[arr[i]] += 1
    if map[arr[i]] > 1
      numberOfDoubles += 1
    end
  end
  return numberOfDoubles
end

################################# VISIBLE ######################################
"""
Test if cell (l, c) is visible

Arguments
- x: array of size n*n with values in [0, n] (0 if empty)
- l, c: Int64, line and column
- direction: Int64 (1=up, 2=right, 3=down, 4=left)

Return: true the tower is visible in this direction
"""

function visible(x, l, c, direction)
  n= size(x,1)
  bool = true
  if x[l,c] == 0
    bool = false
  elseif direction == 1 #up
    for i in 1:l
      if x[i,c]>x[l,c]
        bool = false
      end
    end
  elseif direction == 2 #right
    for i in c:n
      if x[l,i]>x[l,c]
        bool = false
      end
    end
  elseif direction == 3 #down
    for i in l:n
      if x[i,c]>x[l,c]
        bool = false
      end
    end
  elseif direction == 4 
    for i in 1:c
      if x[l,i]>x[l,c]
        bool = false
      end
    end
  end
  return bool
end


################################ NBVISIBLE #####################################
"""
Test if cell (l, c) can be assigned value v

Arguments
- x: array of size n*n with values in [0, n] (0 if empty)
- k: Int64, value at position k
- direction: Int64 (1=up, 2=right, 3=down, 4=left)

Return: the number of visible towers
"""

function nbvisible(x, k, direction)
  n= size(x,1)
  v = 0
  if direction == 1
    for i in 1:n
      if visible(x, i,k,1)
        v += 1
      end
    end

  elseif direction == 2
    for i in 1:n
      if visible(x, k,i,2)
        v += 1
      end
    end
  elseif direction == 3
    for i in 1:n
      if visible(x, i,k,3)
        v += 1
      end
    end
  elseif direction == 4
    for i in 1:n
      if visible(x, k,i,4)
        v += 1
      end
    end
  end
  return v
end

#------------------------------------------------
function flatten(arr)
    arr
    rst = Any[]
    grep(v) =   for x in v
                if isa(x, Tuple) ||  isa(x, Array)
                grep(x) 
                else push!(rst, x) end
                end
    grep(arr)
    rst'
end

#------------------------------------------------
function printIndividual(ind)
    n = sqrt(length(ind))
    n = convert(Int32, n)
    individual = reshape(ind,n,n)
    println(individual')

end

################################ GENERATE INDIVIDUAL #####################################
"""
Argument
-n: the size of the grid's side

return
-individual: an nxn matrix represeting a possible solution (individual)

"""
function generateRandomIndividual(n) 
    seed = Int64(ceil(40*rand()));
    size = n*n;
    individual = Array{Int64, 2}(undef, n, n)
    i = Int64(1)
    row = Array{Int64, 1}(undef, n)

    #for i in 1:n
     #   row[i] = i;
    #end

    row = randperm(n);
    row = row'
    for i in 1:n
        individual[i,:] = roll(row, i-1)
    end

    perm = randperm(MersenneTwister(seed+i), n)
    perm = shuffle!(perm)    
    
    temp = Array{Int64}(undef, n)
    temp = individual[: , perm[1] ]
    individual[:, perm[1]] = individual[:, perm[2]]
    individual[:, perm[2]] = temp

    temp = temp'
    temp = individual[perm[3], :]
    individual[perm[3],:] = individual[perm[4],:]
    individual[perm[3],:] = temp


    ind = Array{Int64, 1}(undef, size)
    ind = flatten(individual')
    return ind

end


################################ GENERATE POPULATION #####################################
"""
Argument:
n: size of grid
k: number of individuals in population

return:
population: matrice k x n, each line is a random individual

"""
function generatePopulation(n, k)
    population = Array{Int64,2}(undef, k, n*n)
    for i in 1:k
        population[i,:] = generateRandomIndividual(n)
    end

    return population
end


################################ MUTATION #####################################
"""
the mutation consists of swaping two rows

Argument:
ind: individual (one dimensional array) that will suffer the mutation
n: grid size
"""
function mutation(ind, n)
    seed = Int64(ceil(40*rand()));
    perm = randperm(MersenneTwister(seed), n)
    perm = shuffle!(perm) 
    indexRow1 = perm[1]
    indexRow2 = perm[2]
    indexRow1 -= 1
    indexRow2 -= 1

    for i in 1:n
        temp = ind[n*indexRow1 + i]
        ind[n*indexRow1 + i] = ind[n*indexRow2 + i]
        ind[n*indexRow2 + i] = temp
    end

    return ind

end


#-----------SECOND MUTATION----------------------
"""
second type of mutation: swaping columns
"""
function mutation2(ind, n)
  ind = reshape(ind, n, n)
  ind = ind'
  
  seed = Int64(ceil(40*rand()));
  perm = randperm(MersenneTwister(seed), n)
  perm = shuffle!(perm) 
  indexCol1 = perm[1]
  indexCol2 = perm[2]

  temp = ind[:,indexCol1]
  ind[:,indexCol1] = ind[:,indexCol2]
  ind[:,indexCol2] = temp

  ind = flatten(ind')

  return ind
    
end

#---------------THIRD MUTATION-------------------
"""
third mutation: swaping two elements on a given row / column
"""
function mutation3(ind, n, cont)
  ind = reshape(ind, n, n)
  ind = ind'
  seed = Int64(ceil(40*rand()));

  perm = randperm(MersenneTwister(seed), n)
  perm = shuffle!(perm) 

  if rand()<0.8
    v1 = perm[1]
    v2 = perm[2]
    rowIndex = ceil.(Int, n * rand())

    temp = ind[rowIndex,v1]
    ind[rowIndex,v1] = ind[rowIndex,v2]
    ind[rowIndex,v2] = temp
    
  else
    perm = shuffle!(perm)
    
    v1 = perm[1]
    v2 = perm[2]
    colIndex = ceil.(Int, n * rand())
    
    temp = ind[v1,colIndex]
    ind[v1,colIndex] = ind[v2,colIndex]
    ind[v2,colIndex] = temp
  end
  
  if fitness(ind, cont) <= n*4 - 3
    perm = randperm(MersenneTwister(seed), n)
    perm = shuffle!(perm) 
  
    v1 = perm[1]
    v2 = perm[2]
    rowIndex = ceil.(Int, n * rand())
  
    temp = ind[rowIndex,v1]
    ind[rowIndex,v1] = ind[rowIndex,v2]
    ind[rowIndex,v2] = temp
    
    perm = shuffle!(perm)
    
    v1 = perm[1]
    v2 = perm[2]
    colIndex = ceil.(Int, n * rand())
    
    temp = ind[v1,colIndex]
    ind[v1,colIndex] = ind[v2,colIndex]
    ind[v2,colIndex] = temp
  end

  if fitness(ind, cont) >= n*4-2
    ind = refinement(ind, n, cont)
  end

  ind = flatten(ind')

  return ind
  
end

#--------------------- FOURTH MUTATION---------------------------------------
function mutation4(ind, n, cont)
  ind = reshape(ind, n, n)
  ind = ind'
  seed = Int64(ceil(40*rand()));

  perm = randperm(MersenneTwister(seed), n)
  perm = shuffle!(perm) 

  v1 = perm[1]
  v2 = perm[2]
  rowIndex = ceil.(Int, n * rand())

  temp = ind[rowIndex,v1]
  ind[rowIndex,v1] = ind[rowIndex,v2]
  ind[rowIndex,v2] = temp
  
  if fitness(ind, cont) >= n*4 - 2
    ind = refinement(ind, n, cont)
  end

  ind = flatten(ind')

  return ind
  
end



################################ CROSSOVER #####################################
"""
combines two individuals (parents) in order to create two new individuals (offspring)

Argument:
p1: the first parent
p2: the second parent
n: the grid size

return:
offspring: matrice 2 x n, each line is a new individual
"""
function recombination(p1, p2, cont, n)

    seed = Int64(ceil(40*rand()));
    offspring1 = Array{Int32,2}(undef, n, n)
    offspring2 = Array{Int32,2}(undef, n, n)
    perm = randperm(MersenneTwister(seed), n)
    perm = shuffle!(perm)

    parent1 = reshape(p1,n,n)
    parent2 = reshape(p2,n,n)

    parent1 = parent1'
    parent2 = parent2'

    rowIndex = n-2
    #rowIndex = perm[1]

    if first(rand()) > 0.5
      for i in 1:rowIndex
        offspring1[i,:] = parent1[i,:]
        offspring2[i,:] = parent2[i,:]
      end

      for i in rowIndex+1:n
        offspring1[i,:] = parent2[i,:]
        offspring2[i,:] = parent1[i,:]
      end
    else
      for i in 1:rowIndex
        offspring1[:,i] = parent1[:,i]
        offspring2[:,i] = parent2[:,i]
      end

      for i in rowIndex+1:n
        offspring1[:,i] = parent2[:,i]
        offspring2[:,i] = parent1[:,i]
      end
    
    end


    offspring = Array{Int64,2}(undef, 2, n*n)    

    offspring[1,:] = refinement(flatten(offspring1'), n, cont)
    offspring[2,:] = refinement(flatten(offspring2'), n, cont)
    #offspring[1,:] = flatten(offspring1')
    #offspring[2,:] = flatten(offspring2')

    return offspring
    
end

################################ FITNESS #####################################

"""
Argument:
ind: individual whose fitness will be evaluated
cont: visibility constraints, matrix 4 x n

return:
fit: value that represents an individual's fitness. Better solutions have fitness that are closest to 20

"""
function fitness(ind, cont)
    n = size(cont, 2)

    if size(ind, 1) == 1
      ind = ind'
    end
    if size(ind, 2) == 1
      ind = reshape(ind, n, n)
      ind = ind'
    end
    fit = Int64(0)
    i  = Int64(0)
    direction = Int64(0)

    directionRespectee = zeros(Int64, 1, 5)
    respectBoth = false
    for direction in 1:4
        for i in 1:n
            if nbvisible(ind, i, direction) == cont[direction,i]
              fit += 1
            end    
        end
    end

    numberOfDoubles = 0
    for i in 1:n
      numberOfDoubles += countDoubles(ind[i,:]')
      numberOfDoubles += countDoubles(ind[:,i]')
    end

    if fit-numberOfDoubles < 0
      return 0
    else
      return fit - numberOfDoubles
    end
end

################################ SORT BY FIT #####################################

"""
Sort the population by each individual fitness
Argument:
pop: population, k x n matrix
cont: constraints matrix

return:
fitArray: array containing each individual fitness, sorted from greatest to smaller. Ex: the best individual is pop[fitArray[1]]
fitIndex: array containing the idex of individuals
"""
function sortByFitness(pop, cont)
    n = size(pop,2)
    k = size(pop,1)
    n = sqrt(n)
    n = convert(Int32, n)
    fitArray = Array{Int32}(undef, k)
    
    for i in 1:k
      ind = pop[i,:]
      ind = reshape(ind, n,n)
      ind = ind'
      fitArray[i] = fitness( ind, cont )  
    end

    fitIndex = sortperm(fitArray, rev=true)

    return fitArray, fitIndex
end


################################ GA #####################################
"""
Genetic Algorithm
"""
function GA(n, k, cont)
    pop = generatePopulation(n,k)
    found = false
    ind = []
    maxIter = 0
    currentBestFit = 0
    contPlateau = 0

    while(!found && maxIter < 20000)
      println(maxIter)

      fit, indexFit = sortByFitness(pop, cont)

      bestInd = pop[indexFit[1], :]
      bestInd = bestInd'
      ind = bestInd
      currentBestFit = fit[indexFit[1]]
      println(currentBestFit)
      if fit[indexFit[1]] == n*4
        found = true
        ind = pop[indexFit[1],:]
      end
      
      offspring = Array{Int64, 2}(undef, Int64(k/2), n*n)

      #shuffle the best ones so 2 parents are not together twice in a roll
      last = Int64(k/2)
      bestOnes = indexFit[1:last]
      bestOnes = shuffle(bestOnes)

      for i in 1:2:k/2
        j = Int64(i)
        #kids = recombination(pop[indexFit[j],:]', pop[indexFit[j+1],:]', cont, n)
        kids = recombination(pop[bestOnes[j],:]', pop[bestOnes[j+1],:]', cont, n)
        kid1 = kids[1,:]'
        kid2 = kids[2,:]'
        offspring[j,:] = kid1
        offspring[j+1,:] = kid2
      end

      p = 0.9
      if first(rand(1)) < p
        for i in 1:k/2
          j = Int64(i)
          offspring[j,:] = mutation(offspring[j,:], n)
          #offspring[j,:] = mutation2(offspring[j,:], n)
        end
      end

      if first(rand(1)) < p
        for i in 1:k/2
          j = Int64(i)
          offspring[j,:] = mutation2(offspring[j,:], n)
        end
      end

      p = p - 0.001

      p2 = 0.4
      if first(rand(1)) < p2
        for i in 1:k/2
          j = Int64(i)
          offspring[j,:] = mutation3(offspring[j,:], n, cont)
        end
      end

      if first(rand(1)) < p2
        for i in 1:k/2
          j = Int64(i)
          if fitness(offspring[j,:], cont) >= n*4 - 3
            offspring[j,:] = mutation4(offspring[j,:], n, cont)
          end
        end
      end
      p2 = p2 + 0.01
      
      newPop = [pop; offspring]
    
      fit, indexFit = sortByFitness(newPop, cont)

      for i in 1:k
        pop[i,:] = newPop[indexFit[i],:]
      end

      #for i in 1:k/2
      #  j = Int64(i)
      #  pop[indexFit[k-j+1], :] = offspring[j,:];
      #end

      maxIter += 1
    end

    println(fitness(ind, cont))
    return pop, ind


end

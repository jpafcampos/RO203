# This file contains methods to generate a data set of instances (i.e., sudoku grids)
include("io.jl")
using Random

function roll(arr, step)
  return vcat(arr[end-step+1:end], arr[1:end-step])'
end

############################ GENERATE FILLED GRID ##############################

function generateRandomInd(n) 
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
  println(individual)

  return individual


end

############################ GENERATEINSTANCE ##################################

"""
Generate an n*n grid with a given density

Argument
- n: size of the grid
"""

function generateInstance(n)

  matrix = generateRandomInd(n)
  t = zeros(Int64, 4 , n)

  for i in 1:4
    for j in 1:n
      t[i,j] = nbvisible(matrix, j, i)
    end
  end
  
  return t
end #end fct



################################# VISIBLE ######################################
"""
Test if cell (l, c) can be assigned value v

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
      if visible(x,i,k,1)
        v += 1
      end
    end
  elseif direction == 2
    for i in 1:n
      if visible(x,k,i,2)
        v += 1
      end
    end
  elseif direction == 3
    for i in 1:n
      if visible(x,i,k,3)
        v += 1
      end
    end
  elseif direction == 4
    for i in 1:n
      if visible(x,k,i,4)
        v += 1
      end
    end
  end
  return v
end

############################ GENERATEDATASET ###################################

"""
Generate all the instances

Remark: a grid is generated only if the corresponding output file does not already exist

"""

function generateDataSet()

    # For each grid size considered
    for size in [5, 6, 8, 10]
        ind = generateInstance(size)
        # Generate 10 instances
        for instance in 1:10

            fileName = "data/instance_n" * string(size) * "_" * string(instance) * ".txt"

            if !isfile(fileName)
                println("-- Generating file " * fileName)
                saveInstance(generateInstance(ind), fileName) 
            end
        end
    end
end

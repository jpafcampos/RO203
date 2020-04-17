# This file contains methods to generate a data set of instances (i.e., sudoku grids)
include("io.jl")
include("resolution.jl")



############################ GENERATEINSTANCE ##################################

"""
Generate an n*n grid with a given density

Argument
- n: size of the grid
"""

function generateInstance(n::Int64)

  # True if the current grid has no conflicts
  # (i.e., not twice the same value on a line, column or block)
  isGridValid = false

  t = []

  # While a valid grid is not obtained
  while !isGridValid
    t = Int64.(zeros(4, n)) #constraints
    isGridValid = true

    count = 0
    l = 1
    c = 1

    while isGridValid && count < 4*n
      v = ceil.(Int, n * rand())






    for l in 1:4
      for c in 1:n
        while t[l,c] == 0
          isGridValid = false
          while !isGridValid
            isGridValid = true

            # Randomly select a cell and a value
            v = ceil.(Int, n * rand())

            #constraints angles

            if (c == 1 && l == 2) && t[1,n] == 1
              v = 1
            elseif (c == n && l == 3) && t[2,n] == 1
              v = 1
            elseif (c == n && l == 4) && t[3,1] == 1
              v = 1
            elseif (c == 1 && l == 4) && t[1,1] == 1
              v = 1
            end  #end if

            #more than one 1 or n is impossible in each line of t
            if v == 1 && 1 in t
              isGridValid = false
            elseif v == n && n in t
              isGridValid = false
            elseif v == n && !(n in t)
              ll = rem(l+2,4)
              if ll == 0
                ll = 4
              end
              t[ll,c] = 1

            #angles cases
            elseif v == 1 && (l == 2 && c == 1)
              if t[1,n] != v
                isGridValid = false
              end #end if
            elseif v == 1 && (l == 3 && c == n)
              if t[2,n] != v
                isGridValid = false
              end #end if
            elseif v == 1 && (l == 3 && c == 1)
              if t[4,n] != v
                isGridValid = false
              end #end if
            end #end if

            t[l,c] = v

          end #end while
        end #end if
      end # end for c
    end #end for l
    return t
end #end fct



################################# ISVALID ######################################

"""
Test if cell (l, c) can be assigned value v

Arguments
- t: array of size 4*n with values in [1, n]
- x: array of size n*n with values in [0, n] (0 if empty)
- l, c: considered cell
- v: value considered

Return: true if t[l, c] can be set to v; false otherwise
"""

function isValid(t::Array{Int64, 2}, x::Array{Int,2}, l::Int64, c::Int64, v::Int64)

    n = size(t, 2)
    valid = true

    # Test if v appears in column c
    l2 = 1

    while valid && l2 <= n
        if x[l2, c] == v
            valid = false
        end
        l2 += 1
    end

    # Test if v appears in line l
    c2 = 1

    while valid && c2 <= n
        if x[l, c2] == v
            valid = false
        end
        c2 += 1
    end

    # Test if v respect the visibility constraint define by t
    #CELLE LA NE MARCHE PAS
"""
    xcopy = copy(x)
    if x[l,c] == 0
      xcopy[l,c] = v
    else
      valid = false
    end

    #lines
    c3 = 1
    left = 0
    right = 0
    while valid && c3 <= n
      if visible(xcopy,l,c3,2)
        right += 1
      end
      if visible(xcopy,l,c3,4)
        left += 1
      end
      if t[4,l]<left || t[2,l]<right
        print(left)
        print(right)
        println("visible")
        valid = false
      end
      c3 += 1
    end

    #column
    l3 = 1
    up = 0
    down = 0
    println("v =", v)
    while valid && l3 <= n
      if visible(xcopy,l3,c,1)
        up += 1
        println(up, " up/line ", l3)
      end
      if visible(xcopy,l3,c,3)
        down += 1
        println(down, " down/line ", l3)
      end
      if t[1,c]<up || t[3,c]<down
        println("visible")
        valid = false
      end
      l3 += 1
    end
"""
    return valid
end

################################# VISIBLE ######################################
"""
Test if cell (l, c) can be assigned value v

Arguments
- x: array of size n*n with values in [0, n] (0 if empty)
- l, c: Int64, line and column
- direction: Int64 (1=up, 2=right, 3=down, 4=left)

Return: true the tower is visible in this direction
"""

function visible(x::Array{Int,2}, l::Int64, c::Int64, direction::Int64)
  n= size(x,1)
  bool = true
  if x[l,c] == 0
    bool = false
  elseif direction == 1 #up
    for i in 2:l
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
    for i in 2:c
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

function nbvisible (x::Array{Int,2}, k::Int64, direction::Int64)
  n= size(x,1)
  v = 0
  if d == 1
    for i in 1:n
      if visible(x, i,k,1)
        v += 1
      end
    end
  end
  elseif d == 2
    for i in 1:n
      if visible(x, k,i,2)
        v += 1
      end
    end
  end
  elseif d == 3
    for i in 1:n
      if visible(x, i,k,3)
        v += 1
      end
    end
  end
  elseif d == 4
    for i in 1:n
      if visible(x, k,i,4)
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

        # Generate 10 instances
        for instance in 1:10

            fileName = "../data/instance_n" * string(size) * "_" * string(instance) * ".txt"

            if !isfile(fileName)
                println("-- Generating file " * fileName)
                saveInstance(generateInstance(size), fileName)
            end
        end
    end
end

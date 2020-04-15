# This file contains methods to generate a data set of instances (i.e., sudoku grids)
include("io.jl")



############################ GENERATEINSTANCE ##################################

"""
Generate an n*n grid with a given density

Argument
- n: size of the grid
- density: percentage in [0, 1] of initial values in the grid
"""
function generateInstance(n::Int64, density::Float64)

    # TODO
    println("In file generation.jl, in method generateInstance(), TODO: generate an instance")

end

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
            isValid = false
        end
        c2 += 1
    end

    # Test if v respect the visibility constraint define by t
    xcopy = copy(x)
    xcopy[l,c] = v

    #lines
    c3 = 1
    left = 1
    right = 1
    while valid && c3 <= n
      println(c3, "  ")
      if visible(xcopy,l,c3,2)
        right += 1
      elseif visible(xcopy,l,c3,4)
        left += 1
      end
      if t[4,l]<left || t[2,l]<right
        valid = false
      end
      c3 += 1
    end

    #column
    l3 = 1
    up = 1
    down = 1
    while valid && l3 <= n
      if visible(xcopy,l3,c,2)
        right += 1
      elseif visible(xcopy,l3,c,4)
        left += 1
      end
      if t[1,c]<up || t[3,c]<down
        valid = false
      end
      l3 += 1
    end

    return valid
end

################################# visible ######################################
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
  if direction == 1 #up
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
  elseif direction == 4 #
    for i in 2:c
      if x[l,i]>x[l,c]
        bool = false
      end
    end
  end
  return bool
end

############################ GENERATEDATASET ###################################

"""
Generate all the instances

Remark: a grid is generated only if the corresponding output file does not already exist

"""
function generateDataSet()

    # TODO
    println("In file generation.jl, in method generateDataSet(), TODO: generate an instance")

end

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
    isValid = true

    # Test if v appears in column c
    l2 = 1

    while isValid && l2 <= n
        if t[l2, c] == v
            isValid = false
        end
        l2 += 1
    end

    # Test if v appears in line l
    c2 = 1

    while isValid && c2 <= n
        if t[l, c2] == v
            isValid = false
        end
        c2 += 1
    end

    # Test if v respect the visibility constraint define by t
    xcopy = copy(x)
    xcopy[l,c] = v

    #lines
    l = 1
    while isValid && l <= n
      left = 1
      right = 1
      for c in 1:n
        if visible(xcopy,l,c,2)
          right += 1
        elseif visible(xcopy,l,c,4)
          left += 1
        end
      end
      if t[4,l]>left || t[2,l]>right
        isValid = false
      end
      l += 1
    end

    #column
    c = 1
    while isValid && c <= n
      up = 1
      down = 1
      for l in 1:n
        if visible(xcopy,l,c,3)
          down += 1
        elseif visible(xcopy,l,c,1)
          up += 1
        end
      end
      if t[1,c]>up || t[3,c]>down
        isValid = false
      end
      c += 1
    end

    return isValid
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

function(x::Array{Int,2}, l::Int64, c::Int64, direction::Int64)
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

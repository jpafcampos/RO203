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
    #lines
    l = 1
    while isValid && l <= n
      left = 1
      right = 1
      mleft = x[l,1]
      mright = x[l,n]
      for i in 2:n
        if x[l,i]>mleft
          mleft = x[l,i]
          left += 1
        end
        if x[l,n-i+1]>right
          mright = x[l,n-i+1]
          right += 1
        end
      end
      if t[4,l]<left || t[2,l]<right
        isValid = false
      end
      l += 1
    end

    #columns
    c = 1
    while isValid && c <= n
      up = 1
      down = 1
      mup = x[1,c]
      mdown = x[n,c]
      for i in 2:n
        if x[i,c]>mup
          mup = x[i,c]
          up += 1
        end
        if x[n-i+1,c]>down
          mdown = x[n-i+1,c]
          down += 1
        end
      end
      if t[1,c]<up || t[3,c]<down
        isValid = false
      end
      c += 1
    end

    return isValid
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

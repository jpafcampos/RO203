# This file contains methods to generate a data set of instances (i.e., sudoku grids)
include("io.jl")



############################ GENERATEINSTANCE ##################################

"""
Generate an n*n grid with a given density

Argument
- n: size of the grid
"""
function generateInstance(n::Int64, density::Float64)

    # TODO
    println("In file generation.jl, in method generateInstance(), TODO: generate an instance")

end
"""
function generateInstance(n::Int64)

    # True if the current grid has no conflicts
    # (i.e., not twice the same value on a line, column or block)
    isGridValid = false

    t = []

    # While a valid grid is not obtained
    while !isGridValid

        isGridValid = true

        t = zeros(4, n) #constraints
        x = zeros(n, n) #grid
        i = 1

        # While the grid is valid and the required number of cells is not filled
        while isGridValid && i < 4*n

            # Randomly select a cell and a value
            l = ceil.(Int, 4 * rand())
            c = ceil.(Int, n * rand())
            v = ceil.(Int, n * rand())

            # True if a value has already been assigned to the cell (l, c)
            isFree = t[l, c] == 0

            # True if value v can be set in cell (l, c)
            isValueValid = isValid(t, x, l, c, v)

            # Number of value that we already tried to assign to cell (l, c)
            attemptCount = 0

            # Number of cells considered in the grid
            testedCells = 1

            # While is it not possible to assign the value to the cell
            # (we assign a value if the cell is free and the value is valid)
            # and while all the cells have not been considered
            while !(isCellFree && isValueValid) && testedCells < n*n

                # If the cell has already been assigned a number or if all the values have been tested for this cell
                if !isCellFree || attemptCount == n

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

                    testedCells += 1
                    isCellFree = t[l, c] == 0
                    isValueValid = isValid(t, l, c, v)
                    attemptCount = 0

                    # If the cell has not already been assigned a value and all the value have not all been tested
                else
                    attemptCount += 1
                    v = rem(v, n) + 1
                end
            end

            if testedCells == n*n
                isGridValid = false
            else
                t[l, c] = v
            end

            i += 1
        end
    end

    return t

end

"""


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

"""

function generateDataSet()

    # For each grid size considered
    for size in 4:6[4, 9, 16, 25]

        # For each grid density considered
        for density in 0.1:0.2:0.3

            # Generate 10 instances
            for instance in 1:10

                fileName = "../data/instance_t" * string(size) * "_d" * string(density) * "_" * string(instance) * ".txt"

                if !isfile(fileName)
                    println("-- Generating file " * fileName)
                    saveInstance(generateInstance(size, density), fileName)
                end
            end
        end
    end
end
"""

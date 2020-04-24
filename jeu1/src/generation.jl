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

    count = 4
    l = 1
    c = 1
    cont1 = false
    cont2 = false
      
    #one 1 by line
    for i in 1:4
      un = ceil.(Int, n * rand())
      #constraints angles
      if i == 2 
        if t[1,n] == 1
          un = 1
        elseif t[1,n] == 0 && un == 1
          isGridValid = false
        end  #end i
      elseif i == 3 
        if t[2,n] == 1
          un =n
        elseif t[2,n] == 0 && un == n
          isGridValid = false
        end  #end i
      elseif i == 4 && t[3,1] == 1
        un = n
        cont1 = true
      elseif i == 4 && t[1,1] == 1
        un = 1
        cont2 = true
      elseif i == 4 && t[3,1] == 0 && un == n
        isGridValid = false
      elseif i == 4 && t[1,1] == 0 && un == 1
        isGridValid = false
      end  #end if
      if t[i, 1] == 1 && t[i, 3] == 1
        isGridValid = false
      elseif t[i, 2] == 1 && t[i, 4] == 1
        isGridValid = false
      end
      t[i,un] = 1
    end #end for
    
    #impossible : need two 1 in one line
    if cont1 && cont2
      isGridValid = false
    end
      
    isValueValid = true
    aux = ceil.(Int64, (n-1) * rand()) + 1
    testedvalue = 1

    while isGridValid && count < 4*n
      #one already choose
      v = aux

      if isValueValid
        v = ceil.(Int64, (n-1) * rand()) + 1
        testedvalue = 1
      end

      # True if a value has already been assigned to the cell (l, c)
      isCellFree = t[l, c] == 0
      isValueValid = true

      #opposite direction
      ll = rem(l+2,4)
      if ll == 0
        ll = 4
      end


      #more than one n is impossible in each line of t
      if v == n && n in t
        isValueValid = false

      # if constraint equals n the opposite is 1
      elseif v == n && !(n in t) 
        if t[ll,c] > 1 #no 5 if no 1 at the opposite
          if t[ll,c] == 0
            t[ll,c] = 1
            count += 1
          else
            isValueValid = false
          end
        end
      end

      #sum of opposite constraints czn not exceed n+1
      if v + t[ll,c] > n+1
        isValueValid = false
      end

      #constraints impossible (occurances)
      nbvalue = 0
      for i in 1:n
        if t[l,i] == v
          nbvalue += 1
        end
      end

      #count(i->(i==v),t[l,:])
      if nbvalue == (n-v)
        isValueValid = false
      end

      if !(isValueValid) && testedvalue < (n-1)
        if v == 2
          aux = n
        else
          aux = rem(v-1, n)
        end
        testedvalue += 1
      end

      if testedvalue == n-1
        isGridValid = false
      end

      if isValueValid && isCellFree
        t[l,c] = v
        count += 1
      end

      #if value assign go to next cell
      if isValueValid
        if c < n
          c += 1
        else
          if l < 4
            l += 1
            c = 1
          end
        end
      end
    end # end while

    if count == 4*n
      isGridValid = true
    end
  end #end while

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

function visible(x::Array{Int,2}, l::Int64, c::Int64, direction::Int64)
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

function nbvisible(x::Array{Int,2}, k::Int64, direction::Int64)
  n= size(x,1)
  v = 0
  if d == 1
    for i in 1:n
      if visible(x,i,k,1)
        v += 1
      end
    end
  elseif d == 2
    for i in 1:n
      if visible(x,k,i,2)
        v += 1
      end
    end
  elseif d == 3
    for i in 1:n
      if visible(x,i,k,3)
        v += 1
      end
    end
  elseif d == 4
    for i in 1:n
      if visible(x,k,i,4)
        v += 1
      end
    end
  end
  return v
end


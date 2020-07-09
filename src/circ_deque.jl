mutable struct CircularDeque{T}
    buffer::Vector{T}
    capacity::Int
    n::Int
    first::Int
    last::Int
end

"""
    CircularDeque{T}(n)

Create a double-ended queue of maximum capacity `n`, implemented as a circular buffer. The element type is `T`.
"""
CircularDeque{T}(n::Int) where {T} = CircularDeque(Vector{T}(undef, n), n, 0, 1, n)

Base.length(D::CircularDeque) = D.n
Base.eltype(::Type{CircularDeque{T}}) where {T} = T

"""
    capacity(D::CircularDeque)

Return the capacity of the circular deque
"""
capacity(D::CircularDeque) = D.capacity

function Base.empty!(D::CircularDeque)
    D.n = 0
    D.first = 1
    D.last = D.capacity
    return D
end

Base.isempty(D::CircularDeque) = D.n == 0

"""
    first(D::CircularDeque)

Get the item at the front of the queue.
"""
@inline function first(D::CircularDeque)
    @boundscheck isempty(D) && Base.throw_boundserror(D, 1)
    @inbounds return D.buffer[D.first]
end

"""
    last(D::CircularDeque)

Get the item from the back of the queue.
"""
@inline function last(D::CircularDeque)
    @boundscheck isempty(D) && Base.throw_boundserror(D, 1)
    @inbounds return D.buffer[D.last]
end

@inline function Base.push!(D::CircularDeque, v)
    @boundscheck D.n < D.capacity || Base.throw_boundserror(D, D.n + 1)  # prevent overflow
    D.last = (D.last == D.capacity ? 1 : D.last + 1)
    D.n += 1
    @inbounds D.buffer[D.last] = v
    return D
end

Base.@propagate_inbounds function Base.pop!(D::CircularDeque)
    v = last(D)
    D.n -= 1
    D.last = (D.last == 1 ? D.capacity : D.last - 1)
    return v
end

"""
    pushfirst!(D::CircularDeque, v)

Add an element to the front.
"""
@inline function pushfirst!(D::CircularDeque, v)
    @boundscheck D.n < D.capacity || Base.throw_boundserror(D, 0)
    D.first = (D.first == 1 ? D.capacity : D.first - 1)
    D.n += 1
    @inbounds D.buffer[D.first] = v
    return D
end

"""
    popfirst!(D::CircularDeque)

Remove the element at the front.
"""
Base.@propagate_inbounds function popfirst!(D::CircularDeque)
    v = first(D)
    D.n -= 1
    D.first = (D.first == D.capacity ? 1 : D.first + 1)
    return v
end

@inline function Base.getindex(D::CircularDeque, i::Integer)
    @boundscheck 1 <= i <= D.n || Base.throw_boundserror(D, i)
    cap = D.capacity
    j = D.first + i - 1
    k = (j > cap ? j - cap : j)
    @inbounds return D.buffer[k]
end

# Iteration via getindex
@inline function iterate(D::CircularDeque, i=1)
    @inbounds return i == D.n + 1 ? nothing : (D[i], i + 1)
end

@inline function iterate(R::Iterators.Reverse{<:CircularDeque}, i=length(R))
    @inbounds return i == 0 ? nothing : (R.itr[i], i - 1)
end

# Necessary for compatibility with Julia 1.0, which uses lastindex instead of
# Iterators.Reverse in foldr. Also useful in general.
lastindex(D::CircularDeque) = D.n

function Base.show(io::IO, D::CircularDeque{T}) where T
    print(io, "CircularDeque{$T}([")
    for i = 1:length(D)
        print(io, D[i])
        i < length(D) && print(io, ',')
    end
    print(io, "])")
end

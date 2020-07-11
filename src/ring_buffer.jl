mutable struct RingBuffer{T,C} <: AbstractVector{T}
    first::UInt
    last::UInt
    buffer::Vector{T}

    function RingBuffer{T}(n) where {T}
        ispow2(n) || throw(ArgumentError("capacity must be a power of 2"))
        return new{T,UInt(n)}(-1 % UInt, -1 % UInt, Vector{T}(undef, n))
    end
end

Base.IndexStyle(::Type{<:RingBuffer}) = IndexLinear()
Base.size(rb::RingBuffer) = ((rb.last - rb.first) % Int,)
Base.empty!(rb::RingBuffer) = (rb.first = rb.last = -1 % UInt)

capacity(::RingBuffer{T,C}) where {T,C} = C % Int
isfull(rb::RingBuffer) = length(rb) == capacity(rb)

# Faster than the generic lastindex.
Base.lastindex(rb::RingBuffer) = length(rb)

# These `first` and `last` methods allow bounds checking to be elided via `@inbounds`,
# whereas the generic ones for AbstractArray do not.
Base.@propagate_inbounds Base.first(rb::RingBuffer) = rb[1]
Base.@propagate_inbounds Base.last(rb::RingBuffer) = rb[end]

_wrap_index(::RingBuffer{T,C}, i::UInt) where {T,C} = (i % C + 1) % Int

@inline function _to_buffer_index(rb::RingBuffer, i)
    @boundscheck checkbounds(rb, i)
    return _wrap_index(rb, rb.first + i % UInt)
end

Base.@propagate_inbounds function Base.getindex(rb::RingBuffer, i)
    j = _to_buffer_index(rb, i)
    @inbounds return rb.buffer[j]
end

Base.@propagate_inbounds function Base.setindex!(rb::RingBuffer, item, i)
    j = _to_buffer_index(rb, i)
    @inbounds return rb.buffer[j] = item
end

Base.@propagate_inbounds Base.push!(rb::RingBuffer, item) = _push!(rb, Val(false), item)
Base.@propagate_inbounds force_push!(rb::RingBuffer, item) = _push!(rb, Val(true), item)

Base.@propagate_inbounds Base.pushfirst!(rb::RingBuffer, item) = _pushfirst!(rb, Val(false), item)
Base.@propagate_inbounds force_pushfirst!(rb::RingBuffer, item) = _pushfirst!(rb, Val(true), item)

@inline function _push!(rb::RingBuffer, ::Val{overwrite}, item) where {overwrite}
    @boundscheck overwrite || !isfull(rb) || Base.throw_boundserror(rb, length(rb) + 1)
    overwrite && isfull(rb) && (rb.first += 1)
    rb.last += 1
    @inbounds return rb[end] = item
end

@inline function _pushfirst!(rb::RingBuffer, ::Val{overwrite}, item) where {overwrite}
    @boundscheck overwrite || !isfull(rb) || Base.throw_boundserror(rb, 0)
    overwrite && isfull(rb) && (rb.last -= 1)
    rb.first -= 1
    @inbounds return rb[1] = item
end

Base.@propagate_inbounds function Base.pop!(rb::RingBuffer)
    out = last(rb)
    rb.last += 1
    return out
end

Base.@propagate_inbounds function Base.popfirst!(rb::RingBuffer)
    out = first(rb)
    rb.first += 1
    return out
end

module BenchRingBuffer

using DataStructures
using BenchmarkTools
using Random

const SUITE = BenchmarkGroup()
const CAPS = [1024, 1024^2]

# Empirically, 1 second is sufficient for consistent timings here.
BenchmarkTools.DEFAULT_PARAMETERS.seconds = 1

function init_rb(a)
    len = length(a)
    rb = RingBuffer{Int}(len)
    rb.first = rb.last -= div(len, 2)
    for x in a
        push!(rb, x)
    end
    return rb
end

function perf_chained_getindex(rb)
    i = 1
    for k = 1:capacity(rb)
        i = rb[i]
    end
    return i
end

function perf_first(rb)
    cap = capacity(rb)
    rb.first = rb.last - cap
    total = 0
    for i = 1:cap
        total += first(rb)
        rb.first += 1
    end
    return total
end

function perf_last(rb)
    cap = capacity(rb)
    rb.last = rb.first + cap
    total = 0
    for i = 1:cap
        total += last(rb)
        rb.last -= 1
    end
    return total
end

g = addgroup!(SUITE, "access")

# Creating a new copy for each sample seems to eliminate an unknown but substantial source
# of timing variation on some machines. This is why each benchmark has `setup=(rb = deepcopy($rb))`.
for cap in CAPS
    Random.seed!(0)
    rb = init_rb(randcycle(cap))

    g["chained_getindex", cap] = @benchmarkable perf_chained_getindex(rb) setup=(rb = deepcopy($rb))

    g["sum", cap] = @benchmarkable sum(rb) setup=(rb = deepcopy($rb))
    g["foldl", cap] = @benchmarkable foldl(+, rb) setup=(rb = deepcopy($rb))
    g["foldr", cap] = @benchmarkable foldr(+, rb) setup=(rb = deepcopy($rb))

    g["first", cap] = @benchmarkable perf_first(rb) setup=(rb = deepcopy($rb))
    g["last", cap] = @benchmarkable perf_last(rb) setup=(rb = deepcopy($rb))

    g["convert", cap] = @benchmarkable convert(Array, rb) setup=(rb = deepcopy($rb))
end

function perf_setindex!(rb, indices)
    for i in indices
        rb[i] = i
    end
    return rb
end

function perf_force_push!(rb)
    for i = 1:capacity(rb)
        force_push!(rb, i)
    end
    return rb
end

function perf_force_pushfirst!(rb)
    for i = 1:capacity(rb)
        force_pushfirst!(rb, i)
    end
    return rb
end

g = addgroup!(SUITE, "mutate")

for cap in CAPS
    rb = init_rb(-1:-1:-cap)

    Random.seed!(0)
    g["random_setindex!", cap] = @benchmarkable perf_setindex!(rb, $(randperm(cap))) setup=(rb = deepcopy($rb))
    g["forward_setindex!", cap] = @benchmarkable perf_setindex!(rb, 1:$cap) setup=(rb = deepcopy($rb))
    g["reverse_setindex!", cap] = @benchmarkable perf_setindex!(rb, $cap:-1:1) setup=(rb = deepcopy($rb))

    g["full_push!", cap] = @benchmarkable perf_force_push!(rb) setup=(rb = deepcopy($rb))
    g["full_pushfirst!", cap] = @benchmarkable perf_force_pushfirst!(rb) setup=(rb = deepcopy($rb))
end

function perf_empty_push!(rb)
    rb.last = rb.first
    for i = 1:capacity(rb)
        push!(rb, i)
    end
    return rb
end

function perf_empty_pushfirst!(rb)
    rb.first = rb.last
    for i = 1:capacity(rb)
        pushfirst!(rb, i)
    end
    return rb
end

function perf_pop!(rb)
    cap = capacity(rb)
    rb.last = rb.first + cap
    total = 0
    for i = 1:cap
        total += pop!(rb)
    end
    return total
end

function perf_popfirst!(rb)
    cap = capacity(rb)
    rb.first = rb.last - cap
    total = 0
    for i = 1:cap
        total += popfirst!(rb)
    end
    return total
end

for cap in CAPS
    rb = init_rb(-1:-1:-cap)
    g["empty_push!", cap] = @benchmarkable perf_empty_push!(rb) setup=(rb = deepcopy($rb))
    g["empty_pushfirst!", cap] = @benchmarkable perf_empty_pushfirst!(rb) setup=(rb = deepcopy($rb))
    g["pop!", cap] = @benchmarkable perf_pop!(rb) setup=(rb = deepcopy($rb))
    g["popfirst!", cap] = @benchmarkable perf_popfirst!(rb) setup=(rb = deepcopy($rb))
end

end  # module BenchRingBuffer

if @isdefined(SUITE)
    BenchRingBuffer.SUITE
else
    # This `else` branch allows this file to be called directly by PkgBenchmark via the
    # `script` keyword in `PkgBenchmark.benchmarkpkg`.
    using BenchmarkTools
    const SUITE = BenchmarkGroup()
    SUITE["RingBuffer"] = BenchRingBuffer.SUITE
end

module BenchCircularDeque

using DataStructures
using BenchmarkTools
using Random

const SUITE = BenchmarkGroup()
const CAPS = [1024, 1024^2]

BenchmarkTools.DEFAULT_PARAMETERS.seconds = 1

function init_cd(a)
    len = length(a)
    cd = CircularDeque{Int}(len)
    cd.first = 1 + div(len, 2)
    len > 1 && (cd.last = cd.first - 1)
    for x in a
        push!(cd, x)
    end
    return cd
end

function perf_chained_getindex(cd)
    i = 1
    for k = 1:capacity(cd)
        i = cd[i]
    end
    return i
end

function perf_first(cd)
    cd.n = 1
    total = 0
    for i = 1:capacity(cd)
        cd.first = cd.last = i
        total += first(cd)
    end
    return total
end

function perf_last(cd)
    cd.n = 1
    total = 0
    for i = 1:capacity(cd)
        cd.first = cd.last = i
        total += last(cd)
    end
    return total
end

g = addgroup!(SUITE, "access")

# Creating a new copy for each sample seems to eliminate an unknown but substantial source
# of timing variation on some machines. This is why each benchmark has `setup=(cd = deepcopy($cd))`.
for cap in CAPS
    Random.seed!(0)
    cd = init_cd(randcycle(cap))

    g["chained_getindex", cap] = @benchmarkable perf_chained_getindex(cd) setup=(cd = deepcopy($cd))

    g["sum", cap] = @benchmarkable sum(cd) setup=(cd = deepcopy($cd))
    g["foldl", cap] = @benchmarkable foldl(+, cd) setup=(cd = deepcopy($cd))
    g["foldr", cap] = @benchmarkable foldr(+, cd) setup=(cd = deepcopy($cd))

    g["first", cap] = @benchmarkable perf_first(cd) setup=(cd = deepcopy($cd))
    g["last", cap] = @benchmarkable perf_last(cd) setup=(cd = deepcopy($cd))
end

# The following assume that cd is either full or empty.

function perf_push!(cd)
    cd.n = 0
    for i = 1:capacity(cd)
        push!(cd, i)
    end
    return cd
end

function perf_pushfirst!(cd)
    cd.n = 0
    for i = 1:capacity(cd)
        pushfirst!(cd, i)
    end
    return cd
end

function perf_pop!(cb)
    cap = capacity(cb)
    cb.n = cap
    total = 0
    for i = 1:cap
        total += pop!(cb)
    end
    return total
end

function perf_popfirst!(cb)
    cap = capacity(cb)
    cb.n = cap
    total = 0
    for i = 1:cap
        total += popfirst!(cb)
    end
    return total
end

g = addgroup!(SUITE, "mutate")

for cap in CAPS
    cd = init_cd(-1:-1:-cap)

    g["push!", cap] = @benchmarkable perf_push!(cd) setup=(cd = deepcopy($cd))
    g["pushfirst!", cap] = @benchmarkable perf_pushfirst!(cd) setup=(cd = deepcopy($cd))

    g["pop!", cap] = @benchmarkable perf_pop!(cd) setup=(cd = deepcopy($cd))
    g["popfirst!", cap] = @benchmarkable perf_popfirst!(cd) setup=(cd = deepcopy($cd))
end

end  # module BenchCircularDeque

if @isdefined(SUITE)
    BenchCircularDeque.SUITE
else
    # This `else` branch allows this file to be called directly by PkgBenchmark via the
    # `script` keyword in `PkgBenchmark.benchmarkpkg`.
    using BenchmarkTools
    const SUITE = BenchmarkGroup()
    SUITE["CircularDeque"] = BenchCircularDeque.SUITE
end

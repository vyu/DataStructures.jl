using Pkg
tempdir = mktempdir()
Pkg.activate(tempdir)
Pkg.develop(PackageSpec(path=joinpath(@__DIR__, "..")))
Pkg.add(["BenchmarkTools", "PkgBenchmark", "Random"])
Pkg.resolve()

using DataStructures
using BenchmarkTools

const SUITE = BenchmarkGroup()

SUITE["CircularDeque"] = include("bench_circular_deque.jl")
SUITE["heap"] = include("bench_heap.jl")
SUITE["SparseIntSet"] = include("bench_sparse_int_set.jl")
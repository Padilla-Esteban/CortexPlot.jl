module CortexPlot

using Makie
using Makie.FileIO
using Printf
using Leadfields
using Xloreta
using MAT
using NPZ
using LinearAlgebra
using GeometryBasics
using MeshIO

# colors for printing messages
const titleFont = "\x1b[38;5;71m"
const separatorFont = "\x1b[38;5;113m"
const defaultFont = "\x1b[0m"
const greyFont = "\x1b[90m"

#Example data
const example_eeg = joinpath(abspath(@__DIR__, ".."), "Example Data", "synthetic_eeg.npz")



export 
cortex_dashboard,
cortex_plot

include("common.jl")
include("cortex3D.jl")
include("cortex3D_slice.jl")
include("cortex2D_8view.jl")
include("cortex3D_3slice.jl")
include("cortex2D_3view.jl")
include("cortexviewer.jl")

end
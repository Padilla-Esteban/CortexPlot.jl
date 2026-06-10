
**UNDER CONSTRUCTION**

![header](Documents/header.png) 

---

> [!TIP] 
> 🦅
> This package is part of the [Eegle.jl](https://github.com/Marco-Congedo/Eegle.jl) ecosystem for EEG data analysis and classification.

---

# CortexPlot

This package allows to visualize inverse solution functional data on on top of structural (cortex) data with Makie in [julia](https://julialang.org/). 


The **leadfield matrices** used in this package comes from [Leadfields.jl](https://github.com/Marco-Congedo/Leadfields.jl) and have been pre-computed via the [BrainStorm](https://neuroimage.usc.edu/brainstorm/Introduction) software by [OpenMEEG](https://openmeeg.github.io/) using the ‘fsaverage’ adult head model (FreeSurfer’s default template based on 40 normative brains). The computation of the leadfields is based on the Boundary Element Method (BEM).

> [!TIP] 
> The package uses two different meshes that can be found   
> [here](https://github.com/Marco-Congedo/Leadfields.jl/tree/master/Meshes).

The available meshes and leadfields correspond to:  
1) 7509 unconstrained brain dipolar sources (**2503 voxels** × 3 cartesian orientations); voxel size: 4.3mm
2) 15006 unconstrained brain dipolar sources (**5002 voxels** × 3 cartesian orientations); voxel size: 3mm


![separator](Documents/separator.png)

## 🧭 Index

- 📦 [Installation](#-installation)
- 🔣 [Problem Statement, Notation and Nomenclature](#-problem-statement-notation-and-nomenclature)
- 🔌 [API](#-api)
- 💡 [Examples](#-examples)
- ✍️ [About the Author](#️-about-the-author)
- 🌱 [Contribute](#-contribute)

![separator](Documents/separator.png)

## 📦 Installation

*julia* version 1.10+ is required.

Execute the following command in julia's REPL:

```julia
using Pkg
Pkg.add(CortexPlot)
```


[▲ index](#-index)

![separator](Documents/separator.png)

## 🔣 Problem Statement, Notation and Nomenclature
xxx
See the documentation of [Xloreta](https://github.com/Marco-Congedo/Xloreta.jl) and CortexPlot.jl first.

Referring to the problem statement, notation and nomenclature defined in the documentation of *Xloreta.jl* , this package allows to access:
- The leadfield matrix 𝐊 ∈ ℝⁿ×³ᵖ, where n is the number of electrodes and p is the number of voxels.
- The electrode labels
- the electrode locations in 3D cartesian coordinates
- the voxel locations in 3D cartesian coordinates.

The vector of voxel locations depends on the chosen leadfield, which can be computed for any collection of electrodes and with any electrical reference.

> [!WARNING] 
> Each label in the sought collection of electrodes must match one of the strings in this [list](https://github.com/Marco-Congedo/Leadfields.jl/blob/master/Documents/sensors343.txt) (in a case-insensitive fashion).

Referring the documentation of *CortexPlot.jl*, this package allows to generate and save .stl file for plotting
the inverse solution functional data on top of structural (cortex) images.

[▲ index](#-index)

![separator](Documents/separator.png)

## 🔌 API

The package exports only two functions:

```julia
function cortex_dashboard(data :: Union{Vector{Real}, Matrix{Real}};
                        voxels :: Int64 = 2503,
                        alpha :: Real = 1.0,
                        fontsize :: Real = 16.0
                        )
```

**Argument**

- `data`: a current density vector or matrix (J for example) containing the data the user wants to visualize.

**Optional Keyword Argument**
- `voxels`: the number of voxels p in the head model. It can be `2503` or `5002`. 
- `alpha`: the starting value of alpha for the display. 
- `fontsize`: the size of the plot's ticks. Its default value (16.0) is the Makie's default value.  

**Display**
Opens a window containing menus, sliders and buttons.
The first menu allows the user to switch between different display modes:
- `cortex3D`: the default display mode of the menu, which only displays the cortex in 3 dimensions
- `cortex3D_slice`:displays a slice of the cortex that can be moved along an axis with a 'Position' slider. The thickness of the slice can also be adjusted with a 'Thickness' slider. The axis followed by the slice can be changed by clicking the 3 buttons in the bottom. Keyboard controls: use the up or right arrow to move the slice towards greater position values and the down or left arrow to move the slice towards lower position values. Use the -/+ keys to change the thickness of the slab and use the x,y,z keys to change the axis followed by the slice.
- `cortex3D_3slice`: displays the same view than the cortex3D on the left of the screen. The user can then point his mouse cursor over the brain and click the s key, which will calculate the coordinates of the mouse cursor and display the slices crossing this coordinates along each axis. The same can be done by entering coordinates in the TextBoxes and click the 'Display' button. The 'Display max' button calculates the coordinates of the point where the current density is maximal and displays the slices crossing this coordinates along each axis.
- `cortex2D_8view`: displays 8 2D sectional views of the brain. 
- `cortex2D_3view`: displays 3 2D sectional views of the brain (one per axis). Each sectional view contains a slice of the cortex that can be moved with a 'Position' slider. Each slice thickness can be changed with a 'Thickness' slider too. 

Some controllers are common to all the display modes:
- `Time/frequency`: a slider that allows the user to move the EEG time/frequency. It is associated with a play/pause button that can be clicked to let the time advance automatically.
- `Alpha`: a slider that allows the user to change the alpha of all the plots.
- `Colorscale`: a slider that allows the user to modify the colorscale used to display the `data`. It takes the middle scale color and moves it to the value associated to the slider. The colorbar updates automatically when the slider is moved to let the user understand what he is changing.
- `Colormap`:   


> [!TIP] 
> If the leadfield is needed to compute an inverse solution by package [Xloreta](https://github.com/Marco-Congedo/Xloreta.jl), `labels` must hold the electrode labels for your data, in the same order used there, and `reference` must be 0.0 (default).

The following options are for advanced use of the Gedai.jl artifact rejection algorithm only (or if you know what you are doing):

1) If `reference` is equal to an electrode label (a string), the leadfield matrix is re-referenced to that electrode.
- case 1.1: `labels` is not provided:
    n = 343-1, since the elements of (a, b, c) corresponding to that electrode are removed.
- case 1.2: `labels` is provided:
    - 1.2.a: `reference` is in labels:
        n = length(labels)-1, since the elements of (a, b, c) corresponding to that electrode are removed.
    - 1.2.b: `reference` is not in labels:
        n = length(labels)

2) If `reference` is a real value, the leadfield matrix is re-referenced to the (common average reference + `reference`), thus if `reference` = 0.0 (default), it is referenced to the (rank-deficient) common average reference, and if `reference` = 1.0, it referenced to the full-rank pseudo common average reference used by default in the [Gedai](https://github.com/Marco-Congedo/Gedai) denoising algorithm.
See the [Eegle.car!](https://marco-congedo.github.io/Eegle.jl/stable/Processing/#Eegle.Processing.car!) function for explanations
on the common average reference.

[▲ index](#-index)

```julia
function gen_cortex_stl(savepath::String; voxels::Int = 2503)
```

Generate and save a .stl file for plotting the cortex in 2D or 3D using *Makie.jl* given the default brainstorm surface .mat file
generated for the given number of `voxels`. `voxels` can be 2503 (default) or 5002, which will create the .stl file
for the leadfield with 2503 or 5002 voxels, respectively. No .stl can be generated for the model with 1203 voxels.

`savepath` is the full path of the file where the .stl file will be saved.

[▲ index](#-index)

![separator](Documents/separator.png)

## 💡 Examples

**Example for computing inverse solutions**

```julia
using Leadfields
labels = ["FP1", "FP2", "F3", "F4", "C3", "C4", "P3", "P4", "O1", "O2"]
K, ename, eloc, gridloc = leadfield(labels) # default 2503-vector head model
```

- `K` is a 10×7509(2503x3) leadfield matrix referenced to the (rank-deficient) CAR, i.e., the usual CAR.
- `ename` is equal to `labels`
- `eloc` is a vector holding 10 vectors, each one with the 3D electrode cartesian coordinates
- `gridloc` is a vector holding 1210 vectors with the 3D voxels cartesian coordinates

For using the 5002-voxel model, use instead:
```julia
using Leadfields
labels = ["FP1", "FP2", "F3", "F4", "C3", "C4", "P3", "P4", "O1", "O2"]
K, ename, eloc, gridloc = leadfield(labels; voxels=5002) 
```

**Example for use with GEDAI denoising**

See the last example [here](https://github.com/Marco-Congedo/Gedai/tree/master?tab=readme-ov-file#-examples).


**Example for generating and saving .stl files**

```julia
using Leadfields
gen_cortex_stl(joinpath(homedir(), "cortex_2503.stl"))
```
This will generate the .stl file for the leadfield with 2503 voxels (default) and store it in the home directory.

To generate the .stl file for the leadfield with 5002 voxels, use instead:

```julia
using Leadfields
gen_cortex_stl(joinpath(homedir(), "cortex_5002.stl"); voxels = 5002)
```
[▲ index](#-index)

![separator](Documents/separator.png)

## ✍️ About the Author

[Marco Congedo](https://github.com/Marco-Congedo), Arthur Tatlian, Esteban Padilla and [Tomas Ros](https://github.com/neurotuning-personal).

[▲ index](#-index)

![separator](Documents/separator.png)

## 🌱 Contribute

Please contact the first author if you are interested in contributing.

[▲ index](#-index)
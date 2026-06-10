
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
function cortex_dashboard(data :: Union{Vector{A}, Matrix{A}};
                        voxels :: Int64 = 2503,
                        alpha :: Real = 1.0,
                        title :: String = "Brain activation",
                        colorbar_label :: String = "Current density module",
                        fontsize :: Real = 16.0
                        )where {A<:Real}
```

**Argument**

- `data`: a current density vector or matrix (J for example) containing the data the user wants to visualize.

**Optional Keyword Arguments**
- `voxels`: the number of voxels p in the head model. It can be `2503` or `5002`. 
- `alpha`: the starting value of alpha for the display. 
- `title`: sets the title of the plots. 
- `colorbar_label`: sets the title of the colorbars. 
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
- `Colormap`: a menu that allows the user to switch between different colormaps for the plots. The colormap list contains 4 options by default but can be changed by the user with the `colormap` argument.


> [!TIP] 
> In addition to all the interactions listed above, all the basic Makie interactions remain possible (see [here](https://docs.makie.org/stable/reference/blocks/axis3#Axis3-interactions) for 3D plots; and see [here](https://docs.makie.org/stable/reference/blocks/axis#Axis-interaction) for 2D plots)


[▲ index](#-index)

```julia
function cortex_plot(data :: Union{Vector{A}, Matrix{A}};
                    voxels :: Int64 = 2503,
                    alpha :: Real = 1.0,
                    mode :: Symbol = :cortex3D,
                    title :: String = "Brain activation",
                    colorbar_label :: String = "Current density module",
                    fontsize :: Real = 16.0)where {A<:Real}
```

**Argument**

- `data`: a current density vector or matrix (J for example) containing the data the user wants to visualize.

**Optional Keyword Arguments**
- `voxels`: the number of voxels p in the head model. It can be `2503` or `5002`. 
- `alpha`: the starting value of alpha for the display. 
- `mode`: a symbol that tells the function which display mode the user wants.
- `title`: sets the title of the plots. 
- `colorbar_label`: sets the title of the colorbars. 
- `fontsize`: the size of the plot's ticks. Its default value (16.0) is the Makie's default value.  

**Display**
Opens a window with the same content than `cortex_dashboard` but without the mode selection menu. The user has to choose which display mode he wants with the `mode` argument. The possible options for this argument are symbols with the name of the display mode (example: `:cortex3D` for the `cortex3D` mode or `:cortex2D_8view` for the `cortex2D_8view` mode).

> [!TIP] 
> This function should only be used by the users that know what they want to do, because it is faster to load and display than `cortex_dashboard`. Otherwise, it is recommended to use `cortex_dashboard` because it allows to switch between the display modes without closing the window and re-executing a script. 

[▲ index](#-index)

![separator](Documents/separator.png)

## 💡 Examples

**Example using Eegle data**

```julia
using CortexPlot
using EEGPlot, Eegle, GLMakie, Leadfields, Xloreta

# Example if you have data

# read example EEG data, sampling rate and sensor labels from Eegle
X, sr = readASCII(EXAMPLE_Normative_1), 128;
sensors = readSensors(EXAMPLE_Normative_1_sensors);

X = X[1:sr, :] # choose only the 128 first lines of X

# computes leadfield matrix with Leadfields, you can choose voxels = 2503 or voxels = 5002
K, ename, eloc, gridloc = leadfield(sensors; voxels = 5002) 

# calculation of T with Xloreta, you can change the alpha
T = sLORETA(Float64.(K), 1) 

J_raw = T * Transpose(X)  # calculation of J_raw (size : (voxels*3) × n_times)

J = hcat([cd2sm(J_raw[:, t]) for t in 1:size(J_raw, 2)]...)  # calculation of J ( size : voxels × n_times)

# This is optional, to have a title and display in full screen mode directly
GLMakie.activate!(title = "Cortex Viewer", fullscreen = true) 

cortex_dashboard(J, voxels = 5002) # all mods with a dashboard

# if a specific mode is desired, use instead, for example:
#cortex_plot(J, voxels = 2503, mode = :cortex3D_slice)
```


[▲ index](#-index)

![separator](Documents/separator.png)

## ✍️ About the Author

[Marco Congedo](https://github.com/Marco-Congedo), [Arthur Tatlian](https://github.com/Arthtat) and [Esteban Padilla](https://github.com/Padilla-Esteban)

[▲ index](#-index)

![separator](Documents/separator.png)

## 🌱 Contribute

Please contact the first author if you are interested in contributing.

[▲ index](#-index)
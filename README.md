
![header](Documents/header.png) 

---

> [!TIP] 
> 🦅
> This package is part of the [Eegle.jl](https://github.com/Marco-Congedo/Eegle.jl) ecosystem for EEG data analysis and classification.

---

# CortexPlot

This package allows to visualize EEG vector-type distributed inverse solutions data on a standard cortex in 2D and 3D. It is entirely written in [julia](https://julialang.org/) and is powered by [Makie.jl](https://docs.makie.org/stable/). 

The data that can be visualized by this package can be produced by [Xloreta](https://github.com/Marco-Congedo/Xloreta.jl) or can be manipulations thereof.

> [!WARNING]
> As usual in Julia, the time to first plot (TTFP) may be long, depending on the PC. From the second plot on, it will be much faster.

![separator](Documents/separator.png)

<img width="1078" height="658" alt="CortexPlot gif" src="https://github.com/user-attachments/assets/d563b48c-602f-475f-96d1-776f8d74e7d0" />

![separator](Documents/separator.png)

## 🧭 Index

- 📦 [Installation](#-installation)
- 🔣 [Description](#-description)
- 🔌 [API](#-api)
- 🎮 [Interactions](#-interactions)
- 💡 [Examples](#-examples)
- ✍️ [About the Author](#️-about-the-author)
- 🌱 [Contribute](#-contribute)

![separator](Documents/separator.png)

## 📦 Installation

*julia* version 1.10+ is required.

Execute the following command in julia's REPL:

```julia
using Pkg
Pkg.add(url="https://github.com/Marco-Congedo/CortexPlot.jl")
```

[▲ index](#-index)

![separator](Documents/separator.png)

## 🔣 Description

This package allows the visualization in 2D and 3D of functional brain neuroimaging data using a color code on top of a structural cortical image. Several kind of plots are available, individually or altogether in a *dashboard* that allows to easily switch from one to the others. All plots can be inspected and several parameters can be changed on the fly within the dashboard. Typical visualizations of this package concern:

- current density square module for *p* voxels as computed by [Xloreta](https://github.com/Marco-Congedo/Xloreta.jl). 

- test-statistics obtained by testing, voxel-by-voxel, *p* hypotheses on data produced by [Xloreta](https://github.com/Marco-Congedo/Xloreta.jl). For instance, one can perform these tests and correct for the multiplicity of comparisons across voxels using (PermutationTests.jl)[https://github.com/Marco-Congedo/PermutationTests.jl].


> [!TIP] 
> Several images can be plotted, one after the other or as an animated sequence. The different frames of the sequence typically represent time samples, for example in event-related potentials, frequencies, or experimental conditions. 

> The standard cortices used in this package are read from [Leadfields.jl](https://github.com/Marco-Congedo/Leadfields.jl). They have been pre-computed via [BrainStorm](https://neuroimage.usc.edu/brainstorm/Introduction) by [OpenMEEG](https://openmeeg.github.io/), using the ‘fsaverage’ adult head model (FreeSurfer’s default template based on 40 normative brains). The computation of the associated leadfields is based on the Boundary Element Method (BEM).

> The available cortex structural data and leadfields correspond to:  
> 1) 7509 unconstrained brain dipolar sources (*p = 2503 voxels* × 3 cartesian orientations); voxel size: 4.3mm (default)
> 2) 15006 unconstrained brain dipolar sources (*p = 5002 voxels* × 3 cartesian orientations); voxel size: 3mm

> The cortical data and associated leadfields can be found [here](https://github.com/Marco-Congedo/Leadfields.jl/tree/master/Meshes).

[▲ index](#-index)

![separator](Documents/separator.png)

## 🔌 API

The package exports only two functions. The main function runs a **dashboard**:

```julia
function cortex_dashboard(data :: Union{Vector{Real}, Matrix{Real}};
                        voxels :: Int = 2503,
                        alpha :: Real = 1.0,
                        title :: String = "Brain activation",
                        colorbar_label :: String = "Current density square module",
                        fontsize :: Real = 16.0,
                        colorscheme :: Symbol = :rain
                        )
```

**Argument**

- `data`: a vector holding the value to be plotted at each voxel, or a matrix where each column is such a vector (a frame for a sequence).

**Optional Keyword Arguments**
- `voxels`: the number of voxels *p* forming the solution space. It can be `2503` (default) or `5002`. 
- `alpha`: the transparency of the cortex. By default it is 1.0 (completely opaque). 
- `title`: the title of the plot. 
- `colorbar_label`: the label of the color bar. By default it is "current density squared module".
- `fontsize`: the size of the font for the axes. Its default value (16.0) is the Makie's default value. 
- `colorscheme`: The initial [color scheme](https://juliagraphics.github.io/ColorSchemes.jl/dev/catalogue/). The default is `:rain`. 


The second exported function, `cortex_plot`, can be used instead of the dashboard when only a specific visualization mode is needed. It supports exactly the same arguments as `cortex_dashboard` with the addition of keyword argument `mode`, which set the visualization mode. Possible values are: 
    `:Cortex3D` (default), `:Cortex3D_slice`, `:Cortex3D_3view`, `:Cortex2D_8view`, and `:Cortex2D_3view` --- for the visualization modes see [Interactions](#-interactions).

[▲ index](#-index)

![separator](Documents/separator.png)

## 🎮 Interactions

The [dashboard](#-api) contains drop-box menus, text boxes, sliders and buttons. Interactions are also possible using the keyboard and the mouse.

▼ The first drop-box menu allows the user to switch between five available display modes:

1) `Cortex3D`: the default display mode, which displays the whole cortex in 3D (Fig. 1). 

<p align="left">
  <img src="Documents/Fig1.png" width="560">
  <br>
  <em>Figure 1. Visualization mode "Cortex3D".</em>
</p>


2) `Cortex3D_slice`: displays in 3D a slice of the cortex along the x, y or z axis, with any **position** and **tickness** (Fig. 2).

<p align="left">
  <img src="Documents/Fig2.png" width="560">
  <br>
  <em>Figure 2. Visualization mode "Cortex3D_slice".</em>
</p>


3) `Cortex3D_3view`: as 1., but displays also the three sections through a desired voxel. To set the voxel, either point the mouse on the cortex and hit the "V" key, or enter the voxel coordinates in the text boxes (Fig. 3).

<p align="left">
  <img src="Documents/Fig3.png" width="560">
  <br>
  <em>Figure 3. Visualization mode "Cortex3D_3view".</em>
</p>


4) `Cortex2D_8view`: displays eight views of the cortex in 2D (Fig. 4).

<p align="left">
  <img src="Documents/Fig4.png" width="560">
  <br>
  <em>Figure 4. Visualization mode "Cortex2D_8view".</em>
</p>

5) `Cortex2D_3view`: displays in 2D the three sections of the cortex along the x, y, and z axis, each with any **position** and **tickness** (Fig. 5).

<p align="left">
  <img src="Documents/Fig5.png" width="560">
  <br>
  <em>Figure 5. Visualization mode "Cortex2D_3view".</em>
</p>


▼ The second drop-box menu allows to select the color scheme for the color map.

▼ The third drop-box allows to switch between the *Global* and *Local* scaling mode; with *Global* scaling all frames are scaled to the maximum across all frames, while with *Local* scaling each frame is scaled to its own maximum.

──●── The "Alpha" slider sets the opacity of the cortex. 

──●── The "Color scale" slider sets the non-linearity of the color map.

🔲 The "▶" button switches between *Play* and *Pause* animation mode. 

🔲 The "Display max" displays the sections through the voxel with maximum value. It applies only to visualization modes 3 and 5.

**⌨ Keyboard controls:**

| key     | Effect | Apply to mode |
|:--------|:-------|:--------------|
| ← / → (left and right arrow)| display the previous / next frame   |    all      |
| ↑ / ↓ (up and down arrow)| increase / decrease the position of the slice   |    2.      |
| + / - (up and down arrow)| increase / decrease the thickness of the slice   |    2.      |
| V | displays the three sections through the voxel under the mouse's pointer   |    3.      |
 
**⊕ Mouse Controls for 2D visualization modes:**

- *Primary mouse button click and Drag*: zoom in
- *CTRL + Primary mouse button click*: reset

**⊕ Mouse Controls for 3D visualization modes:**

- *Primary mouse button click and Drag*: rotate
- *SHIFT + Primary mouse button click*: reset rotation
- *Secondary mouse button click and Drag*: pan
- *Mouse wheel*: zoom in & out
- *CTRL + Primary mouse button click*: reset pas and zooming

[▲ index](#-index)

![separator](Documents/separator.png)

## 💡 Examples

**Example using Eegle.jl**

```julia
using Eegle, CortexPlot, EEGPlot, GLMakie

using Leadfields, Xloreta # temp

# Example if you have data

# read example EEG data, sampling rate and sensor labels from Eegle
X, sr = readASCII(EXAMPLE_Normative_1), 128;
sensors = readSensors(EXAMPLE_Normative_1_sensors);
voxels = 5002

X = X[1:sr, :] # choose only the 128 first lines of X

# computes leadfield matrix with Leadfields.jl (re-exported from Eegle), 
# you can choose voxels = 2503 or voxels = 5002
K, ename, eloc, gridloc = leadfield(sensors; voxels) ;

# calculation of sLORETA transformation matrix T with Xloreta (re-exported from Eegle), 
# you should find a suitable alpha (regularization) value for the inverse solution
T = sLORETA(Float64.(K), 1);

# calculation of curent density (size : (voxels*3) × n_samples in X)
J_raw = T * Transpose(X)  

# calculation of current density module ( size : voxels × n_times) using Xloreta
J = hcat((cd2sm(Vector(c)) for c in eachcol(J_raw))...)  

# This is optional, to have a title and display in full screen mode directly
GLMakie.activate!(title = "Title of my study", fullscreen = true) 

cortex_dashboard(J; title="Title of my plot", voxels) # Several cortex plots, all available within a dashboard

# if a specific mode is desired, use instead, for example
#cortex_plot(J; voxels, mode = :cortex3D_slice)
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
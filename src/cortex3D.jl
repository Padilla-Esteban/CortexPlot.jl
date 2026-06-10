function cortex3D(brain,
                    parent :: GridLayout, 
                    alpha :: Observable, 
                    J :: Union{Matrix{Float32}, Matrix{Float64}},
                    colors_obs :: Observable,
                    global_scale :: Observable,
                    scale_gamma :: Observable;
                    colormap :: Symbol = :redsblues,
                    datatype :: Symbol = :positive,
                    fontsize :: Real = 16.0
                    )
    """
    Args:
    brain: the loaded .stl file
    parent: the GridLayout where the cortex and sliders will be displayed
    alpha: an Observable containing the value used for the alpha parameter in mesh! 
    J: the data matrix/vector 
    colors_obs: an observable containing a data vector which changes with the time
    global_scale: an observable containing either :global or :local which dictates if the scale used for the mesh is global or local 
    scale_gamma: an observable containing a float which allows the colorscale changes
    colormap: the symbol of the used colormap for the mesh!
    datatype: a symbol which is either :positive or :real depending on wether J contains only positive values or not

    Initializes the global variables used by the other functions of the file
    Then calls the cortex3D_display function to start the display
    """
    global cortex3D_ax3d, cortex3D_cb, cortex3D_limits_obs
    cortex3D_ax3d = nothing
    cortex3D_cb = nothing
    cortex3D_limits_obs = nothing
    cortex3D_display(brain, parent, alpha, J, colors_obs, global_scale, scale_gamma, colormap=colormap, datatype=datatype, fontsize=fontsize)
end

function cortex3D_display(brain,
                        parent :: GridLayout, 
                        alpha :: Observable, 
                        J :: Union{Matrix{Float32}, Matrix{Float64}},
                        colors_obs :: Observable,
                        global_scale :: Observable,
                        scale_gamma :: Observable;
                        colormap :: Symbol = :redsblues,
                        datatype :: Symbol = :positive,
                        fontsize :: Real = 16.0
                        )
    """
    Displays the brain in a 3D view in a "parent" (a GridLayout).
    """
    global cortex3D_ax3d, cortex3D_cb, cortex3D_limits_obs

    limits = global_scale[] ? Observable(get_limits(J, datatype=datatype)) : @lift get_limits($colors_obs, datatype=datatype)
    cortex3D_limits_obs = limits 

    cortex3D_ax3d = Axis3(parent[1, 1], aspect = :data, title = "Brain activation",
                            xlabelsize = fontsize,
                            ylabelsize = fontsize,
                            zlabelsize = fontsize,
                            xticklabelsize = fontsize,
                            yticklabelsize = fontsize,
                            zticklabelsize = fontsize
                            )

    mesh!(                #brain anatomy display
        cortex3D_ax3d,
        brain,
        color = RGBf(0.999, 0.999, 0.999),
        alpha = alpha,
        backlight = 1.0
    )
    colors_rgba = @lift activation_rgba(
        $colors_obs,      # per-vertex activation values (already indexed by vertex_per_face)
        colormap,           
        $limits,
        midpoint = $scale_gamma
    )

    mesh!(                #brain activation display 
        cortex3D_ax3d,
        brain,
        color        = colors_rgba,
        transparency = true,
        overdraw = true   
    )

    cortex3D_cb = Colorbar(parent[1, 2],
        colormap   = warped_cmap(colormap, scale_gamma[]), #Reverse(colormap),  #use "warped_cmap(colormap, scale_gamma[])" insted to update the colorbar scale when scale_gamma is moved 
        colorrange = limits[],
        label      = "Current density module"
    )

    on(limits, update=true) do lims #necessary to update the colorbar each time the scale is changed to global/local
        cortex3D_cb.colorrange = lims
    end

    #use this to update the colorbar scale when scale_gamma is moved:
    on(scale_gamma, update=true) do mid
        cortex3D_cb.colormap = warped_cmap(colormap, mid)
    end
end

function clear_cortex3D()
    """
    Clears the axis and the colorbar created by brain_display.
    """
    global cortex3D_ax3d, cortex3D_cb, cortex3D_limits_obs

    if cortex3D_ax3d !== nothing
        try; empty!(cortex3D_ax3d); catch; end
        try; delete!(cortex3D_ax3d); catch; end
    end

    if cortex3D_limits_obs !== nothing
        empty!(cortex3D_limits_obs.listeners)  
    end

    if cortex3D_cb !== nothing
        try; delete!(cortex3D_cb); catch; end
    end
end


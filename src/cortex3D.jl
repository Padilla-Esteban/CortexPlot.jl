function cortex3D(brain,
                    parent :: GridLayout, 
                    alpha :: Observable, 
                    J :: Union{Matrix{Float32}, Matrix{Float64}},
                    colors_obs :: Observable,
                    global_scale :: Observable,
                    scale_gamma :: Observable,
                    colormap :: Observable;
                datatype :: Symbol = :positive,
                title :: String = "Brain activation",
                colorbar_label :: String = "Current density module",
                fontsize :: Real = 16.0
                )
    global cortex3D_ax3d, cortex3D_cb
    cortex3D_ax3d = nothing
    cortex3D_cb = nothing
    cortex3D_display(brain, parent, alpha, J, colors_obs, global_scale, scale_gamma, colormap, datatype=datatype, title=title, colorbar_label=colorbar_label, fontsize=fontsize)
end

"""
Displays the brain in a 3D view in a "parent" (a GridLayout).
"""
function cortex3D_display(brain,
                            parent :: GridLayout, 
                            alpha :: Observable, 
                            J :: Union{Matrix{Float32}, Matrix{Float64}},
                            colors_obs :: Observable,
                            global_scale :: Observable,
                            scale_gamma :: Observable,
                            colormap :: Observable;
                        datatype :: Symbol = :positive,
                        title :: String = "Brain activation",
                        colorbar_label :: String = "Current density module",
                        fontsize :: Real = 16.0
                        )
    global cortex3D_ax3d, cortex3D_cb

    limits = Observable(get_limits(J, datatype=datatype))

    on(global_scale, update=true) do is_global
        limits[] = is_global ? get_limits(J, datatype=datatype) :
                               get_limits(colors_obs[], datatype=datatype)
    end

    on(colors_obs) do cols
        if !global_scale[]
            limits[] = get_limits(cols, datatype=datatype)
        end
    end

    cortex3D_ax3d = Axis3(parent[1, 1], aspect = :data, title = title,
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
        $colormap,           
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
        colormap   = warped_cmap(colormap[], scale_gamma[]), 
        colorrange = limits[],
        label      = colorbar_label,
        labelsize = fontsize,
        ticksize = fontsize
    )

    on(limits, update=true) do lims #necessary to update the colorbar each time the scale is changed to global/local
        cortex3D_cb.colorrange = lims
    end

    on(colormap, update=true) do cmap
        cortex3D_cb.colormap = warped_cmap(cmap, scale_gamma[])
    end

    #use this to update the colorbar scale when scale_gamma is moved:
    on(scale_gamma, update=true) do mid
        cortex3D_cb.colormap = warped_cmap(colormap[], mid)
    end
end

"""
Clears the axis and the colorbar created by brain_display.
"""
function clear_cortex3D()
    global cortex3D_ax3d, cortex3D_cb

    if cortex3D_ax3d !== nothing
        try; empty!(cortex3D_ax3d); catch; end
        try; delete!(cortex3D_ax3d); catch; end
    end

    if cortex3D_cb !== nothing
        try; delete!(cortex3D_cb); catch; end
    end
end


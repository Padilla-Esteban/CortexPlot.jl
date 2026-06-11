function cortex2D_8view(brain,
                            parent :: GridLayout, 
                            J :: Union{Matrix{Float32}, Matrix{Float64}},
                            colors_obs :: Observable,
                            alpha :: Observable,
                            global_scale :: Observable,
                            scale_gamma :: Observable,
                            colormap :: Observable;
                        datatype :: Symbol = :positive,
                        colorbar_label :: String = "Current density module",
                        fontsize :: Real = 16.0
                        )
    global eight_view_axis, eight_view_widgets
    pts = [p for tri in brain for p in tri]

    lo_x, hi_x = get_range(1, pts)
    lo_y, hi_y = get_range(2, pts)
    lo_z, hi_z = get_range(3, pts)

    eight_view_axis = Axis[]
    eight_view_widgets = []

    # - Definition of the sectional views -
    # (position in the grid, azimuth, elevation, section)
    views = [
        (1,1,  0.0,   0.0,    section(lo_y, hi_y,  2), "OR"),
        (2,1,  pi,   0.0,    section(0,    hi_y,  2), "IL"),
        (3,1,  0.0,   pi/2,   section(lo_z, hi_z,  3), "A"),
        (1,2,  pi/2,  0.0,    section(lo_x, hi_x,  1), "F"),
        (2,2, -pi/2,  0.0,    section(lo_x, hi_x,  1), "B"),
        (1,3,  pi,    0.0,    section(lo_y, hi_y,  2), "OL"),
        (2,3,  0.0,  0.0,    section(lo_y, 0,     2), "IR"),
        (3,3,  0.0,  -pi/2,   section(lo_z, hi_z,  3), "U"),
    ]
    
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

    for (row, col, az, el, clip, texte) in views
        R  = make_view_rotation(az, el)
        rb = rotate_mesh_for_view(brain, R)   # pre-rotated mesh
        clip = rotate_clip_planes(clip, R)    # clip planes in rotated space

        ax = Axis(parent[row, col], aspect = DataAspect(),
                bottomspinevisible=false,
                leftspinevisible=false,
                rightspinevisible=false,
                topspinevisible=false,
                xgridvisible=false,
                ygridvisible=false,
                xminorgridvisible=false,
                yminorgridvisible=false,
                xminorticksvisible=false,
                yminorticksvisible=false,
                xticklabelsvisible=false,
                yticklabelsvisible=false,
                xticksvisible=false,
                yticksvisible=false
                )
        
        mesh!(                #brain anatomy display
        ax,
        rb,
        color = RGBf(0.999, 0.999, 0.999),
        clip_planes = clip,
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
            ax,
            rb,
            color        = colors_rgba,
            transparency = true,
            overdraw = true,
            clip_planes = clip  
        )
        
        push!(eight_view_axis, ax)
        text!(ax, texte, position = (1.0, 0.0), align = (:right, :bottom), space = :relative)
    end

    ax_text_legend_above = Axis(parent[3, 2][1,1],bottomspinevisible=false,
                leftspinevisible=false,
                rightspinevisible=false,
                topspinevisible=false,
                xgridvisible=false,
                ygridvisible=false,
                xminorgridvisible=false,
                yminorgridvisible=false,
                xminorticksvisible=false,
                yminorticksvisible=false,
                xticklabelsvisible=false,
                yticklabelsvisible=false,
                xticksvisible=false,
                yticksvisible=false)
    ax_text_legend_under = Axis(parent[3, 2][2,1],bottomspinevisible=false,
                leftspinevisible=false,
                rightspinevisible=false,
                topspinevisible=false,
                xgridvisible=false,
                ygridvisible=false,
                xminorgridvisible=false,
                yminorgridvisible=false,
                xminorticksvisible=false,
                yminorticksvisible=false,
                xticklabelsvisible=false,
                yticklabelsvisible=false,
                xticksvisible=false,
                yticksvisible=false)

    text!(ax_text_legend_above, "O=outside, I=inside, F=front, B=back",position = (0.5, 0.0), align = (:center, :bottom), space = :relative)
    text!(ax_text_legend_under, "A=above, U=under, L=left, R=right",position = (0.5, 1.0), align = (:center, :top), space = :relative)

    push!(eight_view_axis, ax_text_legend_above, ax_text_legend_under)

    cb = Colorbar(parent[1:3, 4],
        colormap   = warped_cmap(colormap[], scale_gamma[]), 
        colorrange = limits[],
        label      = colorbar_label,
        labelsize = fontsize,
        ticksize = fontsize
    )

    on(limits, update=true) do lims #necessary to update the colorbar each time the scale is changed to global/local
        cb.colorrange = lims
    end

    on(colormap, update=true) do cmap
        cb.colormap = warped_cmap(cmap, scale_gamma[])
    end

    #use this to update the colorbar scale when scale_gamma is moved:
    on(scale_gamma, update=true) do mid
        cb.colormap = warped_cmap(colormap[], mid)
    end

    push!(eight_view_widgets, cb)

end


"""
Clears the 8 axis created by 'display_sections'. Puts the global back to 'nothing' if necessary.
"""
function clear_8view()
    
    global eight_view_axis, eight_view_widgets

    try;
    for ax in eight_view_axis
        try; empty!(ax); catch; end
        try; delete!(ax); catch; end
    end

    # Input widgets (Textboxes, Buttons) 
    for w in eight_view_widgets
        try; delete!(w); catch; end
    end
    catch;
    end
end





function cortex2D_8view(brain,
                            parent :: GridLayout, 
                            J :: Union{Matrix{Float32}, Matrix{Float64}},
                            colors_obs :: Observable,
                            alpha :: Observable,
                            global_scale :: Observable,
                            scale_gamma :: Observable;
                            colormap :: Symbol = :redsblues,
                            datatype :: Symbol = :positive
                            )
    """
    Args:
    brain: the loaded .stl file
    parent: the GridLayout where the cortex and sliders will be displayed
    J: the data matrix/vector 
    colors_obs: an observable containing a data vector which changes with the time 
    alpha: an Observable containing the value used for the alpha parameter in mesh! 
    global_scale: an observable containing either :global or :local which dictates if the scale used for the mesh is global or local
    scale_gamma: an observable containing a float which allows the colorscale changes
    colormap: the symbol of the used colormap for the mesh!
    datatype: a symbol which is either :positive or :real depending on wether J contains only positive values or not

    Displays 8 sectional views of the brain in 'parent' (a 3*3 GridLayout)
    """
    global eight_view_axis, eight_view_widgets, eight_view_lim_obs 
    pts = [p for tri in brain for p in tri]

    lo_x, hi_x = get_range(1, pts)
    lo_y, hi_y = get_range(2, pts)
    lo_z, hi_z = get_range(3, pts)

    eight_view_axis = Axis[]
    eight_view_widgets = []

    # - Definition of the sectional views -
    # (position in the grid, azimuth, elevation, section)
    views = [
        (1,1,  0.0,   0.0,    section(lo_y, hi_y,  2), "AA"),
        (2,1,  pi,   0.0,    section(0,    hi_y,  2), "AA"),
        (3,1,  0.0,   pi/2,   section(lo_z, hi_z,  3), "AA"),
        (1,2,  pi/2,  0.0,    section(lo_x, hi_x,  1), "AA"),
        (2,2, -pi/2,  0.0,    section(lo_x, hi_x,  1), "AA"),
        (1,3,  pi,    0.0,    section(lo_y, hi_y,  2), "AA"),
        (2,3,  0.0,  0.0,    section(lo_y, 0,     2), "AA"),
        (3,3,  0.0,  -pi/2,   section(lo_z, hi_z,  3), "AA"),
    ]
    
    limits = global_scale[] ? Observable(get_limits(J, datatype=datatype)) : @lift get_limits($colors_obs, datatype=datatype)
    eight_view_lim_obs = limits

    for (row, col, az, el, clip, text) in views
        R  = make_view_rotation(az, el)
        rb = rotate_mesh_for_view(brain, R)   # pre-rotated mesh
        clip = rotate_clip_planes(clip, R)      # clip planes in rotated space

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
            colormap,           
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
    end

    legend1 = Label(parent[3, 2][1, 1], "Sorted from left to right and top to bottom:")
    legend2 = Label(parent[3, 2][2, 1], "1:OR, 2:F, 3:OL, 4:IL, 5:B, 6:IR, 7:A, 8:U")
    legend3 = Label(parent[3, 2][3, 1], "O=outside, I=inside, F=front, B=back")
    legend4 = Label(parent[3, 2][4, 1], "A=above, U=under, L=left, R=right")

    push!(eight_view_widgets, legend1, legend2, legend3, legend4)

    cb = Colorbar(parent[1:3, 4],
            colormap   = Reverse(colormap),
            colorrange = limits[],
            label      = "Current density module",
    )

    on(limits, update=true) do lims #necessary to update the colorbar each time the scale is changed to global/local
        cb.colorrange = lims
    end

    push!(eight_view_widgets, cb)

end

function clear_8view()
    """
    Clears the 8 axis created by 'display_sections'. Puts the global back to 'nothing' if necessary.
    """
    global eight_view_axis, eight_view_widgets, eight_view_lim_obs

    try;
    for ax in eight_view_axis
        try; empty!(ax); catch; end
        try; delete!(ax); catch; end
    end

    # Input widgets (Textboxes, Buttons) 
    for w in eight_view_widgets
        try; delete!(w); catch; end
    end

    if eight_view_lim_obs !== nothing
        empty!(eight_view_lim_obs.listeners)  
        eight_view_lim_obs = nothing
    end

    catch;
    end
end





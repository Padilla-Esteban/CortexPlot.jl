# - Main Function -

function cortex3D_3slice(brain,
                    parent :: GridLayout, 
                    J :: Union{Matrix{Float32}, Matrix{Float64}},
                    colors_obs :: Observable,
                    alpha :: Observable,
                    global_scale :: Observable,
                    scale_gamma :: Observable;
                    colormap:: Symbol = :redsblues,
                    datatype :: Symbol = :positive,
                    fontsize :: Real = 16.0
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

    Initializes the global variables used by the other functions of the file
    Displays the brain model and the control blocks (slider, textEntry...)
    Sets up the keyboard controls
    """
    global three_slice_ax3d, three_slice_mesh, three_slice_cb, three_slice_coord_lbl
    global three_slice_widgets, three_slice_input_grid
    global three_slice_ax_nx, three_slice_ax_ny, three_slice_ax_nz, three_slice_parent
    global three_slice_lim_obs

    three_slice_ax3d      =     nothing
    three_slice_mesh         =  nothing
    three_slice_cb  =           nothing
    three_slice_coord_lbl =     nothing
    three_slice_widgets =       []
    three_slice_input_grid   =  nothing
    three_slice_ax_nx  =        nothing
    three_slice_ax_ny  =        nothing
    three_slice_ax_nz  =        nothing
    three_slice_parent =        parent

    # - Main 3D View -
    three_slice_ax3d = Axis3(parent[1:3, 1], aspect = :data, title = "Brain activation",
                        xlabelsize = fontsize,
                        ylabelsize = fontsize,
                        zlabelsize = fontsize,
                        xticklabelsize = fontsize,
                        yticklabelsize = fontsize,
                        zticklabelsize = fontsize
                        )

    #Calculating the limits of the colorscale
    limits = global_scale[] ? Observable(get_limits(J, datatype=datatype)) : @lift get_limits($colors_obs, datatype=datatype)
    three_slice_lim_obs = limits

    mesh!(                #brain anatomy display
        three_slice_ax3d,
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
    three_slice_mesh = mesh!(                #brain activation display 
        three_slice_ax3d,
        brain,
        color        = colors_rgba,
        transparency = true,
        overdraw = true       
    )

    three_slice_cb = Colorbar(parent[1:3, 2],
            colormap   = Reverse(colormap),
            colorrange = limits[],
            label      = "Current density module",
        )

    on(limits, update=true) do lims #necessary to update the colorbar each time the scale is changed to global/local
        three_slice_cb.colorrange = lims
    end

    three_slice_coord_lbl = Label(parent[4, 1:3],
        "Press a to obtain the coordinates and the views of the point on the mouse",
        fontsize = 14, color = :gray40)

    # - Manual input -
    three_slice_input_grid = parent[5, 1:3] = GridLayout()

    lbl_x = Label(three_slice_input_grid[1, 1], "x :", halign = :right)
    tb_x  = Textbox(three_slice_input_grid[1, 2], placeholder = "x", width = 80)
    lbl_y = Label(three_slice_input_grid[1, 3], "y :", halign = :right)
    tb_y  = Textbox(three_slice_input_grid[1, 4], placeholder = "y", width = 80)
    lbl_z = Label(three_slice_input_grid[1, 5], "z :", halign = :right)
    tb_z  = Textbox(three_slice_input_grid[1, 6], placeholder = "z", width = 80)
    btn   = Button(three_slice_input_grid[1, 7], label = "Display views")
    display_max = Button(three_slice_input_grid[1, 8], label = "Display max")

    push!(three_slice_widgets, lbl_x, tb_x, lbl_y, tb_y, lbl_z, tb_z, btn, display_max)

    on(btn.clicks) do _ 
        try
            #displaying the entered coordinates
            x = parse(Float32, tb_x.displayed_string[])
            y = parse(Float32, tb_y.displayed_string[])
            z = parse(Float32, tb_z.displayed_string[])
            three_slice_coord_lbl.text[] = @sprintf("x = %.3f  |  y = %.3f  |  z = %.3f", x, y, z)
            #calling the function that displays 3 slices based on the entered coordinates
            display_3D_three_slice(brain, x, y, z, colors_obs, colormap, alpha, datatype, limits, scale_gamma)
        catch e
            three_slice_coord_lbl.text[] = "Error : $e — check X, Y, Z are numbers."
        end
    end

    on(display_max.clicks) do s
        #finding the point where the activity is at its maximum
        index = argmax(colors_obs[])
        pos = brain.position
        pt = pos[index]
        #displaying the coordinates of this point
        x, y, z = Float32(pt[1]), Float32(pt[2]), Float32(pt[3])
        three_slice_coord_lbl.text[] = @sprintf("x = %.3f  |  y = %.3f  |  z = %.3f", x, y, z)
        #calling the function that will display 3 slices based on the max coordinates
        display_3D_three_slice(brain, x, y, z, colors_obs, colormap, alpha, datatype, limits, scale_gamma)
    end


    # - Keyboard and mouse -
    mouse_pos = Observable(Point2f(0, 0))
    on(events(three_slice_ax3d).mouseposition) do pos
        mouse_pos[] = pos
    end
    on(events(f.scene).keyboardbutton) do event
        #setting up that pressing q (or a for azerty keyboards) does the same than entering coordinates and clicking the display button
        three_slice_mesh === nothing && return
        (event.action == Keyboard.press && event.key == Keyboard.q) || return
        result = pick(f.scene, mouse_pos[][1], mouse_pos[][2])
        if result === nothing || result[1] !== three_slice_mesh
            three_slice_coord_lbl !== nothing && (three_slice_coord_lbl.text[] = "Mouse out of the brain.")
            return
        end
        plt, idx = result
        if idx > 0 && hasproperty(plt, :converted) && length(plt.converted[]) > 0
            #finding the coordinates of the mouse 
            x, y, z = claim_coordinates(plt, idx)
            #calling the function that displays 3 slices based on the mouse coordinates
            display_3D_three_slice(brain, x, y, z, colors_obs, colormap, alpha, datatype, limits, scale_gamma)
        end
    end
end


# - Side Functions - 
function display_3D_three_slice(brain, x, y, z, colors_obs, colormap, alpha, datatype, limits, scale_gamma)
    """
    Clears the axis if some slices were already displayed
    Then calls the function that displays a slice 3 times (one per axis)
    """
    global three_slice_ax_nx, three_slice_ax_ny, three_slice_ax_nz, three_slice_parent

    for ax in [three_slice_ax_nx, three_slice_ax_ny, three_slice_ax_nz]
        if ax !== nothing
            try; empty!(ax); catch; end
            try; delete!(ax); catch; end
        end
    end

    three_slice_ax_nx = display_3D_slice(brain, 1, x, 10, three_slice_parent[1, 3], "x-Normal slice", colors_obs, colormap, alpha, datatype, limits, scale_gamma)
    three_slice_ax_ny = display_3D_slice(brain, 2, y, 10, three_slice_parent[2, 3], "y-Normal slice", colors_obs, colormap, alpha, datatype, limits, scale_gamma)
    three_slice_ax_nz = display_3D_slice(brain, 3, z, 10, three_slice_parent[3, 3], "z-Normal slice", colors_obs, colormap, alpha, datatype, limits, scale_gamma)

    colsize!(three_slice_parent, 2, Fixed(50))
    colsize!(three_slice_parent, 1, Fixed(600))
    colsize!(three_slice_parent, 3, Auto())
end

function display_3D_slice(brain, axis, pos, thickness, cell, title, colors_obs, colormap, alpha, datatype, limits, scale_gamma)
    """
    Displays the slice located on "pos" along "axis" in a 3d axis
    """
    pts = [p for tri in brain for p in tri]
    slab = make_3D_slab(pos, abs(axis), thickness, pts)
    ax = Axis3(cell, aspect = :data,
                title = title,
                xgridvisible = false,
                ygridvisible = false,
                zgridvisible = false,
                xlabelvisible = false,
                ylabelvisible = false,
                zlabelvisible = false,
                xspinesvisible = false,
                yspinesvisible = false,
                zspinesvisible = false,
                xticklabelsvisible = false,
                yticklabelsvisible = false,
                zticklabelsvisible = false,
                xticksvisible = false,
                yticksvisible = false,
                zticksvisible = false,
                protrusions = 0)

    mesh!(                #brain slab anatomy display
        ax,
        brain,
        color = RGBf(0.999, 0.999, 0.999),        
        clip_planes = slab,
        alpha = alpha,
        backlight = 1.0
    )
    colors_rgba = @lift activation_rgba(
        $colors_obs,      # per-vertex activation values (already indexed by vertex_per_face)
        colormap,           
        $limits,
        midpoint = $scale_gamma
    )
    mesh!(                #brain slab activation display 
        ax,
        brain,
        color        = colors_rgba,
        transparency = true,
        overdraw = true,
        clip_planes = slab  
    )

    ax.azimuth[]   = axis == 1 ? 0.0  : axis == 2 ? pi/2 : 0.0
    ax.elevation[] = axis == 3 ? pi/2 : 0.0
    return ax
end

function claim_coordinates(plt, idx)
    """
    Claims the mouse coordinates, displays them in the Labels and returns them 
    """
    mesh_data = plt[1][]
    pos     = mesh_data.position
    idx > length(pos) && return 0f0, 0f0, 0f0
    pt = pos[idx]
    x, y, z = Float32(pt[1]), Float32(pt[2]), Float32(pt[3])
    three_slice_coord_lbl.text[] = @sprintf("x = %.3f  |  y = %.3f  |  z = %.3f", x, y, z)
    return x, y, z
end


function clear_3slice()
    """
    Clears everything created by the functions above (meshes, Labels, sliders...)
    Puts global variables back to nothing if needed
    """
    global three_slice_ax3d, three_slice_mesh, three_slice_cb, three_slice_coord_lbl
    global three_slice_widgets, three_slice_input_grid
    global three_slice_ax_nx, three_slice_ax_ny, three_slice_ax_nz, three_slice_parent
    global three_slice_lim_obs

    try;
    # Sectional views
    for ax in [three_slice_ax_nx, three_slice_ax_ny, three_slice_ax_nz]
        if ax !== nothing
            try; empty!(ax); catch; end
            try; delete!(ax); catch; end
        end
    end

    # Input widgets (Textboxes, Buttons) 
    if three_slice_widgets !== nothing
        for w in three_slice_widgets
            try; delete!(w); catch; end
        end
    end

    # Input GridLayout
    if three_slice_input_grid !== nothing
        try; delete!(three_slice_input_grid); catch; end
    end

    # Colorbar
    if three_slice_cb !== nothing
        try; delete!(three_slice_cb); catch; end
    end

    # Coordinates label
    if three_slice_coord_lbl !== nothing
        try; delete!(three_slice_coord_lbl); catch; end
    end

    # Main 3D Axis
    if three_slice_ax3d !== nothing
        try; empty!(three_slice_ax3d); catch; end
        try; delete!(three_slice_ax3d); catch; end
    end

    if three_slice_lim_obs !== nothing
        empty!(three_slice_lim_obs.listeners)  
        three_slice_lim_obs = nothing
    end

    catch;
    end
end
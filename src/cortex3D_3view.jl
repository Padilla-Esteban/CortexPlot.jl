# - Main Function -

function cortex3D_3view(brain,
                        parent :: GridLayout, 
                        J :: Union{Matrix{Float32}, Matrix{Float64}},
                        colors_obs :: Observable,
                        alpha :: Observable,
                        global_scale :: Observable,
                        scale_gamma :: Observable,
                        colormap:: Observable;
                    datatype :: Symbol = :positive,
                    title :: String = "Brain activation",
                    colorbar_label :: String = "Current density module",
                    fontsize :: Real = 16.0
                    )
    global three_view3D_ax3d, three_view3D_mesh, three_view3D_cb, three_view3D_coord_lbl
    global three_view3D_widgets, three_view3D_input_grid
    global three_view3D_ax_nx, three_view3D_ax_ny, three_view3D_ax_nz, three_view3D_parent

    three_view3D_ax3d      =     nothing
    three_view3D_mesh         =  nothing
    three_view3D_cb  =           nothing
    three_view3D_coord_lbl =     nothing
    three_view3D_widgets =       []
    three_view3D_input_grid   =  nothing
    three_view3D_ax_nx  =        nothing
    three_view3D_ax_ny  =        nothing
    three_view3D_ax_nz  =        nothing
    three_view3D_parent =        parent

    # - Main 3D View -
    three_view3D_ax3d = Axis3(parent[1:3, 1], aspect = :data, title = title,
                        xlabelsize = fontsize,
                        ylabelsize = fontsize,
                        zlabelsize = fontsize,
                        xticklabelsize = fontsize,
                        yticklabelsize = fontsize,
                        zticklabelsize = fontsize,
                        )

    #Calculating the limits of the colorscale
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

    mesh!(                #brain anatomy display
        three_view3D_ax3d,
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
    three_view3D_mesh = mesh!(                #brain activation display 
        three_view3D_ax3d,
        brain,
        color        = colors_rgba,
        transparency = true,
        overdraw = true       
    )

    three_view3D_cb = Colorbar(parent[1:3, 2],
        colormap   = warped_cmap(colormap[], scale_gamma[]), 
        colorrange = limits[],
        label      = colorbar_label,
        labelsize = fontsize,
        ticksize = fontsize
    )

    on(limits, update=true) do lims #necessary to update the colorbar each time the scale is changed to global/local
        three_view3D_cb.colorrange = lims
    end

    on(colormap, update=true) do cmap
        three_view3D_cb.colormap = warped_cmap(cmap, scale_gamma[])
    end

    #use this to update the colorbar scale when scale_gamma is moved:
    on(scale_gamma, update=true) do mid
        three_view3D_cb.colormap = warped_cmap(colormap[], mid)
    end

    three_view3D_coord_lbl = Label(parent[4, 1:3],
        "Press v to obtain the coordinates of the point on the mouse and the associated views.",
        fontsize = 14, color = :gray40)

    # - Manual input -
    three_view3D_input_grid = parent[5, 1:3] = GridLayout()

    lbl_x = Label(three_view3D_input_grid[1, 1], "x :", halign = :right)
    tb_x  = Textbox(three_view3D_input_grid[1, 2], placeholder = "x", width = 80, displayed_string="0")
    lbl_y = Label(three_view3D_input_grid[1, 3], "y :", halign = :right)
    tb_y  = Textbox(three_view3D_input_grid[1, 4], placeholder = "y", width = 80, displayed_string="0")
    lbl_z = Label(three_view3D_input_grid[1, 5], "z :", halign = :right)
    tb_z  = Textbox(three_view3D_input_grid[1, 6], placeholder = "z", width = 80, displayed_string="0")
    btn   = Button(three_view3D_input_grid[1, 7], label = "Display views")
    display_max = Button(three_view3D_input_grid[1, 8], label = "Display max")

    push!(three_view3D_widgets, lbl_x, tb_x, lbl_y, tb_y, lbl_z, tb_z, btn, display_max)

    on(btn.clicks) do _ 
        try
            #displaying the entered coordinates
            x = parse(Float32, tb_x.displayed_string[])
            y = parse(Float32, tb_y.displayed_string[])
            z = parse(Float32, tb_z.displayed_string[])
            three_view3D_coord_lbl.text[] = @sprintf("x = %.3f  |  y = %.3f  |  z = %.3f", x, y, z)
            #calling the function that displays 3 slices based on the entered coordinates
            display_3D_three_view(brain, x, y, z, colors_obs, colormap, alpha, datatype, limits, scale_gamma)
        catch e
            three_view3D_coord_lbl.text[] = "Error : $e — check X, Y, Z are numbers."
        end
    end

    on(display_max.clicks) do s
        #finding the point where the activity is at its maximum
        index = argmax(colors_obs[])
        pos = brain.position
        pt = pos[index]
        #displaying the coordinates of this point
        x, y, z = Float32(pt[1]), Float32(pt[2]), Float32(pt[3])
        three_view3D_coord_lbl.text[] = @sprintf("x = %.3f  |  y = %.3f  |  z = %.3f", x, y, z)
        #calling the function that will display 3 slices based on the max coordinates
        display_3D_three_view(brain, x, y, z, colors_obs, colormap, alpha, datatype, limits, scale_gamma)
    end


    # - Keyboard and mouse -
    mouse_pos = Observable(Point2f(0, 0))
    on(events(three_view3D_ax3d).mouseposition) do pos
        mouse_pos[] = pos
    end
    on(events(f.scene).keyboardbutton) do event
        #setting up that pressing q (or a for azerty keyboards) does the same than entering coordinates and clicking the display button
        three_view3D_mesh === nothing && return
        (event.action == Keyboard.press && event.key == Keyboard.v) || return
        result = pick(f.scene, mouse_pos[][1], mouse_pos[][2])
        if result === nothing || result[1] !== three_view3D_mesh
            three_view3D_coord_lbl !== nothing && (three_view3D_coord_lbl.text[] = "Mouse out of the brain.")
            return
        end
        plt, idx = result
        if idx > 0 && hasproperty(plt, :converted) && length(plt.converted[]) > 0
            #finding the coordinates of the mouse 
            x, y, z = claim_coordinates(plt, idx)
            #calling the function that displays 3 slices based on the mouse coordinates
            display_3D_three_view(brain, x, y, z, colors_obs, colormap, alpha, datatype, limits, scale_gamma)
        end
    end
end


# - Side Functions - 
function display_3D_three_view(brain, x, y, z, colors_obs, colormap, alpha, datatype, limits, scale_gamma)
    """
    Clears the axis if some slices were already displayed
    Then calls the function that displays a slice 3 times (one per axis)
    """
    global three_view3D_ax_nx, three_view3D_ax_ny, three_view3D_ax_nz, three_view3D_parent

    for ax in [three_view3D_ax_nx, three_view3D_ax_ny, three_view3D_ax_nz]
        if ax !== nothing
            try; empty!(ax); catch; end
            try; delete!(ax); catch; end
        end
    end

    three_view3D_ax_nx = display_3D_view(brain, 1, x, 10, three_view3D_parent[1, 3], "Coronal section", colors_obs, colormap, alpha, datatype, limits, scale_gamma)
    three_view3D_ax_ny = display_3D_view(brain, 2, y, 10, three_view3D_parent[2, 3], "Sagittal section", colors_obs, colormap, alpha, datatype, limits, scale_gamma)
    three_view3D_ax_nz = display_3D_view(brain, 3, z, 10, three_view3D_parent[3, 3], "Axial Section", colors_obs, colormap, alpha, datatype, limits, scale_gamma)

    colsize!(three_view3D_parent, 2, Fixed(50))
    colsize!(three_view3D_parent, 1, Fixed(600))
    colsize!(three_view3D_parent, 3, Auto())
end


"""
Displays the slice located on "pos" along "axis" in a 3d axis
"""
function display_3D_view(brain, axis, pos, thickness, cell, title, colors_obs, colormap, alpha, datatype, limits, scale_gamma)
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
        $colormap,           
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


"""
Claims the mouse coordinates, displays them in the Labels and returns them 
"""
function claim_coordinates(plt, idx)
    
    mesh_data = plt[1][]
    pos     = mesh_data.position
    idx > length(pos) && return 0f0, 0f0, 0f0
    pt = pos[idx]
    x, y, z = Float32(pt[1]), Float32(pt[2]), Float32(pt[3])
    three_view3D_coord_lbl.text[] = @sprintf("x = %.3f  |  y = %.3f  |  z = %.3f", x, y, z)
    return x, y, z
end


"""
Clears everything created by the functions above (meshes, Labels, sliders...)
Puts global variables back to nothing if needed
"""
function clear_3D_3view()
    
    global three_view3D_ax3d, three_view3D_mesh, three_view3D_cb, three_view3D_coord_lbl
    global three_view3D_widgets, three_view3D_input_grid
    global three_view3D_ax_nx, three_view3D_ax_ny, three_view3D_ax_nz, three_view3D_parent

    try;
    # Sectional views
    for ax in [three_view3D_ax_nx, three_view3D_ax_ny, three_view3D_ax_nz]
        if ax !== nothing
            try; empty!(ax); catch; end
            try; delete!(ax); catch; end
        end
    end

    # Input widgets (Textboxes, Buttons) 
    if three_view3D_widgets !== nothing
        for w in three_view3D_widgets
            try; delete!(w); catch; end
        end
    end

    # Input GridLayout
    if three_view3D_input_grid !== nothing
        try; delete!(three_view3D_input_grid); catch; end
    end

    # Colorbar
    if three_view3D_cb !== nothing
        try; delete!(three_view3D_cb); catch; end
    end

    # Coordinates label
    if three_view3D_coord_lbl !== nothing
        try; delete!(three_view3D_coord_lbl); catch; end
    end

    # Main 3D Axis
    if three_view3D_ax3d !== nothing
        try; empty!(three_view3D_ax3d); catch; end
        try; delete!(three_view3D_ax3d); catch; end
    end
    catch;
    end
end
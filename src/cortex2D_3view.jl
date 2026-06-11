# - Main Function -
function cortex2D_3view(brain,
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
    global three_view2D_ax_nx, three_view2D_ax_ny, three_view2D_ax_nz
    global three_view2D_axis, three_view2D_parent, three_view2D_widgets
    global three_view2D_pos_x, three_view2D_pos_y, three_view2D_pos_z
    global three_view2D_thick_x, three_view2D_thick_y, three_view2D_thick_z

    three_view2D_ax_nx     = nothing
    three_view2D_ax_ny     = nothing
    three_view2D_ax_nz     = nothing
    three_view2D_axis = Axis[]
    three_view2D_parent    = parent
    three_view2D_widgets = []

    three_view2D_pos_x = Observable(0.0f0)
    three_view2D_pos_y = Observable(0.0f0)
    three_view2D_pos_z = Observable(0.0f0)
    three_view2D_thick_x = Observable(10.0f0)
    three_view2D_thick_y = Observable(10.0f0)
    three_view2D_thick_z = Observable(10.0f0)

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

    display_2D_3slices(brain, 0.0f0, 0.0f0, 0.0f0, colors_obs, alpha, colormap, datatype, limits, scale_gamma, colorbar_label, fontsize)
    
    pts = [p for tri in brain for p in tri]

    lo_x, hi_x = get_range(1, pts)
    lo_y, hi_y = get_range(2, pts)
    lo_z, hi_z = get_range(3, pts)

    lbl_x     = Label(three_view2D_parent[2, 1][2, 1][1, 1], "X")
    sl_x      = Slider(three_view2D_parent[2, 1][2, 1][1, 2], range = round(lo_x):0.5:hi_x, startvalue = three_view2D_pos_x[])
    connect!(three_view2D_pos_x, sl_x.value)
    lbl_x_var = Label(three_view2D_parent[2, 1][2, 1][1, 3], @lift("$(round($three_view2D_pos_x, digits=3))"), width = 50)
    
    lbl_y     = Label(three_view2D_parent[2, 2][2, 1][1, 1], "Y")
    sl_y      = Slider(three_view2D_parent[2, 2][2, 1][1, 2], range = round(lo_y):0.5:hi_y, startvalue = three_view2D_pos_y[])
    connect!(three_view2D_pos_y, sl_y.value)
    lbl_y_var = Label(three_view2D_parent[2, 2][2, 1][1, 3], @lift("$(round($three_view2D_pos_y, digits=3))"), width = 50)

    lbl_z     = Label(three_view2D_parent[2, 3][2, 1][1, 1], "Z")
    sl_z      = Slider(three_view2D_parent[2, 3][2, 1][1, 2], range = round(lo_z):0.5:hi_z, startvalue = three_view2D_pos_z[])
    connect!(three_view2D_pos_z, sl_z.value)
    lbl_z_var = Label(three_view2D_parent[2, 3][2, 1][1, 3], @lift("$(round($three_view2D_pos_z, digits=3))"), width = 50)

    lbl_three_view2D_thick_x     = Label(three_view2D_parent[2, 1][3, 1][1, 1], "Thickness")
    sl_three_view2D_thick_x      = Slider(three_view2D_parent[2, 1][3, 1][1, 2], range = 0:0.005:150, startvalue = three_view2D_thick_x[])
    connect!(three_view2D_thick_x, sl_three_view2D_thick_x.value)
    lbl_three_view2D_thick_x_var = Label(three_view2D_parent[2, 1][3, 1][1, 3], @lift("$(round($three_view2D_thick_x, digits=3))"), width = 50)
    
    lbl_three_view2D_thick_y     = Label(three_view2D_parent[2, 2][3, 1][1, 1], "Thickness")
    sl_three_view2D_thick_y      = Slider(three_view2D_parent[2, 2][3, 1][1, 2], range = 0:0.005:150, startvalue = three_view2D_thick_y[])
    connect!(three_view2D_thick_y, sl_three_view2D_thick_y.value)
    lbl_three_view2D_thick_y_var = Label(three_view2D_parent[2, 2][3, 1][1, 3], @lift("$(round($three_view2D_thick_y, digits=3))"), width = 50)
    
    lbl_three_view2D_thick_z     = Label(three_view2D_parent[2, 3][3, 1][1, 1], "Thickness")
    sl_three_view2D_thick_z      = Slider(three_view2D_parent[2, 3][3, 1][1, 2], range = 0:0.005:150, startvalue = three_view2D_thick_z[])
    connect!(three_view2D_thick_z, sl_three_view2D_thick_z.value)
    lbl_three_view2D_thick_z_var = Label(three_view2D_parent[2, 3][3, 1][1, 3], @lift("$(round($three_view2D_thick_z, digits=3))"), width = 50)
    
    display_max = Button(three_view2D_parent[1, 2][1, 1], label = "Display max")
    max_coord_lbl = Label(three_view2D_parent[1, 3][1, 1], "x = 0.0  |  y = 0.0  |  z = 0.0")

    colsize!(three_view2D_parent, 1, Relative(0.3))
    colsize!(three_view2D_parent, 2, Relative(0.3))
    colsize!(three_view2D_parent, 3, Relative(0.3))

    push!(three_view2D_widgets, display_max, max_coord_lbl,
        lbl_x, sl_x, lbl_x_var,
        lbl_y, sl_y, lbl_y_var,
        lbl_z, sl_z, lbl_z_var,
        lbl_three_view2D_thick_x, sl_three_view2D_thick_x, lbl_three_view2D_thick_x_var, 
        lbl_three_view2D_thick_y, sl_three_view2D_thick_y, lbl_three_view2D_thick_y_var, 
        lbl_three_view2D_thick_z, sl_three_view2D_thick_z, lbl_three_view2D_thick_z_var)

    on(display_max.clicks) do s
        index = argmax(colors_obs[])
        pos = brain.position
        pt = pos[index]
        x, y, z = Float32(pt[1]), Float32(pt[2]), Float32(pt[3])
        display_2D_3slices(brain, x, y, z, colors_obs, alpha, colormap, datatype, limits, scale_gamma, colorbar_label, fontsize)
        max_coord_lbl.text[] = @sprintf("x = %.3f  |  y = %.3f  |  z = %.3f", x, y, z)
        set_close_to!(sl_x, x)
        set_close_to!(sl_y, y)
        set_close_to!(sl_z, z)
    end
end


# - Side Functions -

"""
Clears the axis if some slices were already displayed
Then calls the function that displays a slice 3 times (one per axis)
"""
function display_2D_3slices(brain, x, y, z, colors_obs, alpha, colormap, datatype, limits, scale_gamma, colorbar_label, fontsize)
    
    global three_view2D_axis, three_view2D_ax_nx, three_view2D_ax_ny, three_view2D_ax_nz, three_view2D_parent
    global three_view2D_pos_x, three_view2D_pos_y, three_view2D_pos_z, three_view2D_thick_x, three_view2D_thick_y, three_view2D_thick_z

    for ax in [three_view2D_ax_nx, three_view2D_ax_ny, three_view2D_ax_nz]
        if ax !== nothing
            try; empty!(ax); catch; end
            try; delete!(ax); catch; end
        end
    end

    three_view2D_pos_x[] = x
    three_view2D_pos_y[] = y
    three_view2D_pos_z[] = z

    three_view2D_ax_nx = display_2D_slice(brain, 1, three_view2D_pos_x, three_view2D_thick_x, three_view2D_parent[2, 1], " x-normal slice", colors_obs, alpha, colormap, datatype, limits, scale_gamma, colorbar_label, fontsize)
    three_view2D_ax_ny = display_2D_slice(brain, 2, three_view2D_pos_y, three_view2D_thick_y, three_view2D_parent[2, 2], "y-normal slice", colors_obs, alpha, colormap, datatype, limits, scale_gamma, colorbar_label, fontsize)
    three_view2D_ax_nz = display_2D_slice(brain, 3, three_view2D_pos_z, three_view2D_thick_z, three_view2D_parent[2, 3], "z-normal slice", colors_obs, alpha, colormap, datatype, limits, scale_gamma, colorbar_label, fontsize)


end


"""
Displays the slice located on "pos" along "axis" in a 2d axis
"""
function display_2D_slice(brain, axis, pos_obs, thick_obs, cell, title, colors_obs, alpha, colormap, datatype, limits, scale_gamma, colorbar_label, fontsize)
   
    global three_view2D_parent, three_view2D_axis, three_view2D_widgets

    azimuth   = axis == 1 ? pi/2  : axis == 2 ? 0.0 : 0.0
    elevation = axis == 3 ? pi/2 : 0.0
    R  = make_view_rotation(azimuth, elevation)
    rb = rotate_mesh_for_view(brain, R)

    clip = @lift begin
        slab = make_2D_slab($pos_obs, abs(axis), $thick_obs)
        rotate_clip_planes(slab, R)
    end

    ax = Axis(cell[1, 1], aspect = DataAspect(), title = title,
                xlabelsize = fontsize,
                ylabelsize = fontsize,
                xticklabelsize = fontsize,
                yticklabelsize = fontsize
                )

    push!(three_view2D_axis, ax)
    
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

    if axis == 3
        cb = Colorbar(three_view2D_parent[2, 3][1, 2],
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

        push!(three_view2D_widgets, cb)
    end

    return ax
end


"""
Clears everything created by the functions above
Puts global variables back to 'nothing' if needed
"""
function clear_2D_3view()
    
    global three_view2D_axis, three_view2D_widgets, three_view2D_parent
    global three_view2D_ax_nx, three_view2D_ax_ny, three_view2D_ax_nz

    try
        try; empty!(three_view2D_axis); catch; end
        try; delete!(three_view2D_axis); catch; end
    

    for w in three_view2D_widgets
        try; delete!(w); catch; end
    end
    

    for ax in [three_view2D_ax_nx, three_view2D_ax_ny, three_view2D_ax_nz]
        if ax !== nothing
            try; empty!(ax); catch; end
            try; delete!(ax); catch; end
        end
    end
    try; delete!(three_view2D_parent); catch; end
    catch;
    end
end
    

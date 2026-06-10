function cortex3D_slice(brain,
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
                    fontsize :: Real = 16.0)
    global moving_slice_blocks, moving_slice_buttons, moving_slice_pos, moving_slice_axis, moving_slice_thick
    global moving_slice_lim_obs

    
    moving_slice_blocks   = nothing   # labels, sliders, ax3d, colorbar
    moving_slice_buttons  = nothing   # axis buttons
    defil_keyboard = nothing   # Observer to be able to disconnect keyboard
    moving_slice_pos  = Observable(0.5f0)      #Observable referring to the position of the slab
    moving_slice_axis   = Observable(1)          #Observable referring to the axis followed by the slab
    moving_slice_thick = Observable(10.0f0)    #Observable referring to the thickness of the slab

    moving_slice_lim_obs = nothing #Used to avoid creating the same variable multiple times

    pts = [p for tri in brain for p in tri]

    #Finding the limit points of the model along each axis
    lo_x, hi_x = get_range(1, pts)
    lo_y, hi_y = get_range(2, pts)
    lo_z, hi_z = get_range(3, pts)
    lo = minimum([lo_x, lo_y, lo_z])
    hi = maximum([hi_x, hi_y, hi_z])

    # - Controls -
    ctrl = parent[2, 1:2] = GridLayout()

    lbl_pos     = Label(ctrl[1, 1], "Position")
    sl_pos      = Slider(ctrl[1, 2], range = lo:0.5:hi, startvalue = (hi + lo) / 2)
    connect!(moving_slice_pos, sl_pos.value)
    lbl_pos_var = Label(ctrl[1, 3], @lift("$(round($moving_slice_pos, digits=3))"), width = 50)

    lbl_thick     = Label(ctrl[2, 1], "Thickness")
    sl_thick      = Slider(ctrl[2, 2], range = 0:0.005:150, startvalue = moving_slice_thick[])
    connect!(moving_slice_thick, sl_thick.value)
    lbl_thick_var = Label(ctrl[2, 3], @lift("$(round($moving_slice_thick, digits=3))"), width = 50)

    # - Axis buttons -
    axis_grid = ctrl[3, 1:3] = GridLayout()
    moving_slice_buttons = Button[]
    for (i, lbl) in enumerate(["X axis", "Y axis", "Z axis"])
        btn = Button(axis_grid[1, i], label = lbl)
        on(btn.clicks) do _; moving_slice_axis[] = i; end
        push!(moving_slice_buttons, btn)
    end

    moving_slice_blocks = [lbl_pos, lbl_pos_var, lbl_thick, lbl_thick_var, sl_pos, sl_thick] 

    # - 3D view -
    display_moving_slice(brain, parent, pts, sl_pos, sl_thick, colormap, J, colors_obs, global_scale, scale_gamma, alpha, datatype, title, colorbar_label, fontsize)
end

# - 3D view construction -
function display_moving_slice(brain, parent, pts, sl_pos, sl_thick, colormap, J, colors_obs, global_scale, scale_gamma, alpha, datatype, title, colorbar_label, fontsize)
    global moving_slice_blocks, defil_keyboard, moving_slice_pos, moving_slice_axis, moving_slice_thick
    global moving_slice_lim_obs

    ax3d = Axis3(parent[1, 1], aspect = :data, title = title,
                    xlabelsize = fontsize,
                    ylabelsize = fontsize,
                    zlabelsize = fontsize,
                    xticklabelsize = fontsize,
                    yticklabelsize = fontsize,
                    zticklabelsize = fontsize
                    )

    #Variable containing two 3dPlanes that define a slice 
    clip = @lift(make_3D_slab($moving_slice_pos, $moving_slice_axis, $moving_slice_thick, pts))

    #Calculating the limits of the colorscale
    limits = global_scale[] ? Observable(get_limits(J, datatype=datatype)) : @lift get_limits($colors_obs, datatype=datatype)
    moving_slice_lim_obs = limits

    mesh!(                  #brain slab anatomy display
        ax3d,
        brain,
        color = RGBf(0.999, 0.999, 0.999),
        clip_planes = clip,
        alpha = alpha,
        backlight = 1.0
    )
    colors_rgba = @lift activation_rgba(
        $colors_obs,        # per-vertex activation values (already indexed by vertex_per_face)
        $colormap,           
        $limits,
        midpoint = $scale_gamma
    )
    mesh!(                  #brain slab activation display
        ax3d,
        brain,
        color        = colors_rgba,
        transparency = true,
        overdraw = true,
        clip_planes = clip
    )

    cb = Colorbar(parent[1, 2],
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

    push!(moving_slice_blocks, ax3d) #Adding the axis and colorbar to the list of blocks
    push!(moving_slice_blocks, cb)   #so we can hide them after

    # - Keyboard navigation
    step = 0.5f0
    defil_keyboard = on(events(f).keyboardbutton) do event
        #If the observables are clear we do nothing
        moving_slice_axis   === nothing && return
        moving_slice_pos  === nothing && return
        moving_slice_thick === nothing && return

        (event.action == Keyboard.press || event.action == Keyboard.repeat) || return
        lo_k, hi_k = get_range(moving_slice_axis[], pts)

        #Setting up the keyboard keys that control the slice movement
        if     event.key == Keyboard.right || event.key == Keyboard.up
            set_close_to!(sl_pos, clamp(moving_slice_pos[] + step, Float32(lo_k), Float32(hi_k)))
        elseif event.key == Keyboard.left  || event.key == Keyboard.down
            set_close_to!(sl_pos, clamp(moving_slice_pos[] - step, Float32(lo_k), Float32(hi_k)))

        #Setting up the keyboard keys that change the axis followed by the slice
        elseif event.key == Keyboard.x;  moving_slice_axis[] = 1
        elseif event.key == Keyboard.y;  moving_slice_axis[] = 2
        elseif event.key == Keyboard.w || event.key == Keyboard.z;  moving_slice_axis[] = 3

        #Setting up the keyboard keys that control the thickness of the slab
        elseif event.key == Keyboard.equal
            set_close_to!(sl_thick, clamp(moving_slice_thick[] + 1.0f0, 0f0, 150f0))
        elseif event.key == Keyboard.minus || event.key == Keyboard._6
            set_close_to!(sl_thick, clamp(moving_slice_thick[] - 1.0f0, 0f0, 150f0))
        end
    end
end


"""
Disconnects the keyboard navigation and clears the blocks created by `init_defil`.
"""
function clear_moving_slice()
    global moving_slice_blocks, moving_slice_buttons, defil_keyboard
    global moving_slice_lim_obs

    # Disconnecting the keyboard navigation
    try;
    if defil_keyboard !== nothing
        try; off(defil_keyboard); catch; end
    end

    if moving_slice_blocks !== nothing
        for blk in moving_slice_blocks
            try; delete!(blk); catch; end
        end
    end

    if moving_slice_buttons !== nothing
        for btn in moving_slice_buttons
            try; delete!(btn); catch; end
        end
    end

    if moving_slice_lim_obs !== nothing
        empty!(moving_slice_lim_obs.listeners)  
    end

    catch;
    end
end




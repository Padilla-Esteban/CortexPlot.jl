function cortex_dashboard(data :: Union{Vector{A}, Matrix{A}};
                        voxels :: Int64 = 2503,
                        alpha :: Real = 1.0,
                        fontsize :: Real = 16.0
                        )where {A<:Real}
    global f
    f          = Figure(backgroundcolor = RGBf(1, 1, 1), size = (1200, 700))
    t_idx      = Observable(1) #Observable referring to the time 
    colormap   = Observable(:solar)
    mode       = Observable(:cortex3D)
    gl_alpha   = Observable(alpha)
    animating  = Observable(false)
    global_scale = Observable(true)

    J = Float32.(data)

    if size(J)[1] == 3*voxels
        J_3d  = reshape(J, 3, voxels, size(J, 2))        
        J     = dropdims(sqrt.(sum(J_3d .^ 2, dims=1)), dims=1)  
    end

    cortex, surf = cortex_and_surf(voxels)

    faces_mat = Int.(surf["Faces"])  

    vertex_per_face = [faces_mat[i,j] for i in 1:size(faces_mat,1) for j in 1:3]
    
    colors_obs = @lift(J[vertex_per_face, $t_idx])
    n = size(J, 1)
    T = size(J, 2)

    datatype = minimum(J)<0 ? :real : :positive #Checking if the J data is positive or real
    scale_gamma = Observable(0.5)

    # - Time slider -
    time_sl = Slider(f[1, 1][2, 1][1, 2], range=1:1:T, startvalue=1)
    connect!(t_idx, time_sl.value)
    time_lbl = Label(f[1, 1][2, 1][1, 3], "Time/frequency:")
    time_lbl_val = Label(f[1, 1][2, 1][1,4], @lift("$($t_idx)"), width = 50)

    # - Alpha slider - 
    lbl_global_alpha    = Label(f[1, 1][2, 2][1, 1],  "Alpha")
    sl_global_alpha      = Slider(f[1, 1][2, 2][1, 2], range = 0:0.1:1, startvalue = alpha)
    connect!(gl_alpha, sl_global_alpha.value)
    lbl_global_alpha_var = Label(f[1, 1][2, 2][1, 3], @lift("$(round($gl_alpha, digits=3))"), width = 50)

    # - Colorscale slider
    lbl_bias     = Label(f[1, 1][2, 2][1, 5], "Color scale")
    sl_bias      = Slider(f[1, 1][2, 2][1, 6], range = 0:0.01:1, startvalue=0.5)
    connect!(scale_gamma, sl_bias.value)
    lbl_bias_val = Label(f[1, 1][2, 2][1, 7], @lift("$(round($scale_gamma, digits=2))"), width=40)

    scale_btn = Button(f[1, 1][2, 2][1, 4], label = @lift($global_scale ? "Global scale" : "Local scale"))
   
    on(scale_btn.clicks) do event 
        global_scale[] = !global_scale[]
        clear_content!()
        content = GridLayout(f[2, 1])
        if mode[] == :cortex3D
            cortex3D(cortex, content, gl_alpha, J, colors_obs, global_scale, scale_gamma, colormap=colormap[], datatype=datatype, fontsize=fontsize)
        elseif mode[] == :cortex3D_slice
            cortex3D_slice(cortex, content, gl_alpha, J, colors_obs, global_scale, scale_gamma, colormap=colormap[], datatype=datatype, fontsize=fontsize)
        elseif mode[] == :cortex3D_3slice
            cortex3D_3slice(cortex, content, J, colors_obs, gl_alpha, global_scale, scale_gamma, colormap=colormap[], datatype=datatype, fontsize=fontsize)
        elseif mode[] == :cortex2D_8view
            cortex2D_8view(cortex, content, J, colors_obs, gl_alpha, global_scale, scale_gamma, colormap = colormap[], datatype=datatype)
        elseif mode[] == :cortex2D_3view
            cortex2D_3view(cortex, content, J, colors_obs, gl_alpha, global_scale, scale_gamma, colormap = colormap[], datatype=datatype, fontsize=fontsize)
        end
    end


    play = Button(f[1, 1][2, 1][1, 1], label = @lift($animating ? "❚❚" : "▶"))
    on(play.clicks) do event 
        animating[] = !animating[]
        if animating[]
            @async while animating[] && isopen(f.scene)
                t_idx[] = mod1(t_idx[] + 1, T) #Time update
                sleep(0.1)                     #Wait 0.1 second to see the animation on the screen
                set_close_to!(time_sl, t_idx[])
            end
        end
    end

    on(events(f.scene).keyboardbutton) do event
        if event.action == Keyboard.press && event.key == Keyboard.p
            animating[] = !animating[]
            if animating[]
                @async while animating[] && isopen(f.scene)
                    t_idx[] = mod1(t_idx[] + 1, T) #Time update
                    sleep(0.1)                     #Wait 0.1 second to see the animation on the screen
                    set_close_to!(time_sl, t_idx[])
                end
            end
        end
    end
    # - Layout of the main window -
    rowsize!(f.layout, 1, Fixed(50))   #menu

    menu = Menu(f[1, 1][1, 1],
                options = ["Cortex3D", "Cortex3D slice", "Cortex3D 3 slice", "Cortex2D 8 view", "Cortex2D 3 view"],
                default = "Cortex3D")

    # - Initial display -
    let content = GridLayout(f[2, 1])
        cortex3D(cortex, content, gl_alpha, J, colors_obs, global_scale, scale_gamma, colormap=colormap[], datatype=datatype, fontsize=fontsize)
    end

    # - Mode switch -
    on(menu.selection) do s
        #cleaning of the scene
        clear_content!()

        #new layout
        content = GridLayout(f[2, 1])

        #selected module call
        if s == "Cortex3D"
            cortex3D(cortex, content, gl_alpha, J, colors_obs, global_scale, scale_gamma, colormap=colormap[], datatype=datatype, fontsize=fontsize)
            mode[] = :cortex3D

        elseif s == "Cortex3D slice"
            cortex3D_slice(cortex, content, gl_alpha, J, colors_obs, global_scale, scale_gamma, colormap=colormap[], datatype=datatype, fontsize=fontsize)
            mode[] = :cortex3D_slice

        elseif s == "Cortex3D 3 slice"
            cortex3D_3slice(cortex, content, J, colors_obs, gl_alpha, global_scale, scale_gamma, colormap=colormap[], datatype=datatype, fontsize=fontsize)
            mode[] = :cortex3D_3slice

        elseif s == "Cortex2D 8 view"
            cortex2D_8view(cortex, content, J, colors_obs, gl_alpha, global_scale, scale_gamma, colormap = colormap[], datatype=datatype)
            mode[] = :cortex2D_8view
        elseif s == "Cortex2D 3 view"
            cortex2D_3view(cortex, content, J, colors_obs, gl_alpha, global_scale, scale_gamma, colormap = colormap[], datatype=datatype, fontsize=fontsize)
            mode[] = :cortex2D_3view
        end
    end

    colormap_menu = Menu(f[1, 1][1, 2], options = ["solar", "redsblues", "magma", "amp"], default = "solar")
    on(colormap_menu.selection) do s
        if s == "magma"
            colormap[] = :magma
        elseif s == "solar"
            colormap[] = :solar
        elseif s == "redsblues"
            colormap[] = :redsblues
        elseif s == "amp"
            colormap[] = :amp
        end
        clear_content!()
        content = GridLayout(f[2, 1])
        if mode[] == :cortex3D
            cortex3D(cortex, content, gl_alpha, J, colors_obs, global_scale, scale_gamma, colormap=colormap[], datatype=datatype, fontsize=fontsize)
        elseif mode[] == :cortex3D_slice
            cortex3D_slice(cortex, content, gl_alpha, J, colors_obs, global_scale, scale_gamma, colormap=colormap[], datatype=datatype, fontsize=fontsize)
        elseif mode[] == :cortex3D_3slice
            cortex3D_3slice(cortex, content, J, colors_obs, gl_alpha, global_scale, scale_gamma, colormap=colormap[], datatype=datatype, fontsize=fontsize)
        elseif mode[] == :cortex2D_8view
            cortex2D_8view(cortex, content, J, colors_obs, gl_alpha, global_scale, scale_gamma, colormap = colormap[], datatype=datatype)
        elseif mode[] == :cortex2D_3view
            cortex2D_3view(cortex, content, J, colors_obs, gl_alpha, global_scale, scale_gamma, colormap = colormap[], datatype=datatype, fontsize=fontsize)
        end
    end

    f
end

function cortex_plot(data :: Union{Vector{A}, Matrix{A}};
                    voxels :: Int64 = 2503,
                    alpha :: Real = 1.0,
                    mode :: Symbol = :cortex3D,
                    fontsize :: Real = 16.0)where {A<:Real}
    global f
    f          = Figure(backgroundcolor = RGBf(1, 1, 1), size = (1200, 700))
    t_idx      = Observable(1) #Observable referring to the time 
    colormap   = Observable(:solar)
    gl_alpha   = Observable(alpha)
    animating  = Observable(false)
    global_scale = Observable(true)
    
    J = Float32.(data)

    if size(J)[1] == 3*voxels
        J_3d  = reshape(J, 3, voxels, size(J, 2))        
        J     = dropdims(sqrt.(sum(J_3d .^ 2, dims=1)), dims=1)  
    end

    cortex, surf = cortex_and_surf(voxels)
 
    faces_mat = Int.(surf["Faces"])  

    vertex_per_face = [faces_mat[i,j] for i in 1:size(faces_mat,1) for j in 1:3]

    colors_obs = @lift(J[vertex_per_face, $t_idx])
    n = size(J, 1)
    T = size(J, 2)

    datatype = minimum(J)<0 ? :real : :positive #Checking if the J data is positive or real
    scale_gamma = Observable(0.5)

    time_sl = Slider(f[1, 1][2, 1][1, 2], range=1:1:T, startvalue=1)
    connect!(t_idx, time_sl.value)
    time_lbl = Label(f[1, 1][2, 1][1, 3], "Time:")
    time_lbl_val = Label(f[1, 1][2, 1][1,4], @lift("$($t_idx)"), width = 50)

    lbl_global_alpha    = Label(f[1, 1][2, 2][1, 1],  "Alpha")
    sl_global_alpha      = Slider(f[1, 1][2, 2][1, 2], range = 0:0.1:1, startvalue = alpha)
    connect!(gl_alpha, sl_global_alpha.value)
    lbl_global_alpha_var = Label(f[1, 1][2, 2][1, 3], @lift("$(round($gl_alpha, digits=3))"), width = 50)

    # - Colorscale slider
    lbl_bias     = Label(f[1, 1][1, 2][1, 2], "Color scale")
    sl_bias      = Slider(f[1, 1][1, 2][1, 3], range = 0:0.01:1, startvalue=0.5)
    connect!(scale_gamma, sl_bias.value)
    lbl_bias_val = Label(f[1, 1][1, 2][1, 4], @lift("$(round($scale_gamma, digits=2))"), width=40)

    scale_btn = Button(f[1, 1][1, 2][1, 1], label = @lift($global_scale ? "Global scale" : "Local scale"))
   
    on(scale_btn.clicks) do event 
        global_scale[] = !global_scale[]
        clear_content!()
        content = GridLayout(f[2, 1])
        if mode == :cortex3D
            cortex3D(cortex, content, gl_alpha, J, colors_obs, global_scale, scale_gamma, colormap=colormap[], datatype=datatype, fontsize=fontsize)
        elseif mode == :cortex3D_slice
            cortex3D_slice(cortex, content, gl_alpha, J, colors_obs, global_scale, scale_gamma, colormap=colormap[], datatype=datatype, fontsize=fontsize)
        elseif mode == :cortex3D_3slice
            cortex3D_3slice(cortex, content, J, colors_obs, gl_alpha, global_scale, scale_gamma, colormap=colormap[], datatype=datatype, fontsize=fontsize)
        elseif mode == :cortex2D_8view
            cortex2D_8view(cortex, content, J, colors_obs, gl_alpha, global_scale, scale_gamma, colormap = colormap[], datatype=datatype)
        elseif mode == :cortex2D_3view
            cortex2D_3view(cortex, content, J, colors_obs, gl_alpha, global_scale, scale_gamma, colormap = colormap[], datatype=datatype, fontsize=fontsize)
        end
    end

    play = Button(f[1, 1][2, 1][1, 1], label = @lift($animating ? "❚❚" : "▶"))
    on(play.clicks) do event 
        animating[] = !animating[]
        if animating[]
            @async while animating[] && isopen(f.scene)
                t_idx[] = mod1(t_idx[] + 1, T) #Time update
                sleep(0.1)                     #Wait 0.1 second to see the animation on the screen
                set_close_to!(time_sl, t_idx[])
            end
        end
    end

    on(events(f.scene).keyboardbutton) do event
        if event.action == Keyboard.press && event.key == Keyboard.p
            animating[] = !animating[]
            if animating[]
                @async while animating[] && isopen(f.scene)
                    t_idx[] = mod1(t_idx[] + 1, T) #Time update
                    sleep(0.1)                     #Wait 0.1 second to see the animation on the screen
                    set_close_to!(time_sl, t_idx[])
                end
            end
        end
    end
    content = GridLayout(f[2, 1])
    if mode === :cortex3D
        cortex3D(cortex, content, gl_alpha, J, colors_obs, global_scale, scale_gamma, datatype=datatype, fontsize = fontsize)
    elseif mode === :cortex3D_slice
        cortex3D_slice(cortex, content, gl_alpha, J, colors_obs, global_scale, scale_gamma, datatype=datatype, fontsize = fontsize)
    elseif mode === :cortex3D_3slice
        cortex3D_3slice(cortex, content, J, colors_obs, gl_alpha, global_scale, scale_gamma, datatype=datatype, fontsize = fontsize)
    elseif mode === :cortex2D_8view
        cortex2D_8view(cortex, content, J, colors_obs, gl_alpha, global_scale, scale_gamma, datatype=datatype)
    elseif mode === :cortex2D_3view
        cortex2D_3view(cortex, content, J,colors_obs, gl_alpha, global_scale, scale_gamma, datatype=datatype, fontsize = fontsize)
    end

    colormap_menu = Menu(f[1, 1][1, 1], options = ["solar", "redsblues", "magma", "amp"], default = "solar")
    on(colormap_menu.selection) do s
        if s == "magma"
            colormap[] = :magma
        elseif s == "solar"
            colormap[] = :solar
        elseif s == "redsblues"
            colormap[] = :redsblues
        elseif s == "amp"
            colormap[] = :devon100
        end
        clear_content!()
        content = GridLayout(f[2, 1])
        if mode == :cortex3D
            cortex3D(cortex, content, gl_alpha, J, colors_obs, global_scale, scale_gamma, colormap=colormap[], datatype=datatype, fontsize=fontsize)
        elseif mode == :cortex3D_slice
            cortex3D_slice(cortex, content, gl_alpha, J, colors_obs, global_scale, scale_gamma, colormap=colormap[], datatype=datatype, fontsize=fontsize)
        elseif mode == :cortex3D_3slice
            cortex3D_3slice(cortex, content, J, colors_obs, gl_alpha, global_scale, scale_gamma, colormap=colormap[], datatype=datatype, fontsize=fontsize)
        elseif mode == :cortex2D_8view
            cortex2D_8view(cortex, content, J, colors_obs, gl_alpha, global_scale, scale_gamma, colormap = colormap[], datatype=datatype)
        elseif mode == :cortex2D_3view
            cortex2D_3view(cortex, content, J, colors_obs, gl_alpha, global_scale, scale_gamma, colormap = colormap[], datatype=datatype, fontsize=fontsize)
        end
    end

    f
end

# - Scene clearing -
"""
    clear_content!()

Clears the blocks in the f[2,1] space
(axes, colorbars, GridLayouts) then resize the parent layout.
Puts back to `nothing` all the globals.
"""
function clear_content!()
    global f
    #cleaning specific to each module
    clear_cortex3D()
    clear_moving_slice()
    clear_3slice()
    clear_8view()
    clear_3view()

    #clearing the [2, 1] cell if it exists
    try
        delete!(f[2, 1])
    catch
    end
    trim!(f.layout)
end


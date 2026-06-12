function cortex_dashboard(data :: Union{Vector{A}, Matrix{A}};
                        voxels :: Int64 = 2503,
                        alpha :: Real = 1.0,
                        title :: String = "Brain activation",
                        colorbar_label :: String = "Current density square module",
                        fontsize :: Real = 16.0,
                        colorscheme :: Symbol = :rain
                        )where {A<:Real}
    global f
    f          = Figure(backgroundcolor = RGBf(1, 1, 1), size = (1200, 700))
    t_idx      = Observable(1) #Observable referring to the time 
    colormap   = Observable(colorscheme)
    mode       = Observable(:Cortex3D)
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
    scale_gamma = Observable(0.75)

    # White bar

    white_bar = Label(f[1, 1][1, 1:2], "  ")
    rowsize!(f[1, 1].layout, 1, Fixed(30))

    # - Time slider -
    time_sl = Slider(f[1, 1][3, 1][1, 2], range=1:1:T, startvalue=1)
    connect!(t_idx, time_sl.value)
    time_lbl = Label(f[1, 1][3, 1][1, 3], "Frame:")
    time_lbl_val = Label(f[1, 1][3, 1][1,4], @lift("$($t_idx)"), width = 50)

    # - Alpha slider - 
    lbl_global_alpha    = Label(f[1, 1][3, 2][1, 1],  "Alpha")
    sl_global_alpha      = Slider(f[1, 1][3, 2][1, 2], range = 0:0.1:1, startvalue = alpha)
    connect!(gl_alpha, sl_global_alpha.value)
    lbl_global_alpha_var = Label(f[1, 1][3, 2][1, 3], @lift("$(round($gl_alpha, digits=3))"), width = 50)

    # - Colorscale slider
    lbl_bias     = Label(f[1, 1][3, 2][1, 4], "Color scale")
    sl_bias      = Slider(f[1, 1][3, 2][1, 5], range = 0:0.01:1, startvalue=scale_gamma[])
    connect!(scale_gamma, sl_bias.value)
    lbl_bias_val = Label(f[1, 1][3, 2][1, 6], @lift("$(round($scale_gamma, digits=2))"), width=40)

    scale_menu = Menu(f[1, 1][2, 2][1, 2], options= ["Global Scale", "Local Scale"], default="Global Scale")
   
    on(scale_menu.selection) do event 
        global_scale[] = event == "Global Scale" ? true : false
    end


    play = Button(f[1, 1][3, 1][1, 1], label = @lift($animating ? "❚❚" : "▶"))
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
        elseif event.key == Keyboard.left && event.action == Keyboard.press
            t_idx[] = mod1(t_idx[] - 1, T)
            set_close_to!(time_sl, t_idx[])
        elseif event.key == Keyboard.right && event.action == Keyboard.press
            t_idx[] = mod1(t_idx[] + 1, T)
            set_close_to!(time_sl, t_idx[])
        end
    end

    # - Layout of the main window -
    rowsize!(f.layout, 1, Fixed(50))   #menu

    menu = Menu(f[1, 1][2, 1],
                options = ["Cortex3D", "Cortex3D_slice", "Cortex3D_3_view", "Cortex2D_8_view", "Cortex2D_3_view"],
                default = "Cortex3D")

    # - Initial display -
    let content = GridLayout(f[2, 1])
        cortex3D(cortex, content, gl_alpha, J, colors_obs, global_scale, scale_gamma, colormap, datatype=datatype, title=title, colorbar_label=colorbar_label, fontsize=fontsize)
    end

    # - Mode switch -
    on(menu.selection) do s
        #cleaning of the scene
        mode[] = Symbol(s)
        clear_content!()

        #new layout
        content = GridLayout(f[2, 1])

        #selected module call
        if mode[] == :Cortex3D
            cortex3D(cortex, content, gl_alpha, J, colors_obs, global_scale, scale_gamma, colormap, datatype=datatype, title=title, colorbar_label=colorbar_label, fontsize=fontsize)
        elseif mode[] == :Cortex3D_slice
            cortex3D_slice(cortex, content, gl_alpha, J, colors_obs, global_scale, scale_gamma, colormap, datatype=datatype, title=title, colorbar_label=colorbar_label, fontsize=fontsize)
        elseif mode[] == :Cortex3D_3_view
            cortex3D_3view(cortex, content, J, colors_obs, gl_alpha, global_scale, scale_gamma, colormap, datatype=datatype, title=title, colorbar_label=colorbar_label, fontsize=fontsize)
        elseif mode[] == :Cortex2D_8_view
            cortex2D_8view(cortex, content, J, colors_obs, gl_alpha, global_scale, scale_gamma, colormap, datatype=datatype, colorbar_label=colorbar_label, fontsize=fontsize)
        elseif mode[] == :Cortex2D_3_view
            cortex2D_3view(cortex, content, J, colors_obs, gl_alpha, global_scale, scale_gamma, colormap, datatype=datatype, colorbar_label=colorbar_label, fontsize=fontsize)
        end
    end

    colormap_list = ["rain", "magma", "bilbao", "solar", "roma", "broc", "redsblues", "vik"]
    if !(String(colorscheme) in colormap_list)
        push!(colormap_list, String(colorscheme))
    end    
    
    colormap_menu = Menu(f[1, 1][2, 2][1, 1], options = colormap_list, default = String(colorscheme))
    on(colormap_menu.selection) do s
        colormap[] = Symbol(s)
    end

    f
end

function cortex_plot(data :: Union{Vector{A}, Matrix{A}};
                    voxels :: Int64 = 2503,
                    alpha :: Real = 1.0,
                    mode :: Symbol = :Cortex3D,
                    title :: String = "Brain activation",
                    colorbar_label :: String = "Current density square module",
                    colorscheme:: Symbol = :rain,
                    fontsize :: Real = 16.0)where {A<:Real}
    global f
    f          = Figure(backgroundcolor = RGBf(1, 1, 1), size = (1200, 700))
    t_idx      = Observable(1) #Observable referring to the time 
    colormap   = Observable(colorscheme)
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
    scale_gamma = Observable(0.75)

    white_bar = Label(f[1, 1][1, 1:2], "  ", tellwidth = false, tellheight = true)
    rowsize!(f[1, 1].layout, 1, Fixed(30))

    time_sl = Slider(f[1, 1][3, 1][1, 2], range=1:1:T, startvalue=1)
    connect!(t_idx, time_sl.value)
    time_lbl = Label(f[1, 1][3, 1][1, 3], "Frame:")
    time_lbl_val = Label(f[1, 1][3, 1][1,4], @lift("$($t_idx)"), width = 50)

    lbl_global_alpha    = Label(f[1, 1][3, 2][1, 1],  "Alpha")
    sl_global_alpha      = Slider(f[1, 1][3, 2][1, 2], range = 0:0.1:1, startvalue = alpha)
    connect!(gl_alpha, sl_global_alpha.value)
    lbl_global_alpha_var = Label(f[1, 1][3, 2][1, 3], @lift("$(round($gl_alpha, digits=3))"), width = 50)

    # - Colorscale slider
    lbl_bias     = Label(f[1, 1][2, 2][1, 2], "Color scale")
    sl_bias      = Slider(f[1, 1][2, 2][1, 3], range = 0:0.01:1, startvalue=scale_gamma[])
    connect!(scale_gamma, sl_bias.value)
    lbl_bias_val = Label(f[1, 1][2, 2][1, 4], @lift("$(round($scale_gamma, digits=2))"), width=40)

    scale_menu = Menu(f[1, 1][2, 2], options= ["Global Scale", "Local Scale"], default="Global Scale")
   
    on(scale_menu.selection) do event 
        global_scale[] = event == "Global Scale" ? true : false
    end

    play = Button(f[1, 1][3, 1][1, 1], label = @lift($animating ? "❚❚" : "▶"))
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
        elseif event.key == Keyboard.left && event.action == Keyboard.press
            t_idx[] = mod1(t_idx[] - 1, T)
            set_close_to!(time_sl, t_idx[])
        elseif event.key == Keyboard.right && event.action == Keyboard.press
            t_idx[] = mod1(t_idx[] + 1, T)
            set_close_to!(time_sl, t_idx[])
        end
    end
    
    content = GridLayout(f[2, 1])
    if mode === :Cortex3D
        cortex3D(cortex, content, gl_alpha, J, colors_obs, global_scale, scale_gamma, colormap,datatype=datatype, title=title, fontsize = fontsize)
    elseif mode === :Cortex3D_slice
        cortex3D_slice(cortex, content, gl_alpha, J, colors_obs, global_scale, scale_gamma, colormap, datatype=datatype, title=title, fontsize = fontsize)
    elseif mode === :Cortex3D_3view
        cortex3D_3view(cortex, content, J, colors_obs, gl_alpha, global_scale, scale_gamma, colormap, datatype=datatype, title=title, fontsize = fontsize)
    elseif mode === :Cortex2D_8view
        cortex2D_8view(cortex, content, J, colors_obs, gl_alpha, global_scale, scale_gamma, colormap, datatype=datatype, colorbar_label=colorbar_label, fontsize=fontsize)
    elseif mode === :Cortex2D_3view
        cortex2D_3view(cortex, content, J,colors_obs, gl_alpha, global_scale, scale_gamma, colormap, datatype=datatype, fontsize = fontsize)
    end

    colormap_list = ["rain", "magma", "bilbao", "solar", "roma", "broc", "redsblues", "vik"]
    if !(String(colorscheme) in colormap_list)
        push!(colormap_list, String(colorscheme))
    end    
    
    colormap_menu = Menu(f[1, 1][2, 1], options = colormap_list, default = String(colorscheme))
    on(colormap_menu.selection) do s
        colormap[] = Symbol(s)
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
    clear_3D_3view()
    clear_8view()
    clear_2D_3view()

    #clearing the [2, 1] cell if it exists
    try
        delete!(f[2, 1])
    catch
    end
    trim!(f.layout)
end


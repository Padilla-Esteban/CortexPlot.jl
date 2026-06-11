"""
ax: axis along which we want to find the range
pts: array containing all the points of the brain model 

Returns the position of the extrema points of the brain along the axis ax.
"""
function get_range(ax :: Int,
                    pts :: Vector{Point{3, Float32}})
    
    return (minimum(p[ax] for p in pts), maximum(p[ax] for p in pts))
end


"""
pos: position of the center of the wanted slab along the axis ax
ax: axis normal to the wanted slab (1 for x, 2 for y, 3 for z)
thickness: thickness of the wanted slab
pts: array containing all the points of the brain model 
Returns a couple of parallel planes located in pos-thickness/2 and pos+thickness/2 along the axis ax
The couple of planes can then be used as clip_planes in a mesh! call 
to mesh a section of the brain located between the two planes.
"""
function make_3D_slab(pos :: Real, 
                        ax:: Int, 
                        thickness :: Real, 
                        pts :: Vector{Point{3, Float32}})    
    ranges     = [get_range(i, pts) for i in 1:3]
    centers    = [(lo + hi) / 2f0 for (lo, hi) in ranges]
    half_exts  = [(hi - lo) / 2f0 for (lo, hi) in ranges]
    global_half = maximum(half_exts)  
    #we must take the maximum because makie normalizes the coordinates following the largest axis
    #so if we normalize independatly, only the sections following the largest axis will be nicely displayed

    pos_n  = (pos - centers[ax]) / global_half
    half_n = (thickness / 2f0)  / global_half

    normal = ax == 1 ? Vec3f(1,0,0) : ax == 2 ? Vec3f(0,1,0) : Vec3f(0,0,1)
    return [Plane3f( normal,  pos_n - half_n),
            Plane3f(-normal, -(pos_n + half_n))]
end


"""
Does the same thing than make_3D_slab but for Axis objects (2D) instead of Axis3 objects (3D)
"""
function make_2D_slab(pos :: Real, 
                        ax :: Int, 
                        thickness :: Real)   
    half   = thickness / 2
    normal = ax == 1 ? Vec3f(1,0,0) : ax == 2 ? Vec3f(0,1,0) : Vec3f(0,0,1)
    return [Plane3f( normal,  pos - half),   # show where axis_coord >= pos-half
            Plane3f(-normal, -(pos + half))] # show where axis_coord <= pos+half
end


"""
    Returns two 'Plane3f' defining a section between 'start' and 'stop'
    along 'axis' (1=X, 2=Y, 3=Z). The 'axis' sign inverts the normal vector.
    """
function section(start :: Real, 
                    stop :: Real, 
                    axis :: Int)
    normal = abs(axis) == 1 ? Vec3f(1,0,0) :
             abs(axis) == 2 ? Vec3f(0,1,0) :
                             Vec3f(0,0,1)
    if axis < 0; normal = -normal; end
    return [Plane3f( normal,  Float32(start)),
            Plane3f(-normal, -Float32(stop))]
end


"""
Returns a 3×3 Float32 rotation matrix that maps world-space → camera-space
to match Makie's Axis3 azimuth/elevation convention.
"""
function make_view_rotation(azimuth :: Real, 
                            elevation :: Real)
    az = Float64(azimuth)
    el = Float64(elevation)

    # Unit vector from scene centre toward the camera
    cam = Vec3f(sin(az)*cos(el), cos(az)*cos(el), sin(el))
    fwd = normalize(-cam)          # direction the camera looks (toward origin)

    if abs(abs(el) - π/2) > 1e-5  # generic case: Z-up is not parallel to fwd
        rgt = Vec3f(normalize(cross(Vec3f(0f0, 0f0, 1f0), fwd)))
    else                           # gimbal lock (top / bottom view)
        rgt = Vec3f(cos(az), -sin(az), 0f0)
    end

    upv = Vec3f(normalize(cross(fwd, rgt)))

    return Float32[ rgt[1]   rgt[2]   rgt[3] ;
                    upv[1]   upv[2]   upv[3] ;
                   -fwd[1]  -fwd[2]  -fwd[3] ]
end



"""
New mesh whose vertices are `R * p` for every original vertex `p`.
Face connectivity is unchanged, so per-vertex colours still line up.
"""
function rotate_mesh_for_view(mesh3d, 
                            R :: Matrix{Float32})
    pts     = decompose(Point3f, mesh3d)
    new_pts = Point3f[Point3f(R * Float32[p[1], p[2], p[3]]) for p in pts]
    fs      = decompose(TriangleFace{Int}, mesh3d)
    return GeometryBasics.Mesh(new_pts, fs)
end


"""
Rotate plane normals by `R`; distances are invariant under rotation
(because dot(Rn, Rp) = dot(n, p) for orthogonal R).
"""
function rotate_clip_planes(planes :: Vector{Plane3f}, 
                            R :: Matrix{Float32})
    [Plane3f(Vec3f(R * [p.normal[1], p.normal[2], p.normal[3]]), p.distance)
     for p in planes]
end


"""
Convert a vector of per-vertex activation values into RGBA colors, where the
RGB channels are determined by a colormap and the alpha channel encodes the
activation strength (0 = fully transparent, 1 = fully opaque).

This is intended to be used as an overlay on top of a uniform gray anatomy mesh:
low-activation vertices will appear transparent (revealing the gray underneath),
while high-activation vertices will appear as the corresponding colormap color.

Args:
values: per-vertex activation values 
cmap_name: name of the colormap to use
vmin: minimum value of the activation range (used for normalization)
vmax: maximum value of the activation range (used for normalization)

Returns:
A Vector{RGBAf} of length length(values), one RGBA color per vertex.
"""
function activation_rgba(values, cmap_name, limits; midpoint=0.5f0)
    vmin = limits[1]
    vmax = limits[2]
    # Normalize values to [0, 1] relative to the activation range.
    normalized = clamp.((values .- vmin) ./ (vmax - vmin), 0f0, 1f0)

    γ = log(0.5f0) / log(clamp(midpoint, 0.001f0, 0.999f0))
    warped = normalized .^ γ

    # Convert the colormap name into a concrete vector of RGBAf colors.
    cmap = apply_colormap(cmap_name)


    n = length(cmap)

    # Build one RGBAf color per vertex.
    return [
        let
            # Map the normalized value in [0, 1] to a colormap index in [1, n].
            idx = clamp(round(Int, w * (n - 1)) + 1, 1, n)

            c = cmap[idx]

            # Build the final RGBA color
            RGBAf(c.r, c.g, c.b, w)
        end
        for w in warped   # iterate over each per-vertex normalized activation value
    ]
end

function apply_colormap(cmap_name::Symbol)
    NOT_REVERSED_COLORMAPS = Set([:rain, :vik, :broc])
    return cmap_name in NOT_REVERSED_COLORMAPS ? to_colormap(cmap_name) : to_colormap(Reverse(cmap_name))
end


function get_limits(data :: Union{Vector{Float32}, Matrix{Float32}};
                    datatype :: Symbol = :positive)
    if datatype === :positive
        return (0, maximum(data))
    else
        return (-maximum(abs, data), maximum(abs, data))
    end
end

function cortex_and_surf(voxels::Int = 2503)

    list_of_voxels = [2503, 5002]
    #  you can adapt this list if you add some ressources

    voxels in list_of_voxels|| throw(ArgumentError("voxels argument has to be in $list_of_voxels"))

    leadfields_root = dirname(dirname(pathof(Leadfields)))

    cortex = load(joinpath(leadfields_root, "Meshes", "cortex_$voxels.stl"))
    surf = matread(joinpath(leadfields_root, "Meshes", "tess_cortex_pial_low_$voxels.mat"))

    return (cortex, surf)

end



#Function used to update the colorbar scale when moving the colormap scale
function warped_cmap(colormap, mid)
    γ = log(0.5f0) / log(clamp(Float32(mid), 0.001f0, 0.999f0))
    cmap = apply_colormap(colormap)
    n = length(cmap)
    return [cmap[clamp(round(Int, ((i-1)/(n-1))^γ * (n-1)) + 1, 1, n)] for i in 1:n]
end
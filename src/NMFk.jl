module NMFk

import NMF
import Distances
import Clustering
import JuMP
import Ipopt
import JLD

include("NMFkCluster.jl")
include("NMFkGeoChem.jl")
include("NMFkMixMatch.jl")
include("NMFkIpopt.jl")
include("NMFkMatrix.jl")
include("NMFkExecute.jl")
include("NMFkFinalize.jl")

end
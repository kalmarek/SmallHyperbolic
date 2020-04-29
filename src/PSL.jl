using RamanujanGraphs
using RamanujanGraphs.LightGraphs
using Arpack

Γ, eigenvalues = let q = 109
      a = RamanujanGraphs.PSL₂{q}([  0  1
                                   108 11])
      b = RamanujanGraphs.PSL₂{q}([57  2
                                   52 42])

      S = unique([[a^i for i in 1:4]; [b^i for i in 1:4]])

      @info "Generating set S of $(eltype(S))" S
      @time Γ, verts, vlabels, elabels = RamanujanGraphs.cayley_graph((q^3 - q)÷2, S)
      @assert all(degree(Γ,i) == length(S) for i in vertices(Γ))
      A = adjacency_matrix(Γ)
      @time eigenvalues, _ = eigs(A, nev=5)
      @show Γ eigenvalues
end

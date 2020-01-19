using JLD
using DelimitedFiles

abstract type WordReduction end
struct KnuthBendix <: WordReduction end
struct AutomaticStructure <: WordReduction end

const GAP_EXECUTABLE = get(ENV, "GAP_EXECUTABLE", "gap")

const PRODUCT_MATRIX_FUNCTIONS = """
MetricBalls := function(rws, radius)
    local l, basis, sizes, i;
    l := EnumerateReducedWords(rws, 0, radius);;
    SortBy(l, Length);
    sizes := [1..radius];
    Apply(sizes, i -> Number(l, w -> Length(w) <= i));
    return [l, sizes];
end;;

MetricBalls := function(rws, gens, radius)
    local elts, sgens, sizes, r, RwsReducedProduct;
    RwsReducedProduct := function(x, y) return ReducedForm(rws, x*y); end;

    elts := Union([Identity(gens[1])], gens);
    sgens := elts;
    sizes := [1, Length(elts)];
    for r in [2..radius] do;
        elts := SetX(elts, sgens, RwsReducedProduct);
        Add(sizes, Length(elts));
        if sizes[Length(sizes)] = sizes[Length(sizes)-1] then
            break;
        fi;
    od;

    return [elts, sizes{[2..Length(sizes)]}];
end;;

ProductMatrix := function(rws, basis, len)
    local result, dict, g, tmpList, t;
    result := [];
    dict := NewDictionary(basis[1], true);
    t := Runtime();
    for g in [1..Length(basis)] do;
        AddDictionary(dict, basis[g], g);
    od;
    Print("Creating dictionary: \t\t", StringTime(Runtime()-t), "\\n");
    for g in basis{[1..len]} do;
        tmpList := List(Inverse(g)*basis{[1..len]}, w->ReducedForm(rws, w));
        #t := Runtime();
        tmpList := List(tmpList, x -> LookupDictionary(dict, x));
        #Print(Runtime()-t, "\\n");
        Assert(1, ForAll(tmpList, x -> x <> fail));
        Add(result, tmpList);
    od;
    return result;
end;;

SaveCSV := function(fname, pm)
   local file, i, j, k;
   file := OutputTextFile(fname, false);;
   for i in pm do;
      k := 1;
      for j in i do;
         if k < Length(i) then
            AppendTo(file, j, ", ");
         else
            AppendTo(file, j, "\\n");
         fi;
         k := k+1;
      od;
   od;
   CloseStream(file);
end;;
"""

function product_matrix_GAP_code(reduction::Type{<:WordReduction},
    G::FPGroup, dir, halfradius; maxeqns=100_000, infolevel=2)
    code = """
LogTo("$(dir)/GAP.log");
RequirePackage("kbmag");
SetInfoLevel(InfoRWS, $infolevel);

$PRODUCT_MATRIX_FUNCTIONS
$(GAP_code(G))

# G:= SimplifiedFpGroup(G);
rws := KBMAGRewritingSystem(G);
# ResetRewritingSystem(rws);
O:=OptionsRecordOfKBMAGRewritingSystem(rws);;
O.maxeqns := $maxeqns;
O.maxstates := 1000*$maxeqns;
#O.maxstoredlen := [100,100];

before := Runtimes();;
$reduction(rws);
after := Runtimes();;
delta := after.user_time_children - before.user_time_children;;
Print("$reduction time: \t", StringTime(delta), "\\n");

t := Runtime();;

A := MetricBalls(rws, [a,b,a^-1,b^-1], 10);;
B := MetricBalls(rws, [b,c,b^-1,c^-1], 10);;
C := MetricBalls(rws, [c,a,c^-1,a^-1], 10);;
S := Union(A[1], B[1], C[1]);;
S := Difference(S, [Identity(F)]);;
Print("Sizes of generated subgroups: \\n", [A[2], B[2], C[2]], "\\n");

res := MetricBalls(rws, S, $(2halfradius));;
Print("Metric-Balls generation: \t", StringTime(Runtime()-t), "\\n");
B := res[1];;
sizes := res[2];;
Print("Sizes of generated Balls: \t", sizes, "\\n");

SortBy(B,
function(x)
    if x = Identity(F) then;
        return 0;
    elif x in S then;
        return Position(S,x);
    fi;
    return Length(S)+Length(x);
end);;

t := Runtime();;
pm := ProductMatrix(rws, B, sizes[$halfradius]);;
Print("Computing ProductMatrix: \t", StringTime(Runtime()-t), "\\n");

# S := EnumerateReducedWords(rws, 1, 1);
S_positions := List(S, s -> Position(B,s));

SaveCSV("$(dir)/pm.csv", pm);
SaveCSV("$(dir)/S.csv", [S_positions]);
SaveCSV("$(dir)/sizes.csv", [sizes]);
SaveCSV("$(dir)/B_$(2halfradius).csv", [B]);

Print("DONE!\\n");

quit;""";
    return code
end

function GAP_code(G::FPGroup)
    S = gens(G);
    rels = [k*inv(v) for (k,v) in G.rels]
    F = "FreeGroup("*join(["\"$v\"" for v in S], ", ") *");"
    m = match(r".*(\[.*\])$", string(rels))
    rels_gap = replace(m.captures[1], " "=>"\n")

    gap_code = """
    F := $F;
    AssignGeneratorVariables(F);;
    relations := $rels_gap;;
    G := F/relations;
    """
    return gap_code
end

function GAP_execute(gap_code, dir)
    isdir(dir) || mkpath(dir)
    GAP_file = joinpath(dir, "GAP_code.g")
    @info "Writing GAP code to $GAP_file"

    open(GAP_file, "w") do io
        write(io, gap_code)
    end
    run(pipeline(`cat $(GAP_file)`, `$GAP_EXECUTABLE -q`))
end

function prepare_pm_delta_csv(reduction::Type{<:WordReduction},
    G::FPGroup, name::AbstractString, halfradius::Integer; kwargs...)

    @info "Preparing multiplication table using GAP (via kbmag)"
    gap_code = product_matrix_GAP_code(reduction, G, name, halfradius; kwargs...)
    return GAP_execute(gap_code, name)
end

function prepare_pm_delta(reduction::Type{<:WordReduction},
    G::FPGroup, name::AbstractString, halfradius::Integer; kwargs...)
    pm_fname = joinpath(name, "pm.csv")
    S_fname = joinpath(name, "S.csv")
    sizes_fname = joinpath(name, "sizes.csv")
    delta_fname = joinpath(name, "delta.jld")

    csv_files_exist = isfile(pm_fname) && isfile(S_fname) && isfile(sizes_fname)

    if !csv_files_exist
        @info "Creating csv files"
        prepare_pm_delta_csv(reduction, G, name, halfradius; kwargs...)
    elseif isfile(sizes_fname)
        sizes = readdlm(sizes_fname, ',')[1,:]
        if 2halfradius > length(sizes)
            prepare_pm_delta_csv(reduction, G, name, halfradius; kwargs...)
        end
    end

    @assert isfile(pm_fname) && isfile(S_fname) && isfile(sizes_fname)

    @info "Reading csv files"
    pm = Int.(readdlm(pm_fname, ','))
    S = Int.(readdlm(S_fname, ',')[1,:])
    sizes = Int.(readdlm(sizes_fname, ',')[1,:])

    Δ = spzeros(Int, sizes[2halfradius])
    Δ[S] .= -1
    Δ[1] = length(S)

    pm = pm[1:sizes[halfradius], 1:sizes[halfradius]]
    @info "Writing delta.jld for radius $(2halfradius)"
    save(joinpath(name, "delta.jld"), "coeffs", Δ, "pm", pm)
end

function prepare_pm_delta(G::FPGroup, dir, halfradius; kwargs...)
    return prepare_pm_delta(KnuthBendix, G, dir, halfradius; kwargs... )
end

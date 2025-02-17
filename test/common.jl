function all_gens_on(result)
    # tolerance of 1e-5 is needed for SCS tests to pass
    return minimum([gen["gen_status"] for (i,gen) in result["solution"]["gen"]]) >= 1.0 - 1e-5
end

function active_power_served(result)
    return sum([load["pd"] for (i,load) in result["solution"]["load"]])
end

function all_voltages_on(result)
    return return minimum([bus["status"] for (i,bus) in result["solution"]["bus"]]) >= 1.0 - 1e-3 #(note, non-SCS solvers are more accurate)
end


# helper functions to access solutions by their OpenDSS names
bus_name2id(pmd_data, name) = [bus["index"] for (_,bus) in pmd_data["bus"] if haskey(bus, "name") && bus["name"]==name][1]
va(sol, pmd_data, name) = PMD._wrap_to_pi(sol["solution"]["bus"][string(bus_name2id(pmd_data, name))]["va"][:])*180/pi
vm(sol, pmd_data, name) = sol["solution"]["bus"][string(bus_name2id(pmd_data, name))]["vm"]
tap(i, pm) = JuMP.value.(PMD.var(pm, InfrastructureModels.nw_id_default, :tap)[i])
vi(sol, pmd_data, name) = sol["solution"]["bus"][string(bus_name2id(pmd_data, name))]["vi"]
vr(sol, pmd_data, name) = sol["solution"]["bus"][string(bus_name2id(pmd_data, name))]["vr"]
calc_vm_acr(sol, pmd_data, name) = sqrt.(vi(sol, pmd_data, name).^2 .+ vr(sol, pmd_data, name).^2)
calc_va_acr(sol, pmd_data, name) = rad2deg.(PMD._wrap_to_pi(atan.(vi(sol, pmd_data, name), vr(sol, pmd_data, name))))

# Helper functions adjusted for eng model
vi(sol, name) = sol["solution"]["bus"][name]["vi"]
vr(sol, name) = sol["solution"]["bus"][name]["vr"]
calc_vm_acr(sol, name) = sqrt.(vi(sol, name).^2 .+ vr(sol, name).^2)
calc_va_acr(sol, name) = rad2deg.(PMD._wrap_to_pi(atan.(vi(sol, name), vr(sol, name))))
va(sol, name) = PMD._wrap_to_pi(sol["solution"]["bus"][name]["va"][:])*180/pi
vm(sol, name) = sol["solution"]["bus"][name]["vm"]
pd(sol, name) = sol["solution"]["load"][name]["pd_bus"]
qd(sol, name) = sol["solution"]["load"][name]["qd_bus"]


# Helper functions for load models tests
load_name2id(pmd_data, name) = [load["index"] for (_,load) in pmd_data["load"] if haskey(load, "name") && load["name"]==name][1]
pdvar(pm, pmd_data, name) = [PMD.var(pm, nw_id_default, c, :pd, load_name2id(pmd_data, name)) for c in 1:3]
pd(sol, pmd_data, name) = sol["solution"]["load"][string(load_name2id(pmd_data, name))]["pd_bus"]
qdvar(pm, pmd_data, name) = [PMD.var(pm, nw_id_default, c, :qd, load_name2id(pmd_data, name)) for c in 1:3]
qd(sol, pmd_data, name) = sol["solution"]["load"][string(load_name2id(pmd_data, name))]["qd_bus"]
sd(pm, pmd_data, name) = pd(sol, pmd_data, name)+im*qd(sol, pmd_data, name)

calc_vm_w(result, id) = sqrt.(      result["solution"]["bus"][id]["w"])
calc_vm_W(result, id) = sqrt.(LinearAlgebra.diag( result["solution"]["bus"][id]["Wr"]))

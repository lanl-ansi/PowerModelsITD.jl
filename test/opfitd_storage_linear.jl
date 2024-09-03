@info "running ITD storage tests for linear model"

@testset "test/opfitd_storage_linear.jl" begin

      @testset "solve_opfitd_storage: Balanced case5-case3 With Battery ACP-ACPU " begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "case3_balanced_withBattery.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3_bal_battery.json")
        pmitd_type = NLPowerModelITD{ACPPowerModel, ACPUPowerModel}
        pmitd_data = parse_files(pm_file, pmd_file, pmitd_file)

        # cost to assign to energy storage
        # Units $/kWh
        strg_cost = 0.025

        # add cost to storages in PMD
        for (st_name, st_data) in pmitd_data["it"]["pmd"]["storage"]
            st_data["cost"] = strg_cost
        end

        # with storage cost problem
        pmitd_result_strg = solve_opfitd_storage_linear(pmitd_data, pmitd_type, ipopt)

    end

    @testset "solve_opfitd_storage with Transmission storage: Balanced case5-case3 With Battery ACP-ACPU " begin
        pm_file = joinpath(dirname(trans_path), "case5_withload_strg.m")
        pmd_file = joinpath(dirname(dist_path), "case3_balanced_withBattery.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3_bal_battery.json")
        pmitd_type = NLPowerModelITD{ACPPowerModel, ACPUPowerModel}
        pmitd_result_strg = solve_opfitd_storage_linear(pm_file, pmd_file, pmitd_file, pmitd_type, ipopt)
        @test pmitd_result_strg["termination_status"] == LOCALLY_SOLVED
    end

    @testset "solve_mn_opfitd_storage with Transmission storage: Multinetwork Balanced case5-case3 With Battery ACP-ACPU " begin
        pm_file = joinpath(dirname(trans_path), "case5_withload_strg.m")
        pmd_file = joinpath(dirname(dist_path), "case3_balanced_withBattery_mn.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3_bal_battery_mn.json")
        pmitd_type = NLPowerModelITD{ACPPowerModel, ACPUPowerModel}
        pmitd_result_strg = solve_mn_opfitd_storage_linear(pm_file, pmd_file, pmitd_file, pmitd_type, ipopt)
        @test pmitd_result_strg["termination_status"] == LOCALLY_SOLVED
    end

    @testset "solve_mn_opfitd_storage with Transmission storage: Multinetwork Balanced case5-case3 With Battery ACR-ACRU " begin
        pm_file = joinpath(dirname(trans_path), "case5_withload_strg.m")
        pmd_file = joinpath(dirname(dist_path), "case3_balanced_withBattery_mn.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3_bal_battery_mn.json")
        pmitd_type = NLPowerModelITD{ACRPowerModel, ACRUPowerModel}
        pmitd_result_strg = solve_mn_opfitd_storage_linear(pm_file, pmd_file, pmitd_file, pmitd_type, ipopt)
        @test pmitd_result_strg["termination_status"] == LOCALLY_SOLVED
    end

    @testset "solve_mn_opfitd_storage with Transmission storage: Multinetwork Balanced case5-case3 With Battery ACR-FBSUBF " begin
        pm_file = joinpath(dirname(trans_path), "case5_withload_strg.m")
        pmd_file = joinpath(dirname(dist_path), "case3_balanced_withBattery_mn.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3_bal_battery_mn.json")
        pmitd_type = NLBFPowerModelITD{ACRPowerModel, FBSUBFPowerModel}
        pmitd_result_strg = solve_mn_opfitd_storage_linear(pm_file, pmd_file, pmitd_file, pmitd_type, ipopt)
        @test pmitd_result_strg["termination_status"] == LOCALLY_SOLVED
    end

    @testset "solve_mn_opfitd_storage with Transmission storage: Multinetwork Balanced case5-case3 With Battery ACR-FOTR " begin
        pm_file = joinpath(dirname(trans_path), "case5_withload_strg.m")
        pmd_file = joinpath(dirname(dist_path), "case3_balanced_withBattery_mn.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3_bal_battery_mn.json")
        pmitd_type = NLFOTPowerModelITD{ACRPowerModel, FOTRUPowerModel}
        pmitd_result_strg = solve_mn_opfitd_storage_linear(pm_file, pmd_file, pmitd_file, pmitd_type, ipopt)
        @test pmitd_result_strg["termination_status"] == LOCALLY_SOLVED
    end

    @testset "solve_mn_opfitd_storage with Transmission storage: Multinetwork Balanced case5-case3 With Battery ACP-FOTP " begin
        pm_file = joinpath(dirname(trans_path), "case5_withload_strg.m")
        pmd_file = joinpath(dirname(dist_path), "case3_balanced_withBattery_mn.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3_bal_battery_mn.json")
        pmitd_type = NLFOTPowerModelITD{ACPPowerModel, FOTPUPowerModel}
        pmitd_result_strg = solve_mn_opfitd_storage_linear(pm_file, pmd_file, pmitd_file, pmitd_type, ipopt)
        @test pmitd_result_strg["termination_status"] == LOCALLY_SOLVED
    end

    @testset "solve_mn_opfitd_storage with Transmission storage: Multinetwork Balanced case5-case3 With Battery BFA-LinDist3Flow " begin
        pm_file = joinpath(dirname(trans_path), "case5_withload_strg.m")
        pmd_file = joinpath(dirname(dist_path), "case3_balanced_withBattery_mn.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3_bal_battery_mn.json")
        pmitd_type = BFPowerModelITD{BFAPowerModel, LinDist3FlowPowerModel}
        pmitd_result_strg = solve_mn_opfitd_storage_linear(pm_file, pmd_file, pmitd_file, pmitd_type, ipopt)
        @test pmitd_result_strg["termination_status"] == LOCALLY_SOLVED
    end

    @testset "solve_mn_opfitd_storage: Multinetwork Balanced case5-case3 With Battery in Transmission ACP-ACPU " begin
        pm_file = joinpath(dirname(trans_path), "case5_withload_strg.m")
        pmd_file = joinpath(dirname(dist_path), "case3_unbalanced_withoutgen_mn_diff3.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3_unbal_nogen_mn_diff.json")
        pmitd_type = NLPowerModelITD{ACPPowerModel, ACPUPowerModel}
        pmitd_data = parse_files(pm_file, pmd_file, pmitd_file; multinetwork=true)

        # cost to assign to energy storage
        # Units $/kWh
        strg_cost = 0.0025

        # add cost to storages in PM
        for (nw_id, nw_data) in pmitd_data["it"]["pm"]["nw"]
            for (st_name, st_data) in nw_data["storage"]
                st_data["cost"] = strg_cost
            end
        end

        # varying load
        pm_residential_prof_p = [0.293391082 0.139045672 0.469951253	0.432787275	0.392755291	0.548138118	0.466415402	0.862109886	0.794416422	0.643809168	0.709608241	0.704126411	0.963765953	0.575280879	0.611590304	0.488662676	0.430361821	0.87041275	1.306424968	1.307958207	0.928544462	0.572729047	0.552861937	0.346550725]
        pm_residential_prof_q = [0.247949186	0.171635443	0.183848151	0.227990471	0.192748178	0.319480381	0.180830891	0.415389708	0.224002485	0.322713139	0.241254927	0.300147051	0.298347195	0.186199635	0.22251068	0.303541769	0.185154905	0.432356924	0.425774291	0.50190239	0.294529233	0.320796731	0.14920804	0.136169507]

        pm_community_prof_p = [0.284287776	0.268623055	0.227327982	0.397346384	0.235818756	0.20823994	0.435025687	0.569052345	0.837116674	0.895062747	0.966074521	1.01396914	0.87299946	0.900887326	0.92727811	0.839239282	1.068426425	1.066425748	1.392200763	1.268324779	1.400386576	1.218758216	1.001009647	0.538582071]
        pm_community_prof_q = [0.124401652	0.149265062	0.112556201	0.226246144	0.112703236	0.145539091	0.24876825	0.304559383	0.412502283	0.360553174	0.361034872	0.481935002	0.515125962	0.507287921	0.398147224	0.463007061	0.507275554	0.534884845	0.508290756	0.531864342	0.549012302	0.519189403	0.452179964	0.218622959]

        pm_commercial_prof_p = [0.375187827	0.286661472	0.289096564	0.22256313	0.271830914	0.292079786	0.236396231	0.93119696	1.056699043	1.049660067	1.009438919	1.082846718	1.059419722	1.039691666	1.025920791	1.032047161	1.085377745	1.04104745	1.022642982	0.924980776	0.319601874	0.347188983	0.289086358	0.276695314]
        pm_commercial_prof_q = [0.167332967	0.299127427	0.279260644	0.207282394	0.159990914	0.219440511	0.178642786	0.559090945	0.514151587	0.540382353	0.531009283	0.518096858	0.514654825	0.591549766	0.525647471	0.549013224	0.520947523	0.557888204	0.553033554	0.511838587	0.161558414	0.257372041	0.20559509	0.295150131]

        for (nw, nw_data) in pmitd_data["it"]["pm"]["nw"]
            for (load, load_data) in nw_data["load"]
                if (load == "1")
                    load_data["pd"] = load_data["pd"]*pm_commercial_prof_p[parse(Int64,nw)]
                    load_data["qd"] = load_data["qd"]*pm_commercial_prof_q[parse(Int64,nw)]
                elseif (load == "2")
                    load_data["pd"] = load_data["pd"]*pm_community_prof_p[parse(Int64,nw)]
                    load_data["qd"] = load_data["qd"]*pm_community_prof_q[parse(Int64,nw)]
                elseif (load == "3")
                    load_data["pd"] = load_data["pd"]*pm_residential_prof_p[parse(Int64,nw)]
                    load_data["qd"] = load_data["qd"]*pm_residential_prof_q[parse(Int64,nw)]
                end
            end
        end

        pmitd_result_strg = solve_mn_opfitd_storage(pmitd_data, pmitd_type, ipopt)
        @test isapprox(pmitd_result_strg["solution"]["it"]["pm"]["nw"]["10"]["storage"]["1"]["sd"]*100, 37.8596; atol = 1e-1)

    end

end

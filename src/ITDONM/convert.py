import json
import uuid

import numpy as np

import grg_mpdata as grg

π = np.pi


def parse_mpc_to_ravens(folder, case_name):
    mpc = grg.io.parse_mp_case_file(folder + "/" + case_name + ".m")
    watt_multiplier = 1e6  # megawatts to watts

    optype_dict = {
        "lowType_5000000000.0s": {
            "Ravens.cimObjectType": "OperationalLimitType",
            "IdentifiedObject.mRID": str(uuid.uuid4()),
            "IdentifiedObject.name": "lowType_5000000000.0s",
            "OperationalLimitType.direction": "OperationalLimitDirectionKind.low",
            "OperationalLimitType.acceptableDuration": 5000000000.0,
        },
        "highType_5000000000.0s": {
            "Ravens.cimObjectType": "OperationalLimitType",
            "IdentifiedObject.mRID": str(uuid.uuid4()),
            "IdentifiedObject.name": "highType_5000000000.0s",
            "OperationalLimitType.direction": "OperationalLimitDirectionKind.high",
            "OperationalLimitType.acceptableDuration": 5000000000.0,
        },
        "slack": {
            "Ravens.cimObjectType": "OperationalLimitType",
            "IdentifiedObject.mRID": str(uuid.uuid4()),
            "IdentifiedObject.name": "slack",
            "OperationalLimitType.direction": "OperationalLimitDirectionKind.low",
            "OperationalLimitType.acceptableDuration": 5000000000.0,
        },
        "lowType_2500000000.0s": {
            "Ravens.cimObjectType": "OperationalLimitType",
            "IdentifiedObject.mRID": str(uuid.uuid4()),
            "IdentifiedObject.name": "lowType_5000000000.0s",
            "OperationalLimitType.direction": "OperationalLimitDirectionKind.low",
            "OperationalLimitType.acceptableDuration": 2500000000.0,
        },
        "highType_2500000000.0s": {
            "Ravens.cimObjectType": "OperationalLimitType",
            "IdentifiedObject.mRID": str(uuid.uuid4()),
            "IdentifiedObject.name": "highType_5000000000.0s",
            "OperationalLimitType.direction": "OperationalLimitDirectionKind.high",
            "OperationalLimitType.acceptableDuration": 2500000000.0,
        },
    }

    base_kvs = [mpc.bus[i].base_kv for i in range(len(mpc.bus))]  # to handle non-consecutive bus numbers

    bus_dict = {}
    opset_dict = {}
    basev_dict = {}
    shunt_dict = {}

    present_buses = [mpc.bus[b].bus_i - 1 for b in range(len(mpc.bus))]

    for bkv in base_kvs:
        basev = {"BaseV_" + str(bkv): {"Ravens.cimObjectType": "BaseVoltage", "IdentifiedObject.mRID": str(uuid.uuid4()), "IdentifiedObject.name": "BaseV_" + str(bkv), "BaseVoltage.nominalVoltage": bkv * 1000}}
        basev_dict.update(basev)

    for i, b in enumerate(present_buses):
        voltage_multiplier = mpc.bus[i].base_kv * 1000
        v_base = mpc.bus[i].base_kv
        s_base = mpc.baseMVA
        g_b_mul = s_base / v_base**2
        if mpc.bus[i].bus_type != 3:
            opset = {
                "OpLimVbus"
                + str(b + 1): {
                    "Ravens.cimObjectType": "OperationalLimitSet",
                    "IdentifiedObject.mRID": str(uuid.uuid4()),
                    "IdentifiedObject.name": "OpLimVbus" + str(b + 1),
                    "OperationalLimitSet.OperationalLimitValue": [
                        {
                            "Ravens.cimObjectType": "VoltageLimit",
                            "IdentifiedObject.mRID": str(uuid.uuid4()),
                            "IdentifiedObject.name": "OpLimVbus" + str(b + 1) + "_low",
                            "IdentifiedObject.description": "magnitude",
                            "VoltageLimit.value": mpc.bus[i].vmin * voltage_multiplier,
                            "OperationalLimit.OperationalLimitType": "OperationalLimitType::'lowType_5000000000.0s'",
                        },
                        {
                            "Ravens.cimObjectType": "VoltageLimit",
                            "IdentifiedObject.mRID": str(uuid.uuid4()),
                            "IdentifiedObject.name": "OpLimVbus" + str(b + 1) + "_high",
                            "IdentifiedObject.description": "magnitude",
                            "VoltageLimit.value": mpc.bus[i].vmax * voltage_multiplier,
                            "OperationalLimit.OperationalLimitType": "OperationalLimitType::'highType_5000000000.0s'",
                        },
                    ],
                }
            }
        else:
            opset = {
                "OpLimVbus"
                + str(b + 1): {
                    "Ravens.cimObjectType": "OperationalLimitSet",
                    "IdentifiedObject.mRID": str(uuid.uuid4()),
                    "IdentifiedObject.name": "OpLimVbus" + str(b + 1),
                    "OperationalLimitSet.OperationalLimitValue": [
                        {
                            "Ravens.cimObjectType": "VoltageLimit",
                            "IdentifiedObject.mRID": str(uuid.uuid4()),
                            "IdentifiedObject.name": "OpLimVbus" + str(b + 1) + "_slack",
                            "IdentifiedObject.description": "magnitude",
                            "VoltageLimit.value": 1.00 * voltage_multiplier,
                            "OperationalLimit.OperationalLimitType": "OperationalLimitType::'slack'",
                        },
                        {
                            "Ravens.cimObjectType": "VoltageLimit",
                            "IdentifiedObject.mRID": str(uuid.uuid4()),
                            "IdentifiedObject.name": "OpLimVbus" + str(b + 1) + "_low",
                            "IdentifiedObject.description": "magnitude",
                            "VoltageLimit.value": mpc.bus[i].vmin * voltage_multiplier,
                            "OperationalLimit.OperationalLimitType": "OperationalLimitType::'lowType_5000000000.0s'",
                        },
                        {
                            "Ravens.cimObjectType": "VoltageLimit",
                            "IdentifiedObject.mRID": str(uuid.uuid4()),
                            "IdentifiedObject.name": "OpLimVbus" + str(b + 1) + "_high",
                            "IdentifiedObject.description": "magnitude",
                            "VoltageLimit.value": mpc.bus[i].vmax * voltage_multiplier,
                            "OperationalLimit.OperationalLimitType": "OperationalLimitType::'highType_5000000000.0s'",
                        },
                    ],
                }
            }
        bus = {
            str(b + 1): {
                "IdentifiedObject.name": str(b + 1),
                "IdentifiedObject.mRID": str(uuid.uuid4()),
                "Ravens.cimObjectType": "ConnectivityNode",
                "ConnectivityNode.SvVoltage": [{"Ravens.cimObjectType": "SvVoltage", "IdentifiedObject.mRID": str(uuid.uuid4()), "SvVoltage.v": mpc.bus[i].vm * voltage_multiplier, "SvVoltage.angle": mpc.bus[i].va * (π / 180)}],
                "ConnectivityNode.OperationalLimitSet": "OperationalLimitSet::'OpLimVbus" + str(b + 1) + "'",
            }
        }
        shunt = {
            "shunt"
            + str(b + 1): {
                "Ravens.cimObjectType": "LinearShuntCompensator",
                "IdentifiedObject.mRID": str(uuid.uuid4()),
                "IdentifiedObject.name": "shunt" + str(b + 1),
                "LinearShuntCompensator.bPerSection": mpc.bus[i].bs * g_b_mul,
                "LinearShuntCompensator.gPerSection": mpc.bus[i].gs * g_b_mul,
                "ShuntCompensator.normalSections": 1,
                "ShuntCompensator.maximumSections": 1,
                "Equipment.inService": (mpc.bus[i].bs != 0.0) or (mpc.bus[i].gs != 0.0),
                "ShuntCompensator.sections": 1.0,
                "ConductingEquipment.BaseVoltage": "BaseVoltage::'BaseV_" + str(mpc.bus[i].base_kv) + "'",
                "ConductingEquipment.Terminals": [
                    {
                        "Ravens.cimObjectType": "Terminal",
                        "IdentifiedObject.mRID": str(uuid.uuid4()),
                        "IdentifiedObject.name": "shunt" + str(b + 1) + "_T1",
                        "ACDCTerminal.sequenceNumber": 1,
                        "Terminal.ConnectivityNode": "ConnectivityNode::'" + str(b + 1) + "'",
                    }
                ],
            }
        }
        bus_dict.update(bus)
        if (mpc.bus[i].bs != 0.0) or (mpc.bus[i].gs != 0.0):
            shunt_dict.update(shunt)
        opset_dict.update(opset)

    load_dict = {}
    for i, b in enumerate(present_buses):
        load = {
            "load"
            + str(b + 1): {
                "Ravens.cimObjectType": "EnergyConsumer",
                "IdentifiedObject.mRID": str(uuid.uuid4()),
                "IdentifiedObject.name": "load" + str(b + 1),
                "ConductingEquipment.BaseVoltage": "BaseVoltage::'BaseV_" + str(mpc.bus[i].base_kv) + "'",
                "EnergyConsumer.p": mpc.bus[i].pd * watt_multiplier,
                "EnergyConsumer.q": mpc.bus[i].qd * watt_multiplier,
                "EnergyConsumer.LoadResponse": "LoadResponseCharacteristic::'Constant kVA'",
                "ConductingEquipment.Terminals": [
                    {"Ravens.cimObjectType": "Terminal", "IdentifiedObject.mRID": str(uuid.uuid4()), "IdentifiedObject.name": str(b + 1) + "_T1", "ACDCTerminal.sequenceNumber": 1, "Terminal.ConnectivityNode": "ConnectivityNode::'" + str(b + 1) + "'"}
                ],
            }
        }
        if mpc.bus[i].pd != 0.0 or mpc.bus[i].qd != 0.0 or mpc.bus[i].bus_type == 1:
            load_dict.update(load)

    gen_dict = {}
    for g in range(len(mpc.gen)):
        gbus = mpc.gen[g].gen_bus
        gbind = -1
        for i, b in enumerate(present_buses):
            if b == (gbus - 1):
                gbind = i
        gen = {
            "gen"
            + str(g + 1): {
                "Ravens.cimObjectType": "SynchronousMachine",
                "IdentifiedObject.mRID": str(uuid.uuid4()),
                "IdentifiedObject.name": "gen" + str(g + 1),
                "RotatingMachine.p": -mpc.gen[g].pg * watt_multiplier,
                "RotatingMachine.q": -mpc.gen[g].qg * watt_multiplier,
                "SynchronousMachine.maxQ": mpc.gen[g].qmax * watt_multiplier,
                "SynchronousMachine.minQ": mpc.gen[g].qmin * watt_multiplier,
                "RotatingMachine.CostFunction": "ProducerCostFunction::'cost_gen" + str(g + 1) + "'",
                "Equipment.inService": bool(mpc.gen[g].gen_status),
                # the base voltage is pulled from the gen bus -- OK?
                "ConductingEquipment.BaseVoltage": "BaseVoltage::'BaseV_" + str(mpc.bus[gbind].base_kv) + "'",
                "ConductingEquipment.Terminals": [
                    {
                        "Ravens.cimObjectType": "Terminal",
                        "IdentifiedObject.mRID": str(uuid.uuid4()),
                        "IdentifiedObject.name": "gen" + str(g + 1) + "_T1",
                        "ACDCTerminal.sequenceNumber": 1,
                        "Terminal.ConnectivityNode": "ConnectivityNode::'" + str(int(mpc.gen[g].gen_bus)) + "'",
                    }
                ],
                "RotatingMachine.GeneratingUnit": {
                    "Ravens.cimObjectType": "GeneratingUnit",
                    "IdentifiedObject.mRID": str(uuid.uuid4()),
                    "IdentifiedObject.name": "gen" + str(g + 1) + "_GenUnit",
                    "GeneratingUnit.minOperatingP": mpc.gen[g].pmin * watt_multiplier,
                    "GeneratingUnit.maxOperatingP": mpc.gen[g].pmax * watt_multiplier,
                },
            }
        }
        gen_dict.update(gen)

    cost_dict = {}
    # TODO add support for piecewise linear costs. These
    # are only for polynomial (in fact, only quadratic)
    for g in range(len(mpc.gen)):
        end = len(mpc.gencost[g].cost) - 1
        cost = {
            "cost_gen"
            + str(g + 1): {
                "Ravens.cimObjectType": "ProducerCostFunction",
                "IdentifiedObject.name": "cost_gen" + str(g + 1),
                "IdentifiedObject.mRID": str(uuid.uuid4()),
                "ProducerCostFunction.CostParameters": [
                    {"PolynomialCostParameter.power": 0, "PolynomialCostParameter.costCoefficient": mpc.gencost[g].cost[end]},
                    {"PolynomialCostParameter.power": 1, "PolynomialCostParameter.costCoefficient": mpc.gencost[g].cost[end - 1]},
                    {"PolynomialCostParameter.power": 2, "PolynomialCostParameter.costCoefficient": mpc.gencost[g].cost[end - 2]},
                ],
                "ProducerCostFunction.startupCost": mpc.gencost[g].startup,
                "ProducerCostFunction.shutdownCost": mpc.gencost[g].shutdown,
            }
        }
        cost_dict.update(cost)

    line_dict = {}
    trnfmr_dict = {}
    tap_dict = {}
    phase_dict = {}

    for br in range(len(mpc.branch)):
        ref_v_bus_ind = present_buses.index(int(mpc.branch[br].f_bus) - 1)  # should not matter whether we pick f_bus or t_bus
        v_base = mpc.bus[ref_v_bus_ind].base_kv
        s_base = mpc.baseMVA
        r_x_mul = v_base**2 / s_base
        g_b_mul = s_base / v_base**2
        opset = {
            "OpLimbranch"
            + str(br + 1): {
                "Ravens.cimObjectType": "OperationalLimitSet",
                "IdentifiedObject.mRID": str(uuid.uuid4()),
                "IdentifiedObject.name": "OpLimbranch" + str(br + 1),
                "OperationalLimitSet.OperationalLimitValue": [
                    {
                        "Ravens.cimObjectType": "ActivePowerLimit",
                        "IdentifiedObject.mRID": str(uuid.uuid4()),
                        "IdentifiedObject.name": "OpLimbranch" + str(br) + "_rate_a",
                        "ActivePowerLimit.value": mpc.branch[br].rate_a * watt_multiplier,
                        "OperationalLimit.OperationalLimitType": "OperationalLimitType::'highType_5000000000.0s'",
                    },
                    {
                        "Ravens.cimObjectType": "ActivePowerLimit",
                        "IdentifiedObject.mRID": str(uuid.uuid4()),
                        "IdentifiedObject.name": "OpLimbranch" + str(br) + "_rate_b",
                        "ActivePowerLimit.value": mpc.branch[br].rate_b * watt_multiplier,
                        "OperationalLimit.OperationalLimitType": "OperationalLimitType::'highType_2500000000.0s'",
                    },
                    {
                        "Ravens.cimObjectType": "VoltageLimit",
                        "IdentifiedObject.mRID": str(uuid.uuid4()),
                        "IdentifiedObject.name": "OpLimbranch" + str(br) + "_angles_low",
                        "IdentifiedObject.description": "angle",
                        "VoltageLimit.value": mpc.branch[br].angmin * (π / 180),
                        "OperationalLimit.OperationalLimitType": "OperationalLimitType::'lowType_5000000000.0s'",
                    },
                    {
                        "Ravens.cimObjectType": "VoltageLimit",
                        "IdentifiedObject.mRID": str(uuid.uuid4()),
                        "IdentifiedObject.name": "OpLimbranch" + str(br) + "_angles_high",
                        "IdentifiedObject.description": "angle",
                        "VoltageLimit.value": mpc.branch[br].angmax * (π / 180),
                        "OperationalLimit.OperationalLimitType": "OperationalLimitType::'highType_5000000000.0s'",
                    },
                ],
            }
        }
        opset_dict.update(opset)
        if (mpc.branch[br].tap == 0) and mpc.branch[br].shift == 0:
            line = {
                "line"
                + str(br + 1): {
                    "Ravens.cimObjectType": "ACLineSegment",
                    "IdentifiedObject.mRID": str(uuid.uuid4()),
                    "IdentifiedObject.name": "line" + str(br + 1),
                    "Equipment.inService": bool(mpc.branch[br].br_status),
                    "ACLineSegment.r": mpc.branch[br].br_r * r_x_mul,
                    "ACLineSegment.x": mpc.branch[br].br_x * r_x_mul,
                    "ACLineSegment.bch": mpc.branch[br].br_b * g_b_mul,
                    "Equipment.OperationalLimitSet": "OperationalLimitSet::'OpLimbranch" + str(br + 1) + "'",
                    "ConductingEquipment.Terminals": [
                        {
                            "Ravens.cimObjectType": "Terminal",
                            "IdentifiedObject.mRID": str(uuid.uuid4()),
                            "IdentifiedObject.name": "line" + str(br + 1) + "_T1",
                            "ACDCTerminal.sequenceNumber": 1,
                            "Terminal.ConnectivityNode": "ConnectivityNode::'" + str(int(mpc.branch[br].f_bus)) + "'",
                        },
                        {
                            "Ravens.cimObjectType": "Terminal",
                            "IdentifiedObject.mRID": str(uuid.uuid4()),
                            "IdentifiedObject.name": "line" + str(br + 1) + "_T2",
                            "ACDCTerminal.sequenceNumber": 2,
                            "Terminal.ConnectivityNode": "ConnectivityNode::'" + str(int(mpc.branch[br].t_bus)) + "'",
                        },
                    ],
                }
            }
            line_dict.update(line)
        if (mpc.branch[br].tap != 0) or mpc.branch[br].shift != 0:  # ratio != 1 => transformer
            trnfmr = {
                "transformer"
                + str(br + 1): {
                    "Ravens.cimObjectType": "PowerTransformer",
                    "IdentifiedObject.mRID": str(uuid.uuid4()),
                    "IdentifiedObject.name": "transformer" + str(br + 1),
                    "Equipment.inService": bool(mpc.branch[br].br_status),
                    "Equipment.OperationalLimitSet": "OperationalLimitSet::'OpLimbranch" + str(br + 1) + "'",
                    "PowerTransformer.PowerTransformerEnd": [
                        {
                            "Ravens.cimObjectType": "PowerTransformerEnd",
                            "IdentifiedObject.mRID": str(uuid.uuid4()),
                            "IdentifiedObject.name": "transformer" + str(br + 1) + "_end1",
                            "TransformerEnd.endNumber": 1,
                            "PowerTransformerEnd.r": 0.0,
                            "PowerTransformerEnd.b": 0.0,
                            "PowerTransformerEnd.x": 0.0,
                            "TransformerEnd.RatioTapChanger": "RatioTapChanger::'tap" + str(br + 1) + "'",
                            "TransformerEnd.PhaseTapChanger": "PhaseTapChanger::'shift" + str(br + 1) + "'",
                            "ConductingEquipment.Terminals": [
                                {
                                    "Ravens.cimObjectType": "Terminal",
                                    "IdentifiedObject.mRID": str(uuid.uuid4()),
                                    "IdentifiedObject.name": "transformer" + str(br + 1) + "_T1",
                                    "ACDCTerminal.sequenceNumber": 1,
                                    "Terminal.ConnectivityNode": "ConnectivityNode::'" + str(int(mpc.branch[br].f_bus)) + "'",
                                }
                            ],
                        },
                        {
                            "Ravens.cimObjectType": "PowerTransformerEnd",
                            "IdentifiedObject.mRID": str(uuid.uuid4()),
                            "IdentifiedObject.name": "transformer" + str(br + 1) + "_end2",
                            "TransformerEnd.endNumber": 2,
                            "PowerTransformerEnd.r": mpc.branch[br].br_r * r_x_mul,
                            "PowerTransformerEnd.b": mpc.branch[br].br_b * g_b_mul,
                            "PowerTransformerEnd.x": mpc.branch[br].br_x * r_x_mul,
                            "ConductingEquipment.Terminals": [
                                {
                                    "Ravens.cimObjectType": "Terminal",
                                    "IdentifiedObject.mRID": str(uuid.uuid4()),
                                    "IdentifiedObject.name": "transformer" + str(br + 1) + "_T2",
                                    "ACDCTerminal.sequenceNumber": 2,
                                    "Terminal.ConnectivityNode": "ConnectivityNode::'" + str(int(mpc.branch[br].t_bus)) + "'",
                                }
                            ],
                        },
                    ],
                }
            }
            tap = {
                "tap"
                + str(br + 1): {
                    "Ravens.cimObjectType": "RatioTapChanger",
                    "IdentifiedObject.mRID": str(uuid.uuid4()),
                    "IdentifiedObject.name": "tap" + str(br + 1),
                    "TapChanger.TapChangerRatio": {"Ravens.cimObjectType": "TapChangerRatio", "IdentifiedObject.mRID": str(uuid.uuid4()), "IdentifiedObject.name": "tap" + str(br + 1) + "_ratio", "TapChangerRatio.ptRatio": mpc.branch[br].tap},
                }
            }
            phase = {
                "shift"
                + str(br + 1): {
                    "Ravens.cimObjectType": "PhaseTapChanger",
                    "IdentifiedObject.mRID": str(uuid.uuid4()),
                    "IdentifiedObject.name": "shift" + str(br + 1),
                    "TapChanger.TapChangerRatio": {
                        "Ravens.cimObjectType": "TapChangerRatio",
                        "IdentifiedObject.mRID": str(uuid.uuid4()),
                        "IdentifiedObject.name": "shift" + str(br + 1) + "_angle",
                        "TapChangerRatio.ptRatio": mpc.branch[br].shift * (π / 180),
                    },
                }
            }
            trnfmr_dict.update(trnfmr)
            tap_dict.update(tap)
            phase_dict.update(phase)

    meta_dict = {
        "ConnectivityNode": bus_dict,
        "PowerSystemResource": {
            "Equipment": {
                "ConductingEquipment": {"Conductor": {"ACLineSegment": line_dict}, "PowerTransformer": trnfmr_dict, "EnergyConnection": {"EnergyConsumer": load_dict, "RegulatingCondEq": {"RotatingMachine": gen_dict, "ShuntCompensator": shunt_dict}}},
            },
            "TapChanger": {"RatioTapChanger": tap_dict, "PhaseTapChanger": phase_dict},
        },
        "BaseVoltage": basev_dict,
        "OperationalLimitSet": opset_dict,
        "OperationalLimitType": optype_dict,
        "ProducerCostFunction": cost_dict,
        "MySettings": {
            "IdentifiedObject.mRID": "b95df443-bcee-49d5-b60c-e819df5b0959",
            "IdentifiedObject.name": "MySettings",
            "Ravens.cimObjectType": "AlgorithmSettings",
            "ApplicationSettings.Settings": [{"Ravens.cimObjectType": "GenericApplicationSetting", "name": "baseMVA", "value": mpc.baseMVA, "type": "float"}],
        },
        "LoadResponseCharacteristic": {
            "Constant kVA": {
                "Ravens.cimObjectType": "LoadResponseCharacteristic",
                "IdentifiedObject.mRID": "66064af5-17f6-4ba0-9b3a-371c7f3230c8",
                "IdentifiedObject.name": "Constant kVA",
                "LoadResponseCharacteristic.pConstantPower": 100.0,
                "LoadResponseCharacteristic.qConstantPower": 100.0,
            },
            "Constant I": {
                "Ravens.cimObjectType": "LoadResponseCharacteristic",
                "IdentifiedObject.mRID": "931bccf6-29ca-40e4-b818-1ab2c2853601",
                "IdentifiedObject.name": "Constant I",
                "LoadResponseCharacteristic.pConstantCurrent": 100.0,
                "LoadResponseCharacteristic.qConstantCurrent": 100.0,
            },
            "Constant Z": {
                "Ravens.cimObjectType": "LoadResponseCharacteristic",
                "IdentifiedObject.mRID": "30068317-46eb-4b99-9f42-da0db3039da9",
                "IdentifiedObject.name": "Constant Z",
                "LoadResponseCharacteristic.pConstantImpedance": 100.0,
                "LoadResponseCharacteristic.qConstantImpedance": 100.0,
            },
        },
    }

    with open(folder + "/" + case_name + ".json", "w") as fp:
        json.dump(meta_dict, fp, indent=2)

parse_mpc_to_ravens('.', 'case118_ravens')
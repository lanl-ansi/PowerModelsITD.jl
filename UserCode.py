import requests
import json

ravens_file = './data/case118_case123_x4.json'
with open(ravens_file, 'r') as file:    
    inputdata = json.load(file)

switch_keys = list(inputdata["PowerSystemResource"]["Equipment"]["ConductingEquipment"]["Switch"].keys())
closedswitches=["sw1","sw3","sw7", "sw5"]#"sw1"
for sw in switch_keys:
    if sw in closedswitches:
        inputdata["PowerSystemResource"]["Equipment"]["ConductingEquipment"]["Switch"][sw]["Switch.open"] = False
    else:
        inputdata["PowerSystemResource"]["Equipment"]["ConductingEquipment"]["Switch"][sw]["Switch.open"] = True

output=requests.get('http://localhost:8800/RunITDRestore', json=inputdata)

RavensOutput=output.json()["Ravens Output"]

for i in range(0,7):
    v=RavensOutput["OptimalPowerFlow"]['OperationsResult.Switches'][i]
    name=RavensOutput["OptimalPowerFlow"]['OperationsResult.Switches'][i]['ArSwitch.Switch']
    print([name]+[v['AnalysisResultData.Curve']['AnalysisResultCurve.CurveDatas'][j]["ArCurveData.DataValues"]["AvSwitch.open"] for j in [0,1]])
    print("\n")




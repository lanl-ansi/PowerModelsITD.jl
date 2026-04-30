import os
from fastapi import FastAPI

from typing import List, Dict
from julia.api import Julia
from pathlib import Path

PROJECT_DIR = Path(__file__).resolve().parent
os.environ["JULIA_PROJECT"] = str(PROJECT_DIR)
os.environ["PYTHON"] = str(PROJECT_DIR / ".." / "venv" / "bin" / "python")
os.environ["PYCALL_JL_RUNTIME_PYTHON"] = str(PROJECT_DIR / ".."  / "venv" / "bin" / "python")


jl = Julia(compiled_modules=False)
from julia import Main
from fastapi.param_functions import Depends
from pydantic import BaseModel
import json
from typing import Any

Main.eval(f'''
import Pkg
Pkg.activate(raw"{PROJECT_DIR}")
''')
print("Active Julia project:", Main.eval("Base.active_project()"))


app = FastAPI()


class Gen(BaseModel):
    status: int | None = 1
    inverter: str | None = 'GRID_FOLLOWING'
class Solar(BaseModel):
    status: int | None = 1
    inverter: str | None = 'GRID_FOLLOWING'
class VoltageSource(BaseModel):
    status: int | None = 1
    inverter: str | None = 'GRID_FOLLOWING'
class Storage(BaseModel):
    energy: float | None = 1.0
    status: int | None = 1
    inverter: str | None = 'GRID_FOLLOWING'
class Bus(BaseModel):
    status: int | None = 1
    inverter: str | None = 'GRID_FOLLOWING'
class Load(BaseModel):
    status: int | None = 1
    dispatchable: int
class Line(BaseModel):
    status: int | None = 1
class Switch(BaseModel):
    status: int | None = 1
    state: str | None = 'CLOSED'
class Transformer(BaseModel):
    status: int | None = 1


class Settings(BaseModel):
    generator: Dict[str, Gen] | None = None
    solar: Dict[str, Solar] | None = None
    voltage_source: Dict[str, VoltageSource] | None = None
    storage: Dict[str, Storage] | None = None
    bus: Dict[str, Bus] | None = None
    load: Dict[str, Load] | None = None
    line: Dict[str, Line] | None = None
    switch: Dict[str, Switch] | None = None
    transformer: Dict[str, Transformer] | None = None


@app.get("/RunITDRestore")
async def RunITDRestore(InputVals: dict[str, Any]):               

    with open('./data/ravensinput.json', "w") as outfile: 
        json.dump(InputVals, outfile)

    fn = Main.include('ITDRestore.jl')

    ravens_output=fn()
    return {"Ravens Output": ravens_output}

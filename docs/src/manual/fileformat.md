# File Formats Guide

In this section, we will give a brief introduction to the file formats supported in PowerModelsITD.jl. Place special attention at the **Boundary** section to understand how the _boundary linking file_ must be formatted and how the `auto_rename=true` option works.

## File Formats Supported

- **Transmission**: Matpower ".m" and PTI ".raw" files (PSS(R)E v33 specification)
- **Distribution**: OpenDSS ".dss" files
- **Boundary**: JSON ".json" files

## Transmission System

- **Matpower (".m")**

```julia
function mpc = case5
mpc.version = '2';
mpc.baseMVA = 100.0;

%% bus data
%	bus_i	type	Pd	Qd	Gs	Bs	area	Vm	Va	baseKV	zone	Vmax	Vmin
mpc.bus = [
	1	 2	 0.0	 0.0	 0.0	 0.0	 1	    1.07762	    2.80377	 230.0	 1	    1.10000	    0.90000;
	2	 1	 300.0	 98.61	 0.0	 0.0	 1	    1.08407	   -0.73465	 230.0	 1	    1.10000	    0.90000;
	3	 2	 300.0	 98.61	 0.0	 0.0	 1	    1.10000	   -0.55972	 230.0	 1	    1.10000	    0.90000;
	4	 3	 390.0	 131.47	 0.0	 0.0	 1	    1.06414	    0.00000	 230.0	 1	    1.10000	    0.90000;
	5	 1	 8.0	 1.2	 0.0	 0.0	 1	    1.00000	    0.00000	 230.0	 1	    1.10000	    0.90000;
	10	 2	 0.0	 0.0	 0.0	 0.0	 1	    1.06907	    3.59033	 230.0	 1	    1.10000	    0.90000;
];

%% generator data
%	bus	Pg	Qg	Qmax	Qmin	Vg	mBase	status	Pmax	Pmin
mpc.gen = [
	1	 40.0	 30.0	 30.0	 -30.0	 1.07762	 100.0	 1	 40.0	 0.0;
	1	 170.0	 127.5	 127.5	 -127.5	 1.07762	 100.0	 1	 170.0	 0.0;
	3	 324.498	 390.0	 390.0	 -390.0	 1.1	 100.0	 1	 520.0	 0.0;
	4	 0.0	 -10.802	 150.0	 -150.0	 1.06414	 100.0	 1	 200.0	 0.0;
	10	 470.694	 -165.039	 450.0	 -450.0	 1.06907	 100.0	 1	 600.0	 0.0;
];

%% generator cost data
%	2	startup	shutdown	n	c(n-1)	...	c0
mpc.gencost = [
	2	 0.0	 0.0	 3	   0.000000	  14.000000	   0.000000	   2.000000;
	2	 0.0	 0.0	 3	   0.000000	  15.000000	   0.000000	   2.000000;
	2	 0.0	 0.0	 3	   0.000000	  30.000000	   0.000000	   2.000000;
	2	 0.0	 0.0	 3	   0.000000	  40.000000	   0.000000	   2.000000;
	2	 0.0	 0.0	 3	   0.000000	  10.000000	   0.000000	   2.000000;
];

%% branch data
%	fbus	tbus	r	x	b	rateA	rateB	rateC	ratio	angle	status	angmin	angmax
mpc.branch = [
	1	 2	 0.00281	 0.0281	 0.00712	 400.0	 400.0	 400.0	 0.0	  0.0	 1	 -30.0	 30.0;
	1	 4	 0.00304	 0.0304	 0.00658	 426	 426	 426	 0.0	  0.0	 1	 -30.0	 30.0;
	1	 10	 0.00064	 0.0064	 0.03126	 426	 426	 426	 0.0	  0.0	 1	 -30.0	 30.0;
	2	 3	 0.00108	 0.0108	 0.01852	 426	 426	 426	 0.0	  0.0	 1	 -30.0	 30.0;
	3	 4	 0.00297	 0.0297	 0.00674	 426	 426	 426	 1.05	  1.0	 1	 -30.0	 30.0;
	4	 10	 0.00297	 0.0297	 0.00674	 240.0	 240.0	 240.0	 0.0	  0.0	 1	 -30.0	 30.0;
	2	 5	 0.00297	 0.0297	 0.00674	 426	 426	 426	 0.0	  0.0	 1	 -30.0	 30.0;
];

```

- **PSS(R)E v33 specification (".raw")**

```julia
 0,    100.00, 33, 0, 0, 60.00
tests an angle shifting transformer
tests two winding transformer status
    1,'1', 230.0000,2,   1,   1,   1,1.00000000,   2.803770, 1.10000, 0.90000, 1.10000, 0.90000
    2,'2', 230.0000,1,   1,   1,   1,1.08406997,  -0.734650, 1.10000, 0.90000, 1.10000, 0.90000
    3,'3', 230.0000,2,   1,   1,   1,1.00000000,  -0.559720, 1.10000, 0.90000, 1.10000, 0.90000
    4,'4', 230.0000,3,   1,   1,   1,1.06413996,   0.000000, 1.10000, 0.90000, 1.10000, 0.90000
    5,'5', 230.0000,1,   1,   1,   1,1.00000000,   0.000000, 1.10000, 0.90000, 1.10000, 0.90000
   10,'10', 230.0000,2,   1,   1,   1,1.00000000,   3.590330, 1.10000, 0.90000, 1.10000, 0.90000
0 / END OF BUS DATA, BEGIN LOAD DATA
    2,'1',1,   1,   1,   300.000,    98.610,     0.000,     0.000,     0.000,     0.000,   1,1
    3,'1',1,   1,   1,   300.000,    98.610,     0.000,     0.000,     0.000,     0.000,   1,1
    4,'1',1,   1,   1,   390.000,   131.470,     0.000,     0.000,     0.000,     0.000,   1,1
    5,'1',1,   1,   1,   8.00000,   1.20000,     0.000,     0.000,     0.000,     0.000,   1,1
0 / END OF LOAD DATA, BEGIN FIXED SHUNT DATA
0 / END OF FIXED SHUNT DATA, BEGIN GENERATOR DATA
    1,'1',    40.000,    30.000,    30.000,   -30.000,1.07762,    0,   100.000,   0.00000,   1.00000,   0.00000,   0.00000,1.00000,1,  100.0,    40.000,     0.000,   1,1.0000,   0,1.0000,   0,1.0000,   0,1.0000,0, 1.0000
    1,'2',   170.000,   127.500,   127.500,  -127.500,1.07762,    0,   100.000,   0.00000,   1.00000,   0.00000,   0.00000,1.00000,1,  100.0,   170.000,     0.000,   1,1.0000,   0,1.0000,   0,1.0000,   0,1.0000,0, 1.0000
    3,'1',   324.498,   390.000,   390.000,  -390.000,1.10000,    0,   100.000,   0.00000,   1.00000,   0.00000,   0.00000,1.00000,1,  100.0,   520.000,     0.000,   1,1.0000,   0,1.0000,   0,1.0000,   0,1.0000,0, 1.0000
    4,'1',     0.000,   -10.802,   150.000,  -150.000,1.06414,    0,   100.000,   0.00000,   1.00000,   0.00000,   0.00000,1.00000,1,  100.0,   200.000,     0.000,   1,1.0000,   0,1.0000,   0,1.0000,   0,1.0000,0, 1.0000
   10,'1',   470.694,  -165.039,   450.000,  -450.000,1.06907,    0,   100.000,   0.00000,   1.00000,   0.00000,   0.00000,1.00000,1,  100.0,   600.000,     0.000,   1,1.0000,   0,1.0000,   0,1.0000,   0,1.0000,0, 1.0000
0 / END OF GENERATOR DATA, BEGIN BRANCH DATA
     1,     2,'1',2.81000E-3,2.81000E-2,7.12000E-3, 400.00, 400.00, 400.00,  0.00000,  0.00000,  0.00000,  0.00000,1,1,   0.0,   1,1.0000,   0,1.0000,   0,1.0000,   0,1.0000
     1,     4,'1',3.04000E-3,3.04000E-2,6.58000E-3, 426.00, 426.00, 426.00,  0.00000,  0.00000,  0.00000,  0.00000,1,1,   0.0,   1,1.0000,   0,1.0000,   0,1.0000,   0,1.0000
     1,    10,'1',6.40000E-4,6.40000E-3,3.12600E-2, 426.00, 426.00, 426.00,  0.00000,  0.00000,  0.00000,  0.00000,1,1,   0.0,   1,1.0000,   0,1.0000,   0,1.0000,   0,1.0000
     2,     3,'1',1.08000E-3,1.08000E-2,1.85200E-2, 426.00, 426.00, 426.00,  0.00000,  0.00000,  0.00000,  0.00000,1,1,   0.0,   1,1.0000,   0,1.0000,   0,1.0000,   0,1.0000
     3,     4,'1',2.97000E-3,2.97000E-2,6.74000E-3, 426.00, 426.00, 426.00,  1.05000,  0.00000,  0.00000,  0.00000,1,1,   0.0,   1,1.0000,   0,1.0000,   0,1.0000,   0,1.0000
     4,    10,'1',2.97000E-3,2.97000E-2,6.74000E-3, 240.00, 240.00, 240.00,  0.00000,  0.00000,  0.00000,  0.00000,1,1,   0.0,   1,1.0000,   0,1.0000,   0,1.0000,   0,1.0000
     2,     5,'1',2.97000E-3,2.97000E-2,6.74000E-3, 426.00, 426.00, 426.00,  0.00000,  0.00000,  0.00000,  0.00000,1,1,   0.0,   1,1.0000,   0,1.0000,   0,1.0000,   0,1.0000
0 / END OF BRANCH DATA, BEGIN TRANSFORMER DATA
     4,     3,    0,'1 ',0,1,1,0.00000E0,6.74000E-3,2,'            ',1,   1,1.0000,   0,1.0000,   0,1.0000,   0,1.0000,'            '
2.97000E-3,2.97000E-2, 100.00
1.050000,230.000,  -1.000, 426.00, 426.00, 426.00,-3,     0,   30.00,  -30.00,  150.00,   51.00,9601, 0, 0.00000, 0.00000,  0.000
1.000000,230.000
     3,     4,    0,'2 ',1,0,1,0.00000E0,6.74000E-3,2,'            ',1,   1,1.0000,   0,1.0000,   0,1.0000,   0,1.0000,'            '
2.97000E-3,2.97000E-2, 100.00
1.050000,230.000,   1.000, 426.00, 426.00, 426.00,-3,     0,   30.00,  -30.00,  150.00,   51.00,9601, 0, 0.00000, 0.00000,  0.000
1.000000,230.000
     3,     4,    0,'2 ',1,1,0,0.00000E0,6.74000E-3,2,'            ',0,   1,1.0000,   0,1.0000,   0,1.0000,   0,1.0000,'            '
2.97000E-3,2.97000E-2, 100.00
1.050000,230.000,   1.000, 426.00, 426.00, 426.00,-3,     0,   30.00,  -30.00,  150.00,   51.00,9601, 0, 0.00000, 0.00000,  0.000
1.000000,230.000
     3,     4,    0,'2 ',1,1,1,0.00000E0,6.74000E-3,2,'            ',2,   1,1.0000,   0,1.0000,   0,1.0000,   0,1.0000,'            '
2.97000E-3,2.97000E-2, 100.00
1.050000,230.000,   1.000, 426.00, 426.00, 426.00,-3,     0,   30.00,  -30.00,  150.00,   51.00,9601, 0, 0.00000, 0.00000,  0.000
1.000000,230.000
0 / END OF TRANSFORMER DATA, BEGIN AREA DATA
   1,    0,     0.000,     1.000,'1           '
0 / END OF AREA DATA, BEGIN TWO-TERMINAL DC DATA
0 / END OF TWO-TERMINAL DC DATA, BEGIN VOLTAGE SOURCE CONVERTER DATA
0 / END OF VOLTAGE SOURCE CONVERTER DATA, BEGIN IMPEDANCE CORRECTION DATA
0 / END OF IMPEDANCE CORRECTION DATA, BEGIN MULTI-TERMINAL DC DATA
0 / END OF MULTI-TERMINAL DC DATA, BEGIN MULTI-SECTION LINE DATA
0 / END OF MULTI-SECTION LINE DATA, BEGIN ZONE DATA
   1,'1       '
0 / END OF ZONE DATA, BEGIN INTER-AREA TRANSFER DATA
0 / END OF INTER-AREA TRANSFER DATA, BEGIN OWNER DATA
    1,'1'
0 / END OF OWNER DATA, BEGIN FACTS CONTROL DEVICE DATA
0 / END OF FACTS CONTROL DEVICE DATA, BEGIN SWITCHED SHUNT DATA
0 /END OF SWITCHED SHUNT DATA, BEGIN GNE DEVICE DATA
0 /END OF GNE DEVICE DATA
Q
```

## Distribution System

- **OpenDSS (".dss")**

```julia
New Circuit.3bus_bal
!  define a really stiff source
~ basekv=230 pu=1.00 MVAsc3=200000 MVAsc1=210000

! Substation Transformer
New Transformer.SubXF Phases=3 Windings=2 Xhl=0.01
~ wdg=1 bus=sourcebus conn=wye kv=230   kva=25000    %r=0.0005
~ wdg=2 bus=Substation   conn=wye kv=13.8  kva=25000   %r=0.0005

!Define Linecodes
New linecode.556MCM nphases=3 basefreq=60  ! ohms per 5 mile
~ rmatrix = ( 0.1000 | 0.0400    0.1000 |  0.0400    0.0400    0.1000)
~ xmatrix = ( 0.0583 |  0.0233    0.0583 | 0.0233    0.0233    0.0583)
~ cmatrix = (50.92958178940651  | -0  50.92958178940651 | -0 -0 50.92958178940651  ) ! small capacitance

New linecode.4/0QUAD nphases=3 basefreq=60  ! ohms per 100ft
~ rmatrix = ( 0.1167 | 0.0467    0.1167 | 0.0467    0.0467    0.1167)
~ xmatrix = (0.0667  |  0.0267    0.0667  |  0.0267    0.0267    0.0667 )
~ cmatrix = (50.92958178940651  | -0  50.92958178940651 | -0 -0 50.92958178940651  )  ! small capacitance

!Define lines
New Line.OHLine  bus1=Substation.1.2.3  Primary.1.2.3  linecode = 556MCM   length=1 normamps=6000 emergamps=6000! 5 mile line
New Line.Quad    Bus1=Primary.1.2.3  loadbus.1.2.3  linecode = 4/0QUAD  length=1 normamps=6000 emergamps=6000  ! 100 ft

!Loads - single phase
New Load.L1 phases=1  loadbus.1.0   ( 13.8 3 sqrt / )   kW=3000   kvar=1500  model=1
New Load.L2 phases=1  loadbus.2.0   ( 13.8 3 sqrt / )   kW=3000   kvar=1500  model=1
New Load.L3 phases=1  loadbus.3.0   ( 13.8 3 sqrt / )   kW=3000   kvar=1500  model=1

!GENERATORS DEFINITIONS
New generator.gen1 Bus1=loadbus.1.2.3 Phases=3 kV=( 13.8 3 sqrt / )  kW=2000 pf=1 conn=wye Model=3

Set VoltageBases = "230,13.8"
Set tolerance=0.000001
set defaultbasefreq=60
```

**_Important Note_**: See how the defined file has a unique circuit (ckt) name (i.e., `New Circuit.3bus_bal`). It is important that for scenarios where multiple distribution systems are to be used, each distribution system file must have a **unique** ckt name. Otherwise, PowerModelsITD.jl will generate an **error** indicating the user that they must input distribution systems with unique names (or use the `auto_rename=true` option explained later).

## Boundary

The file shown below shows the **ideal** format to be used when defining the boundary connections in the JSON file. For transmission system boundary buses, the name of the bus is sufficient. For distribution systems, especially, cases where multiple distribution systems will be inputted, the **ideal** format for `distribution_boundary` names is `circuit_name.object.name_of_object`. In this example, two distribution systems (`3bus_unbal` and `3bus_bal`) are going to be connected to buses **5** and **6** in the transmission system.

- **JSON (".json")**

```julia
[
	{
        "transmission_boundary": "5",
        "distribution_boundary": "3bus_unbal.voltage_source.source"
	},

	{
        "transmission_boundary": "6",
        "distribution_boundary": "3bus_bal.voltage_source.source"
        }
]
```

As observed in the file, we follow the **ideal** format when defining the `distribution_boundary` names. If this format is **not** followed (and the `auto_rename=true` option is not used), **errors** will be displayed by PowerModelsITD.jl. Errors ranging from `"The distribution bus/source specified in the JSON file does not exists. Please input an existing bus/source!"` to `"Distribution systems have same circuit names! Please use different names for each distribution system. (e.g., New Circuit.NameOfCkt) or use the auto_rename=true option."` will be displayed warning the user that something is wrong with the JSON file information provided.

But, what happens when we would like to use the **same** distribution system file to create multiple dsitribution systems connected at different transmission system boundary buses. In other words, _we don't care too much about the names of the distribution circuits, and the boundary names in the JSON file are inputted in a sequential order_. Then, for use with **caution**, PowerModelsITD.jl supports the use of an **auto-renaming** option that renames **repeated** circuits in a sequential manner such as: `pmd_files = [pmd, pmd, ..., pmd]`, `pmd_cktName_1`, `pmd_cktName_2`, ..., `pmd_cktName_n`.

**_Important Note_**: All elements/components inside the `pmd=>` dictionary will always be renamed based on the format `ckt_name.component_name`

## The `auto_rename=true` Option

**_Important Note_**: Use this option with **extreme caution!** When this option is used, a `@warn` will be displayed such that the user is aware that the boundary connections **may be wrong** because they are assigned/connected in a sequential manner and not based on buses names.

Let's go through an example case where we would like to use the same distribution system file to create a test case where multiple distribution systems (with the same name) are connected to different transmission system boundary buses. And, **we don't care** about the specific boundary connections since they can be done sequentially (since all or some distribution systems will be a copy of the same circuit and will have the same names).

Let's first define the test case in Julia:

```julia
using PowerModelsITD
using Ipopt

pm_file = joinpath(dirname(trans_path), "case5_with2loads.m")
pmd_file = joinpath(dirname(dist_path), "case3_unbalanced_withoutgen.dss")
pmd_files = [pmd_file, pmd_file] # vector of multiple distro. systems copies
pmitd_file = joinpath(dirname(bound_path), "case5_case3x2.json")
pmitd_type = NLPowerModelITD{ACPPowerModel, ACPUPowerModel}

result = solve_opfitd(pm_file, pmd_files, pmitd_file, pmitd_type, Ipopt.Optimizer; auto_rename=true)
```

Another way to define and solve the problem could be (both ways are equivalent):

```julia
using PowerModelsITD
using Ipopt

pm_file = joinpath(dirname(trans_path), "case5_with2loads.m")
pmd_file = joinpath(dirname(dist_path), "case3_unbalanced_withoutgen.dss")
pmd_files = [pmd_file, pmd_file] # vector of multiple distro. systems copies
pmitd_file = joinpath(dirname(bound_path), "case5_case3x2.json")
pmitd_type = NLPowerModelITD{ACPPowerModel, ACPUPowerModel}

pmitd_data = parse_files(pm_file, pmd_files, pmitd_file; auto_rename=true)
result = solve_model(pmitd_data, pmitd_type, Ipopt.Optimizer, build_opfitd)
```

Note, how the option `auto_rename=true` is defined such that PowerModelsITD.jl can understand that we don't care about the specific names of the circuits (because we are repeating ckts) so we are allowing the application to **auto-rename** the ckts as needed for its correct operation. If the `auto_rename` option is not defined, errors will be displayed.

The JSON file for this example is defined as:

```julia
[
	{
        "transmission_boundary": "5",
        "distribution_boundary": "voltage_source.source"
	},

	{
        "transmission_boundary": "6",
        "distribution_boundary": "voltage_source.source"
        }
]
```

See how we **do not** need to especifically define the circuit names, but we still need to define the `object.name_of_object`. Internally, PowerModelsITD.jl will parse the files and assign the names: `3bus_unbal_nogen_1` and `3bus_unbal_nogen_2` as the names of the circuits (based on the `ckt_name_n` standard format).

**_Important Note_**: In the case where multiple distribuition systems are defined, let's say 3 or more, and only two have the same circuit name, if `auto_rename=false` (i.e., not used) errors will be displayed, if `auto_rename=true` only the repeated circuits will be renamed (in this case, all repeated circuits after the first one).

**_The `auto rename` option can be very useful for some cases, but users must be very careful when using it since specific boundary connections are going to be performed in a sequential manner and PowerModelsITD.jl cannot guarantee that this is what the user is expecting. To avoid confusions, we recommend users stick to the ideal boundary linking file JSON format._**

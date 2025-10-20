% Generated from the OpenDSS file, case3_balanced_withoutgen

function mpc = case3_bal_nogen
mpc.version = '2';
mpc.baseMVA = 100;

%% bus data
%  bus_i type Pd Qd  Gs Bs area Vm Va baseKV zone Vmax Vmin
mpc.bus = [
	1	3	0	    0	   0	0	1	1.00	0	230	1	1.05	0.95;
	2	1	100	    60	   0	0	1	1.00	0	230	1	1.05	0.95;
	3	1	90	    40	   0	0	1	1.00	0	230	1	1.05	0.95;
];

%% generator data
%  bus	Pg	Qg	Qmax	Qmin	Vg	mBase	status	Pmax	Pmin
mpc.gen = [
	1	0	0	300	-300	1.00	100	1	300	0;
];

%% branch data
%  fbus tbus	r	x	b	rateA rateB rateC	ratio	angle	status	angmin	angmax
mpc.branch = [
	1	2	0.010	0.085	0.176	250	250	250	0	0	1	-360	360;
	1	3	0.017	0.092	0.158	250	250	250	0	0	1	-360	360;
	2	3	0.032	0.161	0.306	150	150	150	0	0	1	-360	360;
];

%% generator cost data
% 2 startup shutdown n c(n-1) ... c0
mpc.gencost = [
	2	0	0	3	0.02	2	0;
];
# ITD Network Formulations

There is a diverse number of formulations that can be used to solve the `OPFITD`, `PFITD`, and other problem specifications. These can be found in `types.jl`. A non-exhaustive list of the **supported ITD boundary mathematical formulations** is presented below.

## Sets, Parameters, and (General) Variables

```math
\begin{align}
%
\mbox{sets:} & \nonumber \\
& N \mbox{ - Set of buses}\nonumber \\
& \mathcal{T} \mbox{ - Belongs to transmission network}\nonumber \\
& \mathcal{D} \mbox{ - Belongs to distribution network}\nonumber \\
& \mathcal{B} \mbox{ - Set of boundary links}\nonumber \\
%
\mbox{parameters:} & \nonumber \\
& \Re \mbox{ - Real part}\nonumber \\
& \Im \mbox{ - Imaginary part}\nonumber \\
& \Phi = a, b, c \mbox{ - Multi-conductor phases}\nonumber \\
& \chi \rightarrow{\mathcal{T}},{\mathcal{D}} \mbox{ - Belongs to Transmission or Distribution}\nonumber \\
& \beta^{^{\chi}} \mbox{ - Boundary bus}\nonumber \\
%
\mbox{variables:} & \nonumber \\
& P_{\beta^{^\mathcal{T}}\beta^{^\mathcal{D}}}^{^\mathcal{T}} \mbox{ - Active power flow from Transmisison boundary bus to Distribution boundary bus}\nonumber \\
& Q_{\beta^{^\mathcal{T}}\beta^{^\mathcal{D}}}^{^\mathcal{T}} \mbox{ - Reactive power flow from Transmisison boundary bus to Distribution boundary bus}\nonumber \\
& P_{\beta^{^\mathcal{D}}\beta^{^\mathcal{T}}}^{{\mathcal{D},\varphi}} \mbox{ - Active power flow from Distribution boundary bus phase $\varphi$ to Transmission boundary bus}\nonumber \\
& Q_{\beta^{^\mathcal{D}}\beta^{^\mathcal{T}}}^{{\mathcal{D},\varphi}} \mbox{ - Reactive power flow from Distribution boundary bus phase $\varphi$ to Transmission boundary bus}\nonumber \\
& V_i^{^\mathcal{T}} \mbox{ - Voltage magnitude at bus $i$}\nonumber \\
& \theta_i^{^\mathcal{T}} \mbox{ - Voltage angle at bus $i$}\nonumber \\
& v_i^{\mathcal{D}, \varphi} \mbox{ - Voltage magnitude at bus $i$ phase $\varphi$}\nonumber \\
& \theta_i^{\mathcal{D}, \varphi} \mbox{ - Voltage angle at bus $i$ phase $\varphi$}\nonumber \\
%
\end{align}
```

## ACP-ACPU

[`NLPowerModelITD{ACPPowerModel, ACPUPowerModel}`](@ref NLPowerModelITD)

ACP to ACPU (AC polar to AC polar unbalanced)

- **Coordinates**: Polar
- **Variables**: Power-Voltage
- **Model(s)**: NLP-NLP
- **ITD Boundary Math. Formulation**:

```math
\begin{align}
%
\mbox{ITD boundaries: } & \nonumber \\
& \sum_{\varphi \in \Phi} P_{\beta^{^\mathcal{D}}\beta^{^\mathcal{T}}}^{\mathcal{D},\varphi} +  P_{\beta^{^\mathcal{T}}\beta^{^\mathcal{D}}}^{^\mathcal{T}} = 0, \ \forall (\beta^{^\mathcal{T}},\beta^{^\mathcal{D}}) \in {\Lambda} \mbox{ - Active power flow at boundary} \\
& \sum_{\varphi \in \Phi} Q_{\beta^{^\mathcal{D}}\beta^{^\mathcal{T}}}^{\mathcal{D},\varphi} +  Q_{\beta^{^\mathcal{T}}\beta^{^\mathcal{D}}}^{^\mathcal{T}} = 0, \ \forall (\beta^{^\mathcal{T}},\beta^{^\mathcal{D}}) \in {\Lambda} \mbox{ - Reactive power flow at boundary} \\
& V_{\beta^{^\mathcal{T}}} = v_{\beta^{^\mathcal{D}}}^{^{a}}, \ \forall (\beta^{^\mathcal{T}},\beta^{^\mathcal{D}}) \in {\Lambda} \mbox{ - Voltage mag. equality - phase a} \\
& V_{\beta^{^\mathcal{T}}} = v_{\beta^{^\mathcal{D}}}^{^{b}}, \ \forall (\beta^{^\mathcal{T}},\beta^{^\mathcal{D}}) \in {\Lambda} \mbox{ - Voltage mag. equality - phase b} \\
& V_{\beta^{^\mathcal{T}}} = v_{\beta^{^\mathcal{D}}}^{^{c}}, \ \forall (\beta^{^\mathcal{T}},\beta^{^\mathcal{D}}) \in {\Lambda} \mbox{ - Voltage mag. equality - phase c} \\
& \theta_{\beta^{^\mathcal{T}}} = \theta_{\beta^{^\mathcal{D}}}^{^{a}}, \ \forall (\beta^{^\mathcal{T}},\beta^{^\mathcal{D}}) \in {\Lambda} \mbox{ - Voltage ang. equality - phase a} \\
& \theta_{\beta^{^\mathcal{D}}}^{^{b}} = (\theta_{\beta^{^\mathcal{D}}}^{^{a}} -120^{\circ}),  \ \forall \beta^{^\mathcal{D}} \in N^{^\mathcal{B}} \cap  N^{^\mathcal{D}} \mbox{ - Voltage ang. equality - phase b} \\
& \theta_{\beta^{^\mathcal{D}}}^{^{c}} = (\theta_{\beta^{^\mathcal{D}}}^{^{a}} +120^{\circ}), \ \forall \beta^{^\mathcal{D}} \in N^{^\mathcal{B}} \cap  N^{^\mathcal{D}} \mbox{ - Voltage ang. equality - phase c} \\
%
\end{align}
```

## ACR-ACRU

[`NLPowerModelITD{ACRPowerModel, ACRUPowerModel}`](@ref NLPowerModelITD)

ACR to ACRU (AC rectangular to AC rectangular unbalanced)

- **Coordinates**: Rectangular
- **Variables**: Power-Voltage
- **Model(s)**: NLP-NLP
- **ITD Boundary Math. Formulation**:

```math
\begin{align}
%
\mbox{ITD boundaries: } & \nonumber \\
& \sum_{\varphi \in \Phi} P_{\beta^{^\mathcal{D}}\beta^{^\mathcal{T}}}^{\mathcal{D},\varphi} +  P_{\beta^{^\mathcal{T}}\beta^{^\mathcal{D}}}^{^\mathcal{T}} = 0, \ \forall (\beta^{^\mathcal{T}},\beta^{^\mathcal{D}}) \in {\Lambda} \mbox{ - Active power flow at boundary} \\
& \sum_{\varphi \in \Phi} Q_{\beta^{^\mathcal{D}}\beta^{^\mathcal{T}}}^{\mathcal{D},\varphi} +  Q_{\beta^{^\mathcal{T}}\beta^{^\mathcal{D}}}^{^\mathcal{T}} = 0, \ \forall (\beta^{^\mathcal{T}},\beta^{^\mathcal{D}}) \in {\Lambda} \mbox{ - Reactive power flow at boundary} \\
& \Big({V^\Re_{\beta^{^\mathcal{T}}}}\Big)^2 \!\!\!\! + \! \Big({V^\Im_{\beta^{^\mathcal{T}}}}\Big)^2 \!\!\!\! = \!\Big(v_{\beta^{^\mathcal{D}}}^{^{a,\Re}}\Big)^2 \!\!\!\!+\! \Big(v_{\beta^{^\mathcal{D}}}^{^{a,\Im}}\Big)^2,\forall (\beta^{^\mathcal{T}},\beta^{^\mathcal{D}}) \in \Lambda \mbox{ - Voltage mag. equality - phase a} \\
& \Big({V^\Re_{\beta^{^\mathcal{T}}}}\Big)^2 \!\!\!\!+\! \Big({V^\Im_{\beta^{^\mathcal{T}}}}\Big)^2 \!\!\!\!=\! \Big(v_{\beta^{^\mathcal{D}}}^{^{b,\Re}}\Big)^2 \!\!\!\!+\! \Big(v_{\beta^{^\mathcal{D}}}^{^{b,\Im}}\Big)^2,\forall (\beta^{^\mathcal{T}},\beta^{^\mathcal{D}}) \in \Lambda \mbox{ - Voltage mag. equality - phase b} \\
& \Big({V^\Re_{\beta^{^\mathcal{T}}}}\Big)^2 \!\!\!\!+\! \Big({V^\Im_{\beta^{^\mathcal{T}}}}\Big)^2 \!\!\!\!=\! \Big(v_{\beta^{^\mathcal{D}}}^{^{c,\Re}}\Big)^2 \!\!\!\!+\! \Big(v_{\beta^{^\mathcal{D}}}^{^{c,\Im}}\Big)^2,\forall (\beta^{^\mathcal{T}},\beta^{^\mathcal{D}}) \in \Lambda \mbox{ - Voltage mag. equality - phase c} \\
& \Big({V^\Im_{\beta^{^\mathcal{T}}}}\Big) = \Big(v_{\beta^{^\mathcal{D}}}^{^{a,\Im}}\Big),\ \ \ \forall (\beta^{^\mathcal{T}},\beta^{^\mathcal{D}}) \in \Lambda \mbox{ - Voltage ang. equality - phase a} \\
& \Big(v_{\beta^{^\mathcal{D}}}^{^{b,\Im}}\Big) = tan\Bigg(atan\bigg(\frac{v_{\beta^{^\mathcal{D}}}^{^{a,\Im}}}{v_{\beta^{^\mathcal{D}}}^{^{a,\Re}}} \bigg) -120^{\circ} \Bigg) v_{\beta^{^\mathcal{D}}}^{^{b,\Re}}, \ \forall \beta^{^\mathcal{D}} \in N^{^\mathcal{B}} \cap  N^{^\mathcal{D}} \mbox{ - Voltage ang. equality - phase b} \\
& \Big(v_{\beta^{^\mathcal{D}}}^{^{c,\Im}}\Big) = tan\Bigg(atan\bigg(\frac{v_{\beta^{^\mathcal{D}}}^{^{a,\Im}}}{v_{\beta^{^\mathcal{D}}}^{^{a,\Re}}} \bigg) +120^{\circ} \Bigg) v_{\beta^{^\mathcal{D}}}^{^{c,\Re}}, \ \forall \beta^{^\mathcal{D}} \in N^{^\mathcal{B}} \cap  N^{^\mathcal{D}} \mbox{ - Voltage ang. equality - phase c} \\
%
\end{align}
```

## IVR-IVRU

[`IVRPowerModelITD{IVRPowerModel, IVRUPowerModel}`](@ref IVRPowerModelITD)

IVR to IVRU (AC-IV rectangular to AC-IV rectangular unbalanced)

- **Coordinates**: Rectangular
- **Variables**: Current-Voltage
- **Model(s)**: NLP-NLP
- **ITD Boundary Math. Formulation**:

```math
\begin{align}
%
\mbox{ITD boundaries: } & \nonumber \\
& {V^\Re_{\beta^{^\mathcal{T}}}} \Re\Big(I_{\beta^{^\mathcal{T}}\beta^{^\mathcal{D}}}^{^\mathcal{T}}\Big) + {V^\Im_{\beta^{^\mathcal{T}}}} \Im\Big(I_{\beta^{^\mathcal{T}}\beta^{^\mathcal{D}}}^{^\mathcal{T}}\Big) = \!\!-\!\!\Bigg[\sum_{\varphi \in \Phi} \Bigg( \Big(v_{\beta^{^\mathcal{D}}}^{^{\varphi,\Re}}\Big) \Re\Big(I_{\beta^{^\mathcal{D}}\beta^{^\mathcal{T}}}^{\mathcal{D},\varphi}\Big) \!\!+\!\! \Big(v_{\beta^{^\mathcal{D}}}^{^{\varphi,\Im}}\Big) \Im\Big(I_{\beta^{^\mathcal{D}}\beta^{^\mathcal{T}}}^{\mathcal{D},\varphi}\Big) \Bigg) \Bigg], \ \forall (\beta^{^\mathcal{T}},\beta^{^\mathcal{D}}) \in \Lambda \mbox{ - Active power flow at boundary} \\
& {V^\Im_{\beta^{^\mathcal{T}}}} \Re\Big(I_{\beta^{^\mathcal{T}}\beta^{^\mathcal{D}}}^{^\mathcal{T}}\Big) - {V^\Re_{\beta^{^\mathcal{T}}}} \Im\Big(I_{\beta^{^\mathcal{T}}\beta^{^\mathcal{D}}}^{^\mathcal{T}}\Big) = \!\!-\!\! \Bigg[\sum_{\varphi \in \Phi} \Bigg( \Big(v_{\beta^{^\mathcal{D}}}^{^{\varphi,\Im}}\Big) \Re\Big(I_{\beta^{^\mathcal{D}}\beta^{^\mathcal{T}}}^{\mathcal{D},\varphi}\Big) \!\!-\!\! \Big(v_{\beta^{^\mathcal{D}}}^{^{\varphi,\Re}}\Big) \Im\Big(I_{\beta^{^\mathcal{D}}\beta^{^\mathcal{T}}}^{\mathcal{D},\varphi}\Big) \Bigg) \Bigg], \ \forall (\beta^{^\mathcal{T}},\beta^{^\mathcal{D}}) \in \Lambda \mbox{ - Reactive power flow at boundary} \\
& \Big({V^\Re_{\beta^{^\mathcal{T}}}}\Big)^2 \!\!\!\! + \! \Big({V^\Im_{\beta^{^\mathcal{T}}}}\Big)^2 \!\!\!\! = \!\Big(v_{\beta^{^\mathcal{D}}}^{^{a,\Re}}\Big)^2 \!\!\!\!+\! \Big(v_{\beta^{^\mathcal{D}}}^{^{a,\Im}}\Big)^2,\forall (\beta^{^\mathcal{T}},\beta^{^\mathcal{D}}) \in \Lambda \mbox{ - Voltage mag. equality - phase a} \\
& \Big({V^\Re_{\beta^{^\mathcal{T}}}}\Big)^2 \!\!\!\!+\! \Big({V^\Im_{\beta^{^\mathcal{T}}}}\Big)^2 \!\!\!\!=\! \Big(v_{\beta^{^\mathcal{D}}}^{^{b,\Re}}\Big)^2 \!\!\!\!+\! \Big(v_{\beta^{^\mathcal{D}}}^{^{b,\Im}}\Big)^2,\forall (\beta^{^\mathcal{T}},\beta^{^\mathcal{D}}) \in \Lambda \mbox{ - Voltage mag. equality - phase b} \\
& \Big({V^\Re_{\beta^{^\mathcal{T}}}}\Big)^2 \!\!\!\!+\! \Big({V^\Im_{\beta^{^\mathcal{T}}}}\Big)^2 \!\!\!\!=\! \Big(v_{\beta^{^\mathcal{D}}}^{^{c,\Re}}\Big)^2 \!\!\!\!+\! \Big(v_{\beta^{^\mathcal{D}}}^{^{c,\Im}}\Big)^2,\forall (\beta^{^\mathcal{T}},\beta^{^\mathcal{D}}) \in \Lambda \mbox{ - Voltage mag. equality - phase c} \\
& \Big({V^\Im_{\beta^{^\mathcal{T}}}}\Big) = \Big(v_{\beta^{^\mathcal{D}}}^{^{a,\Im}}\Big),\ \ \ \forall (\beta^{^\mathcal{T}},\beta^{^\mathcal{D}}) \in \Lambda \mbox{ - Voltage ang. equality - phase a} \\
& \Big(v_{\beta^{^\mathcal{D}}}^{^{b,\Im}}\Big) = tan\Bigg(atan\bigg(\frac{v_{\beta^{^\mathcal{D}}}^{^{a,\Im}}}{v_{\beta^{^\mathcal{D}}}^{^{a,\Re}}} \bigg) -120^{\circ} \Bigg) v_{\beta^{^\mathcal{D}}}^{^{b,\Re}}, \ \forall \beta^{^\mathcal{D}} \in N^{^\mathcal{B}} \cap  N^{^\mathcal{D}} \mbox{ - Voltage ang. equality - phase b} \\
& \Big(v_{\beta^{^\mathcal{D}}}^{^{c,\Im}}\Big) = tan\Bigg(atan\bigg(\frac{v_{\beta^{^\mathcal{D}}}^{^{a,\Im}}}{v_{\beta^{^\mathcal{D}}}^{^{a,\Re}}} \bigg) +120^{\circ} \Bigg) v_{\beta^{^\mathcal{D}}}^{^{c,\Re}}, \ \forall \beta^{^\mathcal{D}} \in N^{^\mathcal{B}} \cap  N^{^\mathcal{D}} \mbox{ - Voltage ang. equality - phase c} \\
%
\end{align}
```

## NFA-NFAU

[`LPowerModelITD{NFAPowerModel, NFAUPowerModel}`](@ref LPowerModelITD)

NFA to NFAU (Linear Network flow approximation to Linear Network flow approximation unbalanced)

- **Coordinates**: N/A
- **Variables**: N/A
- **Model(s)**: Apprx.-Apprx.
- **ITD Boundary Math. Formulation**:

```math
\begin{align}
%
\mbox{ITD boundaries: } & \nonumber \\
& \sum_{\varphi \in \Phi} P_{\beta^{^\mathcal{D}}\beta^{^\mathcal{T}}}^{\mathcal{D},\varphi} +  P_{\beta^{^\mathcal{T}}\beta^{^\mathcal{D}}}^{^\mathcal{T}} = 0, \ \forall (\beta^{^\mathcal{T}},\beta^{^\mathcal{D}}) \in {\Lambda} \mbox{ - Active power flow at boundary} \\
& \sum_{\varphi \in \Phi} Q_{\beta^{^\mathcal{D}}\beta^{^\mathcal{T}}}^{\mathcal{D},\varphi} +  Q_{\beta^{^\mathcal{T}}\beta^{^\mathcal{D}}}^{^\mathcal{T}} = 0, \ \forall (\beta^{^\mathcal{T}},\beta^{^\mathcal{D}}) \in {\Lambda} \mbox{ - Reactive power flow at boundary} \\
%
\end{align}
```

## ACR-FBSUBF

[`NLBFPowerModelITD{ACRPowerModel, FBSUBFPowerModel}`](@ref NLBFPowerModelITD)

ACR to FBSUBF (AC rectangular to forward-backward sweep unbalanced branch flow approximation)

- **Coordinates**: Rectangular
- **Variables**: Power-Voltage
- **Model(s)**: NLP-Apprx.
- **ITD Boundary Math. Formulation**:

```math
\begin{align}
%
\mbox{ITD boundaries: } & \nonumber \\
& \sum_{\varphi \in \Phi} P_{\beta^{^\mathcal{D}}\beta^{^\mathcal{T}}}^{\mathcal{D},\varphi} +  P_{\beta^{^\mathcal{T}}\beta^{^\mathcal{D}}}^{^\mathcal{T}} = 0, \ \forall (\beta^{^\mathcal{T}},\beta^{^\mathcal{D}}) \in {\Lambda} \mbox{ - Active power flow at boundary} \\
& \sum_{\varphi \in \Phi} Q_{\beta^{^\mathcal{D}}\beta^{^\mathcal{T}}}^{\mathcal{D},\varphi} +  Q_{\beta^{^\mathcal{T}}\beta^{^\mathcal{D}}}^{^\mathcal{T}} = 0, \ \forall (\beta^{^\mathcal{T}},\beta^{^\mathcal{D}}) \in {\Lambda} \mbox{ - Reactive power flow at boundary} \\
& \Big({V^\Re_{\beta^{^\mathcal{T}}}}\Big)^2 \!\!\!\! + \! \Big({V^\Im_{\beta^{^\mathcal{T}}}}\Big)^2 \!\!\!\! = \!\Big(v_{\beta^{^\mathcal{D}}}^{^{a,\Re}}\Big)^2 \!\!\!\!+\! \Big(v_{\beta^{^\mathcal{D}}}^{^{a,\Im}}\Big)^2,\forall (\beta^{^\mathcal{T}},\beta^{^\mathcal{D}}) \in \Lambda \mbox{ - Voltage mag. equality - phase a} \\
& \Big({V^\Re_{\beta^{^\mathcal{T}}}}\Big)^2 \!\!\!\!+\! \Big({V^\Im_{\beta^{^\mathcal{T}}}}\Big)^2 \!\!\!\!=\! \Big(v_{\beta^{^\mathcal{D}}}^{^{b,\Re}}\Big)^2 \!\!\!\!+\! \Big(v_{\beta^{^\mathcal{D}}}^{^{b,\Im}}\Big)^2,\forall (\beta^{^\mathcal{T}},\beta^{^\mathcal{D}}) \in \Lambda \mbox{ - Voltage mag. equality - phase b} \\
& \Big({V^\Re_{\beta^{^\mathcal{T}}}}\Big)^2 \!\!\!\!+\! \Big({V^\Im_{\beta^{^\mathcal{T}}}}\Big)^2 \!\!\!\!=\! \Big(v_{\beta^{^\mathcal{D}}}^{^{c,\Re}}\Big)^2 \!\!\!\!+\! \Big(v_{\beta^{^\mathcal{D}}}^{^{c,\Im}}\Big)^2,\forall (\beta^{^\mathcal{T}},\beta^{^\mathcal{D}}) \in \Lambda \mbox{ - Voltage mag. equality - phase c} \\
& \Big({V^\Im_{\beta^{^\mathcal{T}}}}\Big) = \Big(v_{\beta^{^\mathcal{D}}}^{^{a,\Im}}\Big),\ \ \ \forall (\beta^{^\mathcal{T}},\beta^{^\mathcal{D}}) \in \Lambda \mbox{ - Voltage ang. equality - phase a} \\
& \Big(v_{\beta^{^\mathcal{D}}}^{^{b,\Im}}\Big) = tan\Bigg(atan\bigg(\frac{v_{\beta^{^\mathcal{D}}}^{^{a,\Im}}}{v_{\beta^{^\mathcal{D}}}^{^{a,\Re}}} \bigg) -120^{\circ} \Bigg) v_{\beta^{^\mathcal{D}}}^{^{b,\Re}}, \ \forall \beta^{^\mathcal{D}} \in N^{^\mathcal{B}} \cap  N^{^\mathcal{D}} \mbox{ - Voltage ang. equality - phase b} \\
& \Big(v_{\beta^{^\mathcal{D}}}^{^{c,\Im}}\Big) = tan\Bigg(atan\bigg(\frac{v_{\beta^{^\mathcal{D}}}^{^{a,\Im}}}{v_{\beta^{^\mathcal{D}}}^{^{a,\Re}}} \bigg) +120^{\circ} \Bigg) v_{\beta^{^\mathcal{D}}}^{^{c,\Re}}, \ \forall \beta^{^\mathcal{D}} \in N^{^\mathcal{B}} \cap  N^{^\mathcal{D}} \mbox{ - Voltage ang. equality - phase c} \\
%
\end{align}
```

## ACR-FOTRU

[`NLFOTPowerModelITD{ACRPowerModel, FOTRUPowerModel}`](@ref NLFOTPowerModelITD)

ACR to FOTRU (AC rectangular to first-order Taylor rectangular unbalanced approximation)

- **Coordinates**: Rectangular
- **Variables**: Power-Voltage
- **Model(s)**: NLP-Apprx.
- **ITD Boundary Math. Formulation**:

```math
\begin{align}
%
\mbox{ITD boundaries: } & \nonumber \\
& \sum_{\varphi \in \Phi} P_{\beta^{^\mathcal{D}}\beta^{^\mathcal{T}}}^{\mathcal{D},\varphi} +  P_{\beta^{^\mathcal{T}}\beta^{^\mathcal{D}}}^{^\mathcal{T}} = 0, \ \forall (\beta^{^\mathcal{T}},\beta^{^\mathcal{D}}) \in {\Lambda} \mbox{ - Active power flow at boundary} \\
& \sum_{\varphi \in \Phi} Q_{\beta^{^\mathcal{D}}\beta^{^\mathcal{T}}}^{\mathcal{D},\varphi} +  Q_{\beta^{^\mathcal{T}}\beta^{^\mathcal{D}}}^{^\mathcal{T}} = 0, \ \forall (\beta^{^\mathcal{T}},\beta^{^\mathcal{D}}) \in {\Lambda} \mbox{ - Reactive power flow at boundary} \\
& \Big({V^\Re_{\beta^{^\mathcal{T}}}}\Big)^2 \!\!\!\! + \! \Big({V^\Im_{\beta^{^\mathcal{T}}}}\Big)^2 \!\!\!\! = \!\Big(v_{\beta^{^\mathcal{D}}}^{^{a,\Re}}\Big)^2 \!\!\!\!+\! \Big(v_{\beta^{^\mathcal{D}}}^{^{a,\Im}}\Big)^2,\forall (\beta^{^\mathcal{T}},\beta^{^\mathcal{D}}) \in \Lambda \mbox{ - Voltage mag. equality - phase a} \\
& \Big({V^\Re_{\beta^{^\mathcal{T}}}}\Big)^2 \!\!\!\!+\! \Big({V^\Im_{\beta^{^\mathcal{T}}}}\Big)^2 \!\!\!\!=\! \Big(v_{\beta^{^\mathcal{D}}}^{^{b,\Re}}\Big)^2 \!\!\!\!+\! \Big(v_{\beta^{^\mathcal{D}}}^{^{b,\Im}}\Big)^2,\forall (\beta^{^\mathcal{T}},\beta^{^\mathcal{D}}) \in \Lambda \mbox{ - Voltage mag. equality - phase b} \\
& \Big({V^\Re_{\beta^{^\mathcal{T}}}}\Big)^2 \!\!\!\!+\! \Big({V^\Im_{\beta^{^\mathcal{T}}}}\Big)^2 \!\!\!\!=\! \Big(v_{\beta^{^\mathcal{D}}}^{^{c,\Re}}\Big)^2 \!\!\!\!+\! \Big(v_{\beta^{^\mathcal{D}}}^{^{c,\Im}}\Big)^2,\forall (\beta^{^\mathcal{T}},\beta^{^\mathcal{D}}) \in \Lambda \mbox{ - Voltage mag. equality - phase c} \\
& \Big({V^\Im_{\beta^{^\mathcal{T}}}}\Big) = \Big(v_{\beta^{^\mathcal{D}}}^{^{a,\Im}}\Big),\ \ \ \forall (\beta^{^\mathcal{T}},\beta^{^\mathcal{D}}) \in \Lambda \mbox{ - Voltage ang. equality - phase a} \\
& \Big(v_{\beta^{^\mathcal{D}}}^{^{b,\Im}}\Big) = tan\Bigg(atan\bigg(\frac{v_{\beta^{^\mathcal{D}}}^{^{a,\Im}}}{v_{\beta^{^\mathcal{D}}}^{^{a,\Re}}} \bigg) -120^{\circ} \Bigg) v_{\beta^{^\mathcal{D}}}^{^{b,\Re}}, \ \forall \beta^{^\mathcal{D}} \in N^{^\mathcal{B}} \cap  N^{^\mathcal{D}} \mbox{ - Voltage ang. equality - phase b} \\
& \Big(v_{\beta^{^\mathcal{D}}}^{^{c,\Im}}\Big) = tan\Bigg(atan\bigg(\frac{v_{\beta^{^\mathcal{D}}}^{^{a,\Im}}}{v_{\beta^{^\mathcal{D}}}^{^{a,\Re}}} \bigg) +120^{\circ} \Bigg) v_{\beta^{^\mathcal{D}}}^{^{c,\Re}}, \ \forall \beta^{^\mathcal{D}} \in N^{^\mathcal{B}} \cap  N^{^\mathcal{D}} \mbox{ - Voltage ang. equality - phase c} \\
%
\end{align}
```

## ACP-FOTPU

[`NLFOTPowerModelITD{ACPPowerModel, FOTPUPowerModel}`](@ref NLFOTPowerModelITD)

ACP to FOTPU (AC rectangular to first-order Taylor polar unbalanced approximation)

- **Coordinates**: Polar
- **Variables**: Power-Voltage
- **Model(s)**: NLP-Apprx.
- **ITD Boundary Math. Formulation**:

```math
\begin{align}
%
\mbox{ITD boundaries: } & \nonumber \\
& \sum_{\varphi \in \Phi} P_{\beta^{^\mathcal{D}}\beta^{^\mathcal{T}}}^{\mathcal{D},\varphi} +  P_{\beta^{^\mathcal{T}}\beta^{^\mathcal{D}}}^{^\mathcal{T}} = 0, \ \forall (\beta^{^\mathcal{T}},\beta^{^\mathcal{D}}) \in {\Lambda} \mbox{ - Active power flow at boundary} \\
& \sum_{\varphi \in \Phi} Q_{\beta^{^\mathcal{D}}\beta^{^\mathcal{T}}}^{\mathcal{D},\varphi} +  Q_{\beta^{^\mathcal{T}}\beta^{^\mathcal{D}}}^{^\mathcal{T}} = 0, \ \forall (\beta^{^\mathcal{T}},\beta^{^\mathcal{D}}) \in {\Lambda} \mbox{ - Reactive power flow at boundary} \\
& V_{\beta^{^\mathcal{T}}} = v_{\beta^{^\mathcal{D}}}^{^{a}}, \ \forall (\beta^{^\mathcal{T}},\beta^{^\mathcal{D}}) \in {\Lambda} \mbox{ - Voltage mag. equality - phase a} \\
& V_{\beta^{^\mathcal{T}}} = v_{\beta^{^\mathcal{D}}}^{^{b}}, \ \forall (\beta^{^\mathcal{T}},\beta^{^\mathcal{D}}) \in {\Lambda} \mbox{ - Voltage mag. equality - phase b} \\
& V_{\beta^{^\mathcal{T}}} = v_{\beta^{^\mathcal{D}}}^{^{c}}, \ \forall (\beta^{^\mathcal{T}},\beta^{^\mathcal{D}}) \in {\Lambda} \mbox{ - Voltage mag. equality - phase c} \\
& \theta_{\beta^{^\mathcal{T}}} = \theta_{\beta^{^\mathcal{D}}}^{^{a}}, \ \forall (\beta^{^\mathcal{T}},\beta^{^\mathcal{D}}) \in {\Lambda} \mbox{ - Voltage ang. equality - phase a} \\
& \theta_{\beta^{^\mathcal{D}}}^{^{b}} = (\theta_{\beta^{^\mathcal{D}}}^{^{a}} -120^{\circ}),  \ \forall \beta^{^\mathcal{D}} \in N^{^\mathcal{B}} \cap  N^{^\mathcal{D}} \mbox{ - Voltage ang. equality - phase b} \\
& \theta_{\beta^{^\mathcal{D}}}^{^{c}} = (\theta_{\beta^{^\mathcal{D}}}^{^{a}} +120^{\circ}), \ \forall \beta^{^\mathcal{D}} \in N^{^\mathcal{B}} \cap  N^{^\mathcal{D}} \mbox{ - Voltage ang. equality - phase c} \\
%
\end{align}
```

## BFA-LinDist3Flow

[`BFPowerModelITD{BFAPowerModel, LinDist3FlowPowerModel}`](@ref BFPowerModelITD)

BFA to LinDist3Flow (Branch flow approximation to LinDist3Flow approximation)

- **Coordinates**: W-space
- **Variables**: Power-Voltage (W)
- **Model(s)**: Apprx.-Apprx.
- **ITD Boundary Math. Formulation**:

```math
\begin{align}
%
\mbox{ITD boundaries: } & \nonumber \\
& \sum_{\varphi \in \Phi} P_{\beta^{^\mathcal{D}}\beta^{^\mathcal{T}}}^{\mathcal{D},\varphi} +  P_{\beta^{^\mathcal{T}}\beta^{^\mathcal{D}}}^{^\mathcal{T}} = 0, \ \forall (\beta^{^\mathcal{T}},\beta^{^\mathcal{D}}) \in {\Lambda} \mbox{ - Active power flow at boundary} \\
& \sum_{\varphi \in \Phi} Q_{\beta^{^\mathcal{D}}\beta^{^\mathcal{T}}}^{\mathcal{D},\varphi} +  Q_{\beta^{^\mathcal{T}}\beta^{^\mathcal{D}}}^{^\mathcal{T}} = 0, \ \forall (\beta^{^\mathcal{T}},\beta^{^\mathcal{D}}) \in {\Lambda} \mbox{ - Reactive power flow at boundary} \\
& \Big({w_{\beta^{^\mathcal{T}}}} \Big) = \Big(w^{a}_{\beta^{^\mathcal{D}}}\Big), \ \forall (\beta^{^\mathcal{T}},\beta^{^\mathcal{D}}) \in \Lambda \mbox{ - W equality - phase a} \\
& \Big({w_{\beta^{^\mathcal{T}}}} \Big) = \Big(w^{b}_{\beta^{^\mathcal{D}}}\Big), \ \forall (\beta^{^\mathcal{T}},\beta^{^\mathcal{D}}) \in \Lambda \mbox{ - W equality - phase b} \\
& \Big({w_{\beta^{^\mathcal{T}}}} \Big) = \Big(w^{c}_{\beta^{^\mathcal{D}}}\Big), \ \forall (\beta^{^\mathcal{T}},\beta^{^\mathcal{D}}) \in \Lambda \mbox{ - W equality - phase c} \\
%
\end{align}
```

## SOCBF-LinDist3Flow

[`BFPowerModelITD{SOCBFPowerModel, LinDist3FlowPowerModel}`](@ref BFPowerModelITD)

SOCBF to LinDist3Flow (Second-order cone branch flow relaxation to LinDist3Flow approximation)

- **Coordinates**: W-space
- **Variables**: Power-Voltage (W)
- **Model(s)**: Relax.-Apprx.
- **ITD Boundary Math. Formulation**:

```math
\begin{align}
%
\mbox{ITD boundaries: } & \nonumber \\
& \sum_{\varphi \in \Phi} P_{\beta^{^\mathcal{D}}\beta^{^\mathcal{T}}}^{\mathcal{D},\varphi} +  P_{\beta^{^\mathcal{T}}\beta^{^\mathcal{D}}}^{^\mathcal{T}} = 0, \ \forall (\beta^{^\mathcal{T}},\beta^{^\mathcal{D}}) \in {\Lambda} \mbox{ - Active power flow at boundary} \\
& \sum_{\varphi \in \Phi} Q_{\beta^{^\mathcal{D}}\beta^{^\mathcal{T}}}^{\mathcal{D},\varphi} +  Q_{\beta^{^\mathcal{T}}\beta^{^\mathcal{D}}}^{^\mathcal{T}} = 0, \ \forall (\beta^{^\mathcal{T}},\beta^{^\mathcal{D}}) \in {\Lambda} \mbox{ - Reactive power flow at boundary} \\
& \Big({w_{\beta^{^\mathcal{T}}}} \Big) = \Big(w^{a}_{\beta^{^\mathcal{D}}}\Big), \ \forall (\beta^{^\mathcal{T}},\beta^{^\mathcal{D}}) \in \Lambda \mbox{ - W equality - phase a} \\
& \Big({w_{\beta^{^\mathcal{T}}}} \Big) = \Big(w^{b}_{\beta^{^\mathcal{D}}}\Big), \ \forall (\beta^{^\mathcal{T}},\beta^{^\mathcal{D}}) \in \Lambda \mbox{ - W equality - phase b} \\
& \Big({w_{\beta^{^\mathcal{T}}}} \Big) = \Big(w^{c}_{\beta^{^\mathcal{D}}}\Big), \ \forall (\beta^{^\mathcal{T}},\beta^{^\mathcal{D}}) \in \Lambda \mbox{ - W equality - phase c} \\
%
\end{align}
```

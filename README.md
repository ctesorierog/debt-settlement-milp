# Debt settlement as a MILP: settling a Tricount with the fewest transfers

Apps like Tricount and Splitwise settle shared expenses with greedy heuristics. They are fast but don't guarantee the minimum number of payments. This project formulates settlement as a **mixed-integer linear program** that provably minimises the number of transfers while settling every balance to the exact cent. It then studies an extension that caps how many payments any one person has to make.

## Model

- **Exact cents.** The total is split with `floor` plus the remainder spread one cent at a time, so balances are integers and settle exactly.
- **Variables.** `x_ij ≥ 0` is the integer amount debtor *i* pays creditor *j*. `y_ij ∈ {0,1}` is whether that transfer happens.
- **Objective.** Minimise Σ y_ij, the number of transfers.
- **Constraints.**
  - Each debtor pays exactly what they owe, and each creditor receives exactly what they are owed.
  - A Big-M link, `x_ij ≤ min(d_i, c_j) · y_ij`, uses the tightest valid M for each pair.
- **Extension.** At most K transfers per debtor: Σ_j y_ij ≤ K.

It is solved with IBM CPLEX from MATLAB.

## Experiments

35 random instances: 7 group sizes (6–17 people) × 5 seeds, with expenses drawn uniformly from 1–10,000 cents. Each instance was solved with the base model and with the cap at K = 2 and K = 3.

| Model | Feasible | Mean transfers | Mean max per debtor | Extra transfers vs. base |
|---|---|---|---|---|
| Base (no cap) | 35 / 35 | 10.4 | 3.3 | – |
| Cap K = 3 | **34 / 35** | 10.6 | 2.9 | **0** in every feasible case |
| Cap K = 2 | 26 / 35 | 10.7 | 2.0 | 0 in every feasible case |

Capping each person at three payments is almost always possible at no cost in total transfers. The report covers the formulation, why the binary variables and Big-M are needed, computational complexity (the problem is NP-hard), and comparisons with greedy and quadratic approaches.

## Files

```
src/resolver_liquidacion.m  MILP builder + CPLEX solve (base model and K cap)
src/Experiments.m           batch of 35 instances × 3 models -> resultados_bateria
src/GraficarRes.m           runtime / transfers / feasibility plots
src/Tricount.m              worked toy example (6 people)
src/TricountRestPP.m        variant with the per-person cap
results/resultados_bateria.csv
docs/report.pdf
```

## Run

You need MATLAB and IBM ILOG CPLEX (Studio 12.10). Update the `addpath` line in `resolver_liquidacion.m` to your CPLEX install, then run `Experiments.m` followed by `GraficarRes.m`.

## Team

Carlos Tesoriero (theory, formulation and report) and Felipe Salazar Molina (MATLAB/CPLEX implementation and experiments). Course project for *Optimización*, AI Engineering, Tecnun – Universidad de Navarra, April 2026.

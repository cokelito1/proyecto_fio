set of int: SOURCES     = 1..1;
set of int: TANKS       = 1..2;
set of int: TRANS_NODES = 1..4;
set of int: FINAL_NODES = 1..2;
set of int: PIPE_TYPE   = 1..3;

array [PIPE_TYPE] of int: price_of_pipe = [20, 24, 32];
array [PIPE_TYPE] of int: capacity      = [795, 1414, 3181];

array[FINAL_NODES] of float: demand_final = [51.70488, 73.41979];
array[TRANS_NODES] of float: demand_trans = [88.69506, 55.23844, 89.60512, 55.88310];

array[SOURCES, TANKS] of float: costs_sources_tanks = array2d(SOURCES, TANKS,
  [5.31812,6.35544]);

array[TANKS, TRANS_NODES] of float: costs_tanks_trans = array2d(TANKS, TRANS_NODES,
  [10.15366,6.34835,5.29613,5.43657,
   5.90857,5.17312,5.11900,8.90199]);

array[TRANS_NODES, FINAL_NODES] of float: costs_trans_final = array2d(TRANS_NODES, FINAL_NODES,
  [5.41475,8.16652,
   6.13954,5.26625,
   5.04706,6.35062,
   4.18797,3.23578]);


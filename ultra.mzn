set of int: SOURCES     = 1..1;
set of int: TANKS       = 1..2;
set of int: TRANS_NODES = 1..5;
set of int: FINAL_NODES = 1..2;
set of int: PIPE_TYPE   = 1..3;

array [PIPE_TYPE] of int: price_of_pipe = [20, 24, 32];
array [PIPE_TYPE] of int: capacity      = [795, 1414, 3181];

array[FINAL_NODES] of float: demand_final = [78.50087, 92.80892];
array[TRANS_NODES] of float: demand_trans = [48.85054, 85.21089, 76.98102, 42.13288, 78.54950];

array[SOURCES, TANKS] of float: costs_sources_tanks = array2d(SOURCES, TANKS,
  [7.43982,2.10318]);

array[TANKS, TRANS_NODES] of float: costs_tanks_trans = array2d(TANKS, TRANS_NODES,
  [5.73985,8.64231,6.51431,6.82938,6.21791,
   4.18275,5.19280,8.71566,3.66273,4.47120]);

array[TRANS_NODES, FINAL_NODES] of float: costs_trans_final = array2d(TRANS_NODES, FINAL_NODES,
  [8.06988,9.21947,
   5.79583,7.56732,
   6.88651,2.28108,
   6.65591,2.10237,
   5.79270,6.80073]);


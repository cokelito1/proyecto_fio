set of int: SOURCES     = 1..1;
set of int: TANKS       = 1..2;
set of int: TRANS_NODES = 1..4;
set of int: FINAL_NODES = 1..2;
set of int: PIPE_TYPE   = 1..3;

array [PIPE_TYPE] of int: price_of_pipe = [20, 24, 32];
array [PIPE_TYPE] of int: capacity      = [795, 1414, 3181];

array[FINAL_NODES] of float: demand_final = [83.30329, 90.05415];
array[TRANS_NODES] of float: demand_trans = [70.69479, 52.96744, 87.23077, 84.42241];

array[SOURCES, TANKS] of float: costs_sources_tanks = array2d(SOURCES, TANKS,
  [9.41493,5.93052]);

array[TANKS, TRANS_NODES] of float: costs_tanks_trans = array2d(TANKS, TRANS_NODES,
  [8.78037,5.52410,7.69982,5.75635,
   8.55365,1.97188,1.72935,7.58406]);

array[TRANS_NODES, FINAL_NODES] of float: costs_trans_final = array2d(TRANS_NODES, FINAL_NODES,
  [5.18828,3.54249,
   5.04870,6.77658,
   9.74860,4.33487,
   6.20777,3.90223]);


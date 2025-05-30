% Use this editor as a MiniZinc scratch book
include "ide/vis.mzn";
include "./big.mzn";

array[SOURCES, TANKS, PIPE_TYPE] of var bool: install_source_tank_type;
array[TANKS, TRANS_NODES, PIPE_TYPE] of var bool: install_tank_trans_type;
array[TRANS_NODES, FINAL_NODES, PIPE_TYPE] of var bool: install_trans_final_type;

array[SOURCES, TANKS] of var float: quantity_from_source_tank;
array[TANKS, TRANS_NODES] of var float: quantity_from_tank_trans;
array[TRANS_NODES, FINAL_NODES] of var float: quantity_from_trans_final;

constraint forall(j in TANKS)(sum(i in SOURCES)(quantity_from_source_tank[i, j]) - sum(i in TRANS_NODES)(quantity_from_tank_trans[j, i]) = 0);                   /* No se almacena agua en los tankes, ¿Por que se llaman tankes? */
constraint forall(j in TRANS_NODES)(sum(i in TANKS)(quantity_from_tank_trans[i, j]) - sum(i in FINAL_NODES)(quantity_from_trans_final[j, i]) = demand_trans[j]); /* delta en flujo es la demanda */
constraint forall(j in FINAL_NODES)(sum(i in TRANS_NODES)(quantity_from_trans_final[i, j]) = demand_final[j]);                                                   /* No se puede almacenar agua en los clientes */

constraint forall(i in SOURCES, j in TANKS)(sum(k in PIPE_TYPE)(install_source_tank_type[i, j, k]) <= 1);           /* Solo podemos instalar una cañeria */
constraint forall(i in TANKS, j in TRANS_NODES)(sum(k in PIPE_TYPE)(install_tank_trans_type[i, j, k]) <= 1);        /* Solo podemos instalar una cañeria */
constraint forall(i in TRANS_NODES, j in FINAL_NODES)(sum(k in PIPE_TYPE)(install_trans_final_type[i, j, k]) <= 1); /* Solo podemos instalar una cañeria */

constraint forall(i in SOURCES, j in TANKS)(quantity_from_source_tank[i, j] <= sum(k in PIPE_TYPE)(install_source_tank_type[i, j, k]*capacity[k]));         /* Podemos enviar a lo más lo que aguante la pipe */
constraint forall(i in TANKS, j in TRANS_NODES)(quantity_from_tank_trans[i, j] <= sum(k in PIPE_TYPE)(install_tank_trans_type[i, j, k]*capacity[k]));       /* Podemos enviar a lo más lo que aguante la pipe */
constraint forall(i in TRANS_NODES, j in FINAL_NODES)(quantity_from_trans_final[i, j] <= sum(k in PIPE_TYPE)(install_trans_final_type[i,j,k]*capacity[k])); /* Podemos enviar a lo más lo que aguante la pipe */

constraint forall(i in SOURCES, j in TANKS)(quantity_from_source_tank[i, j] >= 0);
constraint forall(i in TANKS, j in TRANS_NODES)(quantity_from_tank_trans[i, j] >= 0);
constraint forall(i in TRANS_NODES, j in FINAL_NODES)(quantity_from_trans_final[i,j] >= 0);

constraint forall(i in SOURCES)(sum(j in TANKS)(quantity_from_source_tank[i, j]) <= supply[i]); /* Respetar la oferta */

solve minimize sum(i in SOURCES, j in TANKS, k in PIPE_TYPE)(price_of_pipe[k] * install_source_tank_type[i, j, k])            /* Costo de instlara una pipe del tipo k entre i y j */
             + sum(i in TANKS, j in TRANS_NODES, k in PIPE_TYPE)(price_of_pipe[k] * install_tank_trans_type[i, j, k])         /* Costo de instalar una pipe del tipo k entre i y j */
             + sum(i in TRANS_NODES, j in FINAL_NODES, k in PIPE_TYPE)(price_of_pipe[k] * install_trans_final_type[i, j, k])  /* Costo de instalar una pipe del tipo k entre i y j */
             + sum(i in SOURCES, j in TANKS)(costs_sources_tanks[i, j] * quantity_from_source_tank[i, j])                    /* [costo/L] * [L] */
             + sum(i in TANKS, j in TRANS_NODES)(costs_tanks_trans[i, j] * quantity_from_tank_trans[i, j])
             + sum(i in TRANS_NODES, j in FINAL_NODES)(costs_trans_final[i, j] * quantity_from_trans_final[i, j]);
       
output ["meta: S = " ++ show(length(SOURCES)) ++ " T = " ++ show(length(TANKS)) ++ " TN = " ++ show(length(TRANS_NODES)) ++ " FN = " ++ show(length(FINAL_NODES)) ++ "\n"];
output [
  if fix(install_source_tank_type[i, j, k]) = 1 then
    "Se instala cañeria del tipo " ++ show(k) ++ " entre fuente " ++ show(i) ++ " y tanque " ++ show(j) ++
    " con flujo " ++ show(quantity_from_source_tank[i, j]) ++ "\n"
  else
    ""
  endif
  |
  i in SOURCES, j in TANKS, k in PIPE_TYPE
] ++ [
  if fix(install_tank_trans_type[i, j, k]) = 1 then
    "Se instala cañeria del tipo " ++ show(k) ++ " entre tanque " ++ show(i) ++ " y nodo transitorio " ++ show(j) ++ 
    " con flujo " ++ show(quantity_from_tank_trans[i, j]) ++ "\n"
  else
    ""
  endif
  |
  i in TANKS, j in TRANS_NODES, k in PIPE_TYPE
] ++ [
  if fix(install_trans_final_type[i, j, k]) = 1 then
    "Se instala cañeria del tipo " ++ show(k) ++ " entre nodo transitorio " ++ show(i) ++ " y nodo final " ++ show(j) ++ 
    " con flujo " ++ show(quantity_from_trans_final[i, j]) ++ "\n"
  else
    ""
  endif
  |
  i in TRANS_NODES, j in FINAL_NODES, k in PIPE_TYPE
];

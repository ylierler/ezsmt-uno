% Model for mapping H263 encoder on a system with a network on chip (NoC)
%
% The model is a simplified version of the model presented in the paper
%
% "Mapping streaming applications on multiprocessors with time-division-multiplexed network-on-chip ",
% by
% Usman Mazhar Mirza, Flavius Gruian and Krzysztof Kuchcinski,
% Computers & Electrical Engineering, vol. 40, no. 8, pp. 276-291, 2014
%
% Author: Krzysztof Kuchcinski

include "globals.mzn";

int: row;          % number of rows in the mesh
int: col;          % number of columns in the mesh
int: k = row*col;  %  number processors
int: n = k + 2;    % number of nodes
int: no_links;     % number of links between processors
int: m = no_links + 2*k;  % number of arcs
int: no_flows;     % number of flows
int: link_bandwidth;

int: no_actors;

array[1..m, 1..2] of int: arc;

array[1..m] of int: unit_cost;

array[1..no_flows, 1..n] of int: balance;

int: processor_load;
array[1..k] of var 0..processor_load: cpu_loads;

array[1..no_actors] of int: actor_load;
array[1..2, 1..no_flows] of int: load;

array[1..no_flows] of var 0..10000: cost;

% var 0..10000: load_cost;
% var 0..10000: cpu_cost;
var 0..10000: communication_cost;
var 0..10000: objective;

array[1..2*no_flows] of var 1..k: flow_processor;

array[1..no_links] of var 0..link_bandwidth : comm_full;
array[1..k] of var 0..5*link_bandwidth : flow_from_processor;

array[1..k] of var 0..10000*no_flows: cc;

array[1..no_flows] of int: inStream;
array[1..no_flows, 1..n] of int: b;

array[1..no_flows, 1..k] of var 0..max(inStream): inFlow;
array[1..no_flows, 1..k] of var 0..max(inStream): outFlow;
array[1..no_flows, 1..no_links] of var 0..link_bandwidth: commFlow;

array[1..no_flows, 1..m] of var 0..max(max(inStream),link_bandwidth): flows;

array[1..no_flows,1..2] of int: source_destination_actor;

array[1..no_actors] of var 1..k: actor_processor;

array[1..2*k*no_flows + no_links] of var 0..max(max(inStream),link_bandwidth): total_flow;
array[1..2*k*no_flows + no_links] of int: total_unit_cost;
array[1..k+2*no_flows] of int: total_balance;

array[1..2*no_flows*k] of int: in_connections;
array[1..2*no_flows*k] of int: out_connections;
array[1..2*no_flows*k+no_links, 1..2] of int: all_connections;

%% === Model constraints ===

constraint %% constraining input and output flows defining mapping
   forall( i in 1..no_flows, j in 1..k) (inFlow[i,j] in {0, inStream[i]} /\ outFlow[i,j] in {0, inStream[i]})
;

constraint %% to select processor and not divide flow on incomming and outgoing streams
	forall (i in 1..no_flows) (count([flows[i,j] | j in 1..k], 0, k-1) /\ count([flows[i,j] | j in m-k+1..m], 0, k-1))
;

constraint %% network flow constraint
	forall (i in 1..no_flows) (network_flow_cost(arc,  [balance[i,j] | j in 1..n], unit_cost, [flows[i,j] | j in 1..m], cost[i]))
;

constraint  %% networkflow for all flows
	network_flow_cost(all_connections, total_balance, total_unit_cost, total_flow, communication_cost)
	/\
	%% flow for communications between processors for the combined network flow; must be the same as sum of separate flows
	forall (i in 1..no_links) (comm_full[i] = sum(j in 1..no_flows)(flows[j,i+k]))
;

constraint %% computes processors' load
	forall (i in 1..no_flows, j in 1..k) ( ( flows[i,j] != 0 <-> flow_processor[i] = j)
	       	     		               /\
				               ( flows[i, m-k+j] != 0 <-> flow_processor[no_flows+i] = j) )
	/\ 
	bin_packing_load(cpu_loads, flow_processor, [load[i, j] | i in 1..2, j in 1..no_flows])
;

constraint  %% cost function to minimize
	forall (i in 1..k) (cc[i] = sum(j in 1..no_flows)((flow_processor[source_destination_actor[j,1]] = i) * cost[j]))
	/\
	maximum(objective, [cpu_loads[i] + cc[i] | i in 1..k])
	% maximum(load_cost, [cpu_loads[i] + cc[i] | i in 1..k])
	% /\
	% objective = load_cost
;

constraint  %% flow out from each processor
	    forall (i in 1..k) (flow_from_processor[i] = sum(j in 1..no_flows, n in k+1..no_links+k where arc[n,1] = i) (flows[j,n]))
;

% constraints on flow_processors; to be the same if they are the same as source or sink
constraint
	forall ( i in 1..no_flows) ( 
	       forall (j in i+1..no_flows where source_destination_actor[i,1] = source_destination_actor[j,1]) (flow_processor[i] = flow_processor[j]))
	/\
	forall ( i in 1..no_flows) ( 
	       forall (j in 1..no_flows where source_destination_actor[i,1] = source_destination_actor[j,2]) (flow_processor[i] = flow_processor[no_flows+j]))
	/\
	forall ( i in 1..no_flows) ( 
	       forall (j in i+1..no_flows where source_destination_actor[i,2] = source_destination_actor[j,2]) (flow_processor[no_flows+i] = flow_processor[no_flows+j]))
;

solve :: seq_search([
            int_search(flow_processor, first_fail, indomain_min, complete),
      	    int_search(total_flow, smallest, indomain_min, complete),
      	    int_search(cost ++ [communication_cost], input_order, indomain_min, complete)
          , int_search( cpu_loads, first_fail, indomain_min, complete)
          , int_search( [inFlow[i,j] | i in 1..no_flows, j in 1..k], first_fail, indomain_min, complete)
          , int_search( [outFlow[i,j] | i in 1..no_flows, j in 1..k], first_fail, indomain_min, complete)
          , int_search( [commFlow[i,j] | i in 1..no_flows, j in 1..no_links], first_fail, indomain_min, complete)
          , int_search( [flows[i,j] | i in 1..no_flows, j in 1..m], first_fail, indomain_min, complete)
          , int_search( actor_processor, first_fail, indomain_min, complete)

      ]) 
      minimize objective;

array[1..no_links] of string: link_str;

% output
% ["Objective = " ++ show(objective) ++ ", Communication_cost = " ++  show(communication_cost) ++ "\n" ++ "Processor loads = " ++ show(cpu_loads) ++"\n"] ++

% ["cpu for actor "++ show(i)++" = " ++ show(actor_processor[i]) ++", " | i in 1..no_actors] ++ ["\n"] ++

% [if i = 1 then "Flow " ++ show(j) ++ " with cost " ++ show(cost[j]) ++ " from processor "++ show(actor_processor[source_destination_actor[j,1]]) ++ " to " ++ show(actor_processor[source_destination_actor[j,2]]) ++ " :\n" ++ 
% if fix(cost[j]) != 0 then 
% if fix(flows[j,i+k]) != 0 then link_str[i] ++ show(flows[j,i+k]) ++ "\n" else "" endif else "" endif
% else
% if fix(flows[j,i+k]) != 0 then link_str[i] ++ show(flows[j,i+k]) ++ "\n" else "" endif endif | j in 1..no_flows, i in 1..no_links] 
% ;
%
output [ 
    "objective = \(objective);\n",
    "communication_cost = \(communication_cost);\n",
    "flow_processor = \(flow_processor);\n",
    "total_flow = \(total_flow);\n",
    "cpu_loads = \(cpu_loads);\n",
    "inFlow = array2d(1..\(no_flows), 1..\(k), \(inFlow));\n",
    "outFlow = array2d(1..\(no_flows), 1..\(k), \(outFlow));\n",
    "commFlow = array2d(1..\(no_flows), 1..\(k), \(commFlow));\n",
    "flows = array2d(1..\(no_flows), 1..\(k), \(flows));\n",
    "actor_processor = \(actor_processor);\n"
];

%% ========= DATA =============
% MPEG decoder inspired
%
% Actors
% ======
%  1. source	16
%  2. display	68
%  3. decoder_parser_parseheaders	116
%  4. decoder_parser_blkexp	33
%  5. decoder_parser_mvrecon	15
%  6. decoder_texture_idct2d	106
%  7. decoder_texture_is	27
%  8. decoder_texture_iDcPred	45
%  9. decoder_texture_iAcPred	29
% 10. decoder_texture_iq	93
% 11. decoder_motion_interpolation	67
% 12. decoder_motion_add	74
% 13. decoder_motion_framebuf	99


% Communications
% ==============
%
%  1. decparpar2decparmvr (3 -> 5)	17
%  2. dectexiDc2dectexis (8 -> 7)	570
%  3. dectexiAc2dectexiq (9 -> 10)	570
%  4. decparmvr2decmotfra (5 -> 13)	16
%  5. dectexidc2decmotadd (6 -> 12)	395
%  6. dectexiDc2dectexidc (8 -> 6)	1
%  7. decmotfra2decmotint (13 -> 11)	4
%  8. decparpar2decparmvr2 (3 -> 5)	11
%  9. dectexis2dectexiAc (7 -> 5)	570
% 10. sou2decparpar (1 -> 3)		24
% 11. decmotfra2decmotint2 (13 -> 11)	677
% 12. dectexiDc2dectexis2 (8 -> 7)	2
% 13. dectexiDc2dectexiq (8 -> 10)	5
% 14. decparpar2decparblk (3 -> 4)	29
% 15. decparblk2dectexiDc (4 -> 8)	570
% 16. decparpar2decmotadd (3 -> 12)	17
% 17. decparpar2dis (3 -> 2) 		1
% 18. dectexiDc2dectexiAc (8 -> 9)	66
% 19. dectexiDc2dectexiAc2 (8 -> 9)	2
% 20. decparpar2decparblk2 (3 -> 4)	47
% 21. decmotint2decmotadd (11 -> 12)	476
% 22. decparpar2dectexiDc (3 -> 8)	17
% 23. dectexiq2dectexidc (10 -> 6)	570
% 24. decmotadd2dis (12 -> 2)	713
% 25. decparpar2decmotfra (3 -> 13)	17
% 26. dectexiDc2dectexiAc3 (8 -> 9)	1
% 27. decmotadd2decmotfra (12 -> 13)	713
% 28. decparpar2decparblk3 (3 -> 4)	4
% 29. decparpar2dectexiDc2 (3 -> 8)	9

% Architecture:
%
% ___   ___ 
% |1 |--|2 |
% ---   --- 
%  |     |  
% ___   ___ 
% |3 |--|4 |
% ---   --- 

row = 2;
col = 2;

no_links = 2*2*(row-1)*col;

no_actors = 13;
no_flows = 29;

link_bandwidth = 500;

source_destination_actor = 
			[| 3, 5 |
			   8, 7 |
			   9, 10 |
			   5, 13 |
			   6, 12 |
			   8, 6 |
			   13, 11 |
			   3, 5 |
			   7, 5 |
			   1, 3 |
			   13, 11 |
			   8, 7 |
			   8, 10 |
			   3, 4 |
			   4, 8 |
			   3, 12 |
			   3, 2 |
			   8, 9 |
			   8, 9 |
			   3, 4 |
			   11, 12 |
			   3, 8 |
			   10, 6 |
			   12, 2 |
			   3, 13 |
			   8, 9 |
			   12, 13 |
			   3, 4 |
			   3, 8 
			|];


actor_processor = [flow_processor[10], %1
		   flow_processor[53], % 2
		   flow_processor[1],  % 3
		   flow_processor[15], % 4
		   flow_processor[4],  % 5
		   flow_processor[5],  % 6
		   flow_processor[31], % 7
		   flow_processor[2],  % 8
		   flow_processor[3],  % 9
		   flow_processor[32], % 10
		   flow_processor[36], % 11
		   flow_processor[34], % 12
		   flow_processor[33], % 13
		   ];

inStream = [17, 570, 570, 16, 395, 1, 4, 11, 570, 24, 677, 2, 5, 29, 570, 17, 1, 66, 2, 47, 476, 17, 570, 713, 17, 1, 713, 4, 9];

b = [| 0, 0, 0, 0, inStream[1], -inStream[1] |
       0, 0, 0, 0, inStream[2], -inStream[2] |
       0, 0, 0, 0, inStream[3], -inStream[3] |
       0, 0, 0, 0, inStream[4], -inStream[4] |
       0, 0, 0, 0, inStream[5], -inStream[5] |
       0, 0, 0, 0, inStream[6], -inStream[6] |
       0, 0, 0, 0, inStream[7], -inStream[7] |
       0, 0, 0, 0, inStream[8], -inStream[8] |
       0, 0, 0, 0, inStream[9], -inStream[9] |
       0, 0, 0, 0, inStream[10], -inStream[10] |
       0, 0, 0, 0, inStream[11], -inStream[11] |
       0, 0, 0, 0, inStream[12], -inStream[12] |
       0, 0, 0, 0, inStream[13], -inStream[13] |
       0, 0, 0, 0, inStream[14], -inStream[14] |
       0, 0, 0, 0, inStream[15], -inStream[15] |
       0, 0, 0, 0, inStream[16], -inStream[16] |
       0, 0, 0, 0, inStream[17], -inStream[17] |
       0, 0, 0, 0, inStream[18], -inStream[18] |
       0, 0, 0, 0, inStream[19], -inStream[19] |
       0, 0, 0, 0, inStream[20], -inStream[20] |
       0, 0, 0, 0, inStream[21], -inStream[21] |
       0, 0, 0, 0, inStream[22], -inStream[22] |
       0, 0, 0, 0, inStream[23], -inStream[23] |
       0, 0, 0, 0, inStream[24], -inStream[24] |
       0, 0, 0, 0, inStream[25], -inStream[25] |
       0, 0, 0, 0, inStream[26], -inStream[26] |
       0, 0, 0, 0, inStream[27], -inStream[27] |
       0, 0, 0, 0, inStream[28], -inStream[28] |
       0, 0, 0, 0, inStream[29], -inStream[29] 
       |];


flows = array2d(1..no_flows, 1..m, 
        [inFlow[1,i] | i in 1..k] ++ [commFlow[1,i] | i in 1..no_links] ++ [outFlow[1,i] | i in 1..k] ++
        [inFlow[2,i] | i in 1..k] ++ [commFlow[2,i] | i in 1..no_links] ++ [outFlow[2,i] | i in 1..k] ++
	[inFlow[3,i] | i in 1..k] ++ [commFlow[3,i] | i in 1..no_links] ++ [outFlow[3,i] | i in 1..k] ++
	[inFlow[4,i] | i in 1..k] ++ [commFlow[4,i] | i in 1..no_links] ++ [outFlow[4,i] | i in 1..k] ++
	[inFlow[5,i] | i in 1..k] ++ [commFlow[5,i] | i in 1..no_links] ++ [outFlow[5,i] | i in 1..k] ++
	[inFlow[6,i] | i in 1..k] ++ [commFlow[6,i] | i in 1..no_links] ++ [outFlow[6,i] | i in 1..k] ++
	[inFlow[7,i] | i in 1..k] ++ [commFlow[7,i] | i in 1..no_links] ++ [outFlow[7,i] | i in 1..k] ++
	[inFlow[8,i] | i in 1..k] ++ [commFlow[8,i] | i in 1..no_links] ++ [outFlow[8,i] | i in 1..k] ++
	[inFlow[9,i] | i in 1..k] ++ [commFlow[9,i] | i in 1..no_links] ++ [outFlow[9,i] | i in 1..k] ++
	[inFlow[10,i] | i in 1..k] ++ [commFlow[10,i] | i in 1..no_links] ++ [outFlow[10,i] | i in 1..k] ++
	[inFlow[11,i] | i in 1..k] ++ [commFlow[11,i] | i in 1..no_links] ++ [outFlow[11,i] | i in 1..k] ++
	[inFlow[12,i] | i in 1..k] ++ [commFlow[12,i] | i in 1..no_links] ++ [outFlow[12,i] | i in 1..k] ++
	[inFlow[13,i] | i in 1..k] ++ [commFlow[13,i] | i in 1..no_links] ++ [outFlow[13,i] | i in 1..k] ++
	[inFlow[14,i] | i in 1..k] ++ [commFlow[14,i] | i in 1..no_links] ++ [outFlow[14,i] | i in 1..k] ++
	[inFlow[15,i] | i in 1..k] ++ [commFlow[15,i] | i in 1..no_links] ++ [outFlow[15,i] | i in 1..k] ++
	[inFlow[16,i] | i in 1..k] ++ [commFlow[16,i] | i in 1..no_links] ++ [outFlow[16,i] | i in 1..k] ++
	[inFlow[17,i] | i in 1..k] ++ [commFlow[17,i] | i in 1..no_links] ++ [outFlow[17,i] | i in 1..k] ++
	[inFlow[18,i] | i in 1..k] ++ [commFlow[18,i] | i in 1..no_links] ++ [outFlow[18,i] | i in 1..k] ++
	[inFlow[19,i] | i in 1..k] ++ [commFlow[19,i] | i in 1..no_links] ++ [outFlow[19,i] | i in 1..k] ++
	[inFlow[20,i] | i in 1..k] ++ [commFlow[20,i] | i in 1..no_links] ++ [outFlow[20,i] | i in 1..k] ++
	[inFlow[21,i] | i in 1..k] ++ [commFlow[21,i] | i in 1..no_links] ++ [outFlow[21,i] | i in 1..k] ++
	[inFlow[22,i] | i in 1..k] ++ [commFlow[22,i] | i in 1..no_links] ++ [outFlow[22,i] | i in 1..k] ++
	[inFlow[23,i] | i in 1..k] ++ [commFlow[23,i] | i in 1..no_links] ++ [outFlow[23,i] | i in 1..k] ++
	[inFlow[24,i] | i in 1..k] ++ [commFlow[24,i] | i in 1..no_links] ++ [outFlow[24,i] | i in 1..k] ++
	[inFlow[25,i] | i in 1..k] ++ [commFlow[25,i] | i in 1..no_links] ++ [outFlow[25,i] | i in 1..k] ++
	[inFlow[26,i] | i in 1..k] ++ [commFlow[26,i] | i in 1..no_links] ++ [outFlow[26,i] | i in 1..k] ++
	[inFlow[27,i] | i in 1..k] ++ [commFlow[27,i] | i in 1..no_links] ++ [outFlow[27,i] | i in 1..k] ++
	[inFlow[28,i] | i in 1..k] ++ [commFlow[28,i] | i in 1..no_links] ++ [outFlow[28,i] | i in 1..k] ++
	[inFlow[29,i] | i in 1..k] ++ [commFlow[29,i] | i in 1..no_links] ++ [outFlow[29,i] | i in 1..k] 
	);

balance = array2d(1..no_flows, 1..n, [b[i,j] | i in 1..no_flows, j in 1..n]);


processor_load = 1000;

% load for actors
actor_load = [16, 68, 116, 33, 15, 106, 27, 45, 29, 93, 67, 74, 99];

load = array2d(1..2, 1..no_flows, 
	[if (not exists (k in 1..i-1) (source_destination_actor[k,j+1] = source_destination_actor[i,j+1] \/ 
	    	 	      	       source_destination_actor[k,((j+1) mod 2) + 1] = source_destination_actor[i,j+1])) 
	    then actor_load[source_destination_actor[i,j+1]] else 0 endif | j in 0..1, i in 1..no_flows]);

unit_cost = [ 0, 0, 0, 0, 
	    1, 1, 1, 1, 1, 1, 1, 1,
	    0, 0, 0, 0];
arc =[| 
    	%% from action to processors
    	5, 1 |
    	5, 2 |
	5, 3 |
	5, 4 |

	1, 2 |
	1, 3 |

	2, 1 |
	2, 4 |

	3, 1 |
	3, 4 |

	4, 2 |
	4, 3 |
	
	%% from processors to action
	1, 6 |
    	2, 6 |
	3, 6 |
	4, 6 
	|];

in_connections = [if ((i mod 2) mod 2) = 0 then (k+1)+(i div (2*k)) else ((i div 2) mod k + 1) endif | i in 0..2*no_flows*k-1];
out_connections = [if ((i mod 2) mod 2) = 0 then ((i div 2) mod k + 1) else (k+no_flows+1)+(i div (2*k)) endif | i in 0..2*no_flows*k-1];

all_connections = array2d(1..2*no_flows*k+no_links, 1..2, in_connections ++ [arc[i,j] | i in k+1..no_links+k, j in 1..2] ++ out_connections);

total_flow = [flows[i,j] | i in 1..no_flows, j in 1..k] ++ 
	     comm_full ++ 
             [flows[i,j] | i in 1..no_flows, j in k+no_links+1..2*k+no_links];

total_unit_cost = [0 | i in 1..no_flows, j in 1..k] ++ [ 1 | i in 1..no_links] ++ [0 | i in 1..no_flows, j in 1..k];

total_balance = [0 | i in 1..k] ++ [balance[i,j] | i in 1..no_flows, j in k+1..k+1] ++ [balance[i,j] | i in 1..no_flows, j in k+2..k+2];

link_str = ["1 -> 2 = ", "1 -> 3 = ", "2 -> 1 = ", "2 -> 4 = ", "3 -> 1 = ", "3 -> 4 = ", "4 -> 2 = ", "4 -> 3 = "];

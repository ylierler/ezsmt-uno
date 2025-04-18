% pizza voucher problem
%
% pizzas to order
%    13 25 17 12 9
% vouchers
%    1+1  2+1
% you pay for the most expensive pizzas when using a voucher.

int: n; % number of pizzas
set of int: PIZZA = 1..n;
array[PIZZA] of int: price;   % price of each pizza

int: m; % number of vouchers
set of int: VOUCHER = 1..m;
array[VOUCHER] of int: buy;   % buy this many to use voucher
array[VOUCHER] of int: free;  % get this many free

set of int: ASSIGN = -m .. m; % -i pizza is assigned to buy of voucher i
                              %  i pizza is assigned to free of voucher i
                              %  0 no voucher used on pizza

array[PIZZA] of var ASSIGN: how;
array[VOUCHER] of var bool: used;

% assign right number of pizzas to buy order
constraint forall(v in VOUCHER)(used[v] <-> sum(p in PIZZA)(how[p] = -v) >= buy[v]);
constraint forall(v in VOUCHER)(sum(p in PIZZA)(how[p] = -v) <= used[v]*buy[v]);
% assign not too many pizzas to free order
constraint forall(v in VOUCHER)(sum(p in PIZZA)(how[p] = v) <= used[v]*free[v]);

% pizzas assigned to free are cheaper than pizzas assigned to buy
constraint forall(p1, p2 in PIZZA)((how[p1] < how[p2] /\ how[p1] = -how[p2]) 
                                   -> price[p2] <= price[p1]);


% symmetry breaking
%constraint forall(v1, v2 in VOUCHER where v1 < v2 /\ buy[v1] = buy[v2] /\ free[v1] = free[v2])
%                 (forall(p1, p2 in PIZZA where price[p1] < price[p2])
%                        (how[p1] = -v2 -> how[p2] != -v1));

                  




int: total = sum(price);
var 0..total: objective = sum(p in PIZZA)((how[p] <= 0)*price[p]);

solve :: int_search(how, input_order, indomain_min, complete)
      minimize objective;

output  
  ["how = "++show(how)++";\nobjective = "++show(objective)++";\n"];




n = 180;
price = [243,7031,4313,8033,6321,1688,2132,4142,9593,5882,2167,8072,4972,4594,1139,6071,7764,500,9029,7980,3112,5020,7167,5794,906,344,6141,6945,6551,5242,6606,2254,6175,130,3643,6060,9163,9931,9753,751,6056,8498,7390,8019,1028,9309,7245,9627,9360,1905,9603,4300,5167,1849,6417,8766,9122,7462,3742,1232,6904,6779,4104,3993,2134,5785,2599,8836,5049,4875,3500,4426,6961,8275,1665,9216,37,2858,6751,7111,4462,7513,9184,5679,7800,5170,5043,4554,5662,4510,6755,368,1748,1850,6325,2055,2779,1576,1048,3113,5628,6491,8839,6543,1546,2907,2897,80,5456,9925,3048,6512,4788,9398,1105,4958,2302,8710,2418,6032,3294,7269,9161,6684,5378,7426,8385,5609,3196,4973,3021,9954,3110,4213,7379,1042,6007,2189,473,1679,2167,1954,6845,2108,315,4635,6691,5809,222,4818,8223,3151,6662,2351,3255,796,4543,9876,4253,7279,8091,9252,9669,9575,4675,5394,2485,4443,8409,3202,7893,9879,3673,6190,189,7708,5414,1897,6504,160];
m = 4;
buy = [3,2,3,2];
free = [5,7,5,7];

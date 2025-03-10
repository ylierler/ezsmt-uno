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




n = 200;
price = [3596,5509,5509,4492,151,2782,1656,8811,5552,5692,5152,69,4880,5291,8801,711,4688,1356,4335,8043,8054,8206,4612,3460,2859,2247,583,2386,2600,5017,5937,5055,5378,759,7758,1081,2522,3626,6878,2065,3317,2837,8126,5703,7986,4695,4563,143,750,826,4465,3194,9230,2836,2716,1775,2779,819,5445,5613,5677,7306,596,9921,885,5947,16,80,821,983,8303,8271,7467,8035,4453,5021,8375,3602,6507,9393,5667,4107,7526,2273,9917,7707,2972,5356,1512,1803,7889,9757,7591,7547,8340,152,259,6508,4004,6499,5357,2339,5863,532,8625,8202,5556,2354,240,6932,7479,5326,2567,5146,6297,2717,9142,3197,8456,9274,3019,5215,5015,7556,488,410,836,521,1019,3815,1241,7649,4186,6141,94,1413,1454,8325,3866,4457,1557,5057,8729,2659,2734,2609,4011,9814,5353,8231,4279,9801,1070,1880,5278,9018,626,6872,583,371,3100,7072,5795,9246,9426,610,6929,7759,7631,1608,3688,573,5852,6884,7161,429,8571,8924,4331,1775,4118,5378,9245,1922,6352,4836,2028,5065,8091,112,6375,2824,9749,2357,7497,9525,7915,1416,3595,1920];
m = 7;
buy = [5,5,5,5,5,5,5];
free = [7,7,7,7,7,7,7];

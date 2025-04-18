%------------------------------------------------------------------------------%
% gfd-schedule.mzn
%
% Scheduling problem:
%
%   Constraints:
%    * Items are grouped by its 'kind'.
%    * Items are processed by group using 'facility'.
%    * Items must be processed after 'producedDay'.
%    * Maximum number of processed-items/day is fixed.
%
%   Objective:
%     Items may be processed before 'deadLineDay'.
%     Minimize group. (minimize use of facility)
%
%------------------------------------------------------------------------------%
% Includes

include "nvalue.mzn";
include "at_most.mzn";

%------------------------------------------------------------------------------%
% Parameters

% how many items
int: N;

% how many facilities
int: F;

% max items per day
int: MaxItemsPerDay;

% max day of schedule
int: MaxDay;

% item names
array[1..N] of string: name;

% kind of items
array[1..N] of int: kind;

% which facility can be used to process item
array[1..N] of set of 1..F: facility;

% item must be tested after prodecedDay
array[1..N] of int: producedDay;

% item must be tested until deadLineDay
array[1..N] of int: deadLineDay;

%------------------------------------------------------------------------------%
% Variables

% item -> group mapping
array[1..N] of var 1..N: assignedGroup;

% group -> facility mapping (0 if group number not used)
array[1..N] of var 0..F: groupFacility;

array[1..N] of var 0..MaxDay: groupProcessDay;

array[1..N] of var 1..MaxDay: itemProcessDay;

var 1..N: nGroups;

int: dlp_max = sum(i in 1..N)(MaxDay - deadLineDay[i]);
var 0..dlp_max: deadLinePenalty;

int: obj_min = lb(deadLinePenalty) * 100 + lb(nGroups);
int: obj_max = ub(deadLinePenalty) * 100 + ub(nGroups);
var obj_min..obj_max: objective;

%------------------------------------------------------------------------------%
% Constraints

constraint
	forall(i in 1..N) (
		itemProcessDay[i] = groupProcessDay[assignedGroup[i]]
	);

% one group contains only one kind of item
constraint
	forall(i, j in 1..N where i < j) (
		kind[i] != kind[j] -> assignedGroup[i] != assignedGroup[j]
	);

constraint
	forall(k in lb_array(kind)..ub_array(kind)) (
		let {
			int: base = card({ i | i in 1..N where kind[i] < k});
			int: size = card({ i | i in 1..N where kind[i] = k});

			% index set of items having same kind (may be assigned to same group)
			array[1..size] of int: giset = [i |i in 1..N where kind[i] == k];
		} in
		% define group number selection range
		forall(i in index_set(giset)) (
			base < assignedGroup[giset[i]] /\ assignedGroup[giset[i]] <= base + size
		)
	);

% set 0 if not used
constraint
	forall(g in 1..N) (
		exists(i in 1..N)(assignedGroup[i] = g) != true
		<-> (groupFacility[g] == 0 /\ groupProcessDay[g] == 0)
	);

% set group order
constraint symmetry_breaking_constraint(
	forall(k in lb_array(kind)..ub_array(kind)) (
		let {
			int: base = card({ i | i in 1..N where kind[i] < k});
			int: size = card({ i | i in 1..N where kind[i] = k});

			% index set of items having same kind (may be assigned to same group)
			array[1..size] of int: giset = [i |i in 1..N where kind[i] == k];
		} in
		% define group number selection range
		forall(i in index_set(giset)) (
			assignedGroup[giset[i]] <= base + i
		)
		/\
		% use group number from smaller to bigger
		forall(g, h in base+1..base+size where g < h) (
			groupFacility[g] == 0 -> groupFacility[h] = 0
		)
	)
);

% facility is assinged to group according to item's facility
constraint
	forall(i in 1..N) (
		groupFacility[assignedGroup[i]] in facility[i]
	);

% facility must be used by group exclusively
constraint
	forall(i, j in 1..N where i < j) (
	    groupFacility[i] != 0 /\ groupFacility[j] != 0
	    /\ groupFacility[i] == groupFacility[j]
		 -> groupProcessDay[i] != groupProcessDay[j]
	);

% items must be assigned to facility after its producedDay
constraint
	forall(i in 1..N) (
		producedDay[i] < groupProcessDay[assignedGroup[i]]
	);

% items per day
constraint
	forall(d in 1..MaxDay) (
		at_most(MaxItemsPerDay, itemProcessDay, d)
	);

% penalty
function var int: itemDeadLinePenalty(int: i) = (
	if (itemProcessDay[i] <=  deadLineDay[i]) then
	   0
	else
	   itemProcessDay[i] - deadLineDay[i]
	endif
);

constraint
	deadLinePenalty = sum(i in 1..N) (itemDeadLinePenalty(i));

constraint nvalue(nGroups, assignedGroup);


%------------------------------------------------------------------------------%
% Search and solve item

solve 
    :: seq_search([
        int_search(
            assignedGroup ++ groupFacility ++ groupProcessDay,
            first_fail, indomain_min, complete
        ),
        int_search(
            itemProcessDay ++ [nGroups, deadLinePenalty, objective],
            first_fail, indomain_min, complete
        )
    ])
    minimize objective;

%------------------------------------------------------------------------------%
% Output item

output [ 
    "% item\t k, g, f, day\n" 
] ++ [ 
    "% \(name[i])\t \(kind[i]), \(assignedGroup[i]), \(groupFacility[assignedGroup[i]]), \(itemProcessDay[i]) (\(producedDay[i]) - \(deadLineDay[i]))\n"
| i in 1..N 
] ++ [ 
    "assignedGroup = \(assignedGroup);\n", 
	"groupFacility = \(groupFacility);\n",
	"groupProcessDay = \(groupProcessDay);\n",
	"itemProcessDay = \(itemProcessDay);\n",
	"deadLinePenalty = \(deadLinePenalty);\n",
    "nGroups = \(nGroups);\n",
	"objective = \(objective);\n"
];

%------------------------------------------------------------------------------%

N = 180;
F = 7;
MaxItemsPerDay = 30;
MaxDay = 50;
name = ["i1", "i2", "i3", "i4", "i5", "i6", "i7", "i8", "i9", "i10", "i11", "i12", "i13", "i14", "i15", "i16", "i17", "i18", "i19", "i20", "i21", "i22", "i23", "i24", "i25", "i26", "i27", "i28", "i29", "i30", "i31", "i32", "i33", "i34", "i35", "i36", "i37", "i38", "i39", "i40", "i41", "i42", "i43", "i44", "i45", "i46", "i47", "i48", "i49", "i50", "i51", "i52", "i53", "i54", "i55", "i56", "i57", "i58", "i59", "i60", "i61", "i62", "i63", "i64", "i65", "i66", "i67", "i68", "i69", "i70", "i71", "i72", "i73", "i74", "i75", "i76", "i77", "i78", "i79", "i80", "i81", "i82", "i83", "i84", "i85", "i86", "i87", "i88", "i89", "i90", "i91", "i92", "i93", "i94", "i95", "i96", "i97", "i98", "i99", "i100", "i101", "i102", "i103", "i104", "i105", "i106", "i107", "i108", "i109", "i110", "i111", "i112", "i113", "i114", "i115", "i116", "i117", "i118", "i119", "i120", "i121", "i122", "i123", "i124", "i125", "i126", "i127", "i128", "i129", "i130", "i131", "i132", "i133", "i134", "i135", "i136", "i137", "i138", "i139", "i140", "i141", "i142", "i143", "i144", "i145", "i146", "i147", "i148", "i149", "i150", "i151", "i152", "i153", "i154", "i155", "i156", "i157", "i158", "i159", "i160", "i161", "i162", "i163", "i164", "i165", "i166", "i167", "i168", "i169", "i170", "i171", "i172", "i173", "i174", "i175", "i176", "i177", "i178", "i179", "i180"];
kind = [6, 12, 18, 7, 3, 7, 7, 18, 5, 12, 4, 6, 6, 6, 9, 17, 13, 18, 4, 10, 9, 11, 6, 3, 2, 2, 10, 10, 9, 6, 7, 14, 9, 14, 2, 6, 8, 16, 6, 13, 16, 13, 2, 18, 7, 2, 6, 3, 16, 4, 9, 11, 14, 18, 14, 7, 2, 18, 1, 16, 14, 14, 7, 6, 2, 2, 4, 14, 13, 4, 7, 6, 14, 9, 18, 2, 17, 1, 15, 2, 1, 14, 6, 5, 7, 18, 1, 16, 16, 12, 14, 13, 2, 11, 6, 9, 7, 12, 4, 11, 4, 11, 7, 12, 15, 16, 15, 1, 6, 10, 18, 14, 10, 5, 3, 17, 2, 13, 2, 14, 3, 3, 12, 12, 6, 3, 18, 8, 11, 15, 12, 16, 5, 11, 16, 5, 8, 1, 4, 3, 11, 4, 12, 16, 12, 10, 2, 8, 2, 14, 3, 14, 8, 7, 17, 9, 5, 12, 8, 3, 6, 13, 3, 18, 8, 17, 12, 13, 10, 11, 9, 13, 5, 10, 4, 6, 2, 4, 5, 7];
facility = [
  { 3, 6, 7 },
  { 2, 3, 4, 7 },
  { 2, 3, 4, 6, 7 },
  { 4, 5, 6, 7 },
  { 1, 3, 4 },
  { 4, 6, 7 },
  { 2, 7 },
  { 5 },
  { 1, 2, 4, 5, 7 },
  { 2, 3, 6 },
  { 4, 7 },
  { 1, 3, 5, 6, 7 },
  { 2, 3, 4, 5, 6 },
  { 4, 5, 6 },
  { 1, 2, 3, 5, 6 },
  { 1, 2, 5, 6, 7 },
  { 5 },
  { 1, 3, 5, 6, 7 },
  { 2, 4, 6, 7 },
  { 5 },
  { 6 },
  { 1, 4, 6 },
  { 6 },
  { 2, 3 },
  { 1, 2, 5, 6, 7 },
  { 2, 3, 4, 7 },
  { 1, 2, 5, 6 },
  { 3, 6 },
  { 2, 3, 7 },
  { 1, 3, 4, 5, 6, 7 },
  { 2, 3, 4, 6, 7 },
  { 1, 7 },
  { 1 },
  { 3, 5, 6 },
  { 1, 2, 4, 5 },
  { 1, 5, 6 },
  { 1, 4, 5, 7 },
  { 5, 6, 7 },
  { 3, 6, 7 },
  { 1, 2, 6 },
  { 2, 3, 4, 5 },
  { 5, 7 },
  { 2, 3, 4, 6 },
  { 4, 6, 7 },
  { 1, 2, 3, 5, 6, 7 },
  { 1, 2, 3, 4, 5, 6 },
  { 1, 2, 3, 5, 6 },
  { 1, 3 },
  { 4 },
  { 1, 4, 6 },
  { 3 },
  { 4 },
  { 4 },
  { 1 },
  { 1, 3, 7 },
  { 1, 2, 5, 6, 7 },
  { 1, 2, 3, 5, 7 },
  { 1, 2, 3 },
  { 1 },
  { 3, 4, 6 },
  { 1 },
  { 2, 4, 6, 7 },
  { 2, 3, 5, 6, 7 },
  { 2, 5, 6 },
  { 2, 4, 5, 6, 7 },
  { 2, 3, 4, 6, 7 },
  { 2, 4, 5, 6, 7 },
  { 1, 3 },
  { 5 },
  { 2, 4, 7 },
  { 2, 3, 7 },
  { 1, 3, 4, 5, 6, 7 },
  { 4, 5 },
  { 1, 3, 5, 6, 7 },
  { 4 },
  { 2, 3, 4, 5, 6 },
  { 5 },
  { 1, 3, 4, 6 },
  { 3, 4 },
  { 1, 2, 7 },
  { 1, 5, 6 },
  { 3, 4, 5, 6, 7 },
  { 1, 3, 6, 7 },
  { 1, 5 },
  { 1, 2, 4, 5, 6, 7 },
  { 2, 5, 7 },
  { 1, 3, 7 },
  { 3, 5, 6 },
  { 1, 2, 3, 6, 7 },
  { 2, 6 },
  { 1, 2, 4, 5, 6, 7 },
  { 2, 3, 4, 5, 7 },
  { 2, 3, 4, 7 },
  { 6, 7 },
  { 1, 6 },
  { 2, 5, 6 },
  { 5, 7 },
  { 3, 4, 6, 7 },
  { 1, 2, 4, 6 },
  { 2, 6 },
  { 3, 4, 5, 6 },
  { 1, 3, 5, 6 },
  { 4, 5, 7 },
  { 1, 3, 6, 7 },
  { 1, 2, 3, 4, 6 },
  { 5 },
  { 2, 4, 5, 7 },
  { 1, 5, 6 },
  { 2, 3, 4, 6, 7 },
  { 1, 2 },
  { 3, 5, 7 },
  { 2, 3, 5 },
  { 2, 6 },
  { 5, 7 },
  { 1, 3, 6 },
  { 1, 2, 6 },
  { 2, 3, 5 },
  { 1, 2, 4, 5, 7 },
  { 2, 4, 5, 7 },
  { 1, 2, 3, 7 },
  { 3, 4 },
  { 1, 3 },
  { 3, 6, 7 },
  { 1, 2, 3, 6, 7 },
  { 4, 5, 6 },
  { 3, 6, 7 },
  { 1, 2, 3, 4, 7 },
  { 4, 5 },
  { 2, 5, 6, 7 },
  { 2, 3 },
  { 7 },
  { 1, 2, 4, 7 },
  { 1, 5, 6, 7 },
  { 1, 3, 6 },
  { 1, 3, 6, 7 },
  { 2, 3, 5 },
  { 3, 4 },
  { 1, 2, 3 },
  { 2, 3, 4, 6, 7 },
  { 1, 2, 3, 5, 7 },
  { 1, 3, 7 },
  { 1, 2, 4 },
  { 2, 3, 4, 5 },
  { 1, 2, 5 },
  { 2, 5, 6 },
  { 1 },
  { 2, 3 },
  { 3, 4, 5, 6 },
  { 2, 3, 4, 6 },
  { 3, 5 },
  { 1, 2, 3, 4, 5, 7 },
  { 1, 2, 6 },
  { 6, 7 },
  { 3, 4, 7 },
  { 1, 2, 3, 5, 7 },
  { 3, 4 },
  { 2, 5, 6 },
  { 1, 2, 3, 4, 7 },
  { 1 },
  { 1, 2, 3, 5 },
  { 1, 6, 7 },
  { 1, 3, 5 },
  { 1, 3, 5, 6 },
  { 2, 5 },
  { 1, 2, 4, 6 },
  { 2, 5, 6, 7 },
  { 3, 4, 6, 7 },
  { 1, 3, 4, 5, 7 },
  { 3, 4, 7 },
  { 3, 5, 6 },
  { 3 },
  { 1, 2, 3, 5, 6 },
  { 5 },
  { 3 },
  { 1, 4 },
  { 1, 2, 3, 5, 6 },
  { 2, 4 },
  { 3, 4, 6 },
  { 4, 5 },
  { 1, 2, 4, 7 }
];
producedDay = [5, 25, 25, 25, 25, 25, 25, 25, 25, 5, 25, 25, 25, 25, 25, 25, 21, 25, 23, 25, 25, 25, 3, 25, 25, 25, 4, 25, 25, 25, 25, 23, 25, 25, 25, 7, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 15, 25, 25, 25, 25, 25, 25, 25, 25, 22, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 9, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 1, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 6, 25, 25, 25, 1, 4, 21, 18, 25, 25, 2, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 12, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 14, 21, 25, 25, 25, 25, 25, 12, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 8, 25, 25, 19, 25, 4, 25, 25, 25];
deadLineDay = [34, 48, 32, 28, 46, 42, 27, 50, 26, 30, 33, 41, 49, 26, 50, 50, 50, 50, 48, 50, 50, 40, 38, 50, 50, 46, 27, 40, 41, 48, 50, 50, 30, 50, 50, 12, 46, 37, 50, 50, 32, 38, 50, 50, 28, 26, 50, 41, 50, 50, 50, 41, 50, 50, 47, 50, 50, 50, 27, 50, 50, 47, 34, 43, 32, 43, 50, 33, 50, 50, 50, 50, 39, 43, 50, 29, 50, 43, 43, 42, 30, 50, 50, 50, 37, 50, 50, 10, 50, 50, 50, 49, 50, 26, 50, 50, 50, 50, 36, 50, 35, 50, 34, 30, 21, 35, 39, 33, 34, 50, 28, 50, 47, 50, 50, 46, 50, 50, 31, 34, 50, 50, 21, 50, 50, 44, 29, 50, 29, 50, 50, 45, 50, 50, 50, 50, 43, 50, 27, 50, 50, 50, 50, 32, 50, 50, 50, 21, 41, 40, 50, 50, 31, 50, 23, 50, 50, 50, 50, 50, 40, 50, 50, 50, 50, 38, 46, 50, 50, 43, 26, 25, 49, 50, 50, 40, 23, 50, 37, 47];

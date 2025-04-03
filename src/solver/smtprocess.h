#ifndef SMTPROCESS_H_
#define SMTPROCESS_H_

#include "boost/process/detail/child_decl.hpp"
#include "boost/process/pipe.hpp"
#include <boost/process.hpp>
#include "defines.h"
#include "solver/smtsolver.h"

using namespace std;

class SMTProcess {
public:
  SMTProcess(SMTSolverCommand solverCommand);
  SMTProcess(string solverCommand);

  void Send(string body);
  unique_ptr<SolverResult> CheckSatAndGetAssignments(list<Atom*> &atoms, list<SymbolicTerm*> &constraintVariables, list<MinimizationStatement*> &minimizations, Param &params, list<list<tuple<int, int, Atom*>>> &lwCollections);
private:
  SMTSolverCommand solverOption = NO_VALUE;
  list<string> solvers = {"CVC4", "CVC5", "Z3", "YICES"};
  boost::process::ipstream output;
  boost::process::opstream input;
  boost::process::child process;

  map<string, string> getRawAssignments(list<string> &variableNames);
  void setSolverOption(string solverCommand);
};

#endif // SMTPROCESS_H_

#ifndef QF_IDL_logic_H_
#define QF_IDL_logic_H_

#include "QF_LIA_logic.h"

class QF_IDL_logic : public QF_LIA_logic {
public:
    bool optimization;
    QF_IDL_logic(bool optimization) : optimization(optimization) {};
    string SMT_LOGIC_NAME() override;
    void getAssertionStatements(std::ostringstream &output) override;

    string getDiffAssertionStatement(TheoryStatement* statement);
};

#endif // QF_IDL_logic_H_
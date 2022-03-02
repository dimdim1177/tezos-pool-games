const _ = Test.reset_state(5n, (list []: list(tez)));

const aOWNER = Test.nth_bootstrap_account(0);
const aADMIN = Test.nth_bootstrap_account(1);
const aMANAGER = Test.nth_bootstrap_account(2);
const aUSER0 = Test.nth_bootstrap_account(3);
const aUSER1 = Test.nth_bootstrap_account(4);

function mustOK(const r: test_exec_result): bool is
    case r of [
    | Success(n) -> True
    | Fail(err) -> False
    ];

function mustERR(const r: test_exec_result; const cERR: string): bool is
    case r of [
    | Success(n) -> False
    | Fail(err) -> case err of [
        | Rejected(e, addr) -> Test.michelson_equal(e, Test.compile_value(cERR))
        | Other -> False
        ]
    ];

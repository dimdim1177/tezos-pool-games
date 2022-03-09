const testCreateFutureOK = {
    const (caddr, c) = originate(unit);
    Test.set_source(aUSER0);
    Test.set_now(tsNow);
    const r = Test.transfer_to_contract(c, CreateFuture((tsEvent, iobj)), 0mutez);
    Test.log(("CreateFutureOK", r));

    var musts: t_storage := initialStorage(unit);
    const ifuture: t_ifuture = record [
        addr = aUSER0;
        ts = tsEvent;
        iobj = iobj;
    ];
    musts.futures[ifuture] := emptyFuture;
} with (mustOK(r)) and (musts = Test.get_storage(caddr));

const testCreateFutureFailOnlyFuture = {
    const (caddr, c) = originate(unit);
    Test.set_source(aUSER0);
    Test.set_now(tsNow + 10);
    const r = Test.transfer_to_contract(c, CreateFuture((tsNow, iobj)), 0mutez);
    Test.log(("CreateFutureFailOnlyFuture", r));
} with (mustERR(r, cERR_ONLY_FUTURE)) and (initialStorage(unit) = Test.get_storage(caddr));

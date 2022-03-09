const testDeleteFutureOK = {
    const (caddr, c) = originate(unit);
    Test.set_source(aUSER0);
    Test.set_now(tsNow + 100);
    const r0 = Test.transfer_to_contract(c, CreateFuture((tsEvent, iobj)), 0mutez);
    const r = Test.transfer_to_contract(c, DeleteFuture((tsEvent, iobj)), 0mutez);
    Test.log(("DeleteFutureOK", r));
} with (mustOK(r)) and (initialStorage(unit) = Test.get_storage(caddr));

const testForceDeleteFutureOK = {
    const (caddr, c) = originate(unit);
    Test.set_source(aUSER0);
    Test.set_now(tsNow + 110);
    const r0 = Test.transfer_to_contract(c, CreateFuture((tsEvent, iobj)), 0mutez);
    Test.set_source(aOWNER);
    const ifuture: t_ifuture = record [
        addr = aUSER0;
        ts = tsEvent;
        iobj = iobj;
    ];
    const r = Test.transfer_to_contract(c, ForceDeleteFuture(ifuture), 0mutez);
    Test.log(("ForceDeleteFutureOK", r));
} with (mustOK(r)) and (initialStorage(unit) = Test.get_storage(caddr));

const testForceDeleteFutureFailDenied = {
    const (caddr, c) = originate(unit);
    Test.set_source(aUSER0);
    Test.set_now(tsNow + 120);
    const r0 = Test.transfer_to_contract(c, CreateFuture((tsEvent, iobj)), 0mutez);
    Test.set_source(aUSER1);
    const ifuture: t_ifuture = record [
        addr = aUSER0;
        ts = tsEvent;
        iobj = iobj;
    ];
    const r = Test.transfer_to_contract(c, ForceDeleteFuture(ifuture), 0mutez);
    Test.log(("ForceDeleteFutureFailDenied", r));

    var musts: t_storage := initialStorage(unit);
    musts.futures[ifuture] := emptyFuture;
} with ((mustERR(r, MOwner.cERR_DENIED)) or (mustERR(r, MAdmin.cERR_DENIED))) and (musts = Test.get_storage(caddr));

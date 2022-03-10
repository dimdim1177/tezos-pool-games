const testFillFutureFailDenied = {
    const (caddr, c) = originate(unit);
    Test.set_source(aUSER0);
    Test.set_now(tsNow + 200);
    const r0 = Test.transfer_to_contract(c, CreateFuture((tsEvent, iobj)), 0mutez);
    Test.set_source(aUSER1);
    const ifuture: t_ifuture = record [
        addr = aUSER0;
        ts = tsEvent;
        iobj = iobj;
    ];
    const r = Test.transfer_to_contract(c, FillFuture((ifuture, filledFuture)), 0mutez);
    Test.log(("FillFutureFailDenied", r));

    var musts: t_storage := initialStorage(unit);
    musts.futures[ifuture] := emptyFuture;
} with ((mustERR(r, MOwner.cERR_DENIED)) or (mustERR(r, MAdmin.cERR_DENIED))) and (musts = Test.get_storage(caddr));

const testFillFutureFailDenied = {
    const (caddr, c) = originate(unit);
    Test.set_source(aUSER0);
    Test.set_now(tsNow + 210);
    const r0 = Test.transfer_to_contract(c, CreateFuture((tsEvent, iobj)), 0mutez);
    Test.set_source(aUSER1);
    const ifuture: t_ifuture = record [
        addr = aUSER0;
        ts = tsEvent;
        iobj = iobj;
    ];
    const r = Test.transfer_to_contract(c, FillFuture((ifuture, filledFuture)), 0mutez);
    Test.log(("FillFutureFailDenied", r));

    var musts: t_storage := initialStorage(unit);
    musts.futures[ifuture] := emptyFuture;
} with ((mustERR(r, MOwner.cERR_DENIED)) or (mustERR(r, MAdmin.cERR_DENIED))) and (musts = Test.get_storage(caddr));

const testFillFutureFailEarly = {
    const (caddr, c) = originate(unit);
    Test.set_source(aUSER0);
    Test.set_now(tsNow + 220);
    const r0 = Test.transfer_to_contract(c, CreateFuture((tsEvent, iobj)), 0mutez);
    Test.set_source(aOWNER);
    const ifuture: t_ifuture = record [
        addr = aUSER0;
        ts = tsEvent;
        iobj = iobj;
    ];
    const r = Test.transfer_to_contract(c, FillFuture((ifuture, filledFuture)), 0mutez);
    Test.log(("FillFutureFailEarly", r));

    var musts: t_storage := initialStorage(unit);
    musts.futures[ifuture] := emptyFuture;
} with (mustERR(r, cERR_EARLY)) and (musts = Test.get_storage(caddr));

const testGetFutureFailNotFound = {
    const (caddr, c) = originate(unit);
    Test.set_source(aUSER0);
    const cb = originateCallback(unit);
    const r = Test.transfer_to_contract(c, GetFuture((tsEvent, iobj, cb)), 0mutez);
    Test.log(("GetFutureFailNotFound", r));
} with (mustERR(r, cERR_NOT_FOUND)) and (initialStorage(unit) = Test.get_storage(caddr));

const testGetFutureFailNotReady = {
    const (caddr, c) = originate(unit);
    Test.set_source(aUSER0);
    Test.set_now(tsNow + 230);
    const r0 = Test.transfer_to_contract(c, CreateFuture((tsEvent, iobj)), 0mutez);
    const cb = originateCallback(unit);
    const r = Test.transfer_to_contract(c, GetFuture((tsEvent, iobj, cb)), 0mutez);
    Test.log(("GetFutureFailNotReady", r));

    var musts: t_storage := initialStorage(unit);
    const ifuture: t_ifuture = record [
        addr = aUSER0;
        ts = tsEvent;
        iobj = iobj;
    ];
    musts.futures[ifuture] := emptyFuture;
} with (mustERR(r, cERR_NOT_READY)) and (musts = Test.get_storage(caddr));

const testFillGetFutureOK = {
    const (caddr, c) = originate(unit);
    Test.set_source(aUSER0);
    const r0 = Test.transfer_to_contract(c, CreateFuture((tsEvent, iobj)), 0mutez);
    Test.set_source(aOWNER);
    const ifuture: t_ifuture = record [
        addr = aUSER0;
        ts = tsEvent;
        iobj = iobj;
    ];
    Test.set_now(filledFuture.tsLevel);
    const r = Test.transfer_to_contract(c, FillFuture((ifuture, filledFuture)), 0mutez);
    Test.log(("FillGetFutureOK", "Fill", r));

    var musts: t_storage := initialStorage(unit);
    musts.futures[ifuture] := filledFuture;

    if ((mustOK(r)) and (musts = Test.get_storage(caddr))) then block {
        Test.set_source(aUSER0);
        const cb = originateCallback(unit);
        const r = Test.transfer_to_contract(c, GetFuture((tsEvent, iobj, cb)), 0mutez);
        Test.log(("FillGetFutureOK", "Get", r));
        musts := initialStorage(unit);
    } else skip;
} with (mustOK(r)) and (musts = Test.get_storage(caddr));

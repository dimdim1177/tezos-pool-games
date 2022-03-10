const testEditPoolFailDenied = {
    const (caddr, c) = originate(unit);
#if ENABLE_POOL_AS_SERVICE
    const creator = aUSER0;
#else // ENABLE_POOL_AS_SERVICE
    const creator = aOWNER;
#endif // else ENABLE_POOL_AS_SERVICE
    Test.set_source(creator);
    const pool_create = poolCreate(False, False);
    const r0 = Test.transfer_to_contract(c, CreatePool(pool_create), 0mutez);
    Test.set_source(aUSER1);
    const pool_edit = poolEdit(False, False);
    const r = Test.transfer_to_contract(c, EditPool((1n, pool_edit)), 0mutez);
    Test.log(("EditPoolFailDenied", r));
    var musts: t_storage := initialStorage(unit);
    musts.pools[musts.inext] := poolCreated(pool_create, creator);
    musts.inext := musts.inext + 1n;
    musts.usedFarms[(pool_create.farm.addr, pool_create.farm.id)] := unit;
} with ((mustERR(r, MManager.cERR_DENIED)) or ((mustERR(r, MAdmin.cERR_DENIED))) or (mustERR(r, MOwner.cERR_DENIED))) and (musts = Test.get_storage(caddr));

const testEditPoolFailEditActive = {
    const (caddr, c) = originate(unit);
    const creator = aOWNER;
    Test.set_source(creator);
    const pool_create = poolCreate(False, False);
    const r0 = Test.transfer_to_contract(c, CreatePool(pool_create), 0mutez);
    const pool_edit = poolEdit(False, False);
    const r = Test.transfer_to_contract(c, EditPool((1n, pool_edit)), 0mutez);
    Test.log(("EditPoolFailEditActive", r));
    var musts: t_storage := initialStorage(unit);
    musts.pools[musts.inext] := poolCreated(pool_create, creator);
    musts.inext := musts.inext + 1n;
    musts.usedFarms[(pool_create.farm.addr, pool_create.farm.id)] := unit;
} with (mustERR(r, MPool.cERR_EDIT_ACTIVE)) and (musts = Test.get_storage(caddr));

const testEditPoolOK = {
    const (caddr, c) = originate(unit);
    const creator = aOWNER;
    Test.set_source(creator);
    var pool_create: t_pool_create := poolCreate(False, False);
    pool_create.state := PoolStatePause;
    const r0 = Test.transfer_to_contract(c, CreatePool(pool_create), 0mutez);
    Test.log(("EditPoolOK", "Create", r0));
    const pool_edit = poolEdit(False, False);
    const r = Test.transfer_to_contract(c, EditPool((1n, pool_edit)), 0mutez);
    Test.log(("EditPoolOK", r));
    var musts: t_storage := initialStorage(unit);
    var pool: t_pool := poolEdited(pool_create, creator, pool_edit);
    pool.game.state := GameStatePause;
    pool.game.tsBeg := ("2022-01-01T00:00:00Z" : timestamp);
    pool.game.tsEnd := pool.game.tsBeg;
    musts.pools[musts.inext] := pool;
    musts.inext := musts.inext + 1n;
    musts.usedFarms[(pool_create.farm.addr, pool_create.farm.id)] := unit;
} with (mustOK(r)) and (musts = Test.get_storage(caddr));

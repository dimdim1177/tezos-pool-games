function createPoolOK(const burn: bool; const fee: bool): bool is block {
    const (caddr, c) = originate(unit);
#if ENABLE_POOL_AS_SERVICE
    const creator = aUSER0;
#else // ENABLE_POOL_AS_SERVICE
    const creator = aOWNER;
#endif // else ENABLE_POOL_AS_SERVICE
    Test.set_source(creator);
    const pool_create = poolCreate(burn, fee);
    const r = Test.transfer_to_contract(c, CreatePool(pool_create), 0mutez);
    Test.log(("CreatePoolOK", "burn", burn, "fee", fee, r));

    var musts: t_storage := initialStorage(unit);
    musts.pools[musts.inext] := poolCreated(pool_create, creator);
    musts.inext := musts.inext + 1n;
    musts.usedFarms[(pool_create.farm.addr, pool_create.farm.id)] := unit;
} with (mustOK(r)) and (musts = Test.get_storage(caddr));

const testCreatePoolOK00 = {
    const r = createPoolOK(False, False);
    Test.log(("testCreatePoolOK00", r));
} with r;

const testCreatePoolOK01 = {
    const r = createPoolOK(False, True);
    Test.log(("testCreatePoolOK01", r));
} with r;

const testCreatePoolOK10 = {
    const r = createPoolOK(True, False);
    Test.log(("testCreatePoolOK10", r));
} with r;

const testCreatePoolOK11 = {
    const r = createPoolOK(True, True);
    Test.log(("testCreatePoolOK11", r));
} with r;

const testCreatePoolFailInvalidState = {
    const (caddr, c) = originate(unit);
    Test.set_source(aOWNER);
    var pool_create: t_pool_create := poolCreate(False, False);
    pool_create.state := PoolStateRemove;
    const r = Test.transfer_to_contract(c, CreatePool(pool_create), 0mutez);
    Test.log(("CreatePoolFailInvalidState", r));
} with (mustERR(r, MPool.cERR_INVALID_STATE)) and (initialStorage(unit) = Test.get_storage(caddr));

const testCreatePoolFailMustBurnToken = {
    const (caddr, c) = originate(unit);
    Test.set_source(aOWNER);
    var pool_create: t_pool_create := poolCreate(True, False);
    pool_create.burnToken := (None: option(MToken.t_token));
    const r = Test.transfer_to_contract(c, CreatePool(pool_create), 0mutez);
    Test.log(("CreatePoolFailMustBurnToken", r));
} with (mustERR(r, MPool.cERR_MUST_BURN_TOKEN)) and (initialStorage(unit) = Test.get_storage(caddr));

const testCreatePoolFailMustBurnSwap = {
    const (caddr, c) = originate(unit);
    Test.set_source(aOWNER);
    var pool_create: t_pool_create := poolCreate(True, False);
    pool_create.burnSwap := (None: option(MQuipuswap.t_swap));
    const r = Test.transfer_to_contract(c, CreatePool(pool_create), 0mutez);
    Test.log(("CreatePoolFailMustBurnSwap", r));
} with (mustERR(r, MPool.cERR_MUST_BURN_SWAP)) and (initialStorage(unit) = Test.get_storage(caddr));

const testCreatePoolFailMustRewardSwap = {
    const (caddr, c) = originate(unit);
    Test.set_source(aOWNER);
    var pool_create: t_pool_create := poolCreate(True, False);
    pool_create.rewardSwap := (None: option(MQuipuswap.t_swap));
    const r = Test.transfer_to_contract(c, CreatePool(pool_create), 0mutez);
    Test.log(("CreatePoolFailMustRewardSwap", r));
} with (mustERR(r, MPool.cERR_MUST_REWARD_SWAP)) and (initialStorage(unit) = Test.get_storage(caddr));

const testCreatePoolFailMustFeeAddr = {
    const (caddr, c) = originate(unit);
    Test.set_source(aOWNER);
    var pool_create: t_pool_create := poolCreate(False, True);
    pool_create.feeAddr := (None: option(address));
    const r = Test.transfer_to_contract(c, CreatePool(pool_create), 0mutez);
    Test.log(("CreatePoolFailMustFeeAddr", r));
} with (mustERR(r, MPool.cERR_MUST_FEEADDR)) and (initialStorage(unit) = Test.get_storage(caddr));

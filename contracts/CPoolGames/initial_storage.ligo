(record [
#if ENABLE_OWNER
    owner = ("OWNER_ADDRESS": address);
#endif // ENABLE_OWNER
#if ENABLE_ADMIN
    admin = ("OWNER_ADDRESS": address);
#endif // ENABLE_ADMIN
#if ENABLE_ADMINS
    admins = (set []: t_admins);
#endif // ENABLE_ADMINS
    inext = 1n;
    pools = (big_map []: t_pools);
    users = (big_map []: t_ipooladdr2user);
    waitBalanceBeforeHarvest = -1;
    waitBalanceAfterHarvest = -1;
    waitBalanceBeforeTez2Burn = -1;
    waitBalanceAfterTez2Burn = -1;
    usedFarms = (big_map []: t_farms);
#if !ENABLE_TRANSFER_SECURITY
    approved = (big_map []: t_approved);
#endif // !ENABLE_TRANSFER_SECURITY
]: t_storage)

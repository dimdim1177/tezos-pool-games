///RU \file
///RU \brief Начальное состояние хранилища для деплоя
///EN \file
///EN \brief Initial state of storage for deploy

(record [
#if ENABLE_OWNER
    owner = ("OWNER_ADDRESS": address);
#endif // ENABLE_OWNER
#if ENABLE_ADMIN
    admin = ("OWNER_ADDRESS": address);//RU Владельца используем как админа //EN We use the owner as an admin
#endif // ENABLE_ADMIN
#if ENABLE_ADMINS
#if !ENABLE_OWNER
    admins = (set [("OWNER_ADDRESS": address)]: MAdmins.t_admins);
#else // !ENABLE_OWNER
    admins = (set []: MAdmins.t_admins);
#endif // else !ENABLE_OWNER
#endif // ENABLE_ADMINS
    inext = 1n;//RU ID первого пула //EN ID of the first pool
    pools = (big_map []: t_pools);
    users = (big_map []: t_ipooladdr2user);
    waitBalanceBeforeHarvest = -1;//RU Не ожидаем колбек //EN Don't expect a callback
    waitBalanceAfterHarvest = -1;//RU Не ожидаем колбек //EN Don't expect a callback
    waitBalanceBeforeTez2Burn = -1;//RU Не ожидаем колбек //EN Don't expect a callback
    waitBalanceAfterTez2Burn = -1;//RU Не ожидаем колбек //EN Don't expect a callback
    usedFarms = (big_map []: t_farms);
#if !ENABLE_TRANSFER_SECURITY
    approved = (big_map []: t_approved);
#endif // !ENABLE_TRANSFER_SECURITY
]: t_storage)

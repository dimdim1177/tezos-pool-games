#include "../../contracts/CPoolGames.ligo"
#include "../include/workspace.ligo"

function initialStorage(const _: unit): t_storage is block {
    const s = (record [
#if ENABLE_OWNER
        owner = aOWNER;
#endif // ENABLE_OWNER
#if ENABLE_ADMIN
        admin = aOWNER;//RU Владельца используем как админа //EN We use the owner as an admin
#endif // ENABLE_ADMIN
#if ENABLE_ADMINS
#if !ENABLE_OWNER
        admins = (set [aOWNER]: MAdmins.t_admins);
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
    ]: t_storage);
} with s;

function originate(const _: unit): typed_address(t_entrypoint, t_storage) * contract(t_entrypoint) is block {
    const sini = initialStorage(unit);
    const (addr, _, _) = Test.originate(main, sini, 0tez);
    const contract = Test.to_contract(addr);
} with (addr, contract);

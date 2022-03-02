#include "../../contracts/CRandom.ligo"
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
    futures = (big_map []: t_futures);
    ]: t_storage);
} with s;

function originate(const _: unit): typed_address(t_entrypoint, t_storage) * contract(t_entrypoint) is block {
    const sini = initialStorage(unit);
    const (addr, _, _) = Test.originate(main, sini, 0tez);
    const contract = Test.to_contract(addr);
} with (addr, contract);

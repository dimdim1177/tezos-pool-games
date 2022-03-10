#include "../include/workspace.ligo"
#include "../../contracts/CRandom.ligo"

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

type t_callback_storage is [@layout:comb] record [
    iobj: MRandom.t_iobj;
    random: MRandom.t_random;
];

function callbackContract(const e: MRandom.t_callback_params; var s: t_callback_storage): list(operation) * t_callback_storage is block {
    case e of [
    | OnRandomCallback(iobj_random) -> block {
        s.iobj := iobj_random.0;
        s.random := iobj_random.1;
    }
    ];
} with (cNO_OPERATIONS, s);

function originateCallback(const _: unit): MRandom.t_callback is block {
    const (addr, _, _) = Test.originate(callbackContract, (record [iobj = 0n; random = 0n]: t_callback_storage), 0tez);
    const contract = (Test.to_contract(addr): MRandom.t_callback);
} with contract;

const tsNow: timestamp = ("2022-01-01T00:00:00Z" : timestamp);
const tsEvent: timestamp = ("2022-01-01T01:00:00Z" : timestamp);
const iobj: nat = 12345n;

const emptyFuture: t_future = record [
    tsLevel = ("1970-01-01T00:00:00Z" : timestamp);
    level = 0n;
    random = 0n;
];

const filledFuture: t_future = record [
    tsLevel = tsEvent + 10;
    level = 1234567890n;
    random = 1234567890123456789012345678901234567890n;
];

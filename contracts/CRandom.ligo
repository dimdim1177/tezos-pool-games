/// \file
/// \author Dmitrii Dmitriev
/// \date 02.2022
/// \copyright MIT
///RU Контракт для РЕДКОЙ генерации случайного числа по запросу на основе блоков Тезос
///EN Contract for SELDOM generation random number by request based on Tezos blocks

#include "CRandom/storage.ligo"
#include "CRandom/access.ligo"

///RU Все точки входа контракта
///EN All entrypoints of contract
type t_entrypoint is
//RU --- Управление доступами
//EN --- Access management

#if ENABLE_OWNER
///RU Смена владельца контракта
///EN Change owner of contract
| ChangeOwner of MOwner.t_owner
#endif // ENABLE_OWNER

#if ENABLE_ADMIN
///RU Смена админа контракта
///EN Change admin of contract
| ChangeAdmin of MAdmins.t_admin
#endif // ENABLE_ADMIN

#if ENABLE_ADMINS
///RU Добавление админа контракта
///EN Add admin of contract
| AddAdmin of MAdmins.t_admin

///RU Удаление админа контракта
///EN Remove admin of contract
| RemAdmin of MAdmins.t_admin
#endif // ENABLE_ADMINS

///RU Создание запроса на случайное число
///EN Creating a request for a random number
| CreateFuture of MRandom.t_ts_iobj

///RU Удаление запроса на случайное число
///EN Deleting a request for a random number
| DeleteFuture of MRandom.t_ts_iobj

///RU Запрос случайного числа
///EN Random Number Request
| GetFuture of MRandom.t_ts_iobj_callback

///RU Заполнение случайного числа
///EN Filling in a random number
| FillFuture of t_ifuture * t_future

///RU Принудительное удаление запроса на случайное число админом контракта
///EN Forced deletion of a request for a random number by the contract admin
| ForceDeleteFuture of t_ifuture
;

///RU Время заказа случайного числа должно быть в будущем
///EN The order time of a random number should be in the future
const cERR_ONLY_FUTURE: string = "OnlyFuture";

///RU Не найдено случайное число
///EN No random number found
const cERR_NOT_FOUND: string = "NotFound";

///RU Случайное число еще не получено
///EN Random number not received yet
const cERR_NOT_READY: string = "NotReady";

///RU Получение случайного числа с выдачей ошибки, если не найдено
///EN Getting a random number with an error if not found
function getFuture(const s: t_storage; const ifuture: t_ifuture): t_future is
    case s.futures[ifuture] of [
    | Some(future) -> future
    | None -> (failwith(cERR_NOT_FOUND): t_future)
    ];

///RU Единая точка входа контракта
///EN Single entry point of the contract
function main(const entrypoint: t_entrypoint; var s: t_storage): t_return is
case entrypoint of [

//RU --- Управление доступами
//EN --- Access management

#if ENABLE_OWNER //RU Есть владелец контракта //EN There is a contract owner
| ChangeOwner(newowner) -> (cNO_OPERATIONS, block { s.owner := MOwner.accessChange(newowner, s.owner); } with s)
#endif // ENABLE_OWNER

#if ENABLE_ADMIN //RU Есть админ контракта //EN There is an admin of the contract
| ChangeAdmin(newadmin) -> (cNO_OPERATIONS, block { mustAdmin(s); s.admin := newadmin; } with s)
#endif // ENABLE_ADMIN

#if ENABLE_ADMINS //RU Есть набор админов контракта //EN There is a set of contract admins
| AddAdmin(addadmin) -> (cNO_OPERATIONS, block { mustAdmin(s); s.admins := MAdmins.forceAdd(addadmin, s.admins); } with s)
| RemAdmin(remadmin) -> (cNO_OPERATIONS, block { mustAdmin(s); s.admins := MAdmins.forceRem(remadmin, s.admins); } with s)
#endif // ENABLE_ADMINS

//RU Создание запроса на случайное число
//EN Creating a request for a random number
| CreateFuture(ts_iobj) -> (cNO_OPERATIONS, block {
    const ts: MRandom.t_ts = ts_iobj.0;
    if ts <= Tezos.now then failwith(cERR_ONLY_FUTURE) else skip;
    const ifuture: t_ifuture = record [
        addr = Tezos.sender;
        ts = ts;
        iobj = ts_iobj.1;
    ];
    s.futures[ifuture] := record [
        tsLevel = ("1970-01-01T00:00:00Z" : timestamp);
        level = 0n;
        random = 0n;
    ];
} with s)

//RU Удаление запроса на случайное число
//EN Deleting a request for a random number
| DeleteFuture(ts_iobj) -> (cNO_OPERATIONS, block {
    const ifuture: t_ifuture = record [
        addr = Tezos.sender;
        ts = ts_iobj.0;
        iobj = ts_iobj.1;
    ];
    s.futures := Big_map.remove(ifuture, s.futures);
} with s)

//RU Заполнение случайного числа админом контракта
//EN Filling in a random number by the contract admin
| FillFuture(ifuture_future) -> (cNO_OPERATIONS, block {
    mustAdmin(s);
    const ifuture: t_ifuture = ifuture_future.0;
    if Big_map.mem(ifuture, s.futures) then s.futures[ifuture] := ifuture_future.1 ///RU Заполняем только существующие ///EN Fill in only existing ones
    else skip;
} with s)

//RU Получения случайного числа
//EN Getting a random number
| GetFuture(ts_iobj_callback) -> block {
    const iobj: MRandom.t_iobj = ts_iobj_callback.1;
    const ifuture: t_ifuture = record [
        addr = Tezos.sender;
        ts = ts_iobj_callback.0;
        iobj = iobj;
    ];
    const future = getFuture(s, ifuture);
    if 0n = future.level then failwith(cERR_NOT_READY)
    else skip;
    const operations = list [
        Tezos.transaction(
            OnRandomCallback(iobj, future.random),
            0mutez,
            ts_iobj_callback.2
        );
    ];
    s.futures := Big_map.remove(ifuture, s.futures);
} with (operations, s)

//RU Принудительное удаление запроса на случайное число админом контракта
//EN Forced deletion of a request for a random number by the contract admin
| ForceDeleteFuture(ifuture) -> (cNO_OPERATIONS, block {
    mustAdmin(s);
    s.futures := Big_map.remove(ifuture, s.futures);
} with s)
];

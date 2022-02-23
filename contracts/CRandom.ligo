///RU \namespace CRandom
///RU Контракт для РЕДКОЙ генерации случайного числа по запросу
///EN \namespace CRandom
///EN Contract for SELDOM generation random number by request
/// \author Dmitrii Dmitriev
/// \date 02.2022
/// \copyright MIT

#include "CRandom/storage.ligo"
#include "CRandom/access.ligo"

type t_entrypoint is
///RU --- Управление доступами
#if ENABLE_OWNER
| ChangeOwner of t_owner ///RU< Смена владельца контракта ///EN< Change owner of contract
#endif // ENABLE_OWNER
#if ENABLE_ADMIN
| ChangeAdmin of t_admin ///RU< Смена админа контракта ///EN< Change admin of contract
#endif // ENABLE_ADMIN
#if ENABLE_ADMINS
| AddAdmin of t_admin ///RU< Добавление админа контракта ///EN< Add admin of contract
| RemAdmin of t_admin ///RU< Удаление админа контракта ///EN< Remove admin of contract
#endif // ENABLE_ADMINS
| CreateFuture of t_ts_iobj ///RU< Создание запроса на случайное число
| DeleteFuture of t_ts_iobj ///RU< Удаление запроса на случайное число
| GetFuture of t_ts_iobj_callback ///RU< Запрос случайного числа
| FillFuture of t_ifuture * t_future ///RU< Заполнение случайного числа
| ForceDeleteFuture of t_ifuture ///RU< Принудительное удаление запроса на случайное число админом контракта
;

const cERR_ONLY_FUTURE: string = "OnlyFuture";///RU< Время заказа случайного числа должно быть в будущем
const cERR_NOT_FOUND: string = "NotFound";///RU< Не найдено случайное число
const cERR_NOT_READY: string = "NotReady";///RU< Случайное число еще не получено

///RU Получение случайного числа с выдачей ошибки, если не найдено
function getFuture(const s: t_storage; const ifuture: t_ifuture): t_future is
    case s.futures[ifuture] of [
    | Some(future) -> future
    | None -> (failwith(cERR_NOT_FOUND): t_future)
    ];

///RU Единая точка входа контракта
function main(const entrypoint: t_entrypoint; var s: t_storage): t_return is
case entrypoint of [
///RU --- Управление доступами
#if ENABLE_OWNER ///RU Есть владелец контракта
| ChangeOwner(newowner) -> (cNO_OPERATIONS, block { s.owner:= MOwner.accessChange(newowner, s.owner); } with s)
#endif // ENABLE_OWNER
#if ENABLE_ADMIN ///RU Есть админ контракта
| ChangeAdmin(newadmin) -> (cNO_OPERATIONS, block { mustAdmin(s); s.admin := newadmin; } with s)
#endif // ENABLE_ADMIN
#if ENABLE_ADMINS ///RU Есть набор админов контракта
| AddAdmin(addadmin) -> (cNO_OPERATIONS, block { mustAdmin(s); s.admins := MAdmins.forceAdd(addadmin, s.admins); } with s)
| RemAdmin(remadmin) -> (cNO_OPERATIONS, block { mustAdmin(s); s.admins := MAdmins.forceRem(remadmin, s.admins); } with s)
#endif // ENABLE_ADMINS

///RU Создание запроса на случайное число
| CreateFuture(ts_iobj) -> (cNO_OPERATIONS, block {
    const ts: t_ts = ts_iobj.0;
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

///RU Удаление запроса на случайное число
| DeleteFuture(ts_iobj) -> (cNO_OPERATIONS, block {
    const ifuture: t_ifuture = record [
        addr = Tezos.sender;
        ts = ts_iobj.0;
        iobj = ts_iobj.1;
    ];
    s.futures := Big_map.remove(ifuture, s.futures);
} with s)

///RU Заполнение случайного числа админом контракта
| FillFuture(ifuture_future) -> (cNO_OPERATIONS, block {
    mustAdmin(s);
    const ifuture: t_ifuture = ifuture_future.0;
    if Big_map.mem(ifuture, s.futures) then s.futures[ifuture] := ifuture_future.1 ///RU Заполняем только существующие
    else skip;
} with s)

///RU Получения случайного числа
| GetFuture(ts_iobj_callback) -> block {
    const iobj = ts_iobj_callback.1;
    const ifuture: t_ifuture = record [
        addr = Tezos.sender;
        ts = ts_iobj_callback.0;
        iobj = iobj;
    ];
    const future: t_future = getFuture(s, ifuture);
    if 0n = future.level then failwith(cERR_NOT_READY)
    else skip;
    const operations: t_operations = list [
        Tezos.transaction(
            OnRandomCallback(iobj, future.random),
            0mutez,
            ts_iobj_callback.2
        );
    ];
    s.futures := Big_map.remove(ifuture, s.futures);
} with (operations, s)

///RU Принудительное удаление запроса на случайное число админом контракта
| ForceDeleteFuture(ifuture) -> (cNO_OPERATIONS, block {
    mustAdmin(s);
    s.futures := Big_map.remove(ifuture, s.futures);
} with s)
];

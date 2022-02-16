#include "CRandom/storage.ligo"
#include "CRandom/access.ligo"

type t_entrypoint is
//RU --- Управление доступами
#if ENABLE_OWNER
| ChangeOwner of t_owner //RU< Смена владельца контракта //EN< Change owner of contract
#endif // ENABLE_OWNER
#if ENABLE_ADMIN
| ChangeAdmin of t_admin //RU< Смена админа контракта //EN< Change admin of contract
#endif // ENABLE_ADMIN
#if ENABLE_ADMINS
| AddAdmin of t_admin //RU< Добавление админа контракта //EN< Add admin of contract
| RemAdmin of t_admin //RU< Удаление админа контракта //EN< Remove admin of contract
#endif // ENABLE_ADMINS
| CreateFuture of t_iobj * t_event_ts //RU< Создание запроса на случайное число
| DeleteFuture of t_iobj * t_event_ts //RU< Удаление запроса на случайное число
| GetFuture of t_iobj * t_event_ts //RU< Запрос случайного числа
| FillFuture of t_ifuture * t_future //RU< Заполнение случайного числа
| ForceDeleteFuture of t_ifuture //RU< Принудительное удаление запроса на случайное число админом контракта
;

//RU Единая точка входа контракта
function main(const entrypoint: t_entrypoint; var s: t_storage): t_return is
case entrypoint of
//RU --- Управление доступами
#if ENABLE_OWNER //RU Есть владелец контракта
| ChangeOwner(newowner) -> (cNO_OPERATIONS, block { s.owner:= MOwner.accessChange(newowner, s.owner); } with s)
#endif // ENABLE_OWNER
#if ENABLE_ADMIN //RU Есть админ контракта
| ChangeAdmin(newadmin) -> (cNO_OPERATIONS, block { mustAdmin(s); s.admin := newadmin; } with s)
#endif // ENABLE_ADMIN
#if ENABLE_ADMINS //RU Есть набор админов контракта
| AddAdmin(addadmin) -> (cNO_OPERATIONS, block { mustAdmin(s); s.admins := MAdmins.forceAdd(addadmin, s.admins); } with s)
| RemAdmin(remadmin) -> (cNO_OPERATIONS, block { mustAdmin(s); s.admins := MAdmins.forceRem(remadmin, s.admins); } with s)
#endif // ENABLE_ADMINS
| CreateFuture(params) -> (cNO_OPERATIONS, block { skip; } with s)
| DeleteFuture(params) -> (cNO_OPERATIONS, block { skip; } with s)
| FillFuture(params) -> (cNO_OPERATIONS, block { skip; } with s)
| GetFuture(params) -> (cNO_OPERATIONS, block { skip; } with s)
| ForceDeleteFuture(params) -> (cNO_OPERATIONS, block { skip; } with s)
end;

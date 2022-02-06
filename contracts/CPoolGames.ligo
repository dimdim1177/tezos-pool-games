#include "include/consts.ligo"
#include "CPoolGames/config.ligo"
#include "CPoolGames/storage.ligo"
#include "CPoolGames/access.ligo"

type t_entrypoint is
//RU --- Управление доступами
#if ENABLE_OWNER
| ChangeOwner of MOwner.t_owner //RU< Смена владельца контракта //EN< Change owner of contract
#endif // ENABLE_OWNER
#if ENABLE_ADMIN
| ChangeAdmin of MAdmin.t_admin //RU< Смена админа контракта //EN< Change admin of contract
#endif // ENABLE_ADMIN
#if ENABLE_ADMINS
| AddAdmin of MAdmins.t_admin //RU< Добавление админа контракта //EN< Add admin of contract
| RemAdmin of MAdmins.t_admin //RU< Удаление админа контракта //EN< Remove admin of contract
#endif // ENABLE_ADMINS

//RU --- Управление пулами
| CreatePool of MCtrl.t_ctrl * MFarm.t_farm //RU< Создание нового пула //EN< Create new pool
| PausePool of MPools.t_ipool //RU< Приостановка пула //EN< Pause pool
| PlayPool of MPools.t_ipool //RU< Запуск пула (после паузы) //EN< Play pool (after pause)
| RemovePool of MPools.t_ipool //RU< Удаление пула (по окончании партии) //EN< Remove pool (after game)
| RemovePoolNow of MPools.t_ipool //RU< Удаление пула сейчас //EN< Remove pool now
#if ENABLE_EDIT_POOL
| EditPool of MPools.t_ipool * MCtrl.t_ctrl //RU< Редактирование пула (приостановленого) //EN< Edit pool (paused)
#endif // ENABLE_EDIT_POOL

//RU --- Для пользователей пулов
| Deposit of MPools.t_ipool * MUsers.t_balance //RU< Депозит в пул //EN< Deposit to pool
| Withdraw of MPools.t_ipool //RU< Извлечение из пула //EN< Withdraw from pool

//RU --- От провайдера случайных чисел
| OnRandom of MPools.t_ipool * nat //RU< Случайное число для определения победителя //EN< Random number for detect winner

//RU --- От фермы
| OnReward of MPools.t_ipool * nat //RU< Начисление вознаграждения от фермы //EN< Reward from farm

//RU Единая точка входа контракта
function main(const entrypoint: t_entrypoint; var s: t_storage): list(operation) * t_storage is
case entrypoint of
//RU --- Управление доступами
#if ENABLE_OWNER //RU Есть владелец контракта
| ChangeOwner(params) -> (c_NO_OPERATIONS, block { s.owner:= MOwner.accessChange(params, s.owner); } with s)
#endif // ENABLE_OWNER
#if ENABLE_ADMIN //RU Есть владелец контракта
| ChangeAdmin(params) -> (c_NO_OPERATIONS, block { mustAdmin(s); s.admin := params; } with s)
#endif // ENABLE_ADMIN
#if ENABLE_ADMINS //RU Есть набор админов контракта
| AddAdmin(params) -> (c_NO_OPERATIONS, block { mustAdmin(s); s.admins := MAdmins.forceAdd(params, s.admins); } with s)
| RemAdmin(params) -> (c_NO_OPERATIONS, block { mustAdmin(s); s.admins := MAdmins.forceRem(params, s.admins); } with s)
#endif // ENABLE_ADMINS

//RU --- Управление пулами
| CreatePool(params) -> (c_NO_OPERATIONS, block { mustAdmin(s); s.pools := MPools.createPool(s.pools, params.0, params.1); } with s)
| PausePool(params) -> (c_NO_OPERATIONS, block { mustAdmin(s); s.pools := MPools.pausePool(s.pools, params); } with s)
| PlayPool(params) -> (c_NO_OPERATIONS, block { mustAdmin(s); s.pools := MPools.playPool(s.pools, params); } with s)
| RemovePool(params) -> (c_NO_OPERATIONS, block { mustAdmin(s); s.pools := MPools.removePool(s.pools, params); } with s)
| RemovePoolNow(params) -> (c_NO_OPERATIONS, block { mustAdmin(s); s.pools := MPools.removePoolNow(s.pools, params); } with s)
#if ENABLE_EDIT_POOL
| EditPool(params) -> (c_NO_OPERATIONS, block { mustAdmin(s); s.pools := MPools.editPool(s.pools, params.0, params.1); } with s)
#endif // ENABLE_EDIT_POOL

//RU --- Для пользователей пулов
| Deposit(params) -> (c_NO_OPERATIONS, block { s.pools := MPools.deposit(s.pools, params.0, params.1); } with s)
| Withdraw(params) -> (c_NO_OPERATIONS, block { s.pools := MPools.withdraw(s.pools, params); } with s)

//RU --- От провайдера случайных чисел
| OnRandom(params) -> (c_NO_OPERATIONS, block { s.pools := MPools.onRandom(s.pools, params.0, params.1); } with s)

//RU --- От фермы
| OnReward(params) -> (c_NO_OPERATIONS, block { s.pools := MPools.onReward(s.pools, params.0, params.1); } with s)

end

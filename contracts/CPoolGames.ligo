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
| CreatePool of MCtrl.t_ctrl * MFarm.t_farm * MRandom.t_random //RU< Создание нового пула //EN< Create new pool
| PausePool of MPools.t_ipool //RU< Приостановка пула //EN< Pause pool
| PlayPool of MPools.t_ipool //RU< Запуск пула (после паузы) //EN< Play pool (after pause)
| RemovePool of MPools.t_ipool //RU< Удаление пула (по окончании партии) //EN< Remove pool (after game)
#if ENABLE_POOL_FORCE
| ForceRemovePool of MPools.t_ipool //RU< Принудительное удаление пула сейчас //EN< Force remove pool now
#endif // ENABLE_POOL_FORCE
#if ENABLE_POOL_EDIT
| EditPool of MPools.t_ipool * option(MCtrl.t_ctrl) * option(MFarm.t_farm) * option(MRandom.t_random) //RU< Редактирование пула (приостановленого) //EN< Edit pool (paused)
#if ENABLE_POOL_FORCE
| ForceEditPool of MPools.t_ipool * option(MCtrl.t_ctrl) * option(MFarm.t_farm) * option(MRandom.t_random) //RU< Принудительное редактирование пула //EN< Force edit pool
#endif // ENABLE_POOL_FORCE
#endif // ENABLE_POOL_EDIT

//RU --- Для пользователей пулов
| Deposit of MPools.t_ipool * MFarm.t_amount //RU< Депозит в пул //EN< Deposit to pool
| Withdraw of MPools.t_ipool * MFarm.t_amount //RU< Извлечение из пула //EN< Withdraw from pool
| WithdrawAll of MPools.t_ipool //RU< Извлечение всего из пула //EN< Withdraw all from pool

//RU --- От провайдера случайных чисел
| OnRandom of MPools.t_ipool * nat //RU< Случайное число для определения победителя //EN< Random number for detect winner

//RU --- От фермы
| OnReward of MPools.t_ipool * nat //RU< Начисление вознаграждения от фермы //EN< Reward from farm

//RU Единая точка входа контракта
function main(const entrypoint: t_entrypoint; var s: t_storage): t_return is
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
| CreatePool(params) -> (c_NO_OPERATIONS, block { mustAdmin(s); s.pools := MPools.createPool(s.pools, params.0, params.1, params.2); } with s)
| PausePool(params) -> (c_NO_OPERATIONS, block { mustAdmin(s); s.pools := MPools.pausePool(s.pools, params); } with s)
| PlayPool(params) -> (c_NO_OPERATIONS, block { mustAdmin(s); s.pools := MPools.playPool(s.pools, params); } with s)
| RemovePool(params) -> (c_NO_OPERATIONS, block { mustAdmin(s); s.pools := MPools.removePool(s.pools, params); } with s)
#if ENABLE_POOL_FORCE
| ForceRemovePool(params) -> (c_NO_OPERATIONS, block { mustAdmin(s); s.pools := MPools.forceRemovePool(s.pools, params); } with s)
#endif // ENABLE_POOL_FORCE
#if ENABLE_POOL_EDIT
| EditPool(params) -> (c_NO_OPERATIONS, block { mustAdmin(s); s.pools := MPools.editPool(s.pools, params.0, params.1, params.2, params.3); } with s)
#if ENABLE_POOL_FORCE
| ForceEditPool(params) -> (c_NO_OPERATIONS, block { mustAdmin(s); s.pools := MPools.editPool(s.pools, params.0, params.1, params.2, params.3); } with s)//TODO force
#endif // ENABLE_POOL_FORCE
#endif // ENABLE_POOL_EDIT

//RU --- Для пользователей пулов
| Deposit(params) -> (c_NO_OPERATIONS, block { s.pools := MPools.deposit(s.pools, params.0, params.1); } with s)
| Withdraw(params) -> (c_NO_OPERATIONS, block { s.pools := MPools.withdraw(s.pools, params.0, params.1); } with s)
| WithdrawAll(params) -> (c_NO_OPERATIONS, block { s.pools := MPools.withdraw(s.pools, params, 0n); } with s)

//RU --- От провайдера случайных чисел
| OnRandom(params) -> (c_NO_OPERATIONS, block { s.pools := MPools.onRandom(s.pools, params.0, params.1); } with s)

//RU --- От фермы
| OnReward(params) -> (c_NO_OPERATIONS, block { s.pools := MPools.onReward(s.pools, params.0, params.1); } with s)

end

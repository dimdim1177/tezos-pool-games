#include "include/consts.ligo"
#include "CPoolGames/config.ligo"
#include "CPoolGames/storage.ligo"
#include "CPoolGames/access.ligo"

//RU --- Часто используемые в main типы дублируем для читаемости кода

//RU ID пула
type t_ipool is MPools.t_ipool;

//RU Список операций и измененные пулы
type t_lo_rpools is t_operations * MPools.t_rpools;


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
| CreatePool of MPoolOpts.t_opts * MFarm.t_farm * MRandom.t_random * (*burnToken*)option(MToken.t_token) //RU< Создание нового пула //EN< Create new pool
| PausePool of t_ipool //RU< Приостановка пула //EN< Pause pool
| PlayPool of t_ipool //RU< Запуск пула (после паузы) //EN< Play pool (after pause)
| RemovePool of t_ipool //RU< Удаление пула (по окончании партии) //EN< Remove pool (after game)
#if ENABLE_POOL_FORCE
| ForceRemovePool of t_ipool //RU< Принудительное удаление пула сейчас //EN< Force remove pool now
#endif // ENABLE_POOL_FORCE
#if ENABLE_POOL_EDIT
| EditPool of t_ipool * option(MPoolOpts.t_opts) * option(MFarm.t_farm) * option(MRandom.t_random) * (*burnToken*)option(MToken.t_token) //RU< Редактирование пула (приостановленого) //EN< Edit pool (paused)
#if ENABLE_POOL_FORCE
| ForceEditPool of t_ipool * option(MPoolOpts.t_opts) * option(MFarm.t_farm) * option(MRandom.t_random) * (*burnToken*)option(MToken.t_token) //RU< Принудительное редактирование пула //EN< Force edit pool
#endif // ENABLE_POOL_FORCE
#endif // ENABLE_POOL_EDIT

//RU --- Для пользователей пулов
| Deposit of t_ipool * MFarm.t_amount //RU< Депозит в пул //EN< Deposit to pool
| Withdraw of t_ipool * MFarm.t_amount //RU< Извлечение из пула //EN< Withdraw from pool
| WithdrawAll of t_ipool //RU< Извлечение всего из пула //EN< Withdraw all from pool

//RU --- От провайдера случайных чисел
| OnRandom of t_ipool * nat //RU< Случайное число для определения победителя //EN< Random number for detect winner

//RU --- От фермы
| OnReward of t_ipool * nat //RU< Начисление вознаграждения от фермы //EN< Reward from farm

//RU Единая точка входа контракта
function main(const entrypoint: t_entrypoint; var s: t_storage): t_return is
case entrypoint of
//RU --- Управление доступами
#if ENABLE_OWNER //RU Есть владелец контракта
| ChangeOwner(params) -> (c_NO_OPERATIONS, block { s.owner:= MOwner.accessChange(params, s.owner); } with s)
#endif // ENABLE_OWNER
#if ENABLE_ADMIN //RU Есть админ контракта
| ChangeAdmin(params) -> (c_NO_OPERATIONS, block { mustAdmin(s); s.admin := params; } with s)
#endif // ENABLE_ADMIN
#if ENABLE_ADMINS //RU Есть набор админов контракта
| AddAdmin(params) -> (c_NO_OPERATIONS, block { mustAdmin(s); s.admins := MAdmins.forceAdd(params, s.admins); } with s)
| RemAdmin(params) -> (c_NO_OPERATIONS, block { mustAdmin(s); s.admins := MAdmins.forceRem(params, s.admins); } with s)
#endif // ENABLE_ADMINS

//RU --- Управление пулами
| CreatePool(params) -> (c_NO_OPERATIONS, block { mustAdmin(s); s.rpools := MPools.createPool(s.rpools, params.0, params.1, params.2, params.3); } with s)
| PausePool(params) -> (c_NO_OPERATIONS, block { mustAdmin(s); s.rpools := MPools.pausePool(s.rpools, params); } with s)
| PlayPool(params) -> (c_NO_OPERATIONS, block { mustAdmin(s); s.rpools := MPools.playPool(s.rpools, params); } with s)
| RemovePool(params) -> block { mustAdmin(s); const r: t_lo_rpools = MPools.removePool(s.rpools, params); s.rpools := r.1; } with (r.0, s)
#if ENABLE_POOL_FORCE
| ForceRemovePool(params) -> block { mustAdmin(s); const r: t_lo_rpools = MPools.forceRemovePool(s.rpools, params); s.rpools := r.1; } with (r.0, s)
#endif // ENABLE_POOL_FORCE
#if ENABLE_POOL_EDIT
| EditPool(params) -> (c_NO_OPERATIONS, block { mustAdmin(s); s.rpools := MPools.editPool(s.rpools, params.0, params.1, params.2, params.3, params.4); } with s)
#if ENABLE_POOL_FORCE
| ForceEditPool(params) -> (c_NO_OPERATIONS, block { mustAdmin(s); s.rpools := MPools.editPool(s.rpools, params.0, params.1, params.2, params.3, params.4); } with s)//TODO force
#endif // ENABLE_POOL_FORCE
#endif // ENABLE_POOL_EDIT

//RU --- Для пользователей пулов
| Deposit(params) -> block { const r: t_lo_rpools = MPools.deposit(s.rpools, params.0, params.1); s.rpools := r.1; } with (r.0, s)
| Withdraw(params) -> block { const r: t_lo_rpools = MPools.withdraw(s.rpools, params.0, params.1); s.rpools := r.1; } with (r.0, s)
| WithdrawAll(params) -> block { const r: t_lo_rpools = MPools.withdraw(s.rpools, params, 0n); s.rpools := r.1; } with (r.0, s)

//RU --- От провайдера случайных чисел
| OnRandom(params) -> block { const r: t_lo_rpools = MPools.onRandom(s.rpools, params.0, params.1); s.rpools := r.1; } with (r.0, s)

//RU --- От фермы
| OnReward(params) -> block { const r: t_lo_rpools = MPools.onReward(s.rpools, params.0, params.1); s.rpools := r.1; } with (r.0, s)
end;

//RU Получение ID последнего созданного этим адином пула
//RU
//RU Обоснованно полагаем, что с одного адреса не создаются пулы в несколько потоков, поэтому этот метод позволяет получить
//RU ID только что созданного админов нового пула. Если нет созданных админов пулов, будет возвращено -1
[@view] function viewLastIPool(const _: unit; const s: t_storage): int is block {
    mustAdmin(s);
    const ilast: int = MPools.viewLastIPool(s.rpools);
} with ilast;

//RU Получение списка всех пулов в любом состоянии админом
[@view] function viewPoolsFullInfo(const _: unit; const s: t_storage): MPools.t_pools_fullinfo is block {
    mustAdmin(s);
    const pools_fullinfo: MPools.t_pools_fullinfo = MPools.viewPoolsFullInfo(s.rpools);
} with pools_fullinfo;
//RU Получение пула в любом состоянии по его ID админом
[@view] function viewPoolFullInfo(const ipool: t_ipool; const s: t_storage): MPools.t_pool is block {
    mustAdmin(s);
    const pool: MPools.t_pool = MPools.viewPoolFullInfo(s.rpools, ipool);
} with pool;

//RU Получение списка всех активных пулов любым пользователем
[@view] function viewActivePoolsInfo(const _: unit; const s: t_storage): MPools.t_pools_info is MPools.viewPoolsInfo(s.rpools);
//RU Получение активного пула по его ID любым пользователем
[@view] function viewActivePoolInfo(const ipool: t_ipool; const s: t_storage): MPool.t_pool_info is MPools.viewPoolInfo(s.rpools, ipool);

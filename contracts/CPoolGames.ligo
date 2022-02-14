#include "CPoolGames/storage.ligo"
#include "CPoolGames/access.ligo"
#include "CPoolGames/MPools.ligo"

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

//RU --- Управление пулами

| PoolCreate of t_pool_create //RU< Создание нового пула //EN< Create new pool
| PoolPause of t_ipool //RU< Приостановка пула //EN< Pause pool
| PoolPlay of t_ipool //RU< Запуск пула (после паузы) //EN< Play pool (after pause)
| PoolRemove of t_ipool //RU< Удаление пула (по окончании партии) //EN< Remove pool (after game)
| PoolEdit of t_ipool * t_pool_edit //RU< Редактирование пула (приостановленого) //EN< Edit pool (paused)
#if ENABLE_POOL_MANAGER
| PoolChangeManager of t_ipool * address //RU< Смена менеджера (админа одного пула)
#endif // ENABLE_POOL_MANAGER
| PoolGameTime of t_ipool //RU< Закончилась партия розыгрышы в пуле //EN< Complete of pool game

//RU --- Для пользователей пулов
| Deposit of t_ipool * t_amount //RU< Депозит в пул //EN< Deposit to pool
| Withdraw of t_ipool * t_amount //RU< Извлечение из пула //EN< Withdraw from pool
| WithdrawAll of t_ipool //RU< Извлечение всего из пула //EN< Withdraw all from pool

//RU Колбек провайдера случайных чисел
| OnRandom of t_ipool * nat //RU< Случайное число для определения победителя //EN< Random number for detect winner

//RU Колбек самого себя после запроса вознаграждения с фермы 
| AfterReward of t_ipool //RU< Самовызов после запроса вознаграждения от фермы //EN< Call myself after require reward from farm

//RU Колбек самого себя после обмена токенов вознаграждения на токены для сжигания
| AfterChangeReward of t_ipool
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

//RU --- Управление пулами
| PoolCreate(pool_create) -> (cNO_OPERATIONS, block { 
#if !ENABLE_POOL_AS_SERVICE
        mustAdmin(s);
#endif // !ENABLE_POOL_AS_SERVICE
        s := MPools.poolCreate(s, pool_create); 
    } with s)
| PoolPause(ipool) -> (cNO_OPERATIONS, MPools.poolPause(s, ipool) )
| PoolPlay(ipool) -> (cNO_OPERATIONS, MPools.poolPlay(s, ipool) )
| PoolRemove(ipool) -> (cNO_OPERATIONS, MPools.poolRemove(s, ipool) )
| PoolEdit(params) -> (cNO_OPERATIONS, MPools.poolEdit(s, params.0(*ipool*), params.1(*pool_edit*)) )
#if ENABLE_POOL_MANAGER
| PoolChangeManager(params) -> (cNO_OPERATIONS, MPools.poolChangeManager(s, params.0(*ipool*), params.1(*newmanager*)) )
#endif // ENABLE_POOL_MANAGER
| PoolGameTime(ipool) -> MPools.poolGameTime(s, ipool)

//RU --- Для пользователей пулов
| Deposit(params) -> MPools.deposit(s, params.0(*ipool*), params.1(*damount*))
| Withdraw(params) -> MPools.withdraw(s, params.0(*ipool*), params.1(*wamount*))
| WithdrawAll(ipool) -> MPools.withdraw(s, ipool, 0n)

//RU Колбек провайдера случайных чисел
| OnRandom(params) -> MPools.onRandom(s, params.0, params.1)

//RU Колбек самого себя после запроса вознаграждения с фермы 
| AfterReward(ipool) -> MPools.afterReward(s, ipool)

//RU Колбек самого себя после обмена токенов вознаграждения на токены для сжигания
| AfterChangeReward(ipool) -> MPools.afterChangeReward(s, ipool)
end;

#if ENABLE_POOL_LASTIPOOL_VIEW
//RU Получение ID последнего созданного этим админом пула
//RU
//RU Обоснованно полагаем, что с одного адреса не создаются пулы в несколько потоков, поэтому этот метод позволяет получить
//RU ID только что созданного админом нового пула. Если нет созданных админом пулов, будет возвращено -1
[@view] function viewLastIPool(const _: unit; const s: t_storage): int is block {
    mustAdmin(s);
    const ilast: int = MPools.viewLastIPool(s);
} with ilast;
#endif // ENABLE_POOL_LASTIPOOL_VIEW

#if ENABLE_POOL_VIEW
//RU Получение активного пула по его ID любым пользователем
[@view] function viewPoolInfo(const ipool: t_ipool; const s: t_storage): t_pool_info is MPools.viewPoolInfo(s, ipool);
#endif // ENABLE_POOL_VIEW

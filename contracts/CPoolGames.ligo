//RU< Контракт розыгрышей вознаграждения на пулах депозитов в фермы //EN< Contract for reward drawing on pools of deposits to farms

#include "CPoolGames/storage.ligo"
#include "CPoolGames/access.ligo"
#include "CPoolGames/MPools.ligo"

//RU Все точки входа контракта
//EN All entrypoints of contract
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
| CreatePool of t_pool_create //RU< Создание нового пула //EN< Create new pool
| PausePool of t_ipool //RU< Приостановка пула //EN< Pause pool
| StartPool of t_ipool //RU< Запуск пула (после паузы) //EN< Play pool (after pause)
| RemovePool of t_ipool //RU< Удаление пула (по окончании партии) //EN< Remove pool (after game)
| EditPool of t_ipool * t_pool_edit //RU< Редактирование пула (приостановленого) //EN< Edit pool (paused)
#if ENABLE_POOL_MANAGER
| ChangePoolManager of t_ipool * address //RU< Смена менеджера (админа одного пула)
#endif // ENABLE_POOL_MANAGER
| SetPoolGameComplete of t_ipool //RU< Пометить партию завершившейся по времени //EN< Mark pool game complete by time
| GetPoolRandom of t_ipool //RU< Получить случайное число из источника //EN< Get random number from source
| SetPoolWinner of t_ipool * address //RU< Установить победителя партии //EN< Set pool game winner

//RU --- Для пользователей пулов
| Deposit of t_ipool * t_amount //RU< Депозит в пул //EN< Deposit to pool
| Withdraw of t_ipool * t_amount //RU< Извлечение из пула //EN< Withdraw from pool
| WithdrawAll of t_ipool //RU< Извлечение всего из пула //EN< Withdraw all from pool

//RU Колбек со случайным числом для определения победителя //EN Callback with random number for detect winner
| OnRandom of t_iobj_random
//RU Колбек с балансом токена FA1.2 //EN Колбек с балансом токена FA1.2
| OnBalanseFA1_2 of MFA1_2.t_balance_callback_params
//RU Колбек с балансом токена FA2 //EN Колбек с балансом токена FA2
| OnBalanseFA2 of MFA2.t_balance_callback_params

//RU Колбек самого себя после обмена токенов вознаграждения на токены для сжигания
| AfterReward2Tez of t_ipool
;

const cERR_AFTER_DENIED: string = "After/Denied";//RU Метод должен вызываться только самим контрактом

//RU Проверка на самовызов
function mustAfter(const _: unit): unit is block {
    if Tezos.sender = Tezos.self_address then skip
    else failwith(cERR_AFTER_DENIED);
} with unit;

//RU Единая точка входа контракта
function main(const entrypoint: t_entrypoint; var s: t_storage): t_return is
case entrypoint of [
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
| CreatePool(pool_create) -> (cNO_OPERATIONS, block {
#if !ENABLE_POOL_AS_SERVICE
        mustAdmin(s);
#endif // !ENABLE_POOL_AS_SERVICE
        s := MPools.createPool(s, pool_create);
    } with s)
| PausePool(ipool) -> (cNO_OPERATIONS, MPools.pausePool(s, ipool) )
| StartPool(ipool) -> (cNO_OPERATIONS, MPools.startPool(s, ipool) )
| RemovePool(ipool) -> (cNO_OPERATIONS, MPools.removePool(s, ipool) )
| EditPool(params) -> (cNO_OPERATIONS, MPools.editPool(s, params.0(*ipool*), params.1(*pool_edit*)) )
#if ENABLE_POOL_MANAGER
| ChangePoolManager(params) -> (cNO_OPERATIONS, MPools.changePoolManager(s, params.0(*ipool*), params.1(*newmanager*)) )
#endif // ENABLE_POOL_MANAGER
| SetPoolGameComplete(ipool) -> MPools.setPoolGameComplete(s, ipool)
| GetPoolRandom(ipool) -> MPools.getPoolRandom(s, ipool)
| SetPoolWinner(params) -> MPools.setPoolWinner(s, params.0(*ipool*), params.1(*winner*))

//RU --- Для пользователей пулов
| Deposit(params) -> MPools.deposit(s, params.0(*ipool*), params.1(*damount*))
| Withdraw(params) -> MPools.withdraw(s, params.0(*ipool*), params.1(*wamount*))
| WithdrawAll(ipool) -> MPools.withdraw(s, ipool, 0n)

//RU Колбек со случайным числом для определения победителя //EN Callback with random number for detect winner
| OnRandom(params) -> MPools.onRandom(s, params.0, params.1)

//RU Колбек с балансом токена FA1.2 //EN Колбек с балансом токена FA1.2
| OnBalanseFA1_2(params) -> MPools.onBalanceFA1_2(s, params)
//RU Колбек с балансом токена FA2 //EN Колбек с балансом токена FA2
| OnBalanseFA2(params) -> MPools.onBalanceFA2(s, params)

//RU Колбек самого себя после обмена токенов вознаграждения на tez
| AfterReward2Tez(ipool) -> block { mustAfter(unit); const r: t_return = MPools.afterReward2Tez(s, ipool); } with r
];

#if ENABLE_POOL_VIEW
//RU Получение основных настроек пула по его ID любым пользователем
[@view] function viewPoolInfo(const ipool: t_ipool; const s: t_storage): t_pool_info is MPools.viewPoolInfo(s, ipool);
#endif // ENABLE_POOL_VIEW

#if ENABLE_BALANCE_VIEW
//RU Получение баланса пользователя в пуле
[@view] function viewBalance(const ipool: t_ipool; const s: t_storage): nat is MPools.viewBalance(s, ipool);
#endif // ENABLE_BALANCE_VIEW

//RU Недоработки, идеи для развития проекта (TODO)
//RU - подтверждение победителя другими участниками пула (кроме победителя) за небольшое вознаграждение из выигрыша первым N подтвердившим
//RU - выбор участниками токена или XTZ, в котором они хотят получить выигрыш и автоконвертация выигрыша в нужный конкретному пользователю токен
//RU - по флагу, установленному пользователем, автоинвестирование выигранных токенов в тот же пул через автоконвертацию
//RU - получение и вывод менеджерами пула вознаграждения с момента приостановки партий и до извлечения пользователями всех депозитов
//RU - старт розыгрыша при внесении первого депозита в пул

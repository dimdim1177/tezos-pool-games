/// \file
/// \author Dmitrii Dmitriev
/// \date 02.2022
/// \copyright MIT
///RU Контракт периодического розыгрышей вознаграждения на пулах депозитов в фермы
///RU \todo Подтверждение победителя другими участниками пула (кроме победителя) за небольшое вознаграждение из выигрыша первым N подтвердившим
///RU \todo Выбор участниками токена или XTZ, в котором они хотят получить выигрыш и автоконвертация выигрыша в нужный конкретному пользователю токен
///RU \todo По флагу, установленному пользователем, автоинвестирование выигранных токенов в тот же пул через автоконвертацию
///RU \todo Получение и вывод менеджерами пула вознаграждения с момента приостановки партий и до извлечения пользователями всех депозитов
///RU \todo Старт розыгрыша при внесении первого депозита в пул
///EN Contract for periodic reward draws on deposit pools in farms
///EN \todo Confirmation of the winner by other pool participants (except the winner) for a small reward from the winnings of the first N confirmed
///EN \todo The participants' choice of the token or XTZ in which they want to receive the winnings and autoconvert the winnings into the token needed by a particular user
///EN \todo According to the flag set by the user, the auto-investment of the won tokens into the same pool through auto-conversion
///EN \todo Receipt and withdrawal of remuneration by pool managers from the moment of suspension of the parties and until the withdrawal of all deposits by users
///EN \todo The start of the draw when making the first deposit to the pool

#include "CPoolGames/storage.ligo"
#include "CPoolGames/access.ligo"
#include "CPoolGames/MPools.ligo"

///RU Все точки входа контракта
///EN All entrypoints of contract
type t_entrypoint is

//RU --- Управление доступами
//EN --- Access management

#if ENABLE_OWNER
///RU Смена владельца контракта
///EN Change owner of contract
/// \see MOwner, t_storage.owner
| ChangeOwner of MOwner.t_owner
#endif // ENABLE_OWNER

#if ENABLE_ADMIN
///RU Смена админа контракта
///EN Change admin of contract
/// \see MAdmin, t_storage.admin
| ChangeAdmin of MAdmins.t_admin
#endif // ENABLE_ADMIN

#if ENABLE_ADMINS
///RU Добавление админа контракта
///EN Add admin of contract
/// \see MAdmins, t_storage.admins
| AddAdmin of MAdmins.t_admin

///RU Удаление админа контракта
///EN Remove admin of contract
/// \see MAdmins, t_storage.admins
| RemAdmin of MAdmins.t_admin
#endif // ENABLE_ADMINS

//RU --- Управление пулами
//EN --- Pool management

///RU Создание нового пула
///EN Create new pool
| CreatePool of t_pool_create

///RU Приостановка пула
///EN Pause pool
| PausePool of t_ipool

///RU Запуск пула (после паузы)
///EN Play pool (after pause)
| StartPool of t_ipool

///RU Удаление пула (по окончании партии)
///EN Remove pool (after game)
| RemovePool of t_ipool

///RU Редактирование пула (приостановленого)
///EN Edit pool (paused)
| EditPool of t_ipool * t_pool_edit

///RU Пометить партию завершившейся по времени
///EN Mark pool game complete by time
| SetPoolGameComplete of t_ipool

///RU Получить случайное число из источника
///EN< Get random number from source
| GetPoolRandom of t_ipool

///RU Установить победителя партии
///EN Set pool game winner
| SetPoolWinner of t_ipool * address

#if ENABLE_POOL_MANAGER
///RU Смена менеджера (админа одного пула)
///EN Change pool manager (admin of one pool)
| ChangePoolManager of t_ipool * address
#endif // ENABLE_POOL_MANAGER

//RU --- Для участников розыгрышей в пулах
//EN --- For participants of sweepstakes in pools

///RU Депозит в пул
///EN Deposit to pool
| Deposit of t_ipool * MToken.t_amount

///RU Извлечение из пула
///EN Withdraw from pool
| Withdraw of t_ipool * MToken.t_amount

///RU Извлечение всего из пула
///EN Withdraw all from pool
| WithdrawAll of t_ipool

///RU Колбек со случайным числом для определения победителя
///EN Callback with random number for detect winner
| OnRandom of MRandom.t_iobj_random

///RU Колбек с балансом токена FA1.2
///EN Callback with balance of token FA1.2
| OnBalanseFA1_2 of MFA1_2.t_balance_callback_params

///RU Колбек с балансом токена FA2
///EN Callback with balance of token FA2
| OnBalanseFA2 of MFA2.t_balance_callback_params

///RU Колбек самого себя после обмена токенов вознаграждения на токены для сжигания
///EN Colback of himself after exchanging reward tokens for tokens for burning
| AfterReward2Tez of t_ipool
;

///RU Ошибка: Метод должен вызываться только самим контрактом
///EN Error: The method should only be called by the contract itself
const cERR_AFTER_DENIED: string = "After/Denied";

///RU Проверка на самовызов
///EN Checking for self-call
function mustAfter(const _: unit): unit is block {
    if Tezos.sender = Tezos.self_address then skip
    else failwith(cERR_AFTER_DENIED);
} with unit;

///RU Единая точка входа контракта
///EN Single entry point of the contract
function main(const entrypoint: t_entrypoint; var s: t_storage): t_return is
case entrypoint of [

//RU --- Управление доступами
//EN --- Access management

#if ENABLE_OWNER
| ChangeOwner(newowner) -> (cNO_OPERATIONS, block { s.owner:= MOwner.accessChange(newowner, s.owner); } with s)
#endif // ENABLE_OWNER

#if ENABLE_ADMIN
| ChangeAdmin(newadmin) -> (cNO_OPERATIONS, block { mustAdmin(s); s.admin := newadmin; } with s)
#endif // ENABLE_ADMIN

#if ENABLE_ADMINS
| AddAdmin(addadmin) -> (cNO_OPERATIONS, block { mustAdmin(s); s.admins := MAdmins.forceAdd(addadmin, s.admins); } with s)
| RemAdmin(remadmin) -> (cNO_OPERATIONS, block { mustAdmin(s); s.admins := MAdmins.forceRem(remadmin, s.admins); } with s)
#endif // ENABLE_ADMINS

//RU --- Управление пулами
//EN --- Pool management

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
| SetPoolGameComplete(ipool) -> MPools.setPoolGameComplete(s, ipool)
| GetPoolRandom(ipool) -> MPools.getPoolRandom(s, ipool)
| SetPoolWinner(params) -> MPools.setPoolWinner(s, params.0(*ipool*), params.1(*winner*))

#if ENABLE_POOL_MANAGER
| ChangePoolManager(params) -> (cNO_OPERATIONS, MPools.changePoolManager(s, params.0(*ipool*), params.1(*newmanager*)) )
#endif // ENABLE_POOL_MANAGER

//RU --- Для пользователей пулов
//EN --- For pool users

| Deposit(params) -> MPools.deposit(s, params.0(*ipool*), params.1(*damount*))
| Withdraw(params) -> MPools.withdraw(s, params.0(*ipool*), params.1(*wamount*))
| WithdrawAll(ipool) -> MPools.withdraw(s, ipool, 0n)

//RU Колбек со случайным числом для определения победителя
//EN Callback with random number for detect winner
| OnRandom(params) -> MPools.onRandom(s, params.0, params.1)

//RU Колбек с балансом токена FA1.2 //EN Callback with balance of token FA1.2
| OnBalanseFA1_2(params) -> MPools.onBalanceFA1_2(s, params)

//RU Колбек с балансом токена FA2 //EN Callback with balance of token FA2
| OnBalanseFA2(params) -> MPools.onBalanceFA2(s, params)

//RU Колбек самого себя после обмена токенов вознаграждения на tez
//EN Callback of himself after exchanging reward tokens for tez
| AfterReward2Tez(ipool) -> block { mustAfter(unit); const r: t_return = MPools.afterReward2Tez(s, ipool); } with r
];

#if ENABLE_POOL_VIEW
///RU Получение основных настроек пула по его ID любым пользователем
///EN Getting basic pool settings by its ID by any user
/// \see ENABLE_POOL_VIEW
[@view] function viewPoolInfo(const ipool: t_ipool; const s: t_storage): t_pool_info is MPools.viewPoolInfo(s, ipool);
#endif // ENABLE_POOL_VIEW

#if ENABLE_BALANCE_VIEW
///RU Получение баланса пользователя в пуле
///EN Getting the user's balance in the pool
/// \see ENABLE_BALANCE_VIEW
[@view] function viewBalance(const ipool: t_ipool; const s: t_storage): nat is MPools.viewBalance(s, ipool);
#endif // ENABLE_BALANCE_VIEW

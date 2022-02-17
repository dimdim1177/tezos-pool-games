#if !MPOOL_INCLUDED
#define MPOOL_INCLUDED

#include "storage.ligo"
#include "MPoolOpts.ligo"
#include "MPoolStat.ligo"
#include "MPoolGame.ligo"

//RU Модуль пула ликвидности с периодическими розыгрышами вознаграждений
module MPool is {

    const cERR_INVALID_STATE: string = "MPool/InvalidState";//RU< Ошибка: Недопустимое состояние
    const cERR_MUST_SWAPFARM: string = "MPool/MustSwapFarm";//RU< Ошибка: Обязателен адрес контракта для обмена токена фермы
    const cERR_MUST_SWAPBURN: string = "MPool/MustSwapBurn";//RU< Ошибка: Обязателен адрес контракта для обмена токена для сжигания
    const cERR_MUST_BURN: string = "MPool/MustBurn";//RU< Ошибка: Обязателен токен для сжигания
    const cERR_MUST_FEEADDR: string = "MPool/MustFeeAddr";//RU< Ошибка: Обязателен адрес для комиссии
    const cERR_DEPOSIT_INACTIVE: string = "MPool/DepositInactive";//RU< Ошибка: Пул неактивен, внесение депозитов приостановлено
    const cERR_EDIT_ACTIVE: string = "MPool/EditActive";//RU< Ошибка: Пул активен, редактирование возможно только приостановленного пула
    const cERR_OVER_MAX_DEPOSIT: string = "MPool/OverMaxDeposit";//RU< Ошибка: При таком пополнении будет нарушено условие максимального депозита пула
    const cERR_INSUFFICIENT_FUNDS: string = "MPool/InsufficientFunds";//RU< Ошибка: Недостаточно средств для списания
    const cERR_UNDER_MIN_DEPOSIT: string = "MPool/UnderMinDeposit";//RU< Ошибка: При таком списании будет нарушено условие минимального депозита пула

    //RU Активен ли пул
    //RU
    //RU Технически пока партия не приостановлена пул активен, он доступен для просмотра, для внесения
    //RU депозитов и т.п.
    [@inline] function isActive(const pool: t_pool): bool is block {
        const r: bool = (pool.game.state =/= GameStatePause);
    } with r;

    //RU Проверка доступа к пулу
    function mustManager(const s: t_storage; const pool: t_pool):unit is block {
#if ENABLE_POOL_AS_SERVICE
        MManager.mustManager(pool.manager);//RU Если пул-как-сервис, им управляет менеджер пула
#else // ENABLE_POOL_AS_SERVICE

#if ENABLE_POOL_MANAGER
        if isAdmin(s) then skip
        else MManager.mustManager(pool.manager);
#else // ENABLE_POOL_MANAGER
        mustAdmin(s);
#endif // else ENABLE_POOL_MANAGER

#endif // else ENABLE_POOL_AS_SERVICE
    } with unit;

#if ENABLE_POOL_MANAGER
    //RU Безусловная смена менеджера пула (проверка доступа должна быть сделана извне)
    function forceChangeManager(var pool: t_pool; const newmanager: address): t_pool is block {
        pool.manager := MManager.forceChange(pool.manager, newmanager);
    } with pool;
#endif // ENABLE_POOL_MANAGER

    //RU Проверка настроек для сжигания
    function checkBurn(const burn: option(t_token); const swapfarm: option(t_swap); const swapburn: option(t_swap)): unit is block {
        case burn of
        Some(burn) -> MToken.check(burn)
        | None -> failwith(cERR_MUST_BURN)
        end;
        case swapfarm of
        Some(swapfarm) -> MQuipuswap.check(swapfarm)
        | None -> failwith(cERR_MUST_SWAPFARM)
        end;
        case swapburn of
        Some(swapburn) -> MQuipuswap.check(swapburn)
        | None -> failwith(cERR_MUST_SWAPBURN)
        end;
    } with unit;

    //RU Создание нового пула
    function create(const pool_create: t_pool_create): t_pool is block {
        //RU Проверяем все входные параметры
        if PoolStateRemove = pool_create.state then failwith(cERR_INVALID_STATE);
        else skip;
        MPoolOpts.check(pool_create.opts);
        MFarm.check(pool_create.farm);
        MRandom.check(pool_create.randomSource);
        //RU Проверяем настройки для сжигания только если они необходимы
        if MPoolOpts.maybeNoBurn(pool_create.opts) then skip
        else checkBurn(pool_create.burn, pool_create.swapfarm, pool_create.swapburn);
        case pool_create.feeaddr of
        Some(_feeaddr) -> skip
        | None -> block {
            if MPoolOpts.maybeNoFeeAddr(pool_create.opts) then skip
            else failwith(cERR_MUST_FEEADDR);
        }
        end;

    // RU И если все корректно, формируем начальные данные пула
        var gameState: t_game_state := GameStateActive;
        var gameSeconds: nat := pool_create.opts.gameSeconds;
        if PoolStateActive = pool_create.state then skip
        else block {//RU Создание пула в приостановленном состоянии
            gameState := GameStatePause;
            gameSeconds := 0n;
        };
        const pool: t_pool = record [
            opts = pool_create.opts;
            farm = pool_create.farm;
            randomSource = pool_create.randomSource;
            swapfarm = pool_create.swapfarm;
            swapburn = pool_create.swapburn;
            burn = pool_create.burn;
            feeaddr = pool_create.feeaddr;
            state = pool_create.state;
            balance = 1n;
            count = 0n;
            game = MPoolGame.create(gameState, gameSeconds);
            randomFuture = False;
#if ENABLE_POOL_MANAGER
            manager = Tezos.sender;//RU Менеджер пула - его создатель
#endif // ENABLE_POOL_MANAGER
#if ENABLE_POOL_STAT
            stat = MPoolStat.create(unit);
#endif // ENABLE_POOL_STAT
        ];
    } with pool;

//RU --- Управление пулом

    [@inline] function setState(var pool: t_pool; const state: t_pool_state): t_pool is block {
        pool.state := state;
    } with pool;

    function edit(var pool: t_pool; const pool_edit: t_pool_edit): t_pool is block {
        if isActive(pool) then failwith(cERR_EDIT_ACTIVE);
        else skip;
        case pool_edit.opts of
        Some(opts) -> block {
            MPoolOpts.check(opts);
            pool.opts := opts;
        }
        | None -> skip
        end;
        case pool_edit.randomSource of
        Some(randomSource) -> block {
            MRandom.check(randomSource);
            pool.randomSource := randomSource;
        }
        | None -> skip
        end;
        //RU Настройки для сжигания просто пишем, если поданы, проверим потом
        case pool_edit.burn of
        Some(burn) -> pool.burn := Some(burn)
        | None -> skip
        end;
        case pool_edit.swapfarm of
        Some(swapfarm) -> pool.swapfarm := Some(swapfarm)
        | None -> skip
        end;
        case pool_edit.swapburn of
        Some(swapburn) -> pool.swapburn := Some(swapburn)
        | None -> skip
        end;
        //RU Проверяем настройки для сжигания только если они необходимы
        if MPoolOpts.maybeNoBurn(pool.opts) then skip
        else checkBurn(pool.burn, pool.swapfarm, pool.swapburn);
        case pool_edit.feeaddr of
        Some(feeaddr) -> pool.feeaddr := Some(feeaddr)
        | _ -> skip
        end;
    } with pool;

//RU --- Для пользователей пулов

    function deposit(const ipool: t_ipool; var pool: t_pool; var user: t_user; const damount: t_amount; const doapprove: bool): t_pool * t_user * t_operations is block {
        pool := MPoolGame.checkGameComplete(pool);//RU Обработка окончания розыгрыша по времени
        if isActive(pool) then skip else failwith(cERR_DEPOSIT_INACTIVE);
        const newbalance: nat = user.balance + damount;
        //RU Пополнять можно не больше максимального депозита
        if (pool.opts.maxDeposit > 0n) and (newbalance > pool.opts.maxDeposit) then failwith(cERR_OVER_MAX_DEPOSIT)
        else skip;
        if 0n = user.balance then pool.count := pool.count + 1n //RU Добавление нового пользователя в пул
        else skip;
        user.balance := newbalance;
        var operations: t_operations := MFarm.deposit(pool.farm, damount, doapprove);//RU Перечисляем депозит в ферму
        if GameStateActivating = pool.game.state then block {//RU Нужно запустить партию
            const r: t_pool * t_operations = MPoolGame.activateGame(ipool, pool, operations);
            pool := r.0; operations := r.1;
        } else skip;
    } with (pool, user, operations);

    //RU Извлечение из пула
    //RU
    //RU 0n == wamount - извлечение всего депозита из пула
    //EN Withdraw from pool
    //EN
    //EN 0n == wamount - withdraw all deposit from pool
    function withdraw(const ipool: t_ipool; var pool: t_pool; var user: t_user; var wamount: t_amount): t_pool * t_user * t_operations is block {
        pool := MPoolGame.checkGameComplete(pool);//RU Обработка окончания розыгрыша по времени
        if 0n = wamount then wamount := user.balance //RU Списание всего баланса
        else skip;
        const inewbalance: int = user.balance - wamount;
        if inewbalance < 0 then failwith(cERR_INSUFFICIENT_FUNDS)
        else skip;
        const newbalance: nat = abs(inewbalance);
        //RU Списать можно либо все, либо до минимального депозита
        if (newbalance > 0n) and (newbalance < pool.opts.minDeposit) then failwith(cERR_UNDER_MIN_DEPOSIT)
        else skip;
        if 0n = newbalance then pool.count := abs(pool.count - 1n) //RU Удаление пользователя из пула
        else skip;
        user.balance := newbalance;
        var operations: t_operations := MFarm.withdraw(pool.farm, wamount);//RU Извлекаем депозит из фермы
        if GameStateActivating = pool.game.state then block {//RU Нужно запустить партию
            const r: t_pool * t_operations = MPoolGame.activateGame(ipool, pool, operations);
            pool := r.0; operations := r.1;
        } else skip;
    } with (pool, user, operations);

    //RU Колбек провайдера случайных чисел
    function onRandom(const _ipool: t_ipool; var pool: t_pool; const _random: t_random): t_pool is block {
        skip;//TODO
    } with pool;

    //RU Колбек самого себя после запроса вознаграждения с фермы 
    function afterReward(const _ipool: t_ipool; var pool: t_pool): t_pool is block {
        skip;//TODO
    } with pool;

    //RU Колбек самого себя после обмена токенов вознаграждения на токены для сжигания
    function afterChangeReward(const _ipool: t_ipool; var pool: t_pool): t_pool is block {
        skip;//TODO
    } with pool;

}
#endif // !MPOOL_INCLUDED

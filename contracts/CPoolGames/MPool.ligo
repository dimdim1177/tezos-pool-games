#if !MPOOL_INCLUDED
#define MPOOL_INCLUDED

#include "storage.ligo"
#include "MPoolOpts.ligo"
#include "MPoolStat.ligo"
#include "MPoolGame.ligo"
#include "MCallback.ligo"

//RU Модуль пула ликвидности с периодическими розыгрышами вознаграждений
module MPool is {

    const cERR_INVALID_STATE: string = "MPool/InvalidState";//RU< Ошибка: Недопустимое состояние
    const cERR_MUST_REWARD_SWAP: string = "MPool/MustRewardSwap";//RU< Ошибка: Обязателен адрес контракта для обмена токена вознаграждения фермы
    const cERR_MUST_BURN_SWAP: string = "MPool/MustBurnSwap";//RU< Ошибка: Обязателен адрес контракта для обмена токена для сжигания
    const cERR_MUST_BURN_TOKEN: string = "MPool/MustBurnToken";//RU< Ошибка: Обязателен токен для сжигания
    const cERR_MUST_FEEADDR: string = "MPool/MustFeeAddr";//RU< Ошибка: Обязателен адрес для комиссии
    const cERR_DEPOSIT_INACTIVE: string = "MPool/DepositInactive";//RU< Ошибка: Пул неактивен, внесение депозитов приостановлено
    const cERR_EDIT_ACTIVE: string = "MPool/EditActive";//RU< Ошибка: Пул активен, редактирование возможно только приостановленного пула
    const cERR_OVER_MAX_DEPOSIT: string = "MPool/OverMaxDeposit";//RU< Ошибка: При таком пополнении будет нарушено условие максимального депозита пула
    const cERR_INSUFFICIENT_FUNDS: string = "MPool/InsufficientFunds";//RU< Ошибка: Недостаточно средств для списания
    const cERR_UNDER_MIN_DEPOSIT: string = "MPool/UnderMinDeposit";//RU< Ошибка: При таком списании будет нарушено условие минимального депозита пула
    const cERR_LOGIC: string = "MPool/Logic";//RU< Ошибка: Сбой внутренней логики контракта
    const cERR_DENIED: string = "MPool/Denied";//RU< Ошибка: Нет доступа к пулу

    //RU Активен ли пул
    //RU
    //RU Пока партия не приостановлена пул активен, он доступен для просмотра, для внесения депозитов и т.д.
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
    function checkBurn(const rewardToken: t_token; const optburnToken: option(t_token); const optrewardSwap: option(t_swap); const optburnSwap: option(t_swap)): unit is block {
        case optburnToken of [
        | Some(burnToken) -> block {
            MToken.check(burnToken);
            if MToken.isEqual(rewardToken, burnToken) then skip
            else block {
                case optrewardSwap of [
                | Some(rewardSwap) -> MQuipuswap.check(rewardSwap)
                | None -> failwith(cERR_MUST_REWARD_SWAP)
                ];
                case optburnSwap of [
                | Some(burnSwap) -> MQuipuswap.check(burnSwap)
                | None -> failwith(cERR_MUST_BURN_SWAP)
                ];
            };
        }
        | None -> failwith(cERR_MUST_BURN_TOKEN)
        ];
    } with unit;

    //RU Снятие option с адреса для комиссии пула
    function getFeeAddr(const pool: t_pool): address is
        case pool.feeAddr of [
        | Some(feeAddr) -> feeAddr
        | None -> (failwith(cERR_LOGIC): address)
        ];

    //RU Снятие option с адреса фермы Quipuswap для обмена токенов вознаграждения
    function getSwapReward(const pool: t_pool): address is
        case pool.rewardSwap of [
        | Some(rewardSwap) -> rewardSwap
        | None -> (failwith(cERR_LOGIC): address)
        ];

    //RU Снятие option с описания токена для сжигания
    function getBurnToken(const pool: t_pool): t_token is
        case pool.burnToken of [
        | Some(burnToken) -> burnToken
        | None -> (failwith(cERR_LOGIC): t_token)
        ];

    //RU Снятие option с адреса фермы Quipuswap для обмена токенов для сжигания
    function getSwapBurn(const pool: t_pool): address is
        case pool.burnSwap of [
        | Some(burnSwap) -> burnSwap
        | None -> (failwith(cERR_LOGIC): address)
        ];

    //RU Создание нового пула
    function create(const pool_create: t_pool_create): t_pool is block {
        //RU Проверяем все входные параметры
        if PoolStateRemove = pool_create.state then failwith(cERR_INVALID_STATE) else skip;
        MPoolOpts.check(pool_create.opts);
        MFarm.check(pool_create.farm);
        MRandom.check(pool_create.randomSource);
        //RU Проверяем настройки для сжигания только если они необходимы
        if MPoolOpts.maybeNoBurn(pool_create.opts) then skip
        else checkBurn(pool_create.farm.rewardToken, pool_create.burnToken, pool_create.rewardSwap, pool_create.burnSwap);
        case pool_create.feeAddr of [
        | Some(_feeAddr) -> skip
        | None -> block {
            if MPoolOpts.maybeNoFeeAddr(pool_create.opts) then skip
            else failwith(cERR_MUST_FEEADDR);
        }
        ];

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
            rewardSwap = pool_create.rewardSwap;
            burnSwap = pool_create.burnSwap;
            burnToken = pool_create.burnToken;
            feeAddr = pool_create.feeAddr;
            state = pool_create.state;
            balance = 1n;
            count = 0n;
            game = MPoolGame.create(gameState, gameSeconds);
            randomFuture = False;
            beforeHarvestBalance = 0n;
            beforeReward2TezBalance = 0mutez;
            beforeBurnBalance = 0n;
#if ENABLE_POOL_MANAGER
            manager = Tezos.sender;//RU Менеджер пула - его создатель
#endif // ENABLE_POOL_MANAGER
#if ENABLE_POOL_STAT
            stat = MPoolStat.create(unit);
#endif // ENABLE_POOL_STAT
        ];
    } with pool;

//RU --- Управление пулом

    //RU Изменение состояние пула
    [@inline] function setState(var pool: t_pool; const state: t_pool_state): t_pool is block {
        pool.state := state;
    } with pool;

    //RU Редактирование параметров пула
    function edit(var pool: t_pool; const pool_edit: t_pool_edit): t_pool is block {
        if isActive(pool) then failwith(cERR_EDIT_ACTIVE) else skip;
        case pool_edit.opts of [
        | Some(opts) -> block {
            MPoolOpts.check(opts);
            pool.opts := opts;
        }
        | None -> skip
        ];
        case pool_edit.randomSource of [
        | Some(randomSource) -> block {
            MRandom.check(randomSource);
            pool.randomSource := randomSource;
        }
        | None -> skip
        ];
        //RU Настройки для сжигания просто пишем, если поданы, проверим потом
        case pool_edit.burnToken of [
        | Some(burnToken) -> pool.burnToken := Some(burnToken)
        | None -> skip
        ];
        case pool_edit.rewardSwap of [
        | Some(rewardSwap) -> pool.rewardSwap := Some(rewardSwap)
        | None -> skip
        ];
        case pool_edit.burnSwap of [
        | Some(burnSwap) -> pool.burnSwap := Some(burnSwap)
        | None -> skip
        ];
        //RU Проверяем настройки для сжигания только если они необходимы
        if MPoolOpts.maybeNoBurn(pool.opts) then skip
        else checkBurn(pool.farm.rewardToken, pool.burnToken, pool.rewardSwap, pool.burnSwap);
        case pool_edit.feeAddr of [
        | Some(feeAddr) -> pool.feeAddr := Some(feeAddr)
        | _ -> skip
        ];
        case pool_edit.state of [
        | Some(state) -> pool.state := state
        | _ -> skip
        ];
    } with pool;

    //RU Запуск новой партии, если необходимо
    function requestRandomIfNeed(const ipool: t_ipool; var pool: t_pool; var operations: t_operations): t_pool * t_operations is block {
        //RU Если розыгрыш активен, участников больше одного и еще не заказывали случайное число
        if (GameStateActive = pool.game.state) and (pool.count > 1n) and (not pool.randomFuture) then block {
            operations := MRandom.create(pool.randomSource, pool.game.tsEnd, ipool) # operations;//RU Заказываем случайное число
            pool.randomFuture := True;//RU Случайное число заказано
        } else skip;
    } with (pool, operations);

    //RU Запуск новой партии
    function newGame(const ipool: t_ipool; var pool: t_pool; var operations: t_operations): t_pool * t_operations is block {
        pool := MPoolGame.newGame(pool);
        const r: t_pool * t_operations = requestRandomIfNeed(ipool, pool, operations);
    } with (r.0, r.1);

    //RU< Пометить партию завершившейся по времени //EN< Mark pool game complete by time
    function setGameComplete(const ipool: t_ipool; var pool: t_pool): t_pool * t_operations is block {
        pool := MPoolGame.checkComplete(pool);//RU Обработка окончания розыгрыша по времени
        var operations: t_operations := cNO_OPERATIONS;
        if GameStateActivating = pool.game.state then block {//RU Если нет участников, сразу запускаем новую игру
            const r: t_pool * t_operations = newGame(ipool, pool, operations);
            pool := r.0; operations := r.1;
        } else skip;
    } with (pool, operations);

    //RU< Получить случайное число из источника //EN< Get random number from random source
    function getRandom(const ipool: t_ipool; var pool: t_pool): t_pool * t_operations is block {
        if GameStateComplete = pool.game.state then skip
        else failwith(cERR_INVALID_STATE);
        //RU Запрашиваем случайное число колбеком
        const operations: t_operations = list [
            MRandom.get(pool.randomSource, pool.game.tsEnd, ipool, MCallback.onRandomEntrypoint(unit))
        ];
        pool.game.state := GameStateWaitRandom;
    } with (pool, operations);

    //RU< Установить победителя партии //EN< Set pool game winner
    function setPoolWinner(var pool: t_pool; const winner: address): t_pool * t_operations is block {
        pool.game.winner := winner;
        const rewardToken: t_token = pool.farm.rewardToken;
        const cbFA1_2: contract(MFA1_2.t_balance_callback_params) = MCallback.onBalanceFA1_2Entrypoint(unit);
        const cbFA2: contract(MFA2.t_balance_callback_params) = MCallback.onBalanceFA2Entrypoint(unit);
        const operations: t_operations = list [
            MToken.balanceOf(rewardToken, Tezos.self_address, cbFA1_2, cbFA2);
            MFarm.harvest(pool.farm);
            MToken.balanceOf(rewardToken, Tezos.self_address, cbFA1_2, cbFA2)
        ];
    } with (pool, operations);

//RU --- Для пользователей пулов

    function deposit(const ipool: t_ipool; var pool: t_pool; var user: t_user; const damount: t_amount; const doapprove: bool): t_pool * t_user * t_operations is block {
    //RU --- Проверки ограничений
        if isActive(pool) then skip else failwith(cERR_DEPOSIT_INACTIVE);
        const newbalance: nat = user.balance + damount;
        //RU Пополнять можно не больше максимального депозита
        if (pool.opts.maxDeposit > 0n) and (newbalance > pool.opts.maxDeposit) then failwith(cERR_OVER_MAX_DEPOSIT)
        else skip;

        pool := MPoolGame.checkComplete(pool);//RU Обработка окончания розыгрыша по времени

    //RU --- Корректируем веса для розыгрыша по внесенному депозиту
        const pool_user: t_pool * t_user  = MPoolGame.onDeposit(pool, user, damount);
        pool := pool_user.0; user := pool_user.1;

    //RU --- Фиксируем балансы
        if 0n = user.balance then pool.count := pool.count + 1n //RU Добавление нового пользователя в пул
        else skip;
        pool.balance := pool.balance + damount;//RU Новый баланс пула
        user.balance := newbalance;//RU Новый баланс пользователя
        user.tsBalance := Tezos.now;//RU Когда он был изменен

        const operations: t_operations = MFarm.deposit(pool.farm, damount, doapprove);//RU Перечисляем депозит в ферму

    //RU Если появилось больше 2 участников, нужно заказать случайное число для розыгрыша
        const r: t_pool * t_operations = requestRandomIfNeed(ipool, pool, operations);

    } with (r.0, user, r.1);

    //RU Извлечение из пула
    //RU
    //RU 0n == wamount - извлечение всего депозита из пула
    //EN Withdraw from pool
    //EN
    //EN 0n == wamount - withdraw all deposit from pool
    function withdraw(const _ipool: t_ipool; var pool: t_pool; var user: t_user; var wamount: t_amount): t_pool * t_user * t_operations is block {
        //RU При wamount=0 списание всего баланса
        if 0n = wamount then wamount := user.balance else skip;

    //RU --- Проверки ограничений
        const inewbalance: int = user.balance - wamount;
        if inewbalance < 0 then failwith(cERR_INSUFFICIENT_FUNDS)
        else block {
            //RU Списать можно либо все, либо до минимального депозита
            if (inewbalance > 0) and (inewbalance < int(pool.opts.minDeposit)) then failwith(cERR_UNDER_MIN_DEPOSIT)
            else skip;
        };

        pool := MPoolGame.checkComplete(pool);//RU Обработка окончания розыгрыша по времени

    //RU --- Корректируем веса для розыгрыша по извлеченному депозиту
        const pool_user: t_pool * t_user  = MPoolGame.onWithdraw(pool, user, wamount);
        pool := pool_user.0; user := pool_user.1;

    //RU --- Фиксируем балансы
        const newbalance: nat = abs(inewbalance);
        if 0n = newbalance then pool.count := abs(pool.count - 1n) //RU Удаление пользователя из пула
        else skip;
        pool.balance := abs(pool.balance - wamount);
        user.balance := newbalance;
        user.tsBalance := Tezos.now;

        const operations: t_operations = MFarm.withdraw(pool.farm, wamount);//RU Извлекаем депозит из фермы
    } with (pool, user, operations);

    //RU Колбек провайдера случайных чисел
    function onRandom(const _ipool: t_ipool; var pool: t_pool; const random: t_random): t_pool is block {
        if GameStateWaitRandom = pool.game.state then skip
        else failwith(cERR_INVALID_STATE);
        //RU Вес победителя должен быть больше 0, иначе могут быть отобраны участники весом 0,
        //RU то есть, не участвующие в текущем розыгрыше
        pool.game.winWeight := (random mod pool.game.weight) + 1n;
        pool.game.state := GameStateWaitWinner;
    } with pool;

    //RU Получен баланс токенов вознаграждения до получения вознаграждения
    function onBalanceBeforeHarvest(var pool: t_pool; const currentBalance: t_amount): t_pool is block {
        if Tezos.sender = pool.farm.rewardToken.addr then skip
        else failwith(cERR_DENIED);
        pool.beforeHarvestBalance := currentBalance;
    } with pool;

    //RU Получен баланс токенов вознаграждения после получения вознаграждения
    function onBalanceAfterHarvest(const ipool: t_ipool; var pool: t_pool; const currentBalance: t_amount): t_pool * t_operations is block {
        if Tezos.sender = pool.farm.rewardToken.addr then skip
        else failwith(cERR_DENIED);
        var operations: t_operations := cNO_OPERATIONS;
        const ifullReward: int = currentBalance - pool.beforeHarvestBalance;//RU< Полученное из фермы вознаграждение
        if ifullReward < 0 then failwith(cERR_LOGIC) else skip;//RU Отрицательное вознаграждение
        const fullReward: t_amount = abs(ifullReward);
        //RU Если есть комиссия, перечисляем ее
        const fee: t_amount = (fullReward * pool.opts.feePercent) / 100n;
        if fee > 0n then operations := MToken.transfer(pool.farm.rewardToken, Tezos.self_address, getFeeAddr(pool), fee) # operations
        else skip;
        const burn: t_amount = (fullReward * pool.opts.burnPercent) / 100n;
        const reward: t_amount = abs(fullReward - fee - burn);//RU Оставшиеся токены с копейками в вознаграждение
        //RU Перечисляем вознаграждение победителю
        if reward > 0n then operations := MToken.transfer(pool.farm.rewardToken, Tezos.self_address, pool.game.winner, fee) # operations
        else skip;
#if ENABLE_POOL_STAT
        pool := MPoolStat.onWin(pool, pool.game.winner, reward);
#endif // ENABLE_POOL_STAT
        //RU Если нужно сжигать другие токены
        if burn > 0n then block {
            const burnToken: t_token = getBurnToken(pool);
            const rewardToken: t_token = pool.farm.rewardToken;
            //RU Если токены вознаграждения и сжигания совпадают, сжигаем их сразу
            if MToken.isEqual(burnToken, rewardToken) then block {
                operations := MToken.burn(burnToken, Tezos.self_address, burn) # operations;
                //RU Все действия по выигрышу выполнены, активируем новый розыгрыш
                const r: t_pool * t_operations = newGame(ipool, pool, operations);
                pool := r.0; operations := r.1;
            } else block {//RU Токены вознаграждения и для сжигания не совпадают, нужно их обменять через tez
                pool.beforeReward2TezBalance := Tezos.balance + Tezos.amount;
                operations := MCallback.opAfterReward2Tez(ipool) # operations;
                operations := MQuipuswap.token2tez(getSwapReward(pool), burn, 1n, Tezos.self_address) # operations;
            };
        } else skip;
    } with (pool, operations);

    //RU Колбек самого себя после обмена токенов вознаграждения на tez
    function afterReward2Tez(const ipool: t_ipool; var pool: t_pool): t_pool * t_operations is block {
        const currentTez: tez = Tezos.balance + Tezos.amount;
        if currentTez < pool.beforeReward2TezBalance then failwith(cERR_LOGIC) else skip;
        const changedTez: tez = currentTez - pool.beforeReward2TezBalance;
        var operations: t_operations := cNO_OPERATIONS;
        if changedTez > 0mutez then block {//RU Если получили при конвертации хоть сколько-то tez
            const burnToken: t_token = getBurnToken(pool);
            const cbFA1_2: contract(MFA1_2.t_balance_callback_params) = MCallback.onBalanceFA1_2Entrypoint(unit);
            const cbFA2: contract(MFA2.t_balance_callback_params) = MCallback.onBalanceFA2Entrypoint(unit);
            operations := list [
                MToken.balanceOf(burnToken, Tezos.self_address, cbFA1_2, cbFA2);
                MQuipuswap.tez2token(getSwapBurn(pool), changedTez, 1n, Tezos.self_address);
                MToken.balanceOf(burnToken, Tezos.self_address, cbFA1_2, cbFA2)
            ];
        } else block {//RU Не получили Tez
            //RU Все действия по выигрышу выполнены, активируем новый розыгрыш
            const r: t_pool * t_operations = newGame(ipool, pool, operations);
            pool := r.0; operations := r.1;
        };
    } with (pool, operations);

    //RU Получен баланс токенов для сжигания до обмена tez на них
    function onBalanceBeforeTez2Burn(var pool: t_pool; const currentBalance: t_amount): t_pool is block {
        const burnToken: t_token = getBurnToken(pool);
        if Tezos.sender = burnToken.addr then skip
        else failwith(cERR_DENIED);
        pool.beforeBurnBalance := currentBalance;
    } with pool;

    //RU Получен баланс токенов для сжигания после обмена tez на них
    function onBalanceAfterTez2Burn(const ipool: t_ipool; var pool: t_pool; const currentBalance: t_amount): t_pool * t_operations is block {
        const burnToken: t_token = getBurnToken(pool);
        if Tezos.sender = burnToken.addr then skip
        else failwith(cERR_DENIED);
        const iburn: int = currentBalance - pool.beforeBurnBalance;//RU< Полученные токены для сжигания
        if iburn < 0 then failwith(cERR_LOGIC) else skip;//RU Отрицательное кол-во
        const burn: t_amount = abs(iburn);
        var operations: t_operations := cNO_OPERATIONS;
        operations := MToken.burn(burnToken, Tezos.self_address, burn) # operations;// RU Сжигаем токены
        //RU Все действия по выигрышу выполнены, активируем новый розыгрыш
        const r: t_pool * t_operations = newGame(ipool, pool, operations);
        pool := r.0; operations := r.1;
    } with (pool, operations);
}
#endif // !MPOOL_INCLUDED

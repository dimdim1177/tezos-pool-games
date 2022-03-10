#if !MPOOL_INCLUDED
#define MPOOL_INCLUDED

#include "storage.ligo"
#include "MPoolOpts.ligo"
#include "MPoolStat.ligo"
#include "MPoolGame.ligo"
#include "MCallback.ligo"

///RU Модуль пула ликвидности с периодическими розыгрышами вознаграждений
///EN The module of the liquidity pool with periodic raffles of rewards
module MPool is {

    ///RU Ошибка: Недопустимое состояние
    ///EN Error: Invalid state
    const cERR_INVALID_STATE: string = "MPool/InvalidState";

    ///RU Ошибка: Обязателен адрес контракта для обмена токена вознаграждения фермы
    ///EN Error: The contract address is required for the exchange of the farm reward token
    const cERR_MUST_REWARD_SWAP: string = "MPool/MustRewardSwap";

    ///RU Ошибка: Обязателен адрес контракта для обмена токена для сжигания
    ///EN Error: Required contract address for token exchange for burning
    const cERR_MUST_BURN_SWAP: string = "MPool/MustBurnSwap";

    ///RU Ошибка: Обязателен токен для сжигания
    ///EN Error: Required token for burning
    const cERR_MUST_BURN_TOKEN: string = "MPool/MustBurnToken";

    ///RU Ошибка: Обязателен адрес для комиссии
    ///EN Error: Required address for commission
    const cERR_MUST_FEEADDR: string = "MPool/MustFeeAddr";

    ///RU Ошибка: Пул неактивен, внесение депозитов приостановлено
    ///EN Error: The pool is inactive, deposits are suspended
    const cERR_DEPOSIT_INACTIVE: string = "MPool/DepositInactive";

    ///RU Ошибка: Пул активен, редактирование возможно только приостановленного пула
    ///EN Error: The pool is active, editing is only possible for the suspended pool
    const cERR_EDIT_ACTIVE: string = "MPool/EditActive";

    ///RU Ошибка: При таком пополнении будет нарушено условие максимального депозита пула
    ///EN Error: With such a deposit, the condition of the maximum deposit of the pool will be violated
    const cERR_OVER_MAX_DEPOSIT: string = "MPool/OverMaxDeposit";

    ///RU Ошибка: Недостаточно средств для списания
    ///EN Error: Insufficient funds for debiting
    const cERR_INSUFFICIENT_FUNDS: string = "MPool/InsufficientFunds";

    ///RU Ошибка: При таком списании будет нарушено условие минимального депозита пула
    ///EN Error: With such a write-off, the condition of the minimum deposit of the pool will be violated
    const cERR_UNDER_MIN_DEPOSIT: string = "MPool/UnderMinDeposit";

    ///RU Ошибка: Сбой внутренней логики контракта
    ///EN Error: Failure of the internal logic of the contract
    const cERR_LOGIC: string = "MPool/Logic";

    ///RU Ошибка: Нет доступа к пулу
    ///EN Error: There is no access to the pool
    const cERR_DENIED: string = "MPool/Denied";

    ///RU Активен ли пул
    ///RU
    ///RU Пока партия не приостановлена пул активен, он доступен для просмотра, для внесения депозитов и т.д.
    ///EN Is the pool active
    ///EN
    ///EN While the game is not suspended, the pool is active, it is available for viewing, for making deposits, etc.
    [@inline] function isActive(const pool: t_pool): bool is (pool.game.state =/= GameStatePause);

    ///RU Проверка доступа к пулу
    ///EN Checking access to the pool
    function mustManager(const s: t_storage; const pool: t_pool):unit is block {
#if ENABLE_POOL_AS_SERVICE
        const _ = s;//RU Чтобы избавиться от предупреждения LIGO //EN For hide LIGO warning

        //RU Если пул-как-сервис, им управляет менеджер пула
        //EN If the pool is a service, it is managed by the pool manager
        MManager.mustManager(pool.manager);
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
    ///RU Безусловная смена менеджера пула (проверка доступа должна быть сделана извне)
    ///EN Unconditional change of the pool manager (access check must be done from the outside)
    function forceChangeManager(var pool: t_pool; const newmanager: address): t_pool is block {
        pool.manager := newmanager;
    } with pool;
#endif // ENABLE_POOL_MANAGER

    ///RU Проверка настроек для сжигания
    ///EN Checking the settings for burning
    function checkBurn(const rewardToken: MToken.t_token; const optburnToken: option(MToken.t_token); const optrewardSwap: option(MQuipuswap.t_swap); const optburnSwap: option(MQuipuswap.t_swap)): unit is block {
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

    ///RU Снятие option с адреса для комиссии пула
    ///EN Withdrawal of option from the address for the pool commission
    function getFeeAddr(const pool: t_pool): address is
        case pool.feeAddr of [
        | Some(feeAddr) -> feeAddr
        | None -> (failwith(cERR_LOGIC): address)
        ];

    ///RU Снятие option с адреса фермы Quipuswap для обмена токенов вознаграждения
    ///EN Withdrawal of option from the Quipuswap farm address for the exchange of reward tokens
    function getSwapReward(const pool: t_pool): address is
        case pool.rewardSwap of [
        | Some(rewardSwap) -> rewardSwap
        | None -> (failwith(cERR_LOGIC): address)
        ];

    ///RU Снятие option с описания токена для сжигания
    ///EN Removing option from the description of the token for burning
    function getBurnToken(const pool: t_pool): MToken.t_token is
        case pool.burnToken of [
        | Some(burnToken) -> burnToken
        | None -> (failwith(cERR_LOGIC): MToken.t_token)
        ];

    ///RU Снятие option с адреса фермы Quipuswap для обмена токенов для сжигания
    ///EN Removing the option from the Quipuswap farm address to exchange tokens for burning
    function getSwapBurn(const pool: t_pool): address is
        case pool.burnSwap of [
        | Some(burnSwap) -> burnSwap
        | None -> (failwith(cERR_LOGIC): address)
        ];

    ///RU Создание нового пула
    ///EN Creating a new pool
    function create(const pool_create: t_pool_create): t_pool is block {
        //RU Проверяем все входные параметры
        //EN Check all input parameters
        if PoolStateRemove = pool_create.state then failwith(cERR_INVALID_STATE) else skip;
        MPoolOpts.check(pool_create.opts);
        MFarm.check(pool_create.farm);
        MRandom.check(pool_create.randomSource);
        //RU Проверяем настройки для сжигания только если они необходимы
        //EN We check the settings for burning only if they are necessary
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
        else block {//RU Создание пула в приостановленном состоянии //EN Creating a pool in a suspended state
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
            balance = 0n;
            count = 0n;
            game = MPoolGame.create(gameState, gameSeconds);
            randomFuture = False;
            beforeHarvestBalance = 0n;
            beforeReward2TezBalance = 0mutez;
            beforeBurnBalance = 0n;
#if ENABLE_POOL_MANAGER
            manager = Tezos.sender;//RU Менеджер пула - его создатель //EN The pool manager is its creator
#endif // ENABLE_POOL_MANAGER
#if ENABLE_POOL_STAT
            stat = MPoolStat.create(unit);
#endif // ENABLE_POOL_STAT
        ];
    } with pool;

//RU --- Управление пулом
//EN --- Pool management

    ///RU Изменение состояние пула
    ///EN Changing the pool state
    [@inline] function setState(var pool: t_pool; const state: t_pool_state): t_pool is block {
        pool.state := state;
    } with pool;

    ///RU Редактирование параметров пула
    ///EN Editing Pool parameters
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
        //EN The settings for burning are simply written, if submitted, we will check later
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
        //EN We check the settings for burning only if they are necessary
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

    ///RU Запуск новой партии, если необходимо
    ///EN Starting a new game, if necessary
    function requestRandomIfNeed(const ipool: t_ipool; var pool: t_pool; var operations: t_operations): t_pool * t_operations is block {
        //RU Если розыгрыш активен, участников больше одного и еще не заказывали случайное число
        //EN If the draw is active, there are more than one participants and no random number has been ordered yet
        if (GameStateActive = pool.game.state) and (pool.count > 1n) and (not pool.randomFuture) then block {
            //RU Запрашиваем случайное число
            //EN Requesting a random number
            operations := MRandom.create(pool.randomSource, pool.game.tsEnd, ipool) # operations;
            pool.randomFuture := True;//RU Случайное число запрошено //EN Random number requested
        } else skip;
    } with (pool, operations);

    ///RU Запуск новой партии
    ///EN Launching a new game
    function newGame(const ipool: t_ipool; var pool: t_pool; var operations: t_operations): t_pool * t_operations is block {
        pool := MPoolGame.newGame(pool);
        const r: t_pool * t_operations = requestRandomIfNeed(ipool, pool, operations);
    } with (r.0, r.1);

    ///RU Пометить партию завершившейся по времени
    ///EN Mark pool game complete by time
    function setGameComplete(const ipool: t_ipool; var pool: t_pool): t_pool * t_operations is block {
        //RU Обработка окончания розыгрыша по времени
        //EN Processing the end of the draw by time
        pool := MPoolGame.checkComplete(pool);
        var operations: t_operations := cNO_OPERATIONS;
        if GameStateActivating = pool.game.state then block {
            //RU Если нет участников, сразу запускаем новую игру
            //EN If there are no participants, we immediately launch a new game
            const r: t_pool * t_operations = newGame(ipool, pool, operations);
            pool := r.0; operations := r.1;
        } else skip;
    } with (pool, operations);

    ///RU Получить случайное число из источника
    ///EN Get random number from random source
    function getRandom(const ipool: t_ipool; var pool: t_pool): t_pool * t_operations is block {
        if GameStateComplete = pool.game.state then skip
        else failwith(cERR_INVALID_STATE);
        //RU Запрашиваем случайное число колбеком
        //EN Requesting a random number with a callback
        const operations = list [
            MRandom.get(pool.randomSource, pool.game.tsEnd, ipool, MCallback.onRandomEntrypoint(unit))
        ];
        pool.game.state := GameStateWaitRandom;
    } with (pool, operations);

    ///RU Установить победителя партии
    ///EN Set pool game winner
    function setPoolWinner(var pool: t_pool; const winner: address): t_pool * t_operations is block {
        pool.game.winner := winner;
        const rewardToken = pool.farm.rewardToken;
        const cbFA1_2 = MCallback.onBalanceFA1_2Entrypoint(unit);
        const cbFA2 = MCallback.onBalanceFA2Entrypoint(unit);
        const operations = list [
            MToken.balanceOf(rewardToken, Tezos.self_address, cbFA1_2, cbFA2);
            MFarm.harvest(pool.farm);
            MToken.balanceOf(rewardToken, Tezos.self_address, cbFA1_2, cbFA2)
        ];
    } with (pool, operations);

//RU --- Для пользователей пулов
//EN --- For pool users

    ///RU Внесение депозита в пул
    ///EN Making a deposit to the pool
    function deposit(const ipool: t_ipool; var pool: t_pool; var user: t_user; const damount: MToken.t_amount; const doapprove: bool): t_pool * t_user * t_operations is block {
    //RU --- Проверки ограничений
    //EN --- Checking restrictions
        if isActive(pool) then skip else failwith(cERR_DEPOSIT_INACTIVE);
        const newbalance = user.balance + damount;
        //RU Пополнять можно не больше максимального депозита
        //EN You can top up no more than the maximum deposit
        if (pool.opts.maxDeposit > 0n) and (newbalance > pool.opts.maxDeposit) then failwith(cERR_OVER_MAX_DEPOSIT)
        else skip;

        pool := MPoolGame.checkComplete(pool);//RU Обработка окончания розыгрыша по времени //EN Processing the end of the draw by time

    //RU --- Корректируем веса для розыгрыша по внесенному депозиту
    //EN --- We adjust the weights for the draw on the deposited deposit
        const pool_user: t_pool * t_user  = MPoolGame.onDeposit(pool, user, damount);
        pool := pool_user.0; user := pool_user.1;

    //RU --- Фиксируем балансы
        //RU Добавление нового пользователя в пул
    //EN --- Fixing balances
    //EN Adding a new user to the pool
        if 0n = user.balance then pool.count := pool.count + 1n
        else skip;
        pool.balance := pool.balance + damount;//RU Новый баланс пула //EN New pool balance
        user.balance := newbalance;//RU Новый баланс пользователя //EN New user balance
        user.tsBalance := Tezos.now;//RU Когда он был изменен //EN When it was changed

        const operations = MFarm.deposit(pool.farm, damount, doapprove);//RU Перечисляем депозит в ферму //EN We transfer the deposit to the farm

    ///RU Если появилось больше 2 участников, нужно заказать случайное число для розыгрыша
    ///EN If there are more than 2 participants, you need to order a random number for the draw
        const r: t_pool * t_operations = requestRandomIfNeed(ipool, pool, operations);

    } with (r.0, user, r.1);

    ///RU Извлечение из пула
    ///RU
    ///RU 0n == wamount - извлечение всего депозита из пула
    ///EN Withdraw from pool
    ///EN
    ///EN 0n == wamount - withdraw all deposit from pool
    function withdraw(const _ipool: t_ipool; var pool: t_pool; var user: t_user; var wamount: MToken.t_amount): t_pool * t_user * t_operations is block {
        //RU При wamount=0 списание всего баланса
        //EN When wamount=0, the entire balance is debited
        if 0n = wamount then wamount := user.balance else skip;

    //RU --- Проверки ограничений
    //EN --- Checking restrictions
        const inewbalance = user.balance - wamount;
        if inewbalance < 0 then failwith(cERR_INSUFFICIENT_FUNDS)
        else block {
            //RU Списать можно либо все, либо до минимального депозита
            //EN You can write off either everything or up to the minimum deposit
            if (inewbalance > 0) and (inewbalance < int(pool.opts.minDeposit)) then failwith(cERR_UNDER_MIN_DEPOSIT)
            else skip;
        };

        pool := MPoolGame.checkComplete(pool);//RU Обработка окончания розыгрыша по времени //EN Processing the end of the draw by time

    //RU --- Корректируем веса для розыгрыша по извлеченному депозиту
    //EN --- We adjust the weights for the draw on the extracted deposit
        const pool_user: t_pool * t_user  = MPoolGame.onWithdraw(pool, user, wamount);
        pool := pool_user.0; user := pool_user.1;

    //RU --- Фиксируем балансы
    //EN --- Fixing balances
        const newbalance = abs(inewbalance);
        //RU Удаление пользователя из пула
        //EN Removing a user from the pool
        if 0n = newbalance then pool.count := abs(pool.count - 1n)
        else skip;
        pool.balance := abs(pool.balance - wamount);
        user.balance := newbalance;
        user.tsBalance := Tezos.now;
        //RU Извлекаем депозит из фермы
        //EN We extract the deposit from the farm
        const operations = MFarm.withdraw(pool.farm, wamount);
    } with (pool, user, operations);

    ///RU Колбек провайдера случайных чисел
    ///EN Callback of a random number provider
    function onRandom(const _ipool: t_ipool; var pool: t_pool; const random: MRandom.t_random): t_pool is block {
        if GameStateWaitRandom = pool.game.state then skip
        else failwith(cERR_INVALID_STATE);
        //RU Вес победителя должен быть больше 0, иначе могут быть отобраны участники весом 0,
        //RU то есть, не участвующие в текущем розыгрыше
        //EN The winner's weight must be greater than 0, otherwise participants weighing 0 may be selected,
        //EN that is, not participating in the current draw
        pool.game.winWeight := (random mod pool.game.weight) + 1n;
        pool.game.state := GameStateWaitWinner;
    } with pool;

    ///RU Получен баланс токенов вознаграждения до получения вознаграждения
    ///EN The balance of reward tokens was received before receiving the reward
    function onBalanceBeforeHarvest(var pool: t_pool; const currentBalance: MToken.t_amount): t_pool is block {
        if Tezos.sender = pool.farm.rewardToken.addr then skip
        else failwith(cERR_DENIED);
        pool.beforeHarvestBalance := currentBalance;
    } with pool;

    ///RU Получен баланс токенов вознаграждения после получения вознаграждения
    ///EN The balance of reward tokens was received after receiving the reward
    function onBalanceAfterHarvest(const ipool: t_ipool; var pool: t_pool; const currentBalance: MToken.t_amount): t_pool * t_operations is block {
        if Tezos.sender = pool.farm.rewardToken.addr then skip
        else failwith(cERR_DENIED);
        var operations: t_operations := cNO_OPERATIONS;
        //RU Полученное из фермы вознаграждение
        //EN The reward received from the farm
        const ifullReward = currentBalance - pool.beforeHarvestBalance;
        if ifullReward < 0 then failwith(cERR_LOGIC) else skip;//RU Отрицательное вознаграждение //EN Negative remuneration
        const fullReward = abs(ifullReward);
        //RU Если есть комиссия, перечисляем ее
        //EN If there is a commission, we list it
        const fee = (fullReward * pool.opts.feePercent) / 100n;
        if fee > 0n then operations := MToken.transfer(pool.farm.rewardToken, Tezos.self_address, getFeeAddr(pool), fee) # operations
        else skip;
        const burn = (fullReward * pool.opts.burnPercent) / 100n;
        //RU Оставшиеся токены с копейками в вознаграждение
        //EN The remaining tokens with pennies in the reward
        const reward = abs(fullReward - fee - burn);
        //RU Перечисляем вознаграждение победителю
        //EN We transfer the reward to the winner
        if reward > 0n then operations := MToken.transfer(pool.farm.rewardToken, Tezos.self_address, pool.game.winner, fee) # operations
        else skip;
#if ENABLE_POOL_STAT
        pool := MPoolStat.onWin(pool, pool.game.winner, reward);
#endif // ENABLE_POOL_STAT
        //RU Если нужно сжигать другие токены
        //EN If you need to burn other tokens
        if burn > 0n then block {
            const burnToken = getBurnToken(pool);
            const rewardToken = pool.farm.rewardToken;
            //RU Если токены вознаграждения и сжигания совпадают, сжигаем их сразу
            //EN If the reward and burning tokens match, we burn them immediately
            if MToken.isEqual(burnToken, rewardToken) then block {
                operations := MToken.burn(burnToken, Tezos.self_address, burn) # operations;
                //RU Все действия по выигрышу выполнены, активируем новый розыгрыш
                //EN All the winning actions have been completed, we activate a new draw
                const r: t_pool * t_operations = newGame(ipool, pool, operations);
                pool := r.0; operations := r.1;
            } else block {
                //RU Токены вознаграждения и для сжигания не совпадают, нужно их обменять через tez
                //EN Reward tokens and for burning do not match, you need to exchange them through tez
                pool.beforeReward2TezBalance := Tezos.balance + Tezos.amount;
                operations := MCallback.opAfterReward2Tez(ipool) # operations;
                operations := MQuipuswap.token2tez(getSwapReward(pool), burn, 1n, Tezos.self_address) # operations;
            };
        } else skip;
    } with (pool, operations);

    ///RU Колбек самого себя после обмена токенов вознаграждения на tez
    ///EN Callback of himself after exchanging reward tokens for tez
    function afterReward2Tez(const ipool: t_ipool; var pool: t_pool): t_pool * t_operations is block {
        const currentTez = Tezos.balance + Tezos.amount;
        if currentTez < pool.beforeReward2TezBalance then failwith(cERR_LOGIC) else skip;
        const changedTez = currentTez - pool.beforeReward2TezBalance;
        var operations: t_operations := cNO_OPERATIONS;
        if changedTez > 0mutez then block {
            //RU Если получили при конвертации хоть сколько-то tez
            //EN If you received at least some tez during the conversion
            const burnToken = getBurnToken(pool);
            const cbFA1_2 = MCallback.onBalanceFA1_2Entrypoint(unit);
            const cbFA2 = MCallback.onBalanceFA2Entrypoint(unit);
            operations := list [
                MToken.balanceOf(burnToken, Tezos.self_address, cbFA1_2, cbFA2);
                MQuipuswap.tez2token(getSwapBurn(pool), changedTez, 1n, Tezos.self_address);
                MToken.balanceOf(burnToken, Tezos.self_address, cbFA1_2, cbFA2)
            ];
        } else block {
            //RU Не получили Tez
            //RU Все действия по выигрышу выполнены, активируем новый розыгрыш
            //EN Did not receive Tez
            //EN All the winning actions have been completed, we activate a new draw
            const r: t_pool * t_operations = newGame(ipool, pool, operations);
            pool := r.0; operations := r.1;
        };
    } with (pool, operations);

    ///RU Получен баланс токенов для сжигания до обмена tez на них
    ///EN Received a balance of tokens for burning before exchanging tez for them
    function onBalanceBeforeTez2Burn(var pool: t_pool; const currentBalance: MToken.t_amount): t_pool is block {
        const burnToken = getBurnToken(pool);
        if Tezos.sender = burnToken.addr then skip
        else failwith(cERR_DENIED);
        pool.beforeBurnBalance := currentBalance;
    } with pool;

    ///RU Получен баланс токенов для сжигания после обмена tez на них
    ///EN The balance of tokens for burning was obtained after the exchange of tez for them
    function onBalanceAfterTez2Burn(const ipool: t_ipool; var pool: t_pool; const currentBalance: MToken.t_amount): t_pool * t_operations is block {
        const burnToken = getBurnToken(pool);
        if Tezos.sender = burnToken.addr then skip
        else failwith(cERR_DENIED);
        //RU Полученные токены для сжигания
        //EN Received tokens for burning
        const iburn = currentBalance - pool.beforeBurnBalance;
        if iburn < 0 then failwith(cERR_LOGIC) else skip;//RU Отрицательное кол-во //EN Negative quantity
        const burn = abs(iburn);
        var operations: t_operations := cNO_OPERATIONS;
        operations := MToken.burn(burnToken, Tezos.self_address, burn) # operations;// RU Сжигаем токены
        ///RU Все действия по выигрышу выполнены, активируем новый розыгрыш
        ///EN All the winning actions have been completed, we activate a new draw
        const r: t_pool * t_operations = newGame(ipool, pool, operations);
        pool := r.0; operations := r.1;
    } with (pool, operations);

}
#endif // !MPOOL_INCLUDED

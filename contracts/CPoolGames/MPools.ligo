#if !MPOOLS_INCLUDED
#define MPOOLS_INCLUDED

#include "MPool.ligo"
#include "MUsers.ligo"

//RU Модуль списка пулов ликвидности с периодическими розыгрышами вознаграждений
module MPools is {

    type t_ipool is nat;//RU< Индекс пула

    //RU Список пулов
    type t_pools is [@layout:comb] record [
        ibeg: t_ipool;//RU< Начальный индекс пулов
        iend: t_ipool;//RU< Следующий за максимальным индекс пулов
        count: t_ipool;//RU Кол-во пулов
        pools: big_map(t_ipool, MPool.t_pool);//RU< Собственно пулы
        addr2ilast: big_map(address, t_ipool);//RU< Последний идентификатор пула по адресу создателя
    ];

    const c_ERR_NOT_FOUND: string = "MPools/NotFound";//RU< Ошибка: Не найден пользователь для удаления

    //RU Получить пул по индексу
    //RU
    //RU Если пул не найден, будет возвращена ошибка c_ERR_NOT_FOUND
    function getPool(const pools: t_pools; const ipool: t_ipool): MPool.t_pool is
        case pools.pools[ipool] of
        Some(pool) -> pool
        | None -> (failwith(c_ERR_NOT_FOUND) : MPool.t_pool)
        end;

    //RU Обновить пул по индексу
    [@inline] function setPool(var pools: t_pools; const ipool: t_ipool; const pool: MPool.t_pool): t_pools is block {
        pools.pools := Big_map.update(ipool, Some(pool), pools.pools);
    } with pools;

    //RU Задать состояние пула
    function setState(var pools: t_pools; const ipool: t_ipool; const state: MCtrl.t_state): t_pools is block {
        var pool: MPool.t_pool := getPool(pools, ipool);
        pool := MPool.setState(pool, state);
        pools := setPool(pools, ipool, pool);
    } with pools;

//RU --- Управление пулами

    //RU Создание нового пула //EN Create new pool
    [@inline] function createPool(var pools: t_pools; const ctrl: MCtrl.t_ctrl; const farm: MFarm.t_farm; const random: MRandom.t_random): t_pools is block {
        const pool: MPool.t_pool = record [
            ctrl = ctrl;
            farm = farm;
            random = random;
            game = MGame.idleGame(unit);
            balance = 0n;
#if ENABLE_POOL_STAT
            paid = 0n;
            games = 0n;
#endif // ENABLE_POOL_STAT
        ];
        MPool.check(pool);//RU Проверяем валидность настроек пула
        const ipool: t_ipool = pools.iend;//RU Индекс нового пула
        pools.iend := ipool + 1n;
        pools.count := pools.count + 1n;
        pools.pools := Big_map.add(ipool, pool, pools.pools);
        case pools.addr2ilast[Tezos.sender] of //RU Обновляем последний индекс по адресу создателя пула
        Some(_ilast) -> pools.addr2ilast := Big_map.update(Tezos.sender, Some(ipool), pools.addr2ilast)
        | None -> pools.addr2ilast := Big_map.add(Tezos.sender, ipool, pools.addr2ilast)
        end
    } with pools;

    //RU Приостановка пула //EN Pause pool
    [@inline] function pausePool(var pools: t_pools; const ipool: t_ipool): t_pools is block {
        pools := setState(pools, ipool, MCtrl.c_STATE_PAUSED);
    } with pools;

    //RU Запуск пула (после паузы) //EN Play pool (after pause)
    [@inline] function playPool(var pools: t_pools; const ipool: t_ipool): t_pools is block {
        pools := setState(pools, ipool, MCtrl.c_STATE_ACTIVE);
    } with pools;

    //RU Удаление пула сейчас //EN Remove pool now
    function forceRemovePool(var pools: t_pools; const ipool: t_ipool): t_pools is block {
        pools := setState(pools, ipool, MCtrl.c_STATE_REMOVENOW);//RU Все необходимые операции по удалению пула
        pools.pools := Big_map.remove(ipool, pools.pools);
        pools.count := abs(pools.count - 1);
        var ibeg: nat := pools.ibeg;
        if ipool = ibeg then block {//RU Нужно найти новое начало индексов
            // const iend: nat = pools.iend;
            // while ((ibeg < iend) and (not Big_map.mem(ibeg, pools.pools))) block { ibeg := ibeg + 1n; };
            pools.ibeg := ibeg;
        } else skip;
    } with pools;

    //RU Удаление пула (по окончании партии) //EN Remove pool (after game)
    [@inline] function removePool(var pools: t_pools; const ipool: t_ipool): t_pools is block {
        const pool: MPool.t_pool = getPool(pools, ipool);
        if MGame.c_STATE_IDLE = pool.game.state then block {//RU Партия завершена, можно удалить сейчас
            pools := forceRemovePool(pools, ipool);
        } else block {
            const pool: MPool.t_pool = MPool.setState(pool, MCtrl.c_STATE_REMOVE);//RU Только меняем состояние, реальное удаление по завершению партии
            pools := setPool(pools, ipool, pool);
        };
    } with pools;

#if ENABLE_POOL_EDIT
    //RU Редактирование пула (приостановленого) //EN Edit pool (paused)
    [@inline] function editPool(var pools: t_pools; const ipool: t_ipool;
            const optctrl: option(MCtrl.t_ctrl); const optfarm: option(MFarm.t_farm); const optrandom: option(MRandom.t_random)): t_pools is block {
        var pool: MPool.t_pool := getPool(pools, ipool);
        pool := MPool.edit(pool, optctrl, optfarm, optrandom);
        pools := setPool(pools, ipool, pool);
    } with pools;
#endif // ENABLE_POOL_EDIT

//RU --- Для пользователей пулов

    //RU Депозит в пул 
    //RU @param damount Кол-во токенов для инвестирования в пул
    //EN Deposit to pool
    //RU @param damount Amount of tokens for invest to pool
    [@inline] function deposit(var pools: t_pools; const ipool: t_ipool; const damount: MFarm.t_amount): t_pools is block {
        var pool: MPool.t_pool := getPool(pools, ipool);
        pool := MPool.deposit(pool, damount);
        pools := setPool(pools, ipool, pool);
    } with pools;

    //RU Извлечение из пула
    //RU
    //RU 0n == wamount - извлечение всего депозита из пула
    //EN Withdraw from pool
    //RU
    //RU 0n == wamount - withdraw all deposit from pool
    [@inline] function withdraw(var pools: t_pools; const ipool: t_ipool; const wamount: MFarm.t_amount): t_pools is block {
        var pool: MPool.t_pool := getPool(pools, ipool);
        pool := MPool.withdraw(pool, wamount);
        pools := setPool(pools, ipool, pool);
    } with pools;

//RU --- От провайдера случайных чисел

    [@inline] function onRandom(var pools: t_pools; const ipool: t_ipool; const random: nat): t_pools is block {
        var pool: MPool.t_pool := getPool(pools, ipool);
        pool := MPool.onRandom(pool, random);
        pools := setPool(pools, ipool, pool);
    } with pools;

//RU --- От фермы

    [@inline] function onReward(var pools: t_pools; const ipool: t_ipool; const reward: nat): t_pools is block {
        var pool: MPool.t_pool := getPool(pools, ipool);
        pool := MPool.onReward(pool, reward);
        pools := setPool(pools, ipool, pool);
    } with pools;
}
#endif // MPOOLS_INCLUDED

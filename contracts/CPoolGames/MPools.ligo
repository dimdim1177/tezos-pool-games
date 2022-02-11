#if !MPOOLS_INCLUDED
#define MPOOLS_INCLUDED

#include "../include/consts.ligo"
#include "MPool.ligo"
#include "MUsers.ligo"

//RU Модуль списка пулов ликвидности с периодическими розыгрышами вознаграждений
module MPools is {

    type t_ipool is nat;//RU< Индекс пула
    type t_pool is MPool.t_pool;//RU< Пул
    type t_pools is map(t_ipool, t_pool);//RU< Пулы по их ID
    type t_creator is address;//RU< Адрес админа, создавшего пул

    //RU Список пулов
    type t_rpools is [@layout:comb] record [
        inext: t_ipool;//RU< ID следующего пула
        pools: t_pools;//RU< Собственно пулы
        addr2ilast: big_map(address, t_ipool);//RU< Последний идентификатор пула по адресу создателя
    ];

    const c_ERR_NOT_FOUND: string = "MPools/NotFound";//RU< Ошибка: Не найден пользователь для удаления

    //RU Получить пул по индексу
    //RU
    //RU Если пул не найден, будет возвращена ошибка c_ERR_NOT_FOUND
    function getPool(const rpools: t_rpools; const ipool: t_ipool): t_pool is
        case rpools.pools[ipool] of
        Some(pool) -> pool
        | None -> (failwith(c_ERR_NOT_FOUND) : t_pool)
        end;

    //RU Обновить пул по индексу
    [@inline] function setPool(var rpools: t_rpools; const ipool: t_ipool; const pool: t_pool): t_rpools is block {
        rpools.pools := Big_map.update(ipool, Some(pool), rpools.pools);
    } with rpools;

    //RU Задать состояние пула
    function setState(var rpools: t_rpools; const ipool: t_ipool; const state: MCtrl.t_state): t_rpools is block {
        var pool: t_pool := getPool(rpools, ipool);
        pool := MPool.setState(pool, state);
        rpools := setPool(rpools, ipool, pool);
    } with rpools;

//RU --- Управление пулами

    //RU Создание нового пула //EN Create new pool
    [@inline] function createPool(var rpools: t_rpools; const ctrl: MCtrl.t_ctrl; const farm: MFarm.t_farm; const random: MRandom.t_random): t_rpools is block {
        const pool: t_pool = record [
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
        const ipool: t_ipool = rpools.inext;//RU Индекс нового пула
        rpools.inext := ipool + 1n;
        rpools.pools := Big_map.add(ipool, pool, rpools.pools);
        rpools.addr2ilast := Big_map.update(Tezos.sender, Some(ipool), rpools.addr2ilast);//RU Обновляем последний индекс по адресу создателя пула
    } with rpools;

    //RU Получить ID последнего созданного админом пула
    //RU
    //RU Обоснованно полагаем, что с одного адреса не создаются пулы в несколько потоков, поэтому этот метод позволяет получить
    //RU ID только что созданного админов нового пула. Если нет созданных админов пулов, будет возвращено -1
    [@inline] function viewLastIPool(const rpools: t_rpools): int is
        case rpools.addr2ilast[Tezos.sender] of
        Some(ilast) -> int(ilast)
        | None -> -1
        end

    //RU Получение карты пулов, всех или только активных
    [@inline] function viewPools(const rpools: t_rpools; const onlyActive: bool): t_pools is block {
        function folded(var pools: t_pools; const ipool2pool: t_ipool * t_pool): t_pools is block {
            if (not onlyActive) or MPool.isActive(ipool2pool.1) then
                pools := Map.add(ipool2pool.0, ipool2pool.1, pools)
            else skip;
        } with pools;
        var pools: t_pools := map [];
        pools := Map.fold(folded, rpools.pools, pools);
    } with pools;

    //RU Получение пула, любого или только активного
    [@inline] function viewPool(const rpools: t_rpools; const ipool: t_ipool; const onlyActive: bool): t_pool is block {
        const pool: t_pool = getPool(rpools, ipool);
        if (onlyActive) and (not MPool.isActive(pool)) then failwith(c_ERR_NOT_FOUND)
        else skip;
    } with pool;

    //RU Приостановка пула //EN Pause pool
    [@inline] function pausePool(var rpools: t_rpools; const ipool: t_ipool): t_rpools is block {
        rpools := setState(rpools, ipool, MCtrl.c_STATE_PAUSED);
    } with rpools;

    //RU Запуск пула (после паузы) //EN Play pool (after pause)
    [@inline] function playPool(var rpools: t_rpools; const ipool: t_ipool): t_rpools is block {
        rpools := setState(rpools, ipool, MCtrl.c_STATE_ACTIVE);
    } with rpools;

    //RU Удаление пула сейчас //EN Remove pool now
    function forceRemovePool(var rpools: t_rpools; const ipool: t_ipool): t_operations * t_rpools is block {
        var operations: t_operations := list [];
        rpools := setState(rpools, ipool, MCtrl.c_STATE_FORCE_REMOVE);//RU Все необходимые операции по удалению пула сейчас
        rpools.pools := Big_map.remove(ipool, rpools.pools);
    } with (operations, rpools);

    //RU Удаление пула (по окончании партии) //EN Remove pool (after game)
    [@inline] function removePool(var rpools: t_rpools; const ipool: t_ipool): t_operations * t_rpools is block {
        var operations: t_operations := list [];
        var pool: t_pool := getPool(rpools, ipool);
        if (MGame.c_STATE_IDLE = pool.game.state) or (0n = pool.balance) then block {//RU Партия завершена или пул пуст, можно удалить сейчас
            const r: t_operations * t_rpools = forceRemovePool(rpools, ipool);
            operations := r.0;
            rpools := r.1;
        } else block {
            var pool: t_pool := MPool.setState(pool, MCtrl.c_STATE_REMOVE);//RU Только меняем состояние, реальное удаление по завершению партии
            rpools := setPool(rpools, ipool, pool);
        };
    } with (operations, rpools);

#if ENABLE_POOL_EDIT
    //RU Редактирование пула (приостановленого) //EN Edit pool (paused)
    [@inline] function editPool(var rpools: t_rpools; const ipool: t_ipool;
            const optctrl: option(MCtrl.t_ctrl); const optfarm: option(MFarm.t_farm); const optrandom: option(MRandom.t_random)): t_rpools is block {
        var pool: t_pool := getPool(rpools, ipool);
        pool := MPool.edit(pool, optctrl, optfarm, optrandom);
        rpools := setPool(rpools, ipool, pool);
    } with rpools;
#endif // ENABLE_POOL_EDIT

//RU --- Для пользователей пулов

    //RU Депозит в пул 
    //RU @param damount Кол-во токенов для инвестирования в пул
    //EN Deposit to pool
    //RU @param damount Amount of tokens for invest to pool
    [@inline] function deposit(var rpools: t_rpools; const ipool: t_ipool; const damount: MFarm.t_amount): t_operations * t_rpools is block {
        var operations: t_operations := list [];
        var pool: t_pool := getPool(rpools, ipool);
        pool := MPool.deposit(pool, damount);
        rpools := setPool(rpools, ipool, pool);
    } with (operations, rpools);

    //RU Извлечение из пула
    //RU
    //RU 0n == wamount - извлечение всего депозита из пула
    //EN Withdraw from pool
    //EN
    //EN 0n == wamount - withdraw all deposit from pool
    [@inline] function withdraw(var rpools: t_rpools; const ipool: t_ipool; const wamount: MFarm.t_amount): t_operations * t_rpools is block {
        var operations: t_operations := list [];
        var pool: t_pool := getPool(rpools, ipool);
        pool := MPool.withdraw(pool, wamount);
        rpools := setPool(rpools, ipool, pool);
    } with (operations, rpools);

//RU --- От провайдера случайных чисел

    [@inline] function onRandom(var rpools: t_rpools; const ipool: t_ipool; const random: nat): t_operations * t_rpools is block {
        var operations: t_operations := list [];
        var pool: t_pool := getPool(rpools, ipool);
        pool := MPool.onRandom(pool, random);
        rpools := setPool(rpools, ipool, pool);
    } with (operations, rpools);

//RU --- От фермы

    [@inline] function onReward(var rpools: t_rpools; const ipool: t_ipool; const reward: nat): t_operations * t_rpools is block {
        var operations: t_operations := list [];
        var pool: t_pool := getPool(rpools, ipool);
        pool := MPool.onReward(pool, reward);
        rpools := setPool(rpools, ipool, pool);
    } with (operations, rpools);

}
#endif // !MPOOLS_INCLUDED

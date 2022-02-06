#if !MPOOLS_INCLUDED
#define MPOOLS_INCLUDED

#include "MPool.ligo"
#include "MUsers.ligo"

//RU Модуль списка пулов ликвидности с периодическими розыгрышами вознаграждений
module MPools is {

    type t_ipool is nat;//RU< Индекс пула

    //RU Пулы для розыгрышей вознаграждения
    type t_pools is map(t_ipool, MPool.t_pool);

    const c_ERR_NOT_FOUND: string = "MPools/NotFound";//RU< Ошибка: Не найден пользователь для удаления

    //RU Получить пул по индексу
    //RU
    //RU Если пул не найден, будет возвращена ошибка c_ERR_NOT_FOUND
    function getPool(const pools: t_pools; const ipool: t_ipool): MPool.t_pool is
        case pools[ipool] of
        Some(pool) -> pool
        | None -> (failwith(c_ERR_NOT_FOUND) : MPool.t_pool)
        end;

    //RU Задать состояние пула
    function setState(var pools: t_pools; const ipool: t_ipool; const state: MCtrl.t_state): t_pools is block {
        var pool := getPool(pools, ipool);
        pool := MPool.setState(pool, state);
        pools := Map.update(ipool, Some(pool), pools);
    } with pools;

//RU --- Управление пулами

    //RU Создание нового пула //EN Create new pool
    [@inline] function createPool(var pools: t_pools; const ctrl: MCtrl.t_ctrl; const farm: MFarm.t_farm): t_pools is block {
        skip;
    } with pools;

    //RU Приостановка пула //EN Pause pool
    [@inline] function pausePool(var pools: t_pools; const ipool: t_ipool): t_pools is block {
        pools := setState(pools, ipool, MCtrl.c_STATE_PAUSED);
    } with pools;

    //RU Запуск пула (после паузы) //EN Play pool (after pause)
    [@inline] function playPool(var pools: t_pools; const ipool: t_ipool): t_pools is block {
        pools := setState(pools, ipool, MCtrl.c_STATE_ACTIVE);
    } with pools;

    //RU Удаление пула (по окончании партии) //EN Remove pool (after game)
    [@inline] function removePool(var pools: t_pools; const ipool: t_ipool): t_pools is block {
        pools := setState(pools, ipool, MCtrl.c_STATE_REMOVE);
    } with pools;

    //RU Удаление пула сейчас //EN Remove pool now
    [@inline] function removePoolNow(var pools: t_pools; const ipool: t_ipool): t_pools is block {
        pools := setState(pools, ipool, MCtrl.c_STATE_REMOVENOW);
    } with pools;

#if ENABLE_EDIT_POOL
    //RU Редактирование пула (приостановленого) //EN Edit pool (paused)
    [@inline] function editPool(var pools: t_pools; const ipool: t_ipool; const ctrl: MCtrl.t_ctrl): t_pools is block {
        var pool := getPool(pools, ipool);
        pool := MPool.edit(pool, ctrl);
        pools := Map.update(ipool, Some(pool), pools);
    } with pools;
#endif // ENABLE_EDIT_POOL

//RU --- Для пользователей пулов

    //RU Депозит в пул //EN Deposit to pool
    [@inline] function deposit(var pools: t_pools; const ipool: t_ipool; const addamount: MUsers.t_balance): t_pools is block {
        var pool := getPool(pools, ipool);
        pool := MPool.deposit(pool, addamount);
        pools := Map.update(ipool, Some(pool), pools);
    } with pools;

    //RU Извлечение из пула //EN Withdraw from pool
    [@inline] function withdraw(var pools: t_pools; const ipool: t_ipool): t_pools is block {
        var pool := getPool(pools, ipool);
        pool := MPool.withdraw(pool);
        pools := Map.update(ipool, Some(pool), pools);
    } with pools;

//RU --- От провайдера случайных чисел

    [@inline] function onRandom(var pools: t_pools; const ipool: t_ipool; const random: nat): t_pools is block {
        var pool := getPool(pools, ipool);
        pool := MPool.onRandom(pool, random);
        pools := Map.update(ipool, Some(pool), pools);
    } with pools;

//RU --- От фермы

    [@inline] function onReward(var pools: t_pools; const ipool: t_ipool; const reward: nat): t_pools is block {
        var pool := getPool(pools, ipool);
        pool := MPool.onReward(pool, reward);
        pools := Map.update(ipool, Some(pool), pools);
    } with pools;
}
#endif // MPOOLS_INCLUDED

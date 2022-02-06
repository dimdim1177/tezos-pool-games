#if !MPOOL_INCLUDED
#define MPOOL_INCLUDED

#include "../module/MToken.ligo"
#include "../module/MFarm.ligo"
#include "MCtrl.ligo"
#include "MGame.ligo"
#include "MUsers.ligo"

//RU Модуль пула ликвидности с периодическими розыгрышами вознаграждений
module MPool is {

    //RU Пул для розыгрышей вознаграждения
    type t_pool is [@layout:comb] record [
        ctrl: MCtrl.t_ctrl;//RU< Управление пулом
        farm: MFarm.t_farm;//RU< Ферма для пула
        game: MGame.t_game;//RU< Текущая партия розыгрыша вознаграждения
    ];

    //RU Проверка подаваемых на вход контракта параметров
    [@inline] function check(const pool: t_pool): unit is block {
        MCtrl.check(pool.ctrl);
        MFarm.check(pool.farm);
    } with unit; 

//RU --- Управление пулом

    [@inline] function setState(var pool: t_pool; const state: MCtrl.t_state): t_pool is block {
        pool.ctrl.state := state;//TODO
    } with pool;

    [@inline] function edit(var pool: t_pool; const ctrl: MCtrl.t_ctrl): t_pool is block {
        pool.ctrl := ctrl;//TODO
    } with pool;

//RU --- Для пользователей пулов

    [@inline] function deposit(var pool: t_pool; const addamount: MUsers.t_balance): t_pool is block {
        skip;//TODO
    } with pool;

    [@inline] function withdraw(var pool: t_pool): t_pool is block {
        skip;//TODO
    } with pool;

//RU --- От провайдера случайных чисел

    [@inline] function onRandom(var pool: t_pool; const random: nat): t_pool is block {
        skip;//TODO
    } with pool;

//RU --- От фермы

    [@inline] function onReward(var pool: t_pool; const reward: nat): t_pool is block {
        skip;//TODO
    } with pool;

}
#endif // MPOOL_INCLUDED

#if !MPOOL_INCLUDED
#define MPOOL_INCLUDED

#include "../module/MToken.ligo"
#include "../module/MFarm.ligo"
#include "../module/MRandom.ligo"
#include "MCtrl.ligo"
#include "MGame.ligo"
#include "MUsers.ligo"

//RU Модуль пула ликвидности с периодическими розыгрышами вознаграждений
module MPool is {

    //RU Пул для розыгрышей вознаграждения
    type t_pool is [@layout:comb] record [
        ctrl: MCtrl.t_ctrl;//RU< Управление пулом
        farm: MFarm.t_farm;//RU< Ферма для пула
        random: MRandom.t_random;//RU< Источник случайных чисел для розыгрышей
        game: MGame.t_game;//RU< Текущая партия розыгрыша вознаграждения
        balance: MFarm.t_amount;//RU< Сколько токенов фермы инвестировано в пул в настоящий момент
#if ENABLE_POOL_STAT
        paid: MFarm.t_amount;//RU< Сколько токенов вознаграждения было выплачено пулом за все партии
        games: nat;//RU< Сколько партий уже проведено в этом пуле
#endif // ENABLE_POOL_STAT
    ];

    //RU Проверка параметров пула при создании на валидность
    [@inline] function check(const pool: t_pool): unit is block {
        MCtrl.check(pool.ctrl, True);
        MFarm.check(pool.farm);
        MRandom.check(pool.random);
    } with unit;

//RU --- Управление пулом

    [@inline] function setState(var pool: t_pool; const state: MCtrl.t_state): t_pool is block {
        pool.ctrl.state := state;//TODO
    } with pool;

    [@inline] function edit(var pool: t_pool; const optctrl: option(MCtrl.t_ctrl);
            const optfarm: option(MFarm.t_farm); const optrandom: option(MRandom.t_random)): t_pool is block {
        case optctrl of
        Some(ctrl) -> block {
            MCtrl.check(ctrl, False);
            pool.ctrl := ctrl;
        }
        | None -> skip
        end;
        case optfarm of
        Some(farm) -> block {
            MFarm.check(farm);
            pool.farm := farm;
        }
        | None -> skip
        end;
        case optrandom of
        Some(random) -> block {
            MRandom.check(random);
            pool.random := random;
        }
        | None -> skip
        end;
    } with pool;

//RU --- Для пользователей пулов

    [@inline] function deposit(var pool: t_pool; const damount: MFarm.t_amount): t_pool is block {
        MFarm.deposit(pool.farm, damount);
        skip;//TODO
    } with pool;

    //RU Извлечение из пула
    //RU
    //RU 0n == wamount - извлечение всего депозита из пула
    //EN Withdraw from pool
    //EN
    //EN 0n == wamount - withdraw all deposit from pool
    [@inline] function withdraw(var pool: t_pool; const wamount: MFarm.t_amount): t_pool is block {
        MFarm.withdraw(pool.farm, wamount);
        skip;//TODO
    } with pool;

//RU --- От провайдера случайных чисел

    [@inline] function onRandom(var pool: t_pool; const _random: nat): t_pool is block {
        skip;//TODO
    } with pool;

//RU --- От фермы

    [@inline] function onReward(var pool: t_pool; const _reward: nat): t_pool is block {
        skip;//TODO
    } with pool;

}
#endif // MPOOL_INCLUDED

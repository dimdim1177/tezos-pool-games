#if !MPOOL_INCLUDED
#define MPOOL_INCLUDED

#include "../module/MToken.ligo"
#include "../module/MFarm.ligo"
#include "../module/MRandom.ligo"
#include "MPoolOpts.ligo"
#include "MPoolStat.ligo"
#include "MPoolGame.ligo"
#include "MUsers.ligo"

//RU Модуль пула ликвидности с периодическими розыгрышами вознаграждений
module MPool is {

    //RU Индекс пользователя внутри пула
    type t_iuser is nat;

    //RU Информация о пуле, выдаваемая при запросе всем пользователям
    type t_pool_info is [@layout:comb] record [
        opts: MPoolOpts.t_opts;//RU< Настройки пула
        farm: MFarm.t_farm;//RU< Ферма для пула
        game: MPoolGame.t_game;//RU< Текущая партия розыгрыша вознаграждения
#if ENABLE_POOL_STAT
        stat: MPoolStat.t_stat;//RU< Статистика пула
#endif // ENABLE_POOL_STAT
    ];

    //RU Пул (возвращается при запросе информации о пуле админом)
    type t_pool is [@layout:comb] record [
        info: t_pool_info;//RU< Основная информация о пуле, предоставляется любым пользователям
        random: MRandom.t_random;//RU< Источник случайных чисел для розыгрышей
        burn: MToken.t_token;///RU< Токен для сжигания всего, что выше процента выигрыша
        ibeg: t_iuser;//RU< Начальный индекс пользователей в пуле
        inext: t_iuser;//RU< Следующий за максимальным индекс пользователей в пуле
    ];

    //RU Создание нового пула
    function create(const opts: MPoolOpts.t_opts; const farm: MFarm.t_farm; 
            const random: MRandom.t_random; const optburn: option(MToken.t_token)): t_pool is block {
    //RU Проверяем все входные параметры
        MPoolOpts.check(opts, True);
        MFarm.check(farm);
        MRandom.check(random);
        const burn: MToken.t_token = MToken.opt2token(optburn);
        MToken.check(burn, MPoolOpts.maybeNoBurn(opts));
    
    // RU И если все корректно, формируем начальные данные пула
        var gameState: MPoolGame.t_game_state := MPoolGame.c_STATE_ACTIVE;
        var gameSeconds: nat := opts.gameSeconds;
        if MPoolOpts.c_STATE_ACTIVE = opts.state then skip
        else block {//RU Создание пула в приостановленном состоянии
            gameState := MPoolGame.c_STATE_PAUSE;
            gameSeconds := 0n;
        };
        const pool: t_pool = record [
            info = record [
                opts = opts;
                farm = farm;
                game = MPoolGame.create(gameState, int(gameSeconds));
#if ENABLE_POOL_STAT
                stat = MPoolStat.create(unit);
#endif // ENABLE_POOL_STAT
            ];
            random = random;
            burn = burn;
            ibeg = 0n;
            inext = 0n;//RU Начинаем индексацию пользователей с нуля
        ];
    } with pool;

//RU --- Управление пулом

    function setState(var pool: t_pool; const state: MPoolOpts.t_pool_state): t_pool is block {
        pool.info.opts.state := state;//TODO
    } with pool;

#if ENABLE_POOL_EDIT
    function edit(var pool: t_pool; const optctrl: option(MPoolOpts.t_opts); const optfarm: option(MFarm.t_farm); 
            const optrandom: option(MRandom.t_random); const optburn: option(MToken.t_token)): t_pool is block {
        case optctrl of
        Some(opts) -> block {
            MPoolOpts.check(opts, False);
            pool.info.opts := opts;
        }
        | None -> skip
        end;
        case optfarm of
        Some(farm) -> block {
            MFarm.check(farm);
            pool.info.farm := farm;
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
        case optburn of
        Some(burn) -> block {
            MToken.check(burn, 100n = pool.info.opts.winPercent);
            pool.burn := burn;
        }
        | None -> skip
        end;
    } with pool;
#endif // ENABLE_POOL_EDIT

//RU --- Для пользователей пулов

    function deposit(var pool: t_pool; const damount: MFarm.t_amount): t_pool is block {
        MFarm.deposit(pool.info.farm, damount);
        skip;//TODO
    } with pool;

    //RU Извлечение из пула
    //RU
    //RU 0n == wamount - извлечение всего депозита из пула
    //EN Withdraw from pool
    //EN
    //EN 0n == wamount - withdraw all deposit from pool
    function withdraw(var pool: t_pool; const wamount: MFarm.t_amount): t_pool is block {
        MFarm.withdraw(pool.info.farm, wamount);
        skip;//TODO
    } with pool;

//RU --- От провайдера случайных чисел

    function onRandom(var pool: t_pool; const _random: nat): t_pool is block {
        skip;//TODO
    } with pool;

//RU --- От фермы

    function onReward(var pool: t_pool; const _reward: nat): t_pool is block {
        skip;//TODO
    } with pool;

    [@inline] function isActive(const pool: t_pool): bool is block {
        const r: bool = (pool.info.opts.state = MPoolOpts.c_STATE_ACTIVE);
    } with r;

}
#endif // !MPOOL_INCLUDED

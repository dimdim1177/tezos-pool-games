#if !MPOOL_INCLUDED
#define MPOOL_INCLUDED

#include "storage.ligo"
#include "MPoolOpts.ligo"
#include "MPoolStat.ligo"
#include "MPoolGame.ligo"
#include "MUsers.ligo"

//RU Модуль пула ликвидности с периодическими розыгрышами вознаграждений
module MPool is {

    const cERR_MUST_BURN: string = "MPool/MustBurn";//RU< Ошибка: Обязателен токен для сжигания
    const cERR_INACTIVE: string = "MPool/Inactive";//RU< Ошибка: Пул неактивен

    //RU Активен ли пул
    //RU
    //RU Технически пока партия не приостановлена пул активен, он доступен для просмотра, для внесения
    //RU депозитов и т.п.
    [@inline] function isActive(const pool: t_pool): bool is block {
        const r: bool = (pool.game.state =/= MPoolGame.cSTATE_PAUSE);
    } with r;

    //RU Создание нового пула
    function create(const opts: t_opts; const farm: t_farm; 
            const random: t_random; const burn: option(t_token)): t_pool is block {
    //RU Проверяем все входные параметры
        MPoolOpts.check(opts, True);
        MFarm.check(farm);
        MRandom.check(random);
        case burn of
        Some(b) -> MToken.check(b)
        | None -> block {
            if MPoolOpts.maybeNoBurn(opts) then skip
            else failwith(cERR_MUST_BURN);
        }
        end;

    // RU И если все корректно, формируем начальные данные пула
        var gameState: t_game_state := MPoolGame.cSTATE_ACTIVE;
        var gameSeconds: nat := opts.gameSeconds;
        if MPoolOpts.cSTATE_ACTIVE = opts.state then skip
        else block {//RU Создание пула в приостановленном состоянии
            gameState := MPoolGame.cSTATE_PAUSE;
            gameSeconds := 0n;
        };
        const pool: t_pool = record [
            opts = opts;
            farm = farm;
            game = MPoolGame.create(gameState, int(gameSeconds));
            random = random;
            burn = burn;
            ibeg = 0n;
            inext = 0n;//RU Начинаем индексацию пользователей с нуля
#if ENABLE_POOL_STAT
            stat = MPoolStat.create(unit);
#endif // ENABLE_POOL_STAT
        ];
    } with pool;

//RU --- Управление пулом

    function setState(var pool: t_pool; const state: t_pool_state): t_pool is block {
        pool.opts.state := state;
    } with pool;

#if ENABLE_POOL_EDIT
    function edit(var pool: t_pool; const optopts: option(t_opts); const optfarm: option(t_farm); 
            const optrandom: option(t_random); const burn: option(t_token)): t_pool is block {
        case optopts of
        Some(opts) -> block {
            MPoolOpts.check(opts, False);
            pool.opts := opts;
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
        case burn of
        Some(b) -> MToken.check(b)
        | None -> block {
            if MPoolOpts.maybeNoBurn(pool.opts) then skip
            else failwith(cERR_MUST_BURN);
        }
        end;
        pool.burn := burn;
    } with pool;
#endif // ENABLE_POOL_EDIT

(*
    //RU Начать следующую партию
    function nextGame(const ipool: t_ipool; var pool: t_pool; var users: t_users): t_pool * t_users is block {
#if ENABLE_REINDEX_USERS
        //RU Если кол-во индексов пользователей в пуле в 2 раза больше реального кол-ва,
        //RU переиндексируем пул, что вдвое уменьшит кол-во итераций по пулу при переборе всех пользователей
        if ((pool.inext - pool.ibeg) > (2 * pool.game.count)) then block {
            const r: t_users * t_iuser * t_iuser = MUsers.reindex(users, ipool, pool.ibeg, pool.inext);
            users := r.0;
            pool.ibeg := r.1;
            pool.inext := r.2;
        } else skip;
#endif // ENABLE_REINDEX_USERS
    } with (pool, users);
*)

//RU --- Для пользователей пулов

    function deposit(var s: t_storage; const _ipool: t_ipool; var pool: t_pool; const damount: t_amount): t_return * t_pool is block {
        if isActive(pool) then skip
        else failwith(cERR_INACTIVE);
        const operations = MFarm.deposit(pool.farm, damount);
    } with ((operations, s), pool);

    //RU Извлечение из пула
    //RU
    //RU 0n == wamount - извлечение всего депозита из пула
    //EN Withdraw from pool
    //EN
    //EN 0n == wamount - withdraw all deposit from pool
    function withdraw(var s: t_storage; const _ipool: t_ipool; var pool: t_pool; const wamount: t_amount): t_return * t_pool is block {
        const operations = MFarm.withdraw(pool.farm, wamount);
    } with ((operations, s), pool);

//RU --- От провайдера случайных чисел

    function onRandom(const _ipool: t_ipool; var pool: t_pool; const _random: nat): t_pool is block {
        skip;//TODO
    } with pool;

//RU --- От фермы

    function onReward(const _ipool: t_ipool; var pool: t_pool; const _reward: nat): t_pool is block {
        skip;//TODO
    } with pool;

}
#endif // !MPOOL_INCLUDED

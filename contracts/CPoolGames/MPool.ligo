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
    const cERR_MUST_FEEADDR: string = "MPool/MustFeeAddr";//RU< Ошибка: Обязателен адрес для комиссии
    const cERR_INACTIVE: string = "MPool/Inactive";//RU< Ошибка: Пул неактивен

    //RU Активен ли пул
    //RU
    //RU Технически пока партия не приостановлена пул активен, он доступен для просмотра, для внесения
    //RU депозитов и т.п.
    [@inline] function isActive(const pool: t_pool): bool is block {
        const r: bool = (pool.game.state =/= MPoolGame.cSTATE_PAUSE);
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
    //RU Безусловная смена менеджера пула (без проверки доступа)
    function forceChangeManager(var pool: t_pool; const newmanager: address): t_pool is block {
        pool.manager := MManager.forceChange(pool.manager, newmanager);
    } with pool;
#endif // ENABLE_POOL_MANAGER

    //RU Создание нового пула
    function create(const pool_create: t_pool_create): t_pool is block {
    //RU Проверяем все входные параметры
        MPoolOpts.check(pool_create.opts, True);
        MFarm.check(pool_create.farm);
        MRandom.check(pool_create.random);
        case pool_create.burn of
        Some(burn) -> MToken.check(burn)
        | None -> block {
            if MPoolOpts.maybeNoBurn(pool_create.opts) then skip
            else failwith(cERR_MUST_BURN);
        }
        end;
        case pool_create.feeaddr of
        Some(_feeaddr) -> skip
        | None -> block {
            if MPoolOpts.maybeNoFeeAddr(pool_create.opts) then skip
            else failwith(cERR_MUST_FEEADDR);
        }
        end;

    // RU И если все корректно, формируем начальные данные пула
        var gameState: t_game_state := MPoolGame.cSTATE_ACTIVE;
        var gameSeconds: nat := pool_create.opts.gameSeconds;
        if MPoolOpts.cSTATE_ACTIVE = pool_create.opts.state then skip
        else block {//RU Создание пула в приостановленном состоянии
            gameState := MPoolGame.cSTATE_PAUSE;
            gameSeconds := 0n;
        };
        const pool: t_pool = record [
            opts = pool_create.opts;
            farm = pool_create.farm;
            random = pool_create.random;
            burn = pool_create.burn;
            feeaddr = pool_create.feeaddr;
            game = MPoolGame.create(gameState, int(gameSeconds));
            ibeg = 0n;
            inext = 0n;//RU Начинаем индексацию пользователей с нуля
#if ENABLE_POOL_MANAGER
            manager = Tezos.sender;//RU Менеджер пула - его создатель
#endif // ENABLE_POOL_MANAGER
#if ENABLE_POOL_STAT
            stat = MPoolStat.create(unit);
#endif // ENABLE_POOL_STAT
        ];
    } with pool;

//RU --- Управление пулом

    function setState(var pool: t_pool; const state: t_pool_state): t_pool is block {
        pool.opts.state := state;
    } with pool;

    function edit(var pool: t_pool; const pool_edit: t_pool_edit): t_pool is block {
        case pool_edit.opts of
        Some(opts) -> block {
            MPoolOpts.check(opts, False);
            pool.opts := opts;
        }
        | None -> skip
        end;
        case pool_edit.farm of
        Some(farm) -> block {
            MFarm.check(farm);
            pool.farm := farm;
        }
        | None -> skip
        end;
        case pool_edit.random of
        Some(random) -> block {
            MRandom.check(random);
            pool.random := random;
        }
        | None -> skip
        end;
        case pool_edit.burn of
        Some(burn) -> block {
            MToken.check(burn);
            pool.burn := Some(burn);
        }
        | _ -> skip
        end;
        case pool_edit.feeaddr of
        Some(feeaddr) -> pool.feeaddr := Some(feeaddr)
        | _ -> skip
        end;
    } with pool;

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

    //RU Колбек провайдера случайных чисел
    function onRandom(var pool: t_pool; const _random: nat): t_pool is block {
        skip;//TODO
    } with pool;

    //RU Колбек самого себя после запроса вознаграждения с фермы 
    function afterReward(var pool: t_pool): t_pool is block {
        skip;//TODO
    } with pool;

    //RU Колбек самого себя после обмена токенов вознаграждения на токены для сжигания
    function afterChangeReward(var pool: t_pool): t_pool is block {
        skip;//TODO
    } with pool;

}
#endif // !MPOOL_INCLUDED

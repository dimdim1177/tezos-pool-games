#if !MPOOLS_INCLUDED
#define MPOOLS_INCLUDED

#include "MPool.ligo"

//RU Модуль списка пулов ликвидности с периодическими розыгрышами вознаграждений
module MPools is {

    const cERR_UNPACK: string = "MPools/Unpack";//RU< Ошибка: Сбой распаковки
    const cERR_NOT_FOUND: string = "MPools/NotFound";//RU< Ошибка: Не найден пользователь для удаления

    //RU Получить набор ID всех пулов
    //RU
    //RU При ошибке распаковки будет возвращена ошибка cERR_UNPACK
    function getIPools(const s: t_storage): t_ipools is block {
        var ipools: t_ipools := set [];
        const packed_ipools: t_packed_ipools = s.rpools.packed_ipools;
        if 0n = Bytes.length(packed_ipools) then skip //RU Пока не сохраняли упакованный набор
        else block {
            case (Bytes.unpack(packed_ipools): option(t_ipools)) of //RU Распоковка набор
            Some(uipools) -> ipools := uipools
            | None -> failwith(cERR_UNPACK)
            end;
        };
    } with ipools;

    //RU Записать набор ID всех пулов
    [@inline] function setIPools(var s: t_storage; const ipools: t_ipools): t_storage is block {
        s.rpools.packed_ipools := Bytes.pack(ipools);
    } with s;

    //RU Получить пул по индексу
    //RU
    //RU Если пул не найден, будет возвращена ошибка cERR_NOT_FOUND
    function getPool(const s: t_storage; const ipool: t_ipool): t_pool is
        case s.rpools.pools[ipool] of
        Some(pool) -> pool
        | None -> (failwith(cERR_NOT_FOUND) : t_pool)
        end;

    //RU Обновить пул по индексу
    function setPool(var s: t_storage; const ipool: t_ipool; const pool: t_pool): t_storage is block {
        if MPoolOpts.cSTATE_FORCE_REMOVE = pool.info.opts.state then block {//RU Пул на удаление сейчас
            s.rpools.pools := Big_map.remove(ipool, s.rpools.pools);
            var ipools: t_ipools := getIPools(s);
            ipools := Set.remove(ipool, ipools);
            s := setIPools(s, ipools);
        } else block {//RU Обновить пул
            s.rpools.pools := Big_map.update(ipool, Some(pool), s.rpools.pools);
        };
    } with s;

    //RU Задать состояние пула
    //RU
    //RU Если убрать inline компилятор падает
    function setState(const s: t_storage; const ipool: t_ipool; const state: t_pool_state): t_return is block {
        const pool: t_pool = getPool(s, ipool);
        const r_pool: t_return * t_pool = MPool.setState(s, ipool, pool, state);
        const rs: t_storage = setPool(r_pool.0.1, ipool, r_pool.1);
    } with (r_pool.0.0, rs);

//RU --- Управление пулами

    //RU Создание нового пула //EN Create new pool
    function createPool(var s: t_storage; const opts: t_opts; const farm: t_farm; 
            const random: t_random; const optburn: option(t_token)): t_storage is block {
        const pool: t_pool = MPool.create(opts, farm, random, optburn);
        var rpools: t_rpools := s.rpools;
        const ipool: t_ipool = rpools.inext;//RU Индекс нового пула
        rpools.inext := ipool + 1n;
        rpools.pools := Big_map.add(ipool, pool, rpools.pools);
        rpools.addr2ilast := Big_map.update(Tezos.sender, Some(ipool), rpools.addr2ilast);//RU Обновляем последний индекс по адресу создателя пула
        s.rpools := rpools;
        var ipools: t_ipools := getIPools(s);
        ipools := Set.add(ipool, ipools);
        s := setIPools(s, ipools);
    } with s;

    //RU Приостановка пула //EN Pause pool
    function pausePool(const s: t_storage; const ipool: t_ipool): t_return is setState(s, ipool, MPoolOpts.cSTATE_PAUSE);

    //RU Запуск пула (после паузы) //EN Play pool (after pause)
    function playPool(const s: t_storage; const ipool: t_ipool): t_return is setState(s, ipool, MPoolOpts.cSTATE_ACTIVE);

    //RU Удаление пула сейчас //EN Remove pool now
    function forceRemovePool(const s: t_storage; const ipool: t_ipool): t_return is setState(s, ipool, MPoolOpts.cSTATE_FORCE_REMOVE);

    //RU Удаление пула (по окончании партии) //EN Remove pool (after game)
    function removePool(const s: t_storage; const ipool: t_ipool): t_return is block {
        const pool: t_pool = getPool(s, ipool);
        var state: t_pool_state := MPoolOpts.cSTATE_REMOVE;
        if (MPoolGame.cSTATE_PAUSE = pool.info.game.state) or (0n = pool.info.game.balance) then block {//RU Партия завершена или пул пуст, можно удалить сейчас
            state := MPoolOpts.cSTATE_FORCE_REMOVE;
        } else skip;
        const r: t_return = setState(s, ipool, state);
    } with r;

#if ENABLE_POOL_EDIT
    //RU Редактирование пула (приостановленого) //EN Edit pool (paused)
    function editPool(var s: t_storage; const ipool: t_ipool; const optopts: option(t_opts); 
            const optfarm: option(t_farm); const optrandom: option(t_random); const optburn: option(t_token)): t_storage is block {
        var pool: t_pool := getPool(s, ipool);
        pool := MPool.edit(pool, optopts, optfarm, optrandom, optburn);
        s := setPool(s, ipool, pool);
    } with s;
#endif // ENABLE_POOL_EDIT

//RU --- Для пользователей пулов

    //RU Депозит в пул 
    //RU @param damount Кол-во токенов для инвестирования в пул
    //EN Deposit to pool
    //RU @param damount Amount of tokens for invest to pool
    function deposit(var s: t_storage; const ipool: t_ipool; const damount: t_amount): t_return is block {
        const pool: t_pool = getPool(s, ipool);
        const r_pool: t_return * t_pool = MPool.deposit(s, ipool, pool, damount);
        s := setPool(r_pool.0.1, ipool, r_pool.1);
    } with (r_pool.0.0, s);

    //RU Извлечение из пула
    //RU
    //RU 0n == wamount - извлечение всего депозита из пула
    //EN Withdraw from pool
    //EN
    //EN 0n == wamount - withdraw all deposit from pool
    function withdraw(var s: t_storage; const ipool: t_ipool; const wamount: t_amount): t_return is block {
        var pool: t_pool := getPool(s, ipool);
        const r_pool: t_return * t_pool = MPool.withdraw(s, ipool, pool, wamount);
        s := setPool(r_pool.0.1, ipool, r_pool.1);
    } with (r_pool.0.0, s);

//RU --- От провайдера случайных чисел

    function onRandom(var s: t_storage; const ipool: t_ipool; const random: nat): t_return is block {
        var operations: t_operations := list [];
        var pool: t_pool := getPool(s, ipool);
        pool := MPool.onRandom(ipool, pool, random);
        s := setPool(s, ipool, pool);
    } with (operations, s);

//RU --- От фермы

    function onReward(var s: t_storage; const ipool: t_ipool; const reward: nat): t_return is block {
        var operations: t_operations := list [];
        var pool: t_pool := getPool(s, ipool);
        pool := MPool.onReward(ipool, pool, reward);
        s := setPool(s, ipool, pool);
    } with (operations, s);

//RU --- Чтение данных админами (Views)

    //RU Получить ID последнего созданного админом пула
    //RU
    //RU Обоснованно полагаем, что с одного адреса не создаются пулы в несколько потоков, поэтому этот метод позволяет получить
    //RU ID только что созданного админов нового пула. Если нет созданных админов пулов, будет возвращено -1
    function viewLastIPool(const s: t_storage): int is
        case s.rpools.addr2ilast[Tezos.sender] of
        Some(ilast) -> int(ilast)
        | None -> -1
        end

    //RU Получение карты с информацией о пулах (только активных)
    function viewPoolsFullInfo(const s: t_storage): t_pools_fullinfo is block {
        function folded(var pools_fullinfo: t_pools_fullinfo; const ipool: t_ipool): t_pools_fullinfo is block {
            const pool: t_pool = getPool(s, ipool);
            pools_fullinfo := Map.add(ipool, pool, pools_fullinfo);
        } with pools_fullinfo;
        var pools_fullinfo: t_pools_fullinfo := map [];
        const ipools: t_ipools = getIPools(s); 
        pools_fullinfo := Set.fold(folded, ipools, pools_fullinfo);
    } with pools_fullinfo;

    //RU Получение пула (админом)
    function viewPoolFullInfo(const s: t_storage; const ipool: t_ipool): t_pool is getPool(s, ipool);

//RU --- Чтение данных любыми пользователями (Views)

    //RU Получение карты с информацией о пулах (только активных)
    function viewPoolsInfo(const s: t_storage): t_pools_info is block {
        function folded(var pools_info: t_pools_info; const ipool: t_ipool): t_pools_info is block {
            const pool: t_pool = getPool(s, ipool);
            if MPool.isActive(pool) then pools_info := Map.add(ipool, pool.info, pools_info)
            else skip;
        } with pools_info;
        var pools_info: t_pools_info := map [];
        const ipools: t_ipools = getIPools(s); 
        pools_info := Set.fold(folded, ipools, pools_info);
    } with pools_info;

    //RU Получение пула (только активного)
    function viewPoolInfo(const s: t_storage; const ipool: t_ipool): t_pool_info is block {
        const pool: t_pool = getPool(s, ipool);
        if MPool.isActive(pool) then skip
        else failwith(cERR_NOT_FOUND);
        const pool_info: t_pool_info = pool.info;
    } with pool_info;

}
#endif // !MPOOLS_INCLUDED

#if !MPOOLS_INCLUDED
#define MPOOLS_INCLUDED

#include "../include/consts.ligo"
#include "MPool.ligo"
#include "MUsers.ligo"

//RU Модуль списка пулов ликвидности с периодическими розыгрышами вознаграждений
module MPools is {

    type t_ipool is nat;//RU< Индекс пула
    type t_pool is MPool.t_pool;//RU< Пул
    type t_pools is big_map(t_ipool, t_pool);//RU< Пулы по их ID

    type t_ipools is set(t_ipool);//RU< Набор ID всех пулов
    type t_packed_ipools is bytes;//RU< Упакованный набор ID всех пулов

    //RU Пулы и сопутствующая информация
    type t_rpools is [@layout:comb] record [
        inext: t_ipool;//RU< ID следующего пула
        ipools: t_packed_ipools;//RU< Упакованный набор ID всех пулов
        pools: t_pools;//RU< Собственно пулы
        addr2ilast: big_map(address, t_ipool);//RU< Последний идентификатор пула по адресу админа
    ];

    const c_ERR_UNPACK: string = "MPools/Unpack";//RU< Ошибка: Сбой распаковки
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

    //RU Получить набор ID всех пулов
    //RU
    //RU При ошибке распаковки будет возвращена ошибка c_ERR_UNPACK
    function getIPools(const rpools: t_rpools): t_ipools is block {
        var ipools: t_ipools := set [];
        if 0n = Bytes.length(rpools.ipools) then skip //RU Пока не сохраняли упакованный набор
        else block {
            case (Bytes.unpack(rpools.ipools): option(t_ipools)) of //RU Распоковка набор
            Some(uipools) -> ipools := uipools
            | None -> failwith(c_ERR_UNPACK)
            end;
        };
    } with ipools;

    //RU Записать набор ID всех пулов
    [@inline] function setIPools(var rpools: t_rpools; const ipools: t_ipools): t_rpools is block {
        rpools.ipools := Bytes.pack(ipools);
    } with rpools;

    //RU Задать состояние пула
    function setState(var rpools: t_rpools; const ipool: t_ipool; const state: MPoolOpts.t_pool_state): t_rpools is block {
        var pool: t_pool := getPool(rpools, ipool);
        pool := MPool.setState(pool, state);
        rpools := setPool(rpools, ipool, pool);
    } with rpools;

//RU --- Управление пулами

    //RU Создание нового пула //EN Create new pool
    function createPool(var rpools: t_rpools; const opts: MPoolOpts.t_opts; const farm: MFarm.t_farm; 
            const random: MRandom.t_random; const optburn: option(MToken.t_token)): t_rpools is block {
        const pool: t_pool = MPool.create(opts, farm, random, optburn);
        const ipool: t_ipool = rpools.inext;//RU Индекс нового пула
        rpools.inext := ipool + 1n;
        rpools.pools := Big_map.add(ipool, pool, rpools.pools);
        rpools.addr2ilast := Big_map.update(Tezos.sender, Some(ipool), rpools.addr2ilast);//RU Обновляем последний индекс по адресу создателя пула
    } with rpools;

    //RU Приостановка пула //EN Pause pool
    function pausePool(var rpools: t_rpools; const ipool: t_ipool): t_rpools is block {
        rpools := setState(rpools, ipool, MPoolOpts.c_STATE_PAUSE);
    } with rpools;

    //RU Запуск пула (после паузы) //EN Play pool (after pause)
    function playPool(var rpools: t_rpools; const ipool: t_ipool): t_rpools is block {
        rpools := setState(rpools, ipool, MPoolOpts.c_STATE_ACTIVE);
    } with rpools;

    //RU Удаление пула сейчас //EN Remove pool now
    function forceRemovePool(var rpools: t_rpools; const ipool: t_ipool): t_operations * t_rpools is block {
        var operations: t_operations := list [];
        rpools := setState(rpools, ipool, MPoolOpts.c_STATE_FORCE_REMOVE);//RU Все необходимые операции по удалению пула сейчас
        rpools.pools := Big_map.remove(ipool, rpools.pools);
    } with (operations, rpools);

    //RU Удаление пула (по окончании партии) //EN Remove pool (after game)
    function removePool(var rpools: t_rpools; const ipool: t_ipool): t_operations * t_rpools is block {
        var operations: t_operations := list [];
        var pool: t_pool := getPool(rpools, ipool);
        if (MPoolGame.c_STATE_PAUSE = pool.info.game.state) or (0n = pool.info.game.balance) then block {//RU Партия завершена или пул пуст, можно удалить сейчас
            const r: t_operations * t_rpools = forceRemovePool(rpools, ipool);
            operations := r.0;
            rpools := r.1;
        } else block {
            var pool: t_pool := MPool.setState(pool, MPoolOpts.c_STATE_REMOVE);//RU Только меняем состояние, реальное удаление по завершению партии
            rpools := setPool(rpools, ipool, pool);
        };
    } with (operations, rpools);

#if ENABLE_POOL_EDIT
    //RU Редактирование пула (приостановленого) //EN Edit pool (paused)
    function editPool(var rpools: t_rpools; const ipool: t_ipool; const optctrl: option(MPoolOpts.t_opts); 
            const optfarm: option(MFarm.t_farm); const optrandom: option(MRandom.t_random); const optburn: option(MToken.t_token)): t_rpools is block {
        var pool: t_pool := getPool(rpools, ipool);
        pool := MPool.edit(pool, optctrl, optfarm, optrandom, optburn);
        rpools := setPool(rpools, ipool, pool);
    } with rpools;
#endif // ENABLE_POOL_EDIT

//RU --- Для пользователей пулов

    //RU Депозит в пул 
    //RU @param damount Кол-во токенов для инвестирования в пул
    //EN Deposit to pool
    //RU @param damount Amount of tokens for invest to pool
    function deposit(var rpools: t_rpools; const ipool: t_ipool; const damount: MFarm.t_amount): t_operations * t_rpools is block {
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
    function withdraw(var rpools: t_rpools; const ipool: t_ipool; const wamount: MFarm.t_amount): t_operations * t_rpools is block {
        var operations: t_operations := list [];
        var pool: t_pool := getPool(rpools, ipool);
        pool := MPool.withdraw(pool, wamount);
        rpools := setPool(rpools, ipool, pool);
    } with (operations, rpools);

//RU --- От провайдера случайных чисел

    function onRandom(var rpools: t_rpools; const ipool: t_ipool; const random: nat): t_operations * t_rpools is block {
        var operations: t_operations := list [];
        var pool: t_pool := getPool(rpools, ipool);
        pool := MPool.onRandom(pool, random);
        rpools := setPool(rpools, ipool, pool);
    } with (operations, rpools);

//RU --- От фермы

    function onReward(var rpools: t_rpools; const ipool: t_ipool; const reward: nat): t_operations * t_rpools is block {
        var operations: t_operations := list [];
        var pool: t_pool := getPool(rpools, ipool);
        pool := MPool.onReward(pool, reward);
        rpools := setPool(rpools, ipool, pool);
    } with (operations, rpools);

//RU --- Чтение данных админами (Views)

    //RU Получить ID последнего созданного админом пула
    //RU
    //RU Обоснованно полагаем, что с одного адреса не создаются пулы в несколько потоков, поэтому этот метод позволяет получить
    //RU ID только что созданного админов нового пула. Если нет созданных админов пулов, будет возвращено -1
    function viewLastIPool(const rpools: t_rpools): int is
        case rpools.addr2ilast[Tezos.sender] of
        Some(ilast) -> int(ilast)
        | None -> -1
        end

    type t_pools_fullinfo is map(t_ipool, t_pool);//RU< Полная информация о пулах по их ID для админов

    //RU Получение карты с информацией о пулах (только активных)
    function viewPoolsFullInfo(const rpools: t_rpools): t_pools_fullinfo is block {
        function folded(var pools_fullinfo: t_pools_fullinfo; const ipool: t_ipool): t_pools_fullinfo is block {
            const pool: t_pool = getPool(rpools, ipool);
            pools_fullinfo := Map.add(ipool, pool, pools_fullinfo);
        } with pools_fullinfo;
        var pools_fullinfo: t_pools_fullinfo := map [];
        const ipools: t_ipools = getIPools(rpools); 
        pools_fullinfo := Set.fold(folded, ipools, pools_fullinfo);
    } with pools_fullinfo;

    //RU Получение пула (админом)
    function viewPoolFullInfo(const rpools: t_rpools; const ipool: t_ipool): t_pool is getPool(rpools, ipool);

//RU --- Чтение данных любыми пользователями (Views)

    type t_pools_info is map(t_ipool, MPool.t_pool_info);//RU< Информация о пулах (только активных) по их ID

    //RU Получение карты с информацией о пулах (только активных)
    function viewPoolsInfo(const rpools: t_rpools): t_pools_info is block {
        function folded(var pools_info: t_pools_info; const ipool: t_ipool): t_pools_info is block {
            const pool: t_pool = getPool(rpools, ipool);
            if MPool.isActive(pool) then pools_info := Map.add(ipool, pool.info, pools_info)
            else skip;
        } with pools_info;
        var pools_info: t_pools_info := map [];
        const ipools: t_ipools = getIPools(rpools); 
        pools_info := Set.fold(folded, ipools, pools_info);
    } with pools_info;

    //RU Получение пула (только активного)
    function viewPoolInfo(const rpools: t_rpools; const ipool: t_ipool): MPool.t_pool_info is block {
        const pool: t_pool = getPool(rpools, ipool);
        if MPool.isActive(pool) then skip
        else failwith(c_ERR_NOT_FOUND);
        const pool_info: MPool.t_pool_info = pool.info;
    } with pool_info;

}
#endif // !MPOOLS_INCLUDED

#if !MPOOLS_INCLUDED
#define MPOOLS_INCLUDED

#include "MPool.ligo"

//RU Модуль списка пулов ликвидности с периодическими розыгрышами вознаграждений
module MPools is {

    const cERR_UNPACK: string = "MPools/Unpack";//RU< Ошибка: Сбой распаковки
    const cERR_NOT_FOUND: string = "MPools/NotFound";//RU< Ошибка: Не найден пользователь для удаления

    //RU Получить пул по индексу
    //RU
    //RU Если пул не найден, будет возвращена ошибка cERR_NOT_FOUND
    function getPool(const s: t_storage; const ipool: t_ipool): t_pool is
        case s.rpools.pools[ipool] of
        Some(pool) -> pool
        | None -> (failwith(cERR_NOT_FOUND) : t_pool)
        end;

    //RU Обновить пул по индексу
    [@inline] function setPool(var s: t_storage; const ipool: t_ipool; const pool: t_pool): t_storage is block {
        s.rpools.pools[ipool] := pool;
    } with s;

    //RU Задать состояние пула
    //RU
    //RU Если убрать inline компилятор падает
    function setState(var s: t_storage; const ipool: t_ipool; const state: t_pool_state): t_storage is block {
        var pool: t_pool := getPool(s, ipool);
        MPool.mustManager(s, pool);//RU Проверка доступа к пулу
        pool := MPool.setState(pool, state);
        s := setPool(s, ipool, pool);
    } with s;

//RU --- Управление пулами

    //RU Создание нового пула //EN Create new pool
    function createPool(var s: t_storage; const opts: t_opts; const farm: t_farm; const random: t_random;
            const burn: option(t_token); const feeaddr: option(address)): t_storage is block {
        const pool: t_pool = MPool.create(opts, farm, random, burn, feeaddr);
        var rpools: t_rpools := s.rpools;
        const ipool: t_ipool = rpools.inext;//RU Индекс нового пула
        rpools.inext := ipool + 1n;
        rpools.pools := Big_map.add(ipool, pool, rpools.pools);
#if ENABLE_POOL_LASTIPOOL_VIEW
        rpools.addr2ilast := Big_map.update(Tezos.sender, Some(ipool), rpools.addr2ilast);//RU Обновляем последний индекс по адресу создателя пула
#endif // ENABLE_POOL_LASTIPOOL_VIEW
        s.rpools := rpools;
    } with s;

    //RU Приостановка пула //EN Pause pool
    function pausePool(const s: t_storage; const ipool: t_ipool): t_storage is setState(s, ipool, MPoolOpts.cSTATE_PAUSE);

    //RU Запуск пула (после паузы) //EN Play pool (after pause)
    function playPool(const s: t_storage; const ipool: t_ipool): t_storage is setState(s, ipool, MPoolOpts.cSTATE_ACTIVE);

    //RU Удаление пула (по окончании партии) //EN Remove pool (after game)
    function removePool(var s: t_storage; const ipool: t_ipool): t_storage is block {
        const pool: t_pool = getPool(s, ipool);
        MPool.mustManager(s, pool);//RU Проверка доступа к пулу
        if 0n = pool.game.balance then block {//RU Пул уже пуст, можно удалить прямо сейчас
            s.rpools.pools := Big_map.remove(ipool, s.rpools.pools);
        } else s := setState(s, ipool, MPoolOpts.cSTATE_REMOVE);
    } with s;

    //RU Редактирование пула (приостановленого) //EN Edit pool (paused)
    function editPool(var s: t_storage; const ipool: t_ipool;
            const optopts: option(t_opts); 
            const optfarm: option(t_farm);
            const optrandom: option(t_random);
            const optburn: option(t_token);
            const optfeeaddr: option(address)): t_storage is block {
        var pool: t_pool := getPool(s, ipool);
        MPool.mustManager(s, pool);//RU Проверка доступа к пулу
        pool := MPool.edit(pool, optopts, optfarm, optrandom, optburn, optfeeaddr);
        s := setPool(s, ipool, pool);
    } with s;

    //RU Смена менеджера пула
    function changeManager(var s: t_storage; const ipool: t_ipool; const newmanager: address): t_storage is block {
        var pool: t_pool := getPool(s, ipool);
        MPool.mustManager(s, pool);//RU Проверка доступа к пулу
        pool := MPool.forceChangeManager(pool, newmanager);
        s := setPool(s, ipool, pool);
    } with s;

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

//RU --- Чтение данных (Views)

#if ENABLE_POOL_LASTIPOOL_VIEW
    //RU Получить ID последнего созданного админом пула
    //RU
    //RU Обоснованно полагаем, что с одного адреса не создаются пулы в несколько потоков, поэтому этот метод позволяет получить
    //RU ID только что созданного админов нового пула. Если нет созданных админов пулов, будет возвращено -1
    function viewLastIPool(const s: t_storage): int is
        case s.rpools.addr2ilast[Tezos.sender] of
        Some(ilast) -> int(ilast)
        | None -> -1
        end
#endif // ENABLE_POOL_LASTIPOOL_VIEW

//RU --- Чтение данных любыми пользователями (Views)

#if ENABLE_POOL_VIEW
    //RU Получение пула (только активного)
    function viewPoolInfo(const s: t_storage; const ipool: t_ipool): t_pool_info is block {
        const pool: t_pool = getPool(s, ipool);
        if MPool.isActive(pool) then skip
        else failwith(cERR_NOT_FOUND);
        const pool_info: t_pool_info = record [
            opts = pool.opts;
            farm = pool.farm;
            game = pool.game;
        ];
    } with pool_info;
#endif // ENABLE_POOL_VIEW

}
#endif // !MPOOLS_INCLUDED

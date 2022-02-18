#if !MPOOLS_INCLUDED
#define MPOOLS_INCLUDED

#include "MPool.ligo"

//RU Модуль списка пулов ликвидности с периодическими розыгрышами вознаграждений
module MPools is {

    const cERR_NOT_FOUND: string = "MPools/NotFound";//RU< Ошибка: Не найден пул

    //RU Получить пул по индексу
    //RU
    //RU Если пул не найден, будет возвращена ошибка cERR_NOT_FOUND
    function getPool(const s: t_storage; const ipool: t_ipool): t_pool is
        case s.pools[ipool] of
        Some(pool) -> pool
        | None -> (failwith(cERR_NOT_FOUND) : t_pool)
        end;

    //RU Обновить пул по индексу
    [@inline] function setPool(var s: t_storage; const ipool: t_ipool; const pool: t_pool): t_storage is block {
        s.pools[ipool] := pool;
    } with s;

    //RU Получить текущие параметры пользователя в пуле
    //RU
    //RU Пользователь идентифицируется по Tezos.sender
    function getUser(const s: t_storage; const ipool: t_ipool): t_user is
        case s.users[(ipool, Tezos.sender)] of
        | Some(user) -> user
        | None -> record [//RU Параметры пользователя по умолчанию
            tsPool = Tezos.now;
            balance = 0n;
            tsBalance = Tezos.now;
            addWeight = 0n;
        ]
        end;

    //RU Обновить текущие параметры пользователя в пуле
    //RU
    //RU Пользователь идентифицируется по Tezos.sender. При нулевом сохраняемом балансе пользователь удаляется
    function setUser(var s: t_storage; const ipool: t_ipool; const user: t_user): t_storage is block {
        const ipooladdr: t_ipooladdr = (ipool, Tezos.sender);
        if user.balance > 0n then s.users[ipooladdr] := user //RU Обновление существующего
        else s.users := Big_map.remove(ipooladdr, s.users);//RU Удаляем пользователя
    } with s;

    //RU Задать состояние пула
    //RU
    //RU Если убрать inline компилятор падает
    function setPoolState(var s: t_storage; const ipool: t_ipool; const state: t_pool_state): t_storage is block {
        var pool: t_pool := getPool(s, ipool);
        MPool.mustManager(s, pool);//RU Проверка доступа к пулу
        pool := MPool.setState(pool, state);
        s := setPool(s, ipool, pool);
    } with s;

//RU --- Управление пулами

    //RU Создание нового пула //EN Create new pool
    function createPool(var s: t_storage; const pool_create: t_pool_create): t_storage is block {
        const pool: t_pool = MPool.create(pool_create);
        const ipool: t_ipool = s.inext;//RU Индекс нового пула
        s.inext := ipool + 1n;
        s.pools := Big_map.add(ipool, pool, s.pools);
    } with s;

    //RU Приостановка пула //EN Pause pool
    function pausePool(const s: t_storage; const ipool: t_ipool): t_storage is setPoolState(s, ipool, PoolStatePause);

    //RU Запуск пула (после паузы) //EN Play pool (after pause)
    function startPool(const s: t_storage; const ipool: t_ipool): t_storage is setPoolState(s, ipool, PoolStateActive);

    //RU Удаление пула (по окончании партии) //EN Remove pool (after game)
    function removePool(var s: t_storage; const ipool: t_ipool): t_storage is block {
        const pool: t_pool = getPool(s, ipool);
        MPool.mustManager(s, pool);//RU Проверка доступа к пулу
        if 0n = pool.balance then s.pools := Big_map.remove(ipool, s.pools);//RU Пул уже пуст, можно удалить прямо сейчас
        else s := setPoolState(s, ipool, PoolStateRemove);//RU Удалим, когда все заберут депозиты
    } with s;

    //RU Редактирование пула (приостановленого) //EN Edit pool (paused)
    function editPool(var s: t_storage; const ipool: t_ipool; const pool_edit: t_pool_edit): t_storage is block {
        var pool: t_pool := getPool(s, ipool);
        MPool.mustManager(s, pool);//RU Проверка доступа к пулу
        pool := MPool.edit(pool, pool_edit);
        s := setPool(s, ipool, pool);
    } with s;

#if ENABLE_POOL_MANAGER
    //RU Смена менеджера пула
    function changePoolManager(var s: t_storage; const ipool: t_ipool; const newmanager: address): t_storage is block {
        var pool: t_pool := getPool(s, ipool);
        MPool.mustManager(s, pool);//RU Проверка доступа к пулу
        pool := MPool.forceChangeManager(pool, newmanager);
        s := setPool(s, ipool, pool);
    } with s;
#endif // ENABLE_POOL_MANAGER

    //RU Удаление пула (по окончании партии) //EN Remove pool (after game)
    function setPoolWinner(var s: t_storage; const ipool: t_ipool): t_return is block {
        const pool: t_pool = getPool(s, ipool);
        //TODO
        s := setPool(s, ipool, pool);
    } with (cNO_OPERATIONS, s);

//RU --- Для пользователей пулов

    //RU Депозит в пул
    //RU \param damount Кол-во токенов для инвестирования в пул
    //EN Deposit to pool
    //RU \param damount Amount of tokens for invest to pool
    function deposit(var s: t_storage; const ipool: t_ipool; const damount: t_amount): t_return is block {
        var pool: t_pool := getPool(s, ipool);
        var user: t_user := getUser(s, ipool);
#if ENABLE_TRANSFER_SECURITY
        const doapprove: bool = True;
#else // ENABLE_TRANSFER_SECURITY
        const doapprove: bool = (not Big_map.mem(pool.farm.addr, s.approved));
#endif // else ENABLE_TRANSFER_SECURITY
        const r: t_pool * t_user * t_operations = MPool.deposit(ipool, pool, user, damount, doapprove);
#if !ENABLE_TRANSFER_SECURITY
        s.approved[pool.farm.addr] := unit;
#endif // !ENABLE_TRANSFER_SECURITY
        s := setPool(s, ipool, r.0);
        s := setUser(s, ipool, r.1);
    } with (r.2, s);

    //RU Извлечение из пула
    //RU
    //RU 0n == wamount - извлечение всего депозита из пула
    //EN Withdraw from pool
    //EN
    //EN 0n == wamount - withdraw all deposit from pool
    function withdraw(var s: t_storage; const ipool: t_ipool; const wamount: t_amount): t_return is block {
        var pool: t_pool := getPool(s, ipool);
        var user: t_user := getUser(s, ipool);
        const r: t_pool * t_user * t_operations = MPool.withdraw(ipool, pool, user, wamount);
        if (0n = pool.balance) and (PoolStateRemove = pool.state) then //RU Пул на удаление, забрали последний депозит
            s.pools := Big_map.remove(ipool, s.pools);//RU Удаляем пул
        else s := setPool(s, ipool, r.0);
        s := setUser(s, ipool, r.1);
    } with (r.2, s);

    //RU Колбек провайдера случайных чисел
    function onRandom(var s: t_storage; const ipool: t_ipool; const random: t_random): t_return is block {
        var pool: t_pool := getPool(s, ipool);
        pool := MPool.onRandom(ipool, pool, random);
        s := setPool(s, ipool, pool);
        var operations: t_operations := cNO_OPERATIONS;
    } with (operations, s);

    //RU Колбек самого себя после запроса вознаграждения с фермы 
    function afterReward(var s: t_storage; const ipool: t_ipool): t_return is block {
        var pool: t_pool := getPool(s, ipool);
        pool := MPool.afterReward(ipool, pool);
        s := setPool(s, ipool, pool);
        var operations: t_operations := cNO_OPERATIONS;
    } with (operations, s);

    //RU Колбек самого себя после обмена токенов вознаграждения на токены для сжигания
    function afterChangeReward(var s: t_storage; const ipool: t_ipool): t_return is block {
        var pool: t_pool := getPool(s, ipool);
        pool := MPool.afterChangeReward(ipool, pool);
        s := setPool(s, ipool, pool);
        var operations: t_operations := cNO_OPERATIONS;
    } with (operations, s);

//RU --- Чтение данных любыми пользователями (Views)

#if ENABLE_POOL_VIEW
    //RU Получение основной информации о пуле
    function viewPoolInfo(const s: t_storage; const ipool: t_ipool): t_pool_info is block {
        const pool: t_pool = getPool(s, ipool);
        const pool_info: t_pool_info = record [
            opts = pool.opts;
            farm = pool.farm;
            state = pool.state;
            balance = pool.balance;
            count = pool.count;
            game = pool.game;
        ];
    } with pool_info;
#endif // ENABLE_POOL_VIEW

#if ENABLE_BALANCE_VIEW
    //RU Получение баланса пользователя в пуле
    function viewBalance(const s: t_storage; const ipool: t_ipool): nat is block {
        const user: t_user = getUser(s, ipool);
    } with user.balance;
#endif // ENABLE_BALANCE_VIEW

}
#endif // !MPOOLS_INCLUDED

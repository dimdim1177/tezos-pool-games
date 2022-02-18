#if !MGAME_INCLUDED
#define MGAME_INCLUDED

//RU Модуль партии розыгрыша вознаграждения
module MPoolGame is {

    //RU Параметры партии при создании пула в активном илии приостановленном состоянии
    function create(const state: t_game_state; const seconds: nat): t_game is block {
        const game: t_game = record [
            state = state;
            tsBeg = Tezos.now;
            tsEnd = Tezos.now + int(seconds);
            weight = 0n;
            winWeight = 0n;
        ];
    } with game;

    //RU Начало партии
    function activateIfNeed(var pool: t_pool): t_pool is block {
        if GameStateActivating = pool.game.state then block {//RU Нужно запустить партию
            pool.game.state := GameStateActive;
            pool.game.tsBeg := Tezos.now;
            const gameSeconds: nat = pool.opts.gameSeconds;
            pool.game.tsEnd := Tezos.now + int(gameSeconds);
            //RU Вес партии заполняем так, как будто все пользователи пробудут всю партию, при изменениях вес будет корректироваться
            case pool.opts.algo of
            | AlgoTime -> pool.game.weight := pool.count * gameSeconds
            | AlgoTimeVol -> pool.game.weight := pool.balance * gameSeconds
            | AlgoEqual -> pool.game.weight := pool.count
            end;
            pool.randomFuture := False;//RU Пока не заказывали случайное число
        } else skip;
    } with pool;

    //RU Пополнен депозит пользователем
    function onDeposit(var pool: t_pool; var user: t_user; const damount: t_amount): t_pool * t_user is block {
        //RU Обновления веса розыгрыша и пользователя только если сейчас идет партия
        const tsEnd: timestamp = pool.game.tsEnd;
        const goodMin: bool = ((user.tsPool + int(pool.opts.minSeconds)) > tsEnd);//RU Вступил в пул с соблюдением минимума по секундам
        if (GameStateActive = pool.game.state) and (goodMin) then block {
            case pool.opts.algo of
            | AlgoTime -> block {
                //RU Депозит в этом алгоритме влияет на вес только при внесении
                if 0n = user.balance then pool.game.weight := pool.game.weight + abs(tsEnd - Tezos.now)
                else skip;
            }
            | AlgoTimeVol -> block {
                const tsBalance: timestamp = user.tsBalance;
                const tsBeg: timestamp = pool.game.tsBeg;
                var addWeight: t_weight := user.addWeight;
                if tsBalance <= tsBeg then block {//RU Предыдущий баланс был внесен до начала партии
                //RU Сохраняем вес от начала партии то текущего момента
                    addWeight := abs(Tezos.now - tsBeg) * user.balance;
                } else block {//RU Предыдущее изменение было во время партии
                    //RU Добавляем в сохранение вес от прошлого изменения до текущего момента
                    addWeight := addWeight + abs(Tezos.now - tsBalance) * user.balance;
                };
                user.addWeight := addWeight;
                //RU Добавляем к весу партии вес внесенного от текущего момента до конца партии
                pool.game.weight := pool.game.weight + abs(tsEnd - Tezos.now) * damount;
            }
            | AlgoEqual -> block {
                //RU Депозит в этом алгоритме влияет на вес только при внесении
                if 0n = user.balance then pool.game.weight := pool.game.weight + 1n
                else skip;
            }
            end;
        } else skip;
    } with (pool, user);

    //RU Извлечен депозит пользователем
    function onWithdraw(var pool: t_pool; var user: t_user; const wamount: t_amount): t_pool * t_user is block {
        //RU Обновления веса розыгрыша и пользователя только если сейчас идет партия
        if GameStateActive = pool.game.state then block {//RU Партия активна, значит Tezos.now < tsEnd
            const tsEnd: timestamp = pool.game.tsEnd;
            const goodMin: bool = ((user.tsPool + int(pool.opts.minSeconds)) > tsEnd);//RU Вступил в пул с соблюдением минимума по секундам
            if (wamount = user.balance) and (goodMin) then block {//RU Полное извлечение, удаление участника
                //RU Для вычисления весов моментом внесения баланса является максимум из момента внесения и начала партии
                const tsBeg: timestamp = pool.game.tsBeg;
                case pool.opts.algo of
                | AlgoTime -> block {
                    var tsPool: timestamp := user.tsPool;
                    if tsPool < tsBeg then tsPool := tsBeg else skip;
                    pool.game.weight := abs(pool.game.weight - abs(tsEnd - tsPool))
                }
                | AlgoTimeVol -> block {
                    const tsBalance: timestamp = user.tsBalance;
                    if tsBalance > tsBeg then block {//RU Последнее изменение баланса во время партии
                        //RU Учитывается addWeight, вычитаем его из веса партии
                        pool.game.weight := abs(pool.game.weight - user.addWeight);
                        //RU Также вычитаем вес участника от последнего изменения баланса до конца партии
                        pool.game.weight := abs(pool.game.weight - abs(tsEnd - tsBalance) * wamount);
                    } else block {//RU Участник внес депозит до партии и не менял баланс во время партии
                        pool.game.weight := abs(pool.game.weight - abs(tsEnd - tsBeg) * wamount);//RU Вычитаем вес за всю партию
                    };
                }
                | AlgoEqual -> pool.game.weight := abs(pool.game.weight - 1n)
                end;
            } else block {//RU Частичное извлечение депозита
                if (AlgoTimeVol = pool.opts.algo) and (goodMin) then block {
                    const tsBalance: timestamp = user.tsBalance;
                    const tsBeg: timestamp = pool.game.tsBeg;
                    const tsEnd: timestamp = pool.game.tsEnd;
                    var addWeight: t_weight := user.addWeight;
                    if tsBalance <= tsBeg then block {//RU Предыдущий баланс был внесен до начала партии
                    //RU Сохраняем вес от начала партии то текущего момента
                        addWeight := abs(Tezos.now - tsBeg) * user.balance;
                    } else block {//RU Предыдущее изменение было во время партии
                        //RU Добавляем в сохранение вес от прошлого изменения до текущего момента
                        addWeight := addWeight + abs(Tezos.now - tsBalance) * user.balance;
                    };
                    user.addWeight := addWeight;
                    //RU Вычитаем из веса партии вес извлеченного от текущего момента до конца партии
                    pool.game.weight := abs(pool.game.weight - abs(tsEnd - Tezos.now) * wamount);
                } else skip;//RU В других алгоритмах частичное извлечение не влияет на вес
            };
        } else skip;
    } with (pool, user);

    //RU Проверяем, не закончилось ли время розыгрыша
    function checkEnd(var pool: t_pool): t_pool is block {
        if (GameStateActive = pool.game.state) and (Tezos.now >= pool.game.tsEnd) then block { //RU Если партия активна и время вышло
            if pool.game.weight > 0n then block {//RU Идет какой-то розыгрыш
                if pool.randomFuture then pool.game.state := GameStateWaitRandom; //RU Заказывали случайное число, ждем его
                else {//RU Раз не заказывали случайное число, один реальный участник
                    pool.game.winWeight := pool.game.weight; //RU Обязательно попадем в него по суммарному весу
                    pool.game.state := GameStateWaitWinner;//RU Списка пользователей у нас нет, поэтому все равно нужна его загрузка извне
                };
            } else {//RU Нет реального розыгрыша, некому разыгрывать
                if PoolStateActive = pool.state then pool.game.state := GameStateActivating //RU Пул активен, нужно запустить новую партию
                else pool.game.state := GameStatePause;//RU Пул приостановлен или на удаление, приостанавливаем партии
            };
        } else skip;
    } with pool;

}
#endif // !MGAME_INCLUDED

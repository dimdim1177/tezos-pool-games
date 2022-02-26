#if !MGAME_INCLUDED
#define MGAME_INCLUDED

///RU Модуль партии розыгрыша вознаграждения
///EN The module of the reward drawing party
module MPoolGame is {

    ///RU Параметры партии при создании пула в активном илии приостановленном состоянии
    ///EN Batch parameters when creating a pool in an active or suspended state
    function create(const state: t_game_state; const seconds: nat): t_game is block {
        const game: t_game = record [
            state = state;
            tsBeg = Tezos.now;
            tsEnd = Tezos.now + int(seconds);
            weight = 0n;
            winWeight = 0n;
            winner = cZERO_ADDRESS;
        ];
    } with game;

    ///RU Начать новую партию
    ///EN Start a new batch
    function newGame(var pool: t_pool): t_pool is block {
        pool.game.state := GameStateActive;
        pool.game.tsBeg := Tezos.now;
        const gameSeconds: nat = pool.opts.gameSeconds;
        pool.game.tsEnd := Tezos.now + int(gameSeconds);
        //RU Вес партии заполняем так, как будто все пользователи пробудут всю партию, при изменениях вес будет корректироваться
        //EN We fill in the weight of the batch as if all users will stay the whole batch, with changes the weight will be adjusted
        case pool.opts.algo of [
        | AlgoTime -> pool.game.weight := pool.count * gameSeconds
        | AlgoTimeVol -> pool.game.weight := pool.balance * gameSeconds
        | AlgoEqual -> pool.game.weight := pool.count
        ];
        pool.randomFuture := False;//RU Пока не запрашивали случайное число //EN No random number has been requested yet
    } with pool;

    ///RU Пополнен депозит пользователем
    ///EN The deposit has been replenished by the user
    function onDeposit(var pool: t_pool; var user: t_user; const damount: MToken.t_amount): t_pool * t_user is block {
        //RU Обновления веса розыгрыша и пользователя только если сейчас идет партия
        //EN Updates of the draw weight and the user only if there is a party going on now
        const tsEnd: timestamp = pool.game.tsEnd;
        //RU Вступил в пул с соблюдением минимума по секундам
        //EN Joined the pool with a minimum of seconds
        const goodMin: bool = ((user.tsPool + int(pool.opts.minSeconds)) > tsEnd);
        if (GameStateActive = pool.game.state) and (goodMin) then block {
            case pool.opts.algo of [
            | AlgoTime -> block {
                //RU Депозит в этом алгоритме влияет на вес только при внесении
                //EN The deposit in this algorithm affects the weight only when depositing
                if 0n = user.balance then pool.game.weight := pool.game.weight + abs(tsEnd - Tezos.now)
                else skip;
            }
            | AlgoTimeVol -> block {
                const tsBalance: timestamp = user.tsBalance;
                const tsBeg: timestamp = pool.game.tsBeg;
                var addWeight: t_weight := user.addWeight;
                if tsBalance <= tsBeg then block {
                    //RU Предыдущий баланс был внесен до начала партии
                    //RU Сохраняем вес от начала партии то текущего момента
                    //EN The previous balance was entered before the start of the party
                    //EN We keep the weight from the beginning of the batch to the current moment
                    addWeight := abs(Tezos.now - tsBeg) * user.balance;
                } else block {
                    //RU Предыдущее изменение было во время партии
                    //RU Добавляем в сохранение вес от прошлого изменения до текущего момента
                    //EN The previous change was during the party
                    //EN Adding the weight from the last change to the current moment to the save
                    addWeight := addWeight + abs(Tezos.now - tsBalance) * user.balance;
                };
                user.addWeight := addWeight;
                //RU Добавляем к весу партии вес внесенного от текущего момента до конца партии
                //EN Add to the weight of the batch the weight of the input from the current moment to the end of the batch
                pool.game.weight := pool.game.weight + abs(tsEnd - Tezos.now) * damount;
            }
            | AlgoEqual -> block {
                //RU Депозит в этом алгоритме влияет на вес только при внесении
                //EN The deposit in this algorithm affects the weight only when depositing
                if 0n = user.balance then pool.game.weight := pool.game.weight + 1n
                else skip;
            }
            ];
        } else skip;
    } with (pool, user);

    ///RU Извлечен депозит пользователем
    ///EN The deposit was extracted by the user
    function onWithdraw(var pool: t_pool; var user: t_user; const wamount: MToken.t_amount): t_pool * t_user is block {
        //RU Обновления веса розыгрыша и пользователя только если сейчас идет партия
        //EN Updates of the draw weight and the user only if there is a party going on now
        if GameStateActive = pool.game.state then block {
            //RU Партия активна, значит Tezos.now < tsEnd
            //EN The party is active, so Tezos.now < tsEnd
            const tsEnd: timestamp = pool.game.tsEnd;
            //RU Вступил в пул с соблюдением минимума по секундам
            //EN Joined the pool with a minimum of seconds
            const goodMin: bool = ((user.tsPool + int(pool.opts.minSeconds)) > tsEnd);
            if (wamount = user.balance) and (goodMin) then block {
                //RU Полное извлечение, удаление участника
                //RU Для вычисления весов моментом внесения баланса является максимум из момента внесения и начала партии
                //EN Full extraction, removal of the participant
                //EN To calculate the weights, the moment of making the balance is the maximum from the moment of making and the beginning of the batch
                const tsBeg: timestamp = pool.game.tsBeg;
                case pool.opts.algo of [
                | AlgoTime -> block {
                    var tsPool: timestamp := user.tsPool;
                    if tsPool < tsBeg then tsPool := tsBeg else skip;
                    pool.game.weight := abs(pool.game.weight - abs(tsEnd - tsPool))
                }
                | AlgoTimeVol -> block {
                    const tsBalance: timestamp = user.tsBalance;
                    if tsBalance > tsBeg then block {
                        //RU Последнее изменение баланса во время партии
                        //RU Учитывается addWeight, вычитаем его из веса партии
                        //EN Last balance change during the party
                        //EN addWeight is taken into account, we subtract it from the weight of the batch
                        pool.game.weight := abs(pool.game.weight - user.addWeight);
                        //RU Также вычитаем вес участника от последнего изменения баланса до конца партии
                        //EN We also subtract the participant's weight from the last balance change to the end of the game
                        pool.game.weight := abs(pool.game.weight - abs(tsEnd - tsBalance) * wamount);
                    } else block {
                        //RU Участник внес депозит до партии и не менял баланс во время партии
                        //EN The participant made a deposit before the game and did not change the balance during the game
                        pool.game.weight := abs(pool.game.weight - abs(tsEnd - tsBeg) * wamount);//RU Вычитаем вес за всю партию //EN Subtract the weight for the whole batch
                    };
                }
                | AlgoEqual -> pool.game.weight := abs(pool.game.weight - 1n)
                ];
            } else block {//RU Частичное извлечение депозита //EN Partial withdrawal of the deposit
                if (AlgoTimeVol = pool.opts.algo) and (goodMin) then block {
                    const tsBalance: timestamp = user.tsBalance;
                    const tsBeg: timestamp = pool.game.tsBeg;
                    const tsEnd: timestamp = pool.game.tsEnd;
                    var addWeight: t_weight := user.addWeight;
                    if tsBalance <= tsBeg then block {
                        //RU Предыдущий баланс был внесен до начала партии
                        //RU Сохраняем вес от начала партии то текущего момента
                        //EN The previous balance was entered before the start of the party
                        //EN We keep the weight from the beginning of the batch to the current moment
                        addWeight := abs(Tezos.now - tsBeg) * user.balance;
                    } else block {
                        //RU Предыдущее изменение было во время партии
                        //RU Добавляем в сохранение вес от прошлого изменения до текущего момента
                        //EN The previous change was during the party
                        //EN Adding the weight from the last change to the current moment to the save
                        addWeight := addWeight + abs(Tezos.now - tsBalance) * user.balance;
                    };
                    user.addWeight := addWeight;
                    //RU Вычитаем из веса партии вес извлеченного от текущего момента до конца партии
                    //EN Subtract from the weight of the batch the weight extracted from the current moment to the end of the batch
                    pool.game.weight := abs(pool.game.weight - abs(tsEnd - Tezos.now) * wamount);
                } else skip;//RU В других алгоритмах частичное извлечение не влияет на вес //EN In other algorithms, partial extraction does not affect the weight
            };
        } else skip;
    } with (pool, user);

    ///RU Проверяем, не закончилось ли время розыгрыша
    ///EN We check if the time of the draw has not ended
    function checkComplete(var pool: t_pool): t_pool is block {
        if (GameStateActive = pool.game.state) and (Tezos.now >= pool.game.tsEnd) then block { 
            //RU Если партия активна и время вышло
            //EN If the party is active and the time is up
            if pool.game.weight > 0n then block {
                //RU Есть фактический розыгрыш вознаграждения
                //EN There is an actual reward draw
                if pool.randomFuture then block {
                    //RU Заказывали случайное число, нужно будет его получить позже, пока помечаем партию законченной
                    //EN We ordered a random number, we will need to get it later, while we mark the batch finished
                    pool.game.state := GameStateComplete;
                } else block {
                    //RU Раз не заказывали случайное число, один реальный участник, можно сразу переходить к ожиданию победителя
                    //EN If you didn't order a random number, one real participant, you can immediately proceed to waiting for the winner
                    pool.game.winWeight := pool.game.weight;//RU Обязательно попадем в него по суммарному весу //EN We will definitely get into it by total weight
                    pool.game.state := GameStateWaitWinner;//RU Списка пользователей у нас нет, поэтому все равно нужна его загрузка извне //EN We don't have a list of users, so we still need to download it from the outside
                };
            } else {
                //RU Нет реального розыгрыша вознаграждения, некому разыгрывать
                //EN There is no real prize draw, there is no one to play
                if PoolStateActive = pool.state then pool.game.state := GameStateActivating //RU Пул активен, нужно запустить новую партию //EN The pool is active, you need to start a new batch
                else pool.game.state := GameStatePause;//RU Пул приостановлен или на удаление, приостанавливаем партии //EN The pool is suspended or for deletion, we suspend the parties
            };
        } else skip;
    } with pool;

}
#endif // !MGAME_INCLUDED

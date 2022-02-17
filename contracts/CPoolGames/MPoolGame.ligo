#if !MGAME_INCLUDED
#define MGAME_INCLUDED

//RU Модуль партии розыгрыша вознаграждения
module MPoolGame is {

    //RU Параметры партии при создании пула
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
    function activateGame(const ipool: t_ipool; var pool: t_pool; var operations: t_operations): t_pool * t_operations is block {
        pool.game.state := GameStateActive;
        pool.game.tsBeg := Tezos.now;
        const gameSeconds: nat = pool.opts.gameSeconds;
        pool.game.tsEnd := Tezos.now + int(gameSeconds);
        case pool.opts.algo of //RU Вес партии заполняем так, как будто все пользователи пробудут всю партию
        | AlgoTime -> pool.game.weight := pool.count * gameSeconds
        | AlgoTimeVol -> pool.game.weight := pool.balance * gameSeconds
        | AlgoEqual -> pool.game.weight := pool.count
        end;
        if pool.count > 1n then block {//RU Больше 1 участника
            operations := MRandom.create(pool.randomSource, pool.game.tsEnd, ipool) # operations;//RU Заказываем случайное число
            pool.randomFuture := True;//RU Ждем случайное число
        } else pool.randomFuture := False;
    } with (pool, operations);

    //RU Проверяем, не закончилась ли игра
    function checkGameComplete(var pool: t_pool): t_pool is block {
        if (GameStateActive = pool.game.state) and (Tezos.now >= pool.game.tsEnd) then block { //RU Если партия активна и время вышло
            if pool.game.weight > 0n then block {//RU Идет какой-то розыгрыш
                if pool.randomFuture then skip //RU Заказывали случайное число, ждем его
                else {//RU Раз не заказывали случайное число, один реальный участник
                    pool.game.winWeight := pool.game.weight; //RU Обязательно попадем в него по суммарному весу
                    pool.game.state := GameStateWaitWinner;//RU Списка пользователей у нас нет, поэтому все равно нужна его загрузка извне
                };
            } else {
                if PoolStateActive = pool.state then pool.game.state := GameStateActivating //RU Пул активен, нужно запустить новую партию
                else pool.game.state := GameStatePause;//RU Пул приостановлен или на удаление, приостанавливаем партии
            };
        } else skip;
    } with pool;

}
#endif // !MGAME_INCLUDED

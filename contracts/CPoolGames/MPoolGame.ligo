#if !MGAME_INCLUDED
#define MGAME_INCLUDED

//RU Модуль партии розыгрыша вознаграждения
module MPoolGame is {

//RU --- Состояния партии
//EN --- States of game
    [@inline] const cSTATE_ACTIVE: t_game_state = 0n;//RU< Идет партия (по умолчанию)
    [@inline] const cSTATE_WAIT_RANDOM: t_game_state = 1n;//RU< Партия закончена по времени, но пока ожидаем случайное число для определения победителя
    [@inline] const cSTATE_WAIT_REWARD: t_game_state = 2n;//RU< Партия закончена по времени, но пока ожидаем перечисление вознаграждения из фермы
    [@inline] const cSTATE_PAUSE: t_game_state = 0n;//RU< Партии приостановлены (предыдущая завершена, но запуск следующей заблокирован)

    const cSTATEs: set(t_game_state) = set [cSTATE_ACTIVE; cSTATE_WAIT_RANDOM; cSTATE_WAIT_REWARD; cSTATE_PAUSE];//RU< Все состояния

    //RU Структура партии по умолчанию
    function create(const state: t_game_state; const seconds: int): t_game is block {
        const game: t_game = record [
            balance = 0n;
            count = 0n;
            state = state;
            tsBeg = Tezos.now;
            tsEnd = Tezos.now + seconds;
            weight = 0n;
        ];
    } with game;

}
#endif // !MGAME_INCLUDED

#if !MGAME_INCLUDED
#define MGAME_INCLUDED

//RU Модуль партии розыгрыша вознаграждения
module MGame is {

    type t_state is nat;//RU< Состояние партии

//RU --- Состояния партии
//EN --- States of game
    const c_STATE_IDLE: t_state = 0n;//RU< Нет партии (предыдущая завершена, но запуск следующей заблокирован)
    const c_STATE_GAME: t_state = 1n;//RU< Идет партия, пользователи могут вносить депозиты
    const c_STATE_WAIT_RANDOM: t_state = 2n;//RU< Партия закончена по времени, но пока ожидаем случайное число для определения победителя
    const c_STATE_WAIT_REWARD: t_state = 3n;//RU< Партия закончена по времени, но пока ожидаем перечисление вознаграждения из фермы

    const c_STATEs: set(t_state) = set [c_STATE_IDLE; c_STATE_GAME; c_STATE_WAIT_RANDOM; c_STATE_WAIT_REWARD];//RU< Все состояния

    //RU Параметры партии
    type t_game is [@layout:comb] record [
        state: t_state;//RU< Состояние партии
        tsBeg: timestamp;//RU< Начало партии
        tsEnd: timestamp;//RU< Конец партии
    ];

    //RU Запись игры в состоянии IDLE
    [@inline] function idleGame(const _u: unit): t_game is block {
        const game: t_game = record [
            state = c_STATE_IDLE;
            tsBeg = Tezos.now;
            tsEnd = Tezos.now;
        ];
    } with game;
}
#endif // MGAME_INCLUDED

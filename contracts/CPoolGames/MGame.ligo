#if !MGAME_INCLUDED
#define MGAME_INCLUDED

//RU Модуль партии розыгрыша вознаграждения
module MGame is {

//RU --- Состояния партии
//EN --- States of game
    const c_STATE_IDLE:        nat = 0n;//RU< Нет партии (предыдущая завершена, но запуск следующей заблокирован)
    const c_STATE_GAME:        nat = 1n;//RU< Идет партия, пользователи могут вносить депозиты
    const c_STATE_WAIT_RANDOM: nat = 2n;//RU< Партия закончена по времени, но пока ожидаем случайное число для определения победителя
    const c_STATE_WAIT_REWARD: nat = 3n;//RU< Партия закончена по времени, но пока ожидаем перечисление вознаграждения из фермы

    const c_STATEs: set(nat) = set [c_STATE_IDLE; c_STATE_GAME; c_STATE_WAIT_RANDOM; c_STATE_WAIT_REWARD];//RU< Все состояния

    //RU Параметры партии
    type t_game is [@layout:comb] record [
        state: nat;//RU< Состояние партии
        tsBeg: timestamp;//RU< Начало партии
        tsEnd: timestamp;//RU< Конец партии
    ];
}
#endif // MGAME_INCLUDED

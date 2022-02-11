#if !MGAME_INCLUDED
#define MGAME_INCLUDED

//RU Модуль партии розыгрыша вознаграждения
module MPoolGame is {

    type t_game_state is nat;//RU< Состояние партии

    //RU Вес для определения вероятности победы
    //RU
    //RU Вероятность выигрыша пользователя пропорциональна отношению веса пользователя к весу всей партии
    type t_weight is nat;

//RU --- Состояния партии
//EN --- States of game
    const c_STATE_ACTIVE: t_game_state = 0n;//RU< Идет партия (по умолчанию)
    const c_STATE_WAIT_RANDOM: t_game_state = 1n;//RU< Партия закончена по времени, но пока ожидаем случайное число для определения победителя
    const c_STATE_WAIT_REWARD: t_game_state = 2n;//RU< Партия закончена по времени, но пока ожидаем перечисление вознаграждения из фермы
    const c_STATE_PAUSE: t_game_state = 0n;//RU< Партии приостановлены (предыдущая завершена, но запуск следующей заблокирован)

    const c_STATEs: set(t_game_state) = set [c_STATE_ACTIVE; c_STATE_WAIT_RANDOM; c_STATE_WAIT_REWARD; c_STATE_PAUSE];//RU< Все состояния

    //RU Параметры партии
    type t_game is [@layout:comb] record [
        balance: MFarm.t_amount;//RU< Сколько токенов фермы инвестировано в пул в настоящий момент
        count: nat;//RU< Кол-во пользователей в пуле
        state: t_game_state;//RU< Состояние партии
        tsBeg: timestamp;//RU< Начало партии
        tsEnd: timestamp;//RU< Конец партии
        weight: t_weight;//RU< Суммарный вес всех участников партии
    ];

    //RU Структура партии по умолчанию
    [@inline] function create(const state: t_game_state; const seconds: int): t_game is block {
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

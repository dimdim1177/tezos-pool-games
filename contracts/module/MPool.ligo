#if !MPOOL_INCLUDED
#define MPOOL_INCLUDED

//RU Модуль пула ликвидности с периодическими розыгрышами вознаграждений
module MPool is {
//RU --- Стандарты токенов //EN --- Token standards
    const c_FA1: nat = 1n;//< FA1.2
    const c_FA2: nat = 1n;//< FA2
    const c_FAs: set(nat) = set [c_FA1; c_FA2];//RU< Все стандарты

//RU --- Интерфейсы ферм //EN --- Farm interfaces
    const c_INTERFACE_CRUNCH: nat = 1n;
    
    const c_INTERFACEs: set(nat) = set [c_INTERFACE_CRUNCH];//RU< Все интерфейсы

//RU --- Режимы определения победителя
//EN --- Mode of calculate winner
    //RU< Вероятность выигрыша пропорционально суммарному времени в игре
    const c_MODE_TIME:    nat = 1n;
    
    //RU< Вероятность выигрыша пропорционально сумме произведений объема на время в игре
    const c_MODE_TIMEVOL: nat = 2n;

    const c_MODEs: set(nat) = set [c_MODE_TIME; c_MODE_TIMEVOL];//RU< Все режимы

//RU --- Состояния партии
//EN --- States of game
    const c_STATE_IDLE:        nat = 0n;//RU< Нет партии
    const c_STATE_GAME:        nat = 1n;//RU< Идет партия
    const c_STATE_WAIT_RANDOM: nat = 2n;//RU< Партия закончена, ожидаем случайное число для определения победителя
    const c_STATE_WAIT_REWARD: nat = 3n;//RU< Партия закончена, ожидаем перечисление вознаграждения из фермы

    const c_STATEs: set(nat) = set [c_STATE_IDLE; c_STATE_GAME; c_STATE_WAIT_RANDOM; c_STATE_WAIT_REWARD];//RU< Все состояния

    type t_token is record [
        addr: address;//RU< Токен пула
        id: nat;//RU< ID токена
        fa: nat;//RU< Стандарт FA токена, см. c_FA...
    ];

    //RU Параметры фермы
    type t_farm is record [
        addr: address;//RU< Адрес фермы
        id: nat;//RU< ID фермы
        farmToken: t_token;//RU< Токен фермы
        rewardToken: t_token;//RU< Токен вознаграждения
        interface: nat;//RU< Интерфейс фермы, см. c_INTERFACE...
    ];

    //RU Параметры партии
    type t_game is record [
        //RU Режим определения победителя партии, см. c_MODE...
        //EN Mode of calculate winner of game, см. c_MODE...
        mode: nat;
        seconds: nat;//RU< Длительность партии в секундах
        state: nat;//RU< Состояние партии
        tsBeg: timestamp;//RU< Начало партии
        tsEnd: timestamp;//RU< Конец партии
    ];

    //RU Параметры участника
    type t_user is record [
        weight: nat;//RU< Ранее накопленный вес для определения вероятности победы
        amount: nat;//RU< Сколько токенов фермы инвестировано в пул
        tsAmount: timestamp;//RU< Когда было получены текущие токены
    ];

    //RU< Участники пула
    type t_users is record [
        minI: nat;//RU< Минимальный индекс пользователя
        maxI: nat;//RU< Максимальный индекс пользователя
        addr2i: big_map(address * nat);//RU< Определение индекса пользователя по адресу
        i2user: big_map(nat * t_user);//RU< Параметры пользователя по индексу
    ];

    //RU Пул для игр
    type t_pool is record [
        paused: bool;//RU< Приостановка пула
        farm: t_farm;//RU< Ферма пула
        game: t_game;//RU< Текущая партия
        users: t_users;//RU< Участники пула
    ];
    
}
#endif // MPOOL_INCLUDED

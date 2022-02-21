#if !TYPES_INCLUDED
#define TYPES_INCLUDED

#include "config.ligo"
#include "../include/consts.ligo"
#include "../module/MOwner.ligo"
#include "../module/MAdmin.ligo"
#include "../module/MAdmins.ligo"
#include "../module/MManager.ligo"
#include "../module/MFarm.ligo"
#include "../module/MRandom.ligo"
#include "../module/MToken.ligo"
#include "../module/MQuipuswap.ligo"

//RU Типы для хранилища контракта
//EN Types for contract storage

//RU Транзитные объявления типов из модулей
#if ENABLE_OWNER
type t_owner is MOwner.t_owner;
#endif // ENABLE_OWNER
#if ENABLE_ADMIN
type t_admin is MAdmin.t_admin;
#endif // ENABLE_ADMIN
#if ENABLE_ADMINS
type t_admin is MAdmins.t_admin;
type t_admins is MAdmins.t_admins;
#endif // ENABLE_ADMINS
type t_amount is MToken.t_amount;
type t_farm is MFarm.t_farm;
type t_random_source is MRandom.t_random_source;
type t_random is MRandom.t_random;
type t_ts_iobj is MRandom.t_ts_iobj;
type t_iobj_random is MRandom.t_iobj_random;
type t_token is MToken.t_token;
type t_swap is MQuipuswap.t_swap;

//RU Состояние пула
type t_pool_state is
//RU Пул активен
//RU
//RU Периодически разыгрывается вознаграждение для всех участников пула
| PoolStateActive
//RU Пул приостановлен
//RU
//RU Если партия активна, она продолжается до завершения, но следующая не будет запущена.
| PoolStatePause
//RU Пул на удаление
//RU
//RU Если партия активна, она продолжается до завершения. По окончании партии, когда пользователи
//RU заберут все депозиты, пул будет удален во время списания последнего депозита.
//RU Если же пул уже пуст на момент вызова, он будет удален немедленно
| PoolStateRemove
;

//RU Алгоритм розыгрышей пула
//RU
//RU Кроме кода алгоритма используются дополнительные настройки minDeposit, maxDeposit, minSeconds
type t_algo is
//RU Вероятность выигрыша пропорциональна суммарному времени в игре
//RU
//RU Время вступления каждого пользователя в розыгрыш фиксируется. В конце партии суммируются все времена пребывания в партии 
//RU всех пользователей (и эта сумма принимается за вероятность 1.0). Далее случайное число нормируется к этой сумме и выбирается
//RU пользователь на основании этого числа. В итоге вероятность выигрыша пользователя пропорциональна его времени нахождения в 
//RU пуле.
//RU Обнуление депозита удаляет пользователя из партии, соответственно удаляет его время нахождения в пуле, это делает 
//RU бессмысленным выход и повторный вход в партию.
//RU Этот алгоритм более интересен пользователям с малыми депозитами, вероятность выигрыша не зависит от размера депозита, поэтому 
//RU можно вложить мало, а выиграть много.
| AlgoTime
//RU Вероятность выигрыша пропорциональна сумме произведений объема на время в игре
//RU
//RU Время вступления каждого пользователя в розыгрыш и его депозит на этот момент фиксируется. При пополнении депозита, предыдущий 
//RU депозит умножается на его время присутствия в пуле в секундах и эта сумма копится отдельно по каждому пользователю. Это позволяет 
//RU пользователям увеличивать вероятность выигрыша, увеличивая депозит во время партии. В конце партии суммируются все времена 
//RU пребывания в партии умноженные на депозиты всех пользователей (с учетом пополнений депозита в течение партии, см. выше) (и эта 
//RU сумма принимается за вероятность 1.0). Далее случайное число нормируется к этой сумме и выбирается пользователь на основании 
//RU этого числа. В итоге вероятность выигрыша пользователя пропорциональна сумме произведений его депозита и времени нахождения в 
//RU пуле его ликвидности.
//RU Обнуление депозита удаляет пользователя из партии, соответственно удаляет его время нахождения в пуле, это делает 
//RU бессмысленным выход и повторный вход в партию.
//RU Этот алгоритм более интересен пользователям с большими депозитами, вероятность выигрыша зависит от размера депозита, поэтому можно
//RU существенно увеличить вероятность выигрыша, вложив большой депозит.
| AlgoTimeVol
//RU Вероятность выигрыша равновероятна
//RU
//RU Вероятность выигрыша равновероятна для всех пользователей в пуле, которые присутствуют на окончание партии. 
//RU Использование алгоритма без minSeconds уязвимо перед халявщиками, которые входят в пул только перед розыгрышем
| AlgoEqual
;

//RU Параметры для управления пулом
type t_opts is [@layout:comb] record [
    //RU Алгоритм пула
    algo: t_algo;

    //RU Длительность партии в секундах
    //RU
    //RU Допустимо в интервале [cMIN_GAME_SECONDS, cMAX_GAME_SECONDS]
    // \see cMIN_GAME_SECONDS, cMAX_GAME_SECONDS
    gameSeconds: nat;

    //RU Минимальное время (в секундах) нахождения в пуле для участия в розыгрыше
    //RU
    //RU Параметр не влияет на внесение депозита, пользователь может вносить депозит в любой момент, если проходит по другим ограничениям, 
    //RU он сможет участвовать в следующих розыгрышах
    //RU 0 - нет ограничения. Максимальное значение - длительность партии gameSeconds
    // \see gameSeconds
    minSeconds: nat;

    //RU Минимальный депозит для пула
    //RU
    //RU Пул с алгоритмом cALGO_TIME не учитывает размер депозита для розыгрыша вознагражедения. Этот параметр позволит избежать
    //RU копеечных депозитов
    //RU 0 - нет ограничения
    minDeposit: nat;

    //RU Максимальный депозит для пула
    //RU
    //RU Пул с алгоритмом AlgoTimeVol может позволить владельцу огромного депозита войти в последний момент и с большой вероятностью 
    //RU забрать вознаграждения. Чтобы ограничить размеры депозитов в пуле разумными рамками и дать пользователям сопоставимые шансы
    //RU этот параметр вместе с minDeposit позволит получить честный розыгрыш.
    //RU 0 - нет ограничения
    maxDeposit: nat;

    //RU Процент от вознаграждения для выигрыша
    //RU
    //RU В интервале [1; 100], в сумме с другими процентами должно быть 100.
    // \see burnPercent, feePercent
    winPercent: nat;

    //RU Процент от вознаграждения для сжигания
    //RU
    //RU В интервале [0; 100], в сумме с другими процентами должно быть 100.
    // \see winPercent, feePercent, t_pool.burnToken
    burnPercent: nat;

    //RU Процент комиссии за розыгрыш
    //RU
    //RU В интервале [0; 100], в сумме с другими процентами должно быть 100.
    //RU Для осуществления розыгрыша админ контракта должен вызвать контракт после завершения партии, запросить случайное число
    //RU у оракула и осуществить розыгрыш, что потребует затрат на выполнение.
    // \see winPercent, burnPercent
    feePercent: nat;
];

//RU Состояния партии
//EN States of game
type t_game_state is
| GameStateActivating //RU< Идет запуск партии (внутреннее состояние)
| GameStateActive //RU< Идет партия
| GameStateComplete //RU< Партия закончена по времени
| GameStateWaitRandom//RU< Партия закончена по времени, ожидаем случайное число для определения победителя
| GameStateWaitWinner//RU< Партия закончена по времени, случайное число получено (или не требуется), ожидаем определения победителя внешним кодом
| GameStatePause//RU< Партии приостановлены (предыдущая завершена, но запуск следующей заблокирован)
;

//RU Вес для определения вероятности победы
//RU
//RU Вероятность выигрыша пользователя пропорциональна отношению веса пользователя к весу всей партии
type t_weight is nat;

//RU Параметры партии
type t_game is [@layout:comb] record [
    state: t_game_state;//RU< Состояние партии
    tsBeg: timestamp;//RU< Начало партии
    tsEnd: timestamp;//RU< Конец партии
    weight: t_weight;//RU< Суммарный вес всех участников партии
    winWeight: t_weight;//RU< Вес победителя при проходе по всем пользователям в порядке возрастания их индексов
    winner: address;//RU< Победитель текущей партии
];

type t_iuser is t_i;//RU< Индекс пользователя внутри пула

#if ENABLE_POOL_STAT
//RU Статистика пула
type t_stat is [@layout:comb] record [
    lastWinner: address;//RU< Последний победитель
    lastReward: t_amount;//RU< Последнее вознаграждение победителя
    paidRewards: t_amount;//RU< Сколько токенов вознаграждения было выплачено пулом победителям за все партии
    gamesComplete: nat;//RU< Сколько партий уже проведено в этом пуле
];
#endif // ENABLE_POOL_STAT

//RU Пул (возвращается при запросе информации о пуле админом)
type t_pool is [@layout:comb] record [
    opts: t_opts;//RU< Настройки пула
    farm: t_farm;//RU< Ферма для пула
    randomSource: t_random_source;//RU< Источник случайных чисел для розыгрышей
    burnToken: option(t_token);//RU< Токен для сжигания всего, что выше процента выигрыша
    rewardSwap: option(t_swap);//RU Обменник Quipuswap для обмена токенов вознаграждения фермы через tez
    burnSwap: option(t_swap);//RU Обменник Quipuswap для обмена токенов для сжигания через tez
    feeAddr: option(address);//RU< Адрес, для перечисления комиссии пула
    state: t_pool_state;//RU< Состояние пула
    balance: t_amount;//RU< Сколько токенов фермы инвестировано в пул в настоящий момент
    count: nat;//RU< Кол-во пользователей в пуле
    game: t_game;//RU< Текущая партия розыгрыша вознаграждения
    randomFuture: bool;//RU< Делался ли запрос на колбек со случайным числом по окончании партии
    beforeHarvestBalance: t_amount;//RU< Баланс контракта в токенах вознаграждения до взыскания вознаграждения
    beforeReward2TezBalance: tez;//RU< Баланс контракта до обмена токенов вознаграждения на tez
    beforeBurnBalance: t_amount;//RU< Баланс контракта в токенах для сжигания до обмена tez на них
#if ENABLE_POOL_MANAGER
    manager: address;//RU< Менеджер пула (админ только данного пула)
#endif // ENABLE_POOL_MANAGER
#if ENABLE_POOL_STAT
    stat: t_stat;//RU< Статистика пула
#endif // ENABLE_POOL_STAT
];

//RU Данные для создания пула
type t_pool_create is [@layout:comb] record [
    opts: t_opts;//RU< Настройки пула
    farm: t_farm;//RU< Ферма для пула
    randomSource: t_random_source;//RU< Источник случайных чисел для розыгрышей
    burnToken: option(t_token);//RU< Токен для сжигания
    rewardSwap: option(t_swap);//RU Обменник Quipuswap для обмена токенов фермы через tez
    burnSwap: option(t_swap);//RU Обменник Quipuswap для обмена токенов для сжигания через tez
    feeAddr: option(address);//RU< Адрес, для перечисления комиссии пула
    state: t_pool_state;//RU< Состояние пула
];

//RU Данные для редактирования пула
type t_pool_edit is [@layout:comb] record [
    opts: option(t_opts);//RU< Настройки пула
    randomSource: option(t_random_source);//RU< Источник случайных чисел для розыгрышей
    burnToken: option(t_token);//RU< Токен для сжигания
    rewardSwap: option(t_swap);//RU Обменник Quipuswap для обмена токенов фермы через tez
    burnSwap: option(t_swap);//RU Обменник Quipuswap для обмена токенов для сжигания через tez
    feeAddr: option(address);//RU< Адрес, для перечисления комиссии пула
    state: option(t_pool_state);//RU< Состояние пула
];

type t_ipool is t_i;//RU< Индекс пула
type t_pools is big_map(t_ipool, t_pool);//RU< Пулы по их ID

//RU Параметры пользователя в пуле
type t_user is [@layout:comb] record [
    //RU Когда пользователь вступил в пул
    //RU
    //RU Для алгоритма AlgoTime вес равен tsEnd - (максимум из tsPool и tsBeg)
    tsPool: timestamp;
    balance: t_amount;//RU< Сколько токенов фермы инвестировано в пул этим пользователем
    tsBalance: timestamp;//RU< Когда было последнее изменение баланса пользователя
    
    //RU Дополнительный вес пользователя только для AlgoTimeVol при (tsBalance >= game.tsBeg) && (tsBalance < game.tsEnd)
    //RU
    //RU При пополнениях/списания во время партии это может изменять вес пользователя в розыгрыше при AlgoTimeVol
    //RU Эта переменная сохраняет накопленный пользователем вес от начала партии game.tsBeg до tsBalance и в следующих
    //RU партиях (при tsBalance < game.tsBeg) переменная игнорируется, чтобы не делать лишних обновлений данных
    // \see AlgoTimeVol
    addWeight: t_weight;
];

//RU Ключ для поиска индекса пользователя по индексу пула и адресу
type t_ipooladdr is t_ipool * address;

//RU Индекса в пуле по номеру пула и адресу пользователя
type t_ipooladdr2user is big_map(t_ipooladdr, t_user);

#if ENABLE_POOL_VIEW
//RU Информация о пуле, выдаваемая при запросе информации о пуле
type t_pool_info is [@layout:comb] record [
    opts: t_opts;//RU< Настройки пула
    farm: t_farm;//RU< Ферма для пула
    state: t_pool_state;//RU< Состояние пула
    balance: t_amount;//RU< Сколько токенов фермы инвестировано в пул в настоящий момент
    count: nat;//RU< Кол-во пользователей в пуле
    game: t_game;//RU< Текущая партия розыгрыша вознаграждения
];
#endif // ENABLE_POOL_VIEW

//RU Адрес, которому разрешено списывать токены с контракта
type t_approve is address * t_token;
//RU Уже одобренные адреса для списания токенов с контракта
type t_approved is big_map(t_approve, unit);

//RU Идентификация фермы
type t_farm_ident is address * nat;
//RU Использованные фермы
type t_farms is big_map(t_farm_ident, unit);

//RU Прототип методов After
type t_after_method is After of t_ipool;


#endif // !TYPES_INCLUDED

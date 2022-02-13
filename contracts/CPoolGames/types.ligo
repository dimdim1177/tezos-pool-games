#if !TYPES_INCLUDED
#define TYPES_INCLUDED

#include "config.ligo"
#include "../include/consts.ligo"
#include "../module/MOwner.ligo"
#include "../module/MAdmin.ligo"
#include "../module/MAdmins.ligo"
#include "../module/MFarm.ligo"
#include "../module/MRandom.ligo"
#include "../module/MToken.ligo"
#include "../module/MManager.ligo"

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
type t_random is MRandom.t_random;
type t_token is MToken.t_token;

type t_pool_state is nat;//RU< Состояние пула

type t_algo is nat;//RU< Алгоритм розыгрышей пула

//RU Параметры для управления пулом
type t_opts is [@layout:comb] record [
    //RU Состояние пула
    // \see MPoolOpts.cSTATEs
    state: t_pool_state;

    //RU Алгоритм пула
    // \see MPoolOpts.cALGOs
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

    //RU Максимальный депозит для пула (только для алгоритма cALGO_TIMEVOL)
    //RU
    //RU Пул с алгоритмом cALGO_TIMEVOL может позволить владельцу большого депозита войти в последний момент и с большой вероятностью 
    //RU забрать вознаграждения. Чтобы ограничить размеры депозитов в пуле разумными рамками и дать пользователям сопоставимые шансы
    //RU этот параметр вместе с minDeposit позволит получить честный розыгрыш.
    //RU 0 - нет ограничения. В алгоритмах кроме cALGO_TIMEVOL параметр игнорируется
    maxDeposit: nat;

    //RU Процент от вознаграждения для выигрыша
    //RU
    //RU В интервале [0; 100], в сумме с другими процентами должно быть 100.
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

type t_game_state is nat;//RU< Состояние партии

//RU Вес для определения вероятности победы
//RU
//RU Вероятность выигрыша пользователя пропорциональна отношению веса пользователя к весу всей партии
type t_weight is nat;

//RU Параметры партии
type t_game is [@layout:comb] record [
    balance: t_amount;//RU< Сколько токенов фермы инвестировано в пул в настоящий момент
    count: nat;//RU< Кол-во пользователей в пуле
    state: t_game_state;//RU< Состояние партии
    tsBeg: timestamp;//RU< Начало партии
    tsEnd: timestamp;//RU< Конец партии
    weight: t_weight;//RU< Суммарный вес всех участников партии
];

//RU Информация о пуле, выдаваемая при запросе всем пользователям
type t_pool_info is [@layout:comb] record [
    opts: t_opts;//RU< Настройки пула
    farm: t_farm;//RU< Ферма для пула
    game: t_game;//RU< Текущая партия розыгрыша вознаграждения
];

type t_iuser is t_i;//RU< Индекс пользователя внутри пула

#if ENABLE_POOL_STAT
//RU Статистика пула
type t_stat is [@layout:comb] record [
    paidRewards: t_amount;//RU< Сколько токенов вознаграждения было выплачено пулом за все партии
    gamesComplete: nat;//RU< Сколько партий уже проведено в этом пуле
];
#endif // ENABLE_POOL_STAT

//RU Пул (возвращается при запросе информации о пуле админом)
type t_pool is [@layout:comb] record [
    opts: t_opts;//RU< Настройки пула
    farm: t_farm;//RU< Ферма для пула
    random: t_random;//RU< Источник случайных чисел для розыгрышей
    burn: option(t_token);//RU< Токен для сжигания всего, что выше процента выигрыша
    feeaddr: option(address);//RU< Адрес, для перечисления комиссии пула
    game: t_game;//RU< Текущая партия розыгрыша вознаграждения
    ibeg: t_iuser;//RU< Начальный индекс пользователей в пуле
    inext: t_iuser;//RU< Следующий за максимальным индекс пользователей в пуле
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
    random: t_random;//RU< Источник случайных чисел для розыгрышей
    burn: option(t_token);//RU< Токен для сжигания всего, что выше процента выигрыша
    feeaddr: option(address);//RU< Адрес, для перечисления комиссии пула
];

type t_ipool is t_i;//RU< Индекс пула
type t_pools is big_map(t_ipool, t_pool);//RU< Пулы по их ID

//RU Пулы и сопутствующая информация
type t_rpools is [@layout:comb] record [
    inext: t_ipool;//RU< ID следующего пула
    pools: t_pools;//RU< Собственно пулы
#if ENABLE_POOL_LASTIPOOL_VIEW
    addr2ilast: big_map(address, t_ipool);//RU< Последний идентификатор пула по адресу админа
#endif // ENABLE_POOL_LASTIPOOL_VIEW
];

//RU Параметры пользователя в пуле
type t_user is [@layout:comb] record [
    balance: t_amount;//RU< Сколько токенов фермы инвестировано в пул этим пользователем
    tsBalance: timestamp;//RU< Когда было последнее пополнение токенов пользователем
    weight: t_weight;//RU< Вес для определения вероятности победы в текущей партии
#if ENABLE_REINDEX_USERS
    addr: address;//RU< Адрес пользователя
#endif // ENABLE_REINDEX_USERS
];

//RU Ключ для поиска индекса пользователя по индексу пула и адресу
type t_ipooladdr is t_ipool * address;

//RU Индекса в пуле по номеру пула и адресу пользователя
type t_ipooladdr2iuser is big_map(t_ipooladdr, t_iuser);

//RU Комбинация индекса пула и индекса пользователя в нем
type t_ipooliuser is t_ipool * t_iuser;

//RU Параметры пользователя по индексу пула и индекса пользователя в нем
type t_ipooliuser2user is big_map(t_ipooliuser, t_user);

//RU Пользователи пулов
type t_users is [@layout:comb] record [
    //RU Индекса в пуле по номеру пула и адресу пользователя
    ipooladdr2iuser: t_ipooladdr2iuser;

    //RU Параметры пользователя по индексу пула и индекса пользователя в нем
    ipooliuser2user: t_ipooliuser2user;
];

#endif // !TYPES_INCLUDED

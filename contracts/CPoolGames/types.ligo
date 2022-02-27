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

///RU Состояние пула
///EN Pool status
type t_pool_state is
///RU Пул активен
///RU
///RU Периодически разыгрывается вознаграждение для всех участников пула согласно настройкам пула
///EN The pool is active
///EN
///EN A reward is played periodically for all pool participants according to the pool settings
/// \see StartPool, CreatePool
| PoolStateActive
///RU Пул приостановлен
///RU
///RU Если партия розыгрыша активна, она продолжается до завершения, но следующая не будет запущена.
///EN Pool suspended
///EN
///EN If the drawing party is active, it continues until completion, but the next one will not be started.
/// \see PausePool, CreatePool
| PoolStatePause
///RU Пул на удаление
///RU
///RU Если партия розыгрыша активна, она продолжается до завершения. По окончании партии, когда пользователи
///RU заберут все депозиты, пул будет удален во время списания последнего депозита.
///RU Если же пул уже пуст на момент установки состояния, он будет удален немедленно.
///EN Pool for deletion
///EN
///EN If the drawing party is active, it continues until the end. At the end of the batch, when users
///EN have collected all deposits, the pool will be deleted during the last deposit debiting.
///EN If the pool is already empty at the time of setting the status, it will be deleted immediately.
/// \see RemovePool
| PoolStateRemove
;

///RU Алгоритм розыгрышей пула
///RU
///RU Кроме собственно алгоритма в каждом случае используются дополнительные настройки minDeposit, minSeconds,
///RU maxDeposit (только для AlgoTimeVol) для дополнительных ограничений
///EN The algorithm of pool draws
///EN
///EN In addition to the algorithm itself, in each case, additional settings minDeposit, minSeconds are used,
///EN maxDeposit (only for AlgoTimeVol) for additional restrictions
/// \see t_opts.minDeposit, t_opts.minSeconds, t_opts.maxDeposit
type t_algo is
///RU Вероятность выигрыша пропорциональна суммарному времени в игре
///RU
///RU Время вступления каждого пользователя в розыгрыш фиксируется. В конце партии суммируются все времена пребывания в партии
///RU всех пользователей (и эта сумма принимается за вероятность 1.0). Далее случайное число нормируется к этой сумме и выбирается
///RU пользователь на основании этого числа. В итоге вероятность выигрыша пользователя пропорциональна его времени нахождения в
///RU пуле.
///RU Обнуление депозита удаляет пользователя из партии, соответственно удаляет его время нахождения в пуле, это делает
///RU бессмысленным выход и повторный вход в партию.
///RU Этот алгоритм более интересен пользователям с малыми депозитами, вероятность выигрыша не зависит от размера депозита, поэтому
///RU можно вложить мало, а выиграть много.
///EN The probability of winning is proportional to the total time in the game
///EN
///EN The time of entry of each user into the draw is fixed. At the end of the batch, all the time spent in the batch
///EN of all users are summed up (and this sum is taken as probability 1.0). Next, a random number is normalized to this amount and
///EN the user is selected based on this number. As a result, the probability of a user winning is proportional to his time in the
///EN pool.
///EN Zeroing the deposit removes the user from the batch, respectively, removes his time in the pool, this makes
///EN it pointless to exit and re-enter the batch.
///EN This algorithm is more interesting for users with small deposits, the probability of winning does not depend on the size of the
///EN deposit, so you can invest little and win a lot.
/// \see t_opts.minDeposit, t_opts.minSeconds, t_weight, t_game.weight
| AlgoTime
///RU Вероятность выигрыша пропорциональна сумме произведений объема на время в игре
///RU
///RU Время вступления каждого пользователя в розыгрыш и его депозит на этот момент фиксируется. При пополнении депозита, предыдущий
///RU депозит умножается на его время присутствия в пуле в секундах и эта сумма копится отдельно по каждому пользователю. Это позволяет
///RU пользователям увеличивать вероятность выигрыша, увеличивая депозит во время партии. В конце партии суммируются все времена
///RU пребывания в партии умноженные на депозиты всех пользователей (с учетом пополнений депозита в течение партии, см. выше) (и эта
///RU сумма принимается за вероятность 1.0). Далее случайное число нормируется к этой сумме и выбирается пользователь на основании
///RU этого числа. В итоге вероятность выигрыша пользователя пропорциональна сумме произведений его депозита и времени нахождения в
///RU пуле его ликвидности.
///RU Обнуление депозита удаляет пользователя из партии, соответственно удаляет его время нахождения в пуле, это делает
///RU бессмысленным выход и повторный вход в партию.
///RU Этот алгоритм более интересен пользователям с большими депозитами, вероятность выигрыша зависит от размера депозита, поэтому можно
///RU существенно увеличить вероятность выигрыша, вложив большой депозит.
///EN The probability of winning is proportional to the sum of the products of the volume for the time in the game
///EN
///EN The time of entry of each user into the draw and his deposit at this moment is fixed. When replenishing the deposit, the previous
///EN deposit is multiplied by its time of presence in the pool in seconds and this amount is accumulated separately for each user. This allows
///EN users to increase the probability of winning by increasing the deposit during the game. At the end of the batch, all the time
///EN spent in the batch multiplied by the deposits of all users are summed up (taking into account deposits during the batch, see above) (and this
///EN amount is taken as probability 1.0). Next, a random number is normalized to this amount and the user is selected based
///EN on this number. As a result, the probability of a user winning is proportional to the sum of the products of his deposit and the time
///EN spent in his liquidity pool.
///EN Zeroing the deposit removes the user from the batch, respectively, removes his time in the pool, this makes
///EN it pointless to exit and re-enter the batch.
///EN This algorithm is more interesting for users with large deposits, the probability of winning depends on the size of the deposit, so you can
///EN significantly increase the probability of winning by investing a large deposit.
/// \see t_opts.minDeposit, t_opts.maxDeposit, t_weight, t_game.weight
| AlgoTimeVol
///RU Вероятность выигрыша равновероятна
///RU
///RU Вероятность выигрыша равновероятна для всех пользователей в пуле, которые присутствуют на окончание партии, у всех вес 1.
///RU Использование алгоритма без minSeconds уязвимо перед халявщиками, которые входят в пул только перед розыгрышем
///EN The probability of winning is equally likely
///EN
///EN The probability of winning is equally likely for all users in the pool who are present at the end of the game, all have a weight of 1.
///EN Using the algorithm without minSeconds is vulnerable to freeloaders who enter the pool only before the draw
/// \see t_opts.minSeconds, t_weight, t_game.weight
| AlgoEqual
;

///RU Настройки пула
///EN Pool settings
type t_opts is [@layout:comb] record [
    ///RU Алгоритм пула
    ///EN Pool algorithm
    algo: t_algo;

    ///RU Длительность партии в секундах
    ///RU
    ///RU Допустимо в интервале [cMIN_GAME_SECONDS, cMAX_GAME_SECONDS]
    ///EN Game duration in seconds
    ///EN
    ///EN Allowed in the interval [cMIN_GAME_SECONDS, cMAX_GAME_SECONDS]
    /// \see cMIN_GAME_SECONDS, cMAX_GAME_SECONDS
    gameSeconds: nat;

    ///RU Минимальное время (в секундах) нахождения в пуле для участия в розыгрыше
    ///RU
    ///RU Параметр не влияет на внесение депозита, пользователь может вносить депозит в любой момент, если проходит по другим ограничениям,
    ///RU он сможет участвовать в следующих розыгрышах
    ///RU 0 - нет ограничения. Максимальное значение - длительность партии gameSeconds
    ///EN Minimum time (in seconds) spent in the pool to participate in the draw
    ///EN
    ///EN The parameter does not affect the deposit, the user can make a deposit at any time, if he passes through other restrictions,
    ///EN he will be able to participate in the following draws
    ///EN 0 - there is no limit. The maximum value is the duration of the gameSeconds game
    /// \see gameSeconds
    minSeconds: nat;

    ///RU Минимальный депозит для пула
    ///RU
    ///RU Пул с алгоритмом AlgoTime не учитывает размер депозита для розыгрыша вознагражедения. Этот параметр позволит избежать
    ///RU копеечных депозитов
    ///RU 0 - нет ограничения
    ///EN Minimum deposit for the pool
    ///EN
    ///EN The pool with the algorithm AlgoTime does not take into account the size of the deposit for the reward draw. This parameter will avoid
    ///EN penny deposits
    ///EN 0 - there is no limit
    /// \see AlgoTime
    minDeposit: nat;

    ///RU Максимальный депозит для пула
    ///RU
    ///RU Пул с алгоритмом AlgoTimeVol может позволить владельцу огромного депозита войти в последний момент и с большой вероятностью
    ///RU забрать вознаграждения. Чтобы ограничить размеры депозитов в пуле разумными рамками и дать пользователям сопоставимые шансы
    ///RU этот параметр вместе с minDeposit позволит получить честный розыгрыш.
    ///RU 0 - нет ограничения
    ///EN Maximum deposit for the pool
    ///EN
    ///EN A pool with the algorithm AlgoTimeVol can allow the owner of a huge deposit to enter at the last moment and with a high probability
    ///EN take the rewards. To limit the size of deposits in the pool to reasonable limits and give users comparable chances
    ///EN this parameter together with minDeposit will allow you to get a fair draw.
    ///EN 0 - there is no limit
    /// \see AlgoTimeVol
    maxDeposit: nat;

    ///RU Процент от вознаграждения для выигрыша
    ///RU
    ///RU В интервале [1; 100], в сумме с другими процентами должно быть 100.
    ///EN Percentage of the reward for winner
    ///EN
    ///EN In the interval [1; 100], in total with other percentages should be 100.
    /// \see burnPercent, feePercent
    winPercent: nat;

    ///RU Процент от вознаграждения для сжигания
    ///RU
    ///RU В интервале [0; 100], в сумме с другими процентами должно быть 100.
    ///EN Percentage of the reward for burning
    ///EN
    ///EN In the interval [0; 100], in total with other percentages should be 100.
    /// \see winPercent, feePercent, t_pool.burnToken
    burnPercent: nat;

    ///RU Процент комиссии за розыгрыш
    ///RU
    ///RU В интервале [0; 100], в сумме с другими процентами должно быть 100.
    ///RU Для осуществления розыгрыша админ контракта должен вызвать контракт после завершения партии, запросить случайное число
    ///RU у оракула и осуществить розыгрыш, что потребует затрат на выполнение.
    ///EN Percentage of commission for the drawing
    ///EN
    ///EN In the interval [0; 100], in total with other percentages should be 100.
    ///EN To carry out the drawing, the contract administrator must call the contract after the end of the game, request a random number
    ///EN from the oracle and carry out the drawing, which will require execution costs.
    /// \see winPercent, burnPercent
    feePercent: nat;
];

///RU Состояния партии розыгрыша вознаграждения
///EN States of the reward drawing party
type t_game_state is
///RU Идет запуск партии
///RU
///RU Это состояние остается в хранилище только когда пользователи вносят или извлекают депозит после окончания розыгрыша
///RU в пустом пуле. Запуск нового розыгрыша требует дополнительных операций некорректно будет расход газа для этих операций
///RU истребовать с пользователя. Полноценный запуск партии будет произведен позднее менеджером пула
///EN The batch is being launched
///EN
///EN This state remains in the vault only when users make or withdraw a deposit after the end of the draw
///EN in an empty pool. Launching a new drawing requires additional operations, it will be incorrect to demand gas consumption for these
///EN operations from the user. A full batch launch will be made later by the pool manager.
| GameStateActivating
///RU Идет партия розыгрыша
///EN There is a drawing party going on
| GameStateActive
///RU Партия розыгрыша закончена по времени
///EN The drawing party is over in time
| GameStateComplete
///RU Партия розыгрыша закончена по времени, ожидаем случайное число для определения победителя
///EN The drawing party is over in time, we are waiting for a random number to determine the winner
| GameStateWaitRandom
///RU Партия розыгрыша закончена по времени, случайное число получено (или не требуется), ожидаем определения победителя внешним кодом
///EN The drawing party is over in time, a random number has been received (or is not required), we are waiting for the winner to be
///EN determined by an external code
| GameStateWaitWinner
///RU Партии приостановлены (партия розыгрыша завершена, но запуск следующей заблокирован)
///EN The games are suspended (the drawing party is completed, but the launch of the next one is blocked)
| GameStatePause
;

///RU Вес для определения вероятности победы участника
///RU
///RU Вероятность выигрыша пользователя пропорциональна отношению веса участника к весу всей партии
///EN Weight to determine the probability of a participant winning
///EN
///EN The probability of a user winning is proportional to the ratio of the participant's weight to the weight of the entire party
type t_weight is nat;

///RU Параметры партии розыгрыша
///EN Parameters of the drawing party
/// \see MPoolGame
type t_game is [@layout:comb] record [
    state: t_game_state;///RU< Состояние партии ///EN< Game status
    tsBeg: timestamp;///RU< Время начала партии ///EN< Game start time

    ///RU Время окончания партии
    ///RU
    ///RU Время начала партии tsBeg + opts.gameSeconds
    ///EN End time of the game
    ///EN
    ///EN Party start time tsBeg + opts.gameSeconds
    /// \see t_opts.gameSeconds
    tsEnd: timestamp;

    ///RU Вес партии - суммарный вес всех участников партии
    ///EN Party weight - the total weight of all party participants
    weight: t_weight;

    ///RU Вес для определения победителя
    ///RU
    ///RU Вес определяется делением с остатком 256-битного случайного числа на вес партии + 1n (то есть никогда не равен 0)
    ///RU Для поиска победителя бэкенд должен взять адреса всех участников пула, отсортировать их в алфавитном порядке и
    ///RU последовательно суммируя веса участников найти того, при добавлении веса которого результат >=winWeight И <=winWeight,
    ///RU он и будет являться победителям розыгрыша
    ///RU Участники, вошедшие в пул с нарушением ограничений (например, менее чем за minSeconds до окончания партии), будут иметь
    ///RU для текущей партии вес 0 и таким образом исключаются из победителей.
    ///EN Weight to determine the winner
    ///EN
    ///EN Weight is determined by dividing with remainder 256-bit random numbers on the weight of the party + 1n (that is never equal to 0)
    ///EN To search for the winner of the backend needs to take addresses of all the members of the pool, sort them in alphabetical order and
    ///EN consistently adding up the weight of the participants to find someone, adding weight which result >=winWeight And <=winWeight,
    ///EN he will be the winners
    ///EN Participants who entered the pool in violation of the restrictions (for example, less than minSeconds before the end of the game)
    ///EN will have for the current batch, the weight is 0 and thus excluded from the winners.
    /// \see winner
    winWeight: t_weight;

    ///RU Победитель текущей партии
    ///RU
    ///RU Определяется извне бэкендом после определения веса победителя партии на основе случайного числа
    ///EN The winner of the current game
    ///EN
    ///EN Determined externally by the backend after determining the weight of the winner of the game based on a random number
    /// \see winWeight
    winner: address;
];

///RU Статистика пула
///RU
///RU Используется для фиксации последнего победителя и выигрыша и сумаррных данных в блокчейне, чтобы иметь для
///RU продвижения розыгрышей публичный и подтвержденный источник этих данных
///EN Pool statistics
///EN
///EN It is used to record the last winner and winnings and sumar data in the blockchain in order to have
///EN a public and confirmed source of this data for the promotion of the draws.
/// \see ENABLE_POOL_STAT, MPoolStat
type t_stat is [@layout:comb] record [
    lastWinner: address;///RU< Последний победитель ///EN< Last winner
    lastReward: MToken.t_amount;///RU< Последнее вознаграждение победителя ///EN< The winner's last reward

    ///RU Сколько токенов вознаграждения было выплачено пулом победителям за все партии
    ///EN How many reward tokens were paid by the pool to the winners for all the games
    paidRewards: MToken.t_amount;

    ///RU Сколько партий уже проведено в этом пуле
    ///EN How many games have already been held in this pool
    gamesComplete: nat;
];

///RU Пул для периодических розыгрышей вознаграждения
///EN A pool for periodic raffles of rewards
/// \see CreatePool
type t_pool is [@layout:comb] record [
    opts: t_opts;///RU< Настройки пула ///EN< Pool Settings
    farm: MFarm.t_farm;///RU< Ферма для пула ///EN< Pool Farm

    ///RU Источник случайных чисел для розыгрышей
    ///EN Source of random numbers for draws
    randomSource: MRandom.t_random_source;

    ///RU Токен для сжигания
    ///RU
    ///RU Используется только при burnPercent > 0
    ///EN Token for burning
    ///EN
    ///EN Used only when burnPercent > 0
    /// \see t_opts.burnPercent, t_pool.rewardSwap, t_pool.burnSwap
    burnToken: option(MToken.t_token);

    ///RU Обменник Quipuswap для обмена токенов вознаграждения фермы через tez
    ///RU
    ///RU Используется только при burnPercent > 0 И rewardToken != burnToken
    ///EN Quipuswap exchanger for exchanging farm reward tokens via tez
    ///EN
    ///EN Used only when burnPercent > 0 And rewardToken != burnToken
    /// \see t_opts.burnPercent, t_pool.burnToken, t_pool.burnSwap, MFarm::t_farm.rewardToken
    rewardSwap: option(MQuipuswap.t_swap);

    ///RU Обменник Quipuswap для обмена токенов для сжигания через tez
    ///RU
    ///RU Используется только при burnPercent > 0 И rewardToken != burnToken
    ///EN Quipuswap exchanger for exchanging tokens for burning via tez
    ///EN
    ///EN Used only when burnPercent > 0 And rewardToken != burnToken
    /// \see t_opts.burnPercent, t_pool.burnToken, t_pool.rewardSwap, MFarm::t_farm.rewardToken
    burnSwap: option(MQuipuswap.t_swap);

    ///RU Адрес, для перечисления комиссии пула
    ///RU
    ///RU Используется только при feePercent > 0
    ///EN Address for transferring the pool commission
    ///EN
    ///EN Used only when feePercent > 0
    /// \see t_opts.feePercent
    feeAddr: option(address);

    state: t_pool_state;///RU< Состояние пула ///EN< Pool Status

    ///RU Сколько токенов фермы инвестировано в пул в настоящий момент
    ///EN How many farm tokens are currently invested in the pool
    /// \see MFarm::t_farm.farmToken, t_pool.farm
    balance: MToken.t_amount;

    ///RU Кол-во пользователей в пуле
    ///EN Number of users in the pool
    count: nat;

    ///RU Текущая партия розыгрыша вознаграждения
    ///EN The current batch of the reward draw
    game: t_game;

    ///RU Делался ли запрос случайного числа для партии
    ///EN Was a random number request made for the batch
    randomFuture: bool;

    ///RU Баланс контракта в токенах вознаграждения до взыскания вознаграждения
    ///EN The balance of the contract in reward tokens before the collection of remuneration
    beforeHarvestBalance: MToken.t_amount;

    ///RU Баланс контракта до обмена токенов вознаграждения на tez
    ///EN Contract balance before the exchange of reward tokens for tez
    beforeReward2TezBalance: tez;

    ///RU Баланс контракта в токенах для сжигания до обмена tez на них
    ///EN Contract balance in tokens to burn before exchanging tez for them
    beforeBurnBalance: MToken.t_amount;

#if ENABLE_POOL_MANAGER
    ///RU Менеджер пула (админ только данного пула)
    ///RU
    ///RU Если в коде включен пул-как-сервис ключом ENABLE_POOL_AS_SERVICE, то он единственный управляющий пулом, владелец и
    ///RU админ контракта не имеют доступа к пулу.
    ///RU При выключенном пул-как-сервис может использоваться для увеличения безопасности бэкенда. Контракт должен вызываться
    ///RU внешним бэкендом для работы розыгрышей, можно использовать для этого доступ менеджера, а ключи владельца не хранить
    ///RU на сервере бэкенда
    ///EN Pool manager (admin of this pool only)
    ///EN
    ///EN If the pool-as-a-service is enabled in the code with the ENABLE_POOL_AS_SERVICE key, then it is the only pool manager, the owner and
    ///EN the contract administrator do not have access to the pool.
    ///EN When the pool-as-a-service is turned off, it can be used to increase the security of the backend. The contract must be called
    ///EN by an external backend for the operation of the drawings, you can use the manager's access for this, and the owner's keys are not stored
    ///EN on the backend server
    /// \see ENABLE_POOL_AS_SERVICE
    manager: address;
#endif // ENABLE_POOL_MANAGER

#if ENABLE_POOL_STAT
    ///RU Статистика пула
    ///RU
    ///RU Используется для фиксации последнего победителя и выигрыша и сумаррных данных в блокчейне, чтобы иметь для
    ///RU продвижения розыгрышей публичный и подтвержденный источник этих данных
    ///EN Pool statistics
    ///EN
    ///EN It is used to record the last winner and winnings and sumar data in the blockchain in order to have
    ///EN a public and confirmed source of this data for the promotion of the draws.
    /// \see ENABLE_POOL_STAT
    stat: t_stat;
#endif // ENABLE_POOL_STAT
];

///RU Данные для создания пула
///RU
///RU Все настройки, необходимые для создания пула
///EN Data for creating a pool
///EN
///EN All settings required to create a pool
/// \see CreatePool, t_pool
type t_pool_create is [@layout:comb] record [
    opts: t_opts;///RU< Настройки пула ///EN< Pool Settings
    farm: MFarm.t_farm;///RU< Ферма для пула ///EN< Pool Farm

    ///RU Источник случайных чисел для розыгрышей
    ///EN Source of random numbers for reward draws
    randomSource: MRandom.t_random_source;
    burnToken: option(MToken.t_token);///RU< Токен для сжигания ///EN< Token for burning

    ///RU Обменник Quipuswap для обмена токенов фермы через tez
    ///EN Quipuswap exchanger for exchanging farm tokens via tez
    rewardSwap: option(MQuipuswap.t_swap);

    ///RU Обменник Quipuswap для обмена токенов для сжигания через tez
    ///EN Quipuswap exchanger for exchanging tokens for burning via tez
    burnSwap: option(MQuipuswap.t_swap);

    ///RU Адрес, для перечисления комиссии пула
    ///EN Address for transferring the pool commission
    feeAddr: option(address);
    state: t_pool_state;///RU< Состояние пула ///EN< Pool Status
];

///RU Данные для редактирования пула
///RU
///RU Все настройки, необходимые для редактирования пула. Если любое из полей None, оно игнорируется в методе
///RU редактирования, редактировать можно только остановленный пул у которого закончился розыгрыш
///EN Pool editing data
///EN
///EN All the settings needed to edit the pool. If any of the fields are None, it is ignored in
///EN the editing method, you can edit only the stopped pool that has ended the draw
/// \see EditPool, t_pool, PoolStatePause, GameStatePause
type t_pool_edit is [@layout:comb] record [
    opts: option(t_opts);///RU< Настройки пула ///EN< Pool Settings

    ///RU Источник случайных чисел для розыгрышей
    ///EN Source of random numbers for reward draws
    randomSource: option(MRandom.t_random_source);
    burnToken: option(MToken.t_token);///RU< Токен для сжигания ///EN< Token for burning

    ///RU Обменник Quipuswap для обмена токенов фермы через tez
    ///EN Quipuswap exchanger for exchanging farm tokens via tez
    rewardSwap: option(MQuipuswap.t_swap);

    ///RU Обменник Quipuswap для обмена токенов для сжигания через tez
    ///EN Quipuswap exchanger for exchanging tokens for burning via tez
    burnSwap: option(MQuipuswap.t_swap);

    ///RU Адрес, для перечисления комиссии пула
    ///EN Address for transferring the pool commission
    feeAddr: option(address);
    state: option(t_pool_state);///RU< Состояние пула ///EN< Pool Status
];

type t_ipool is t_i;///RU< Индекс пула ///EN< Pool Index
type t_pools is big_map(t_ipool, t_pool);///RU< Пулы по их ID ///EN< Pools by their ID

///RU Параметры пользователя в пуле
///EN User parameters in the pool
type t_user is [@layout:comb] record [
    ///RU Когда пользователь вступил в пул
    ///RU
    ///RU Для алгоритма AlgoTime вес равен tsEnd - (максимум из tsPool и tsBeg)
    ///EN When the user joined the pool
    ///EN
    ///EN For the algorithm AlgoTime, the weight is equal to tsEnd - (maximum of tsPool and tsBeg)
    tsPool: timestamp;

    ///RU Сколько токенов фермы инвестировано в пул этим пользователем
    ///RU
    ///RU Когда пользователь забирает все токены из пула, его параметры удаляются из пула
    ///EN How many farm tokens are invested in the pool by this user
    ///EN
    ///EN When a user takes all tokens from the pool, his parameters are removed from the pool
    /// \see MFarm::farmToken
    balance: MToken.t_amount;

    ///RU Когда было последнее изменение баланса пользователя
    ///RU
    ///RU Фиксируется последнее изменение баланса в любую сторону, что необходимо для алгоритма AlgoTimeVol
    ///EN When was the last change in the user's balance
    ///EN
    ///EN The last balance change in any direction is recorded, which is necessary for the algorithm AlgoTimeVol
    /// \see AlgoTimeVol
    tsBalance: timestamp;

    ///RU Дополнительный вес пользователя только для AlgoTimeVol при (tsBalance >= game.tsBeg) && (tsBalance < game.tsEnd)
    ///RU
    ///RU При пополнениях/списания во время партии это может изменять вес пользователя в розыгрыше при AlgoTimeVol
    ///RU Эта переменная сохраняет накопленный пользователем вес от начала партии game.tsBeg до tsBalance и в следующих
    ///RU партиях (при tsBalance < game.tsBeg) переменная игнорируется, чтобы не делать лишних обновлений данных
    ///EN Additional user weight only for AlgoTimeVol at (tsBalance >= game.tsBeg) && (tsBalance < game.tsEnd)
    ///EN
    ///EN When depositing/debiting during the party, this may change the user's weight in the draw at AlgoTimeVol
    ///EN This variable stores the user's accumulated weight from the beginning of the game.tsBeg batch to tsBalance and in the following
    ///EN batches (with tsBalance < game.tsBeg) the variable is ignored so as not to make unnecessary data updates
    /// \see AlgoTimeVol
    addWeight: t_weight;
];

///RU Ключ для поиска индекса пользователя по индексу пула и адресу
///EN The key for searching the user's index by pool index and address
type t_ipooladdr is t_ipool * address;

///RU Индекса в пуле по номеру пула и адресу пользователя
///EN Index in the pool by pool number and user address
type t_ipooladdr2user is big_map(t_ipooladdr, t_user);

///RU Информация о пуле, выдаваемая при запросе информации о пуле
///EN Pool information issued when requesting pool information
/// \see ENABLE_POOL_VIEW
type t_pool_info is [@layout:comb] record [
    opts: t_opts;///RU< Настройки пула ///EN< Pool settings
    farm: MFarm.t_farm;///RU< Ферма для пула ///EN< Pool sarm
    state: t_pool_state;///RU< Состояние пула ///EN< Pool status

    ///RU Сколько токенов фермы инвестировано в пул в настоящий момент
    ///EN How many farm tokens are currently invested in the pool
    balance: MToken.t_amount;

    ///RU Кол-во пользователей в пуле
    ///EN Number of users in the pool
    count: nat;

    ///RU Текущая партия розыгрыша вознаграждения
    ///EN The current batch of the reward draw
    game: t_game;
];

///RU Адрес, которому разрешено списывать токены с контракта
///EN The address that is allowed to debit tokens from the contract
type t_approve is address * MToken.t_token;

///RU Уже одобренные адреса для списания токенов с контракта
///EN Already approved addresses for debiting tokens from the contract
type t_approved is big_map(t_approve, unit);

///RU Идентификация фермы
///EN Farm identification
type t_farm_ident is address * nat;

///RU Использованные фермы
///EN Used farms
type t_farms is big_map(t_farm_ident, unit);

#endif // !TYPES_INCLUDED

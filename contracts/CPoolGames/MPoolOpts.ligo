#if !MCTRL_INCLUDED
#define MCTRL_INCLUDED

//RU Модуль управления пулом
module MPoolOpts is {

//RU --- Состояния пула

    type t_pool_state is nat;//RU< Состояние пула

    //RU Пул активен
    //RU 
    //RU Периодически разыгрывается вознаграждение для всех участников пула
    const c_STATE_ACTIVE: t_pool_state = 0n;

    //RU Пул приостановлен
    //RU 
    //RU Если партия активна, она продолжается до завершения, но следующая не будет запущена. Депозиты пользователей останутся без изменений
    const c_STATE_PAUSE: t_pool_state = 1n;

    //RU Пул на удаление
    //RU 
    //RU Если партия активна, она продолжается до завершения. По окончании партии (или если она уже завершена) депозиты 
    //RU пользователей будут возвращены и пул будет удален
    const c_STATE_REMOVE: t_pool_state = 2n;

    //RU Пул на удаление немедленно (псевдосостояние - по сути команда)
    //RU
    //RU Без учета состояния партии депозиты пользователей будут возвращены немедленно и пул будет удален
    const c_STATE_FORCE_REMOVE: t_pool_state = 3n;

    //RU Допустимые состояния при создании нового пула
    //RU
    //RU \see c_STATE_ACTIVE, c_STATE_PAUSE
    const c_CREATE_STATEs: set(t_pool_state) = set [c_STATE_ACTIVE; c_STATE_PAUSE];

    //RU Все состояния при управлении уже существующим пулом
    //RU
    //RU \see c_STATE_ACTIVE, c_STATE_PAUSE, c_STATE_REMOVE, c_STATE_FORCE_REMOVE
    const c_STATEs: set(t_pool_state) = set [c_STATE_ACTIVE; c_STATE_PAUSE; c_STATE_REMOVE; c_STATE_FORCE_REMOVE];

//RU --- Алгоритмы розыгрыша вознаграждения

    type t_algo is nat;//RU< Алгоритм пула пула

    //RU Кроме кода алгоритма используются дополнительные настройки minDeposit, maxDeposit, minSeconds

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
    const c_ALGO_TIME: t_algo = 1n;
    
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
    const c_ALGO_TIMEVOL: t_algo = 2n;

    //RU Вероятность выигрыша равновероятна
    //RU
    //RU Вероятность выигрыша равновероятна для всех пользователей в пуле, которые присутствуют на окончание партии. 
    //RU Использование алгоритма без minSeconds уязвимо перед халявщиками, которые входят в пул только перед розыгрышем
    const c_ALGO_EQUAL: t_algo = 3n;

    //RU Алгоритмы определения победителя
    //RU
    //RU \see c_ALGO_TIME, c_ALGO_TIMEVOL, c_ALGO_EQUAL
    const c_ALGOs: set(t_algo) = set [c_ALGO_TIME; c_ALGO_TIMEVOL; c_ALGO_EQUAL];

    //RU Параметры для управления пулом
    type t_opts is [@layout:comb] record [
        //RU Состояние пула
        // \see c_STATEs
        state: t_pool_state;

        //RU Алгоритм пула
        // \see c_ALGOs
        algo: t_algo;

        //RU Длительность партии в секундах
        //RU
        //RU Допустимо в интервале [c_MIN_GAME_SECONDS, c_MAX_GAME_SECONDS]
        // \see c_MIN_GAME_SECONDS, c_MAX_GAME_SECONDS
        gameSeconds: nat;
        
        //RU Процент от вознаграждения для выигрыша
        //RU
        //RU В интервале [1; 100], все остальное сжигается в burnToken
        // \see MPool::burnToken
        winPercent: nat;

        //RU Минимальный депозит для пула
        //RU
        //RU Пул с алгоритмом c_ALGO_TIME не учитывает размер депозита для розыгрыша вознагражедения. Этот параметр позволит избежать
        //RU копеечных депозитов
        //RU 0 - нет ограничения
        minDeposit: nat;

        //RU Максимальный депозит для пула (только для алгоритма c_ALGO_TIMEVOL)
        //RU
        //RU Пул с алгоритмом c_ALGO_TIMEVOL может позволить владельцу большого депозита войти в последний момент и с большой вероятностью 
        //RU забрать вознаграждения. Чтобы ограничить размеры депозитов в пуле разумными рамками и дать пользователям сопоставимые шансы
        //RU этот параметр вместе с minDeposit позволит получить честный розыгрыш.
        //RU 0 - нет ограничения. В алгоритмах кроме c_ALGO_TIMEVOL параметр игнорируется
        maxDeposit: nat;

        //RU Минимальное время (в секундах) нахождения в пуле для участия в розыгрыше
        //RU
        //RU Параметр не влияет на внесение депозита, пользователь может вносить депозит в любой момент, если проходит по другим ограничениям, 
        //RU он сможет участвовать в следующих розыгрышах
        //RU 0 - нет ограничения. Максимальное значение - длительность партии gameSeconds
        // \see gameSeconds
        minSeconds: nat;
    ];

    const c_ERR_UNKNOWN_STATE: string = "MPoolOpts/UnknownState";//RU< Ошибка: Неизвестное состояние
    const c_ERR_INVALID_STATE: string = "MPoolOpts/InvalidState";//RU< Ошибка: Недопустимое состояние
    const c_ERR_UNKNOWN_ALGO: string = "MPoolOpts/UnknownAlgo";//RU< Ошибка: Неизвестный алгоритм
    const c_ERR_INVALID_SECONDS: string = "MPoolOpts/InvalidSeconds";//RU< Ошибка: Недопустимое кол-во секунд
    const c_ERR_INVALID_MIN_SECONDS: string = "MPoolOpts/InvalidMinSeconds";//RU< Ошибка: Недопустимое минимальное кол-во секунд
    const c_ERR_INVALID_MIN_DEPOSIT: string = "MPoolOpts/InvalidMinDeposit";//RU< Ошибка: Минимальный депозит больше максимального

    //RU Проверка подаваемых на вход контракта параметров
    function check(const opts: t_opts; const create: bool): unit is block {
        if c_STATEs contains opts.state then skip
        else failwith(c_ERR_UNKNOWN_STATE);
        if create then block {
            if c_CREATE_STATEs contains opts.state then skip
            else failwith(c_ERR_INVALID_STATE);
        } else skip;
        if c_ALGOs contains opts.algo then skip
        else failwith(c_ERR_UNKNOWN_ALGO);
        if opts.gameSeconds < c_MIN_GAME_SECONDS then failwith(c_ERR_INVALID_SECONDS)
        else block {
            if opts.gameSeconds > c_MAX_GAME_SECONDS then failwith(c_ERR_INVALID_SECONDS)
            else skip;
        };
        if opts.minSeconds > opts.gameSeconds then failwith(c_ERR_INVALID_MIN_SECONDS)
        else skip;
        if (opts.minDeposit > 0n) and (opts.maxDeposit > 0n)
            and (opts.minDeposit > opts.maxDeposit) then failwith(c_ERR_INVALID_MIN_DEPOSIT)
        else skip;
    } with unit;

    //RU Может ли пул не иметь токена для сжигания
    //RU
    //RU Если 100% выигрыша отдается победителю, токен для сжигания не нужен
    [@inline] function maybeNoBurn(const opts: t_opts): bool is (100n = opts.winPercent);

}
#endif // !MCTRL_INCLUDED

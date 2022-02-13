#if !MCTRL_INCLUDED
#define MCTRL_INCLUDED

//RU Модуль управления пулом
module MPoolOpts is {

//RU --- Состояния пула

    //RU Пул активен
    //RU 
    //RU Периодически разыгрывается вознаграждение для всех участников пула
    [@inline] const cSTATE_ACTIVE: t_pool_state = 0n;

    //RU Пул приостановлен
    //RU 
    //RU Если партия активна, она продолжается до завершения, но следующая не будет запущена.
    [@inline] const cSTATE_PAUSE: t_pool_state = 1n;

    //RU Пул на удаление
    //RU
    //RU Если партия активна, она продолжается до завершения. По окончании партии, когда пользователи
    //RU заберут все депозиты, пул будет удален во время списания последнего депозита.
    //RU Если же пул уже пуст на момент вызова, он будет удален немедленно
    [@inline] const cSTATE_REMOVE: t_pool_state = 2n;

    //RU Допустимые состояния при создании нового пула
    //RU
    //RU \see cSTATE_ACTIVE, cSTATE_PAUSE
    const cCREATE_STATEs: set(t_pool_state) = set [cSTATE_ACTIVE; cSTATE_PAUSE];

    //RU Все состояния при управлении уже существующим пулом
    //RU
    //RU \see cSTATE_ACTIVE, cSTATE_PAUSE, cSTATE_REMOVE
    const cSTATEs: set(t_pool_state) = set [cSTATE_ACTIVE; cSTATE_PAUSE; cSTATE_REMOVE];

//RU --- Алгоритмы розыгрыша вознаграждения

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
    [@inline] const cALGO_TIME: t_algo = 1n;
    
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
    [@inline] const cALGO_TIMEVOL: t_algo = 2n;

    //RU Вероятность выигрыша равновероятна
    //RU
    //RU Вероятность выигрыша равновероятна для всех пользователей в пуле, которые присутствуют на окончание партии. 
    //RU Использование алгоритма без minSeconds уязвимо перед халявщиками, которые входят в пул только перед розыгрышем
    [@inline] const cALGO_EQUAL: t_algo = 3n;

    //RU Алгоритмы определения победителя
    //RU
    //RU \see cALGO_TIME, cALGO_TIMEVOL, cALGO_EQUAL
    const cALGOs: set(t_algo) = set [cALGO_TIME; cALGO_TIMEVOL; cALGO_EQUAL];

    const cERR_UNKNOWN_STATE: string = "MPoolOpts/UnknownState";//RU< Ошибка: Неизвестное состояние
    const cERR_INVALID_STATE: string = "MPoolOpts/InvalidState";//RU< Ошибка: Недопустимое состояние
    const cERR_UNKNOWN_ALGO: string = "MPoolOpts/UnknownAlgo";//RU< Ошибка: Неизвестный алгоритм
    const cERR_INVALID_SECONDS: string = "MPoolOpts/InvalidSeconds";//RU< Ошибка: Недопустимое кол-во секунд
    const cERR_INVALID_MIN_SECONDS: string = "MPoolOpts/InvalidMinSeconds";//RU< Ошибка: Недопустимое минимальное кол-во секунд
    const cERR_INVALID_MAX_DEPOSIT: string = "MPoolOpts/InvalidMaxDeposit";//RU< Ошибка: Максимальный депозит меньше минимального
    const cERR_INVALID_PERCENT: string = "MPoolOpts/InvalidPercent";//RU< Ошибка: Сумма процентов победителя+сжигания+комиссии не равна 100

    //RU Проверка параметров пула на валидность
    function check(const opts: t_opts; const creating: bool): unit is block {
        if cSTATEs contains opts.state then skip
        else failwith(cERR_UNKNOWN_STATE);
        if creating then block {
            if cCREATE_STATEs contains opts.state then skip
            else failwith(cERR_INVALID_STATE);
        } else skip;
        if cALGOs contains opts.algo then skip
        else failwith(cERR_UNKNOWN_ALGO);
        if opts.gameSeconds < cMIN_GAME_SECONDS then failwith(cERR_INVALID_SECONDS)
        else block {
            if opts.gameSeconds > cMAX_GAME_SECONDS then failwith(cERR_INVALID_SECONDS)
            else skip;
        };
        if opts.minSeconds > opts.gameSeconds then failwith(cERR_INVALID_MIN_SECONDS)
        else skip;
        if (cALGO_TIMEVOL = opts.algo) and (opts.maxDeposit > 0n)
            and (opts.minDeposit > opts.maxDeposit) then failwith(cERR_INVALID_MAX_DEPOSIT)
        else skip;
        if 100n =/= (opts.winPercent + opts.burnPercent + opts.feePercent) then failwith(cERR_INVALID_PERCENT)
        else skip;
    } with unit;

    //RU Может ли пул не иметь токена для сжигания
    //RU
    //RU Если процент сжигания 0, то токен для сжигания не нужен
    [@inline] function maybeNoBurn(const opts: t_opts): bool is (0n = opts.burnPercent);

    //RU Может ли пул не иметь адреса для комиссии
    //RU
    //RU Если процент вознаграждения 0, то адрес для комиссии не нужен
    [@inline] function maybeNoFeeAddr(const opts: t_opts): bool is (0n = opts.feePercent);

}
#endif // !MCTRL_INCLUDED

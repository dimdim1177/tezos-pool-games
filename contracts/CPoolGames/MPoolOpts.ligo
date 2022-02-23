#if !MCTRL_INCLUDED
#define MCTRL_INCLUDED

///RU Модуль управления пулом
module MPoolOpts is {

    const cERR_INVALID_SECONDS: string = "MPoolOpts/InvalidSeconds";///RU< Ошибка: Недопустимое кол-во секунд
    const cERR_INVALID_MIN_SECONDS: string = "MPoolOpts/InvalidMinSeconds";///RU< Ошибка: Недопустимое минимальное кол-во секунд
    const cERR_INVALID_MAX_DEPOSIT: string = "MPoolOpts/InvalidMaxDeposit";///RU< Ошибка: Максимальный депозит меньше минимального
    const cERR_INVALID_PERCENT: string = "MPoolOpts/InvalidPercent";///RU< Ошибка: Сумма процентов победителя+сжигания+комиссии не равна 100

    ///RU Проверка параметров пула на валидность
    function check(const opts: t_opts): unit is block {
        if opts.gameSeconds < cMIN_GAME_SECONDS then failwith(cERR_INVALID_SECONDS)
        else block {
            if opts.gameSeconds > cMAX_GAME_SECONDS then failwith(cERR_INVALID_SECONDS)
            else skip;
        };
        if opts.minSeconds > opts.gameSeconds then failwith(cERR_INVALID_MIN_SECONDS)
        else skip;
        if (opts.maxDeposit > 0n) and (opts.minDeposit > opts.maxDeposit) then failwith(cERR_INVALID_MAX_DEPOSIT)
        else skip;
        if (0n = opts.winPercent) or (100n =/= (opts.winPercent + opts.burnPercent + opts.feePercent)) then failwith(cERR_INVALID_PERCENT)
        else skip;
    } with unit;

    ///RU Может ли пул не иметь токена для сжигания
    ///RU
    ///RU Если процент сжигания 0, то токен для сжигания не нужен
    [@inline] function maybeNoBurn(const opts: t_opts): bool is (0n = opts.burnPercent);

    ///RU Может ли пул не иметь адреса для комиссии
    ///RU
    ///RU Если процент вознаграждения 0, то адрес для комиссии не нужен
    [@inline] function maybeNoFeeAddr(const opts: t_opts): bool is (0n = opts.feePercent);

}
#endif // !MCTRL_INCLUDED

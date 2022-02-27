#if !MPOOLOPTS_INCLUDED
#define MPOOLOPTS_INCLUDED

///RU Настройки пула
///EN Pool options
module MPoolOpts is {

    ///RU Ошибка: Недопустимое кол-во секунд
    ///EN Error: Invalid number of seconds
    const cERR_INVALID_SECONDS: string = "MPoolOpts/InvalidSeconds";

    ///RU Ошибка: Недопустимое минимальное кол-во секунд
    ///EN Error: Invalid minimum number of seconds
    const cERR_INVALID_MIN_SECONDS: string = "MPoolOpts/InvalidMinSeconds";

    ///RU Ошибка: Максимальный депозит меньше минимального
    ///EN Error: The maximum deposit is less than the minimum
    const cERR_INVALID_MAX_DEPOSIT: string = "MPoolOpts/InvalidMaxDeposit";

    ///RU Ошибка: Сумма процентов победителя+сжигания+комиссии не равна 100
    ///EN Error: The sum of the winner's percentage+burning+commission is not equal to 100
    const cERR_INVALID_PERCENT: string = "MPoolOpts/InvalidPercent";

    ///RU Проверка параметров пула на валидность
    ///EN Checking the pool parameters for validity
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
    ///EN Can a pool not have a token to burn
    ///EN
    ///EN If the percentage of burning is 0, then the token is not needed for burning
    [@inline] function maybeNoBurn(const opts: t_opts): bool is (0n = opts.burnPercent);

    ///RU Может ли пул не иметь адреса для комиссии
    ///RU
    ///RU Если процент вознаграждения 0, то адрес для комиссии не нужен
    ///EN Can a pool not have an address for a commission
    ///EN
    ///EN If the percentage of remuneration is 0, then the address for the commission is not needed
    [@inline] function maybeNoFeeAddr(const opts: t_opts): bool is (0n = opts.feePercent);

}
#endif // !MPOOLOPTS_INCLUDED

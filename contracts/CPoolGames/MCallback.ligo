#if !MCALLBACK_INCLUDED
#define MCALLBACK_INCLUDED

//RU Статистика пула
module MCallback is {

    const cERR_FAIL: string = "MCallback/Fail";//RU< Ошибка: Не удалось создать точку входа колбека

    //RU Получить точку входа onRandom
    function onRandomEntrypoint(const _: unit): MRandom.t_callback is
        case (Tezos.get_entrypoint_opt("%onRandom", Tezos.self_address): option(MRandom.t_callback)) of
        Some(onrandom) -> onrandom
        | None -> (failwith(cERR_FAIL): MRandom.t_callback)
        end;

    //RU Получить точку входа onBalanceFA1_2
    function onBalanceFA1_2Entrypoint(const _: unit): contract(MFA1_2.t_balance_callback_params) is
        case (Tezos.get_entrypoint_opt("%onBalanceFA1_2", Tezos.self_address): option(contract(MFA1_2.t_balance_callback_params))) of
        Some(onBalance) -> onBalance
        | None -> (failwith(cERR_FAIL): contract(MFA1_2.t_balance_callback_params))
        end;

    //RU Получить точку входа onBalanceFA2
    function onBalanceFA2Entrypoint(const _: unit): contract(MFA2.t_balance_callback_params) is
        case (Tezos.get_entrypoint_opt("%onBalanceFA2", Tezos.self_address): option(contract(MFA2.t_balance_callback_params))) of
        Some(onBalance) -> onBalance
        | None -> (failwith(cERR_FAIL): contract(MFA2.t_balance_callback_params))
        end;

    //RU Получить точку входа afterReward
    function afterRewardEntrypoint(const _: unit): contract(t_ipool) is
        case (Tezos.get_entrypoint_opt("%afterReward", Tezos.self_address): option(contract(t_ipool))) of
        Some(afterReward) -> afterReward
        | None -> (failwith(cERR_FAIL): contract(t_ipool))
        end;

    //RU Колбек AfterReward
    function operAfterReward(const ipool: t_ipool): operation is
        Tezos.transaction(
            ipool,
            0mutez,
            afterRewardEntrypoint(unit)
        );

}
#endif // !MCALLBACK_INCLUDED
#if !MCALLBACK_INCLUDED
#define MCALLBACK_INCLUDED

///RU Вспомогательные функции для колбеков
///EN Auxiliary functions for callbacks
module MCallback is {

    ///RU Ошибка: Не удалось создать точку входа колбека
    ///EN Error: Failed to create a callback entry point
    const cERR_FAIL: string = "MCallback/Fail";

    ///RU Получить точку входа onRandom
    ///EN Get an onRandom entry point
    /// \see CPoolGames::t_entrypoint::OnRandom
    function onRandomEntrypoint(const _: unit): MRandom.t_callback is
        case (Tezos.get_entrypoint_opt("%onRandom", Tezos.self_address): option(MRandom.t_callback)) of [
        | Some(onrandom) -> onrandom
        | None -> (failwith(cERR_FAIL): MRandom.t_callback)
        ];

    ///RU Получить точку входа onBalanceFA1_2
    ///EN Get the onBalanceFA1_2 entry point
    /// \see OnBalanceFA1_2
    function onBalanceFA1_2Entrypoint(const _: unit): contract(MFA1_2.t_balance_callback_params) is
        case (Tezos.get_entrypoint_opt("%onBalanceFA1_2", Tezos.self_address): option(contract(MFA1_2.t_balance_callback_params))) of [
        | Some(onBalance) -> onBalance
        | None -> (failwith(cERR_FAIL): contract(MFA1_2.t_balance_callback_params))
        ];

    ///RU Получить точку входа onBalanceFA2
    ///EN Get the onBalanceFA2 entry point
    /// \see OnBalanceFA2
    function onBalanceFA2Entrypoint(const _: unit): contract(MFA2.t_balance_callback_params) is
        case (Tezos.get_entrypoint_opt("%onBalanceFA2", Tezos.self_address): option(contract(MFA2.t_balance_callback_params))) of [
        | Some(onBalance) -> onBalance
        | None -> (failwith(cERR_FAIL): contract(MFA2.t_balance_callback_params))
        ];

    ///RU Получить точку входа afterReward2Tez
    ///EN Get the entry point afterReward2Tez
    /// \see AfterReward2Tez
    function afterReward2TezEntrypoint(const _: unit): contract(t_ipool) is
        case (Tezos.get_entrypoint_opt("%afterReward2Tez", Tezos.self_address): option(contract(t_ipool))) of [
        | Some(afterReward2Tez) -> afterReward2Tez
        | None -> (failwith(cERR_FAIL): contract(t_ipool))
        ];

    ///RU Операция с самоколбеком AfterReward2Tez
    ///EN Operation with self-check AfterReward2Tez
    /// \see AfterReward2Tez
    function opAfterReward2Tez(const ipool: t_ipool): operation is
        Tezos.transaction(
            ipool,
            0mutez,
            afterReward2TezEntrypoint(unit)
        );

}
#endif // !MCALLBACK_INCLUDED

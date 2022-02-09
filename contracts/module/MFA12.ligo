#if !FA12_INCLUDED
#define FA12_INCLUDED

//RU Типы и методы для FA1.2
module MFA12 is {
    
    //RU Входные параметры для метода transfer
    type t_transfer_params is michelson_pair(address, "from", michelson_pair(address, "to", nat, "value"), "");

    //RU Прототип метода transfer
    type t_transfer is FA12Transfer of t_transfer_params;

    //RU Контракт с точкой входа transfer
    type t_transfer_contract is contract(t_transfer);

    //RU Входные параметры для метода balance
    type t_balance_params is michelson_pair(address, "owner", contract(nat), "");

    //RU Прототип метода balance
    type t_balance is FA12Balance of t_balance_params;

    //RU Контракт с точкой входа balance
    type t_balance_contract is contract(t_balance);

    //RU Входные параметры для метода approve
    type t_approve_params is michelson_pair(address, "spender", nat, "value");

    //RU Прототип метода approve
    type t_approve is FA12Approve of t_approve_params;

    //RU Контракт с точкой входа approve
    type t_approve_contract is contract(t_approve);

    const c_ERR_NOT_FOUND_TRANSFER: string = "MFA12/NotFoundTransfer";//RU< Ошибка: Не найден метод transfer токена
    const c_ERR_NOT_FOUND_BALANCE: string = "MFA12/NotFoundBalance";//RU< Ошибка: Не найден метод balance токена
    const c_ERR_NOT_FOUND_APPROVE: string = "MFA12/NotFoundApprove";//RU< Ошибка: Не найден метод approve токена

    //RU Получить точку входа transfer токена
    function getTransferEntrypoint(const addr: address): t_transfer_contract is
        case (Tezos.get_entrypoint_opt("%transfer", addr): option(t_transfer_contract)) of
        Some(transfer_contract) -> transfer_contract
        | None -> (failwith(c_ERR_NOT_FOUND_TRANSFER): t_transfer_contract)
        end

    //RU Получить точку входа balance токена
    function getBalanceEntrypoint(const addr: address): t_balance_contract is
        case (Tezos.get_entrypoint_opt("%getBalance", addr): option(t_balance_contract)) of
        Some(balance_contract) -> balance_contract
        | None -> (failwith(c_ERR_NOT_FOUND_BALANCE): t_balance_contract)
        end

    //RU Получить точку входа approve токена
    function getApproveEntrypoint(const addr: address): t_approve_contract is
        case (Tezos.get_entrypoint_opt("%approve", addr): option(t_approve_contract)) of
        Some(approve_contract) -> approve_contract
        | None -> (failwith(c_ERR_NOT_FOUND_APPROVE): t_approve_contract)
        end

}
#endif // FA12_INCLUDED

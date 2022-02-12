#if !MFA1_2_INCLUDED
#define MFA1_2_INCLUDED

//RU Типы и методы для FA1.2
module MFA1_2 is {
    
    //RU Входные параметры для метода transfer
    type t_transfer_params is [@layout:comb] record [
        src: address;
        dst: address;
        tamount: nat;
    ];

    //RU Прототип метода transfer
    type t_transfer is FA12Transfer of t_transfer_params;

    //RU Контракт с точкой входа transfer
    type t_transfer_contract is contract(t_transfer);

    //RU Входные параметры для метода balance
    type t_balance_params is [@layout:comb] record [
        owner: address;
        c: contract(nat);
    ];

    //RU Прототип метода balance
    type t_balance is FA12Balance of t_balance_params;

    //RU Контракт с точкой входа balance
    type t_balance_contract is contract(t_balance);

    //RU Входные параметры для метода approve
    type t_approve_params is [@layout:comb] record [
        spender: address;
        value: nat;
    ];

    //RU Прототип метода approve
    type t_approve is FA12Approve of t_approve_params;

    //RU Контракт с точкой входа approve
    type t_approve_contract is contract(t_approve);

    const cERR_NOT_FOUND_TRANSFER: string = "MFA1_2/NotFoundTransfer";//RU< Ошибка: Не найден метод transfer токена
    const cERR_NOT_FOUND_BALANCE: string = "MFA1_2/NotFoundBalance";//RU< Ошибка: Не найден метод balance токена
    const cERR_NOT_FOUND_APPROVE: string = "MFA1_2/NotFoundApprove";//RU< Ошибка: Не найден метод approve токена

    //RU Получить точку входа transfer токена
    function transferEntrypoint(const addr: address): t_transfer_contract is
        case (Tezos.get_entrypoint_opt("%transfer", addr): option(t_transfer_contract)) of
        Some(transfer_contract) -> transfer_contract
        | None -> (failwith(cERR_NOT_FOUND_TRANSFER): t_transfer_contract)
        end

    //RU Параметры для перевода токенов
    function transferParams(const src: address; const dst: address; const tamount: nat): t_transfer is
        FA12Transfer(record [
            src = src;
            dst = dst;
            tamount = tamount;
        ]);

    //RU Операция перевода токенов
    function transfer(const token: address; const src: address; const dst: address; const tamount: nat): operation is
        Tezos.transaction(
            transferParams(src, dst, tamount),
            0mutez,
            transferEntrypoint(token)
        );

    //RU Получить точку входа balance токена
    function balanceEntrypoint(const addr: address): t_balance_contract is
        case (Tezos.get_entrypoint_opt("%getBalance", addr): option(t_balance_contract)) of
        Some(balance_contract) -> balance_contract
        | None -> (failwith(cERR_NOT_FOUND_BALANCE): t_balance_contract)
        end

    //RU Получить точку входа approve токена
    function approveEntrypoint(const addr: address): t_approve_contract is
        case (Tezos.get_entrypoint_opt("%approve", addr): option(t_approve_contract)) of
        Some(approve_contract) -> approve_contract
        | None -> (failwith(cERR_NOT_FOUND_APPROVE): t_approve_contract)
        end

    //RU Проверка на соответствие стандарту FA1.2
    function check(const addr: address): unit is block {
        const _: t_transfer_contract = transferEntrypoint(addr);//RU Проверяем наличие метода transfer для FA1.2
    } with unit;

}
#endif // !MFA1_2_INCLUDED

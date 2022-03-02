#if !MFA1_2_INCLUDED
#define MFA1_2_INCLUDED

///RU Типы и методы для FA1.2
///EN Types and methods for FA1.2
module MFA1_2 is {

    ///RU Входные параметры для метода transfer
    ///EN Input parameters for the transfer method
    type t_transfer_params is [@layout:comb] record [
        ///RU Откуда переводим
        ///EN From where we translate
        src: address;
        ///RU Куда переводим
        ///EN Where are we transferring to
        dst: address;
        ///RU Сколько переводим
        ///EN How much are we transferring
        tamount: nat;
    ];

    ///RU Прототип метода transfer
    ///EN Prototype of the transfer method
    type t_transfer_method is FA12Transfer of t_transfer_params;

    ///RU Контракт с точкой входа transfer
    ///EN Contract with the transfer entry point
    type t_transfer_contract is contract(t_transfer_method);

    ///RU Параметры колбека баланса
    ///EN Balance Callback Parameters
    type t_balance_callback_params is nat;

    ///RU Тип колбека для получения баланса
    ///EN The type of callback to get the balance
    type t_balance_callback is contract(t_balance_callback_params);

    ///RU Входные параметры для метода balance
    ///EN Input parameters for the balance method
    type t_balance_params is [@layout:comb] record [
        ///RU Чей баланс запрашиваем
        ///EN Whose balance we are requesting
        owner: address;
        ///RU Колбек с балансом
        ///EN Colback with balance
        callback: t_balance_callback;
    ];

    ///RU Прототип метода balance
    ///EN Prototype of the balance method
    type t_balance_method is FA12Balance of t_balance_params;

    ///RU Контракт с точкой входа balance
    ///EN Contract with the balance entry point
    type t_balance_contract is contract(t_balance_method);

    ///RU Входные параметры для метода approve
    ///EN Input parameters for the approve method
    type t_approve_params is [@layout:comb] record [
        spender: address;
        value: nat;
    ];

    ///RU Прототип метода approve
    ///EN Prototype of the approve method
    type t_approve_method is FA12Approve of t_approve_params;

    ///RU Контракт с точкой входа approve
    ///EN Contract with the approve entry point
    type t_approve_contract is contract(t_approve_method);

    const cERR_NOT_FOUND_TRANSFER: string = "MFA1_2/NotFoundTransfer";///RU< Ошибка: Не найден метод transfer токена ///EN< Error: The token transfer method was not found
    const cERR_NOT_FOUND_BALANCE: string = "MFA1_2/NotFoundBalance";///RU< Ошибка: Не найден метод balance токена ///EN< Error: The balance token method was not found
    const cERR_NOT_FOUND_APPROVE: string = "MFA1_2/NotFoundApprove";///RU< Ошибка: Не найден метод approve токена ///EN< Error: The approve token method was not found

    ///RU Получить точку входа transfer токена
    ///EN Get the transfer token entry point
    function transferEntrypoint(const addr: address): t_transfer_contract is
        case (Tezos.get_entrypoint_opt("%transfer", addr): option(t_transfer_contract)) of [
        | Some(transfer_contract) -> transfer_contract
        | None -> (failwith(cERR_NOT_FOUND_TRANSFER): t_transfer_contract)
        ];

    ///RU Параметры для перевода токенов
    ///EN Parameters for transferring tokens
    function transferParams(const src: address; const dst: address; const tamount: nat): t_transfer_method is
        FA12Transfer(record [
            src = src;
            dst = dst;
            tamount = tamount;
        ]);

    ///RU Операция перевода токенов
    ///EN Token Transfer Operation
    function transfer(const token: address; const src: address; const dst: address; const tamount: nat): operation is
        Tezos.transaction(
            transferParams(src, dst, tamount),
            0mutez,
            transferEntrypoint(token)
        );

    ///RU Получить точку входа balance токена
    ///EN Get the balance token entry point
    function balanceEntrypoint(const addr: address): t_balance_contract is
        case (Tezos.get_entrypoint_opt("%getBalance", addr): option(t_balance_contract)) of [
        | Some(balance_contract) -> balance_contract
        | None -> (failwith(cERR_NOT_FOUND_BALANCE): t_balance_contract)
        ];

    ///RU Параметры для запроса баланса
    ///EN Parameters for balance request
    function balanceParams(const owner: address; const callback: t_balance_callback): t_balance_method is
        FA12Balance(record [
            owner = owner;
            callback = callback;
        ]);

    ///RU Операция перевода токенов
    ///EN Token Transfer Operation
    function balanceOf(const token: address; const owner: address; const callback: t_balance_callback): operation is
        Tezos.transaction(
            balanceParams(owner, callback),
            0mutez,
            balanceEntrypoint(token)
        );

    ///RU Получить точку входа approve токена
    ///EN Get the approve token entry point
    function approveEntrypoint(const addr: address): t_approve_contract is
        case (Tezos.get_entrypoint_opt("%approve", addr): option(t_approve_contract)) of [
        | Some(approve_contract) -> approve_contract
        | None -> (failwith(cERR_NOT_FOUND_APPROVE): t_approve_contract)
        ];

    ///RU Параметры для одобрения распоряжения токенами
    ///EN Parameters for approving the disposal of tokens
    function approveParams(const operator: address; const tamount: nat): t_approve_method is
        FA12Approve(record [
            spender = operator;
            value = tamount;
        ]);

    ///RU Операция одобрения распоряжения токенами
    ///EN The operation of approving the disposal of tokens
    function approve(const token: address; const operator: address; const tamount: nat): operation is
        Tezos.transaction(
            approveParams(operator, tamount),
            0mutez,
            approveEntrypoint(token)
        );

    ///RU Операция запрета распоряжения токенами
    ///EN The operation of prohibiting the disposal of tokens
    function decline(const token: address; const operator: address): operation is
        Tezos.transaction(
            approveParams(operator, 0n),
            0mutez,
            approveEntrypoint(token)
        );

    ///RU Проверка на соответствие стандарту FA1.2
    ///EN Checking for compliance with the FA1.2 standard
    function check(const token: address): unit is block {
        const _ = transferEntrypoint(token);//RU Проверяем наличие метода transfer для FA1.2 //EN Checking for the transfer method for FA1.2
        const _ = balanceEntrypoint(token);//RU Проверяем наличие метода getBalance для FA1.2 //EN Checking for the getBalance method for FA1.2
        const _ = approveEntrypoint(token);//RU Проверяем наличие метода approve для FA1.2 //EN Checking for the approve method for FA1.2
    } with unit;

}
#endif // !MFA1_2_INCLUDED

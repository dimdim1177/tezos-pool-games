#if !MFA1_2_INCLUDED
#define MFA1_2_INCLUDED

///RU Типы и методы для FA1.2
module MFA1_2 is {
    
    ///RU Входные параметры для метода transfer
    type t_transfer_params is [@layout:comb] record [
        ///RU Откуда переводим
        src: address;
        ///RU Куда переводим
        dst: address;
        ///RU Сколько переводим
        tamount: nat;
    ];

    ///RU Прототип метода transfer
    type t_transfer_method is FA12Transfer of t_transfer_params;

    ///RU Контракт с точкой входа transfer
    type t_transfer_contract is contract(t_transfer_method);

    ///RU Параметры колбека баланса
    type t_balance_callback_params is nat;

    ///RU Тип колбека для получения баланса
    type t_balance_callback is contract(t_balance_callback_params);

    ///RU Входные параметры для метода balance
    type t_balance_params is [@layout:comb] record [
        ///RU Чей баланс запрашиваем
        owner: address;
        ///RU Колбек с балансом
        callback: t_balance_callback;
    ];

    ///RU Прототип метода balance
    type t_balance_method is FA12Balance of t_balance_params;

    ///RU Контракт с точкой входа balance
    type t_balance_contract is contract(t_balance_method);

    ///RU Входные параметры для метода approve
    type t_approve_params is [@layout:comb] record [
        spender: address;
        value: nat;
    ];

    ///RU Прототип метода approve
    type t_approve_method is FA12Approve of t_approve_params;

    ///RU Контракт с точкой входа approve
    type t_approve_contract is contract(t_approve_method);

    const cERR_NOT_FOUND_TRANSFER: string = "MFA1_2/NotFoundTransfer";///RU< Ошибка: Не найден метод transfer токена
    const cERR_NOT_FOUND_BALANCE: string = "MFA1_2/NotFoundBalance";///RU< Ошибка: Не найден метод balance токена
    const cERR_NOT_FOUND_APPROVE: string = "MFA1_2/NotFoundApprove";///RU< Ошибка: Не найден метод approve токена

    ///RU Получить точку входа transfer токена
    function transferEntrypoint(const addr: address): t_transfer_contract is
        case (Tezos.get_entrypoint_opt("%transfer", addr): option(t_transfer_contract)) of [
        | Some(transfer_contract) -> transfer_contract
        | None -> (failwith(cERR_NOT_FOUND_TRANSFER): t_transfer_contract)
        ];

    ///RU Параметры для перевода токенов
    function transferParams(const src: address; const dst: address; const tamount: nat): t_transfer_method is
        FA12Transfer(record [
            src = src;
            dst = dst;
            tamount = tamount;
        ]);

    ///RU Операция перевода токенов
    function transfer(const token: address; const src: address; const dst: address; const tamount: nat): operation is
        Tezos.transaction(
            transferParams(src, dst, tamount),
            0mutez,
            transferEntrypoint(token)
        );

    ///RU Получить точку входа balance токена
    function balanceEntrypoint(const addr: address): t_balance_contract is
        case (Tezos.get_entrypoint_opt("%getBalance", addr): option(t_balance_contract)) of [
        | Some(balance_contract) -> balance_contract
        | None -> (failwith(cERR_NOT_FOUND_BALANCE): t_balance_contract)
        ];

    ///RU Параметры для запроса баланса
    function balanceParams(const owner: address; const callback: t_balance_callback): t_balance_method is
        FA12Balance(record [
            owner = owner;
            callback = callback;
        ]);

    ///RU Операция перевода токенов
    function balanceOf(const token: address; const owner: address; const callback: t_balance_callback): operation is
        Tezos.transaction(
            balanceParams(owner, callback),
            0mutez,
            balanceEntrypoint(token)
        );

    ///RU Получить точку входа approve токена
    function approveEntrypoint(const addr: address): t_approve_contract is
        case (Tezos.get_entrypoint_opt("%approve", addr): option(t_approve_contract)) of [
        | Some(approve_contract) -> approve_contract
        | None -> (failwith(cERR_NOT_FOUND_APPROVE): t_approve_contract)
        ];

    ///RU Параметры для одобрения распоряжения токенами
    function approveParams(const operator: address; const tamount: nat): t_approve_method is
        FA12Approve(record [
            spender = operator;
            value = tamount;
        ]);

    ///RU Операция одобрения распоряжения токенами
    function approve(const token: address; const operator: address; const tamount: nat): operation is
        Tezos.transaction(
            approveParams(operator, tamount),
            0mutez,
            approveEntrypoint(token)
        );

    ///RU Операция запрета распоряжения токенами
    function decline(const token: address; const operator: address): operation is
        Tezos.transaction(
            approveParams(operator, 0n),
            0mutez,
            approveEntrypoint(token)
        );

    ///RU Проверка на соответствие стандарту FA1.2
    function check(const token: address): unit is block {
        const _: t_transfer_contract = transferEntrypoint(token);///RU Проверяем наличие метода transfer для FA1.2
        const _: t_balance_contract = balanceEntrypoint(token);///RU Проверяем наличие метода getBalance для FA1.2
        const _: t_approve_contract = approveEntrypoint(token);///RU Проверяем наличие метода approve для FA1.2
    } with unit;

}
#endif // !MFA1_2_INCLUDED

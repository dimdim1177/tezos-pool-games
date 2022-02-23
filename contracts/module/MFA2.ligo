#if !MFA2_INCLUDED
#define MFA2_INCLUDED

///RU Типы и методы для FA2
module MFA2 is {
    
    ///RU ID токена ///EN Token ID
    type t_token_id is nat;

    ///RU Одно назначения для перевода токенов
    type t_transfer_dst is [@layout:comb] record [
        dst: address;///RU< Получатель токенов ///EN< Recipient of tokens
        token_id: t_token_id;///RU< ID токена ///EN< Token ID
        tamount: nat;///RU< Кол-во токенов для перевода ///EN< Number of tokens for transfer
    ];

    ///RU Список перечислений с одного адреса
    type t_transfer_src2dsts is [@layout:comb] record [
        src: address;///RU< Отправитель токенов ///EN< Sender of tokens
        transer_dsts: list(t_transfer_dst);///RU< Перечисления ///EN< Transactions
    ];

    ///RU Список перечислений с разных адресов
    type t_transfer_params is list(t_transfer_src2dsts);

    ///RU Прототип метода transfer
    type t_transfer_method is FA2Transfer of t_transfer_params;

    ///RU Контракт с точкой входа transfer
    type t_transfer_contract is contract(t_transfer_method);

    ///RU Запрос баланса
    type t_balance_request is [@layout:comb] record [
        ///RU Владелец токенов ///EN Owner of tokens
        owner: address;
        ///RU ID токена ///EN Token ID
        token_id: t_token_id;
    ];

    ///RU Ответ на запрос баланса
    type t_balance_response is [@layout:comb] record [
        ///RU Запрос баланса ///EN Request of balance
        request: t_balance_request;
        ///RU Баланс ///EN Balance
        balance: nat;
    ];

    ///RU Параметры колбека баланса
    type t_balance_callback_params is list(t_balance_response);

    ///RU Тип колбека на запрос баланса
    type t_balance_callback is contract(t_balance_callback_params);

    ///RU Запросы баланса и колбек для возврата ответов
    type t_balance_params is [@layout:comb] record [
        ///RU Запросы баланса ///EN Requests of balance
        requests: list(t_balance_request);
        ///RU Колбек с ответами на запросы ///EN Callback for balance responces
        callback: t_balance_callback;
    ];

    ///RU Прототип метода balance
    type t_balance_method is FA2Balance of t_balance_params;

    ///RU Контракт с точкой входа balance_of
    type t_balance_contract is contract(t_balance_method);

    ///RU Один оператор
    type t_operator is [@layout:comb] record [
        ///RU Владелец токенов ///EN Owner of tokens
        owner: address;
        ///RU Оператор токена ///EN Operator of token
        operator: address;
        ///RU ID токена ///EN Token ID
        token_id: t_token_id;
    ];

    ///RU Прототипы операторов
    type t_operators_case is Add_operator of t_operator | Remove_operator of t_operator;

    ///RU Параметры метода update_operators
    type t_operators_params is list(t_operators_case);

    ///RU Прототип метода update_operators
    type t_operators_method is FA2Operators of t_operators_params;

    ///RU Контракт с точкой входа update_operators
    type t_operators_contract is contract(t_operators_method);

    const cERR_NOT_FOUND_TRANSFER: string = "MFA2/NotFoundTransfer";///RU< Ошибка: Не найден метод transfer токена
    const cERR_NOT_FOUND_BALANCEOF: string = "MFA2/NotFoundBalanceOf";///RU< Ошибка: Не найден метод balance_of токена
    const cERR_NOT_FOUND_OPERATORS: string = "MFA2/NotFoundUpdateOperators";///RU< Ошибка: Не найден метод update_operators токена

    ///RU Получить точку входа transfer токена
    function transferEntrypoint(const addr: address): t_transfer_contract is
        case (Tezos.get_entrypoint_opt("%transfer", addr): option(t_transfer_contract)) of [
        | Some(transfer_contract) -> transfer_contract
        | None -> (failwith(cERR_NOT_FOUND_TRANSFER): t_transfer_contract)
        ];

    ///RU Параметры для перевода токенов
    function transferParams(const token_id: t_token_id; const src: address; const dst: address; const tamount: nat): t_transfer_method is
        FA2Transfer(list [
            record [
                src = src;
                transer_dsts = list [
                    record [
                        dst = dst;
                        token_id = token_id;
                        tamount = tamount;
                    ]
                ]
            ]
        ]);

    ///RU Операция перевода токенов
    function transfer(const token: address; const token_id: t_token_id; const src: address; const dst: address; const tamount: nat): operation is
        Tezos.transaction(
            transferParams(token_id, src, dst, tamount),
            0mutez,
            transferEntrypoint(token)
        );

    ///RU Получить точку входа balance_of токена
    function balanceEntrypoint(const addr: address): t_balance_contract is
        case (Tezos.get_entrypoint_opt("%balance_of", addr): option(t_balance_contract)) of [
        | Some(balance_contract) -> balance_contract
        | None -> (failwith(cERR_NOT_FOUND_BALANCEOF): t_balance_contract)
        ];

    ///RU Параметры для запроса баланса токенов
    function balanceParams(const token_id: t_token_id; const owner: address; const callback: t_balance_callback): t_balance_method is
        FA2Balance(record [
            requests = list [
                record [
                    owner = owner;
                    token_id = token_id;
                ]
            ];
            callback = callback;
        ]);

    ///RU Запрос баланса токенов
    function balanceOf(const token: address; const token_id: t_token_id; const owner: address; const callback: t_balance_callback): operation is
        Tezos.transaction(
            balanceParams(token_id, owner, callback),
            0mutez,
            balanceEntrypoint(token)
        );

    ///RU Получить точку входа update_operators токена
    function operatorsEntrypoint(const addr: address): t_operators_contract is
        case (Tezos.get_entrypoint_opt("%update_operators", addr): option(t_operators_contract)) of [
        | Some(operators_contract) -> operators_contract
        | None -> (failwith(cERR_NOT_FOUND_OPERATORS): t_operators_contract)
        ];

    ///RU Параметры для одобрения распоряжения токенами
    function approveParams(const token_id: t_token_id; const operator: address): t_operators_method is
        FA2Operators(list [
            Add_operator(record [
                owner = Tezos.self_address;
                operator = operator;
                token_id = token_id;
            ])
        ]);

    ///RU Операция одобрения распоряжения токенами
    function approve(const token: address; const token_id: t_token_id; const operator: address): operation is
        Tezos.transaction(
            approveParams(token_id, operator),
            0mutez,
            operatorsEntrypoint(token)
        );

    ///RU Параметры для запрета распоряжения токенами
    function declineParams(const token_id: t_token_id; const operator: address): t_operators_method is
        FA2Operators(list [
            Remove_operator(record [
                owner = Tezos.self_address;
                operator = operator;
                token_id = token_id;
            ])
        ]);

    ///RU Операция запрета распоряжения токенами
    function decline(const token: address; const token_id: t_token_id; const operator: address): operation is
        Tezos.transaction(
            declineParams(token_id, operator),
            0mutez,
            operatorsEntrypoint(token)
        );


    ///RU Проверка на соответствие стандарту FA2
    function check(const token: address): unit is block {
        const _: t_transfer_contract = transferEntrypoint(token);//RU Проверяем наличие метода transfer для FA2
        const _: t_balance_contract = balanceEntrypoint(token);//RU Проверяем наличие метода balance_of для FA2
        const _: t_operators_contract = operatorsEntrypoint(token);//RU Проверяем наличие метода update_operators для FA2
    } with unit;

}
#endif // !MFA2_INCLUDED

#if !MFA2_INCLUDED
#define MFA2_INCLUDED

//RU Типы и методы для FA2
module MFA2 is {
    
    //RU ID токена //EN Token ID
    type t_token_id is nat;

    //RU Одно перечисление
    type t_transfer_dst is [@layout:comb] record [
        //RU Получатель токенов //EN Recipient of tokens 
        dst: address;
        //RU ID токена //EN Token ID
        token_id: t_token_id;
        //RU Кол-во токенов //EN Number of tokens
        amount: nat;
    ];

    //RU Список перечислений с одного адреса
    type t_transfer_src2dsts is [@layout:comb] record [
        //RU Отправитель токенов //EN Sender of tokens
        src: address;
        //RU Перечисления //EN Transactions
        transer_dsts: list(t_transfer_dst);
    ];

    //RU Список перечислений с разных адресов
    type t_transfer_list is list(t_transfer_src2dsts);

    //RU Прототип метода transfer
    type t_transfer is FA2Transfer of t_transfer_list;

    //RU Контракт с точкой входа transfer
    type t_transfer_contract is contract(t_transfer);

    //RU Запрос баланса
    type t_balance_request is [@layout:comb] record [
        //RU Владелец токенов //EN Owner of tokens
        owner: address;
        //RU ID токена //EN Token ID
        token_id: t_token_id;
    ];

    //RU Ответ на запрос баланса
    type t_balance_response is [@layout:comb] record [
        //RU Запрос баланса //EN Request of balance
        request: t_balance_request;
        //RU Баланс //EN Balance
        balance: nat;
    ];

    //RU Запросы баланса и колбек для возврата ответов
    type t_balance_requests is [@layout:comb] record [
        //RU Запросы баланса //EN Requests of balance
        requests: list(t_balance_request);
        //RU Колбек с ответами на запросы //EN Callback for balance responces
        callback: contract(list(t_balance_response));
    ];

    //RU Контракт с точкой входа balance_of
    type t_balance_contract is contract(t_balance_requests);

    //RU Один оператор
    type t_operator is [@layout:comb] record [
        //RU Владелец токенов //EN Owner of tokens
        owner: address;
        //RU Оператор токена //EN Operator of token
        operator: address;
        //RU ID токена //EN Token ID
        token_id: t_token_id;
    ];

    //RU Прототипы операторов
    type t_operators_case is
    | Add_operator of t_operator
    | Remove_operator of t_operator

    //RU Прототип метода update_operators
    type t_operators is FA2Operators of list(t_operators_case)

    //RU Контракт с точкой входа update_operators
    type t_operators_contract is contract(t_operators);

    const c_ERR_NOT_FOUND_TRANSFER: string = "MFA2/NotFoundTransfer";//RU< Ошибка: Не найден метод transfer токена
    const c_ERR_NOT_FOUND_BALANCEOF: string = "MFA2/NotFoundBalanceOf";//RU< Ошибка: Не найден метод balance_of токена
    const c_ERR_NOT_FOUND_OPERATORS: string = "MFA2/NotFoundUpdateOperators";//RU< Ошибка: Не найден метод update_operators токена

    //RU Получить точку входа transfer токена
    function getTransferEntrypoint(const addr: address): t_transfer_contract is
        case (Tezos.get_entrypoint_opt("%transfer", addr): option(t_transfer_contract)) of
        Some(transfer_contract) -> transfer_contract
        | None -> (failwith(c_ERR_NOT_FOUND_TRANSFER): t_transfer_contract)
        end

    //RU Получить точку входа balance_of токена
    function getBalanceEntrypoint(const addr: address): t_balance_contract is
        case (Tezos.get_entrypoint_opt("%balance_of", addr): option(t_balance_contract)) of
        Some(balance_contract) -> balance_contract
        | None -> (failwith(c_ERR_NOT_FOUND_BALANCEOF): t_balance_contract)
        end

    //RU Получить точку входа update_operators токена
    function getOperatorsEntrypoint(const addr: address): t_operators_contract is
        case (Tezos.get_entrypoint_opt("%update_operators", addr): option(t_operators_contract)) of
        Some(operators_contract) -> operators_contract
        | None -> (failwith(c_ERR_NOT_FOUND_OPERATORS): t_operators_contract)
        end

}
#endif // !MFA2_INCLUDED

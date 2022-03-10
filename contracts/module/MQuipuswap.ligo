#if !MQUIPUSWAP_INCLUDED
#define MQUIPUSWAP_INCLUDED

///RU Типы и методы для обменника токенов через tez в формате Quipuswap
///EN Types and methods for the token exchanger via tez in Quipuswap format
module MQuipuswap is {

    type t_swap is address;///RU< Обменник одного токена на tez ///EN< One token exchange for tez

    ///RU Параметры для конвертации tez в токен
    ///EN Parameters for convert tez to token
    type t_tez2token_params is nat * address;

    ///RU Прототип метода tezToTokenPayment
    ///EN Prototype of the tezToTokenPayment method
    type t_tez2token_method is Tez2Token of t_tez2token_params;

    ///RU Контракт с точкой входа tezToTokenPayment
    ///EN Contract with tezToTokenPayment entry point
    type t_tez2token_contract is contract(t_tez2token_method);

    ///RU Параметры для конвертации токена в tez
    ///EN Parameters for convert token to tez
    type t_token2tez_params is nat * nat * address;

    ///RU Прототип метода tokenToTezPayment
    ///EN Prototype of the tokenToTezPayment method
    type t_token2tez_method is Token2Tez of t_token2tez_params;

    ///RU Контракт с точкой входа tokenToTezPayment
    ///EN Contract with tokenToTezPayment entry point
    type t_token2tez_contract is contract(t_token2tez_method);

    ///RU Ошибка: Не найден метод tezToTokenPayment
    ///EN Error: tezToTokenPayment method not found
    const cERR_NOT_FOUND_TEZ2TOKEN: string = "MRandom/NotFoundTez2Token";

    ///RU Ошибка: Не найден метод tokenToTezPayment
    ///EN Error: tokenToTezPayment method not found
    const cERR_NOT_FOUND_TOKEN2TEZ: string = "MRandom/NotFoundToken2Tez";

    ///RU Получить точку входа tezToTokenPayment
    ///EN Get the tezToTokenPayment entry point
    function tez2tokenEntrypoint(const addr: address): t_tez2token_contract is
        case (Tezos.get_entrypoint_opt("%tezToTokenPayment", addr): option(t_tez2token_contract)) of [
        | Some(contract) -> contract
        | None -> (failwith(cERR_NOT_FOUND_TEZ2TOKEN): t_tez2token_contract)
        ];

    ///RU Параметры для обмена tezToTokenPayment
    ///EN Parameters for exchanging tezToTokenPayment
    function tez2tokenParams(const min_out: nat; const receiver: address): t_tez2token_method is
        Tez2Token(min_out, receiver);

    ///RU Операция создания запроса tezToTokenPayment
    ///EN tezToTokenPayment Request Creation Operation
    function tez2token(const addr: address; const changeTez: tez; const min_out: nat; const receiver: address): operation is
        Tezos.transaction(
            tez2tokenParams(min_out, receiver),
            changeTez,
            tez2tokenEntrypoint(addr)
        );

    ///RU Получить точку входа tokenToTezPayment
    ///EN Get the tokenToTezPayment entry point
    function token2tezEntrypoint(const addr: address): t_token2tez_contract is
        case (Tezos.get_entrypoint_opt("%tokenToTezPayment", addr): option(t_token2tez_contract)) of [
        | Some(contract) -> contract
        | None -> (failwith(cERR_NOT_FOUND_TOKEN2TEZ): t_token2tez_contract)
        ];

    ///RU Параметры для обмена tokenToTezPayment
    ///EN Parameters for exchanging tokenToTezPayment
    function token2tezParams(const tamount: nat; const min_out: nat; const receiver: address): t_token2tez_method is
        Token2Tez(tamount, min_out, receiver);

    ///RU Операция создания запроса tokenToTezPayment
    ///EN Operation of creating a tokenToTezPayment request
    function token2tez(const addr: address; const tamount: nat; const min_out: nat; const receiver: address): operation is
        Tezos.transaction(
            token2tezParams(tamount, min_out, receiver),
            0mutez,
            token2tezEntrypoint(addr)
        );

    ///RU Проверка параметров обменника токена на валидность
    ///EN Checking the parameters of the token exchanger for validity
    function check(const swap: t_swap): unit is block {
        //RU Проверяем наличие метода tezToTokenPayment для обменника
        //EN We check the availability of the tezToTokenPayment method for the exchanger
        const _ = tez2tokenEntrypoint(swap);

        //RU Проверяем наличие метода tokenToTezPayment для обменника
        //EN We check the presence of the tokenToTezPayment method for the exchanger
        const _ = token2tezEntrypoint(swap);
    } with unit;

}
#endif // !MQUIPUSWAP_INCLUDED

#if !MQUIPUSWAP_INCLUDED
#define MQUIPUSWAP_INCLUDED

//RU Типы и методы для обменника токенов через tez в формате Quipuswap
module MQuipuswap is {

    type t_swap is address;//RU< Обменник одного токена на tez

    //RU Прототип метода tezToTokenPayment
    type t_tez2token_method is Tez2Token of nat * address;

    //RU Контракт с точкой входа tezToTokenPayment
    type t_tez2token_contract is contract(t_tez2token_method);

    //RU Прототип метода tokenToTezPayment
    type t_token2tez_method is Token2Tez of nat * nat * address;

    //RU Контракт с точкой входа tokenToTezPayment
    type t_token2tez_contract is contract(t_token2tez_method);

    const cERR_NOT_FOUND_TEZ2TOKEN: string = "MRandom/NotFoundTez2Token";//RU< Ошибка: Не найден метод tezToTokenPayment
    const cERR_NOT_FOUND_TOKEN2TEZ: string = "MRandom/NotFoundToken2Tez";//RU< Ошибка: Не найден метод tokenToTezPayment

    //RU Получить точку входа tezToTokenPayment
    function tez2tokenEntrypoint(const addr: address): t_tez2token_contract is
        case (Tezos.get_entrypoint_opt("%tezToTokenPayment", addr): option(t_tez2token_contract)) of
        Some(contract) -> contract
        | None -> (failwith(cERR_NOT_FOUND_TEZ2TOKEN): t_tez2token_contract)
        end;

    //RU Параметры для обмена tezToTokenPayment
    function tez2tokenParams(const min_out: nat; const receiver: address): t_tez2token_method is
        Tez2Token(min_out, receiver);

    //RU Операция создания запроса tezToTokenPayment
    function tez2token(const addr: address; const min_out: nat; const receiver: address): operation is
        Tezos.transaction(
            tez2tokenParams(min_out, receiver),
            0mutez,
            tez2tokenEntrypoint(addr)
        );

    //RU Получить точку входа tokenToTezPayment
    function token2tezEntrypoint(const addr: address): t_token2tez_contract is
        case (Tezos.get_entrypoint_opt("%tokenToTezPayment", addr): option(t_token2tez_contract)) of
        Some(contract) -> contract
        | None -> (failwith(cERR_NOT_FOUND_TOKEN2TEZ): t_token2tez_contract)
        end;

    //RU Параметры для обмена tokenToTezPayment
    function token2tezParams(const tamount: nat; const min_out: nat; const receiver: address): t_token2tez_method is
        Token2Tez(tamount, min_out, receiver);

    //RU Операция создания запроса tokenToTezPayment
    function token2tez(const addr: address; const tamount: nat; const min_out: nat; const receiver: address): operation is
        Tezos.transaction(
            token2tezParams(tamount, min_out, receiver),
            0mutez,
            token2tezEntrypoint(addr)
        );

    //RU Проверка параметров обменника токена на валидность
    function check(const swap: t_swap): unit is block {
        const _: t_tez2token_contract = tez2tokenEntrypoint(swap);//RU Проверяем наличие метода tezToTokenPayment для обменника
        const _: t_token2tez_contract = token2tezEntrypoint(swap);//RU Проверяем наличие метода tokenToTezPayment для обменника
    } with unit;

}
#endif // !MQUIPUSWAP_INCLUDED

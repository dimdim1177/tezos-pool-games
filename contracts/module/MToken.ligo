#if !MTOKEN_INCLUDED
#define MTOKEN_INCLUDED

#include "MFA1_2.ligo"
#include "MFA2.ligo"

///RU Модуль для работы с токенами разных стандартов
///EN Module for working with tokens of different standards
module MToken is {

    type t_amount is nat;///RU< Кол-во токенов ///EN< Number of tokens

    ///RU Стандарты токенов FA2, FA1.2 ///EN Token standards FA2, FA1.2
    type t_fa is FA2 | FA1_2;

    ///RU Токен
    ///EN Token
    type t_token is [@layout:comb] record [
        addr: address;///RU< Адрес токена ///EN< Token Address
        token_id: MFA2.t_token_id;///RU< ID токена ///EN< Token ID
        fa: t_fa;///RU Стандарты токенов ///EN Token standards
    ];

    ///RU Проверка параметров токена на валидность
    ///EN Checking the token parameters for validity
    function check(const token: t_token): unit is block {
        case token.fa of [
        | FA2 -> MFA2.check(token.addr) //RU Проверяем наличие метода transfer для FA2 //EN Checking for the transfer method for FA2
        | FA1_2 -> MFA1_2.check(token.addr) //RU Проверяем наличие метода transfer для FA1.2 //EN Checking for the transfer method for FA1.2
        ];
    } with unit;

    ///RU Сравненеи токенов
    ///EN Comparison of tokens
    function isEqual(const token0: t_token; const token1: t_token): bool is
        (token0.addr = token1.addr) and (token0.token_id = token1.token_id) and (token0.fa = token1.fa);

    ///RU Перевод токенов
    ///EN Transfer of tokens
    function transfer(const token: t_token; const src: address; const dst: address; const tamount: t_amount): operation is
        case token.fa of [
        | FA2 -> MFA2.transfer(token.addr, token.token_id, src, dst, tamount)
        | FA1_2 -> MFA1_2.transfer(token.addr, src, dst, tamount)
        ];

    ///RU Запрос баланса токенов
    ///EN Request for a token balance
    function balanceOf(const token: t_token; const owner: address; const callbackFA1_2: MFA1_2.t_balance_callback; const callbackFA2: MFA2.t_balance_callback): operation is
        case token.fa of [
        | FA2 -> MFA2.balanceOf(token.addr, token.token_id, owner, callbackFA2)
        | FA1_2 -> MFA1_2.balanceOf(token.addr, owner, callbackFA1_2)
        ];

    ///RU Одобрение распоряжения токенами
    ///EN Approval of Token Disposal
    function approve(const token: t_token; const operator: address; const tamount: t_amount): operation is
        case token.fa of [
        | FA2 -> MFA2.approve(token.addr, token.token_id, operator)
        | FA1_2 -> MFA1_2.approve(token.addr, operator, tamount)
        ];

    ///RU Запрет распоряжения токенами
    ///EN Prohibition of token disposal
    function decline(const token: t_token; const operator: address): operation is
        case token.fa of [
        | FA2 -> MFA2.decline(token.addr, token.token_id, operator)
        | FA1_2 -> MFA1_2.decline(token.addr, operator)
        ];

    ///RU Сжигание токенов
    ///EN Burning tokens
    function burn(const token: t_token; const src: address; const bamount: t_amount): operation is
        case token.fa of [
        | FA2 -> MFA2.transfer(token.addr, token.token_id, src, cZERO_ADDRESS, bamount)
        | FA1_2 -> MFA1_2.transfer(token.addr, src, cZERO_ADDRESS, bamount)
        ];

}
#endif // !MTOKEN_INCLUDED

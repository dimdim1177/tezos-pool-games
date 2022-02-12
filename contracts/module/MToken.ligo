#if !MTOKEN_INCLUDED
#define MTOKEN_INCLUDED

#include "MFA1_2.ligo"
#include "MFA2.ligo"

//RU Модуль для работы с токенами разных стандартов
module MToken is {

    type t_amount is nat;//RU< Кол-во токенов (или mutez, если это XTZ токен)

    //RU Стандарты токенов FA2, FA1.2 //EN Token standards FA2, FA1.2
    type t_fa is FA2 | FA1_2;

    type t_token is [@layout:comb] record [
        addr: address;//RU< Адрес токена
        token_id: MFA2.t_token_id;//RU< ID токена
        fa: t_fa;//RU Стандарты токенов //EN Token standards
    ];

    //RU Проверка параметров токена на валидность
    function check(const token: t_token): unit is block {
        case token.fa of
        | FA2 -> MFA2.check(token.addr) //RU Проверяем наличие метода transfer для FA2
        | FA1_2 -> MFA1_2.check(token.addr) //RU Проверяем наличие метода transfer для FA1.2
        end;
    } with unit;

    //RU Перевод токенов
    function transfer(const token: t_token; const src: address; const dst: address; const tamount: t_amount): operation is
        case token.fa of
        | FA2 -> MFA2.transfer(token.addr, token.token_id, src, dst, tamount)
        | FA1_2 -> MFA1_2.transfer(token.addr, src, dst, tamount)
        end;

}
#endif // !MTOKEN_INCLUDED

#if !MTOKEN_INCLUDED
#define MTOKEN_INCLUDED

#include "MFA1_2.ligo"
#include "MFA2.ligo"

//RU Модуль для работы с токенами разных стандартов
module MToken is {

//RU --- Стандарты токенов //EN --- Token standards
    const c_NO    : nat = 0n;//RU< Нет токена
    const c_XTZ   : nat = 1n;//RU< Нативный токен XTZ
    const c_FA1_2 : nat = 12n;//< FA1.2
    const c_FA2   : nat = 20n;//< FA2
    const c_FAs: set(nat) = set [c_XTZ; c_FA1_2; c_FA2];//RU< Все стандарты

    type t_token is [@layout:comb] record [
        addr: address;//RU< Адрес токена
        token_id: MFA2.t_token_id;//RU< ID токена
        fa: nat;//RU< Стандарт FA токена, см. c_FA...
    ];

    const c_ERR_UNKNOWN_FA: string = "MToken/UnknownFA";//RU< Ошибка: Неизвестный стандарт FA

    //RU Проверка параметров токена на валидность
    function check(const token: t_token; const maybeNo: bool): unit is block {
        if (maybeNo) and (token.fa = c_NO) then skip
        else block {
            if c_FAs contains token.fa then skip
            else failwith(c_ERR_UNKNOWN_FA);
            if c_FA1_2 = token.fa then block {
                const _:MFA1_2.t_transfer_contract = MFA1_2.getTransferEntrypoint(token.addr);//RU Проверяем наличие метода transfer для FA1.2
            } else skip;
            if c_FA2 = token.fa then block {
                const _:MFA2.t_transfer_contract = MFA2.getTransferEntrypoint(token.addr);//RU Проверяем наличие метода transfer для FA2
            } else skip;
        };
    } with unit;

    function opt2token(const opttoken: option(t_token)): t_token is
        case opttoken of
        Some(token) -> token
        | None -> record [
            addr = Tezos.self_address;
            token_id = 0n;
            fa = c_NO;
        ]
        end;

}
#endif // !MTOKEN_INCLUDED

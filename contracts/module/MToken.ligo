#if !MTOKEN_INCLUDED
#define MTOKEN_INCLUDED

#include "MFA1_2.ligo"
#include "MFA2.ligo"

//RU Модуль токена
module MToken is {

//RU --- Стандарты токенов //EN --- Token standards
    const c_FA1_2: nat = 12n;//< FA1.2
    const c_FA2  : nat = 20n;//< FA2
    const c_FAs: set(nat) = set [c_FA1_2; c_FA2];//RU< Все стандарты

    type t_token is [@layout:comb] record [
        addr: address;//RU< Адрес токена
        token_id: MFA2.t_token_id;//RU< ID токена
        fa: nat;//RU< Стандарт FA токена, см. c_FA...
    ];

    const c_ERR_UNKNOWN_FA: string = "MToken/UnknownFA";//RU< Ошибка: Неизвестный стандарт FA

    //RU Проверка параметров токена на валидность
    [@inline] function check(const token: t_token): unit is block {
        if c_FAs contains token.fa then skip
        else failwith(c_ERR_UNKNOWN_FA);
        if c_FA1_2 = token.fa then block {
            const _:MFA1_2.t_transfer_contract = MFA1_2.getTransferEntrypoint(token.addr);//RU Проверяем наличие метода transfer для FA1.2
        } else skip;
        if c_FA2 = token.fa then block {
            const _:MFA2.t_transfer_contract = MFA2.getTransferEntrypoint(token.addr);//RU Проверяем наличие метода transfer для FA2
        } else skip;
    } with unit;
}
#endif // !MTOKEN_INCLUDED

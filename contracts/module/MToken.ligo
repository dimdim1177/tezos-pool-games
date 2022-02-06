#if !MTOKEN_INCLUDED
#define MTOKEN_INCLUDED

//RU Модуль токена
module MToken is {

//RU --- Стандарты токенов //EN --- Token standards
    const c_FA1_2: nat = 12n;//< FA1.2
    const c_FA2  : nat = 20n;//< FA2
    const c_FAs: set(nat) = set [c_FA1_2; c_FA2];//RU< Все стандарты

    type t_token is [@layout:comb] record [
        addr: address;//RU< Адрес токена
        id: nat;//RU< ID токена
        fa: nat;//RU< Стандарт FA токена, см. c_FA...
    ];

    const c_ERR_UNKNOWNFA: string = "MToken/UnknownFA";//RU< Ошибка: Неизвестный стандарт FA

    [@inline] function checkToken(const token: t_token): unit is block {
        if c_FAs contains token.fa then skip
        else failwith(c_ERR_UNKNOWNFA);
    } with unit; 
}
#endif // MTOKEN_INCLUDED

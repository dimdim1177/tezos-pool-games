#if !MFARM_INCLUDED
#define MFARM_INCLUDED

#include "MToken.ligo"

//RU Модуль взаимодействия с фермой
module MFarm is {

//RU --- Интерфейсы ферм //EN --- Farm interfaces
    const c_INTERFACE_CRUNCH: nat = 1n;
    
    const c_INTERFACEs: set(nat) = set [c_INTERFACE_CRUNCH];//RU< Все интерфейсы

    //RU Параметры фермы
    type t_farm is [@layout:comb] record [
        addr: address;//RU< Адрес фермы
        id: nat;//RU< ID фермы
        farmToken: MToken.t_token;//RU< Токен фермы
        rewardToken: MToken.t_token;//RU< Токен вознаграждения
        interface: nat;//RU< Интерфейс фермы, см. c_INTERFACE...
    ];

}
#endif // MFARM_INCLUDED

#if !MFARM_INCLUDED
#define MFARM_INCLUDED

#include "MToken.ligo"

//RU Модуль взаимодействия с фермой
module MFarm is {

//RU --- Интерфейсы ферм //EN --- Farm interfaces
    const c_INTERFACE_CRUNCH: nat = 1n;//RU< Crunch
    
    const c_INTERFACEs: set(nat) = set [c_INTERFACE_CRUNCH];//RU< Все интерфейсы

    //RU Параметры фермы
    type t_farm is [@layout:comb] record [
        addr: address;//RU< Адрес фермы
        id: nat;//RU< ID фермы
        farmToken: MToken.t_token;//RU< Токен фермы
        rewardToken: MToken.t_token;//RU< Токен вознаграждения
        interface: nat;//RU< Интерфейс фермы, см. c_INTERFACE...
    ];

    const c_ERR_UNKNOWN_INTERFACE: string = "MFarm/UnknownInterface";//RU< Ошибка: Неизвестный интерфейс фермы

    //RU Проверка подаваемых на вход контракта параметров
    [@inline] function check(const farm: t_farm): unit is block {
        MToken.check(farm.farmToken);
        MToken.check(farm.rewardToken);
        if c_INTERFACEs contains farm.interface then skip
        else failwith(c_ERR_UNKNOWN_INTERFACE);
    } with unit;

}
#endif // MFARM_INCLUDED

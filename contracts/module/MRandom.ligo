#if !MRANDOM_INCLUDED
#define MRANDOM_INCLUDED

//RU Модуль взаимодействия с источником случайных чисел
module MRandom is {

    type t_random is address;//RU< Адрес источника случайных чисел

    const c_ERR_NOT_FOUND: string = "MRandom/NotFound";//RU< Ошибка: Не найден контракт источника

    //RU Проверка источника случайных чисел на валидность
    [@inline] function check(const random: t_random): unit is block {
        case (Tezos.get_contract_opt(random): option(contract(unit))) of
        Some(_c) -> skip
        | None -> failwith(c_ERR_NOT_FOUND)
        end
    } with unit; 
}
#endif // MRANDOM_INCLUDED

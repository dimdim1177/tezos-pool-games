#if !MRANDOM_INCLUDED
#define MRANDOM_INCLUDED

//RU Модуль взаимодействия с источником случайных чисел
module MRandom is {

    type t_random_source is address;//RU< Адрес источника случайных чисел
    type t_iobj is t_i;//RU< ID объекта в контракте заказчике
    type t_event_ts is timestamp;//RU< Время события, для которого случайное число

    //RU Случайное число
    //RU
    //RU Для создания случайного числа берется хеш ближайшего блока Tezos, время которого больше или равно
    //RU времени события, с него снимается SHA-256, получаем значение levelHash. Также хеш SHA-256 снимается 
    //RU со строки "адрес заказчика<пробел><ID объекта в контракте заказчика в десятичной записи>", получаем
    //RU значение requestHash. Оба хеша приводятся к формату nat и случайное число вычисляется как
    //RU random = levelHash ^ requestHash; 
    type t_random is nat;

    const cERR_NOT_FOUND: string = "MRandom/NotFound";//RU< Ошибка: Не найден контракт источника

    //RU Проверка источника случайных чисел на валидность
    function check(const randomSource: t_random_source): unit is block {
        case (Tezos.get_contract_opt(randomSource): option(contract(unit))) of
        Some(_c) -> skip
        | None -> failwith(cERR_NOT_FOUND)
        end
    } with unit; 
}
#endif // !MRANDOM_INCLUDED

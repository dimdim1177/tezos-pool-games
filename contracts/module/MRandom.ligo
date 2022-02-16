#if !MRANDOM_INCLUDED
#define MRANDOM_INCLUDED

//RU Модуль взаимодействия с источником случайных чисел
module MRandom is {

    type t_random_source is address;//RU< Адрес источника случайных чисел
    type t_iobj is t_i;//RU< ID объекта в контракте заказчике
    type t_ts is timestamp;//RU< Время события, для которого случайное число
    type t_ts_iobj is t_ts * t_iobj;//RU< Время события и ID объекта

    //RU Случайное число
    //RU
    //RU Для создания случайного числа берется хеш ближайшего блока Tezos, время которого больше или равно
    //RU времени события, с него снимается SHA-256, получаем значение levelHash. Также хеш SHA-256 снимается 
    //RU со строки "адрес заказчика<пробел><ID объекта в контракте заказчика в десятичной записи>", получаем
    //RU значение requestHash. Cлучайное число вычисляется как random = levelHash ^ requestHash и переводится
    //RU в формат nat. В итоге в общем случае у нас 256-битное случайное число
    type t_random is nat;

    //RU Тип колбека для получения случайного числа
    type t_iobj_random is t_iobj * t_random;
    type t_callback_params is OnRandomCallback of t_iobj_random;
    type t_callback is contract(t_callback_params);

    type t_ts_iobj_callback is t_ts * t_iobj * t_callback;//RU< Время события, ID объекта и колбек для случайного числа

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

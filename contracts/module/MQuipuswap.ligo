#if !MQUIPUSWAP_INCLUDED
#define MQUIPUSWAP_INCLUDED

//RU Типы и методы для обменника токенов через tez в формате Quipuswap
module MQuipuswap is {

    type t_swap is address;

    //RU Проверка параметров обменника токена на валидность
    function check(const _token_swap: t_swap): unit is block {
        skip;//TODO
    } with unit;

}
#endif // !MQUIPUSWAP_INCLUDED

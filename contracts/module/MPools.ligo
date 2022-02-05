#if !MPOOLS_INCLUDED
#define MPOOLS_INCLUDED

#include "MPool.ligo"

//RU Модуль списка пулов ликвидности с периодическими розыгрышами вознаграждений
module MPools is {

    //RU Пулы для розыгрышей вознаграждения
    type t_pools is map(nat, MPool.t_pool);
}
#endif // MPOOLS_INCLUDED

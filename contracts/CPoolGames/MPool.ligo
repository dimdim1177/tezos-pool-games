#if !MPOOL_INCLUDED
#define MPOOL_INCLUDED

#include "../module/MFarm.ligo"
#include "MCtrl.ligo"
#include "MGame.ligo"

//RU Модуль пула ликвидности с периодическими розыгрышами вознаграждений
module MPool is {

    //RU Пул для розыгрышей вознаграждения
    type t_pool is [@layout:comb] record [
        farm: MFarm.t_farm;//RU< Ферма пула
        ctrl: MCtrl.t_ctrl;//RU< Управление пулом
        game: MGame.t_game;//RU< Текущая партия
    ];

}
#endif // MPOOL_INCLUDED

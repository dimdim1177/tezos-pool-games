#if !MPOOL_INCLUDED
#define MPOOL_INCLUDED

#include "../module/MToken.ligo"
#include "../module/MFarm.ligo"
#include "MCtrl.ligo"
#include "MGame.ligo"

//RU Модуль пула ликвидности с периодическими розыгрышами вознаграждений
module MPool is {

    //RU Пул для розыгрышей вознаграждения
    type t_pool is [@layout:comb] record [
        ctrl: MCtrl.t_ctrl;//RU< Управление пулом
        farm: MFarm.t_farm;//RU< Ферма для пула
        game: MGame.t_game;//RU< Текущая партия розыгрыша вознаграждения
    ];

    [@inline] function check(const pool: t_pool): unit is block {
        MCtrl.check(pool.ctrl);
        MFarm.check(pool.farm);
    } with unit; 
}
#endif // MPOOL_INCLUDED

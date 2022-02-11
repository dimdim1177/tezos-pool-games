#if !MPOOLSTAT_INCLUDED
#define MPOOLSTAT_INCLUDED
#if ENABLE_POOL_STAT

//RU Статистика пула
module MPoolStat is {

    //RU Статистика пула
    type t_stat is [@layout:comb] record [
        paidRewards: MFarm.t_amount;//RU< Сколько токенов вознаграждения было выплачено пулом за все партии
        gamesComplete: nat;//RU< Сколько партий уже проведено в этом пуле
    ];

    //RU Заполнение структуры по умолчанию
    [@inline] function create(const _u: unit): t_stat is block {
        const stat: t_stat = record [
            paidRewards = 0n;
            gamesComplete = 0n;
        ];
    } with stat;

}
#endif // ENABLE_POOL_STAT
#endif // !MPOOLSTAT_INCLUDED

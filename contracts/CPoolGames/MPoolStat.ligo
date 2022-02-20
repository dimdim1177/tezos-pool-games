#if !MPOOLSTAT_INCLUDED
#define MPOOLSTAT_INCLUDED
#if ENABLE_POOL_STAT

//RU Статистика пула
module MPoolStat is {

    //RU Заполнение структуры по умолчанию
    function create(const _u: unit): t_stat is block {
        const stat: t_stat = record [
            lastWinner = cZERO_ADDRESS;
            lastReward = 0n;
            paidRewards = 0n;
            gamesComplete = 0n;
        ];
    } with stat;

    function onWin(var pool: t_pool; const winner: address; const reward: t_amount): t_pool is block {
        pool.stat.lastWinner := winner;
        pool.stat.lastReward := reward;
        pool.stat.paidRewards := pool.stat.paidRewards + reward;
        pool.stat.gamesComplete := pool.stat.gamesComplete + 1n;
    } with pool;
}
#endif // ENABLE_POOL_STAT
#endif // !MPOOLSTAT_INCLUDED

#if !MPOOLSTAT_INCLUDED
#define MPOOLSTAT_INCLUDED

///RU Статистика пула
///EN Pool statistics
module MPoolStat is {

    ///RU Создание пустой структуры статистики
    ///EN Create empty struct of statistic
    function create(const _u: unit): t_stat is block {
        const stat: t_stat = record [
            lastWinner = cZERO_ADDRESS;
            lastReward = 0n;
            paidRewards = 0n;
            gamesComplete = 0n;
        ];
    } with stat;

#if ENABLE_POOL_STAT
    ///RU Определен победитель очередного розыгрыша вознаграждения
    ///RU \param winner Адрес победителя
    ///RU \param reward Количество токенов вознаграждения для перечисления победителю
    ///EN The winner of the next prize drawing has been determined
    ///EN \param winner Address of winner
    ///EN \param reward Count of reward tokens for tranfer to winner
    function onWin(var pool: t_pool; const winner: address; const reward: MToken.t_amount): t_pool is block {
        pool.stat.lastWinner := winner;
        pool.stat.lastReward := reward;
        pool.stat.paidRewards := pool.stat.paidRewards + reward;
        pool.stat.gamesComplete := pool.stat.gamesComplete + 1n;
    } with pool;
#endif // ENABLE_POOL_STAT

}
#endif // !MPOOLSTAT_INCLUDED

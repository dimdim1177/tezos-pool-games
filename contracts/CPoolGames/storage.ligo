#if !STORAGE_INCLUDED
#define STORAGE_INCLUDED

#include "types.ligo"

type t_storage is [@layout:comb] record [
#if ENABLE_OWNER
    owner: t_owner;//RU< Владелец контракта
#endif // ENABLE_OWNER
#if ENABLE_ADMIN
    admin: t_admin;//RU< Админ контракта
#endif // ENABLE_ADMIN
#if ENABLE_ADMINS
    admins: t_admins;//RU< Набор админов контракта
#endif // ENABLE_ADMINS
    inext: t_ipool;//RU< ID следующего пула
    pools: t_pools;//RU< Собственно пулы
    users: t_ipooladdr2user;//RU< Пользователи пулов
    waitBalanceBeforeHarvest: t_ii;//RU< ID пула, ожидающего баланс до получения вознаграждения из фермы, -1 - не ожидаем
    waitBalanceAfterHarvest: t_ii;//RU< ID пула, ожидающего баланс после получения вознаграждения из фермы, -1 - не ожидаем
    waitBalanceBeforeTez2Burn: t_ii;//RU< ID пула, ожидающего баланс до обмена tez на токены для сжигания, -1 - не ожидаем
    waitBalanceAfterTez2Burn: t_ii;//RU< ID пула, ожидающего баланс после обмена tez на токены для сжигания, -1 - не ожидаем
    //RU Использованные фермы
    //RU
    //RU Если два пула будут одновременно использовать одну ферму это приведет к тому, что одна заберет
    //RU вознаграждение другой. Поэтому фиксируем использованные фермы и запрещаем создавать пулы с уже
    //RU существующими фермами
    usedFarms: t_farms;
#if !ENABLE_TRANSFER_SECURITY
    //RU Адреса, которым уже одобрили использование токенов контракта
    //RU
    //RU Для уменьшения кол-ва операций, одобряем ферме использование токенов контракта только один раз
    approved: t_approved;
#endif // !ENABLE_TRANSFER_SECURITY
];

//RU Тип результата отработки контракта
type t_return is t_operations * t_storage;

#endif // !STORAGE_INCLUDED

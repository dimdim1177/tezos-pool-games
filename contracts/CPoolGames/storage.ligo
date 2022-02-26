#if !STORAGE_INCLUDED
#define STORAGE_INCLUDED

#include "types.ligo"

///RU Хранилище контракта
///EN Contract Storage
type t_storage is [@layout:comb] record [
#if ENABLE_OWNER
    owner: MOwner.t_owner;///RU< Владелец контракта ///EN< Contract Owner
#endif // ENABLE_OWNER
#if ENABLE_ADMIN
    admin: MAdmins.t_admin;///RU< Админ контракта ///EN< Contract Admin
#endif // ENABLE_ADMIN
#if ENABLE_ADMINS
    admins: MAdmins.t_admins;///RU< Набор админов контракта ///EN< Set of Contract admins
#endif // ENABLE_ADMINS

    inext: t_ipool;///RU< ID следующего пула ///EN< ID of the next pool
    pools: t_pools;///RU< Собственно пулы ///EN< Actual pools
    users: t_ipooladdr2user;///RU< Пользователи пулов ///EN< Pool Users

    ///RU ID пула, ожидающего баланс до получения вознаграждения из фермы, -1 - не ожидаем
    ///EN ID of the pool waiting for the balance before receiving the reward from the farm, -1 - not expected
    waitBalanceBeforeHarvest: t_ii;

    ///RU ID пула, ожидающего баланс после получения вознаграждения из фермы, -1 - не ожидаем
    ///EN ID of the pool waiting for the balance after receiving the reward from the farm, -1 - not expected
    waitBalanceAfterHarvest: t_ii;

    ///RU ID пула, ожидающего баланс до обмена tez на токены для сжигания, -1 - не ожидаем
    ///EN ID of the pool waiting for the balance before exchanging tez for tokens for burning, -1 - not expected
    waitBalanceBeforeTez2Burn: t_ii;

    ///RU ID пула, ожидающего баланс после обмена tez на токены для сжигания, -1 - не ожидаем
    ///EN ID of the pool waiting for the balance after the exchange of tez for tokens for burning, -1 - not expected
    waitBalanceAfterTez2Burn: t_ii;

    ///RU Использованные фермы
    ///RU
    ///RU Если два пула будут одновременно использовать одну ферму это приведет к тому, что одна заберет
    ///RU вознаграждение другой, потому что списывается вознаграждение за всех пользователей, которые могут
    ///RU вносить и извлекать депозиты в любой момент времени. Поэтому фиксируем использованные фермы и запрещаем
    ///RU создавать пулы с уже существующими фермами
    ///EN Used farms
    ///EN
    ///EN If two pools use the same farm at the same time, this will lead to one taking
    ///EN the reward of the other, because the reward is deducted for all users who can
    ///EN make and withdraw deposits at any time. Therefore, we fix the used farms and prohibit
    ///EN the creation of pools with existing farms
    usedFarms: t_farms;

#if !ENABLE_TRANSFER_SECURITY
    ///RU Адреса, которым уже одобрили использование токенов контракта
    ///RU
    ///RU Для уменьшения кол-ва операций, одобряем ферме использование токенов контракта только один раз
    ///RU Одобрения идентифицируются по комбинации адреса и токена, поэтому для нескольких ферм с одинаковыми адресами и
    ///RU токенами, но разными ID будет только одно одобрение на всех
    ///EN Addresses that have already been approved to use contract tokens
    ///EN
    ///EN To reduce the number of operations, we approve the farm to use contract tokens only once
    ///EN Approvals are identified by a combination of address and token, so for several farms with the same addresses and
    ///EN tokens, but different IDs, there will be only one approval at all
    approved: t_approved;
#endif // !ENABLE_TRANSFER_SECURITY
];

///RU Возвращаемый результат контракта
///EN The returned result of the contract
type t_return is t_operations * t_storage;

#endif // !STORAGE_INCLUDED

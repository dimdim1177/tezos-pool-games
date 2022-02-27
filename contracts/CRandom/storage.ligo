#if !STORAGE_INCLUDED
#define STORAGE_INCLUDED

#include "types.ligo"

///RU Хранилище контракта
///EN Contract storage
type t_storage is [@layout:comb] record [
#if ENABLE_OWNER
    owner: MOwner.t_owner;///RU< Владелец контракта ///EN< Contract owner
#endif // ENABLE_OWNER
#if ENABLE_ADMIN
    admin: MAdmins.t_admin;///RU< Админ контракта ///EN< Contract admin
#endif // ENABLE_ADMIN
#if ENABLE_ADMINS
    admins: MAdmins.t_admins;///RU< Набор админов контракта ///EN< Set of contract admins
#endif // ENABLE_ADMINS
    futures: t_futures;///RU< Заказы на колбеки в будущем ///EN< Requests of random numbers
];

///RU Тип результата отработки контракта
///EN The returned result of the contract
type t_return is t_operations * t_storage;

#endif // !STORAGE_INCLUDED

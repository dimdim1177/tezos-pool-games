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
    rpools: t_rpools;//RU< Пулы для розыгрышей
    users: t_users;//RU< Участники всех пулов
];

//RU Тип результата отработки контракта
type t_return is t_operations * t_storage;

#endif // !STORAGE_INCLUDED

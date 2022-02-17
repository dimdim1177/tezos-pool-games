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
#if !ENABLE_TRANSFER_SECURITY
    //RU Адреса, которым уже одобрили использование токенов контракта
    //RU
    //RU Для уменьшения кол-ва операций, одобряем ферме использование токенов контракта только один раз
    approved: big_map(address, unit);
#endif // !ENABLE_TRANSFER_SECURITY
];

//RU Тип результата отработки контракта
type t_return is t_operations * t_storage;

#endif // !STORAGE_INCLUDED

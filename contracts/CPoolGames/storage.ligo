#if !STORAGE_INCLUDED
#define STORAGE_INCLUDED

#include "config.ligo"
#include "../module/MOwner.ligo"
#include "../module/MAdmin.ligo"
#include "../module/MAdmins.ligo"
#include "../module/MManager.ligo"
#include "../module/MManagers.ligo"

type t_storage is [@layout:comb] record [
#if ENABLE_OWNER
    owner: MOwner.t_owner;//RU< Владелец контракта
#endif // ENABLE_OWNER
#if ENABLE_ADMIN
    admin: MAdmin.t_admin;//RU< Админ контракта
#endif // ENABLE_ADMIN
#if ENABLE_ADMINS
    admins: MAdmins.t_admins;//RU< Набор админов контракта
#endif // ENABLE_ADMINS
]

#endif // STORAGE_INCLUDED
#if !ACCESS_INCLUDED
#define ACCESS_INCLUDED

#include "../module/MOwner.ligo"
#include "../module/MAdmin.ligo"
#include "../module/MAdmins.ligo"
#include "../module/MManager.ligo"
#include "../module/MManagers.ligo"
#include "storage.ligo"

(*RU
    Функции для вычисления доступа с учетом включенных модулей управления доступом

    Owner - Владелец контракта, полный доступ к любым операциям
    Admin - Админ, полный доступ к любым операциям, кроме смены владельца
    Manager - Менеджер, полный доступ к операциям в отдельной части контракта
*)

#if ENABLE_ADMIN //RU Есть набор админов контракта

function mustAdmin(const s: t_storage): unit is block {
#if ENABLE_OWNER
    const isOwner: bool = MOwner.isOwner(s.owner);
#else // ENABLE_OWNER
    const isOwner: bool = False;
#endif // ENABLE_OWNER
    if isOwner then skip //RU Владелец как бы админ
    else MAdmin.mustAdmin(s.admin);
} with unit

#else // ENABLE_ADMIN

[@inline] function mustAdmin(const s: t_storage): unit is block { MOwner.mustOwner(s.owner); } with unit

#endif // ENABLE_ADMIN

#if ENABLE_ADMINS //RU Есть набор админов контракта

function mustAdmin(const s: t_storage): unit is block {
#if ENABLE_OWNER
    const isOwner: bool = MOwner.isOwner(s.owner);
#else // ENABLE_OWNER
    const isOwner: bool = False;
#endif // ENABLE_OWNER
    if isOwner then skip //RU Владелец как бы админ
    else MAdmins.mustAdmin(s.admins);
} with unit

#else // ENABLE_ADMINS

[@inline] function mustAdmin(const s: t_storage): unit is block { MOwner.mustOwner(s.owner); } with unit

#endif // ENABLE_ADMINS

#if ENABLE_MANAGER

function mustManager(const s: t_storage; const manager: MManager.t_manager) : unit is block {
#if ENABLE_OWNER
    const isOwner: bool = MOwner.isOwner(s.owner);
#else // ENABLE_OWNER
    const isOwner: bool = False;
#endif // ENABLE_OWNER
    if isOwner then skip //RU Владелец как бы менеджер
    else block {
#if ENABLE_ADMIN
        const isAdmin: bool = MAdmin.isAdmin(s.admin);
#endif // ENABLE_ADMIN
#if ENABLE_ADMINS
        const isAdmin: bool = MAdmins.isAdmin(s.admins);
#endif // ENABLE_ADMINS
#if (!ENABLE_ADMIN) && (!ENABLE_ADMINS)
        const isAdmin: bool = False;
#endif // (!ENABLE_ADMIN) && (!ENABLE_ADMINS)
        if isAdmin then skip //RU Админ как бы менеджер
        else MManager.mustManager(manager);
    }
} with unit

#endif // ENABLE_MANAGER

#if ENABLE_MANAGERS

function mustManager(const s: t_storage; const managers: MManagers.t_managers) : unit is block {
#if ENABLE_OWNER
    const isOwner: bool = MOwner.isOwner(s.owner);
#else // ENABLE_OWNER
    const isOwner: bool = False;
#endif // ENABLE_OWNER
    if isOwner then skip //RU Владелец как бы менеджер
    else block {
#if ENABLE_ADMIN
        const isAdmin: bool = MAdmin.isAdmin(s.admin);
#endif // ENABLE_ADMIN
#if ENABLE_ADMINS
        const isAdmin: bool = MAdmins.isAdmin(s.admins);
#endif // ENABLE_ADMINS
#if (!ENABLE_ADMIN) && (!ENABLE_ADMINS)
        const isAdmin: bool = False;
#endif // (!ENABLE_ADMIN) && (!ENABLE_ADMINS)
        if isAdmin then skip //RU Админ как бы менеджер
        else MManagers.mustManager(managers);
    }
} with unit

#endif // ENABLE_MANAGERS

#endif // ACCESS_INCLUDED

#if !ACCESS_INCLUDED
#define ACCESS_INCLUDED

#include "../module/MOwner.ligo"
#include "../module/MAdmin.ligo"
#include "../module/MAdmins.ligo"
#include "storage.ligo"

(*RU
    Функции для вычисления доступа с учетом включенных модулей управления доступом

    Owner - Владелец контракта, полный доступ к любым операциям
    Admin - Админ, полный доступ к любым операциям, кроме смены владельца
*)

#if ENABLE_ADMIN ///RU Есть набор админов контракта

function isAdmin(const s: t_storage): bool is block {
#if ENABLE_OWNER
    var isAdmin: bool := MOwner.isOwner(s.owner);
#else // ENABLE_OWNER
    var isAdmin: bool := False;
#endif // else ENABLE_OWNER
    if isAdmin then skip ///RU Владелец как бы админ
    else isAdmin := MAdmin.isAdmin(s.admin);
} with isAdmin;

function mustAdmin(const s: t_storage): unit is block {
#if ENABLE_OWNER
    const isOwner: bool = MOwner.isOwner(s.owner);
#else // ENABLE_OWNER
    const isOwner: bool = False;
#endif // else ENABLE_OWNER
    if isOwner then skip ///RU Владелец как бы админ
    else MAdmin.mustAdmin(s.admin);
} with unit;

#endif // else ENABLE_ADMIN

#if ENABLE_ADMINS ///RU Есть набор админов контракта

function isAdmin(const s: t_storage): bool is block {
#if ENABLE_OWNER
    var isAdmin: bool := MOwner.isOwner(s.owner);
#else // ENABLE_OWNER
    var isAdmin: bool := False;
#endif // else ENABLE_OWNER
    if isAdmin then skip ///RU Владелец как бы админ
    else isAdmin:= MAdmins.isAdmin(s.admins);
} with isAdmin;

function mustAdmin(const s: t_storage): unit is block {
#if ENABLE_OWNER
    const isOwner: bool = MOwner.isOwner(s.owner);
#else // ENABLE_OWNER
    const isOwner: bool = False;
#endif // else ENABLE_OWNER
    if isOwner then skip ///RU Владелец как бы админ
    else MAdmins.mustAdmin(s.admins);
} with unit;

#endif // else ENABLE_ADMINS

#if (!ENABLE_ADMIN) && (!ENABLE_ADMINS)

[@inline] function isAdmin(const s: t_storage): bool is MOwner.isOwner(s.owner);
[@inline] function mustAdmin(const s: t_storage): unit is MOwner.mustOwner(s.owner);

#endif // (!ENABLE_ADMIN) && (!ENABLE_ADMINS)

#endif // !ACCESS_INCLUDED

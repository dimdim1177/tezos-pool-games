#if !ACCESS_INCLUDED
#define ACCESS_INCLUDED

#include "../module/MOwner.ligo"
#include "../module/MAdmin.ligo"
#include "../module/MAdmins.ligo"
#include "../module/MManager.ligo"
#include "storage.ligo"

(*RU
    Функции для вычисления доступа с учетом включенных модулей управления доступом

    Owner - Владелец контракта, полный доступ к любым операциям
    Admin - Админ, полный доступ к любым операциям, кроме смены владельца
    Manager - Менеджер, полный доступ к операциям в отдельной части контракта
*)

#if ENABLE_ADMIN //RU Есть набор админов контракта

function isAdmin(const s: t_storage): bool is block {
#if ENABLE_OWNER
    var isAdmin: bool := MOwner.isOwner(s.owner);
#else // ENABLE_OWNER
    var isAdmin: bool := False;
#endif // ENABLE_OWNER
    if isAdmin then skip //RU Владелец как бы админ
    else isAdmin := MAdmin.isAdmin(s.admin);
} with isAdmin;

function mustAdmin(const s: t_storage): unit is block {
#if ENABLE_OWNER
    const isOwner: bool = MOwner.isOwner(s.owner);
#else // ENABLE_OWNER
    const isOwner: bool = False;
#endif // ENABLE_OWNER
    if isOwner then skip //RU Владелец как бы админ
    else MAdmin.mustAdmin(s.admin);
} with unit;

#else // ENABLE_ADMIN

[@inline] function isAdmin(const s: t_storage): bool is block { const isAdmin: bool = MOwner.isOwner(s.owner); } with isAdmin;
[@inline] function mustAdmin(const s: t_storage): unit is block { MOwner.mustOwner(s.owner); } with unit;

#endif // ENABLE_ADMIN

#if ENABLE_ADMINS //RU Есть набор админов контракта

function isAdmin(const s: t_storage): bool is block {
#if ENABLE_OWNER
    var isAdmin: bool := MOwner.isOwner(s.owner);
#else // ENABLE_OWNER
    var isAdmin: bool := False;
#endif // ENABLE_OWNER
    if isAdmin then skip //RU Владелец как бы админ
    else isAdmin:= MAdmins.isAdmin(s.admins);
} with isAdmin;

function mustAdmin(const s: t_storage): unit is block {
#if ENABLE_OWNER
    const isOwner: bool = MOwner.isOwner(s.owner);
#else // ENABLE_OWNER
    const isOwner: bool = False;
#endif // ENABLE_OWNER
    if isOwner then skip //RU Владелец как бы админ
    else MAdmins.mustAdmin(s.admins);
} with unit;

#else // ENABLE_ADMINS

[@inline] function isAdmin(const s: t_storage): bool is block { const isAdmin: bool = MOwner.isOwner(s.owner); } with isAdmin;
[@inline] function mustAdmin(const s: t_storage): unit is block { MOwner.mustOwner(s.owner); } with unit;

#endif // ENABLE_ADMINS

#endif // !ACCESS_INCLUDED

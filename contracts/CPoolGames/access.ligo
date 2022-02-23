#if !ACCESS_INCLUDED
#define ACCESS_INCLUDED

#include "../module/MOwner.ligo"
#include "../module/MAdmin.ligo"
#include "../module/MAdmins.ligo"
#include "storage.ligo"

///RU \file
///RU Функции для проверки доступа с учетом включенных модулей управления доступом
///RU
///RU Owner - Владелец контракта, полный доступ к любым операциям.
///RU Admin - Админ контракта, полный доступ к любым операциям, кроме смены владельца.
///EN \file
///EN Functions to check access based on enabled access control modules
///EN
///EN Owner - Owner of contract, full access to any operations.
///EN Admin - Admin of contract, full access to any operations, except change owner.

#if ENABLE_ADMIN //RU Есть админ контракта //EN Has admin of contract

///RU Является ли Tezos.sender админом контракта
///EN Is Tezos.sender an admin of the contract?
function isAdmin(const s: t_storage): bool is block {
#if ENABLE_OWNER
    var isAdmin: bool := MOwner.isOwner(s.owner);
#else // ENABLE_OWNER
    var isAdmin: bool := False;
#endif // else ENABLE_OWNER
    if isAdmin then skip //RU Владелец как бы админ
    else isAdmin := MAdmin.isAdmin(s.admin);
} with isAdmin;

///RU Если Tezos.sender не админ контракта, генерируется ошибка
///EN If Tezos.sender is not the contract admin, an error is generated
function mustAdmin(const s: t_storage): unit is block {
#if ENABLE_OWNER
    const isOwner: bool = MOwner.isOwner(s.owner);
#else // ENABLE_OWNER
    const isOwner: bool = False;
#endif // else ENABLE_OWNER
    if isOwner then skip //RU Владелец как бы админ
    else MAdmin.mustAdmin(s.admin);
} with unit;

#endif // else ENABLE_ADMIN

#if ENABLE_ADMINS //RU Есть набор админов контракта //EN Has set of admins of contract

///RU Является ли Tezos.sender админом контракта
///EN Is Tezos.sender an admin of the contract?
function isAdmin(const s: t_storage): bool is block {
#if ENABLE_OWNER
    var isAdmin: bool := MOwner.isOwner(s.owner);
#else // ENABLE_OWNER
    var isAdmin: bool := False;
#endif // else ENABLE_OWNER
    if isAdmin then skip //RU Владелец как бы админ
    else isAdmin:= MAdmins.isAdmin(s.admins);
} with isAdmin;

///RU Если Tezos.sender не админ контракта, генерируется ошибка
///EN If Tezos.sender is not the contract admin, an error is generated
function mustAdmin(const s: t_storage): unit is block {
#if ENABLE_OWNER
    const isOwner: bool = MOwner.isOwner(s.owner);
#else // ENABLE_OWNER
    const isOwner: bool = False;
#endif // else ENABLE_OWNER
    if isOwner then skip //RU Владелец как бы админ
    else MAdmins.mustAdmin(s.admins);
} with unit;

#endif // else ENABLE_ADMINS

#if (!ENABLE_ADMIN) && (!ENABLE_ADMINS)

///RU Является ли Tezos.sender админом контракта
///EN Is Tezos.sender an admin of the contract?
[@inline] function isAdmin(const s: t_storage): bool is MOwner.isOwner(s.owner);

///RU Если Tezos.sender не админ контракта, генерируется ошибка
///EN If Tezos.sender is not the contract admin, an error is generated
[@inline] function mustAdmin(const s: t_storage): unit is MOwner.mustOwner(s.owner);

#endif // (!ENABLE_ADMIN) && (!ENABLE_ADMINS)

#endif // !ACCESS_INCLUDED

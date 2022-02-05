#include "include/consts.ligo"
#include "CPoolGames/config.ligo"
#include "CPoolGames/storage.ligo"
#include "CPoolGames/access.ligo"

type t_entrypoint is
#if ENABLE_OWNER
| ChangeOwner of MOwner.t_owner //RU< Смена владельца контракта //EN< Change owner of contract
#endif // ENABLE_OWNER
#if ENABLE_ADMIN
| ChangeAdmin of MAdmin.t_admin //RU< Смена админа контракта //EN< Change admin of contract
#endif // ENABLE_ADMIN
#if ENABLE_ADMINS
| AddAdmin of MAdmins.t_admin //RU< Добавление админа контракта //EN< Add admin of contract
| RemAdmin of MAdmins.t_admin //RU< Удаление админа контракта //EN< Remove admin of contract
#endif // ENABLE_ADMINS

type t_return is list(operation) * t_storage

function main(const entrypoint: t_entrypoint; var s: t_storage): t_return is
case entrypoint of
#if ENABLE_OWNER //RU Есть владелец контракта
| ChangeOwner(params) -> (c_NO_OPERATIONS, block { s.owner:= MOwner.accessChange(params, s.owner); } with s)
#endif // ENABLE_OWNER
#if ENABLE_ADMIN //RU Есть владелец контракта
| ChangeAdmin(params) -> (c_NO_OPERATIONS, block { mustAdmin(s); s.admin := params; } with s)
#endif // ENABLE_ADMIN
#if ENABLE_ADMINS //RU Есть набор админов контракта
| AddAdmin(params) -> (c_NO_OPERATIONS, block { mustAdmin(s); s.admins := MAdmins.forceAdd(params, s.admins); } with s)
| RemAdmin(params) -> (c_NO_OPERATIONS, block { mustAdmin(s); s.admins := MAdmins.forceRem(params, s.admins); } with s)
#endif // ENABLE_ADMINS
end

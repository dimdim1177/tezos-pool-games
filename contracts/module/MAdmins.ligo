#if !MADMINS_INCLUDED
#define MADMINS_INCLUDED

///RU Модуль управления админами контракта
///RU
///RU Добавление нового админа любым админом, удаление любым админом любого админа, включая самого себя.
///RU Последний админ не может удалить сам себя, чтобы в контракте остался хотя бы один админ.
///RU Пример использование модуля без других модулей доступа
///EN Contract admins management module
///EN
///EN Adding a new admin by any admin, removing any admin by any admin, including himself.
///EN The last admin cannot delete himself so that at least one admin remains in the contract.
///EN Example using a module without other access modules
/// \code{.ligo}
/// #Include "module/MAdmins.ligo"
/// type t_storage record [
///     admins: MAdmins.t_admins;
///     ...
/// ];
///
/// type t_entrypoint is
/// | AddAdmin of MAdmins.t_admin
/// | RemAdmin of MAdmins.t_admin
/// ...
///
/// function main(const entrypoint: t_entrypoint; var s: t_storage): t_return is
/// case entrypoint of
/// | AddAdmin(params) -> (cNO_OPERATIONS, block { s.admins := MAdmins.accessAdd(params, s.admins); } with s)
/// | RemAdmin(params) -> (cNO_OPERATIONS, block { s.admins := MAdmins.accessRem(params, s.admins); } with s)
/// ...
/// \endcode
module MAdmins is {

    type t_admin is address;///RU< Адрес админа ///EN< Admin address

    type t_admins is set(t_admin);///RU< Набор админов ///EN< Set of admins

    const cERR_DENIED: string = "MAdmins/Denied";///RU< Ошибка: Нет доступа ///EN< Error: Access denied
    const cERR_REM_LAST_ADMIN: string = "MAdmins/RemLastAdmin";///RU< Ошибка: Удаление последнего админа ///EN< Error: Remove last admin
    const cERR_NOT_FOUND: string = "MAdmins/NotFound";///RU< Ошибка: Не найден админ для удаления ///EN< Not found admin for remove

    ///RU Является ли текущий пользователь админом контракта
    ///EN Is the current user an admin of the contract
    [@inline] function isAdmin(const admins: t_admins): bool is admins contains Tezos.sender;

    ///RU Текущий пользователь должен обладать правами админа контракта
    ///RU
    ///RU Если пользователь не админ, будет возвращена ошибка cDENIED
    ///EN The current user must have the rights of the contract administrator
    ///EN
    ///EN If the user is not an admin, the error cDENIED will be returned
    function mustAdmin(const admins: t_admins): unit is block {
        if isAdmin(admins) then skip
        else failwith(cERR_DENIED);
    } with unit;

    ///RU Добавление админа безусловно
    ///RU
    ///RU Проверка прав на добавление админа должна делаться извне
    ///EN Adding an admin is definitely
    ///EN
    ///EN Checking the rights to add an admin should be done from the outside
    function forceAdd(const addadmin: t_admin; var admins: t_admins): t_admins is Set.add(addadmin, admins);

    ///RU Удаление админа безусловно
    ///RU
    ///RU Проверка прав на удаление админа должна делаться извне
    ///RU Нельзя удалить админа, когда остался только один и нет владельца контракта,
    ///RU который может добавить админа, будет возвращена ошибка cERR_REM_LAST_ADMIN
    ///RU Если админ для удаления не найден, будет возвращена ошибка cERR_NOT_FOUND
    ///EN Removing the admin of course
    ///EN
    ///EN Checking the rights to delete the admin should be done from the outside
    ///EN You cannot delete an admin when there is only one left and there is no contract owner.,
    ///EN which can add an admin, the error cERR_REM_LAST_ADMIN will be returned
    ///EN If the admin for deletion is not found, the error cERR_NOT_FOUND will be returned
    function forceRem(const remadmin: t_admin; var admins: t_admins): t_admins is block {
        if admins contains remadmin then skip
        else failwith(cERR_NOT_FOUND);
#if !ENABLE_OWNER
        if 1n = Set.size(admins) then failwith(cERR_REM_LAST_ADMIN)
        else skip;
#endif // !ENABLE_OWNER
        admins := Set.remove(remadmin, admins);
    } with admins;

#if !ENABLE_OWNER
    ///RU Добавление админа с проверкой прав админа
    ///EN Adding an admin with admin rights verification
    function accessAdd(const addadmin: t_admin; var admins: t_admins): t_admins is block {
        mustAdmin(admins);
        admins := forceAdd(addadmin, admins);
    } with admins;

    ///RU Удаление админа с проверкой прав админа
    ///EN Admin removal with admin rights check
    function accessRem(const remadmin: t_admin; var admins: t_admins): t_admins is block {
        mustAdmin(admins);
        admins := forceRem(remadmin, admins);
    } with admins;

#endif // !ENABLE_OWNER

}
#endif // !MADMINS_INCLUDED

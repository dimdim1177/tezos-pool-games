#if !MADMIN_INCLUDED
#define MADMIN_INCLUDED

///RU Модуль управления админом контракта
///RU
///RU Админ или владелец может заменить админа на другого
///RU Пример использование модуля без других модулей доступа
///EN Contract admin management module
///EN
///EN The admin or the owner can replace the admin with another one
///EN Example using a module without other access modules
/// \code{.ligo}
/// #Include "module/MAdmin.ligo"
/// type t_storage record [
///     admin: MAdmin.t_admin;
///     ...
/// ];
///
/// type t_entrypoint is
/// | ChangeAdmin of MAdmin.t_admin
/// ...
///
/// function main(const entrypoint: t_entrypoint; var s: t_storage): t_return is
/// case entrypoint of
/// | ChangeAdmin(params) -> (cNO_OPERATIONS, block { s.admin:= MAdmin.accessChange(params, s.admin); } with s)
/// ...
/// \endcode
module MAdmin is {

    type t_admin is address;///RU< Админ контракта ///EN< Contract admin

    const cERR_DENIED: string = "MAdmin/Denied";///RU< Ошибка: Нет доступа ///EN< Error: Access denied

    ///RU Является ли текущий пользователь админом
    ///EN Is the current user an admin
    [@inline] function isAdmin(const admin: t_admin): bool is (admin = Tezos.sender);

    ///RU Текущий пользователь должен обладать правами админа
    ///RU
    ///RU Если пользователь не админ, будет возвращена ошибка cERR_DENIED
    ///EN The current user must have admin rights
    ///EN
    ///EN If the user is not an admin, the error cERR_DENIED will be returned
    function mustAdmin(const admin: t_admin): unit is block {
        if isAdmin(admin) then skip
        else failwith(cERR_DENIED);
    } with unit;

#if !ENABLE_OWNER
    ///RU Смена админа с проверкой прав админа
    ///EN Admin change with admin rights check
    function accessChange(const newadmin: t_admin; var admin: t_admin): t_admin is block {
        mustAdmin(admin);
        admin := newadmin;
    } with admin;
#endif // !ENABLE_OWNER

}
#endif // !MADMIN_INCLUDED

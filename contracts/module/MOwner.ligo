#if !MOWNER_INCLUDED
#define MOWNER_INCLUDED

///RU Модуль управления владельцем контракта
///RU
///RU Владелец может заменить владельца на другого
///RU Пример использование модуля без других модулей доступа
///EN Contract owner management module
///EN
///EN The owner can replace the owner with another
///EN Example using a module without other access modules
/// \code{.ligo}
/// #Include "module/MOwner.ligo"
/// type t_storage record [
///     owner: MOwner.t_owner;
///     ...
/// ];
///
/// type t_entrypoint is
/// | ChangeOwner of MOwner.t_owner
/// ...
///
/// function main(const entrypoint: t_entrypoint; var s: t_storage): t_return is
/// case entrypoint of
/// | ChangeOwner(params) -> (cNO_OPERATIONS, block { s.owner:= MOwner.accessChange(params, s.owner); } with s)
/// ...
/// \endcode
module MOwner is {

    type t_owner is address; ///RU< Владелец контракта ///EN< Contract owner

    const cERR_DENIED: string = "MOwner/Denied";///RU< Ошибка: Нет доступа ///EN< Error: Access denied

    ///RU Является ли текущий пользователь владельцем
    ///EN Is the current user the owner
    [@inline] function isOwner(const owner: t_owner): bool is owner = Tezos.sender;

    ///RU Текущий пользователь должен обладать правами владельца
    ///RU
    ///RU Если пользователь не владелец, будет возвращена ошибка cERR_DENIED
    ///EN The current user must have the rights of the owner
    ///EN
    ///EN If the user is not the owner, the error cERR_DENIED will be returned
    function mustOwner(const owner: t_owner): unit is block {
        if isOwner(owner) then skip
        else failwith(cERR_DENIED);
    } with unit;

    ///RU Смена владельца с проверкой прав владельца
    ///EN Change of owner with verification of the owner's rights
    function accessChange(const newowner: t_owner; var owner: t_owner): t_owner is block {
        mustOwner(owner);
        owner := newowner;
    } with owner;

}
#endif // !MOWNER_INCLUDED

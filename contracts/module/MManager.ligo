#if !MMANAGER_INCLUDED
#define MMANAGER_INCLUDED

///RU Модуль управления менеджером
///RU
///RU Изменение нового менеджера любым админом
///RU Пример использование модуля без других модулей доступа
///EN Contract manager module
///EN
///EN Changing a new manager by any admin
///EN Example using a module without other access modules
/// \code{.ligo}
/// #Include "module/MManager.ligo"
/// type t_part record [
///     manager: MManagers.t_manager;
///     ...
/// ];
///
/// type t_entrypoint is
/// | ChangeManager of MManager.t_manager
/// ...
///
/// function main(const entrypoint: t_entrypoint; var s: t_storage): t_return is
/// case entrypoint of
/// | ChangeManager(newmanager) -> (cNO_OPERATIONS, block {
///      if isAdmin(...) then skip
///      else MManager.mustManager(s.part.manager);
///      s.part.manager := newmanager;
/// } with s)
/// ...
module MManager is {

    type t_manager is address;///RU< Адрес менеджера ///EN< Manager's address

    const cERR_DENIED: string = "MManager/Denied";///RU< Ошибка: Нет доступа ///EN< Error: Access denied

    ///RU Является ли текущий пользователь менеджером
    ///EN Is the current user a manager
    [@inline] function isManager(const manager: t_manager): bool is manager = Tezos.sender;

    ///RU Текущий пользователь должен обладать правами менеджера
    ///RU
    ///RU Если пользователь не менеджер, будет возвращена ошибка cDENIED
    ///EN The current user must have the rights of the manager
    ///EN
    ///EN If the user is not a manager, a cDENIED error will be returned.
    function mustManager(const manager: t_manager): unit is block {
        if isManager(manager) then skip
        else failwith(cERR_DENIED);
    } with unit;

}
#endif // !MMANAGER_INCLUDED

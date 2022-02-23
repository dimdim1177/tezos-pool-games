#if !MMANAGER_INCLUDED
#define MMANAGER_INCLUDED

///RU Модуль управления списком менеджеров модуля контракта
///RU
///RU Изменение нового менеджера любым админом
///RU Пример использование модуля без других модулей доступа
// #Include "module/MManager.ligo"
// type t_part record [
//     manager: MManagers.t_manager;
//     ...
// ];
//
// type t_entrypoint is
// | ChangeManager of MManager.t_manager
// ...
//
// function main(const entrypoint: t_entrypoint; var s: t_storage): t_return is
// case entrypoint of
// | ChangeManager(newmanager) -> (cNO_OPERATIONS, block {
//      if isAdmin(...) then skip
//      else MManager.mustManager(s.part.manager);
//      s.part.manager := newmanager;
// } with s)
// ...
module MManager is {
    
    type t_manager is address;///RU< Адрес менеджера

    const cERR_DENIED: string = "MManager/Denied";///RU< Ошибка: Нет доступа ///EN< Error: Access denied

    ///RU Является ли текущий пользователь менеджером модуля
    [@inline] function isManager(const manager: t_manager): bool is manager = Tezos.sender;

    ///RU Текущий пользователь должен обладать правами менеджера модуля
    ///RU
    ///RU Если пользователь не менеджер, будет возвращена ошибка cDENIED
    function mustManager(const manager: t_manager): unit is block {
        if isManager(manager) then skip
        else failwith(cERR_DENIED);
    } with unit;

}
#endif // !MMANAGER_INCLUDED

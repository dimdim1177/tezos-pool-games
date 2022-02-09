#if !MMANAGER_INCLUDED
#define MMANAGER_INCLUDED
#if ENABLE_MANAGER

//RU Модуль управления списком менеджеров модуля контракта
//RU
//RU Изменение нового менеджера любым админом
//RU Пример использование модуля без других модулей доступа
// #Define ENABLE_MANAGER
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
// | ChangeManager(params) -> (c_NO_OPERATIONS, block {
//      if isAdmin(...) then skip
//      else MManager.mustManager(s.part.manager);
//      MManager.forceChange(params, s.part.manager);
// } with s)
// ...
module MManager is {
    
    type t_manager is address;//RU< Адрес менеджера

    const c_ERR_DENIED: string = "MManager/Denied";//RU< Ошибка: Нет доступа
    const c_ERR_ALREADY: string = "MManager/Already";//RU< Ошибка: Уже установлен этот менеджер

    //RU Является ли текущий пользователь менеджером модуля
    [@inline] function isManager(const manager: t_manager): bool is block {
        const r: bool = (manager = Tezos.sender);
    } with r;

    //RU Текущий пользователь должен обладать правами менеджера модуля
    //RU
    //RU Если пользователь не менеджер, будет возвращена ошибка c_DENIED
    [@inline] function mustManager(const manager: t_manager): unit is block {
        if isManager(manager) then skip
        else failwith(c_ERR_DENIED);
    } with unit;

    //RU Изменение менеджера безусловно
    //RU
    //RU Проверка прав на изменение менеджера должна делаться извне
    //RU Если менеджер уже существует, будет возвращена ошибка c_ERR_ALREADY
    [@inline] function forceChange(const newmanager: t_manager; var manager: t_manager): t_manager is block {
        if newmanager = manager then failwith(c_ERR_ALREADY)
        else skip;
        manager := newmanager;
    } with manager;

}
#endif // ENABLE_MANAGER
#endif // MMANAGER_INCLUDED

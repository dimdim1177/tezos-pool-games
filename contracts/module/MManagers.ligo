#if !MMANAGERS_INCLUDED
#define MMANAGERS_INCLUDED
#if ENABLE_MANAGERS

//RU Модуль управления набором менеджеров модуля контракта
module MManagers is {
    
    type t_manager is address;//RU< Адрес менеджера

    type t_managers is set(t_manager);//RU< Набор менеджеров

    const c_ERR_DENIED: string = "MManagers/Denied";//RU< Ошибка: Нет доступа
    const c_ERR_ALREADY: string = "MManagers/Already";//RU< Ошибка: Уже существует этот менеджер
    const c_ERR_NOTFOUND: string = "MManagers/NotFound";//RU< Ошибка: Не найден менеджер для удаления

    //RU Является ли текущий пользователь менеджером модуля
    [@inline] function isManager(const managers: t_managers): bool is block {
        const r: bool = (managers contains Tezos.sender);
    } with r

    //RU Текущий пользователь должен обладать правами менеджера модуля
    //RU
    //RU Если пользователь не менеджер, будет возвращена ошибка c_ERR_DENIED
    [@inline] function mustManager(const managers: t_managers): unit is block {
        if isManager(managers) then skip
        else failwith(c_ERR_DENIED);
    } with unit

    //RU Добавление нового менеджера безусловно
    //RU
    //RU Проверка прав на добавление менеджера должна делаться извне
    //RU Если менеджер уже существует, будет возвращена ошибка c_ERR_ALREADY
    [@inline] function forceAdd(const addmanager: t_manager; var managers: t_managers): t_managers is block {
        if managers contains addmanager then failwith(c_ERR_ALREADY)
        else skip;
        managers := Set.add(addmanager, managers);
    } with managers

    //RU Удаление менеджера безусловно
    //RU
    //RU Проверка прав на удаление менеджера должна делаться извне
    //RU Если менеджер для удаления не найден, будет возвращена ошибка c_ERR_NOTFOUND
    [@inline] function forceRem(const remmanager: t_manager; var managers: t_managers): t_managers is block {
        if managers contains remmanager then skip
        else failwith(c_ERR_NOTFOUND);
        managers := Set.remove(remmanager, managers);
    } with managers

}
#endif // ENABLE_MANAGERS
#endif // MMANAGERS_INCLUDED

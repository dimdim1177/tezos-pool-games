#if !MADMINS_INCLUDED
#define MADMINS_INCLUDED

//RU Модуль управления админами контракта
//RU
//RU Добавление нового админа любым админом, удаление любым админом любого админа, включая самого себя.
//RU Последний админ не может удалить сам себя, чтобы в контракте остался хотя бы один админ.
//RU Пример использование модуля без других модулей доступа
// #Include "module/MAdmins.ligo"
// type t_storage record [
//     admins: MAdmins.t_admins;
//     ...
// ];
//
// type t_entrypoint is
// | AddAdmin of MAdmins.t_admin
// | RemAdmin of MAdmins.t_admin
// ...
//
// function main(const entrypoint: t_entrypoint; var s: t_storage): t_return is
// case entrypoint of
// | AddAdmin(params) -> (cNO_OPERATIONS, block { s.admins := MAdmins.accessAdd(params, s.admins); } with s)
// | RemAdmin(params) -> (cNO_OPERATIONS, block { s.admins := MAdmins.accessRem(params, s.admins); } with s)
// ...
module MAdmins is {
    
    type t_admin is address;//RU< Адрес админа

    type t_admins is set(t_admin);//RU< Набор админов

    const cERR_DENIED: string = "MAdmins/Denied";//RU< Ошибка: Нет доступа
    const cERR_ALREADY: string = "MAdmins/Already";//RU< Ошибка: Уже существует этот админ
    const cERR_REM_LAST_ADMIN: string = "MAdmins/RemLastAdmin";//RU< Ошибка: Удаление последнего админа
    const cERR_NOT_FOUND: string = "MAdmins/NotFound";//RU< Ошибка: Не найден админ для удаления

    //RU Является ли текущий пользователь админом контракта
    [@inline] function isAdmin(const admins: t_admins): bool is admins contains Tezos.sender;

    //RU Текущий пользователь должен обладать правами админа контракта
    //RU
    //RU Если пользователь не админ, будет возвращена ошибка cDENIED
    function mustAdmin(const admins: t_admins): unit is block {
        if isAdmin(admins) then skip
        else failwith(cERR_DENIED);
    } with unit;

    //RU Добавление админа безусловно
    //RU
    //RU Проверка прав на добавление админа должна делаться извне
    //RU Если админ уже существует, будет возвращена ошибка cERR_ALREADY
    function forceAdd(const addadmin: t_admin; var admins: t_admins): t_admins is block {
        if admins contains addadmin then failwith(cERR_ALREADY)
        else skip;
        admins := Set.add(addadmin, admins);
    } with admins;

    //RU Удаление админа безусловно
    //RU
    //RU Проверка прав на удаление админа должна делаться извне
    //RU Нельзя удалить админа, когда остался только один и нет владельца контракта, 
    //RU который может добавить админа, будет возвращена ошибка cERR_REM_LAST_ADMIN
    //RU Если админ для удаления не найден, будет возвращена ошибка cERR_NOT_FOUND
    function forceRem(const remadmin: t_admin; var admins: t_admins): t_admins is block {
#if !ENABLE_OWNER
        if 1n = Set.size(admins) then failwith(cERR_REM_LAST_ADMIN) 
        else skip;
#endif // !ENABLE_OWNER
        if admins contains remadmin then skip
        else failwith(cERR_NOT_FOUND);
        admins := Set.remove(remadmin, admins);
    } with admins;

#if !ENABLE_OWNER
    //RU Добавление админа с проверкой прав админа
    function accessAdd(const addadmin: t_admin; var admins: t_admins): t_admins is block {
        mustAdmin(admins);
        forceAdd(addadmin, admins);
    } with admins;

    //RU Удаление админа с проверкой прав админа
    function accessRem(const remadmin: t_admin; var admins: t_admins): t_admins is block {
        mustAdmin(admins);
        forceRem(remadmin, admins);
    } with admins;

#endif // !ENABLE_OWNER

}
#endif // !MADMINS_INCLUDED

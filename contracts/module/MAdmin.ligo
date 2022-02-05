#if !MADMIN_INCLUDED
#define MADMIN_INCLUDED
#if ENABLE_ADMIN

//RU Модуль управления админом контракта
//RU
//RU Админ или владелец может заменить админа на другого
module MAdmin is {
    
    type t_admin is address;//RU< Админ контракта

    const c_ERR_DENIED: string = "MAdmin/Denied";//RU< Ошибка: Нет доступа
    const c_ERR_ALREADY: string = "MAdmin/Already";//RU< Ошибка: Уже задан

    //RU Является ли текущий пользователь админом
    [@inline] function isAdmin(const admin: t_admin): bool is block {
        const r: bool = (admin = Tezos.sender);
    } with r

    //RU Текущий пользователь должен обладать правами админа
    //RU
    //RU Если пользователь не админ, будет возвращена ошибка c_ERR_DENIED
    [@inline] function mustAdmin(const admin: t_admin): unit is block {
        if isAdmin(admin) then skip
        else failwith(c_ERR_DENIED);
    } with unit

    //RU Смена админа безусловно
    //RU
    //RU Проверка прав на изменение админа должна делаться извне
    //RU Если админ уже установлен, будет возвращена ошибка c_ERR_ALREADY
    [@inline] function forceChange(const newadmin: t_admin; var admin: t_admin): t_admin is block {
        if newadmin = admin then failwith(c_ERR_ALREADY)
        else skip;
        admin := newadmin;
    } with admin

#if !ENABLE_OWNER
    //RU Смена админа с проверкой прав админа
    //RU
    //RU Если владелец уже установлен, будет возвращена ошибка c_ERR_ALREADY
    [@inline] function accessChange(const newadmin: t_admin; var admin: t_admin): t_admin is block {
        mustAdmin(admin);
        forceChange(newadmin, admin);
    } with admin
#endif // !ENABLE_OWNER

}
#endif // ENABLE_ADMIN
#endif // MADMIN_INCLUDED

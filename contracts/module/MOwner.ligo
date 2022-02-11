#if !MOWNER_INCLUDED
#define MOWNER_INCLUDED
#if ENABLE_OWNER

//RU Модуль управления владельцем контракта
//RU
//RU Владелец может заменить владельца на другого
//RU Пример использование модуля без других модулей доступа
// #Define ENABLE_OWNER
// #Include "module/MOwner.ligo"
// type t_storage record [
//     owner: MOwner.t_owner;
//     ...
// ];
//
// type t_entrypoint is
// | ChangeOwner of MOwner.t_owner
// ...
//
// function main(const entrypoint: t_entrypoint; var s: t_storage): t_return is
// case entrypoint of
// | ChangeOwner(params) -> (c_NO_OPERATIONS, block { s.owner:= MOwner.accessChange(params, s.owner); } with s)
// ...
module MOwner is {
    
    type t_owner is address //RU< Владелец контракта

    const c_ERR_DENIED: string = "MOwner/Denied";//RU< Ошибка: Нет доступа
    const c_ERR_ALREADY: string = "MOwner/Already";//RU< Ошибка: Уже задан

    //RU Является ли текущий пользователь владельцем
    [@inline] function isOwner(const owner: t_owner): bool is block {
        const r: bool = (owner = Tezos.sender);
    } with r;

    //RU Текущий пользователь должен обладать правами владельца
    //RU
    //RU Если пользователь не владелец, будет возвращена ошибка c_ERR_DENIED
    [@inline] function mustOwner(const owner: t_owner): unit is block {
        if isOwner(owner) then skip
        else failwith(c_ERR_DENIED);
    } with unit;

    //RU Смена владельца с проверкой прав владельца
    //RU
    //RU Если владелец уже установлен, будет возвращена ошибка c_ERR_ALREADY
    [@inline] function accessChange(const newowner: t_owner; var owner: t_owner): t_owner is block {
        mustOwner(owner);
        if newowner = owner then failwith(c_ERR_ALREADY)
        else skip;
        owner := newowner;
    } with owner;

}
#endif // ENABLE_OWNER
#endif // !MOWNER_INCLUDED

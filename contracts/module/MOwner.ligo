#if !MOWNER_INCLUDED
#define MOWNER_INCLUDED

///RU Модуль управления владельцем контракта
///RU
///RU Владелец может заменить владельца на другого
///RU Пример использование модуля без других модулей доступа
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
// | ChangeOwner(params) -> (cNO_OPERATIONS, block { s.owner:= MOwner.accessChange(params, s.owner); } with s)
// ...
module MOwner is {
    
    type t_owner is address; ///RU< Владелец контракта

    const cERR_DENIED: string = "MOwner/Denied";///RU< Ошибка: Нет доступа ///EN< Error: Access denied

    ///RU Является ли текущий пользователь владельцем
    [@inline] function isOwner(const owner: t_owner): bool is owner = Tezos.sender;

    ///RU Текущий пользователь должен обладать правами владельца
    ///RU
    ///RU Если пользователь не владелец, будет возвращена ошибка cERR_DENIED
    function mustOwner(const owner: t_owner): unit is block {
        if isOwner(owner) then skip
        else failwith(cERR_DENIED);
    } with unit;

    ///RU Смена владельца с проверкой прав владельца
    function accessChange(const newowner: t_owner; var owner: t_owner): t_owner is block {
        mustOwner(owner);
        owner := newowner;
    } with owner;

}
#endif // !MOWNER_INCLUDED

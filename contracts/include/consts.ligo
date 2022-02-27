#if !CONSTS_INCLUDED
#define CONSTS_INCLUDED

(**RU
    \file

    Префиксы:
    С - Контракт
    M - Модуль
    t_ - Тип
    c[_A-Z0-9]+ - Константа
    cERR_[_A-Z0-9]+ - Константа с кодом ошибки для failwith

    //#Include - если будет include, компилятор падает при повторном включении файла
*)
(**EN
    \file

    Prefixes:
    C - Contract
    M - Module
    t_ - Type
    c[_A-Z0-9]+ - Constant
    cERR_[_A-Z0-9]+ - Constant with error code for failwith

    //#Include - if there is an include, the compiler crashes when the file is included again
*)

type t_operations is list(operation);///RU< Список операций ///EN< List of operations
[@inline] const cNO_OPERATIONS: t_operations = nil;///RU< Пустой список операций ///EN< Empty list of operations

///RU Тип для индексов
///EN Type for indexes
type t_i is nat;

///RU Тип для получения индексов, -1 - элемент отсутствует
///EN Type for getting indexes, -1 - element is missing
/// \see cABSENT
type t_ii is int;

[@inline] const cABSENT: t_ii = -1;///RU< Элемент отсутствует ///EN< The element is missing

const cZERO_ADDRESS: address = ("tz1ZZZZZZZZZZZZZZZZZZZZZZZZZZZZNkiRg" : address);///RU< Нулевой address ///EN< Null address
const cZERO_KEY_HASH: key_hash = ("tz1ZZZZZZZZZZZZZZZZZZZZZZZZZZZZNkiRg" : key_hash);///RU< Заглушка для key_hash ///EN< key_hash stub

#endif // !CONSTS_INCLUDED

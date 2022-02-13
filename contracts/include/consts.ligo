#if !CONSTS_INCLUDED
#define CONSTS_INCLUDED

(*RU
    Префиксы:
    С - Контракт
    M - Модуль
    t_ - Тип
    c[_A-Z0-9]+ - Константа
    cERR_[_A-Z0-9]+ - Константа с кодом ошибки

    //#Define - если будет define, компилятор падает при повторном включении файла
    //#Include - если будет include, компилятор падает при повторном включении файла
*)

type t_operations is list(operation);//RU< Список операций //EN< List of operations
[@inline] const cNO_OPERATIONS: t_operations = nil;//RU< Пустой список операций //EN< Empty list of operations

//RU Тип для индексов
type t_i is nat;

//RU Тип для получения индексов, -1 - элемент отсутствует
// \see cABSENT
type t_ii is int;

[@inline] const cABSENT: t_ii = -1;//RU Элемент отсутствует

[@inline] const cNO_ADDRESS: address = ("tz1ZZZZZZZZZZZZZZZZZZZZZZZZZZZZNkiRg" : address);//RU Заглушка для address
[@inline] const cNO_KEY_HASH: key_hash = ("tz1ZZZZZZZZZZZZZZZZZZZZZZZZZZZZNkiRg" : key_hash);//RU Заглушка для key_hash

#endif // !CONSTS_INCLUDED

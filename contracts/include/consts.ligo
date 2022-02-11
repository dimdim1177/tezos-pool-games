#if !CONSTS_INCLUDED
#define CONSTS_INCLUDED

(*RU
    Префиксы:
    С - Контракт
    M - Модуль
    t_ - Тип
    c_ - Константа

    //#Define - если будет define, компилятор падает при повторном включении файла
    //#Include - если будет include, компилятор падает при повторном включении файла
*)

type t_operations is list(operation);//RU< Список операций //EN< List of operations
const c_NO_OPERATIONS: t_operations = nil;//RU< Пустой список операций //EN< Empty list of operations

#endif // !CONSTS_INCLUDED

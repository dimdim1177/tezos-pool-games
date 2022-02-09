#if !CONSTS_INCLUDED
#define CONSTS_INCLUDED

(*RU
    Префиксы:
    С - Контракт
    M - Модуль
    t_ - Тип
    c_ - Константа

    //#Define - если будет define, компилятор падает
    //#Iefine - если будет include, компилятор падает
*)

type t_operations is list(operation);//RU< Список операций //EN< List of operations
[@inline] const c_NO_OPERATIONS : t_operations = nil;//RU< Пустой список операций //EN< Empty list of operations

#endif // CONSTS_INCLUDED

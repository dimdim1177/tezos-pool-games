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

[@inline] const c_NO_OPERATIONS : list(operation) = nil;//RU< Пустой список пераций //EN< Empty list of operations

#endif // CONSTS_INCLUDED

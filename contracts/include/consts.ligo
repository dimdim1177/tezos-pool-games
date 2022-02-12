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

//RU Тип для индексов
type t_i is nat;

//RU Тип для получения индексов, -1 - элемент отсутствует
// \see cABSENT
type t_ii is int;

const cABSENT: t_ii = -1;//RU Элемент отсутствует

#endif // !CONSTS_INCLUDED

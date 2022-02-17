#if !MRANDOM_INCLUDED
#define MRANDOM_INCLUDED

//RU Модуль взаимодействия с источником случайных чисел
module MRandom is {

    type t_random_source is address;//RU< Адрес источника случайных чисел
    type t_iobj is t_i;//RU< ID объекта в контракте заказчике
    type t_ts is timestamp;//RU< Время события, для которого случайное число
    type t_ts_iobj is t_ts * t_iobj;//RU< Время события и ID объекта

    //RU Случайное число
    //RU
    //RU Для создания случайного числа берется хеш ближайшего блока Tezos, время которого больше или равно
    //RU времени события, с него снимается SHA-256, получаем значение levelHash. Также хеш SHA-256 снимается 
    //RU со строки "адрес заказчика<пробел><ID объекта в контракте заказчика в десятичной записи>", получаем
    //RU значение requestHash. Cлучайное число вычисляется как random = levelHash ^ requestHash и переводится
    //RU в формат nat. В итоге в общем случае у нас 256-битное случайное число
    type t_random is nat;

    //RU Тип колбека для получения случайного числа
    type t_iobj_random is t_iobj * t_random;
    type t_callback_params is OnRandomCallback of t_iobj_random;
    type t_callback is contract(t_callback_params);

    type t_ts_iobj_callback is t_ts * t_iobj * t_callback;//RU< Время события, ID объекта и колбек для случайного числа

    const cERR_NOT_FOUND: string = "MRandom/NotFound";//RU< Ошибка: Не найден контракт источника
    const cERR_NOT_FOUND_CREATE: string = "MRandom/NotFoundCreateFuture";//RU< Ошибка: Не найден метод createFuture токена
    const cERR_NOT_FOUND_DELETE: string = "MRandom/NotFoundDeleteFuture";//RU< Ошибка: Не найден метод deleteFuture токена
    const cERR_NOT_FOUND_GET: string = "MRandom/NotFoundGetFuture";//RU< Ошибка: Не найден метод getFuture токена

    //RU Прототип метода createFuture
    type t_create is RandomCreateFuture of t_ts_iobj;

    //RU Контракт с точкой входа createFuture
    type t_create_contract is contract(t_create);

    //RU Прототип метода deleteFuture
    type t_delete is RandomDeleteFuture of t_ts_iobj;

    //RU Контракт с точкой входа deleteFuture
    type t_delete_contract is contract(t_delete);

    //RU Прототип метода getFuture
    type t_get is RandomGetFuture of t_ts_iobj_callback;

    //RU Контракт с точкой входа getFuture
    type t_get_contract is contract(t_get);

    //RU Получить точку входа createFuture
    function createFutureEntrypoint(const addr: address): t_create_contract is
        case (Tezos.get_entrypoint_opt("%createFuture", addr): option(t_create_contract)) of
        Some(create_contract) -> create_contract
        | None -> (failwith(cERR_NOT_FOUND_CREATE): t_create_contract)
        end;

    //RU Параметры для создания запроса случайного числа
    function createParams(const ts: t_ts; const iobj: t_iobj): t_create is
        RandomCreateFuture(ts, iobj);

    //RU Операция создания запроса случайного числа
    function create(const addr: address; const ts: t_ts; const iobj: t_iobj): operation is
        Tezos.transaction(
            createParams(ts, iobj),
            0mutez,
            createFutureEntrypoint(addr)
        );

    //RU Получить точку входа deleteFuture
    function deleteFutureEntrypoint(const addr: address): t_delete_contract is
        case (Tezos.get_entrypoint_opt("%deleteFuture", addr): option(t_delete_contract)) of
        Some(delete_contract) -> delete_contract
        | None -> (failwith(cERR_NOT_FOUND_DELETE): t_delete_contract)
        end;


    //RU Параметры для удаления запроса случайного числа
    function deleteParams(const ts: t_ts; const iobj: t_iobj): t_delete is
        RandomDeleteFuture(ts, iobj);

    //RU Операция удаления запроса случайного числа
    function delete(const addr: address; const ts: t_ts; const iobj: t_iobj): operation is
        Tezos.transaction(
            deleteParams(ts, iobj),
            0mutez,
            deleteFutureEntrypoint(addr)
        );

    //RU Получить точку входа getFuture
    function getFutureEntrypoint(const addr: address): t_get_contract is
        case (Tezos.get_entrypoint_opt("%getFuture", addr): option(t_get_contract)) of
        Some(contract) -> contract
        | None -> (failwith(cERR_NOT_FOUND_GET): t_get_contract)
        end;

    //RU Параметры для получения случайного числа
    function getParams(const ts: t_ts; const iobj: t_iobj; const callback: t_callback): t_get is
        RandomGetFuture(ts, iobj, callback);

    //RU Операция создания запроса случайного числа
    function get(const addr: address; const ts: t_ts; const iobj: t_iobj; const callback: t_callback): operation is
        Tezos.transaction(
            getParams(ts, iobj, callback),
            0mutez,
            getFutureEntrypoint(addr)
        );

    //RU Проверка источника случайных чисел на валидность
    function check(const randomSource: t_random_source): unit is block {
        const _: t_create_contract = createFutureEntrypoint(randomSource);//RU Проверяем наличие метода createFuture для источника
        const _: t_delete_contract = deleteFutureEntrypoint(randomSource);//RU Проверяем наличие метода deleteFuture для источника
        const _: t_get_contract = getFutureEntrypoint(randomSource);//RU Проверяем наличие метода getFuture для источника random
     } with unit;

}
#endif // !MRANDOM_INCLUDED

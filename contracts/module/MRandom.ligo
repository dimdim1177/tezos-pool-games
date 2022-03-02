#if !MRANDOM_INCLUDED
#define MRANDOM_INCLUDED

///RU Модуль взаимодействия с источником случайных чисел
///EN Module for interaction with a random number source
module MRandom is {

    ///RU Адрес источника случайных чисел
    ///EN Address of the source of random numbers
    type t_random_source is address;

    ///RU ID объекта в контракте заказчике
    ///EN Object ID in the customer contract
    type t_iobj is t_i;

    ///RU Время события, для которого случайное число
    ///EN The time of the event for which a random number
    type t_ts is timestamp;

    ///RU Время события и ID объекта
    ///EN Event time and Object ID
    type t_ts_iobj is t_ts * t_iobj;

    ///RU Случайное число
    ///RU
    ///RU Для создания случайного числа берется хеш ближайшего блока Tezos, время которого больше или равно
    ///RU времени события, с него снимается SHA-256, получаем значение levelHash. Также хеш SHA-256 снимается
    ///RU со строки "адрес заказчика<пробел><ID объекта в контракте заказчика в десятичной записи>", получаем
    ///RU значение requestHash. Cлучайное число вычисляется как random = levelHash ^ requestHash и переводится
    ///RU в формат nat. В итоге в общем случае у нас 256-битное случайное число
    ///EN Random number
    ///EN
    ///EN To create a random number, the hash of the nearest Tezos block is taken, the time of which is greater than or equal
    ///EN to the time of the event, SHA-256 is removed from it, we get the levelHash value. Also, the SHA-256 hash is removed
    ///EN from the line "customer's address<space><object ID in the customer's contract in decimal notation>", we get
    ///EN the requestHash value. A random number is calculated as random = levelHash^ requestHash and converted
    ///EN to nat format. As a result, in general, we have a 256-bit random number
    type t_random is nat;

    ///RU Тип колбека для получения случайного числа
    ///EN The type of callback for getting a random number
    type t_iobj_random is t_iobj * t_random;
    type t_callback_params is OnRandomCallback of t_iobj_random;
    type t_callback is contract(t_callback_params);

    ///RU Время события, ID объекта и колбек для случайного числа
    ///EN Event time, Object ID, and callback for a random number
    type t_ts_iobj_callback is t_ts * t_iobj * t_callback;

    ///RU Ошибка: Не найден контракт источника
    ///EN Error: Source contract not found
    const cERR_NOT_FOUND: string = "MRandom/NotFound";

    ///RU Ошибка: Не найден метод createFuture токена
    ///EN Error: The createFuture token method was not found
    const cERR_NOT_FOUND_CREATE: string = "MRandom/NotFoundCreateFuture";

    ///RU Ошибка: Не найден метод deleteFuture токена
    ///EN Error: Token deleteFuture method not found
    const cERR_NOT_FOUND_DELETE: string = "MRandom/NotFoundDeleteFuture";

    ///RU Ошибка: Не найден метод getFuture токена
    ///EN Error: Token getFuture method not found
    const cERR_NOT_FOUND_GET: string = "MRandom/NotFoundGetFuture";

    ///RU Прототип метода createFuture
    ///EN Prototype of the createFuture method
    type t_create is RandomCreateFuture of t_ts_iobj;

    ///RU Контракт с точкой входа createFuture
    ///EN Contract with createFuture entry point
    type t_create_contract is contract(t_create);

    ///RU Прототип метода deleteFuture
    ///EN Prototype of the deleteFuture method
    type t_delete is RandomDeleteFuture of t_ts_iobj;

    ///RU Контракт с точкой входа deleteFuture
    ///EN Contract with the deleteFuture entry point
    type t_delete_contract is contract(t_delete);

    ///RU Прототип метода getFuture
    ///EN Prototype of the getFuture method
    type t_get is RandomGetFuture of t_ts_iobj_callback;

    ///RU Контракт с точкой входа getFuture
    ///EN Contract with the getFuture entry point
    type t_get_contract is contract(t_get);

    ///RU Получить точку входа createFuture
    ///EN Get the createFuture entry point
    function createFutureEntrypoint(const addr: address): t_create_contract is
        case (Tezos.get_entrypoint_opt("%createFuture", addr): option(t_create_contract)) of [
        | Some(create_contract) -> create_contract
        | None -> (failwith(cERR_NOT_FOUND_CREATE): t_create_contract)
        ];

    ///RU Параметры для создания запроса случайного числа
    ///EN Parameters for creating a random number request
    function createParams(const ts: t_ts; const iobj: t_iobj): t_create is
        RandomCreateFuture(ts, iobj);

    ///RU Операция создания запроса случайного числа
    ///EN Operation of creating a random number request
    function create(const addr: address; const ts: t_ts; const iobj: t_iobj): operation is
        Tezos.transaction(
            createParams(ts, iobj),
            0mutez,
            createFutureEntrypoint(addr)
        );

    ///RU Получить точку входа deleteFuture
    ///EN Get the deleteFuture entry point
    function deleteFutureEntrypoint(const addr: address): t_delete_contract is
        case (Tezos.get_entrypoint_opt("%deleteFuture", addr): option(t_delete_contract)) of [
        | Some(delete_contract) -> delete_contract
        | None -> (failwith(cERR_NOT_FOUND_DELETE): t_delete_contract)
        ];


    ///RU Параметры для удаления запроса случайного числа
    ///EN Parameters for deleting a random number request
    function deleteParams(const ts: t_ts; const iobj: t_iobj): t_delete is
        RandomDeleteFuture(ts, iobj);

    ///RU Операция удаления запроса случайного числа
    ///EN Operation of deleting a random number request
    function delete(const addr: address; const ts: t_ts; const iobj: t_iobj): operation is
        Tezos.transaction(
            deleteParams(ts, iobj),
            0mutez,
            deleteFutureEntrypoint(addr)
        );

    ///RU Получить точку входа getFuture
    ///EN Get a getFuture entry point
    function getFutureEntrypoint(const addr: address): t_get_contract is
        case (Tezos.get_entrypoint_opt("%getFuture", addr): option(t_get_contract)) of [
        | Some(contract) -> contract
        | None -> (failwith(cERR_NOT_FOUND_GET): t_get_contract)
        ];

    ///RU Параметры для получения случайного числа
    ///EN Parameters for getting a random number
    function getParams(const ts: t_ts; const iobj: t_iobj; const callback: t_callback): t_get is
        RandomGetFuture(ts, iobj, callback);

    ///RU Операция создания запроса случайного числа
    ///EN Operation of creating a random number request
    function get(const addr: address; const ts: t_ts; const iobj: t_iobj; const callback: t_callback): operation is
        Tezos.transaction(
            getParams(ts, iobj, callback),
            0mutez,
            getFutureEntrypoint(addr)
        );

    ///RU Проверка источника случайных чисел на валидность
    ///EN Checking the source of random numbers for validity
    function check(const randomSource: t_random_source): unit is block {
        //RU Проверяем наличие метода createFuture для источника
        //EN Checking for the createFuture method for the source
        const _ = createFutureEntrypoint(randomSource);
        //RU Проверяем наличие метода deleteFuture для источника
        //EN Checking for the deleteFuture method for the source
        const _ = deleteFutureEntrypoint(randomSource);
        //RU Проверяем наличие метода getFuture для источника random
        //EN Checking for the getFuture method for the random source
        const _ = getFutureEntrypoint(randomSource);
     } with unit;

}
#endif // !MRANDOM_INCLUDED

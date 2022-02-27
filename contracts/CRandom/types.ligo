#if !TYPES_INCLUDED
#define TYPES_INCLUDED

#include "config.ligo"
#include "../include/consts.ligo"
#include "../module/MOwner.ligo"
#include "../module/MAdmin.ligo"
#include "../module/MAdmins.ligo"
#include "../module/MRandom.ligo"

///RU Типы для хранилища контракта
///EN Types for contract storage

///RU Идентификация заказа случайного числа
///EN Identification of a random number order
type t_ifuture is [@layout:comb] record [
    ///RU Адрес заказчика случайного числа
    ///EN Random number customer's address
    addr: address;

    ///RU Время события (в будущем), для которого нужно случайное число
    ///EN The time of the event (in the future) for which a random number is needed
    ts: MRandom.t_ts;

    ///RU ID объекта заказчика
    ///EN Customer's object ID
    iobj: MRandom.t_iobj;
];

///RU Для какого времени необходимо случайное число
///EN For what time a random number is needed
type t_future is [@layout:comb] record [
    ///RU Время блока, из которого создано случайное число
    ///EN The time of the block from which the random number was created
    tsLevel: timestamp;

    ///RU Уровень блока, из которого создано случайное число
    ///EN The level of the block from which the random number is created
    level: nat;

    ///RU Случайное число ///EN Random number
    random: MRandom.t_random;
];

///RU Структуры для заказов на колбеки в будущем
///EN Structures for future callback orders
type t_futures is big_map(t_ifuture, t_future);

#endif // !TYPES_INCLUDED

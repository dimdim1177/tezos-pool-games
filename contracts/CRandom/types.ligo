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
type t_ifuture is [@layout:comb] record [
    addr: address;///RU< Адрес заказчика случайного числа
    ts: MRandom.t_ts;///RU< Время события (в будущем), для которого нужно случайное число
    iobj: MRandom.t_iobj;///RU< ID объекта заказчика
];

///RU Для какого времени необходимо случайное число
type t_future is [@layout:comb] record [
    tsLevel: timestamp;///RU< Время блока, из которого создано случайное число
    level: nat;///RU< Уровень блока, из которого создано случайное число 
    random: MRandom.t_random;///RU< Случайное число
];

///RU Структуры для заказов на колбеки в будущем
type t_futures is big_map(t_ifuture, t_future);

#endif // !TYPES_INCLUDED

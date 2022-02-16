#if !TYPES_INCLUDED
#define TYPES_INCLUDED

#include "config.ligo"
#include "../include/consts.ligo"
#include "../module/MOwner.ligo"
#include "../module/MAdmin.ligo"
#include "../module/MAdmins.ligo"
#include "../module/MRandom.ligo"

//RU Типы для хранилища контракта
//EN Types for contract storage

//RU Транзитные объявления типов из модулей
#if ENABLE_OWNER
type t_owner is MOwner.t_owner;
#endif // ENABLE_OWNER
#if ENABLE_ADMIN
type t_admin is MAdmin.t_admin;
#endif // ENABLE_ADMIN
#if ENABLE_ADMINS
type t_admin is MAdmins.t_admin;
type t_admins is MAdmins.t_admins;
#endif // ENABLE_ADMINS
type t_iobj is MRandom.t_iobj;//RU< ID объекта в контракте заказчике
type t_event_ts is MRandom.t_event_ts;//RU< Время события, для которого случайное число
type t_random is MRandom.t_random;//RU< Случайное число

type t_ifuture is address * t_iobj;//RU< Идентификация заказа случайного числа

//RU Для какого времени необходимо случайное число
type t_future is [@layout:comb] record [
    ts: t_event_ts;//RU< Время события (в будущем), для которого нужно случайное число
    tsLevel: timestamp;//RU< Время блока, из которого создано случайное число
    level: nat;//RU< Уровень блока, из которого создано случайное число 
    random: t_random;//RU< Случайное число
];

//RU Структуры для заказов на колбеки в будущем
type t_futures is big_map(t_ifuture, t_future);

#endif // !TYPES_INCLUDED

#if !MUSERS_INCLUDED
#define MUSERS_INCLUDED

#include "../module/MFarm.ligo"
#include "MPoolGame.ligo"

//RU Модуль списка пользователей, инвестировавших в пулы для розыгрышей вознаграждений
module MUsers is {

    //RU Параметры пользователя в пуле
    type t_user is record [
        balance: MFarm.t_amount;//RU< Сколько токенов фермы инвестировано в пул этим пользователем
        tsBalance: timestamp;//RU< Когда было последнее пополнение токенов пользователем
        weight: MPoolGame.t_weight;//RU< Вес для определения вероятности победы в текущей партии
#if ENABLE_REINDEX_POOL_USERS
        addr: address;//RU< Адрес пользователя
#endif // ENABLE_REINDEX_POOL_USERS
    ];

    type t_ipool is nat;//RU< Индекс пула

    //RU Индекс пользователя внутри пула
    type t_iuser is nat;

    //RU Комбинация индекса пула и индекса пользователя в нем
    type t_ipooliuser is t_ipool * t_iuser;

    //RU Ключ для поиска индекса пользователя по индексу пула и адресу
    type t_ipooladdr is t_ipool * address;

    //RU Индекса в пуле по номеру пула и адресу пользователя
    type t_ipooladdr2iuser is big_map(t_ipooladdr, t_iuser);

    //RU Параметры пользователя по индексу пула и индекса пользователя в нем
    type t_ipooliuser2user is big_map(t_ipooliuser, t_user);

    //RU Индекс внутри пула по номеру пула
    type t_ipool2i is big_map(t_ipool, nat);

    //RU Пользователи пулов
    type t_users is record [
        //RU Начальный индекс пользователей в пулах
        ipool2ibeg: t_ipool2i;

        //RU Следующий за максимальным индекс пользователей в пулах
        ipool2iend: t_ipool2i;

        //RU Кол-во пользователей в пулах
        ipool2count: t_ipool2i;

        //RU Индекса в пуле по номеру пула и адресу пользователя
        ipooladdr2iuser: t_ipooladdr2iuser;

        //RU Параметры пользователя по индексу пула и индекса пользователя в нем
        ipooliuser2user: t_ipooliuser2user;
    ];

    const c_ERR_NO_INDEX: string = "MUsers/NoIndex";//RU< Ошибка: Не найден индекс в карте
    const c_ERR_NOT_FOUND: string = "MUsers/NotFound";//RU< Ошибка: Не найден пользователь для удаления

    //RU Получение значения некого индекса по индексу пула
    [@inline] function ipool2i(const ipool2i: t_ipool2i; const ipool: nat): nat is 
        case ipool2i[ipool] of
        Some(i) -> i
        | None -> failwith(c_ERR_NO_INDEX)
        end

    //RU Обработка добавления пула
    [@inline] function onAddPool(var users: t_users; const ipool: nat): t_users is block {
        users.ipool2ibeg := Big_map.update(ipool, Some(0n), users.ipool2ibeg);
        users.ipool2iend := Big_map.update(ipool, Some(0n), users.ipool2iend);
        users.ipool2count := Big_map.update(ipool, Some(0n), users.ipool2count);
    } with users

    //RU Обработка удаления пула
    [@inline] function onRemPool(var users: t_users; const ipool: nat): t_users is block {
        users.ipool2ibeg := Big_map.remove(ipool, users.ipool2ibeg);
        users.ipool2iend := Big_map.remove(ipool, users.ipool2iend);
        users.ipool2count := Big_map.remove(ipool, users.ipool2count);
    } with users

    //RU Получить текущие параметры пользователя в пуле
    //RU
    //RU Пользователь идентифицируется по Tezos.sender
    [@inline] function getUser(const users: t_users; const ipool: nat): t_user is block {
        var user: t_user := record [//RU Параметры пользователя по умолчанию
            balance = 0n;
            tsBalance = Tezos.now;
            weight = 0n;
#if ENABLE_REINDEX_POOL_USERS
            addr = Tezos.sender;
#endif // ENABLE_REINDEX_POOL_USERS
        ];
        case users.ipooladdr2iuser[(ipool, Tezos.sender)] of
        | Some(iuser) -> { 
            case users.ipooliuser2user[(ipool, iuser)] of
            | Some(u) -> user := u
            | None -> skip
            end;
        }
        | None -> skip
        end;
    } with user;

#if ENABLE_REINDEX_POOL_USERS
    //RU Переупаковка разряженного индекса пользователей в пуле, если необходимо
    //RU
    //RU После переупаковки индексы пользователей в пуле будут начинаться с 0 и идти подряд
    //RU Это уменьшит кол-во операций для итерирования по всем пользователям пула, за счет избавления от холостых итераций
    [@inline] function reindexIfNeed(var users: t_users; const ipool: nat): t_users is block {
        const ibeg: nat = ipool2i(users.ipool2ibeg, ipool);
        const iend: nat = ipool2i(users.ipool2iend, ipool);
        const count: nat = ipool2i(users.ipool2count, ipool);
        //RU Если кол-во индексов пользователей в пуле в 2 раза больше реального кол-ва,
        //RU переиндексируем пул, что вдвое уменьшит кол-во итераций по пулу при переборе всех пользователей
        if ((iend - ibeg) > (2 * count)) then block {
            var newiend: nat := 0n;
            const imax: int = iend - 1;//RU Конечный индекс
            for i := int(ibeg) to imax block {
                const iuser: nat = abs(i);
                case users.ipooliuser2user[(ipool, iuser)] of
                | Some(user) -> {//RU Существующий индекс - переиндексируем
                    if newiend < iuser then block {//RU Если индекс пользователя изменился
                        //RU Новый индекс по адресу
                        users.ipooladdr2iuser := Big_map.update((ipool, user.addr), Some(newiend), users.ipooladdr2iuser);
                        //RU Вставляем параметры пользователя под новым индексом
                        users.ipooliuser2user := Big_map.add((ipool, newiend), user, users.ipooliuser2user);
                        //RU Удаляем параметры под текущим индексом
                        users.ipooliuser2user := Big_map.remove((ipool, iuser), users.ipooliuser2user);
                        newiend := newiend + 1n;
                    } else skip
                }
                | None -> skip //RU Индекс пуст
                end;
            };
            users.ipool2ibeg := Big_map.update(ipool, Some(0n), users.ipool2ibeg);
            users.ipool2iend := Big_map.update(ipool, Some(newiend), users.ipool2iend);
            users.ipool2count := Big_map.update(ipool, Some(newiend), users.ipool2count);
        } else skip;
    } with users;
#endif // ENABLE_REINDEX_POOL_USERS

    //RU Обновить текущие параметры пользователя в пуле
    //RU
    //RU Пользователь идентифицируется по Tezos.sender. При нулевом сохраняемом балансе пользователь удаляется из пула
    [@inline] function setUser(var users: t_users; const ipool: nat; const user: t_user): t_users is block {
        case users.ipooladdr2iuser[(ipool, Tezos.sender)] of
        Some(iuser) -> {
            if user.balance > 0n then users.ipooliuser2user[(ipool, iuser)] := user //RU Обновление существующего
            else block {//RU Удаление существующего
                users.ipooladdr2iuser := Big_map.remove((ipool, Tezos.sender), users.ipooladdr2iuser);//RU Удаляем индекс по адресу
                users.ipooliuser2user := Big_map.remove((ipool, iuser), users.ipooliuser2user);//RU Удаляем данные по индексу
                const count: nat = ipool2i(users.ipool2count, ipool);//RU Текущее кол-во пользователей в пуле
                users.ipool2count := Big_map.update(ipool, Some(abs(count - 1)), users.ipool2count);//RU Уменьшаем кол-во
                const ibeg: nat = ipool2i(users.ipool2ibeg, ipool);
                if iuser = ibeg then block {//RU Нужно найти новое начало индексов
                    var ibeg := iuser + 1n;
                    const iend: nat = ipool2i(users.ipool2iend, ipool);
                    while ((ibeg < iend) and 
                        (not Big_map.mem((ipool, ibeg), users.ipooliuser2user))) block {
                        ibeg := ibeg + 1n;
                    };
                    users.ipool2ibeg := Big_map.update(ipool, Some(ibeg), users.ipool2ibeg);
                } else skip;
                //RU Новый конец индексов не ищем, обрабатываем только ситуацию удаления самых первых
            }
        }
        | None -> {
            if user.balance > 0n then block {//RU Добавление нового
                const iuser: nat = ipool2i(users.ipool2iend, ipool);
                users.ipooladdr2iuser := Big_map.add((ipool, Tezos.sender), iuser, users.ipooladdr2iuser);
                users.ipooliuser2user := Big_map.add((ipool, iuser), user, users.ipooliuser2user);
                users.ipool2iend := Big_map.update(ipool, Some(iuser + 1n), users.ipool2iend);
                users.ipool2count := Big_map.update(ipool, Some(ipool2i(users.ipool2count, ipool) + 1n), users.ipool2count);
            } else failwith(c_ERR_NOT_FOUND);//RU Удаление несуществующего
        }
        end;
#if ENABLE_REINDEX_POOL_USERS
        users := reindexIfNeed(users, ipool);//RU Переиндексируем пользователей в пуле, если необходимо
#endif // ENABLE_REINDEX_POOL_USERS
    } with users;

}
#endif // !MUSERS_INCLUDED

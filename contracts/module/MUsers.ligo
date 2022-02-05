#if !MUSERS_INCLUDED
#define MUSERS_INCLUDED

//RU Модуль списка пользователей, инвестировавших в пул для розыгрышей вознаграждений
module MUsers is {

    //RU Параметры пользователя
    type t_user is record [
#if ENABLE_REPACKUSERS
        addr: address;//RU< Адрес пользователя
#endif // ENABLE_REPACKUSERS
        winWeight: nat;//RU< Ранее накопленный вес для определения вероятности победы
        amount: nat;//RU< Сколько токенов фермы инвестировано в пул
        tsAmount: timestamp;//RU< Когда было последнее пополнение токенов пользователем
    ];

    type t_addr2i is big_map(address, nat);
    type t_i2user is big_map(nat, t_user);

    //RU Пользователи пула
    type t_users is record [
        count: nat;//RU< Кол-во пользователей
        minI: nat;//RU< Начальный индекс пользователей
        endI: nat;//RU< Следующий за максимальным индекс пользователей
        addr2i: t_addr2i;//RU< Определение индекса пользователя по адресу
        i2user: t_i2user;//RU< Параметры пользователя по индексу
    ];

    const c_ERR_NOTFOUND: string = "MUsers/NotFound";//RU< Ошибка: Не найден пользователь для удаления

    //RU Получить текущие параметры пользователя
    //
    //RU Пользователь идентифицируется по Tezos.sender
    [@inline] function getUser(const users: t_users): t_user is block {
        var user: t_user := record [
#if ENABLE_REPACKUSERS
            addr = Tezos.sender;
#endif // ENABLE_REPACKUSERS
            winWeight = 0n;
            amount = 0n;
            tsAmount = Tezos.now;
        ];
        case users.addr2i[Tezos.sender] of
        | Some(i) -> { 
            case users.i2user[i] of
            | Some(iuser) -> user := iuser
            | None -> skip
            end;
        }
        | None -> skip
        end;
    } with user;

    //RU Обновить текущие параметры пользователя
    //
    //RU Пользователь идентифицируется по Tezos.sender
    [@inline] function setUser(var users: t_users; const user: t_user): t_users is block {
        case users.addr2i[Tezos.sender] of
        Some(i) -> {
            if user.amount > 0n then users.i2user[i] := user //RU Обновление существующего
            else block {//RU Удаление существующего
                users.addr2i := Big_map.remove(Tezos.sender, users.addr2i);//RU Удаляем индекс по адресу
                users.i2user := Big_map.remove(i, users.i2user);//RU Удаляем данные по индексу
                users.count := abs(users.count - 1);//RU Уменьшаем кол-во
                if i = users.minI then block {//RU Нужно найти новое начало индексов
                    while ((users.minI < users.endI) and 
                        (not Big_map.mem(users.minI, users.i2user))) block {
                        users.minI := abs(users.minI + 1);
                    }
                } else skip;
                //RU Новый конец индексов не ищем, обрабатываем только ситуацию удаления самых старых
            }
        }
        | None -> {
            if user.amount > 0n then block {//RU Добавление нового
                const i: nat = users.endI;
                users.addr2i := Big_map.add(Tezos.sender, i, users.addr2i);
                users.i2user := Big_map.add(i, user, users.i2user);
                users.endI := abs(i + 1);
                users.count := abs(users.count + 1);
            } else failwith(c_ERR_NOTFOUND);//RU Удаление несуществующего
        }
        end;
#if ENABLE_REPACKUSERS
        if ((user.endI - user.begI) > (2 * user.count)) then users := repack(users)
        else skip;
#endif // ENABLE_REPACKUSERS
    } with users;

#if ENABLE_REPACKUSERS
    //RU Переупаковка разряженного индекса пользователей
    //RU
    //RU После переупаковки индексы пользователей будут начинаться с 0 и идти подряд
    [@inline] function reindex(var users: t_users): t_users is block {
        var ni: nat := 0n;
        var addr2i: t_addr2i := big_map [];
        var i2user: t_i2user := big_map [];
        if (users.count > 0) then block {//RU Если список не пуст
            const maxI: nat = users.endI - 1;
            for i := users.begI to maxI block {
                case users.i2user[i] of
                | Some(user) -> {//RU Существующий индекс - переиндексируем
                    Big_map.add(user.addr, ni, addr2i);
                    Big_map.add(ni, user, i2user);
                    ni := ni + 1;
                }
                | None -> skip
                end;
            }
        } else skip;
        users.addr2i := addr2i;
        users.i2user := i2user;
        users.begI := 0n;
        users.endI := ni;
        users.count := ni;
    } with users;
#endif // ENABLE_REPACKUSERS

}
#endif // MUSERS_INCLUDED

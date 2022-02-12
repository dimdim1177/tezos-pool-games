#if !MUSERS_INCLUDED
#define MUSERS_INCLUDED

//RU Модуль списка пользователей, инвестировавших в пулы для розыгрышей вознаграждений
module MUsers is {

    const cERR_NO_INDEX: string = "MUsers/NoIndex";//RU< Ошибка: Не найден индекс в карте
    const cERR_NOT_FOUND: string = "MUsers/NotFound";//RU< Ошибка: Не найден пользователь для удаления

    //RU Получить текущие параметры пользователя в пуле
    //RU
    //RU Пользователь идентифицируется по Tezos.sender
    function getUser(const users: t_users; const ipool: t_i): t_ii * t_user is block {
        var ii: t_ii := -1;
        var user: t_user := record [//RU Параметры пользователя по умолчанию
            balance = 0n;
            tsBalance = Tezos.now;
            weight = 0n;
#if ENABLE_REINDEX_USERS
            addr = Tezos.sender;
#endif // ENABLE_REINDEX_USERS
        ];
        case users.ipooladdr2iuser[(ipool, Tezos.sender)] of
        | Some(iuser) -> { 
            ii := int(iuser);
            case users.ipooliuser2user[(ipool, iuser)] of
            | Some(puser) -> user := puser
            | None -> skip
            end;
        }
        | None -> skip
        end;
    } with (ii, user);

#if ENABLE_REINDEX_USERS
    //RU Переупаковка разряженного индекса пользователей в пуле, если необходимо
    //RU
    //RU После переупаковки индексы пользователей в пуле будут начинаться с 0 и идти подряд
    //RU Это уменьшит кол-во операций для итерирования по всем пользователям пула, за счет избавления от холостых итераций
    function reindex(var users: t_users; const ipool: t_i; var ibeg: t_i; var inext: t_i): t_users * t_i * t_i is block {
        const imax: int = inext - 1;//RU Конечный индекс
        inext := 0n;
        for i := int(ibeg) to imax block {
            const iuser: nat = abs(i);
            const ipooliuser: t_ipooliuser = (ipool, iuser);
            case users.ipooliuser2user[ipooliuser] of
            | Some(user) -> {//RU Существующий индекс - переиндексируем
                if inext < iuser then block {//RU Если индекс пользователя изменился
                    //RU Новый индекс по адресу
                    users.ipooladdr2iuser := Big_map.update((ipool, user.addr), Some(inext), users.ipooladdr2iuser);
                    //RU Вставляем параметры пользователя под новым индексом
                    users.ipooliuser2user := Big_map.add((ipool, inext), user, users.ipooliuser2user);
                    //RU Удаляем параметры под текущим индексом
                    users.ipooliuser2user := Big_map.remove(ipooliuser, users.ipooliuser2user);
                } else skip;
                inext := inext + 1n;
            }
            | None -> skip //RU Индекс пуст
            end;
        };
    } with (users, ibeg, inext);
#endif // ENABLE_REINDEX_USERS

    //RU Обновить текущие параметры пользователя в пуле
    //RU
    //RU Пользователь идентифицируется по Tezos.sender. При нулевом сохраняемом балансе пользователь удаляется
    function setUser(var users: t_users; const ipool: t_i; const iuser: t_i; const user: t_user): t_users is block {
        const ipooliuser: t_ipooliuser = (ipool, iuser);
        if user.balance > 0n then users.ipooliuser2user[ipooliuser] := user //RU Обновление существующего
        else block {//RU Удаление
            users.ipooladdr2iuser := Big_map.remove((ipool, Tezos.sender), users.ipooladdr2iuser);//RU Удаляем индекс по адресу
            users.ipooliuser2user := Big_map.remove(ipooliuser, users.ipooliuser2user);//RU Удаляем данные по индексу
        };
    } with users;

}
#endif // !MUSERS_INCLUDED

#if !MFARM_INCLUDED
#define MFARM_INCLUDED

#include "MToken.ligo"
#include "MFarmCrunchy.ligo"
#include "MFarmQUIPU.ligo"

//RU Модуль взаимодействия с фермой
module MFarm is {

    type t_amount is MToken.t_amount;//RU< Кол-во токенов
    type t_token is MToken.t_token;//RU< Структура токена

//RU --- Интерфейсы ферм //EN --- Farm interfaces

    type t_interface is
    
    //RU Crunchy
    //RU
    //RU Методы фермы:
    //RU Депозит в ферму - deposit(farmId, farmTokenAmount)
    //RU Отзыв депозита из фермы - withdraw(farmId, farmTokenAmount)
    //RU Вознаграждение - harvest(farmId)
    // mainnet https://tzkt.io/KT1KnuE87q1EKjPozJ5sRAjQA24FPsP57CE3/entrypoints
    | InterfaceCrunchy

    //RU Quipuswap farm
    //RU
    //RU Методы фермы:
    //RU Депозит в ферму - deposit(farmId, farmTokenAmount, referrer option(address), rewards_receiver address, candidate key_hash)
    //RU Отзыв депозита из фермы - withdraw(farmId, farmTokenAmount, receiver address, rewards_receiver address)
    //RU Вознаграждение - harvest(farmId, rewards_receiver address)
    // https://github.com/madfish-solutions/quipuswap-farming
    // https://better-call.dev/hangzhou2net/KT1FbmZ5Q2MNFHu45jCpiHpkNCLtLkjh65mM/interact?entrypoint=withdraw
    // QUIPU https://tzkt.io/KT193D4vozYnhGJQVtw7CoxxqphqUEEwK6Vb/entrypoints
    // QuipuSwap QUIPU https://tzkt.io/KT1X3zxdTzPB9DgVzA3ad6dgZe9JEamoaeRy/entrypoints
    | InterfaceQUIPU
    ;

    //RU Параметры фермы
    type t_farm is [@layout:comb] record [
        addr: address;//RU< Адрес фермы
        id: nat;//RU< ID фермы, где применимо
        farmToken: t_token;//RU< Токен фермы
        rewardToken: t_token;//RU< Токен вознаграждения
        interface: t_interface;//RU< Интерфейс фермы, см. cINTERFACE...
    ];

    //RU Проверка параметров фермы на валидность
    function check(const farm: t_farm): unit is block {
        MToken.check(farm.farmToken);
        MToken.check(farm.rewardToken);
        case farm.interface of
        | InterfaceCrunchy -> MFarmCrunchy.check(farm.addr)
        | InterfaceQUIPU -> MFarmQUIPU.check(farm.addr)
        end;
    } with unit;

    //RU Инвестирование токенов фермы в ферму пользователем через контракта
    //RU
    //RU Токены фермы от пользователя Tezos.sender перечисляются сначала контракту, а затем в ферму
    function deposit(const farm: t_farm; const damount: t_amount): t_operations is block {

    //RU Добавляем транзакции в обратном порядке, потому что они вставляются в начало списка
        var operations: t_operations := list [];
        //RU Вызываем метод депозита в ферму
        case farm.interface of
        | InterfaceCrunchy -> operations := MFarmCrunchy.deposit(farm.addr, farm.id, damount) # operations
        | InterfaceQUIPU -> operations := MFarmQUIPU.deposit(farm.addr, farm.id, damount) # operations
        end;
        //RU Переводим токены с контракта на адрес фермы
        operations := MToken.transfer(farm.farmToken, Tezos.self_address, farm.addr, damount) # operations;
        //RU Переводим токены пользователя на адрес контракта
        operations := MToken.transfer(farm.farmToken, Tezos.sender, Tezos.self_address, damount) # operations;
    } with operations;

    //RU Отзыв токенов фермы пользователем
    //RU
    //RU Токены фермы перечисляются сначала контракту, а затем пользователю по адресу Tezos.sender
    function withdraw(const farm: t_farm; const wamount: t_amount): t_operations is block {
        var operations: t_operations := list [];
        //RU Вызываем метод извлечения депозита из фермы
        case farm.interface of
        | InterfaceCrunchy -> operations := MFarmCrunchy.withdraw(farm.addr, farm.id, wamount) # operations
        | InterfaceQUIPU -> operations := MFarmQUIPU.withdraw(farm.addr, farm.id, wamount) # operations
        end;
        //RU Переводим токены с адреса фермы на контракт
        operations := MToken.transfer(farm.farmToken, farm.addr, Tezos.self_address, wamount) # operations;
        //RU Переводим токены с контракта на адрес пользователя
        operations := MToken.transfer(farm.farmToken, Tezos.self_address, Tezos.sender, wamount) # operations;
    } with operations;

    //RU Запрос вознаграждения из фермы
    //RU
    //RU Токены вознаграждения перечисляются из фермы на адрес контракта
    function reward(const _farm: t_farm): unit is block {
        skip;//TODO
    } with unit;
}
#endif // !MFARM_INCLUDED

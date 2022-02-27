#if !MFARM_INCLUDED
#define MFARM_INCLUDED

#include "MToken.ligo"
#include "MFarmCrunchy.ligo"
#include "MFarmQUIPU.ligo"

///RU Модуль взаимодействия с фермой
///EN Farm Interaction Module
module MFarm is {

    ///RU Интерфейсы ферм
    ///EN Farm interfaces
    type t_interface is

    ///RU Crunchy
    ///RU
    ///RU Методы фермы:
    ///RU Депозит в ферму - deposit(farmId, farmTokenAmount)
    ///RU Отзыв депозита из фермы - withdraw(farmId, farmTokenAmount)
    ///RU Вознаграждение - harvest(farmId)
    ///EN Crunchy
    ///EN
    ///EN Farm methods:
    ///EN Deposit to the farm - deposit(farmId, farmTokenAmount)
    ///EN Withdrawal of a deposit from a farm - withdraw(farmId, farmTokenAmount)
    ///EN Reward - harvest(farmId)
    // mainnet https://tzkt.io/KT1KnuE87q1EKjPozJ5sRAjQA24FPsP57CE3/entrypoints
    | InterfaceCrunchy

    ///RU Quipuswap farm
    ///RU
    ///RU Методы фермы:
    ///RU Депозит в ферму - deposit(farmId, farmTokenAmount, referrer option(address), rewards_receiver address, candidate key_hash)
    ///RU Отзыв депозита из фермы - withdraw(farmId, farmTokenAmount, receiver address, rewards_receiver address)
    ///RU Вознаграждение - harvest(farmId, rewards_receiver address)
    ///EN Quipuswap farm
    ///EN
    ///EN Farm methods:
    ///EN Deposit to the farm - deposit(farmId, farmTokenAmount, referrer option(address), rewards_receiver address, candidate key_hash)
    ///EN Withdrawal of the deposit from the farm - withdraw(farmId, farmTokenAmount, receiver address, rewards_receiver address)
    ///EN Reward - harvest(farmId, rewards_receiver address)
    // https://github.com/madfish-solutions/quipuswap-farming
    // https://better-call.dev/hangzhou2net/KT1FbmZ5Q2MNFHu45jCpiHpkNCLtLkjh65mM/interact?entrypoint=withdraw
    // QUIPU https://tzkt.io/KT193D4vozYnhGJQVtw7CoxxqphqUEEwK6Vb/entrypoints
    // QuipuSwap QUIPU https://tzkt.io/KT1X3zxdTzPB9DgVzA3ad6dgZe9JEamoaeRy/entrypoints
    | InterfaceQUIPU
    ;

    ///RU Параметры фермы
    ///EN Farm Parameters
    type t_farm is [@layout:comb] record [
        addr: address;///RU< Адрес фермы ///EN< Farm Address
        id: nat;///RU< ID фермы, где применимо ///EN< Farm ID, where applicable
        farmToken: MToken.t_token;///RU< Токен фермы ///EN< Farm Token
        rewardToken: MToken.t_token;///RU< Токен вознаграждения ///EN< Reward Token
        interface: t_interface;///RU< Интерфейс фермы ///EN< Farm Interface
    ];

    ///RU Проверка параметров фермы на валидность
    ///EN Checking the farm parameters for validity
    function check(const farm: t_farm): unit is block {
        MToken.check(farm.farmToken);
        MToken.check(farm.rewardToken);
        case farm.interface of [
        | InterfaceCrunchy -> MFarmCrunchy.check(farm.addr)
        | InterfaceQUIPU -> MFarmQUIPU.check(farm.addr)
        ];
    } with unit;

    ///RU Инвестирование токенов фермы в ферму пользователем через контракта
    ///RU
    ///RU Токены фермы от пользователя Tezos.sender перечисляются сначала контракту, а затем в ферму
    ///EN Investing farm tokens in a farm by a user through a contract
    ///EN
    ///EN Farm tokens from the user Tezos.sender are transferred first to the contract, and then to the farm
    function deposit(const farm: t_farm; const damount: MToken.t_amount; const doapprove: bool): t_operations is block {
        //RU Добавляем транзакции в обратном порядке, потому что они вставляются в начало списка
        //EN We add transactions in reverse order, because they are inserted at the beginning of the list
        var operations: t_operations := list [];
#if ENABLE_TRANSFER_SECURITY
        //RU Запрещаем перевод токенов ферме с контракта
        //EN We prohibit the transfer of tokens to the farm from the contract
        operations := MToken.decline(farm.farmToken, farm.addr) # operations;
#endif // ENABLE_TRANSFER_SECURITY
        //RU Вызываем метод депозита в ферму
        //EN Calling the deposit method to the farm
        case farm.interface of [
        | InterfaceCrunchy -> operations := MFarmCrunchy.deposit(farm.addr, farm.id, damount) # operations
        | InterfaceQUIPU -> operations := MFarmQUIPU.deposit(farm.addr, farm.id, damount) # operations
        ];
#if ENABLE_TRANSFER_SECURITY
        //RU Разрешаем перевод токенов ферме с контракта
        //EN We allow the transfer of tokens to the farm from the contract
        if (doapprove) then operations := MToken.approve(farm.farmToken, farm.addr, damount) # operations
        else skip;
#else // ENABLE_TRANSFER_SECURITY
        //RU Разрешаем безлимитный перевод токенов ферме с контракта
        //EN We allow unlimited transfer of tokens to the farm from the contract
        if (doapprove) then operations := MToken.approve(farm.farmToken, farm.addr, 1000000000000n) # operations
        else skip;
#endif // else ENABLE_TRANSFER_SECURITY
        //RU Переводим токены с контракта на адрес фермы
        //EN Transferring tokens from the contract to the farm address
        operations := MToken.transfer(farm.farmToken, Tezos.self_address, farm.addr, damount) # operations;
        //RU Переводим токены пользователя на адрес контракта
        //EN We transfer the user's tokens to the contract address
        operations := MToken.transfer(farm.farmToken, Tezos.sender, Tezos.self_address, damount) # operations;
    } with operations;

    ///RU Отзыв токенов фермы пользователем
    ///RU
    ///RU Токены фермы перечисляются сначала контракту, а затем пользователю по адресу Tezos.sender
    ///EN Revocation of farm tokens by the user
    ///EN
    ///EN Farm tokens are transferred first to the contract, and then to the user at Tezos.sender
    function withdraw(const farm: t_farm; const wamount: MToken.t_amount): t_operations is block {
        //RU Добавляем транзакции в обратном порядке, потому что они вставляются в начало списка
        //EN We add transactions in reverse order, because they are inserted at the beginning of the list
        var operations: t_operations := list [];
        //RU Переводим токены с контракта на адрес пользователя
        //EN We transfer tokens from the contract to the user's address
        operations := MToken.transfer(farm.farmToken, Tezos.self_address, Tezos.sender, wamount) # operations;
        //RU Вызываем извлечение депозита из фермы
        //EN We call the extraction of the deposit from the farm
        case farm.interface of [
        | InterfaceCrunchy -> operations := MFarmCrunchy.withdraw(farm.addr, farm.id, wamount) # operations
        | InterfaceQUIPU -> operations := MFarmQUIPU.withdraw(farm.addr, farm.id, wamount) # operations
        ];
    } with operations;

    ///RU Запрос вознаграждения из фермы
    ///RU
    ///RU Токены вознаграждения перечисляются из фермы на адрес контракта
    ///EN Request a reward from the farm
    ///EN
    ///EN Reward tokens are transferred from the farm to the contract address
    function harvest(const farm: t_farm): operation is
        case farm.interface of [
        | InterfaceCrunchy -> MFarmCrunchy.harvest(farm.addr, farm.id)
        | InterfaceQUIPU -> MFarmQUIPU.harvest(farm.addr, farm.id)
        ];

}
#endif // !MFARM_INCLUDED

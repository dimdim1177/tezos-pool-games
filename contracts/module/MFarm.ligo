#if !MFARM_INCLUDED
#define MFARM_INCLUDED

#include "MToken.ligo"

//RU Модуль взаимодействия с фермой
module MFarm is {

    type t_amount is nat;//RU< Кол-во токенов
    type t_token is MToken.t_token;//RU< Структура токена

//RU --- Интерфейсы ферм //EN --- Farm interfaces
    
    //RU Crunchy
    //RU
    //RU Методы фермы:
    //RU Депозит в ферму - deposit(farmId, farmTokenAmount)
    //RU Отзыв депозита из фермы - withdraw(farmId, farmTokenAmount)
    //RU Вознаграждение - harvest(farmId)
    // mainnet https://tzkt.io/KT1KnuE87q1EKjPozJ5sRAjQA24FPsP57CE3/entrypoints
    [@inline] const cINTERFACE_CRUNCHY: nat = 1n;

    //RU Quipuswap farm
    //RU
    //RU Методы фермы:
    //RU Депозит в ферму - deposit(farmId, farmTokenAmount, referrer option(address), rewards_receiver address, candidate key_hash)
    //RU Отзыв депозита из фермы - withdraw(farmId, farmTokenAmount, receiver address, rewards_receiver address)
    //RU Вознаграждение - harvest(farmId, rewards_receiver address)
    // https://github.com/madfish-solutions/quipuswap-farming
    // QUIPU https://tzkt.io/KT193D4vozYnhGJQVtw7CoxxqphqUEEwK6Vb/entrypoints
    [@inline] const cINTERFACE_QUIPU: nat = 3n;

    //RU Youves
    //RU
    //RU Методы фермы:
    //RU Депозит в ферму - deposit(farmTokenAmount)
    //RU Отзыв депозита из фермы - withdraw()
    //RU Вознаграждение - ???claim()
    // mainnet https://tzkt.io/KT1TFPn4ZTzmXDzikScBrWnHkoqTA7MBt9Gi/entrypoints
    //TODO [@inline] const cINTERFACE_YOUVES: nat = 3n;

    //RU PAUL
    //RU
    //RU Методы фермы:
    //RU Депозит в ферму - ???
    //RU Отзыв депозита из фермы - ???
    //RU Вознаграждение - ???
    // https://github.com/degentech/aliensfarm
    // mainnet https://tzkt.io/KT1DMCGGiHT2dgjjXHG7qh1C1maFchrLNphx/entrypoints
    //TODO [@inline] const cINTERFACE_PAUL: nat = 4n;

    //RU Все интерфейсы ферм
    const cINTERFACEs: set(nat) = set [cINTERFACE_CRUNCHY; cINTERFACE_QUIPU];

    //RU Параметры фермы
    type t_farm is [@layout:comb] record [
        addr: address;//RU< Адрес фермы
        id: nat;//RU< ID фермы, где применимо
        farmToken: t_token;//RU< Токен фермы
        rewardToken: t_token;//RU< Токен вознаграждения
        interface: nat;//RU< Интерфейс фермы, см. cINTERFACE...
    ];

    const cERR_UNKNOWN_INTERFACE: string = "MFarm/UnknownInterface";//RU< Ошибка: Неизвестный интерфейс фермы

    //RU Проверка параметров фермы на валидность
    function check(const farm: t_farm): unit is block {
        MToken.check(farm.farmToken);
        MToken.check(farm.rewardToken);
        if cINTERFACEs contains farm.interface then skip
        else failwith(cERR_UNKNOWN_INTERFACE);
    } with unit;

    //RU Инвестирование токенов фермы в ферму пользователем через контракта
    //RU
    //RU Токены фермы от пользователя Tezos.sender перечисляются сначала контракту, а затем в ферму
    function deposit(const _farm: t_farm; const _damount: t_amount): unit is block {
        skip;//TODO
    } with unit;

    //RU Отзыв токенов фермы пользователем
    //RU
    //RU Токены фермы перечисляются сначала контракту, а затем пользователю по адресу Tezos.sender
    function withdraw(const _farm: t_farm; const _wamount: t_amount): unit is block {
        skip;//TODO
    } with unit;

    //RU Запрос вознаграждения из фермы
    //RU
    //RU Токены вознаграждения перечисляются из фермы на адрес контракта
    function reward(const _farm: t_farm): unit is block {
        skip;//TODO
    } with unit;
}
#endif // !MFARM_INCLUDED

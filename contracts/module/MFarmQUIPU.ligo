#if !MFARMQUIPU_INCLUDED
#define MFARMQUIPU_INCLUDED

#include "MToken.ligo"

///RU Модуль взаимодействия с фермой QUIPU
///EN QUIPU Farm Interaction Module
module MFarmQUIPU is {

    ///RU Ошибка: Не найдена точка входа deposit для фермы в формате QUIPU
    ///EN Error: The deposit entry point for the farm in QUIPU format was not found
    const cERR_NOT_FOUND_DEPOSIT: string = "MFarmQUIPU/NotFoundDeposit";

    ///RU Ошибка: Не найдена точка входа withdraw для фермы в формате QUIPU
    ///EN Error: No withdrawal entry point found for the farm in QUIPU format
    const cERR_NOT_FOUND_WITHDRAW: string = "MFarmQUIPU/NotFoundWithdraw";

    ///RU Ошибка: Не найдена точка входа harvest для фермы в формате QUIPU
    ///EN Error: The harvest entry point for the farm in QUIPU format was not found
    const cERR_NOT_FOUND_HARVEST: string = "MFarmQUIPU/NotFoundHarvest";

    type t_farm_id is nat;///RU< ID фермы QUIPU ///EN< QUIPU farm ID

    ///RU Параметры для депозита в ферму QUIPU
    ///EN Parameters for the deposit to the QUIPU farm
    type t_deposit_params is [@layout:comb] record [
        fid: t_farm_id;///RU< ID фермы QUIPU ///EN< QUIPU farm ID
        amt: MToken.t_amount;///RU< Кол-во токенов ///EN< Number of tokens
        referrer: option(address);
        rewards_receiver: address;
        candidate: key_hash;
    ];

    ///RU Прототип метода deposit фермы QUIPU
    ///EN Prototype of the deposit method of the QUIPU farm
    type t_deposit_method is QUIPUDeposit of t_deposit_params;

    ///RU Контракт с точкой входа deposit в формате фермы QUIPU
    ///EN Contract with deposit entry point in QUIPU farm format
    type t_deposit_contract is contract(t_deposit_method);

    ///RU Параметры для извлечения депозита в ферму QUIPU
    ///EN Parameters for extracting a deposit to the QUIPU farm
    type t_withdraw_params is [@layout:comb] record [
        fid: t_farm_id;///RU< ID фермы QUIPU ///EN< QUIPU farm ID
        amt: MToken.t_amount;///RU< Кол-во токенов ///EN< Number of tokens
        receiver: address;
        rewards_receiver: address;
    ];

    ///RU Прототип метода withdraw фермы QUIPU
    ///EN Prototype of the QUIPU farm withdrawal method
    type t_withdraw_method is QUIPUWithdraw of t_withdraw_params;

    ///RU Контракт с точкой входа withdraw в формате фермы QUIPU
    ///EN Contract with withdrawal entry point in QUIPU farm format
    type t_withdraw_contract is contract(t_withdraw_method);

    ///RU Параметры получения вознаграждения из фермы QUIPU
    ///EN Parameters for receiving rewards from the QUIPU farm
    type t_harvest_params is [@layout:comb] record [
        fid: t_farm_id;///RU< ID фермы QUIPU ///EN< QUIPU farm ID
        rewards_receiver: address;
    ];

    ///RU Прототип метода harvest фермы QUIPU
    ///EN Prototype of the QUIPU farm harvest method
    type t_harvest_method is QUIPUHarvest of t_harvest_params;

    ///RU Контракт с точкой входа harvest в формате фермы QUIPU
    ///EN A contract with the harvest entry point in the QUIPU farm format
    type t_harvest_contract is contract(t_harvest_method);

    ///RU Получить точку входа deposit фермы с интерфейсом QUIPU
    ///EN Get the deposit farm entry point with the QUIPU interface
    function depositEntrypoint(const addr: address): t_deposit_contract is
        case (Tezos.get_entrypoint_opt("%deposit", addr): option(t_deposit_contract)) of [
        | Some(deposit_contract) -> deposit_contract
        | None -> (failwith(cERR_NOT_FOUND_DEPOSIT): t_deposit_contract)
        ];

    ///RU Параметры для метода deposit QUIPU
    ///EN Parameters for the deposit QUIPU method
    function depositParams(const farm_id: t_farm_id; const damount: MToken.t_amount): t_deposit_method is
        QUIPUDeposit(record [
            fid = farm_id;
            amt = damount;
            referrer = (None: option(address));
            rewards_receiver = Tezos.self_address;
            candidate = cZERO_KEY_HASH;
        ]);

    ///RU Депозит в ферму QUIPU
    ///EN Deposit to QUIPU farm
    function deposit(const addr: address; const farm_id: t_farm_id; const damount: MToken.t_amount): operation is
        Tezos.transaction(
            depositParams(farm_id, damount),
            0mutez,
            depositEntrypoint(addr)
        );

    ///RU Получить точку входа withdraw фермы с интерфейсом QUIPU
    ///EN Get a farm withdrawal entry point with the QUIPU interface
    function withdrawEntrypoint(const addr: address): t_withdraw_contract is
        case (Tezos.get_entrypoint_opt("%withdraw", addr): option(t_withdraw_contract)) of [
        | Some(withdraw_contract) -> withdraw_contract
        | None -> (failwith(cERR_NOT_FOUND_WITHDRAW): t_withdraw_contract)
        ];

    ///RU Параметры для метода deposit QUIPU
    ///EN Parameters for the deposit QUIPU method
    function withdrawParams(const farm_id: t_farm_id; const wamount: MToken.t_amount): t_withdraw_method is
        QUIPUWithdraw(record [
            fid = farm_id;
            amt = wamount;
            receiver = Tezos.self_address;
            rewards_receiver = Tezos.self_address;
        ]);

    ///RU Извлечение депозита из фермы QUIPU
    ///EN Extracting a deposit from a QUIPU farm
    function withdraw(const addr: address; const farm_id: t_farm_id; const wamount: MToken.t_amount): operation is
        Tezos.transaction(
            withdrawParams(farm_id, wamount),
            0mutez,
            withdrawEntrypoint(addr)
        );

    ///RU Получить точку входа harvest фермы с интерфейсом QUIPU
    ///EN Get the harvest farm entry point with the QUIPU interface
    function harvestEntrypoint(const addr: address): t_harvest_contract is
        case (Tezos.get_entrypoint_opt("%harvest", addr): option(t_harvest_contract)) of [
        | Some(harvest_contract) -> harvest_contract
        | None -> (failwith(cERR_NOT_FOUND_HARVEST): t_harvest_contract)
        ];

    ///RU Параметры для метода harvest QUIPU
    ///EN Parameters for the harvest QUIPU method
    function harvestParams(const farm_id: t_farm_id): t_harvest_method is
        QUIPUHarvest(record [
            fid = farm_id;
            rewards_receiver = Tezos.self_address;
        ]);

    ///RU Получение вознаграждения из фермы QUIPU
    ///EN Getting Rewards from QUIPU farm
    function harvest(const addr: address; const farm_id: t_farm_id): operation is
        Tezos.transaction(
            harvestParams(farm_id),
            0mutez,
            harvestEntrypoint(addr)
        );

    ///RU Проверка параметров фермы на валидность
    ///EN Checking the farm parameters for validity
    function check(const addr: address): unit is block {
        //RU Проверяем наличие метода deposit для фермы в формате QUIPU
        //EN We check the presence of the deposit method for the farm in the QUIPU format
        const _ = depositEntrypoint(addr);
        //RU Проверяем наличие метода withdraw для фермы в формате QUIPU
        //EN We check the availability of the withdraw method for the farm in the QUIPU format
        const _ = withdrawEntrypoint(addr);
        //RU Проверяем наличие метода harvest для фермы в формате QUIPU
        //EN We check the availability of the harvest method for the farm in the QUIPU format
        const _ = harvestEntrypoint(addr);
    } with unit;

}
#endif // !MFARMQUIPU_INCLUDED

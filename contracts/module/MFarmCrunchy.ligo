#if !MFARMCRUNCHY_INCLUDED
#define MFARMCRUNCHY_INCLUDED

#include "MToken.ligo"

///RU Модуль взаимодействия с фермой Crunchy
///EN Crunchy Farm Interaction Module
module MFarmCrunchy is {

    ///RU Ошибка: Не найдена точка входа deposit для фермы Crunchy
    ///EN Error: Deposit entry point for Crunchy farm not found
    const cERR_NOT_FOUND_DEPOSIT: string = "MFarmCrunchy/NotFoundDeposit";

    ///RU Ошибка: Не найдена точка входа withdraw для фермы Crunchy
    ///EN Error: Withdrawal entry point not found for Crunchy farm
    const cERR_NOT_FOUND_WITHDRAW: string = "MFarmCrunchy/NotFoundWithdraw";

    ///RU Ошибка: Не найдена точка входа harvest для фермы Crunchy
    ///EN Error: No harvest entry point found for Crunchy farm
    const cERR_NOT_FOUND_HARVEST: string = "MFarmCrunchy/NotFoundHarvest";

    type t_farm_id is nat;///RU< ID фермы Crunchy ///EN< Crunchy farm ID

    ///RU Параметры для депозита в ферму Crunchy
    ///EN Parameters for the deposit to the Crunchy farm
    type t_deposit_params is [@layout:comb] record [
        farm_id: t_farm_id;
        damount: MToken.t_amount;
    ];

    ///RU Прототип метода deposit фермы Crunchy
    ///EN Prototype of the Crunchy farm deposit method
    type t_deposit_method is CrunchyDeposit of t_deposit_params;

    ///RU Контракт с точкой входа deposit в формате фермы Crunchy
    ///EN Contract with deposit entry point in Crunchy farm format
    type t_deposit_contract is contract(t_deposit_method);

    ///RU Параметры для извлечения депозита из фермы Crunchy
    ///EN Parameters for extracting a deposit from a Crunchy farm
    type t_withdraw_params is [@layout:comb] record [
        farm_id: t_farm_id;
        wamount: MToken.t_amount;
    ];

    ///RU Прототип метода withdraw фермы Crunchy
    ///EN Prototype of the Crunchy farm withdrawal method
    type t_withdraw_method is CrunchyWithdraw of t_withdraw_params;

    ///RU Контракт с точкой входа withdraw в формате фермы Crunchy
    ///EN Contract with withdrawal entry point in Crunchy farm format
    type t_withdraw_contract is contract(t_withdraw_method);

    ///RU Параметры получения вознаграждения из фермы Crunchy
    ///EN Parameters for receiving rewards from the Crunchy farm
    type t_harvest_params is t_farm_id;

    ///RU Прототип метода harvest фермы Crunchy
    ///EN Prototype of the Crunchy farm harvest method
    type t_harvest_method is CrunchyHarvest of t_harvest_params;

    ///RU Контракт с точкой входа harvest в формате фермы Crunchy
    ///EN A contract with the harvest entry point in the Crunchy farm format
    type t_harvest_contract is contract(t_harvest_method);

    ///RU Получить точку входа deposit фермы с интерфейсом Crunchy
    ///EN Get the deposit farm entry point with the Crunchy interface
    function depositEntrypoint(const addr: address): t_deposit_contract is
        case (Tezos.get_entrypoint_opt("%deposit", addr): option(t_deposit_contract)) of [
        | Some(deposit_contract) -> deposit_contract
        | None -> (failwith(cERR_NOT_FOUND_DEPOSIT): t_deposit_contract)
        ];

    ///RU Параметры для метода deposit Crunchy
    ///EN Parameters for the deposit Crunchy method
    function depositParams(const farm_id: t_farm_id; const damount: MToken.t_amount): t_deposit_method is
        CrunchyDeposit(record [
            farm_id = farm_id;
            damount = damount;
        ]);

    ///RU Депозит в ферму Crunchy
    ///EN Deposit to Crunchy farm
    function deposit(const addr: address; const farm_id: t_farm_id; const damount: MToken.t_amount): operation is
        Tezos.transaction(
            depositParams(farm_id, damount),
            0mutez,
            depositEntrypoint(addr)
        );

    ///RU Получить точку входа withdraw фермы с интерфейсом Crunchy
    ///EN Get the withdrawal farm entry point with the Crunchy interface
    function withdrawEntrypoint(const addr: address): t_withdraw_contract is
        case (Tezos.get_entrypoint_opt("%withdraw", addr): option(t_withdraw_contract)) of [
        | Some(withdraw_contract) -> withdraw_contract
        | None -> (failwith(cERR_NOT_FOUND_WITHDRAW): t_withdraw_contract)
        ];

    ///RU Параметры для метода withdraw Crunchy
    ///EN Parameters for the withdraw Crunchy method
    function withdrawParams(const farm_id: t_farm_id; const wamount: MToken.t_amount): t_withdraw_method is
        CrunchyWithdraw(record [
            farm_id = farm_id;
            wamount = wamount;
        ]);

    ///RU Извлечение депозита из фермы Crunchy
    ///EN Extracting a deposit from a Crunchy farm
    function withdraw(const addr: address; const farm_id: t_farm_id; const wamount: MToken.t_amount): operation is
        Tezos.transaction(
            withdrawParams(farm_id, wamount),
            0mutez,
            withdrawEntrypoint(addr)
        );

    ///RU Получить точку входа harvest фермы с интерфейсом Crunchy
    ///EN Get the harvest farm entry point with the Crunchy interface
    function harvestEntrypoint(const addr: address): t_harvest_contract is
        case (Tezos.get_entrypoint_opt("%harvest", addr): option(t_harvest_contract)) of [
        | Some(harvest_contract) -> harvest_contract
        | None -> (failwith(cERR_NOT_FOUND_HARVEST): t_harvest_contract)
        ];

    ///RU Параметры для метода harvest Crunchy
    ///EN Parameters for the harvest Crunchy method
    function harvestParams(const farm_id: t_farm_id): t_harvest_method is CrunchyHarvest(farm_id);

    ///RU Получение вознаграждения из фермы Crunchy
    ///EN Getting Rewards from Crunchy arm
    function harvest(const addr: address; const farm_id: t_farm_id): operation is
        Tezos.transaction(
            harvestParams(farm_id),
            0mutez,
            harvestEntrypoint(addr)
        );

    ///RU Проверка параметров фермы на валидность
    ///EN Checking the farm parameters for validity
    function check(const addr: address): unit is block {
        //RU Проверяем наличие метода deposit для фермы в формате Crunchy
        //EN Check for the deposit method for the farm in Crunchy format
        const _d: t_deposit_contract = depositEntrypoint(addr);
        //RU Проверяем наличие метода withdraw для фермы в формате Crunchy
        //EN We check the availability of the withdraw method for the farm in the Crunchy format
        const _w: t_withdraw_contract = withdrawEntrypoint(addr);
        //RU Проверяем наличие метода harvest для фермы в формате Crunchy
        //EN We check the availability of the harvest method for the farm in the Crunchy format
        const _h: t_harvest_contract = harvestEntrypoint(addr);
    } with unit;

}
#endif // !MFARMCRUNCHY_INCLUDED

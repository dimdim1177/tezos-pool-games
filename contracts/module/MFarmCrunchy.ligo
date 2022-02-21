#if !MFARMCRUNCHY_INCLUDED
#define MFARMCRUNCHY_INCLUDED

#include "MToken.ligo"

//RU Модуль взаимодействия с фермой Crunchy
module MFarmCrunchy is {

    const cERR_NOT_FOUND_DEPOSIT: string = "MFarmCrunchy/NotFoundDeposit";//RU< Ошибка: Не найдена точка входа deposit для фермы Crunchy
    const cERR_NOT_FOUND_WITHDRAW: string = "MFarmCrunchy/NotFoundWithdraw";//RU< Ошибка: Не найдена точка входа withdraw для фермы Crunchy
    const cERR_NOT_FOUND_HARVEST: string = "MFarmCrunchy/NotFoundHarvest";//RU< Ошибка: Не найдена точка входа harvest для фермы Crunchy

    type t_farm_id is nat;//RU< ID фермы Crunchy
    type t_amount is nat;//RU< Кол-во токенов

    //RU Параметры для депозита в ферму Crunchy
    type t_deposit_params is [@layout:comb] record [
        farm_id: t_farm_id;
        damount: t_amount;
    ];
    type t_deposit_method is CrunchyDeposit of t_deposit_params;//RU Прототип метода deposit фермы Crunchy
    type t_deposit_contract is contract(t_deposit_method);//RU Контракт с точкой входа deposit в формате фермы Crunchy

    //RU< Параметры для извлечения депозита из фермы Crunchy
    type t_withdraw_params is [@layout:comb] record [
        farm_id: t_farm_id;
        wamount: t_amount;
    ];
    type t_withdraw_method is CrunchyWithdraw of t_withdraw_params;//RU Прототип метода withdraw фермы Crunchy
    type t_withdraw_contract is contract(t_withdraw_method);//RU Контракт с точкой входа withdraw в формате фермы Crunchy

    type t_harvest_params is t_farm_id;//RU< Параметры получения вознаграждения из фермы Crunchy
    type t_harvest_method is CrunchyHarvest of t_harvest_params;//RU Прототип метода harvest фермы Crunchy
    type t_harvest_contract is contract(t_harvest_method);//RU Контракт с точкой входа harvest в формате фермы Crunchy

    //RU Получить точку входа deposit фермы с интерфейсом Crunchy
    function depositEntrypoint(const addr: address): t_deposit_contract is
        case (Tezos.get_entrypoint_opt("%deposit", addr): option(t_deposit_contract)) of [
        | Some(deposit_contract) -> deposit_contract
        | None -> (failwith(cERR_NOT_FOUND_DEPOSIT): t_deposit_contract)
        ];

    //RU Параметры для метода deposit Crunchy
    function depositParams(const farm_id: t_farm_id; const damount: t_amount): t_deposit_method is
        CrunchyDeposit(record [
            farm_id = farm_id;
            damount = damount;
        ]);

    //RU Депозит в ферму Crunchy
    function deposit(const addr: address; const farm_id: t_farm_id; const damount: t_amount): operation is
        Tezos.transaction(
            depositParams(farm_id, damount),
            0mutez,
            depositEntrypoint(addr)
        );

    //RU Получить точку входа withdraw фермы с интерфейсом Crunchy
    function withdrawEntrypoint(const addr: address): t_withdraw_contract is
        case (Tezos.get_entrypoint_opt("%withdraw", addr): option(t_withdraw_contract)) of [
        | Some(withdraw_contract) -> withdraw_contract
        | None -> (failwith(cERR_NOT_FOUND_WITHDRAW): t_withdraw_contract)
        ];

    //RU Параметры для метода withdraw Crunchy
    function withdrawParams(const farm_id: t_farm_id; const wamount: t_amount): t_withdraw_method is
        CrunchyWithdraw(record [
            farm_id = farm_id;
            wamount = wamount;
        ]);

    //RU Извлечение депозита из фермы Crunchy
    function withdraw(const addr: address; const farm_id: t_farm_id; const wamount: t_amount): operation is
        Tezos.transaction(
            withdrawParams(farm_id, wamount),
            0mutez,
            withdrawEntrypoint(addr)
        );

    //RU Получить точку входа harvest фермы с интерфейсом Crunchy
    function harvestEntrypoint(const addr: address): t_harvest_contract is
        case (Tezos.get_entrypoint_opt("%harvest", addr): option(t_harvest_contract)) of [
        | Some(harvest_contract) -> harvest_contract
        | None -> (failwith(cERR_NOT_FOUND_HARVEST): t_harvest_contract)
        ];

    //RU Параметры для метода harvest Crunchy
    function harvestParams(const farm_id: t_farm_id): t_harvest_method is CrunchyHarvest(farm_id);

    //RU Получение вознаграждения из фермы Crunchy
    function harvest(const addr: address; const farm_id: t_farm_id): operation is
        Tezos.transaction(
            harvestParams(farm_id),
            0mutez,
            harvestEntrypoint(addr)
        );

    //RU Проверка параметров фермы на валидность
    function check(const addr: address): unit is block {
        //RU Проверяем наличие метода deposit для фермы в формате Crunchy
        const _d: t_deposit_contract = depositEntrypoint(addr);
        //RU Проверяем наличие метода withdraw для фермы в формате Crunchy
        const _w: t_withdraw_contract = withdrawEntrypoint(addr);
        //RU Проверяем наличие метода harvest для фермы в формате Crunchy
        const _h: t_harvest_contract = harvestEntrypoint(addr);
    } with unit;

}
#endif // !MFARMCRUNCHY_INCLUDED

#if !MGAME_INCLUDED
#define MGAME_INCLUDED

//RU Модуль партии розыгрыша вознаграждения
module MPoolGame is {

    //RU Структура партии по умолчанию
    function create(const state: t_game_state; const seconds: nat): t_game is block {
        const game: t_game = record [
            balance = 0n;
            count = 0n;
            state = state;
            tsBeg = Tezos.now;
            tsEnd = Tezos.now + int(seconds);
            weight = 0n;
            winWeight = 0n;
        ];
    } with game;

}
#endif // !MGAME_INCLUDED

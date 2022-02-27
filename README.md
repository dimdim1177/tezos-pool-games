## Contracts for periodic reward draws on deposit pools in farms

Project developed on Debian 11, not tested in other OS.

## Getting start

### Install tools

Execute script `./install/install_all.sh` for download and install: LIGO, tezos-client, python, pytezos and so on.
Or execute ./install/install_*.sh scripts for each tool manually.

### Compile

Usage: compile.sh NAME|ALL
Compile 'contracts/NAME.ligo' or 'contracts/*.ligo' for ALL.
Compiled files saved to 'build/NAME.tz' and 'build/NAME.storage.tz' files.

### Deploy

Usage: $(basename $0) NAME|ALL [force]
Deploy 'build/NAME.tz' inited by 'build/NAME.storage.tz' (or 'build/*.tz' for ALL) by account saved as 'owner' in tezos-client.

### Documentation

Execute script `./doc/doc.sh` for generate English and Russian documentations for contracts.

## Contract with pools - CPoolGames

See contracts/CPoolGames.ligo and folder contracts/CPoolGames.
Main features:
- Support 2 farms interfaces: Crunchy and QUIPU
- Three algorithms to determine the winner:
    - Probability of win proportional time in current game
    - Probability of win proportional sum of time * deposit in current game
    - Equal probabilities for all users in pool
- Additional pool options:
    - minimal deposit
    - minimal seconds in game
    - maximum deposit (only for algorithm by sum time * deposit)
    - win percent, burn percent, fee percent
    - burn token, fee address
- Flexible configuration:
    - pool owners/admins or pool as service
    - can enable security transfer tokens (remove operator after transfer)
    - can enable pool statictics in blockchain for promotion
    - can enable pool views for other smart contracts

## Contract for generate random numbers - CRandom

See contracts/CRandom.ligo and folder contracts/CRandom
Main features:
- Any can request random number in future
- Request has address and ID of obj
- Random number based on nearest Tezos block hash with time more time in request and XORed with hash of request, that is why one Tezos block generate different random numbers for different requests.


## Folders tree

### accounts

Folder with *.json faucet files, downloaded from https://teztnets.xyz/, basename of file used as account name in tezos-client.
One of it must be named as owner.json, this account used for deploy contracts.
Script `accounts/activate.sh` activate all accounts in testnet.

### build

Folder for compiled files *.tz, logs *.log and so on.

### contracts

Folder with contracts code. Files by mask contracts/CONTRACT_NAME.ligo compiled as contracts.
Folder contracts/CONTRACT_NAME used for contract specific includes and modules.
File contracts/CONTRACT_NAME/config.ligo contains contract configuration defines.
File contracts/CONTRACT_NAME/initial_storage.ligo contains initial storage description.

#### contracts/include

Common includes for all contracts.

#### contracts/module

Common modules for all contracts.

#### contracts/CPoolGames

Specific for contract contract/CPoolGames.ligo includes and modules.

#### contracts/CRandom

Specific for contract contracts/CRandom.ligo includes and modules.

### doc

Documentation folder.

### install

Folder with scripts for install development tools: LIGO, tezos-client and so on.

### tezbin

Binaries from tezos: tezos-client and so on.

### venv

Virtual envoriment for python

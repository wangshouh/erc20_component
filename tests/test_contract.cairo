use core::result::ResultTrait;
use erc20_component::components::erc20::ERC20TraitSafeDispatcherTrait;
use core::array::ArrayTrait;
use starknet::ContractAddress;
use starknet::contract_address_const;
use snforge_std::{declare, ContractClassTrait, start_prank, stop_prank};

use erc20_component::components::erc20::ERC20TraitSafeDispatcher;
use erc20_component::contracts::hello_starknet::MintERC20SafeDispatcher;

fn deploy_contract(name: felt252, owner: ContractAddress) -> ContractAddress {
    let contract = declare(name);
    let args = array!['TEST', 'TE', 18, 5000, 0, owner.into(), owner.into()];
    contract.deploy(@args).unwrap()
}

#[test]
fn test_init() {
    let owner = contract_address_const::<'ADMIN'>();
    let contract_address = deploy_contract('MintableErc20Ownable', owner);

    let safe_dispatcher = ERC20TraitSafeDispatcher { contract_address };

    let owner_balance = safe_dispatcher.balance_of(owner).unwrap();

    assert(owner_balance == 5000_u256, 'Balanace Init');
}
// #[test]
// fn test_increase_balance() {
//     let owner = contract_address_const::<'ADMIN'>();
//     let contract_address = deploy_contract('HelloStarknet', owner);

//     let safe_dispatcher = IHelloStarknetSafeDispatcher { contract_address };

//     let balance_before = safe_dispatcher.get_total_supply().unwrap();
//     assert(balance_before == 0, 'Invalid balance');

//     start_prank(contract_address, owner);
//     safe_dispatcher.increase_balance(42).unwrap();
//     stop_prank(contract_address);

//     let balance_after = safe_dispatcher.get_balance().unwrap();
//     assert(balance_after == 42, 'Invalid balance');
// }

// #[test]
// fn test_cannot_increase_balance_with_not_on() {
//     let owner = contract_address_const::<'ADMIN'>();
//     let contract_address = deploy_contract('HelloStarknet', owner);

//     let safe_dispatcher = IHelloStarknetSafeDispatcher { contract_address };

//     let balance_before = safe_dispatcher.get_balance().unwrap();
//     assert(balance_before == 0, 'Invalid balance');

//     match safe_dispatcher.increase_balance(42) {
//         Result::Ok(_) => panic_with_felt252('Should have panicked'),
//         Result::Err(panic_data) => {
//             assert(*panic_data.at(0) == 'Wrong owner.', *panic_data.at(0));
//         }
//     };
// }



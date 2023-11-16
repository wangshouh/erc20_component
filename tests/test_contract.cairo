use snforge_std::cheatcodes::events::EventFetcher;
use core::result::ResultTrait;
use core::array::ArrayTrait;
use starknet::ContractAddress;
use starknet::contract_address_const;
use snforge_std::{
    declare, ContractClassTrait, start_prank, stop_prank, spy_events, SpyOn, EventAssertions,
    event_name_hash
};
use snforge_std::PrintTrait;

use erc20_component::contracts::hello_starknet::MintableErc20Ownable;
use erc20_component::components::erc20::erc20 as token;
use erc20_component::components::erc20::ERC20TraitSafeDispatcher;
use erc20_component::components::erc20::ERC20TraitSafeDispatcherTrait;

use erc20_component::components::mintable::MintTraitSafeDispatcher;
use erc20_component::components::mintable::MintTraitSafeDispatcherTrait;

fn deploy_contract(name: felt252, owner: ContractAddress) -> ContractAddress {
    let contract = declare(name);
    let args = array!['TEST', 'TE', 18, 5000, 0, owner.into(), owner.into()];
    contract.deploy(@args).unwrap()
}

#[test]
fn test_init() {
    let mut spy = spy_events(SpyOn::All);

    let owner = contract_address_const::<'ADMIN'>();
    let contract_address = deploy_contract('MintableErc20Ownable', owner);

    let safe_dispatcher = ERC20TraitSafeDispatcher { contract_address };

    let owner_balance = safe_dispatcher.balance_of(owner).unwrap();
    assert(owner_balance == 5000_u256, 'Balanace Init');
    assert(safe_dispatcher.get_name().unwrap() == 'TEST', 'Name Init');
    
    spy
        .assert_emitted(
            @array![
                (
                    contract_address,
                    erc20_component::contracts::hello_starknet::MintableErc20Ownable::Event::ERC20(
                        token::TransferEvent {
                            from: contract_address_const::<0>(), to: owner, value: 5000_u256
                        }
                            .into()
                    )
                )
            ]
        );
}

#[test]
fn test_increase_balance() {
    let owner = contract_address_const::<'ADMIN'>();
    let contract_address = deploy_contract('MintableErc20Ownable', owner);
    let receiver = contract_address_const::<1>();

    let erc20_dispatcher = ERC20TraitSafeDispatcher { contract_address };
    let mint_dispatcher = MintTraitSafeDispatcher { contract_address };

    start_prank(contract_address, owner);
    let mut spy = spy_events(SpyOn::One(contract_address));
    mint_dispatcher.mint(receiver, 42).unwrap();
    stop_prank(contract_address);

    let balance_after = erc20_dispatcher.balance_of(receiver).unwrap();

    assert(balance_after == 42, 'Invalid balance');
    spy
        .assert_emitted(
            @array![
                (
                    contract_address,
                    erc20_component::contracts::hello_starknet::MintableErc20Ownable::Event::ERC20(
                        token::TransferEvent {
                            from: contract_address_const::<0>(), to: receiver, value: 42_u256
                        }
                            .into()
                    )
                )
            ]
        );
}

#[test]
fn test_cannot_mint_with_not_on() {
    let owner = contract_address_const::<'ADMIN'>();
    let contract_address = deploy_contract('MintableErc20Ownable', owner);

    let erc20_dispatcher = ERC20TraitSafeDispatcher { contract_address };
    let mint_dispatcher = MintTraitSafeDispatcher { contract_address };

    let balance_before = erc20_dispatcher.balance_of(owner).unwrap();
    assert(balance_before == 5000_u256, 'Invalid balance');

    match mint_dispatcher.mint(owner, 42) {
        Result::Ok(_) => panic_with_felt252('Should have panicked'),
        Result::Err(panic_data) => {
            assert(panic_data.at(0) == @'Wrong owner.', *panic_data.at(0));
        }
    };
}

